`timescale 1ns / 1ps

module CPU(
	Clk, Reset, DEV_to_CPU_RD, DEV_break_SUM, ALU_DEV_Addr, PrBE, RD2_to_DEV, DEV_WE_MEM
);
	input Clk ,Reset;
	input [31:0] DEV_to_CPU_RD;//从Bridge模块读入的数据
	input [7:2] DEV_break_SUM;//设备中断信号
	output [31:0] ALU_DEV_Addr;//32位地址总线
	output [3:0] PrBE;//写使能
	output [31:0] RD2_to_DEV;//写到设备的值
	output DEV_WE_MEM;//CPU写使能


	wire [31:0] oder_ID;
	wire [1:0] EXTOp;
	wire [3:0] branchop;
	wire [4:0] ALUOp;
	wire MemWrite, GprWrite, Mem2Gpr, ALUSrc, RegDst, branch, Is_Move;
	wire [4:0] rt, rs;
	wire [1:0] mndop;
	wire mnd, mnd_we;
	wire hi_lo_sel;
	wire HiLo;
	wire is_eret;
	wire is_mtc0;

	controller controller(/*autoinst*/
			.ALUOp(ALUOp[4:0]),
			.branchop(branchop[3:0]),
			.EXTOp(EXTOp[1:0]),
			.MemWrite(MemWrite),
			.GprWrite(GprWrite),
			.Mem2Gpr(Mem2Gpr),
			.ALUSrc(ALUSrc),
			.RegDst(RegDst),
			.branch(branch),
			.mnd(mnd),
			.mnd_we(mnd_we),  
			.mndop(mndop[1:0]),
			.hi_lo_sel(hi_lo_sel), 
			.HiLo(HiLo), 
			.is_eret(is_eret),
			.is_mtc0(is_mtc0), 
			//
			.Opcode(oder_ID[31:26]),
			.Func(oder_ID[5:0]),
			.rt(rt), 
			.rs(rs)
		);

	datapath datapath(/*autoinst*/
			.oder_ID(oder_ID[31:0]),
			.rt(rt),
			.rs(rs), 
			.ALU_DEV_Addr(ALU_DEV_Addr[31:0]),
			.PrBE(PrBE[3:0]),
			.RD2_to_DEV(RD2_to_DEV[31:0]),
			.DEV_WE_MEM(DEV_WE_MEM),
			//
			.Clk(Clk),
			.Reset(Reset),
			.ALUOp(ALUOp[4:0]),
			.branchop(branchop[3:0]),
			.EXTOp(EXTOp[1:0]),
			.branch(branch),
			.MemWrite(MemWrite),
			.GprWrite(GprWrite),
			.Mem2Gpr(Mem2Gpr),
			.ALUSrc(ALUSrc),
			.RegDst(RegDst),
			.mnd(mnd), 
			.mnd_we(mnd_we), 
			.mndop(mndop[1:0]), 
			.hi_lo_sel(hi_lo_sel), 
			.HiLo(HiLo), 
			.is_eret(is_eret), 
			.is_mtc0(is_mtc0),
			.DEV_to_CPU_RD(DEV_to_CPU_RD[31:0]),
			.DEV_break_SUM(DEV_break_SUM[7:2]) 
		);

endmodule
