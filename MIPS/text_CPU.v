`timescale 1ns / 1ps

module text_CPU;

	// Inputs
	reg Clk;
	reg Reset;

	// Instantiate the Unit Under Test (UUT)
	CPU uut (
		.Clk(Clk), 
		.Reset(Reset)
	);

	initial begin
		// Initialize Inputs
		Clk = 0;
		Reset = 1;

		// Wait 100 ns for global reset to finish
		#1 Reset = ~Reset;
        
		// Add stimulus here

	end
	
	always #2 Clk = ~Clk;
      
endmodule

