`timescale 1ns / 1ps

module bridge(
	ALU_DEV_Addr, RD2_to_DEV, DEV_WE_MEM, DEV0_RD, DEV1_RD, DEV0_break, DEV1_break, 
	DEV_to_CPU_RD, DEV_break_SUM, DEV_Addr, DEV_WD, WeDEV0, WeDEV1
);
	input [31:0] ALU_DEV_Addr; //PrAddr 从CPU输入的取址信号
	input [31:0] RD2_to_DEV; //PrWD 从CPU输入的数据
	input DEV_WE_MEM; //PrWE CPU的写使能
	input [31:0] DEV0_RD; // 从设备0输入的值
	input [31:0] DEV1_RD; //从设备1输入的值
	input DEV0_break; //设备0的中断请求
	input DEV1_break; //设备1的中断请求
	output [31:0] DEV_to_CPU_RD; //DEV_RD 写回CPU的值
	output [7:2] DEV_break_SUM; //HWInt[7:2] 写回CPU的中断请求
	output [3:2] DEV_Addr; //译出的选择设备地址
	output [31:0] DEV_WD; //写入设备的值
	output WeDEV0; //设备0写使能
	output WeDEV1; //设备1写使能

	wire Choose_DEV0 = (ALU_DEV_Addr[31:4] == 28'h00007f0) ? 1 : 0; //CPU选择了设备0的地址
	wire Choose_DEV1 = (ALU_DEV_Addr[31:4] == 28'h00007f1) ? 1 : 0; //CPU选择了设备1的地址

	assign DEV_Addr = ALU_DEV_Addr[3:2];
	assign DEV_to_CPU_RD = (Choose_DEV0) ? DEV0_RD
						 : (Choose_DEV1) ? DEV1_RD
						 : 32'b0;
	assign DEV_WD = RD2_to_DEV;//由CPU通过桥写入设备
	assign WeDEV0 = Choose_DEV0 & DEV_WE_MEM;
	assign WeDEV1 = Choose_DEV1 & DEV_WE_MEM;
	assign DEV_break_SUM = {4'b0, DEV1_break, DEV0_break}; //000001 设备0中断 000010 设备1中断 


endmodule
