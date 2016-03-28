`timescale 1ns / 1ps

module CMP(
	A, B, Op, 
	Br    
);
	input [31:0] A, B;
	input [3:0] Op;
	output Br;

	assign Br =  ((Op == 4'b0000) & (A == B)) //beq
			   | ((Op == 4'b0100) & (A != B)) //bne
			   | ((Op == 4'b0101) & ($signed(A) <= $signed(0))) //blez
			   | ((Op == 4'b0110) & ($signed(A) > $signed(0))) //bgtz
			   | ((Op == 4'b0111) & ($signed(A) < $signed(0))) //bltz
			   | ((Op == 4'b1000) & ($signed(A) >= $signed(0))); //bgez


endmodule
