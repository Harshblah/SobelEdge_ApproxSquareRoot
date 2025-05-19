`timescale 1ns/1ps
(* DONT_TOUCH = "yes" *)
module sobel_edge_detector #(
    parameter IMG_WIDTH  = 192,  // Width of smaller image
    parameter IMG_HEIGHT = 251   // Height of smaller image
) (
    input  wire        clka,
    input  wire        reset,
    output reg         done
);

    //----------------------------------------------------------------------  
    // BRAM interfaces  
    //----------------------------------------------------------------------  
    wire [7:0]  douta_input;
    reg  [15:0] addra_input;
    reg         ena_input;
    
    (* DONT_TOUCH = "yes" *) blk_mem_read input_bram (
        .clka(clka),
        .ena(ena_input),
        .wea(1'b0),
        .addra(addra_input),
        .dina(8'b0),
        .douta(douta_input)
    );
    
    wire [7:0]  douta_input_bb;
    reg  [15:0] addra_input_bb;  // Increased to 16 bits
    
    (* DONT_TOUCH = "yes" *) blk_mem_read1 input_bram_bb (
        .clka(clka),
        .ena(ena_input),
        .wea(1'b0),
        .addra(addra_input_bb),
        .dina(8'b0),
        .douta(douta_input_bb)
    );
    
    reg  [15:0] addra_output;
    reg  [7:0]  dina_output;
    reg         wea_output;
    reg         ena_output;
   
    (* DONT_TOUCH = "yes" *) blk_mem_write output_bram (
        .clka(clka),
        .ena(ena_output),
        .wea(wea_output),
        .addra(addra_output),
        .dina(dina_output),
        .douta()
    );
    
    reg  [15:0] addra_output_bb;  // Increased to 16 bits
    reg  [7:0]  dina_output_bb;
    reg         ena_output_bb;
    reg         wea_output_bb;
    
    (* DONT_TOUCH = "yes" *) blk_mem_write1 output_bram_bb (
        .clka(clka),
        .ena(ena_output_bb),
        .wea(wea_output_bb),
        .addra(addra_output_bb),
        .dina(dina_output_bb),
        .douta()
    );

    //----------------------------------------------------------------------  
    // 3×3 patch registers  
    //----------------------------------------------------------------------  
    reg [7:0] p00, p01, p02;
    reg [7:0] p10, p11, p12;
    reg [7:0] p20, p21, p22;

    //----------------------------------------------------------------------  
    // Sobel-core instantiation  
    //----------------------------------------------------------------------  
    wire [7:0] edge_out;
    (* DONT_TOUCH = "yes" *) core_sobel core_sobel_inst (
        .p0 (p00), .p1 (p01), .p2 (p02),
        .p3 (p10),           .p5 (p12),
        .p6 (p20), .p7 (p21), .p8 (p22),
        .out(edge_out)
    );
    
    reg [7:0] P00, P01, P02;
    reg [7:0] P10, P11, P12;
    reg [7:0] P20, P21, P22;
    wire [7:0] edge_out_bb;
    (* DONT_TOUCH = "yes" *) core_sobel1 core_sobel_inst1 (
        .p0(P00), .p1(P01), .p2(P02),
        .p3(P10),           .p5(P12),
        .p6(P20), .p7(P21), .p8(P22),
        .out(edge_out_bb)
    );

    //----------------------------------------------------------------------  
    // FSM states  
    //----------------------------------------------------------------------  
    localparam 
        IDLE          = 3'd0,
        READ_PIXELS   = 3'd1,
        WAIT_COMPUTE  = 3'd2,
        WRITE_OUTPUT  = 3'd3,
        WAIT_WRITE    = 3'd4;

    reg [2:0] state;
    reg [3:0] read_cnt;
    reg [7:0] m, n;

    //----------------------------------------------------------------------  
    // Cycle counter  
    //----------------------------------------------------------------------  
    reg [31:0] cycle_counter;
    reg        counting;

    //----------------------------------------------------------------------  
    // Main FSM + cycle counting  
    //----------------------------------------------------------------------  
    always @(posedge clka or posedge reset) begin
        if (reset) begin
            // Reset all state & regs
            state         <= IDLE;
            done          <= 1'b0;
            m             <= 8'd0;
            n             <= 8'd0;
            read_cnt      <= 4'd0;
            addra_input   <= 16'd0;
            addra_input_bb<= 16'd0;  // Updated to 16 bits
            addra_output  <= 16'd0;
            addra_output_bb <= 16'd0;  // Updated to 16 bits
            dina_output   <= 8'd0;
            dina_output_bb<= 8'd0;
            ena_input     <= 1'b0;
            wea_output    <= 1'b0;
            wea_output_bb <= 1'b0;
            ena_output    <= 1'b0;
            ena_output_bb <= 1'b0;
            p00 <= 0; p01 <= 0; p02 <= 0;
            p10 <= 0; p11 <= 0; p12 <= 0;
            p20 <= 0; p21 <= 0; p22 <= 0;
            P00 <= 0; P01 <= 0; P02 <= 0;
            P10 <= 0; P11 <= 0; P12 <= 0;
            P20 <= 0; P21 <= 0; P22 <= 0;
            // Reset cycle counter
            cycle_counter <= 32'd0;
            counting      <= 1'b0;
        end else begin
            // Cycle counting
            if (!counting && state != IDLE) counting <= 1'b1;
            if (counting && !done) cycle_counter <= cycle_counter + 1;
            if (done) counting <= 1'b0;

            case (state)
                IDLE: begin
                    done     <= 1'b0;
                    m        <= 8'd0;
                    n        <= 8'd0;
                    read_cnt <= 4'd0;
                    ena_input     <= 1'b0;
                    wea_output    <= 1'b0;
                    wea_output_bb <= 1'b0;
                    ena_output    <= 1'b0;
                    ena_output_bb <= 1'b0;
                    state    <= READ_PIXELS;
                end

                READ_PIXELS: begin
                    if (read_cnt < 4'd9) begin
                        // Issue BRAM read
                        ena_input   <= 1'b1;
                        addra_input <= (m + (read_cnt/3)) * 16'd256 + (n + (read_cnt%3));
                        if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) begin
                            addra_input_bb <= (m + (read_cnt/3)) * IMG_WIDTH + (n + (read_cnt%3));
                        end else begin
                            addra_input_bb <= 16'd0;  // Updated to 16 bits
                        end
                        // Latch previous cycle's data
                        if (read_cnt > 0) begin
                            case (read_cnt - 1)
                                4'd0: begin
                                    p00 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P00 <= douta_input_bb;
                                end
                                4'd1: begin
                                    p01 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P01 <= douta_input_bb;
                                end
                                4'd2: begin
                                    p02 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P02 <= douta_input_bb;
                                end
                                4'd3: begin
                                    p10 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P10 <= douta_input_bb;
                                end
                                4'd4: begin
                                    p11 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P11 <= douta_input_bb;
                                end
                                4'd5: begin
                                    p12 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P12 <= douta_input_bb;
                                end
                                4'd6: begin
                                    p20 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P20 <= douta_input_bb;
                                end
                                4'd7: begin
                                    p21 <= douta_input;
                                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P21 <= douta_input_bb;
                                end
                            endcase
                        end
                        read_cnt <= read_cnt + 1;
                    end else begin
                        // 9th pixel
                        p22 <= douta_input;
                        if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) P22 <= douta_input_bb;
                        read_cnt <= 4'd0;
                        ena_input <= 1'b0;
                        state    <= WAIT_COMPUTE;
                    end
                end

                WAIT_COMPUTE: begin
                    // Set up the output data for both BRAMs
                    addra_output <= (m + 1) * 16'd256 + (n + 1);
                    dina_output  <= edge_out;
                    addra_output_bb <= (m + 1) * IMG_WIDTH + (n + 1);
                    dina_output_bb  <= edge_out_bb;
                    state <= WRITE_OUTPUT;
                end

                WRITE_OUTPUT: begin
                    // Write to first image (256x256)
                    wea_output   <= 1'b1;
                    ena_output   <= 1'b1;
                    state        <= WAIT_WRITE;
                end

                WAIT_WRITE: begin
                    // Disable write to first image
                    wea_output   <= 1'b0;
                    ena_output   <= 1'b0;

                    // Write to second image (179x196) if within bounds
                    if (m < (IMG_HEIGHT-2) && n < (IMG_WIDTH-2)) begin
                        wea_output_bb <= 1'b1;
                        ena_output_bb <= 1'b1;
                    end else begin
                        wea_output_bb <= 1'b0;
                        ena_output_bb <= 1'b0;
                    end

                    // Advance indices
                    if (n < 8'd253) begin
                        n     <= n + 8'd1;
                        state <= READ_PIXELS;
                    end else if (m < 8'd253) begin
                        m     <= m + 8'd1;
                        n     <= 8'd0;
                        state <= READ_PIXELS;
                    end else begin
                        done  <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: begin
                    state         <= IDLE;
                    ena_input     <= 1'b0;
                    wea_output    <= 1'b0;
                    wea_output_bb <= 1'b0;
                    ena_output    <= 1'b0;
                    ena_output_bb <= 1'b0;
                end
            endcase
        end
    end

endmodule