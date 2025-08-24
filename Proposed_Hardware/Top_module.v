(* DONT_TOUCH = "yes" *)
module sobel_edge_detector #(
    parameter IMG_WIDTH   = 83,
    parameter IMG_HEIGHT  = 42,
    parameter BBOX_X0     = 106,
    parameter BBOX_Y0     = 127,
    parameter BBOX_X1     = 189,
    parameter BBOX_Y1     = 169
)(
    input  wire        clka,
    input  wire        reset,
    input  [5:0] error_bck,
    input  [5:0] error_bb,
    output reg         done,
    // Background image BRAM signals (Port A)
    output wire        ena_output,
    output wire        wea_output,
    output wire [15:0] addra_output,
    output wire [7:0]  dina_output,
    // Background image BRAM signals (Port B)
    output wire        enb_output,
    output wire        web_output,
    output wire [15:0] addrb_output,
    output wire [7:0]  dinb_output,
    // Bounding box image BRAM signals (Port A)
    output wire        ena_output_bb,
    output wire        wea_output_bb,
    output wire [11:0] addra_output_bb,
    output wire [7:0]  dina_output_bb,
    // Bounding box image BRAM signals (Port B)
    output wire        enb_output_bb,
    output wire        web_output_bb,
    output wire [11:0] addrb_output_bb,
    output wire [7:0]  dinb_output_bb
);

    // Full image dimensions (assumed for background)
    localparam FULL_WIDTH  = 256;
    localparam FULL_HEIGHT = 256;

    // BRAM signals for background
    wire        ena_bck, enb_bck, wea_bck, web_bck;
    wire [15:0] addra_bck, addrb_bck;
    wire [7:0]  dina_bck, dinb_bck, douta_bck, doutb_bck;
    blk_mem_read read_bck (
        .clka(clka), .ena(ena_bck), .wea(1'b0), .addra(addra_bck), .dina(dina_bck), .douta(douta_bck),
        .clkb(clka), .enb(enb_bck), .web(1'b0), .addrb(addrb_bck), .dinb(dinb_bck), .doutb(doutb_bck)
    );

    wire        ena_write_bck, enb_write_bck, wea_write_bck, web_write_bck;
    wire [15:0] addra_write_bck, addrb_write_bck;
    wire [7:0]  dina_write_bck, dinb_write_bck, douta_write_bck, doutb_write_bck;
    blk_mem_write write_bck (
        .clka(clka), .ena(ena_write_bck), .wea(wea_write_bck), .addra(addra_write_bck), .dina(dina_write_bck), .douta(douta_write_bck),
        .clkb(clka), .enb(enb_write_bck), .web(web_write_bck), .addrb(addrb_write_bck), .dinb(dinb_write_bck), .doutb(doutb_write_bck)
    );

    // BRAM signals for bounding box
    wire        ena_bb, enb_bb, wea_bb, web_bb;
    wire [11:0] addra_bb, addrb_bb;
    wire [7:0]  dina_bb, dinb_bb, douta_bb, doutb_bb;
    blk_mem_read_bb read_bb (
        .clka(clka), .ena(ena_bb), .wea(1'b0), .addra(addra_bb), .dina(dina_bb), .douta(douta_bb),
        .clkb(clka), .enb(enb_bb), .web(1'b0), .addrb(addrb_bb), .dinb(dinb_bb), .doutb(doutb_bb)
    );

    wire        ena_write_bb, enb_write_bb, wea_write_bb, web_write_bb;
    wire [11:0] addra_write_bb, addrb_write_bb;
    wire [7:0]  dina_write_bb, dinb_write_bb, douta_write_bb, doutb_write_bb;
    blk_mem_write_bb write_bb (
        .clka(clka), .ena(ena_write_bb), .wea(wea_write_bb), .addra(addra_write_bb), .dina(dina_write_bb), .douta(douta_write_bb),
        .clkb(clka), .enb(enb_write_bb), .web(web_write_bb), .addrb(addrb_write_bb), .dinb(dinb_write_bb), .doutb(doutb_write_bb)
    );

    // FSM done signals
    wire done_bck, done_bb;

    // FSM for background processing
    fsm_bck fsm_bck_inst (
        .clka(clka),
        .reset(reset),
        .error(error_bck),
        .read_ena(ena_bck),
        .read_enb(enb_bck),
        .read_addra(addra_bck),
        .read_addrb(addrb_bck),
        .read_douta(douta_bck),
        .read_doutb(doutb_bck),
        .write_ena(ena_write_bck),
        .write_enb(enb_write_bck),
        .write_wea(wea_write_bck),
        .write_web(web_write_bck),
        .write_addra(addra_write_bck),
        .write_addrb(addrb_write_bck),
        .write_dina(dina_write_bck),
        .write_dinb(dinb_write_bck),
        .done(done_bck)
    );

    // FSM for bounding box processing
    fsm_bb fsm_bb_inst (
        .clka(clka),
        .reset(reset),
        .error(error_bb),
        .read_ena(ena_bb),
        .read_enb(enb_bb),
        .read_addra(addra_bb),
        .read_addrb(addrb_bb),
        .read_douta(douta_bb),
        .read_doutb(doutb_bb),
        .write_ena(ena_write_bb),
        .write_enb(enb_write_bb),
        .write_wea(wea_write_bb),
        .write_web(web_write_bb),
        .write_addra(addra_write_bb),
        .write_addrb(addrb_write_bb),
        .write_dina(dina_write_bb),
        .write_dinb(dinb_write_bb),
        .done(done_bb)
    );

    // Set top-level done when both FSMs complete
    always @(posedge clka) begin
        if (reset) done <= 0;
        else if (done_bck & done_bb) done <= 1;
    end
    
        // Assign BRAM write signals to outputs (Background)
    assign ena_output   = ena_write_bck;
    assign wea_output   = wea_write_bck;
    assign addra_output = addra_write_bck;
    assign dina_output  = dina_write_bck;
    assign enb_output   = enb_write_bck;
    assign web_output   = web_write_bck;
    assign addrb_output = addrb_write_bck;
    assign dinb_output  = dinb_write_bck;

    // Assign BRAM write signals to outputs (Bounding Box)
    assign ena_output_bb   = ena_write_bb;
    assign wea_output_bb   = wea_write_bb;
    assign addra_output_bb = addra_write_bb;
    assign dina_output_bb  = dina_write_bb;
    assign enb_output_bb   = enb_write_bb;
    assign web_output_bb   = web_write_bb;
    assign addrb_output_bb = addrb_write_bb;
    assign dinb_output_bb  = dinb_write_bb;

endmodule

// FSM for Background (256x256 image)
module fsm_bck (
    input clka,
    input reset,
    input [5:0] error,
    input [7:0] read_douta,
    input [7:0] read_doutb,
    output reg read_ena,
    output reg read_enb,
    output reg [15:0] read_addra,
    output reg [15:0] read_addrb,
    output reg write_ena,
    output reg write_enb,
    output reg write_wea,
    output reg write_web,
    output reg [15:0] write_addra,
    output reg [15:0] write_addrb,
    output reg [7:0] write_dina,
    output reg [7:0] write_dinb,
    output reg done
);
    parameter WIDTH = 256;
    parameter HEIGHT = 256;

    // State encoding
    parameter IDLE = 3'd0, READ_WINDOW = 3'd1, PROCESS = 3'd2, WRITE = 3'd3, DONE = 3'd4;
    reg [2:0] state, next_state;

    // Counters and registers
    reg [7:0] row;
    reg [5:0] chunk;
    reg [3:0] read_count;
    reg [2:0] write_count;
    reg [7:0] window_buf0 [0:20];

    // Core Sobel signals
    reg sobel_start;
    wire sobel_done;
    wire [7:0] sobel_out [0:4];

    // Sobel core instantiation
    core_sobel sobel_inst (
        .clka(clka),
        .reset(reset),
        .start(sobel_start),
        .p_0(window_buf0[0]), .p_1(window_buf0[1]), .p_2(window_buf0[2]), .p_3(window_buf0[3]),
        .p_4(window_buf0[4]), .p_5(window_buf0[5]), .p_6(window_buf0[6]), .p_7(window_buf0[7]),
        .p_8(window_buf0[8]), .p_9(window_buf0[9]), .p_10(window_buf0[10]), .p_11(window_buf0[11]),
        .p_12(window_buf0[12]), .p_13(window_buf0[13]), .p_14(window_buf0[14]), .p_15(window_buf0[15]),
        .p_16(window_buf0[16]), .p_17(window_buf0[17]), .p_18(window_buf0[18]), .p_19(window_buf0[19]),
        .p_20(window_buf0[20]),
        .error(error),
        .out_0(sobel_out[0]), .out_1(sobel_out[1]), .out_2(sobel_out[2]), .out_3(sobel_out[3]),
        .out_4(sobel_out[4]),
        .done(sobel_done)
    );

    // Temporary registers for address calculations
    reg [7:0] j;              // chunk * 5, max 49*5=245 < 256
    reg signed [9:0] r;       // row-1 to row+1, -1 to 256, needs 10-bit signed
    reg [7:0] c;              // j + (read_count % 4) * 2, max 251 < 256
    reg [15:0] addr_a, addr_b; // r * WIDTH + c, max 65531 < 65536
    reg [15:0] base_addr;     // row * WIDTH + chunk * 5 + 1, max 65526 < 65536

    integer i;

    // Sequential state machine
    always @(posedge clka or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            row <= 0;
            chunk <= 0;
            read_count <= 0;
            write_count <= 0;
            read_ena <= 0;
            read_enb <= 0;
            write_ena <= 0;
            write_enb <= 0;
            write_wea <= 0;
            write_web <= 0;
            sobel_start <= 0;
            done <= 0;
            for (i = 0; i < 21; i = i + 1) begin
                window_buf0[i] <= 0;
            end
        end else begin
            state <= next_state;
        end
    end

    // Combinational next-state and output logic
    always @(posedge clka) begin
        case (state)
            IDLE: begin
                next_state <= READ_WINDOW;
                read_ena <= 1;
                read_enb <= 1;
            end
            READ_WINDOW: begin
                if (read_count < 11) begin
                    j = chunk * 5;
                    r = (read_count < 3) ? $signed({1'b0, row}) - 1 :
                        (read_count < 7) ? $signed({1'b0, row}) : $signed({1'b0, row}) + 1;
                    c = j + (read_count[1:0] << 1); // Optimized: (read_count % 4) * 2
                    addr_a = (r < 0 || r >= HEIGHT) ? 0 : (r * WIDTH + c);
                    addr_b = (r < 0 || r >= HEIGHT) ? 0 : (r * WIDTH + c + 1);
                    read_addra <= addr_a < (WIDTH * HEIGHT) ? addr_a : 0;
                    read_addrb <= addr_b < (WIDTH * HEIGHT) ? addr_b : 0;
                    if (read_count > 0) begin
                        window_buf0[(read_count-1)*2] <= (r < 0 || r >= HEIGHT) ? 0 : read_douta;
                        window_buf0[(read_count-1)*2 + 1] <= (r < 0 || r >= HEIGHT) ? 0 : read_doutb;
                    end
                    read_count <= read_count + 1;
                end else begin
                    window_buf0[20] <= (row + 1 >= HEIGHT || j + 6 >= WIDTH) ? 0 : read_doutb;
                    read_ena <= 0;
                    read_enb <= 0;
                    read_count <= 0;
                    next_state <= PROCESS;
                    sobel_start <= 1;
                end
            end
            PROCESS: begin
                sobel_start <= 0;
                if (sobel_done) begin
                    next_state <= WRITE;
                    write_ena <= 1;
                    write_enb <= 1;
                    write_wea <= 1;
                    write_web <= 1;
                end
            end
            WRITE: begin
                if (write_count < 3) begin
                    base_addr = row * WIDTH + chunk * 5 + 1;
                    write_addra <= base_addr + write_count * 2;
                    write_addrb <= base_addr + write_count * 2 + 1;
                    write_dina <= (write_count == 2) ? sobel_out[4] : sobel_out[write_count * 2];
                    write_dinb <= (write_count == 2) ? 0 : sobel_out[write_count * 2 + 1];
                    write_count <= write_count + 1;
                end else begin
                    write_ena <= 0;
                    write_enb <= 0;
                    write_wea <= 0;
                    write_web <= 0;
                    write_count <= 0;
                    if (chunk == 49 && row == 255) begin
                        next_state <= DONE;
                    end else if (chunk == 49) begin
                        chunk <= 0;
                        row <= row + 1;
                        next_state <= READ_WINDOW;
                        read_ena <= 1;
                        read_enb <= 1;
                    end else begin
                        chunk <= chunk + 1;
                        next_state <= READ_WINDOW;
                        read_ena <= 1;
                        read_enb <= 1;
                    end
                end
            end
            DONE: begin
                done <= 1;
                next_state <= IDLE;
            end
            default: begin
                next_state <= IDLE;
            end
        endcase
    end
endmodule

// FSM for Bounding Box (83x42 image)
module fsm_bb (
    input clka,
    input reset,
    input [5:0] error,
    input [7:0] read_douta,
    input [7:0] read_doutb,
    output reg read_ena,
    output reg read_enb,
    output reg [11:0] read_addra,
    output reg [11:0] read_addrb,
    output reg write_ena,
    output reg write_enb,
    output reg write_wea,
    output reg write_web,
    output reg [11:0] write_addra,
    output reg [11:0] write_addrb,
    output reg [7:0] write_dina,
    output reg [7:0] write_dinb,
    output reg done
);
    parameter WIDTH = 83;
    parameter HEIGHT = 42;

    // State encoding
    parameter IDLE = 3'd0, READ_WINDOW = 3'd1, PROCESS = 3'd2, WRITE = 3'd3, DONE = 3'd4;
    reg [2:0] state, next_state;

    // Counters and registers
    reg [5:0] row;
    reg [4:0] chunk;
    reg [3:0] read_count;
    reg [2:0] write_count;
    reg [7:0] window_buf0 [0:20];

    // Core Sobel signals
    reg sobel_start;
    wire sobel_done;
    wire [7:0] sobel_out [0:4];

    // Sobel core instantiation
    core_sobel1 sobel_inst1 (
        .clka(clka),
        .reset(reset),
        .start(sobel_start),
        .p_0(window_buf0[0]), .p_1(window_buf0[1]), .p_2(window_buf0[2]), .p_3(window_buf0[3]),
        .p_4(window_buf0[4]), .p_5(window_buf0[5]), .p_6(window_buf0[6]), .p_7(window_buf0[7]),
        .p_8(window_buf0[8]), .p_9(window_buf0[9]), .p_10(window_buf0[10]), .p_11(window_buf0[11]),
        .p_12(window_buf0[12]), .p_13(window_buf0[13]), .p_14(window_buf0[14]), .p_15(window_buf0[15]),
        .p_16(window_buf0[16]), .p_17(window_buf0[17]), .p_18(window_buf0[18]), .p_19(window_buf0[19]),
        .p_20(window_buf0[20]),
        .error(error),
        .out_0(sobel_out[0]), .out_1(sobel_out[1]), .out_2(sobel_out[2]), .out_3(sobel_out[3]),
        .out_4(sobel_out[4]),
        .done(sobel_done)
    );

    // Temporary registers for address calculations
    reg [6:0] j;              // chunk * 5, max 15*5=75 < 128
    reg signed [6:0] r;       // row-1 to row+1, -1 to 42, needs 7-bit signed
    reg [6:0] c;              // j + (read_count % 4) * 2, max 81 < 128
    reg [11:0] addr_a, addr_b; // r * WIDTH + c, max 3484 < 4096
    reg [11:0] base_addr;     // row * WIDTH + chunk * 5 + 1, max 3479 < 4096

    integer i;

    // Sequential state machine
    always @(posedge clka or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            row <= 0;
            chunk <= 0;
            read_count <= 0;
            write_count <= 0;
            read_ena <= 0;
            read_enb <= 0;
            write_ena <= 0;
            write_enb <= 0;
            write_wea <= 0;
            write_web <= 0;
            sobel_start <= 0;
            done <= 0;
            for (i = 0; i < 21; i = i + 1) begin
                window_buf0[i] <= 0;
            end
        end else begin
            state <= next_state;
        end
    end

    // Combinational next-state and output logic
    always @(posedge clka) begin
        case (state)
            IDLE: begin
                next_state <= READ_WINDOW;
                read_ena <= 1;
                read_enb <= 1;
            end
            READ_WINDOW: begin
                if (read_count < 11) begin
                    j = chunk * 5;
                    r = (read_count < 3) ? $signed({1'b0, row}) - 1 :
                        (read_count < 7) ? $signed({1'b0, row}) : $signed({1'b0, row}) + 1;
                    c = j + (read_count[1:0] << 1); // Optimized: (read_count % 4) * 2
                    addr_a = (r < 0 || r >= HEIGHT) ? 0 : (r * WIDTH + c);
                    addr_b = (r < 0 || r >= HEIGHT) ? 0 : (r * WIDTH + c + 1);
                    read_addra <= addr_a < (WIDTH * HEIGHT) ? addr_a : 0;
                    read_addrb <= addr_b < (WIDTH * HEIGHT) ? addr_b : 0;
                    if (read_count > 0) begin
                        window_buf0[(read_count-1)*2] <= (r < 0 || r >= HEIGHT) ? 0 : read_douta;
                        window_buf0[(read_count-1)*2 + 1] <= (r < 0 || r >= HEIGHT) ? 0 : read_doutb;
                    end
                    read_count <= read_count + 1;
                end else begin
                    window_buf0[20] <= (row + 1 >= HEIGHT || j + 6 >= WIDTH) ? 0 : read_doutb;
                    read_ena <= 0;
                    read_enb <= 0;
                    read_count <= 0;
                    next_state <= PROCESS;
                    sobel_start <= 1;
                end
            end
            PROCESS: begin
                sobel_start <= 0;
                if (sobel_done) begin
                    next_state <= WRITE;
                    write_ena <= 1;
                    write_enb <= 1;
                    write_wea <= 1;
                    write_web <= 1;
                end
            end
            WRITE: begin
                if (write_count < 3) begin
                    base_addr = row * WIDTH + chunk * 5 + 1;
                    write_addra <= base_addr + write_count * 2;
                    write_addrb <= base_addr + write_count * 2 + 1;
                    write_dina <= (write_count == 2) ? sobel_out[4] : sobel_out[write_count * 2];
                    write_dinb <= (write_count == 2) ? 0 : sobel_out[write_count * 2 + 1];
                    write_count <= write_count + 1;
                end else begin
                    write_ena <= 0;
                    write_enb <= 0;
                    write_wea <= 0;
                    write_web <= 0;
                    write_count <= 0;
                    if (chunk == 15 && row == 41) begin
                        next_state <= DONE;
                    end else if (chunk == 15) begin
                        chunk <= 0;
                        row <= row + 1;
                        next_state <= READ_WINDOW;
                        read_ena <= 1;
                        read_enb <= 1;
                    end else begin
                        chunk <= chunk + 1;
                        next_state <= READ_WINDOW;
                        read_ena <= 1;
                        read_enb <= 1;
                    end
                end
            end
            DONE: begin
                done <= 1;
                next_state <= IDLE;
            end
            default: begin
                next_state <= IDLE;
            end
        endcase
    end
endmodule