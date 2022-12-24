module labM;
reg [31:0] PCin;
reg RegWrite, clk, ALUSrc; 
reg [2:0] op;
wire [31:0] wd, rd1, rd2, imm, ins, PCp4, z,branch; 
wire [31:0] jTarget;
wire zero;
yIF myIF(ins, PCp4, PCin, clk);
yID myID(rd1, rd2, imm, jTarget, branch, ins, wd, RegWrite, clk);
yEX myEx(z, zero, rd1, rd2, imm, op, ALUSrc);
assign wd = z;


initial
begin
    //------------------------------------Entry point 
    PCin = 16'h28;
    //------------------------------------Run program 
    repeat (11)
    begin
    //---------------------------------Fetch an ins 
    clk = 1; #1;
    //---------------------------------Set control signals 
    RegWrite = 0; 
    ALUSrc = 1; 
    op = 3'b010;
    // Add statements to adjust the above defaults
    //---------------------------------Execute the ins 
    clk = 0; #1;
    //---------------------------------View results
    $display("ins=%h, rd1=%h, rd2=%h, imm=%h, jTarget=%h, z=%h, zero=%h",ins, rd1,rd2,imm,jTarget,z,zero);
    //---------------------------------Prepare for the next ins 
    PCin = PCp4;
      end
      $finish;
end
endmodule