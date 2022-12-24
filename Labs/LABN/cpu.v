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

module yIF(ins,PC,PCp4, PCin, clk);

    output [31:0] ins, PC, PCp4;
    input [31:0] PCin;
    input clk;

    wire zero;
    wire read, write, enable;
    wire [31:0] a, memIn;
    wire [2:0] op;
    
    register #(32) my_pcReg(PC, PCin, clk, enable);
    mem myMem(ins, PC, memIn , clk, read, write); 
    yAlu my_alu(PCp4, zero, a, PC, op);

    assign enable = 1'b1;
    assign a = 32'h0004;
    assign op = 3'b010;
    assign read = 1'b1;
    assign write = 1'b0;

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

module yDM(memOut, exeOut, rd2, clk, MemRead, MemWrite);
    output [31:0] memOut;
    input [31:0] exeOut, rd2;
    input clk, MemRead, MemWrite;

    //instantiate the circuit
     mem myDM(memOut, exeOut, rd2, clk, MemRead, MemWrite);

endmodule

module yWB(wb, exeOut, memOut, Mem2Reg);
    output [31:0] wb;
    input [31:0] exeOut, memOut;
    input Mem2Reg;

    //instantiate the circuit
    yMux #(32) myWB(wb, exeOut, memOut, Mem2Reg);
endmodule

module yPC(PCin, PC, PCp4, INT, entryPoint, branchImm, jImm, zero, isBranch, isJump);
    output [31:0] PCin; 
    input [31:0] PC, PCp4, entryPoint, branchImm; 
    input [31:0] jImm; 
    input INT, zero, isBranch, isJump; 
    wire [31:0] branchImmX4, jImmX4, jImmX4PPCp4, bTarget, choiceA, choiceB; 
    wire doBranch, zf; 

    // Shifting left branchimm twice 
    assign branchImmX4[31:2] = branchImm[29:0]; 
    assign branchImmX4[1:0] = 2'b00; 

    // Shifting left jump twice 
    assign jImmX4[31:2] = jImm[29:0]; 
    assign jImmX4[1:0] = 2'b00; 

    // adding PC to shifted twice, 
    //Replace? in the yPC module with proper entries. 
    yAlu bALU(bTarget, zf, PC, branchImmX4, 3'b010); 
    
    // adding PC to shifted twice, jimm 
    //Replace? in the yPC module with proper entries. 
    yAlu jALU(jImmX4PPCp4, zf, PC, jImmX4, 3'b010); 

    // deciding to do branch 
    and (doBranch, isBranch, zero); 
    yMux #(32) mux1(choiceA, PCp4, bTarget, doBranch); 
    yMux #(32) mux2(choiceB, choiceA, jImmX4PPCp4, isJump); 
    yMux #(32) mux3(PCin, choiceB, entryPoint, INT); 
    
endmodule

module yC1(isStype, isRtype, isitype, isLw, isjump, isbranch, opCode);
    output isStype, isRtype, isitype, isLw, isjump, isbranch;
    input [6:0] opCode;
    wire lwor, ISselect, JBselect, sbz, sz;
    // opCode
    //     lw 0000011
    // I-Type 0010011    
    // S-Type 0100011
    // R-Type 0110011
    //SB-Type 1100011
    //UJ-Type 1101111

    // Detect UJ-type
    assign isjump=opCode[3];
    // Detect lw
    or (lwor, opCode[6], opCode[5], opCode[4], opCode[3], opCode[2]); 
    not (isLw, lwor);
    // Select between S-Type and I-Type
    xor (ISselect, opCode[6], opCode[5], opCode[4], opCode[3], opCode[2]);
    and (isStype, ISselect, opCode[5]);
    and (isitype, ISselect, opCode[4]);
    // Detect R-Type
    and (isRtype, opCode[5], opCode[4]);
    // Select between JAL and Branch
    and (JBselect, opCode[6], opCode[5]);
    not (sbz, opCode[3]);
    and (isbranch, JBselect, sbz);
endmodule

module yC2(RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, isStype, isRtype, isitype, isLw, isjump, isbranch);
    output RegWrite, ALUSrc,MemRead, MemWrite, Mem2Reg;
    input isStype, isRtype, isitype, isLw, isjump, isbranch;
    //You need two or gates and 3 assignments;

    
    nor (RegWrite, isStype, isbranch);
    nor (ALUSrc,isRtype,isbranch);

    assign Mem2Reg = isLw;
    assign MemRead = isLw;
    assign MemWrite = isStype;


endmodule

module yC3(ALUop, isRtype, isBranch);
output[1:0] ALUop;
input isRtype, isBranch;

assign ALUop[0] = isBranch;
assign ALUop[1] = isRtype;

endmodule

module yC4(op, ALUop, func3);
output[2:0] op;
input [2:0] func3;
input [1:0] ALUop;
wire w1,w2,w3,w4,w5;

xor(w1, func3[2], func3[1]);
xor(w2, func3[1], func3[0]);
and(w3,ALUop[1],w1);
and(op[0],ALUop[1],w2);
or(op[2], ALUop[0],w3);
not(w4,ALUop[1]);
not(w5,func3[1]);
or(op[1], w4,w5);


endmodule

module yChip(ins, rd2, wb, entryPoint, INT, clk);
    output [31:0] ins, rd2, wb;
    input [31:0] entryPoint;
    input INT, clk;
endmodule



