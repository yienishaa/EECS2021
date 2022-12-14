module testbench;
// Inputs to device under test (DUT) reg, outputs wire reg elk, reset;
	reg [31:0] instruction;
	initial begin
	$display("Time: %5d", $time, " Instruction: %8h", instruction);
	#10 instruction = 10;
	$display("Time: %5d Instruction: %8h", $time, instruction);
	#10 instruction = 20;
	$display("Time: %5d Instruction: %8h", $time, instruction);
	#10 instruction = 30;
	$display("Time: %5d Instruction: %8h", $time, instruction);
	$finish;
	end
endmodule
