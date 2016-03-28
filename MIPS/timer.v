`timescale 1ns / 1ps

module timer(
	clk, reset, DEV_Addr, WeDEV, DEV_WD, 
	DEV_RD, DEV_break    
);
	input clk; //时钟
	input reset; //复位信号
	input [3:2] DEV_Addr; //地址输入 DEV_Addr
	input WeDEV; //写使能
	input [31:0] DEV_WD; //32位数据输入
	output DEV_break;//中断请求
	output [31:0] DEV_RD;//32位数据输出
	reg [31:0] CTRL; //控制计数器
	reg [31:0] PRESET; //初始计数器的值
	reg [31:0] COUNT; //计数器的值

	always @ (posedge clk or posedge reset)
	begin
		if(reset) begin
			CTRL <= 32'b0;
			PRESET <= 32'b100;
			COUNT <= 32'b0;
		end
		else begin
			if(WeDEV) begin
				if(DEV_Addr[2] & (COUNT == 0)) begin //偏移为4选择PRESET寄存器
					PRESET <= DEV_WD;
					COUNT <= DEV_WD;
				end
				else begin //偏移为0选择CTRL寄存器
					CTRL[3:0] <= DEV_WD[3:0];
				end
			end
		end

		if(CTRL[0]) begin //计数使能为1
			if(COUNT > 0)
				COUNT <= COUNT - 1;
			else begin
				if(CTRL[2:1] == 2'b01) begin //模式01
					COUNT <= PRESET; //计数器赋初值
				end
			end
		end
	end

	assign DEV_RD = DEV_Addr[3] ? COUNT
				 : DEV_Addr[2] ? PRESET
				 : {28'b0, CTRL[3:0]};
	assign DEV_break = ((COUNT == 0) & CTRL[3] & (CTRL[2:1] == 2'b00)) ? 1 : 0; //允许中断且计数为0
	//只有模式0产生中断
endmodule
