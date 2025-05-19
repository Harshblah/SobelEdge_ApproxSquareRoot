`timescale 1ns / 1ps

module tb_AHSQR_k;

    //Inputs
    reg [15:0] R;

    //Outputs
    wire [7:0] Q;

    squareroot_AHSQR_k12 uut (
        .R(R),
        .final_op(Q)
    );

    integer error_count;
    integer testcases;
    integer ref_op;
    integer norm_factor;
    integer NMED_sum;
    integer ED_max;
    integer abs_error;

    real ER;
    real NMED;
    real MRED;
    real MRED_sum_ref; 

    initial begin

        error_count=0;
        testcases=65536;
        norm_factor=255;
        NMED_sum=0;
        ED_max=0;
        abs_error=0;
        ER=0;
        NMED=0;
        MRED=0;
        MRED_sum_ref=0;

        for(integer i=0; i<65536; i=i+1) begin
                R=i;
                #500;
                ref_op=$rtoi($sqrt(i));
                if(ref_op != Q) begin
                   error_count = error_count + 1; 
                end
                abs_error = (ref_op>Q) ? (ref_op-Q) : (Q-ref_op);
                NMED_sum = NMED_sum + abs_error;
                if(i != 0) begin
                    MRED_sum_ref = MRED_sum_ref + ((abs_error*1.0)/ref_op);
                end
                if(abs_error > ED_max) begin
                    ED_max = abs_error;
                end
        end
        NMED = (NMED_sum*1.0)/(norm_factor*testcases);
        MRED = MRED_sum_ref/(testcases - 1);
        ER = (error_count*100.0)/testcases;

        $display("Error metrics for AHSQR k=12");
        $display("Error Rate (ER): %0.2f%%", ER);
        $display("NMED: %0.6f", NMED);
        $display("MRED: %0.6f", MRED);
        $display("Maximum Error Distance (EDmax): %0d", ED_max);
        $finish;

    end

endmodule
