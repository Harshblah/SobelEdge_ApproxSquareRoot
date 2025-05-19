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

module mux_2to1_14bit_structural (
    input [13:0] mux_a,   // Input 0
    input [13:0] mux_b,   // Input 1
    input mux_sel,        // Select signal
    output [13:0] mux_y   // Output
);
    genvar i;

    generate
        for (i = 0; i < 14; i = i + 1) begin : bit_mux
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
   // wire zero = 1'b0; // Fixed 0 for MSB
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
   // buf b9 (data_out[15],zero);
endmodule

module right_shifter_2bit_structural (
    input [1:0] data_in_t,  // 12-bit input
    output [1:0] data_out_t // 12-bit output
);
  //  wire zeroo = 1'b0; // Fixed 0 for MSB
    genvar i;

    generate
        for (i = 0; i < 2; i = i + 1) begin : shift_logic
            if (i == 1) begin
                mux_2to1 u_mux_x (
                    .d0(data_in_t[1]), // Input 0 (original)
                    .d1(1'b0),       // Input 1 (shifted-in 0)
                    .sel(1'b1),      // Always select shift input
                    .y_mux(data_out_t[1])
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
   // buf b8 (data_out_t[1],zeroo);
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
    input [13:0] z,
    output s
);
    // OR reduction structurally
    wire temp1, temp2, temp3, temp4, temp5, temp6, temp7, r1, r2, r3, r4, r5, or_result;

    or or1(temp1, z[0], z[1]);
    or or2(temp2, z[2], z[3]);
    or or3(temp3, z[4], z[5]);
    or or4(temp4, z[6], z[7]);
    or or5(temp5, z[8], z[9]);
    or or6(temp6, z[10], z[11]);
    or or7(temp7, z[12], z[13]);
    or or8(r1, temp1, temp2);
    or or9(r2, temp3, temp4);
    or or10(r3, temp5, temp6);
    or or11(r4, r1, r2);
    or or12(r5, r3, r4);
    or o13(or_result, r5, temp7);

    not not1(s, or_result); // Final NOR reduction

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

module ERSC_exact(input[13:0] A, output [6:0] Q, output[13:0] R);
  
    wire w1,w2,w3,w5,w7,w8,w11,w12,w13,w14,w15,w16,w17,w18,w19,w20,w21,w22,w23,w24,w25,w26,w29,w30;
    wire w31,w32,w33,w34,w35,w36,w37,w38,w39,w40,w41,w42,w43,w44,w45,w46,w47,w48,w49,w50,w51,w52,w53,w54,w55,w56,w57,w58,w59,w60;
    wire w61,w62,w64,w65,w66,w67,w68,w69,w70,w71,w72,w73,w74,w75,w76,w77,w78,w79,w80,w81,w82,w83,w84,w85,w86,w87,w88,w89,w90;
    wire w91,w92,w94,w95,w96,w97,w98,w99,w100,w101,w102,w103,w104,w105,w106,w107,w108,w109,w110,w111,w112,w113,w114,w115,w116;
    wire w117,w118,w119,w120,w121,w122,w123,w124,w125,w126,w127,w128,w129,w130,w131,w132,w133,w134,w135,w136,w137,w138,w139,w140;
    wire w141,w142,w143,w144,w145,w146,w147,w148,w149,w150,w151,w152,w153,w154;
    
    not n0(w6,w4);
    not n1(w10,w9);
    not n2(w21,w22);
    not n3(w39,w40);
    not n4(w64,w63);
    not n5(w94,w93);
    not n6(w128,w130);

    buf b0(Q[6],w6);
    buf b1(Q[5],w10);
    buf b2(Q[4],w21);
    buf b3(Q[3],w39);
    buf b4(Q[2],w64);
    buf b5(Q[1],w94);
    buf b6(Q[0],w128);
    
    ERSC ERSC0(.a(A[12]), .b(1'b1), .bin(1'b0), .qin(w1), .qout(), .bout(w2), .r(w3));
    ERSC ERSC1(.a(A[13]), .b(1'b0), .bin(w2), .qin(w6), .qout(w1), .bout(w4), .r(w5));

    ERSC ERSC2(.a(w5), .b(1'b0), .bin(w7), .qin(w10), .qout(w8), .bout(w9), .r(w11));
    ERSC ERSC3(.a(w3), .b(Q[6]), .bin(w12), .qin(w8), .qout(w13), .bout(w7), .r(w14));
    ERSC ERSC4(.a(A[11]), .b(1'b0), .bin(w15), .qin(w13), .qout(w16), .bout(w12), .r(w17));
    ERSC ERSC5(.a(A[10]), .b(1'b1), .bin(1'b0), .qin(w16), .qout(), .bout(w15), .r(w18));

    ERSC ERSC6(.a(w11), .b(1'b0), .bin(w19), .qin(w21), .qout(w20), .bout(w22), .r(w31));
    ERSC ERSC7(.a(w14), .b(1'b0), .bin(w23), .qin(w20), .qout(w24), .bout(w19), .r(w32));
    ERSC ERSC8(.a(w17), .b(Q[6]), .bin(w25), .qin(w24), .qout(w26), .bout(w23), .r(w33));
    ERSC ERSC9(.a(w18), .b(Q[5]), .bin(w27), .qin(w26), .qout(w28), .bout(w25), .r(w34));
    ERSC ERSC10(.a(A[9]), .b(1'b0), .bin(w29), .qin(w28), .qout(w30), .bout(w27), .r(w35));
    ERSC ERSC11(.a(A[8]), .b(1'b1), .bin(1'b0), .qin(w30), .qout(), .bout(w29), .r(w36));

    ERSC ERSC12(.a(w31), .b(1'b0), .bin(w37), .qin(w39), .qout(w38), .bout(w40), .r(w41));
    ERSC ERSC13(.a(w32), .b(1'b0), .bin(w42), .qin(w38), .qout(w43), .bout(w37), .r(w44));
    ERSC ERSC14(.a(w33), .b(1'b0), .bin(w45), .qin(w43), .qout(w46), .bout(w42), .r(w47));
    ERSC ERSC15(.a(w34), .b(Q[6]), .bin(w48), .qin(w46), .qout(w49), .bout(w45), .r(w50));
    ERSC ERSC16(.a(w35), .b(Q[5]), .bin(w51), .qin(w49), .qout(w52), .bout(w48), .r(w53));
    ERSC ERSC17(.a(w36), .b(Q[4]), .bin(w54), .qin(w52), .qout(w55), .bout(w51), .r(w56));
    ERSC ERSC18(.a(A[7]), .b(1'b0), .bin(w57), .qin(w55), .qout(w58), .bout(w54), .r(w59));
    ERSC ERSC19(.a(A[6]), .b(1'b1), .bin(1'b0), .qin(w58), .qout(), .bout(w57), .r(w60));

    ERSC ERSC20(.a(w41), .b(1'b0), .bin(w61), .qin(w64), .qout(w62), .bout(w63), .r(w81));
    ERSC ERSC21(.a(w44), .b(1'b0), .bin(w65), .qin(w62), .qout(w66), .bout(w61), .r(w82));
    ERSC ERSC22(.a(w47), .b(1'b0), .bin(w67), .qin(w66), .qout(w68), .bout(w65), .r(w83));
    ERSC ERSC23(.a(w50), .b(1'b0), .bin(w69), .qin(w68), .qout(w70), .bout(w67), .r(w84));
    ERSC ERSC24(.a(w53), .b(Q[6]), .bin(w71), .qin(w70), .qout(w72), .bout(w69), .r(w85));
    ERSC ERSC25(.a(w56), .b(Q[5]), .bin(w73), .qin(w72), .qout(w74), .bout(w71), .r(w86));
    ERSC ERSC26(.a(w59), .b(Q[4]), .bin(w75), .qin(w74), .qout(w76), .bout(w73), .r(w87));
    ERSC ERSC27(.a(w60), .b(Q[3]), .bin(w77), .qin(w76), .qout(w78), .bout(w75), .r(w88));
    ERSC ERSC28(.a(A[5]), .b(1'b0), .bin(w79), .qin(w78), .qout(w80), .bout(w77), .r(w89));
    ERSC ERSC29(.a(A[4]), .b(1'b1), .bin(1'b0), .qin(w80), .qout(), .bout(w79), .r(w90));

    ERSC ERSC30(.a(w81), .b(1'b0), .bin(w91), .qin(w94), .qout(w92), .bout(w93), .r(w95));
    ERSC ERSC31(.a(w82), .b(1'b0), .bin(w96), .qin(w92), .qout(w97), .bout(w91), .r(w98));
    ERSC ERSC32(.a(w83), .b(1'b0), .bin(w99), .qin(w97), .qout(w100), .bout(w96), .r(w101));
    ERSC ERSC33(.a(w84), .b(1'b0), .bin(w102), .qin(w100), .qout(w103), .bout(w99), .r(w104));
    ERSC ERSC34(.a(w85), .b(1'b0), .bin(w105), .qin(w103), .qout(w106), .bout(w102), .r(w107));
    ERSC ERSC35(.a(w86), .b(Q[6]), .bin(w108), .qin(w106), .qout(w109), .bout(w105), .r(w110));
    ERSC ERSC36(.a(w87), .b(Q[5]), .bin(w111), .qin(w109), .qout(w112), .bout(w108), .r(w113));
    ERSC ERSC37(.a(w88), .b(Q[4]), .bin(w114), .qin(w112), .qout(w115), .bout(w111), .r(w116));
    ERSC ERSC38(.a(w89), .b(Q[3]), .bin(w117), .qin(w115), .qout(w118), .bout(w114), .r(w119));
    ERSC ERSC39(.a(w90), .b(Q[2]), .bin(w120), .qin(w118), .qout(w121), .bout(w117), .r(w122));
    ERSC ERSC40(.a(A[3]), .b(1'b0), .bin(w123), .qin(w121), .qout(w124), .bout(w120), .r(w125));
    ERSC ERSC41(.a(A[2]), .b(1'b1), .bin(1'b0), .qin(w124), .qout(), .bout(w123), .r(w126));

    ERSC ERSC42(.a(w95), .b(1'b0), .bin(w127), .qin(w128), .qout(w129), .bout(w130), .r(R[13]));
    ERSC ERSC43(.a(w98), .b(1'b0), .bin(w131), .qin(w129), .qout(w132), .bout(w127), .r(R[12]));
    ERSC ERSC44(.a(w101), .b(1'b0), .bin(w133), .qin(w132), .qout(w134), .bout(w131), .r(R[11]));
    ERSC ERSC45(.a(w104), .b(1'b0), .bin(w135), .qin(w134), .qout(w136), .bout(w133), .r(R[10]));
    ERSC ERSC46(.a(w107), .b(1'b0), .bin(w137), .qin(w136), .qout(w138), .bout(w135), .r(R[9]));
    ERSC ERSC47(.a(w110), .b(1'b0), .bin(w139), .qin(w138), .qout(w140), .bout(w137), .r(R[8]));
    ERSC ERSC48(.a(w113), .b(Q[6]), .bin(w141), .qin(w140), .qout(w142), .bout(w139), .r(R[7]));
    ERSC ERSC49(.a(w116), .b(Q[5]), .bin(w143), .qin(w142), .qout(w144), .bout(w141), .r(R[6]));
    ERSC ERSC50(.a(w119), .b(Q[4]), .bin(w145), .qin(w144), .qout(w146), .bout(w143), .r(R[5]));
    ERSC ERSC51(.a(w122), .b(Q[3]), .bin(w147), .qin(w146), .qout(w148), .bout(w145), .r(R[4]));
    ERSC ERSC52(.a(w125), .b(Q[2]), .bin(w149), .qin(w148), .qout(w150), .bout(w147), .r(R[3]));
    ERSC ERSC53(.a(w126), .b(Q[1]), .bin(w151), .qin(w150), .qout(w152), .bout(w149), .r(R[2]));
    ERSC ERSC54(.a(A[1]), .b(1'b0), .bin(w153), .qin(w152), .qout(w154), .bout(w151), .r(R[1]));
    ERSC ERSC55(.a(A[0]), .b(1'b1), .bin(1'b0), .qin(w154), .qout(), .bout(w153), .r(R[0]));
endmodule

module squareroot_MAHSQR_k14(R,final_op);
    input [15:0] R;  // input radicand
    output [7:0] final_op;  //q+d - final output 

    wire select_line_mux;


    wire [1:0] Y;
    wire [13:0] y;  //goes into firstmux
    wire [13:0] zm; //output of first mux
    wire [15:0] num;
    wire [13:0] rem;      // remainder for ESC circuit
    wire [15:0] shifted_num;  // (x+y/2)/√x
    wire [6:0] quo_exact_z; // √z - MSB of √x
    wire [7:0] quo_exact_x; //√x
    wire [2:0] mLOD; //leading one - m
    wire [7:0] maybe_Q_0;  //input to second mux
    wire [7:0] maybe_Q_1;  //input to second mux

    right_shifter_2bit_structural divide (.data_in_t(R[1:0]), .data_out_t(Y) ); //right shifts by 1 one bit(y/2)

    assign y[13]= 1'b0;
    assign y[12]= 1'b0;
    assign y[11]= 1'b0;
    assign y[10]= 1'b0;
    assign y[9]= 1'b0;
    assign y[8]= 1'b0;
    assign y[7]= 1'b0;
    assign y[6]= 1'b0;
    assign y[5]= 1'b0;
    assign y[4]= 1'b0;
    assign y[3]= 1'b0;
    assign y[2]= 1'b0;
    assign y[1]= R[1];
    assign y[0]= R[0];

    nor_reduction nor_select_line(.z(R[15:2]), .s(select_line_mux));

    mux_2to1_14bit_structural firstmux (.mux_a(R[15:2]), .mux_b(y), .mux_sel(select_line_mux), .mux_y(zm));

    assign num[15]=zm[13];
    assign num[14]=zm[12];
    assign num[13]=zm[11];
    assign num[12]=zm[10];
    assign num[11]=zm[9];
    assign num[10]=zm[8];
    assign num[9]=zm[7];
    assign num[8]=zm[6];
    assign num[7]=zm[5];
    assign num[6]=zm[4];
    assign num[5]=zm[3];
    assign num[4]=zm[2];
    assign num[3]=zm[1];
    assign num[2]=zm[0];
    assign num[1]=Y[1];
    assign num[0]=Y[0];  //num=x+(y/2) comes from zm and not R directly

    ERSC_exact exact1(.Q(quo_exact_z),.R(rem),.A(zm));  // returns √z

    assign quo_exact_x[7]=quo_exact_z[6];
    assign quo_exact_x[6]=quo_exact_z[5];
    assign quo_exact_x[5]=quo_exact_z[4];
    assign quo_exact_x[4]=quo_exact_z[3];
    assign quo_exact_x[3]=quo_exact_z[2];
    assign quo_exact_x[2]=quo_exact_z[1];
    assign quo_exact_x[1]=quo_exact_z[0];
    assign quo_exact_x[0]=1'b0;  //√x

    priorityEncoder PE_find_m(.en(1'b1),.ip(quo_exact_x),.P(mLOD));  //finds m to be used in snipping circuit

    shifterbym MSHIFT(.numerator(num),.num_op(shifted_num),.mshift(mLOD)); //performs (x+y/2)/√x

    assign maybe_Q_0[7]=1'b0;
    assign maybe_Q_0[6]=quo_exact_z[6];
    assign maybe_Q_0[5]=quo_exact_z[5];
    assign maybe_Q_0[4]=quo_exact_z[4];
    assign maybe_Q_0[3]=quo_exact_z[3];
    assign maybe_Q_0[2]=quo_exact_z[2];
    assign maybe_Q_0[1]=quo_exact_z[1];
    assign maybe_Q_0[0]=quo_exact_z[0];  // input at location 1 to second mux

    assign maybe_Q_1[7]=quo_exact_z[6];
    assign maybe_Q_1[6]=quo_exact_z[5];
    assign maybe_Q_1[5]=quo_exact_z[4];
    assign maybe_Q_1[4]=quo_exact_z[3];
    assign maybe_Q_1[3]=quo_exact_z[2];
    assign maybe_Q_1[2]=quo_exact_z[1]; 
    assign maybe_Q_1[1]=quo_exact_z[0];
    assign maybe_Q_1[0]=shifted_num[0];  // input at location 0 to second mux

    mux_2to1_8bit_structural second_mux(.mux_a(maybe_Q_1), .mux_b(maybe_Q_0), .mux_sel(select_line_mux), .mux_y(final_op));

endmodule