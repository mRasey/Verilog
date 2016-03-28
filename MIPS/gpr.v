`timescale 1ns / 1ps

module gpr(A1, A2, A3_WB, WE, Clk, Reset, RD1, RD2, WD
    );
	input [4:0] A1, A2, A3_WB;
	input WE, Clk, Reset;
	input [31:0] WD;
	output [31:0] RD1, RD2;
	reg [31:0] Data [0:31];
	integer i;
	
	assign RD1 = ((A1 == A3_WB) & (A1 != 0) & WE) ? WD : Data[A1]; //内部转发
	assign RD2 = ((A2 == A3_WB) & (A2 != 0) & WE) ? WD : Data[A2];
	
	always @ (posedge Clk or posedge Reset)
	begin
		if(Reset) begin
			for(i = 0; i < 32; i = i + 1) begin
				Data[i] <= 0;
			end
		end
		else if(WE == 1 & A3_WB != 0) begin	
			$display("$%d <= %x", A3_WB, WD);
			Data[A3_WB] <= WD;
		end
	end
	
	/*always @ (Reset)
	begin
		for(i = 0; i < 32; i = i + 1)
		begin
			Data[i] <= 0;
		end
	end*/


endmodule
