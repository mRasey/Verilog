`timescale 1ns / 1ps

module dm_4k(
	A, WD, WE, Clk, BE, Reset, Exception, DEV_to_CPU_RD,
	RD 
);
	input [12:2] A;
	input [31:0] WD;
	input WE, Clk, Reset;
	input [3:0] BE;
	input Exception;
	input [31:0] DEV_to_CPU_RD;
	output [31:0] RD;
	reg [31:0] dm [0:2047];
	integer i;

	wire addr_is_DEV = (A >= 1984) & (A <= 1990);
	
	assign RD = (addr_is_DEV) ? DEV_to_CPU_RD : dm[A];
	
	always @ (posedge Clk or posedge Reset)
	begin
		if(Reset) begin
			for(i = 0; i < 2048; i = i + 1)
				dm[i] <= 0;
		end
		else if(WE == 1 & (!Exception) & (!addr_is_DEV)) begin //未发生异常并且不是写入设备
			case (BE)
				4'b0001 : begin 
					dm[A][7:0] <= WD[7:0];
					$display("*%x <= %x", {A,2'b00}, {dm[A][31:8], WD[7:0]}); end
				4'b0010 : begin 
					dm[A][15:8] <= WD[7:0];
					$display("*%x <= %x", {A,2'b00}, {dm[A][31:16], WD[7:0], dm[A][7:0]}); end
				4'b0100 : begin 
					dm[A][23:16] <= WD[7:0];
					$display("*%x <= %x", {A,2'b00}, {dm[A][31:24], WD[7:0], dm[A][15:0]}); end
				4'b1000 : begin 
					dm[A][31:24] <= WD[7:0];
					$display("*%x <= %x", {A,2'b00}, {WD[7:0], dm[A][23:0]}); end
				4'b0011 : begin 
					dm[A][15:0] <= WD[15:0];
					$display("*%x <= %x", {A,2'b00}, {dm[A][31:16], WD[15:0]}); end
				4'b1100 : begin 
					dm[A][31:16] <= WD[15:0];
					$display("*%x <= %x", {A,2'b00}, {WD[15:0], dm[A][15:0]}); end
				default : begin 
					dm[A] <= WD;
					$display("*%x <= %x", {A,2'b00}, WD); end
			endcase
		end
	end


endmodule
