`timescale 1ns/1ps

module tb_sobel_edge_detector;

  // Parameters for background image (256x256)
  localparam IMG_W        = 256;  
  localparam IMG_H        = 256;  
  localparam IMG_PIXELS   = IMG_W * IMG_H;

  // Parameters for bounding box image (83x42)
  localparam IMG_W_BB     = 83;   
  localparam IMG_H_BB     = 42;   
  localparam IMG_PIXELS_BB= IMG_W_BB * IMG_H_BB;

  // Clock, reset, and done signals
  reg   clka     = 0;
  reg   reset    = 1;
  wire  done;

  // BRAM write signals for background image (Port A)
  wire        ena_output;
  wire        wea_output;
  wire [15:0] addra_output;
  wire [7:0]  dina_output;

  // BRAM write signals for background image (Port B)
  wire        enb_output;
  wire        web_output;
  wire [15:0] addrb_output;
  wire [7:0]  dinb_output;

  // BRAM write signals for bounding box image (Port A)
  wire        ena_output_bb;
  wire        wea_output_bb;
  wire [11:0] addra_output_bb;
  wire [7:0]  dina_output_bb;

  // BRAM write signals for bounding box image (Port B)
  wire        enb_output_bb;
  wire        web_output_bb;
  wire [11:0] addrb_output_bb;
  wire [7:0]  dinb_output_bb;

  // Loop index for memory initialization
  integer i;

  // Clock generation (40 MHz, period = 25 ns)
  initial forever #2.5 clka = ~clka;

  // Error inputs for the DUT
  reg [5:0] error_bck = 6'd33;  // Example error value for background
  reg [5:0] error_bb  = 6'd7;   // Example error value for bounding box

  // DUT instantiation
  sobel_edge_detector #(
      .IMG_WIDTH(IMG_W_BB),
      .IMG_HEIGHT(IMG_H_BB),
      .BBOX_X0(106),
      .BBOX_Y0(127),
      .BBOX_X1(189),
      .BBOX_Y1(169)
  ) dut (
      .clka           (clka),
      .reset          (reset),
      .error_bck      (error_bck),
      .error_bb       (error_bb),
      .done           (done),
      .ena_output     (ena_output),
      .wea_output     (wea_output),
      .addra_output   (addra_output),
      .dina_output    (dina_output),
      .enb_output     (enb_output),
      .web_output     (web_output),
      .addrb_output   (addrb_output),
      .dinb_output    (dinb_output),
      .ena_output_bb  (ena_output_bb),
      .wea_output_bb  (wea_output_bb),
      .addra_output_bb(addra_output_bb),
      .dina_output_bb (dina_output_bb),
      .enb_output_bb  (enb_output_bb),
      .web_output_bb  (web_output_bb),
      .addrb_output_bb(addrb_output_bb),
      .dinb_output_bb (dinb_output_bb)
  );

  // Release reset after initial delay
  initial begin
      #100;
      reset = 0;
  end

  // Shadow memory for background image (256x256)
  reg [7:0] tb_mem [0:IMG_PIXELS-1];
  always @(posedge clka) begin
      if (ena_output && wea_output) begin
          tb_mem[addra_output] <= dina_output;
      end
      if (enb_output && web_output) begin
          tb_mem[addrb_output] <= dinb_output;
      end
  end

  // Shadow memory for bounding box image (83x42)
  reg [7:0] tb_mem_bb [0:IMG_PIXELS_BB-1];
  always @(posedge clka) begin
      if (ena_output_bb && wea_output_bb) begin
          tb_mem_bb[addra_output_bb] <= dina_output_bb;
      end
      if (enb_output_bb && web_output_bb) begin
          tb_mem_bb[addrb_output_bb] <= dinb_output_bb;
      end
  end

  // Initialize shadow memories to zero
  initial begin
      for (i = 0; i < IMG_PIXELS; i = i + 1)
          tb_mem[i] = 8'd0;
      for (i = 0; i < IMG_PIXELS_BB; i = i + 1)
          tb_mem_bb[i] = 8'd0;
  end

  // Dump VCD file for waveform debugging
  initial begin
      $dumpfile("tb_sobel.vcd");
      $dumpvars(0, tb_sobel_edge_detector);
  end

  // Simulation control: wait for done, dump memory, and finish
  initial begin
      wait (done);
      #20;  // Allow final writes to complete
      $display("TB: DONE asserted -- dumping images");
      $writememh("out_bg_dual_256x256.hex", tb_mem, 0, IMG_PIXELS-1);
      $writememh("out_bb_dual_83x42.hex", tb_mem_bb, 0, IMG_PIXELS_BB-1);
      $display("TB: Dump complete -- finishing simulation.");
      $finish;
  end

endmodule