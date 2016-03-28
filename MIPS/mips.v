`timescale 1ns / 1ps

module mips(
	clk, reset
);
	input clk, reset;

	wire [31:0] DEV_to_CPU_RD;
	wire [7:2] DEV_break_SUM;
	wire [3:2] DEV_Addr;
	wire [31:0] DEV_WD;
	wire WeDEV0, WeDEV1;
	wire [31:0] ALU_DEV_Addr;
	wire [31:0] RD2_to_DEV;
	wire [3:0] PrBE;
	wire DEV_WE_MEM;
	wire [31:0] DEV0_RD, DEV1_RD;
	wire DEV0_break, DEV1_break;
	//wire is_mtc0;

	CPU CPU(/*autoinst*/
			.ALU_DEV_Addr(ALU_DEV_Addr[31:0]),
			.PrBE(PrBE[3:0]),
			.RD2_to_DEV(RD2_to_DEV[31:0]),
			.DEV_WE_MEM(DEV_WE_MEM),
			//
			.Clk(clk),
			.Reset(reset),
			.DEV_to_CPU_RD(DEV_to_CPU_RD[31:0]), //从设备写回
			.DEV_break_SUM(DEV_break_SUM[7:2]) //设备中断信号
		);

	bridge bridge(/*autoinst*/
			.DEV_to_CPU_RD(DEV_to_CPU_RD[31:0]),
			.DEV_break_SUM(DEV_break_SUM[7:2]),
			.DEV_Addr(DEV_Addr[3:2]),
			.DEV_WD(DEV_WD[31:0]),
			.WeDEV0(WeDEV0),
			.WeDEV1(WeDEV1),
			//
			.ALU_DEV_Addr(ALU_DEV_Addr[31:0]),
			.RD2_to_DEV(RD2_to_DEV[31:0]),
			.DEV_WE_MEM(DEV_WE_MEM),
			.DEV0_RD(DEV0_RD[31:0]),
			.DEV1_RD(DEV1_RD[31:0]),
			.DEV0_break(DEV0_break),
			.DEV1_break(DEV1_break)
		);

	timer timer0(/*autoinst*/
			.DEV_RD(DEV0_RD[31:0]),
			//
			.clk(clk),
			.reset(reset),
			.DEV_Addr(DEV_Addr[3:2]),
			.WeDEV(WeDEV0),
			.DEV_WD(DEV_WD[31:0]),
			.DEV_break(DEV0_break)
		);

	timer timer1(/*autoinst*/
			.DEV_RD(DEV1_RD[31:0]),
			//
			.clk(clk),
			.reset(reset),
			.DEV_Addr(DEV_Addr[3:2]),
			.WeDEV(WeDEV1),
			.DEV_WD(DEV_WD[31:0]),
			.DEV_break(DEV1_break)
		);


endmodule
