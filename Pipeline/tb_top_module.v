`timescale 1ns/1ps

module tb_sobel_edge_detector;

  //---------------------------------------------
  // Parameters for both images
  //---------------------------------------------
  localparam IMG_W        = 256;  // Background image width
  localparam IMG_H        = 256;  // Background image height
  localparam IMG_PIXELS   = IMG_W * IMG_H;

  localparam IMG_W_BB     = 192;  // Bounding box image width
  localparam IMG_H_BB     = 251;  // Bounding box image height
  localparam IMG_PIXELS_BB= IMG_W_BB * IMG_H_BB;

  //---------------------------------------------
  // Clock, reset, done
  //---------------------------------------------
  reg   clka     = 0;
  reg   reset    = 1;
  wire  done;

  //---------------------------------------------
  // Loop index for initialization
  //---------------------------------------------
  integer i;

  // Clock generation (40 MHz)
  initial forever #12.5 clka = ~clka;

  //---------------------------------------------
  // Error inputs
  //---------------------------------------------
  reg [5:0] error_bck = 6'd33;
  reg [5:0] error_bb  = 6'd7;

  //---------------------------------------------
  // DUT instantiation
  //---------------------------------------------
  sobel_edge_detector #(
      .IMG_WIDTH(IMG_W_BB),
      .IMG_HEIGHT(IMG_H_BB),
      .BBOX_X0(0),
      .BBOX_Y0(2),
      .BBOX_X1(184),
      .BBOX_Y1(252)
  ) dut (
      .clka       (clka),
      .reset      (reset),
      .error_bck  (error_bck),
      .error_bb   (error_bb),
      .done       (done)
  );

  //---------------------------------------------
  // Release reset
  //---------------------------------------------
  initial begin
      #100;
      reset = 0;
  end

  //---------------------------------------------
  // TB-side shadow memory for output BRAM (256×256)
  //---------------------------------------------
  reg [7:0] tb_mem [0:IMG_PIXELS-1];
  always @(posedge clka) begin
      if (dut.ena_output && dut.wea_output) begin
          tb_mem[dut.addra_output] <= dut.dina_output;
      end
  end

  //---------------------------------------------
  // TB-side shadow memory for output BRAM (192×251)
  //---------------------------------------------
  reg [7:0] tb_mem_bb [0:IMG_PIXELS_BB-1];
  always @(posedge clka) begin
      if (dut.ena_output_bb && dut.wea_output_bb) begin
          tb_mem_bb[dut.addra_output_bb] <= dut.dina_output_bb;
      end
  end

  //---------------------------------------------
  // Initialize shadow memory to avoid undefined 'x'
  //---------------------------------------------
  initial begin
      for (i = 0; i < IMG_PIXELS;      i = i + 1)
          tb_mem[i]    = 8'd0;
      for (i = 0; i < IMG_PIXELS_BB;   i = i + 1)
          tb_mem_bb[i] = 8'd0;
  end

  //---------------------------------------------
  // Dump VCD for waveform viewing
  //---------------------------------------------
  initial begin
      $dumpfile("tb_sobel.vcd");
      $dumpvars(0, tb_sobel_edge_detector);
  end

  //---------------------------------------------
  // Finish simulation and dump memory
  //---------------------------------------------
  initial begin
      wait (done);
      #20;  // Allow final writes

      $display("TB: DONE asserted -- dumping images");
      $writememh("output_image_256x256_neural_pipeline.hex", tb_mem,    0, IMG_PIXELS-1);
      $writememh("output_image_192x251_neural_pipeline.hex", tb_mem_bb, 0, IMG_PIXELS_BB-1);
      $display("TB: Dump complete -- finishing simulation.");

      $finish;
  end

endmodule
