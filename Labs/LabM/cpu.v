module yMux1(z, a, b, c);
output z;
input a, b, c;
wire notC, upper, lower;

not my_not(notC, c);
and upperAnd(upper, a, notC);
and lowerAnd(lower, c, b);
or my_or(z, upper, lower);

endmodule

module yMux(z, a, b, c);
parameter SIZE = 2;
output [SIZE-1:0] z;
input [SIZE-1:0] a, b;
input c;

yMux1 mux1[SIZE-1:0](z, a, b, c);

endmodule

module yMux4to1(z, a0,a1,a2,a3, c);
parameter SIZE = 2;
output [SIZE-1:0] z;
input [SIZE-1:0] a0, a1, a2, a3;
input [1:0] c;
wire [SIZE-1:0] zLo, zHi;

yMux #(SIZE) lo(zLo, a0, a1, c[0]);
yMux #(SIZE) hi(zHi, a2, a3, c[0]);
yMux #(SIZE) final(z, zLo, zHi, c[1]);

endmodule

module yAdder1(z, cout, a, b, cin);
output z, cout;
input a, b, cin;

xor left_xor(tmp, a, b);
xor right_xor(z, cin, tmp);
and left_and(outL, a, b);
and right_and(outR, tmp, cin);
or my_or(cout, outR, outL);

endmodule


module yAdder(z, cout, a, b, cin);
output [31:0] z;
output cout;
input cin;
input [31:0] a, b;
wire[31:0] in, out;

yAdder1 mine[31:0](z, out, a, b, in);
assign in[0] = cin;
assign in[31:1] = out[30:0];
assign cout = out[31];

endmodule

module yArith(z, cout, a, b, ctrl);
// add if ctrl=0, subtract if ctrl=1 
output [31:0] z;
output cout;
input [31:0] a, b;
input ctrl;
wire[31:0] B;
wire cin;

xor b_comp[31:0](B, b,ctrl);
assign cin = ctrl;
yAdder add(z, cout, a, B, cin);

endmodule

module yAlu(z, zero, a, b, op);
// op=000: z=a&b, op=001: z=a|b, op=010: z=a+b, op=110: z=a-b, op=111: z=a<b?1:0
input [31:0] a, b;
input [2:0] op;
output [31:0] z;
output zero;
wire [31:0] zAnd, zOr, zArith, slt;
wire condition;

assign slt[31:1] = 0;
xor (condition, a[31], b[31]);
yMux #(1) sltMux(slt[0], zArith[31], a[31], condition);

and myAnd[31:0] (zAnd, a, b);
or myOr[31:0] (zOr, a, b);
yArith myArith (zArith, cout, a, b, op[2]);
yMux4to1 #(32) myMux(z, zAnd, zOr, zArith, slt, op[1:0]);

wire [7:0] z8; wire [1:0] z2; wire z1;
or or8[7:0] (z8, z[31:24], z[23:16], z[15:8], z[7:0]);
or or2[1:0] (z2, z8[7:6], z8[5:4], z8[3:2], z8[1:0]);
or or1[0:0] (z1, z2[1], z2[0]);
not last(zero, z1);

endmodule

module yIF(ins,PCp4, PCin, clk);

    output [31:0] ins, PCp4;
    input [31:0] PCin;
    input clk;

    wire ex;
    wire [31:0] PCregOut;
    
    register #(32) my_reg(PCregOut, PCin, clk, 1'b1);
    yAlu my_alu(PCp4, ex, 4, PCregOut, 3'b010);
    mem myMem(ins, PCregOut, , clk, 1'b1, 1'b0); 

endmodule


module yID(rd1, rd2, immOut, jTarget, branch, ins, wd, RegWrite, clk);
    output [31:0] rd1, rd2, immOut;
    output [31:0] jTarget;

    input [31:0] ins, wd;
    input RegWrite, clk;

output [31:0] branch;
    wire [19:0] zeros, ones; // For I-Type and SB-Type 
    wire [11:0] zerosj, onesj; // For UJ-Type
    wire [31:0] imm, saveImm; // For S-Type

    rf myRF(rd1, rd2, ins[19:15], ins[24:20], ins[11:7], wd, clk, RegWrite);

    assign imm[11:0] = ins[31:20];
    assign zeros = 20'h00000;
    assign ones = 20'hFFFFF;

    yMux #(20) se(imm[31:12], zeros, ones, ins[31]);

    assign saveImm[11:5] = ins[31:25];
    assign saveImm[4:0] = ins[11:7];

    yMux #(20) saveImmSe(saveImm[31:12], zeros, ones, ins[31]);
    yMux #(32) immSelection(immOut, imm, saveImm, ins[5]);

    assign branch[11] = ins[31];
    assign branch[10] = ins[7];
    assign branch[9:4] = ins[30:25];
    assign branch[3:0] = ins[11:8];
    yMux #(20) bra(branch[31:12], zeros, ones, ins[31]);

    assign zerosj = 12'h000;
    assign onesj = 12'hFFF;
    assign jTarget[19] = ins[31];
    assign jTarget[18:11] = ins[19:12];
    assign jTarget[10] = ins[20];
    assign jTarget[9:0] = ins[30:21];
    yMux #(12) jum(jTarget[31:20], zerosj, onesj, jTarget[19]);
endmodule

module yEX(z, zero, rd1, rd2, imm, op, ALUSrc);
output [31:0] z;
output zero;
input [31:0] rd1, rd2, imm;
input [2:0] op;
input ALUSrc;
wire [31:0] MUXout;

    yMux #(32) reg_or_imm(MUXout, rd2, imm, ALUSrc);
    yAlu execAlu(z, zero, rd1, MUXout, op);
endmodule