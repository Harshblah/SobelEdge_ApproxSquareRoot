`timescale 1ns / 1ps

module squareroot_AHSQR_tb;

    // Inputs
    reg [15:0] R;

    // Outputs
    wire [7:0] final_op;

    // Instantiate the Unit Under Test (UUT)
    squareroot_AHSQR uut (
        .R(R),
        .final_op(final_op)
    );

    initial begin
        // Initialize waveform generation for GTKWave
        $dumpfile("squareroot_AHSQR_tb.vcd"); // Name of the VCD file
        $dumpvars(0, squareroot_AHSQR_tb);     // Dump all variables in the testbench

        // Initialize inputs
        R = 16'b1111111110000000;

        // Apply test cases
        $display("Time\tInput R\t\tOutput final_op");
        $monitor("%0t\t%0b\t%0b", $time, R, final_op);

        #10 R = 16'b1101001110011001;      // Test Case 1
        #10 R = 16'b1011111110000010;      // Test Case 2
        #10 R = 16'b1000001110110001;      // Test Case 3 (perfect square)
        #10 R = 16'b1100111100011011;      // Test Case 4 (perfect square)
        #10 R = 16'b1000010110011011;      // Test Case 5 (not a perfect square)

        // Additional cases can be uncommented as needed
        // #10 R = 16'd16;     // Test Case 6 (perfect square)
        // #10 R = 16'd255;    // Test Case 7 (edge case)
        // #10 R = 16'd1023;   // Test Case 8 (large value)
        // #10 R = 16'd4096;   // Test Case 9 (large perfect square)
        // #10 R = 16'd65535;  // Test Case 10 (maximum 16-bit value)

        #10 $finish; // End simulation
    end

endmodule
