`timescale 1ns / 1ps

module squareroot_MAHSQR_tb;

    // Inputs
    reg [15:0] R;

    // Outputs
    wire [7:0] final_op;

    // Instantiate the Unit Under Test (UUT)
    squareroot_MAHSQR_k4 uut (
        .R(R),
        .final_op(final_op)
    );

    initial begin
        // Initialize waveform generation for GTKWave
        $dumpfile("squareroot_MAHSQR_tb.vcd"); // Name of the VCD file
        $dumpvars(0, squareroot_MAHSQR_tb);     // Dump all variables in the testbench

        // Initialize inputs
        R = 16'b0000000000001100;

        // Apply test cases
        $display("Time\tInput R\t\tOutput final_op");
        $monitor("%0t\t%0b\t%0b", $time, R, final_op);

        #10 R = 16'b0000101100101010;      // Test Case 1
        #10 R = 16'b0000110010001111;      // Test Case 2
        #10 R = 16'b0000011111100011;      // Test Case 3 (perfect square)
        #10 R = 16'b0011000000000101;      // Test Case 4 (perfect square)
        #10 R = 16'b1110011000000000;      // Test Case 5 (not a perfect square)

        // Additional cases can be uncommented as needed
        #10 R = 16'b1110000000000010;     // Test Case 6 (perfect square)
        #10 R = 16'b0001111000001011;    // Test Case 7 (edge case)
        #10 R = 16'b0000010010101001;   // Test Case 8 (large value)
        #10 R = 16'b0000000110001101;   // Test Case 9 (large perfect square)
        // #10 R = 16'd65535;  // Test Case 10 (maximum 16-bit value)

        #10 $finish; // End simulation
    end

endmodule
