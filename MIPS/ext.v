`timescale 1ns / 1ps

module ext(in, out, Op
    );
	input [15:0] in;
	output [31:0] out;
	input [1:0] Op; //00有符号， 01无符号， 10高位
	
	assign out = (Op == 2'b00) 
			   ? {{16{in[15]}}, in} : (Op == 2'b01) 
			   ? {{16{1'b0}}, in} : (Op == 2'b10)
			   ? {in, 16'b0} : 32'bx;


endmodule
