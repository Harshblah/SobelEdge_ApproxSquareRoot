`timescale 1ns/1ps
module mux_2to1 (
    input d0,    // Input 0
    input d1,    // Input 1
    input sel,   // Selection signal
    output y_mux     // Output
);
    wire not_sel;   // NOT of sel
    wire and0, and1; // Intermediate AND outputs

    // Structural implementation
    not u1 (not_sel, sel);      // NOT gate
    and u2 (and0, d0, not_sel); // AND gate for d0
    and u3 (and1, d1, sel);     // AND gate for d1
    or  u4 (y_mux, and0, and1);     // OR gate to combine results
endmodule

module mux_2to1_16bit_structural (
    input [15:0] mux_a,   // Input 0
    input [15:0] mux_b,   // Input 1
    input mux_sel,        // Select signal
    output [15:0] mux_y   // Output
);
    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : bit_mux
            mux_2to1 u_mux (
                .d0(mux_a[i]),  // Input 0 for this bit
                .d1(mux_b[i]),  // Input 1 for this bit
                .sel(mux_sel), // Select signal
                .y_mux(mux_y[i])   // Output for this bit
            );
        end
    endgenerate
endmodule

module mux_2to1_6bit_structural (
    input [5:0] mux_a,   // Input 0
    input [5:0] mux_b,   // Input 1
    input mux_sel,        // Select signal
    output [5:0] mux_y   // Output
);
    genvar i;

    generate
        for (i = 0; i < 6; i = i + 1) begin : bit_mux
            mux_2to1 u_mux (
                .d0(mux_a[i]),  // Input 0 for this bit
                .d1(mux_b[i]),  // Input 1 for this bit
                .sel(mux_sel), // Select signal
                .y_mux(mux_y[i])   // Output for this bit
            );
        end
    endgenerate
endmodule

module mux_2to1_8bit_structural (
    input [7:0] mux_a,   // Input 0
    input [7:0] mux_b,   // Input 1
    input mux_sel,        // Select signal
    output [7:0] mux_y   // Output
);
    genvar i;

    generate
        for (i = 0; i < 8; i = i + 1) begin : bit_mux
            mux_2to1 u_mux (
                .d0(mux_a[i]),  // Input 0 for this bit
                .d1(mux_b[i]),  // Input 1 for this bit
                .sel(mux_sel), // Select signal
                .y_mux(mux_y[i])   // Output for this bit
            );
        end
    endgenerate
endmodule

module priorityEncoder(en,ip,P);
    // declare port list via input and output
    input en;
    input [7:0]ip;
    output [2:0]P;

    wire temp1,temp2,temp3,temp4,temp5,temp6,temp7, b7,b6,b5,b4,b3,b2,b1,b0; // temp is used to apply 
    // enable for the or gates
    // check the logic diagram and use 
    // logic gates to compute outputs
    not n1 (temp1,ip[1]);
    not n2 (temp2,ip[2]);
    not n3 (temp3,ip[3]);
    not n4 (temp4,ip[4]);
    not n5 (temp5,ip[5]);
    not n6 (temp6,ip[6]);
    not n7 (temp7,ip[7]);
    buf buf1(b7, ip[7]);
    and and1(b6, temp7, ip[6]);
    and and2(b5, temp7, temp6, ip[5]);
    and and3(b4, temp7, temp6, temp5, ip[4]);
    and and4(b3, temp7, temp6, temp5, temp4, ip[3]);
    and and5(b2, temp7, temp6, temp5, temp4, temp3, ip[2]);
    and and6(b1, temp7, temp6, temp5, temp4, temp3, temp2, ip[1]);
    and and7(b0, temp7, temp6, temp5, temp4, temp3, temp2, temp1, ip[0]);
    assign P[2] = b4 | b5 | b6 | b7;
    assign P[1] = b2 | b3 | b6 | b7;
    assign P[0] = b1 | b3 | b5 | b7;

endmodule

module right_shifter_16bit_structural (
    input [15:0] data_in,  // 16-bit input
    output [15:0] data_out // 16-bit output
);
    //wire zero = 1'b0; // Fixed 0 for MSB
    genvar i;

    generate
        for (i = 0; i < 16; i = i + 1) begin : shift_logic
            if (i == 15) begin
                mux_2to1 u_mux_u (
                    .d0(data_in[15]), // Input 0 (original)
                    .d1(1'b0),       // Input 1 (shifted-in 0)
                    .sel(1'b1),     // Always select shift input
                    .y_mux(data_out[15])
                );
            end else begin
                mux_2to1 u_mux (
                    .d0(data_in[i]),      // Input 0 (original)
                    .d1(data_in[i+1]),    // Input 1 (shifted)
                    .sel(1'b1),          // Always select shift input
                    .y_mux(data_out[i])
                );
            end
        end
    endgenerate
    //buf b9 (data_out[15],zero);
endmodule

module right_shifter_10bit_structural (
    input [9:0] data_in_t,  // 12-bit input
    output [9:0] data_out_t // 12-bit output
);
    //wire zeroo = 1'b0; // Fixed 0 for MSB
    genvar i;

    generate
        for (i = 0; i < 10; i = i + 1) begin : shift_logic
            if (i == 9) begin
                mux_2to1 u_mux_x (
                    .d0(data_in_t[9]), // Input 0 (original)
                    .d1(1'b0),       // Input 1 (shifted-in 0)
                    .sel(1'b1),      // Always select shift input
                    .y_mux(data_out_t[9])
                );
            end else begin
                mux_2to1 u_mux_g (
                    .d0(data_in_t[i]),      // Input 0 (original)
                    .d1(data_in_t[i+1]),    // Input 1 (shifted)
                    .sel(1'b1),           // Always select shift input
                    .y_mux(data_out_t[i])
                );
            end
        end
    endgenerate
    //buf b8 (data_out_t[11],zeroo);
endmodule

module shifterbym(numerator,num_op,mshift);
    // shifts (m[0],m[1],m[2]==1,2,4)
    input [15:0] numerator;
    input [2:0] mshift;
    output [15:0] num_op;

    wire [15:0] stage1, stage2, stage3, stage4, stage5, stage6, stage7, stage8, stage9; //intermediary stages

    right_shifter_16bit_structural shift00(.data_in(numerator),.data_out(stage1));  //shifts 1 bit
    mux_2to1_16bit_structural shiftmux1(.mux_a(numerator),.mux_b(stage1),.mux_sel(mshift[0]),.mux_y(stage2)); //chooses if to choose by 1 bit acc to m[0]

    right_shifter_16bit_structural shift01(.data_in(stage2),.data_out(stage3));
    right_shifter_16bit_structural shift02(.data_in(stage3),.data_out(stage4));     //shifts 2 bits
    mux_2to1_16bit_structural shiftmux2(.mux_a(stage2),.mux_b(stage4),.mux_sel(mshift[1]),.mux_y(stage5)); //chooses if to choose by 2 bit acc to m[1]

    right_shifter_16bit_structural shift03(.data_in(stage5),.data_out(stage6));
    right_shifter_16bit_structural shift04(.data_in(stage6),.data_out(stage7));
    right_shifter_16bit_structural shift05(.data_in(stage7),.data_out(stage8));
    right_shifter_16bit_structural shift06(.data_in(stage8),.data_out(stage9));    //shifts 4 bits
    mux_2to1_16bit_structural shiftmux3(.mux_a(stage5),.mux_b(stage9),.mux_sel(mshift[2]),.mux_y(num_op));  //chooses if to choose by 2 bit acc to m[2]

endmodule

module nor_reduction (
    input [5:0] z,
    output s
);
    // OR reduction structurally
    wire temp1, temp2, temp3, or_result1, or_result2;

    or or1(temp1, z[0], z[1]);
    or or2(temp2, z[2], z[3]);
    or or3(temp3, z[4], z[5]);
    or or11(or_result1, temp1, temp2);
    or or12(or_result2, temp3, or_result1); // First OR reduction
    not not1(s, or_result2); // Final NOR reduction

endmodule

module ERSC (input a,input b,input bin,input qin,output qout,output bout,output r);  // one block of ESRC
   wire a1,y1,y2,y3,y4;

    not n1 (a1,a);
    and a11 (y1,b,a1);
    and a2 (y2,bin,a1);
    and a3 (y3,b,bin);
    or  o1 (bout,y1,y2,y3);
    buf b1 (qout,qin);
    xor xo1(y4,a,b,bin);
    mux_2to1 mux_ESRC(.d0(a),.d1(y4),.sel(qin),.y_mux(r));

endmodule

module exact_ERSC(input[5:0] A, output [2:0] Q, output[5:0] R);
    

    wire w1,w2,w3,w5,w7,w8,w11,w12,w13,w14,w15,w16,w17,w18,w19,w20,w21,w22,w23,w24,w25,w26,w29,w30;
    
    not n0(w6,w4);
    not n1(w10,w9);
    not n2(w21,w22);
    
    buf b0(Q[2],w6);
    buf b1(Q[1],w10);
    buf b2(Q[0],w21);
        
    ERSC ERSC0(.a(A[4]), .b(1'b1), .bin(1'b0), .qin(w1), .qout(), .bout(w2), .r(w3));
    ERSC ERSC1(.a(A[5]), .b(1'b0), .bin(w2), .qin(w6), .qout(w1), .bout(w4), .r(w5));

    ERSC ERSC2(.a(w5), .b(1'b0), .bin(w7), .qin(w10), .qout(w8), .bout(w9), .r(w11));
    ERSC ERSC3(.a(w3), .b(Q[2]), .bin(w12), .qin(w8), .qout(w13), .bout(w7), .r(w14));
    ERSC ERSC4(.a(A[3]), .b(1'b0), .bin(w15), .qin(w13), .qout(w16), .bout(w12), .r(w17));
    ERSC ERSC5(.a(A[2]), .b(1'b1), .bin(1'b0), .qin(w16), .qout(), .bout(w15), .r(w18));

    ERSC ERSC6(.a(w11), .b(1'b0), .bin(w19), .qin(w21), .qout(w20), .bout(w22), .r(R[5]));
    ERSC ERSC7(.a(w14), .b(1'b0), .bin(w23), .qin(w20), .qout(w24), .bout(w19), .r(R[4]));
    ERSC ERSC8(.a(w17), .b(Q[2]), .bin(w25), .qin(w24), .qout(w26), .bout(w23), .r(R[3]));
    ERSC ERSC9(.a(w18), .b(Q[1]), .bin(w27), .qin(w26), .qout(w28), .bout(w25), .r(R[2]));
    ERSC ERSC10(.a(A[1]), .b(1'b0), .bin(w29), .qin(w28), .qout(w30), .bout(w27), .r(R[1]));
    ERSC ERSC11(.a(A[0]), .b(1'b1), .bin(1'b0), .qin(w30), .qout(), .bout(w29), .r(R[0]));

endmodule

module squareroot_MAHSQR_k6(R,final_op);
    input [15:0] R;  // input radicand
    output [7:0] final_op;  //q+d - final output 

    wire select_line_mux;


    wire [9:0] Y;
    wire [5:0] y;  //goes into firstmux
    wire [5:0] zm; //output of first mux
    wire [15:0] num;
    wire [5:0] rem;      // remainder for ESC circuit
    wire [15:0] shifted_num;  // (x+y/2)/√x
    wire [2:0] quo_exact_z; // √z - MSB of √x
    wire [7:0] quo_exact_x; //√x
    wire [2:0] mLOD; //leading one - m
    wire [7:0] maybe_Q_0;  //input to second mux
    wire [7:0] maybe_Q_1;  //input to second mux

    right_shifter_10bit_structural divide (.data_in_t(R[9:0]), .data_out_t(Y) ); //right shifts by 1 one bit(y/2)

    assign y[5]= R[9];
    assign y[4]= R[8];
    assign y[3]= R[7];
    assign y[2]= R[6];
    assign y[1]= R[5];
    assign y[0]= R[4]; 

    nor_reduction nor_select_line(.z(R[15:10]), .s(select_line_mux));

    mux_2to1_6bit_structural firstmux (.mux_a(R[15:10]), .mux_b(y), .mux_sel(select_line_mux), .mux_y(zm));

    assign num[15]=zm[5];
    assign num[14]=zm[4];
    assign num[13]=zm[3];
    assign num[12]=zm[2];
    assign num[11]=zm[1];
    assign num[10]=zm[0];
    assign num[9]=Y[9];
    assign num[8]=Y[8];
    assign num[7]=Y[7];
    assign num[6]=Y[6];
    assign num[5]=Y[5];
    assign num[4]=Y[4];
    assign num[3]=Y[3];
    assign num[2]=Y[2];
    assign num[1]=Y[1];
    assign num[0]=Y[0];  //num=x+(y/2) comes from zm and not R directly

    exact_ERSC exact1(.Q(quo_exact_z),.R(rem),.A(zm));  // returns √z

    assign quo_exact_x[7]=quo_exact_z[2];
    assign quo_exact_x[6]=quo_exact_z[1];
    assign quo_exact_x[5]=quo_exact_z[0];
    assign quo_exact_x[4]=1'b0;
    assign quo_exact_x[3]=1'b0;
    assign quo_exact_x[2]=1'b0;
    assign quo_exact_x[1]=1'b0;
    assign quo_exact_x[0]=1'b0;  //√x

    priorityEncoder PE_find_m(.en(1'b1),.ip(quo_exact_x),.P(mLOD));  //finds m to be used in snipping circuit

    shifterbym MSHIFT(.numerator(num),.num_op(shifted_num),.mshift(mLOD)); //performs (x+y/2)/√x

    assign maybe_Q_0[7]=1'b0;
    assign maybe_Q_0[6]=1'b0;
    assign maybe_Q_0[5]=1'b0;
    assign maybe_Q_0[4]=quo_exact_z[2];
    assign maybe_Q_0[3]=quo_exact_z[1];
    assign maybe_Q_0[2]=quo_exact_z[0];
    assign maybe_Q_0[1]=shifted_num[1];
    assign maybe_Q_0[0]=shifted_num[0];  // input at location 1 to second mux

    assign maybe_Q_1[7]=quo_exact_z[2];
    assign maybe_Q_1[6]=quo_exact_z[1];
    assign maybe_Q_1[5]=quo_exact_z[0];
    assign maybe_Q_1[4]=shifted_num[4];
    assign maybe_Q_1[3]=shifted_num[3];
    assign maybe_Q_1[2]=shifted_num[2]; 
    assign maybe_Q_1[1]=shifted_num[1];
    assign maybe_Q_1[0]=shifted_num[0];  // input at location 0 to second mux

    mux_2to1_8bit_structural second_mux(.mux_a(maybe_Q_1), .mux_b(maybe_Q_0), .mux_sel(select_line_mux), .mux_y(final_op));

endmodule


