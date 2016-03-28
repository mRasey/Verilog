`timescale 1ns / 1ps

module mult_div(
	D1, D2, HiLo, Op, Start, We, Clk, Rst, Exception,
	Busy, HI, LO 
);
	input [31:0] D1, D2;
	input [1:0] Op;
	input Start;
	input HiLo;
	input We, Clk, Rst;
	input Exception;
	output [31:0] HI, LO;
	output reg Busy;
	reg [31:0] data [0:1];
	reg [31:0] D1_MD, D2_MD;
	reg [1:0] Op_MD;
	reg [31:0] hi;
	reg [31:0] lo;
	//reg We_MD;
	integer count;

	assign HI = data[1];
	assign LO = data[0];

	always @ (posedge Clk or posedge Rst) 
	begin
		if(Start & (Busy == 0))
		begin
			D1_MD <= D1;
			D2_MD <= D2;
			Op_MD <= Op;
			Busy <= 1;
		end

		if(Clk | Rst) begin
			if(Rst)
			begin
				count <= 0;
				Busy <= 0;
				D1_MD <= 0;
				D2_MD <= 0;
				Op_MD <= 0;
				data[0] <= 0;
				data[1] <= 0;
			end
			else if(Exception & (count == 1)) begin
				count <= 0;
				Busy <= 0;
				D1_MD <= 0;
				D2_MD <= 0;
				Op_MD <= 0;
				//hi <= 0;
				//lo <= 0;
			end
			else if(Busy == 1) //可以写入且乘法器空闲
			begin
				if(Op_MD == 2'b00) //无符号乘法
					//{data[1], data[0]} <= D1_MD * D2_MD;
					{hi, lo} <= D1_MD * D2_MD;
				else if(Op_MD == 2'b01) //符号乘法
					//{data[1], data[0]} <= $signed(D1_MD) * $signed(D2_MD);
					{hi, lo} <= $signed(D1_MD) * $signed(D2_MD);
				else if(Op_MD == 2'b10) //无符号除法
				begin
					//data[0] <= D1_MD / D2_MD;
					//data[1] <= D1_MD % D2_MD;
					lo <= D1_MD / D2_MD;
					hi <= D1_MD % D2_MD;
				end
				else if(Op_MD == 2'b11) //符号除法
				begin
					//data[0] <= $signed(D1_MD) / $signed(D2_MD);
					//data[1] <= $signed(D1_MD) % $signed(D2_MD);
					lo <= $signed(D1_MD) / $signed(D2_MD);
					hi <= $signed(D1_MD) % $signed(D2_MD);
				end

				count <= count + 1;

				if((Op_MD == 2'b00) & (count == 5)) //无符号乘法
				begin
					{data[1], data[0]} <= {hi, lo};	
					count <= 0;
					Busy <= 0;
				end
				else if((Op_MD == 2'b01) & (count == 5)) //符号乘法
				begin
					{data[1], data[0]} <= {hi, lo};	
					Busy <= 0;
					count <= 0;
				end
				else if((Op_MD == 2'b10) & (count == 10)) //无符号除法
				begin
					{data[1], data[0]} <= {hi, lo};	
					Busy <= 0;
					count <= 0;
				end 
				else if((Op_MD == 2'b11) & (count == 10)) //符号除法
				begin
					{data[1], data[0]} <= {hi, lo};	
					Busy <= 0;
					count <= 0;
				end
			end
			//可以写入		
			if(We & (!Exception))
				data[HiLo] <= D1;
		end
	end

endmodule
