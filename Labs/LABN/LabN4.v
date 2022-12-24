module labN;
//reg [31:0] PCin;
wire RegWrite, ALUSrc, Mem2Reg, MemRead, MemWrite; 
wire [1:0] ALUop;
wire[2:0] func3;
wire [2:0] op;
reg [6:0] opCode;
reg INT,clk;
reg [31:0] entryPoint;
wire [31:0] wd, rd1, rd2, imm, ins, PCp4, z,branch, PC , PCin; 
wire [31:0] jTarget, memOut, wb;
wire zero,isStype, isRtype, isitype, isLw , isJump, isBranch;
yIF myIF(ins,PC, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(z, zero, rd1, rd2, imm, op, ALUSrc);
yDM myDM(memOut, z, rd2, clk, MemRead, MemWrite);
yWB myWB(wb, z, memOut, Mem2Reg);
yPC myPC(PCin,PC,PCp4,INT,entryPoint,branch,jTarget,zero, isBranch,isJump);
yC1 myC1(isStype, isRtype, isitype, isLw, isJump, isBranch, ins[6:0]);
yC2 myC2(RegWrite, ALUSrc, MemRead, MemWrite, Mem2Reg, isStype, isRtype, isitype, isLw, isJump, isBranch);
yC3 myC3(ALUop, isRtype, isBranch);
assign func3=ins[14:12];
yC4 myC4(op, ALUop, func3);
assign wd = wb;


initial
begin
    //------------------------------------Entry point 
    INT = 1;
    entryPoint = 16'h28;
    //PCin = 16'h28;
    #1
    //------------------------------------Run program 
    repeat (43)
    begin
      //---------------------------------Fetch an ins 
      clk = 1; #1;
      INT =0;
      
      
      // Add statements to adjust the above defaults
      //---------------------------------Execute the ins 
      clk = 0; #1;
      //---------------------------------View results
      
      $display("PC=%h, ins=%h: rd1=%2d, rd2=%2d, z=%3d, zero=%1b, wb=%2d",PCin,ins, rd1,rd2,z,zero, wb);
      //---------------------------------Prepare for the next ins 
      /*if(INT ==1)
        PCin = entryPoint;
      else if((ins[6:0]==7'b1100011) && (zero ==0))
        PCin = PCin + (imm << 2);
      else if(ins[6:0]==7'b1101111)
        PCin = PCin + (jTarget<<2);
      else
        PCin = PCp4;*/
    end
    $finish;
end
endmodule