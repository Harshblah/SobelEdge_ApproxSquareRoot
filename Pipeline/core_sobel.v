module core_sobel (
    input wire clka,           // Clock input
    input wire reset,    // Reset input
    input wire start,          // Start computation signal
    input [7:0] p_0, p_1, p_2, p_3, p_4, p_5, p_6,
    input [7:0] p_7, p_8, p_9, p_10, p_11, p_12, p_13,
    input [7:0] p_14, p_15, p_16, p_17, p_18, p_19, p_20,
    input [5:0] error,         // User-provided target error
    output reg [7:0] out_0, out_1, out_2, out_3, out_4, // Individual 8-bit outputs
    output reg done            // Computation done signal
);

    // Internal wire array to map individual inputs to 3x7 structure
    wire [7:0] p_internal [0:20];
    assign p_internal[0] = p_0;
    assign p_internal[1] = p_1;
    assign p_internal[2] = p_2;
    assign p_internal[3] = p_3;
    assign p_internal[4] = p_4;
    assign p_internal[5] = p_5;
    assign p_internal[6] = p_6;
    assign p_internal[7] = p_7;
    assign p_internal[8] = p_8;
    assign p_internal[9] = p_9;
    assign p_internal[10] = p_10;
    assign p_internal[11] = p_11;
    assign p_internal[12] = p_12;
    assign p_internal[13] = p_13;
    assign p_internal[14] = p_14;
    assign p_internal[15] = p_15;
    assign p_internal[16] = p_16;
    assign p_internal[17] = p_17;
    assign p_internal[18] = p_18;
    assign p_internal[19] = p_19;
    assign p_internal[20] = p_20;

    // Compute R for each of the 5 pixels using Sobel gradients
    wire [15:0] R [0:4];
    genvar k;
    generate
        for (k = 0; k < 5; k = k + 1) begin : sobel_k
            wire [7:0] p0 = p_internal[k];         // p[0][k]
            wire [7:0] p1 = p_internal[k+1];       // p[0][k+1]
            wire [7:0] p2 = p_internal[k+2];       // p[0][k+2]
            wire [7:0] p3 = p_internal[7+k];       // p[1][k]
            wire [7:0] p5 = p_internal[7+k+2];     // p[1][k+2]
            wire [7:0] p6 = p_internal[14+k];      // p[2][k]
            wire [7:0] p7 = p_internal[14+k+1];    // p[2][k+1]
            wire [7:0] p8 = p_internal[14+k+2];    // p[2][k+2]

            wire signed [10:0] gx = (p2 - p0) + ((p5 - p3) << 1) + (p8 - p6);
            wire signed [10:0] gy = (p0 - p6) + ((p1 - p7) << 1) + (p2 - p8);

            wire [10:0] abs_gx = gx[10] ? -gx : gx;
            wire [10:0] abs_gy = gy[10] ? -gy : gy;

            wire [7:0] gx8 = (abs_gx > 11'd255) ? 8'd255 : abs_gx[7:0];
            wire [7:0] gy8 = (abs_gy > 11'd255) ? 8'd255 : abs_gy[7:0];

            wire [15:0] sqx = gx8 * gx8;
            wire [15:0] sqy = gy8 * gy8;
            assign R[k] = sqx + sqy;
        end
    endgenerate

    // Map error to trained error
    reg [5:0] trained_error;
    always @(*) begin
        if (error >= 53) trained_error = 53;
        else if (error >= 35) trained_error = 35;
        else if (error >= 25) trained_error = 25;
        else if (error >= 20) trained_error = 20;
        else if (error >= 15) trained_error = 15;
        else if (error >= 12) trained_error = 12;
        else if (error >= 10) trained_error = 10;
        else if (error >= 8) trained_error = 8;
        else if (error >= 7) trained_error = 7;
        else if (error >= 6) trained_error = 6;
        else if (error >= 5) trained_error = 5;
        else if (error >= 4) trained_error = 4;
        else if (error >= 3) trained_error = 3;
        else if (error >= 2) trained_error = 2;
        else trained_error = 1;
    end

    // Map trained error to 4-bit error code
    reg [3:0] error_code;
    always @(*) begin
        case (trained_error)
            1:  error_code = 4'b0000;
            2:  error_code = 4'b0001;
            3:  error_code = 4'b0010;
            4:  error_code = 4'b0011;
            5:  error_code = 4'b0100;
            6:  error_code = 4'b0101;
            7:  error_code = 4'b0110;
            8:  error_code = 4'b0111;
            10: error_code = 4'b1000;
            12: error_code = 4'b1001;
            15: error_code = 4'b1010;
            20: error_code = 4'b1011;
            25: error_code = 4'b1100;
            35: error_code = 4'b1101;
            53: error_code = 4'b1110;
            default: error_code = 4'b0000;
        endcase
    end

    // Predict k for each R using k_predictor
    wire [19:0] key [0:4];
    wire [3:0] k_value [0:4];
    generate
        for (k = 0; k < 5; k = k + 1) begin : predict_k
            assign key[k] = {error_code, R[k]};
            k_predictor pred (.key(key[k]), .k_value(k_value[k]));
        end
    endgenerate

    // Buffers for each k value (4, 6, 8, 10, 12)

    reg [15:0] buffer_k4 [0:4], buffer_k6 [0:4], buffer_k8 [0:4], buffer_k10 [0:4], buffer_k12 [0:4];
    reg [2:0] idx_k4 [0:4], idx_k6 [0:4], idx_k8 [0:4], idx_k10 [0:4], idx_k12 [0:4];
    reg [2:0] count_k4, count_k6, count_k8, count_k10, count_k12;

    // Combinational logic to compute buffer contents for each k
    reg [15:0] buffer_k4_wire [0:4];
    reg [2:0] idx_k4_wire [0:4];
    reg [2:0] count_k4_wire;
    integer i;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            buffer_k4_wire[i] = 16'b0;  // Corrected typo
            idx_k4_wire[i] = 3'b0;
        end
        count_k4_wire = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (k_value[i] == 4) begin
                buffer_k4_wire[count_k4_wire] = R[i];
                idx_k4_wire[count_k4_wire] = i;
                count_k4_wire = count_k4_wire + 1;
            end
        end
    end

    reg [15:0] buffer_k6_wire [0:4];
    reg [2:0] idx_k6_wire [0:4];
    reg [2:0] count_k6_wire;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            buffer_k6_wire[i] = 16'b0;
            idx_k6_wire[i] = 3'b0;
        end
        count_k6_wire = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (k_value[i] == 6) begin
                buffer_k6_wire[count_k6_wire] = R[i];
                idx_k6_wire[count_k6_wire] = i;
                count_k6_wire = count_k6_wire + 1;
            end
        end
    end

    reg [15:0] buffer_k8_wire [0:4];
    reg [2:0] idx_k8_wire [0:4];
    reg [2:0] count_k8_wire;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            buffer_k8_wire[i] = 16'b0;
            idx_k8_wire[i] = 3'b0;
        end
        count_k8_wire = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (k_value[i] == 8) begin
                buffer_k8_wire[count_k8_wire] = R[i];
                idx_k8_wire[count_k8_wire] = i;
                count_k8_wire = count_k8_wire + 1;
            end
        end
    end

    reg [15:0] buffer_k10_wire [0:4];
    reg [2:0] idx_k10_wire [0:4];
    reg [2:0] count_k10_wire;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            buffer_k10_wire[i] = 16'b0;
            idx_k10_wire[i] = 3'b0;
        end
        count_k10_wire = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (k_value[i] == 10) begin
                buffer_k10_wire[count_k10_wire] = R[i];
                idx_k10_wire[count_k10_wire] = i;
                count_k10_wire = count_k10_wire + 1;
            end
        end
    end

    reg [15:0] buffer_k12_wire [0:4];
    reg [2:0] idx_k12_wire [0:4];
    reg [2:0] count_k12_wire;
    always @(*) begin
        for (i = 0; i < 5; i = i + 1) begin
            buffer_k12_wire[i] = 16'b0;
            idx_k12_wire[i] = 3'b0;
        end
        count_k12_wire = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (k_value[i] == 12) begin
                buffer_k12_wire[count_k12_wire] = R[i];
                idx_k12_wire[count_k12_wire] = i;
                count_k12_wire = count_k12_wire + 1;
            end
        end
    end

    // Select R values for MAHSQR modules
    wire [15:0] R_selected_k4 = (count_k4 > 0) ? buffer_k4[0] : 16'h0;
    wire [15:0] R_selected_k6 = (count_k6 > 0) ? buffer_k6[0] : 16'h0;
    wire [15:0] R_selected_k8 = (count_k8 > 0) ? buffer_k8[0] : 16'h0;
    wire [15:0] R_selected_k10 = (count_k10 > 0) ? buffer_k10[0] : 16'h0;
    wire [15:0] R_selected_k12 = (count_k12 > 0) ? buffer_k12[0] : 16'h0;

    // Instantiate MAHSQR modules (strictly combinational)
    wire [7:0] out_k4, out_k6, out_k8, out_k10, out_k12;
    squareroot_MAHSQR_k4 sqrt_k4 (.R(R_selected_k4), .final_op(out_k4));
    squareroot_MAHSQR_k6 sqrt_k6 (.R(R_selected_k6), .final_op(out_k6));
    squareroot_MAHSQR_k8 sqrt_k8 (.R(R_selected_k8), .final_op(out_k8));
    squareroot_MAHSQR_k10 sqrt_k10 (.R(R_selected_k10), .final_op(out_k10));
    squareroot_MAHSQR_k12 sqrt_k12 (.R(R_selected_k12), .final_op(out_k12));

    // State machine definitions
    localparam IDLE = 2'b00, COMPUTE = 2'b01, PROCESS = 2'b10, FINISH = 2'b11;
    reg [1:0] state;
    reg [2:0] remaining;

    // Clock-driven state machine
    integer j;
    always @(posedge clka) begin
        if (reset) begin
            state <= IDLE;
            done <= 1'b0;
            out_0 <= 8'b0;
            out_1 <= 8'b0;
            out_2 <= 8'b0;
            out_3 <= 8'b0;
            out_4 <= 8'b0;
            for (i = 0; i < 5; i = i + 1) begin
                buffer_k4[i] <= 16'b0;
                buffer_k6[i] <= 16'b0;
                buffer_k8[i] <= 16'b0;
                buffer_k10[i] <= 16'b0;
                buffer_k12[i] <= 16'b0;
                idx_k4[i] <= 3'b0;
                idx_k6[i] <= 3'b0;
                idx_k8[i] <= 3'b0;
                idx_k10[i] <= 3'b0;
                idx_k12[i] <= 3'b0;
            end
            count_k4 <= 3'b0;
            count_k6 <= 3'b0;
            count_k8 <= 3'b0;
            count_k10 <= 3'b0;
            count_k12 <= 3'b0;
            remaining <= 3'b0;
        end else begin
            done <= 1'b0; // Default done to 0
            case (state)
                IDLE: begin
                    if (start) state <= COMPUTE;
                end
                COMPUTE: begin
                    for (i = 0; i < 5; i = i + 1) begin
                        buffer_k4[i] <= buffer_k4_wire[i];
                        idx_k4[i] <= idx_k4_wire[i];
                        buffer_k6[i] <= buffer_k6_wire[i];
                        idx_k6[i] <= idx_k6_wire[i];
                        buffer_k8[i] <= buffer_k8_wire[i];
                        idx_k8[i] <= idx_k8_wire[i];
                        buffer_k10[i] <= buffer_k10_wire[i];
                        idx_k10[i] <= idx_k10_wire[i];
                        buffer_k12[i] <= buffer_k12_wire[i];
                        idx_k12[i] <= idx_k12_wire[i];
                    end
                    count_k4 <= count_k4_wire;
                    count_k6 <= count_k6_wire;
                    count_k8 <= count_k8_wire;
                    count_k10 <= count_k10_wire;
                    count_k12 <= count_k12_wire;
                    remaining <= 5;
                    state <= PROCESS;
                end
                PROCESS: begin
                    // Process k=4
                    if (count_k4 > 0) begin
                        case (idx_k4[0])
                            0: out_0 <= out_k4;
                            1: out_1 <= out_k4;
                            2: out_2 <= out_k4;
                            3: out_3 <= out_k4;
                            4: out_4 <= out_k4;
                        endcase
                        for (j = 0; j < 4; j = j + 1) begin
                            buffer_k4[j] <= buffer_k4[j+1];
                            idx_k4[j] <= idx_k4[j+1];
                        end
                        count_k4 <= count_k4 - 1;
                    end
                    // Process k=6
                    if (count_k6 > 0) begin
                        case (idx_k6[0])
                            0: out_0 <= out_k6;
                            1: out_1 <= out_k6;
                            2: out_2 <= out_k6;
                            3: out_3 <= out_k6;
                            4: out_4 <= out_k6;
                        endcase
                        for (j = 0; j < 4; j = j + 1) begin
                            buffer_k6[j] <= buffer_k6[j+1];
                            idx_k6[j] <= idx_k6[j+1];
                        end
                        count_k6 <= count_k6 - 1;
                    end
                    // Process k=8
                    if (count_k8 > 0) begin
                        case (idx_k8[0])
                            0: out_0 <= out_k8;
                            1: out_1 <= out_k8;
 
                            2: out_2 <= out_k8;
                            3: out_3 <= out_k8;
                            4: out_4 <= out_k8;
                        endcase
                        for (j = 0; j < 4; j = j + 1) begin
                            buffer_k8[j] <= buffer_k8[j+1];
                            idx_k8[j] <= idx_k8[j+1];
                        end
                        count_k8 <= count_k8 - 1;
                    end
                    // Process k=10
                    if (count_k10 > 0) begin
                        case (idx_k10[0])
                            0: out_0 <= out_k10;
                            1: out_1 <= out_k10;
                            2: out_2 <= out_k10;
                            3: out_3 <= out_k10;
                            4: out_4 <= out_k10;
                        endcase
                        for (j = 0; j < 4; j = j + 1) begin
                            buffer_k10[j] <= buffer_k10[j+1];
                            idx_k10[j] <= idx_k10[j+1];
                        end
                        count_k10 <= count_k10 - 1;
                    end
                    // Process k=12
                    if (count_k12 > 0) begin
                        case (idx_k12[0])
                            0: out_0 <= out_k12;
                            1: out_1 <= out_k12;
                            2: out_2 <= out_k12;
                            3: out_3 <= out_k12;
                            4: out_4 <= out_k12;
                        endcase
                        for (j = 0; j < 4; j = j + 1) begin
                            buffer_k12[j] <= buffer_k12[j+1];
                            idx_k12[j] <= idx_k12[j+1];
                        end
                        count_k12 <= count_k12 - 1;
                    end
                    // Update remaining and check for finish
                    remaining <= remaining - ((count_k4 > 0) + (count_k6 > 0) + (count_k8 > 0) + (count_k10 > 0) + (count_k12 > 0));
                    if (remaining - ((count_k4 > 0) + (count_k6 > 0) + (count_k8 > 0) + (count_k10 > 0) + (count_k12 > 0)) == 0)
                        state <= FINISH;
                end
                FINISH: begin
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule