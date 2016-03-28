`timescale 1ns / 1ps

module im_4k(addr, dout
    );
	input [12:2] addr;
	output [31:0] dout;
	reg [31:0] im [0:2047];
	integer i;

	/*initial begin
		for(i = 0; i < 2048; i = i + 1)
			im[i] = 0;
	end*/

	assign dout = im[addr];
	initial begin
		$readmemh("main.txt", im);
		$readmemh("handler.txt", im, 11'h460, 11'h7ff);		
	end

	//initial $readmemh("code.txt", im);
endmodule
