`timescale 1ns/1ps
(* DONT_TOUCH = "yes" *)
module sobel_edge_detector #(
    parameter IMG_WIDTH   = 83,  // Width of bounding-box image (kept for compatibility)
    parameter IMG_HEIGHT  = 42,  // Height of bounding-box image (kept for compatibility)
    parameter BBOX_X0     = 106,    // Top-left X
    parameter BBOX_Y0     = 127,    // Top-left Y
    parameter BBOX_X1     = 189,  // Bottom-right X
    parameter BBOX_Y1     = 169   // Bottom-right Y (adjusted: 2 + 251 - 1 = 252)
) (
    input  wire        clka,
    input  wire        reset,
    input  [5:0] error_bck,
    input  [5:0] error_bb,
    output reg         done
);
    // Local parameters for bounding box dimensions
    localparam BBOX_WIDTH  = BBOX_X1 - BBOX_X0 + 1; // 185
    localparam BBOX_HEIGHT = BBOX_Y1 - BBOX_Y0 + 1; // 251

    // BRAM interfaces
    wire [7:0]  douta_input;
    reg  [15:0] addra_input;
    reg         ena_input;
    (* DONT_TOUCH = "yes" *) blk_mem_read input_bram (
        .clka(clka), .ena(ena_input), .wea(1'b0),
        .addra(addra_input), .dina(8'b0), .douta(douta_input)
    );

    wire [7:0]  douta_input_bb;
    reg  [15:0] addra_input_bb;
    (* DONT_TOUCH = "yes" *) blk_mem_read1 input_bram_bb (
        .clka(clka), .ena(ena_input), .wea(1'b0),
        .addra(addra_input_bb), .dina(8'b0), .douta(douta_input_bb)
    );

    reg  [15:0] addra_output;
    reg  [7:0]  dina_output;
    reg         wea_output;
    reg         ena_output;
    (* DONT_TOUCH = "yes" *) blk_mem_write output_bram (
        .clka(clka), .ena(ena_output), .wea(wea_output),
        .addra(addra_output), .dina(dina_output), .douta()
    );

    reg  [15:0] addra_output_bb;
    reg  [7:0]  dina_output_bb;
    reg         wea_output_bb;
    reg         ena_output_bb;
    (* DONT_TOUCH = "yes" *) blk_mem_write1 output_bram_bb (
        .clka(clka), .ena(ena_output_bb), .wea(wea_output_bb),
        .addra(addra_output_bb), .dina(dina_output_bb), .douta()
    );

    // 3x7 patch registers
    reg [7:0] p[0:2][0:6]; // Background
    reg [7:0] P[0:2][0:6]; // Bounding box

    // Wires for flattened inputs to Sobel cores
    wire [7:0] p_0, p_1, p_2, p_3, p_4, p_5, p_6, p_7, p_8, p_9, p_10, p_11, p_12, p_13, p_14, p_15, p_16, p_17, p_18, p_19, p_20;
    wire [7:0] P_0, P_1, P_2, P_3, P_4, P_5, P_6, P_7, P_8, P_9, P_10, P_11, P_12, P_13, P_14, P_15, P_16, P_17, P_18, P_19, P_20;

    // Assign flattened inputs from arrays
    assign p_0  = p[0][0]; assign p_1  = p[0][1]; assign p_2  = p[0][2]; assign p_3  = p[0][3]; assign p_4  = p[0][4]; assign p_5  = p[0][5]; assign p_6  = p[0][6];
    assign p_7  = p[1][0]; assign p_8  = p[1][1]; assign p_9  = p[1][2]; assign p_10 = p[1][3]; assign p_11 = p[1][4]; assign p_12 = p[1][5]; assign p_13 = p[1][6];
    assign p_14 = p[2][0]; assign p_15 = p[2][1]; assign p_16 = p[2][2]; assign p_17 = p[2][3]; assign p_18 = p[2][4]; assign p_19 = p[2][5]; assign p_20 = p[2][6];

    assign P_0  = P[0][0]; assign P_1  = P[0][1]; assign P_2  = P[0][2]; assign P_3  = P[0][3]; assign P_4  = P[0][4]; assign P_5  = P[0][5]; assign P_6  = P[0][6];
    assign P_7  = P[1][0]; assign P_8  = P[1][1]; assign P_9  = P[1][2]; assign P_10 = P[1][3]; assign P_11 = P[1][4]; assign P_12 = P[1][5]; assign P_13 = P[1][6];
    assign P_14 = P[2][0]; assign P_15 = P[2][1]; assign P_16 = P[2][2]; assign P_17 = P[2][3]; assign P_18 = P[2][4]; assign P_19 = P[2][5]; assign P_20 = P[2][6];

    // Sobel-core instantiations
    wire [7:0] edge_out_0, edge_out_1, edge_out_2, edge_out_3, edge_out_4;
    wire done_bg;
    reg  start_bg;
    (* DONT_TOUCH = "yes" *) core_sobel core_sobel_inst (
        .clka(clka),
        .reset(reset),
        .start(start_bg),
        .p_0(p_0), .p_1(p_1), .p_2(p_2), .p_3(p_3), .p_4(p_4), .p_5(p_5), .p_6(p_6),
        .p_7(p_7), .p_8(p_8), .p_9(p_9), .p_10(p_10), .p_11(p_11), .p_12(p_12), .p_13(p_13),
        .p_14(p_14), .p_15(p_15), .p_16(p_16), .p_17(p_17), .p_18(p_18), .p_19(p_19), .p_20(p_20),
        .error(error_bck),
        .out_0(edge_out_0), .out_1(edge_out_1), .out_2(edge_out_2), .out_3(edge_out_3), .out_4(edge_out_4),
        .done(done_bg)
    );

    wire [7:0] edge_out_bb_0, edge_out_bb_1, edge_out_bb_2, edge_out_bb_3, edge_out_bb_4;
    wire done_bb;
    reg  start_bb;
    (* DONT_TOUCH = "yes" *) core_sobel1 core_sobel_inst11 (
        .clka(clka),
        .reset(reset),
        .start(start_bb),
        .p_0(P_0), .p_1(P_1), .p_2(P_2), .p_3(P_3), .p_4(P_4), .p_5(P_5), .p_6(P_6),
        .p_7(P_7), .p_8(P_8), .p_9(P_9), .p_10(P_10), .p_11(P_11), .p_12(P_12), .p_13(P_13),
        .p_14(P_14), .p_15(P_15), .p_16(P_16), .p_17(P_17), .p_18(P_18), .p_19(P_19), .p_20(P_20),
        .error(error_bb),
        .out_0(edge_out_bb_0), .out_1(edge_out_bb_1), .out_2(edge_out_bb_2), .out_3(edge_out_bb_3), .out_4(edge_out_bb_4),
        .done(done_bb)
    );

    // Reconstruct output arrays
    wire [7:0] edge_out[0:4];
    assign edge_out[0] = edge_out_0;
    assign edge_out[1] = edge_out_1;
    assign edge_out[2] = edge_out_2;
    assign edge_out[3] = edge_out_3;
    assign edge_out[4] = edge_out_4;

    wire [7:0] edge_out_bb[0:4];
    assign edge_out_bb[0] = edge_out_bb_0;
    assign edge_out_bb[1] = edge_out_bb_1;
    assign edge_out_bb[2] = edge_out_bb_2;
    assign edge_out_bb[3] = edge_out_bb_3;
    assign edge_out_bb[4] = edge_out_bb_4;

    // FSM states
    localparam 
        IDLE          = 3'd0,
        READ_PIXELS   = 3'd1,
        START_COMPUTE = 3'd2,
        WAIT_COMPUTE  = 3'd3,
        WRITE_OUTPUT  = 3'd4;

    reg [2:0] state;
    reg [7:0] m, n;
    reg [4:0] read_cnt;
    reg [2:0] write_cnt;
    reg done_bg_flag, done_bb_flag;

    // Cycle counter
    reg [31:0] cycle_counter;
    reg        counting;
    reg [2:0] i, j;

    // Registers for pixel position calculations
    reg [8:0] row;        // 9 bits to handle temporary out-of-range values (-1 to 256)
    reg [8:0] col;        // 9 bits to handle temporary out-of-range values (-1 to 256)
    reg [7:0] pixel_row;  // 8 bits for 0 to 255
    reg [7:0] pixel_col;  // 8 bits for 0 to 255
    reg [7:0] last_row;   // 8 bits for 0 to 255
    reg [7:0] last_col;   // 8 bits for 0 to 255

    // Main FSM
    always @(posedge clka or posedge reset) begin
        if (reset) begin
            state           <= IDLE;
            done            <= 1'b0;
            m               <= 8'd0;
            n               <= 8'd0;
            read_cnt        <= 5'd0;
            write_cnt       <= 3'd0;
            ena_input       <= 1'b0;
            cycle_counter   <= 32'd0;
            counting        <= 1'b0;
            addra_input     <= 16'd0;
            addra_input_bb  <= 16'd0;
            addra_output    <= 16'd0;
            dina_output     <= 8'd0;
            wea_output      <= 1'b0;
            ena_output      <= 1'b0;
            addra_output_bb <= 16'd0;
            dina_output_bb  <= 8'd0;
            wea_output_bb   <= 1'b0;
            ena_output_bb   <= 1'b0;
            start_bg        <= 1'b0;
            start_bb        <= 1'b0;
            done_bg_flag    <= 1'b0;
            done_bb_flag    <= 1'b0;
            for (i = 0; i < 3; i = i + 1)
                for (j = 0; j < 7; j = j + 1) begin
                    p[i][j] <= 8'd0;
                    P[i][j] <= 8'd0;
                end
        end else begin
            // Cycle counting
            if (!counting && state != IDLE) counting <= 1'b1;
            if (counting && !done) cycle_counter <= cycle_counter + 1;
            if (done) counting <= 1'b0;

            // Default values
            start_bg      <= 1'b0;
            start_bb      <= 1'b0;
            wea_output    <= 1'b0;
            ena_output    <= 1'b0;
            wea_output_bb <= 1'b0;
            ena_output_bb <= 1'b0;

            case (state)
                IDLE: begin
                    done       <= 1'b0;
                    m          <= 8'd0;
                    n          <= 8'd0;
                    read_cnt   <= 5'd0;
                    write_cnt  <= 3'd0;
                    ena_input  <= 1'b0;
                    state      <= READ_PIXELS;
                end

                READ_PIXELS: begin
                    if (read_cnt < 5'd21) begin
                        ena_input <= 1'b1;
                        row = m + (read_cnt / 7);
                        col = n + (read_cnt % 7);
                        // Background BRAM address calculation
                        if (row >= 0 && row < 256 && col >= 0 && col < 256) begin
                            addra_input <= row * 16'd256 + col;
                        end else begin
                            addra_input <= 16'd0;
                        end
                        // Bounding box BRAM address calculation
                        if (row >= BBOX_Y0 && row <= BBOX_Y1 && col >= BBOX_X0 && col <= BBOX_X1) begin
                            addra_input_bb <= (row - BBOX_Y0) * BBOX_WIDTH + (col - BBOX_X0);
                        end else begin
                            addra_input_bb <= 16'd0;
                        end
                        // Latch previous-cycle data
                        if (read_cnt > 0) begin
                            if (m + ((read_cnt - 1) / 7) >= 0 && m + ((read_cnt - 1) / 7) < 256 &&
                                n + ((read_cnt - 1) % 7) >= 0 && n + ((read_cnt - 1) % 7) < 256) begin
                                p[(read_cnt - 1) / 7][(read_cnt - 1) % 7] <= douta_input;
                            end else begin
                                p[(read_cnt - 1) / 7][(read_cnt - 1) % 7] <= 8'd0;
                            end
                            if (m + ((read_cnt - 1) / 7) >= BBOX_Y0 && m + ((read_cnt - 1) / 7) <= BBOX_Y1 &&
                                n + ((read_cnt - 1) % 7) >= BBOX_X0 && n + ((read_cnt - 1) % 7) <= BBOX_X1) begin
                                P[(read_cnt - 1) / 7][(read_cnt - 1) % 7] <= douta_input_bb;
                            end else begin
                                P[(read_cnt - 1) / 7][(read_cnt - 1) % 7] <= 8'd0;
                            end
                        end
                        read_cnt <= read_cnt + 1;
                    end else begin
                        // Latch final pixel (read_cnt = 20: row = m+2, col = n+6)
                        last_row = m + 2;
                        last_col = n + 6;
                        if (last_row >= 0 && last_row < 256 && last_col >= 0 && last_col < 256) begin
                            p[2][6] <= douta_input;
                        end else begin
                            p[2][6] <= 8'd0;
                        end
                        if (last_row >= BBOX_Y0 && last_row <= BBOX_Y1 && last_col >= BBOX_X0 && last_col <= BBOX_X1) begin
                            P[2][6] <= douta_input_bb;
                        end else begin
                            P[2][6] <= 8'd0;
                        end
                        read_cnt <= 5'd0;
                        ena_input <= 1'b0;
                        state <= START_COMPUTE;
                    end
                end

                START_COMPUTE: begin
                    start_bg <= 1'b1;
                    start_bb <= 1'b1;
                    done_bg_flag <= 1'b0;
                    done_bb_flag <= 1'b0;
                    state <= WAIT_COMPUTE;
                end

                WAIT_COMPUTE: begin
                    if (done_bg) done_bg_flag <= 1'b1;
                    if (done_bb) done_bb_flag <= 1'b1;
                    if (done_bg_flag && done_bb_flag) begin
                        write_cnt <= 3'd0;
                        state <= WRITE_OUTPUT;
                    end
                end

                WRITE_OUTPUT: begin
                    if (write_cnt < 5) begin
                        pixel_row = m + 1;
                        pixel_col = n + write_cnt + 1;
                        // Write to bounding box BRAM if within bounds
                        if (pixel_row >= BBOX_Y0 && pixel_row <= BBOX_Y1 && 
                            pixel_col >= BBOX_X0 && pixel_col <= BBOX_X1) begin
                            addra_output_bb <= (pixel_row - BBOX_Y0) * BBOX_WIDTH + (pixel_col - BBOX_X0);
                            dina_output_bb <= edge_out_bb[write_cnt];
                            wea_output_bb <= 1'b1;
                            ena_output_bb <= 1'b1;
                        end
                        // Write to background BRAM if outside bounding box
                        else if (pixel_row >= 0 && pixel_row < 256 && pixel_col >= 0 && pixel_col < 256) begin
                            addra_output <= pixel_row * 16'd256 + pixel_col;
                            dina_output <= edge_out[write_cnt];
                            wea_output <= 1'b1;
                            ena_output <= 1'b1;
                        end
                        write_cnt <= write_cnt + 1;
                    end else begin
                        if (n < 250) begin // Process up to n=250 (pixels 251-255)
                            n <= n + 5;
                            state <= READ_PIXELS;
                        end else if (m < 254) begin // Process up to row 254
                            m <= m + 1;
                            n <= 0;
                            state <= READ_PIXELS;
                        end else begin
                            done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule