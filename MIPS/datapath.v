`timescale 1ns / 1ps

module datapath(
	Clk, Reset,  ALUOp, EXTOp, branch, branchop, MemWrite, mnd, 
		mnd_we, mndop, hi_lo_sel, HiLo, DEV_to_CPU_RD, DEV_break_SUM, 
		is_eret, is_mtc0,
	GprWrite, Mem2Gpr, ALUSrc, RegDst, oder_ID, rs, rt, ALU_DEV_Addr, PrBE, 
		RD2_to_DEV, DEV_WE_MEM
);
	input Clk, Reset;
	input [1:0] EXTOp;
	input [3:0] branchop;
	input [4:0] ALUOp;
	input branch, MemWrite, GprWrite, Mem2Gpr, ALUSrc, RegDst;
	input hi_lo_sel;
	input HiLo;
	input [1:0] mndop;
	input mnd, mnd_we;
	input is_eret;
	input is_mtc0;
	input [31:0] DEV_to_CPU_RD;//从Bridge模块读入的数据
	input [7:2] DEV_break_SUM;//设备中断信号
	output [31:0] ALU_DEV_Addr;//32位地址总线
	output [3:0] PrBE;//写使能
	output [31:0] RD2_to_DEV;//写到设备的值
	output DEV_WE_MEM;//CPU写使能
	output [31:0] oder_ID;
	output [4:0] rt;
	output [4:0] rs;

	wire [31:0] RD1, RD1_ID, RD1_EX, RD2, RD2_ID, RD2_EX , RD2_MEM , EXT32, 
		EXT_Out, EXT_Out_EX, WD, ALU_Result, ALU_Result_MEM , ALU_Result_WB, 
		RAM_Load, RAM_Load_WB, oder, ALU_RD1, ALU_RD2, Jal_addr, 
		Jal_addr_EX, Jal_addr_MEM, Jal_addr_WB;
	wire [31:2] PC_IF, PC_ID, PC_EX, PC_MEM, NPC; 
	wire [4:0] A3, A3_MEM, A3_WB, rs_EX, rt_EX, rd_EX;
	wire [4:0] rs_MEM, rs_WB;
	wire [2:0] EXTOp_EX, mux_RD1_EX, mux_RD2_EX;
	wire [4:0] ALUOp_EX;
	wire Zero, En_IF, En_ID, Mem2Gpr_EX, 
		Mem2Gpr_MEM, Mem2Gpr_WB, MemWrite_EX, MemWrite_MEM,
		GprWrite_EX, GprWrite_MEM, GprWrite_WB, RegDst_EX, ALUSrc_EX;
	wire [2:0] mux_RD1, mux_RD2;
	wire [5:0] Opcode = oder_ID[31:26];
	wire [5:0] Opcode_EX, Opcode_MEM, Opcode_WB;
	wire [4:0] rs = oder_ID[25:21];
	wire [4:0] rt = oder_ID[20:16];
	wire [4:0] rd = oder_ID[15:11];
	wire [4:0] shamt = oder_ID[10:6];
	wire [4:0] shamt_EX;
	wire [5:0] Func = oder_ID[5:0];
	wire [5:0] Func_EX, Func_MEM, Func_WB;
	wire [3:0] branchop_EX, branchop_MEM, branchop_WB;
	wire [31:2] J_PC_ID, Jal_PC_ID, Jr_PC_ID, B_PC_ID;
	wire [31:0] Load_Word;
	wire [31:0] oder_EX, oder_MEM, oder_WB;
	wire [31:0] HI;
	wire [31:0] LO;
	wire Busy;
	wire mnd_we_EX;
	wire HiLo_EX;
	wire Br;
	wire mnd_EX;
	wire [1:0] mndop_EX;
	wire [31:0] ALU_RD1_Sel; //将shamt扩充为32位
	wire [31:0] hi_lo_result, hi_lo_result_MEM, hi_lo_result_WB;
	wire hi_lo_sel_EX;
	wire [3:0] BE;
	//wire [31:0] slt_WD;
	//wire is_slt;
	wire Clr_IF, Clr_ID, Clr_EX, Clr_MEM, Clr_WB;
	wire is_eret_EX, is_eret_MEM, is_eret_WB;
	wire [31:2] EPC;
	wire IntReq;
	wire Over;
	wire dm_Over;
	wire Exception;
	wire Over_MEM;
	wire [4:0] rd_MEM;
	wire [31:0] CP0_Out_MEM, CP0_Out_WB; //CP0_Out, 
	wire is_mtc0_EX;
	wire branch_EX, branch_MEM, branch_WB;
	wire is_mtc0_MEM;
	wire [31:0] ALL_PC = {NPC, 2'b00};
	wire [31:0] ALL_EPC = {EPC,2'b00}; 


	assign RD2_to_DEV = RD2_MEM;//将将要sw的值输出到bridge
	assign ALU_DEV_Addr = ALU_Result_MEM;//ALU运算结果作为寻找设备的地址
	assign PrBE = 4'b0000;//
	assign DEV_WE_MEM = MemWrite_MEM;//DM的写使能
	

	wire [31:0] real_PC_IF = {PC_IF, 2'b00} - 32'h3000; 
	im_4k im_4k(
			.dout(oder),
			//
			.addr(real_PC_IF[12:2])
		);


	pipe_reg_IF pipe_reg_IF(	
			.PC_IF(PC_IF[31:2]),
			//
			.Clk(Clk),
			.Clr_IF(Clr_IF),  
			.En(En_IF),
			.Reset(Reset), 
			.PC(NPC[31:2]),
			.Exception(Exception)
		);

	mux_J_PC mux_J_PC(/*autoinst*/
			.J_PC_ID(J_PC_ID[31:2]),
			.B_PC_ID(B_PC_ID[31:2]),
			.Jr_PC_ID(Jr_PC_ID[31:2]),
			.Jal_PC_ID(Jal_PC_ID[31:2]),
			.Jal_addr(Jal_addr[31:0]), //PC+8 
			//
			.oder_ID(oder_ID[31:0]),
			.PC_ID(PC_ID[31:2]),
			.RD1_ID(RD1_ID[31:0])
		);

	CMP CMP(/*autoinst*/
			.Br(Br),
			//
			.A(RD1_ID[31:0]),
			.B(RD2_ID[31:0]),
			.Op(branchop[3:0])
		);

	mux_PC mux_PC(/*autoinst*/
			.NPC(NPC[31:2]),
			//
			.J_PC_ID(J_PC_ID[31:2]),
			.B_PC_ID(B_PC_ID[31:2]),
			.Jr_PC_ID(Jr_PC_ID[31:2]),
			.Jal_PC_ID(Jal_PC_ID[31:2]),
			.PC_IF(PC_IF[31:2]),
			.branch(branch),
			.Br(Br),
			.branchop(branchop[3:0]),
			.rt(rt), 
			.is_eret(is_eret),
			.is_mtc0_EX(is_mtc0_EX),
			.is_mtc0_MEM(is_mtc0_MEM),
			.ALU_RD2(ALU_RD2),
			.RD2_MEM(RD2_MEM),
			.EPC(EPC[31:2]), 
			//.IntReq(IntReq),
			.Exception(Exception),
			.rd_EX(rd_EX),
			.rd_MEM(rd_MEM)  
		);

	

	pipe_reg_ID pipe_reg_ID(/*autoinst*/
			.oder_ID(oder_ID[31:0]),
			.PC_ID(PC_ID[31:2]),
			//
			.Clk(Clk),
			.Clr_ID(Clr_ID), 
			.Reset(Reset),
			.En_ID(En_ID),
			.oder(oder[31:0]),
			.PC_IF(PC_IF[31:2])
		);

	
	gpr gpr(
			.RD1(RD1), 
			.RD2(RD2),
			//
			.A1(rs), 
			.A2(rt), 
			.A3_WB(A3_WB),
			.WE(GprWrite_WB), 
			.Clk(Clk), 
			.Reset(Reset), 
			.WD(WD[31:0])
		);

	mux_RD_AM mux_RD1_AM(/*autoinst*/
			.RD_ID(RD1_ID[31:0]),
			//
			.RD(RD1[31:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]),
			.hi_lo_result_MEM(hi_lo_result_MEM[31:0]), 
			.mux_RD(mux_RD1[2:0]), 
			.Jal_addr_MEM(Jal_addr_MEM[31:0]), 
			.CP0_Out_MEM(CP0_Out_MEM[31:0])
		);

	mux_RD_AM mux_RD2_AM(/*autoinst*/
			.RD_ID(RD2_ID[31:0]),
			//
			.RD(RD2[31:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]),
			.hi_lo_result_MEM(hi_lo_result_MEM[31:0]), 
			.mux_RD(mux_RD2[2:0]), 
			.Jal_addr_MEM(Jal_addr_MEM[31:0]), 
			.CP0_Out_MEM(CP0_Out_MEM[31:0])
		);

	pipe_reg_EX pipe_reg_EX(/*autoinst*/
			.RegDst_EX(RegDst_EX),
			.ALUSrc_EX(ALUSrc_EX),
			.Mem2Gpr_EX(Mem2Gpr_EX),
			.GprWrite_EX(GprWrite_EX),
			.MemWrite_EX(MemWrite_EX),
			.ALUOp_EX(ALUOp_EX[4:0]),
			.EXTOp_EX(EXTOp_EX[1:0]),
			.RD1_EX(RD1_EX[31:0]),
			.RD2_EX(RD2_EX[31:0]),
			.rs_EX(rs_EX[4:0]),
			.rt_EX(rt_EX[4:0]),
			.rd_EX(rd_EX[4:0]),
			.EXT_Out_EX(EXT_Out_EX[31:0]),
			.Jal_addr_EX(Jal_addr_EX[31:0]),
			.branchop_EX(branchop_EX[3:0]),
			.Opcode_EX(Opcode_EX),
			.Func_EX(Func_EX),
			.shamt_EX(shamt_EX),
			.mnd_EX(mnd_EX),
			.mndop_EX(mndop_EX),
			.hi_lo_sel_EX(hi_lo_sel_EX),
			.mnd_we_EX(mnd_we_EX),
			.HiLo_EX(HiLo_EX),     
			.oder_EX(oder_EX),
			.PC_EX(PC_EX),
			.is_eret_EX(is_eret_EX),
			.is_mtc0_EX(is_mtc0_EX),
			.branch_EX(branch_EX),  
			//
			.Clk(Clk),
			.Clr_EX(Clr_EX),
			.Reset(Reset),
			.RegDst(RegDst),
			.ALUSrc(ALUSrc),
			.Mem2Gpr(Mem2Gpr),
			.GprWrite(GprWrite),
			.MemWrite(MemWrite),
			.rs(rs[4:0]),
			.rt(rt[4:0]),
			.rd(rd[4:0]),
			.ALUOp(ALUOp[4:0]),
			.EXTOp(EXTOp[1:0]),
			.RD1(RD1[31:0]),
			.RD2(RD2[31:0]),
			.EXT_Out(EXT_Out[31:0]),
			.Jal_addr(Jal_addr[31:0]),
			.branchop(branchop[3:0]),
			.Opcode(Opcode),
			.Func(Func),
			.shamt(shamt), 
			.mnd(mnd), 
			.mndop(mndop), 
			.hi_lo_sel(hi_lo_sel),
			.mnd_we(mnd_we), 
			.HiLo(HiLo),
			.oder_ID(oder_ID), 
			.PC_ID(PC_ID),
			.is_eret(is_eret),
			.is_mtc0(is_mtc0),
			.branch(branch)
		);

	mux_R_W_A mux_RD1_W_A(/*autoinst*/
			.ALU_RD(ALU_RD1[31:0]),
			//
			.mux_RD_EX(mux_RD1_EX[2:0]),
			.RD_EX(RD1_EX[31:0]),
			.WD(WD[31:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]), 
			.hi_lo_result_MEM(hi_lo_result_MEM[31:0]),
			.Jal_addr_MEM(Jal_addr_MEM),  
			.CP0_Out_MEM(CP0_Out_MEM[31:0])
		);

	mux_R_W_A mux_RD2_W_A(/*autoinst*/
			.ALU_RD(ALU_RD2[31:0]),
			//
			.mux_RD_EX(mux_RD2_EX[2:0]),
			.RD_EX(RD2_EX[31:0]),
			.WD(WD[31:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]), 
			.hi_lo_result_MEM(hi_lo_result_MEM[31:0]),
			.Jal_addr_MEM(Jal_addr_MEM),  
			.CP0_Out_MEM(CP0_Out_MEM[31:0])
		);

	mux_RegDst mux_RegDst(
			.out(A3),
			//
			.rt(rt_EX), 
			.rd(rd_EX), 
			.RegDst(RegDst_EX), 
			.branchop_EX(branchop_EX)
		);

	ext ext(
			.out(EXT_Out),
			//
			.in(oder_ID[15:0]), 
			.Op(EXTOp)
		);

	mux_ALUSrc mux_ALUSrc(
			.EXT32(EXT32),
			//
			.RD2(ALU_RD2), 
			.EXT_Out(EXT_Out_EX), 
			.ALUSrc(ALUSrc_EX)
		);

	mux_shamt_EX_ALU_RD1 mux_shamt_EX_ALU_RD1(/*autoinst*/
			.ALU_RD1_Sel(ALU_RD1_Sel[31:0]),
			//
			.shamt_EX(shamt_EX[4:0]),
			.ALU_RD1(ALU_RD1[31:0]),
			.ALUOp_EX(ALUOp_EX[4:0])
		);

	alu alu(
			.Result(ALU_Result),
			.Over(Over),
			.Zero(Zero),
			.Great(Great), 
			.Less(Less), 
			//
			.A(ALU_RD1_Sel[31:0]), 
			.B(EXT32), 
			.ALUOp_EX(ALUOp_EX[4:0])
		);

	mult_div mult_div(/*autoinst*/
			.HI(HI[31:0]),
			.LO(LO[31:0]),
			.Busy(Busy),
			//
			.D1(ALU_RD1_Sel[31:0]),
			.D2(EXT32[31:0]),
			.Op(mndop_EX[1:0]),
			.Start(mnd_EX),
			.HiLo(HiLo_EX),
			.We(mnd_we_EX),
			.Exception(Exception),
			.Clk(Clk),
			.Rst(Reset)
		);

	mux_HI_LO mux_HI_LO(/*autoinst*/
			.hi_lo_result(hi_lo_result[31:0]),
			//
			.HI(HI[31:0]),
			.LO(LO[31:0]),
			.hi_lo_sel_EX(hi_lo_sel_EX)
		);


	pipe_reg_MEM pipe_reg_MEM(/*autoinst*/
			.GprWrite_MEM(GprWrite_MEM),
			.Mem2Gpr_MEM(Mem2Gpr_MEM),
			.MemWrite_MEM(MemWrite_MEM),
			.A3_MEM(A3_MEM[4:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]),
			.RD2_MEM(RD2_MEM[31:0]),
			.Jal_addr_MEM(Jal_addr_MEM[31:0]),
			.branchop_MEM(branchop_MEM[3:0]),
			.Opcode_MEM(Opcode_MEM),
			.Func_MEM(Func_MEM),
			.hi_lo_result_MEM(hi_lo_result_MEM),
			.oder_MEM(oder_MEM), 
			.PC_MEM(PC_MEM),
			//.CP0_Out_MEM(CP0_Out_MEM),
			.rs_MEM(rs_MEM[4:0]),
			.rd_MEM(rd_MEM[4:0]),    
			.Over_MEM(Over_MEM),
			.is_eret_MEM(is_eret_MEM),
			.is_mtc0_MEM(is_mtc0_MEM),
			.branch_MEM(branch_MEM),
			//
			.Clk(Clk),
			.Clr_MEM(Clr_MEM), 
			.Reset(Reset),
			.GprWrite_EX(GprWrite_EX),
			.Mem2Gpr_EX(Mem2Gpr_EX),
			.MemWrite_EX(MemWrite_EX),
			.A3(A3[4:0]),
			.ALU_Result(ALU_Result[31:0]),
			.RD2_EX(ALU_RD2[31:0]),
			.Jal_addr_EX(Jal_addr_EX[31:0]),
			.branchop_EX(branchop_EX[3:0]),
			.Opcode_EX(Opcode_EX),
			.Func_EX(Func_EX),
			.hi_lo_result(hi_lo_result), 
			.oder_EX(oder_EX), 
			.PC_EX(PC_EX), 
			//.CP0_Out(CP0_Out), 
			.rs_EX(rs_EX[4:0]),
			.rd_EX(rd_EX[4:0]),
			.Over(Over),
			.is_eret_EX(is_eret_EX),
			.is_mtc0_EX(is_mtc0_EX),
			.branch_EX(branch_EX)
		);


	CP0 CP0(/*autoinst*/
			.CP0_Out_MEM(CP0_Out_MEM[31:0]), 
			.EPC(EPC[31:2]), 
			.IntReq(IntReq), 
			.Exception(Exception),//异常
			//
			.Clk(Clk),
			.Reset(Reset),
			.DEV_break_SUM(DEV_break_SUM[7:2]), //HWInt
			//.Over_MEM(Over_MEM),
			//.dm_Over(dm_Over),
			//.PC_ID(PC_ID[31:2]),
			//.PC_EX(PC_EX[31:2]),
			.PC_MEM(PC_MEM[31:2]), 
			.rd_MEM(rd_MEM[4:0]),//mfc0 
			.rs_MEM(rs_MEM[4:0]), //mtc0
			.RD2_MEM(RD2_MEM[31:0]), 
			.Opcode_MEM(Opcode_MEM[5:0]), 
			.is_eret(is_eret),//EXLClr
			.branch_WB(branch_WB)//判断是否为跳转
		);	


	/*mux_dm_Over mux_dm_Over(
			.dm_Over(dm_Over), //取值溢出标志
			//
			.ALU_Result_MEM(ALU_Result_MEM[31:2]), 
			.MemWrite_MEM(MemWrite_MEM)
		);*/

	dm_4k dm_4k(
			.RD(RAM_Load),
			//
			.BE(BE[3:0]),
			.A(ALU_Result_MEM[12:2]), 
			.WD(RD2_MEM), 
			.WE(MemWrite_MEM), 
			.Clk(Clk), 
			.Reset(Reset),
			.DEV_to_CPU_RD(DEV_to_CPU_RD),
			.Exception(Exception) //异常信号
		);

	mux_BE mux_BE(/*autoinst*/
			.BE(BE[3:0]),
			//
			.Opcode_MEM(Opcode_MEM[5:0]),
			.ALU_Result_MEM(ALU_Result_MEM[31:0]));

	//wire [31:0] DEV_to_CPU_RD_WB;
	//wire Exception_WB;
	pipe_reg_WB pipe_reg_WB(/*autoinst*/
			.GprWrite_WB(GprWrite_WB),
			.Mem2Gpr_WB(Mem2Gpr_WB),
			.A3_WB(A3_WB[4:0]),
			.RAM_Load_WB(RAM_Load_WB[31:0]),
			.ALU_Result_WB(ALU_Result_WB[31:0]),
			.Jal_addr_WB(Jal_addr_WB[31:0]),
			.branchop_WB(branchop_WB[3:0]),
			.Opcode_WB(Opcode_WB),
			.Func_WB(Func_WB),
			.hi_lo_result_WB(hi_lo_result_WB),
			.oder_WB(oder_WB),
			.CP0_Out_WB(CP0_Out_WB[31:0]),
			.rs_WB(rs_WB[4:0]),    
			.branch_WB(branch_WB),
			.is_eret_WB(is_eret_WB),
			//.DEV_to_CPU_RD_WB(DEV_to_CPU_RD_WB[31:0]),
			//.Exception_WB(Exception_WB),
			//
			.Clk(Clk),
			.Clr_WB(Clr_WB), 
			.Reset(Reset),
			.GprWrite(GprWrite_MEM),
			.Mem2Gpr(Mem2Gpr_MEM),
			.A3_MEM(A3_MEM[4:0]),
			.RAM_Load(RAM_Load[31:0]),
			.ALU_Result(ALU_Result_MEM[31:0]),
			.Jal_addr_MEM(Jal_addr_MEM[31:0]),
			.branchop_MEM(branchop_MEM[3:0]),
			.Opcode_MEM(Opcode_MEM),
			.Func_MEM(Func_MEM), 
			.hi_lo_result_MEM(hi_lo_result_MEM), 
			.oder_MEM(oder_MEM), 
			.CP0_Out_MEM(CP0_Out_MEM[31:0]), 
			.rs_MEM(rs_MEM[4:0]),
			.branch_MEM(branch_MEM),
			.is_eret_MEM(is_eret_MEM)
			//.DEV_to_CPU_RD(DEV_to_CPU_RD[31:0]),
			//.Exception(Exception)
		);


	mux_load_oder mux_load_oder(/*autoinst*/
			.Load_Word(Load_Word[31:0]),
			//
			.Opcode_WB(Opcode_WB[5:0]),
			.ALU_Result_WB(ALU_Result_WB[31:0]),
			.RAM_Load_WB(RAM_Load_WB[31:0])
			//.DEV_to_CPU_RD_WB(DEV_to_CPU_RD_WB)
			//.Exception_WB(Exception_WB)
		);

	mux_WD mux_WD(
			.WD(WD),
			//
			.ALU_Result_WB(ALU_Result_WB), 
			.Load_Word(Load_Word[31:0]),
			.Jal_addr_WB(Jal_addr_WB), 
			.Mem2Gpr_WB(Mem2Gpr_WB), 
			.branchop_WB(branchop_WB),
			.hi_lo_result_WB(hi_lo_result_WB), 
			.Opcode_WB(Opcode_WB), 
			.Func_WB(Func_WB), 
			.CP0_Out_WB(CP0_Out_WB), 
			.rs_WB(rs_WB)
		);

	hazard hazard(/*autoinst*/
			.En_IF(En_IF),
			.En_ID(En_ID),
			.mux_RD1(mux_RD1[2:0]),
			.mux_RD2(mux_RD2[2:0]),
			.Clr_ID(Clr_ID),
			.Clr_IF(Clr_IF),  
			.Clr_EX(Clr_EX),
			.Clr_MEM(Clr_MEM), 
			.Clr_WB(Clr_WB), 
			.mux_RD1_EX(mux_RD1_EX[2:0]),
			.mux_RD2_EX(mux_RD2_EX[2:0]),
			//
			.branch(branch),
			.Mem2Gpr_EX(Mem2Gpr_EX),
			.Mem2Gpr_MEM(Mem2Gpr_MEM),
			.GprWrite_EX(GprWrite_EX),
			.GprWrite_MEM(GprWrite_MEM),
			.GprWrite_WB(GprWrite_WB),
			.rs(rs[4:0]),
			.rt(rt[4:0]),
			.rs_EX(rs_EX[4:0]),
			.rt_EX(rt_EX[4:0]),
			.A3(A3[4:0]),
			.A3_MEM(A3_MEM[4:0]),
			.A3_WB(A3_WB[4:0]),
			.branchop(branchop),
			.branchop_EX(branchop_EX),
			.branchop_MEM(branchop_MEM),
			.oder_ID(oder_ID), 
			.Busy(Busy), 
			.mnd(mnd), 
			.mnd_we(mnd_we),
			.mnd_EX(mnd_EX),  
			.Opcode_EX(Opcode_EX[5:0]), 
			.Func_EX(Func_EX[5:0]), 
			.Opcode_MEM(Opcode_MEM[5:0]), 
			.Func_MEM(Func_MEM[5:0]),
			.rs_MEM(rs_MEM),  
			//.Error(Error), 
			//.Over_MEM(Over_MEM), 
			//.dm_Over(dm_Over), 
			//.DEV_break_SUM(DEV_break_SUM[7:2]), 
			.IntReq(IntReq),
			.Exception(Exception),
			.is_eret(is_eret)
		);

endmodule
