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
    wire zero = 1'b0; // Fixed 0 for MSB
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

module right_shifter_6bit_structural (
    input [5:0] data_in_t,  // 12-bit input
    output [5:0] data_out_t // 12-bit output
);
    //wire zeroo = 1'b0; // Fixed 0 for MSB
    genvar i;

    generate
        for (i = 0; i < 6; i = i + 1) begin : shift_logic
            if (i == 5) begin
                mux_2to1 u_mux_x (
                    .d0(data_in_t[5]), // Input 0 (original)
                    .d1(1'b0),       // Input 1 (shifted-in 0)
                    .sel(1'b1),      // Always select shift input
                    .y_mux(data_out_t[5])
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
    //buf b8 (data_out_t[3],zeroo);
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

module exact_ERSC(input[9:0] A, output [4:0] Q, output[9:0] R);
    not n0(w6,w4);
    not n1(w10,w9);
    not n2(w21,w22);
    not n3(w39,w40);
    not n4(w64,w63);

    wire w1,w2,w3,w5,w7,w8,w11,w12,w13,w14,w15,w16,w17,w18,w19,w20,w21,w22,w23,w24,w25,w26,w29,w30,w31,w32,w33,w34,w35,w36,w37,w38,w39,w40,w41,w42,w43,w44,w45,w46,w47,w48,w49,w50,w51,w52,w53,w54,w55,w56,w57,w58,w59,w60,w61,w62,w64,w65,w66,w67,w68,w69,w70,w71,w72,w73,w74,w75,w76,w77,w78,w79,w80;
    
    buf b0(Q[4],w6);
    buf b1(Q[3],w10);
    buf b2(Q[2],w21);
    buf b3(Q[1],w39);
    buf b4(Q[0],w64);
    
    ERSC ERSC0(.a(A[8]), .b(1'b1), .bin(1'b0), .qin(w1), .qout(), .bout(w2), .r(w3));
    ERSC ERSC1(.a(A[9]), .b(1'b0), .bin(w2), .qin(w6), .qout(w1), .bout(w4), .r(w5));

    ERSC ERSC2(.a(w5), .b(1'b0), .bin(w7), .qin(w10), .qout(w8), .bout(w9), .r(w11));
    ERSC ERSC3(.a(w3), .b(Q[4]), .bin(w12), .qin(w8), .qout(w13), .bout(w7), .r(w14));
    ERSC ERSC4(.a(A[7]), .b(1'b0), .bin(w15), .qin(w13), .qout(w16), .bout(w12), .r(w17));
    ERSC ERSC5(.a(A[6]), .b(1'b1), .bin(1'b0), .qin(w16), .qout(), .bout(w15), .r(w18));

    ERSC ERSC6(.a(w11), .b(1'b0), .bin(w19), .qin(w21), .qout(w20), .bout(w22), .r(w31));
    ERSC ERSC7(.a(w14), .b(1'b0), .bin(w23), .qin(w20), .qout(w24), .bout(w19), .r(w32));
    ERSC ERSC8(.a(w17), .b(Q[4]), .bin(w25), .qin(w24), .qout(w26), .bout(w23), .r(w33));
    ERSC ERSC9(.a(w18), .b(Q[3]), .bin(w27), .qin(w26), .qout(w28), .bout(w25), .r(w34));
    ERSC ERSC10(.a(A[5]), .b(1'b0), .bin(w29), .qin(w28), .qout(w30), .bout(w27), .r(w35));
    ERSC ERSC11(.a(A[4]), .b(1'b1), .bin(1'b0), .qin(w30), .qout(), .bout(w29), .r(w36));

    ERSC ERSC12(.a(w31), .b(1'b0), .bin(w37), .qin(w39), .qout(w38), .bout(w40), .r(w41));
    ERSC ERSC13(.a(w32), .b(1'b0), .bin(w42), .qin(w38), .qout(w43), .bout(w37), .r(w44));
    ERSC ERSC14(.a(w33), .b(1'b0), .bin(w45), .qin(w43), .qout(w46), .bout(w42), .r(w47));
    ERSC ERSC15(.a(w34), .b(Q[4]), .bin(w48), .qin(w46), .qout(w49), .bout(w45), .r(w50));
    ERSC ERSC16(.a(w35), .b(Q[3]), .bin(w51), .qin(w49), .qout(w52), .bout(w48), .r(w53));
    ERSC ERSC17(.a(w36), .b(Q[2]), .bin(w54), .qin(w52), .qout(w55), .bout(w51), .r(w56));
    ERSC ERSC18(.a(A[3]), .b(1'b0), .bin(w57), .qin(w55), .qout(w58), .bout(w54), .r(w59));
    ERSC ERSC19(.a(A[2]), .b(1'b1), .bin(1'b0), .qin(w58), .qout(), .bout(w57), .r(w60));

    ERSC ERSC20(.a(w41), .b(1'b0), .bin(w61), .qin(w64), .qout(w62), .bout(w63), .r(R[9]));
    ERSC ERSC21(.a(w44), .b(1'b0), .bin(w65), .qin(w62), .qout(w66), .bout(w61), .r(R[8]));
    ERSC ERSC22(.a(w47), .b(1'b0), .bin(w67), .qin(w66), .qout(w68), .bout(w65), .r(R[7]));
    ERSC ERSC23(.a(w50), .b(1'b0), .bin(w69), .qin(w68), .qout(w70), .bout(w67), .r(R[6]));
    ERSC ERSC24(.a(w53), .b(Q[4]), .bin(w71), .qin(w70), .qout(w72), .bout(w69), .r(R[5]));
    ERSC ERSC25(.a(w56), .b(Q[3]), .bin(w73), .qin(w72), .qout(w74), .bout(w71), .r(R[4]));
    ERSC ERSC26(.a(w59), .b(Q[2]), .bin(w75), .qin(w74), .qout(w76), .bout(w73), .r(R[3]));
    ERSC ERSC27(.a(w60), .b(Q[1]), .bin(w77), .qin(w76), .qout(w78), .bout(w75), .r(R[2]));
    ERSC ERSC28(.a(A[1]), .b(1'b0), .bin(w79), .qin(w78), .qout(w80), .bout(w77), .r(R[1]));
    ERSC ERSC29(.a(A[0]), .b(1'b1), .bin(1'b0), .qin(w80), .qout(), .bout(w79), .r(R[0]));

endmodule




module squareroot_AHSQR_k10(R,final_op);
    input [15:0] R;  // input radicand
    output [7:0] final_op;  //q+d - final output 

    wire [5:0] Y;
    wire [15:0] num;
    wire [9:0] rem;      // remainder for ESC circuit
    wire [15:0] shifted_num;  // (x+y/2)/√x
    wire [4:0] quo_exact_z; // √z - MSB of √x
    wire [7:0] quo_exact_x; //√x
    wire [2:0] mLOD; //leading one - m 

    right_shifter_6bit_structural divide (.data_in_t(R[5:0]), .data_out_t(Y) ); //right shifts by 1 one bit(y/2)   

    assign num[15]=R[15];
    assign num[14]=R[14];
    assign num[13]=R[13];
    assign num[12]=R[12];
    assign num[11]=R[11];
    assign num[10]=R[10];
    assign num[9]=R[9];
    assign num[8]=R[8];
    assign num[7]=R[7];
    assign num[6]=R[6];
    assign num[5]=Y[5];
    assign num[4]=Y[4];
    assign num[3]=Y[3];
    assign num[2]=Y[2];
    assign num[1]=Y[1];
    assign num[0]=Y[0];  //num=x+(y/2)

    exact_ERSC exact1(.Q(quo_exact_z),.R(rem),.A(R[15:6]));  // returns √z

    assign quo_exact_x[7]=quo_exact_z[4];
    assign quo_exact_x[6]=quo_exact_z[3];
    assign quo_exact_x[5]=quo_exact_z[2];
    assign quo_exact_x[4]=quo_exact_z[1];
    assign quo_exact_x[3]=quo_exact_z[0];
    assign quo_exact_x[2]=1'b0;
    assign quo_exact_x[1]=1'b0;
    assign quo_exact_x[0]=1'b0;  //√x

    priorityEncoder PE_find_m(.en(1'b1),.ip(quo_exact_x),.P(mLOD));  //finds m to be used in snipping circuit

    shifterbym MSHIFT(.numerator(num),.num_op(shifted_num),.mshift(mLOD)); //performs (x+y/2)/√x

    assign final_op[7]=quo_exact_z[4];
    assign final_op[6]=quo_exact_z[3];
    assign final_op[5]=quo_exact_z[2];
    assign final_op[4]=quo_exact_z[1];
    assign final_op[3]=quo_exact_z[0];
    
    wire quo_exact_x_zero;
    assign quo_exact_x_zero = (quo_exact_x == 8'b00000000);
    assign final_op[2:0] = quo_exact_x_zero ? 3'b111 : shifted_num[2:0];

endmodule