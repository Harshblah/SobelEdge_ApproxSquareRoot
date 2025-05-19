`timescale 1ns / 1ps

module squareroot_MAHSQR_tb;

    // Inputs
    reg [15:0] R;

    // Outputs
    wire [7:0] final_op;

    // Instantiate the Unit Under Test (UUT)
    squareroot_MAHSQR_k8 uut (
        .R(R),
        .final_op(final_op)
    );

    // Internal signal declarations
    wire [7:0] Y = uut.Y;
    wire [7:0] y = uut.y;
    wire [7:0] zm = uut.zm;
    wire [15:0] num = uut.num;
    wire [7:0] rem = uut.rem;
    wire [15:0] shifted_num = uut.shifted_num;
    wire [3:0] quo_exact_z = uut.quo_exact_z;
    wire [7:0] quo_exact_x = uut.quo_exact_x;
    wire [2:0] mLOD = uut.mLOD;
    wire [7:0] maybe_Q_0 = uut.maybe_Q_0;
    wire [7:0] maybe_Q_1 = uut.maybe_Q_1;

    initial begin
        // Initialize waveform generation
        $dumpfile("squareroot_MAHSQR_tb.vcd");
        $dumpvars(0, squareroot_MAHSQR_tb); // Dump all variables

        // Apply input
        R = 16'b1000011110011001; // Example input (adjust as needed)

        // Monitor signals (optional)
        $display("Simulation Started");
        #10; // Allow signals to propagate
        $display("Final Output: %h", final_op);
        $display("Y: %h, y: %h, zm: %h", Y, y, zm);
        $display("num: %h, rem: %h, shifted_num: %h", num, rem, shifted_num);
        $display("quo_exact_z: %h, quo_exact_x: %h, mLOD: %h", quo_exact_z, quo_exact_x, mLOD);
        $display("maybe_Q_0: %h, maybe_Q_1: %h", maybe_Q_0, maybe_Q_1);

        #100 $finish;
    end

endmodule