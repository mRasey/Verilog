`timescale 1ns / 1ps

module text_mips;

	// Inputs
	reg clk;
	reg reset;

	// Instantiate the Unit Under Test (UUT)
	mips uut (
		.clk(clk), 
		.reset(reset)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 1;
		#1 reset = ~reset;

	end
      
	always #2 clk = ~clk;
	
endmodule

