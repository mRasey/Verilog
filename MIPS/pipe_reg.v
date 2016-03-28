`timescale 1ns / 1ps

module pipe_reg_IF(
	Clk, Clr_IF, En, PC, Reset, Exception,
	PC_IF
);
	input Clk;
	input En;
	input Reset;
	input [31:2] PC;
	input Clr_IF;
	input Exception;
	output reg [31:2] PC_IF;
	localparam init_pc = 32'h0000_3000;
	always @ (posedge Clk or posedge Reset) 
	begin
		if(Reset | Clr_IF)
			PC_IF <= init_pc[31:2];		
	 	else if (En | Exception) begin
	 		PC_IF <= PC;	
	 	end
	 end 

endmodule

module pipe_reg_ID (
	Clk, Clr_ID, En_ID, oder, PC_IF, Reset,
	oder_ID, PC_ID
);
	input Clk;
	input Reset;
	input En_ID;
	input [31:0] oder;
	input [31:2] PC_IF;
	input Clr_ID;
	output reg [31:0] oder_ID;
	output reg [31:2] PC_ID;

	always @(posedge Clk or posedge Reset) 
	begin
		if(Reset | Clr_ID) begin
			oder_ID <= 0;
			PC_ID <= 0;
		end
		else if (En_ID) begin
			oder_ID <= oder;
			PC_ID <= PC_IF;
		end
	end

endmodule

module pipe_reg_EX (
	Clk, Clr_EX, Reset, RegDst, ALUSrc, Mem2Gpr, GprWrite, MemWrite, EXTOp, ALUOp,
		RD1, RD2, rs, rt, rd, EXT_Out, Jal_addr, branchop, Opcode, Func, shamt,
		mnd, mndop, hi_lo_sel, mnd_we, HiLo, oder_ID, PC_ID, is_eret, is_mtc0,
		branch,
	RegDst_EX, ALUSrc_EX, Mem2Gpr_EX, GprWrite_EX, MemWrite_EX, EXTOp_EX, ALUOp_EX, 
		RD1_EX, RD2_EX, rs_EX, rt_EX, rd_EX, EXT_Out_EX, Jal_addr_EX, branchop_EX, 
		Opcode_EX, Func_EX, shamt_EX, mnd_EX, mndop_EX, hi_lo_sel_EX, mnd_we_EX, 
		HiLo_EX, oder_EX, PC_EX, is_eret_EX, is_mtc0_EX, branch_EX
);
	input Clk, Clr_EX, Reset;
	input RegDst, ALUSrc, Mem2Gpr, GprWrite, MemWrite;
	input [4:0] rs, rt, rd;
	input [1:0] EXTOp;
	input [4:0] ALUOp;
	input [31:0] RD1, RD2, Jal_addr;
	input [31:0] EXT_Out;
	input [3:0] branchop;
	input [5:0] Opcode, Func;
	input [4:0] shamt;
	input mnd;
	input [1:0] mndop;
	input hi_lo_sel;
	input mnd_we;
	input HiLo;
	input [31:0] oder_ID;
	input [31:2] PC_ID;
	input is_eret;
	input is_mtc0;
	input branch;
	//input PC_ID;
	output reg RegDst_EX, ALUSrc_EX, Mem2Gpr_EX, GprWrite_EX, MemWrite_EX;
	output reg [1:0] EXTOp_EX;
	output reg [4:0] ALUOp_EX;
	output reg [31:0] RD1_EX, RD2_EX;
	output reg [4:0] rs_EX, rt_EX, rd_EX;
	output reg [31:0] EXT_Out_EX, Jal_addr_EX;
	output reg [3:0] branchop_EX;
	output reg [5:0] Opcode_EX, Func_EX;
	output reg [4:0] shamt_EX;
	output reg mnd_EX;
	output reg [1:0] mndop_EX;
	output reg hi_lo_sel_EX;
	output reg mnd_we_EX;
	output reg HiLo_EX;
	output reg [31:0] oder_EX;
	output reg [31:2] PC_EX;
	output reg is_eret_EX;
	output reg is_mtc0_EX;
	output reg branch_EX;

	always @(posedge Clk or posedge Reset) begin
		if (Reset | Clr_EX) 
		begin
			RegDst_EX <= 0;
			ALUSrc_EX <= 0;
			Mem2Gpr_EX <= 0;
			GprWrite_EX <= 0;
			MemWrite_EX <= 0;
			ALUOp_EX <= 0;
			EXTOp_EX <= 0;
			RD1_EX <= 0;
			RD2_EX <= 0;
			rs_EX <= 0;
			rd_EX <= 0;
			rt_EX <= 0;
			EXT_Out_EX <= 0;
			Jal_addr_EX <= 0;
			branchop_EX <= 0;
			Opcode_EX <= 0;
			Func_EX <= 0;
			shamt_EX <= 0;
			mndop_EX <= 0;
			mnd_EX <= 0;
			mnd_we_EX <= 0;
			HiLo_EX <= 0;
			oder_EX <= 0;
			PC_EX <= PC_ID; //如果出现阻塞就把ID级的PC转给PC_EX，使得阻塞的PC与之后的PC保持一致
			is_eret_EX <= 0;
			is_mtc0_EX <= 0;
			branch_EX <= 0;
		end
		else begin
			RegDst_EX <= RegDst;
			ALUSrc_EX <= ALUSrc;
			Mem2Gpr_EX <= Mem2Gpr;
			GprWrite_EX <= GprWrite;
			MemWrite_EX <= MemWrite;
			ALUOp_EX <= ALUOp;
			EXTOp_EX <= EXTOp;
			RD1_EX <= RD1;
			RD2_EX <= RD2;
			rs_EX <= rs;
			rt_EX <= rt;
			rd_EX <= rd;
			EXT_Out_EX <= EXT_Out;
			Jal_addr_EX <= Jal_addr;
			branchop_EX <= branchop;
			Opcode_EX <= Opcode;
			Func_EX <= Func;
			shamt_EX <= shamt;
			mnd_EX <= mnd;
			mndop_EX <= mndop;
			hi_lo_sel_EX <= hi_lo_sel;
			mnd_we_EX <= mnd_we;
			HiLo_EX <= HiLo;
			oder_EX <= oder_ID;
			PC_EX <= PC_ID;
			is_eret_EX <= is_eret;
			is_mtc0_EX <= is_mtc0;
			branch_EX <= branch;
		end
	end

endmodule






module pipe_reg_MEM (
	Clk, Clr_MEM, Reset, GprWrite_EX, Mem2Gpr_EX, MemWrite_EX, ALU_Result, RD2_EX, A3, 
		Jal_addr_EX, branchop_EX, Opcode_EX, Func_EX, hi_lo_result, oder_EX, //CP0_Out, 
		PC_EX, rs_EX, Over, is_eret_EX, rd_EX, is_mtc0_EX, branch_MEM,
	GprWrite_MEM, Mem2Gpr_MEM, MemWrite_MEM, ALU_Result_MEM, RD2_MEM, A3_MEM, 
		Jal_addr_MEM, branchop_MEM, Opcode_MEM, Func_MEM, hi_lo_result_MEM, 
		oder_MEM, PC_MEM, rs_MEM, Over_MEM, is_eret_MEM, rd_MEM, is_mtc0_MEM,
		branch_EX //CP0_Out_MEM,   
);
	input Clk, Reset, Clr_MEM;
	input GprWrite_EX, Mem2Gpr_EX, MemWrite_EX;
	input [4:0] A3;
	input [31:0] ALU_Result, RD2_EX, Jal_addr_EX;
	input [3:0] branchop_EX;
	input [5:0] Opcode_EX, Func_EX;
	input [31:0] hi_lo_result;
	input [31:0] oder_EX;
	input [31:2] PC_EX;
	//input [31:0] CP0_Out;
	input [4:0] rs_EX, rd_EX;
	input Over;
	input is_eret_EX;
	input is_mtc0_EX;
	input branch_EX;
	output reg GprWrite_MEM, Mem2Gpr_MEM, MemWrite_MEM;
	output reg [4:0] A3_MEM;
	output reg [31:0] ALU_Result_MEM, RD2_MEM, Jal_addr_MEM;
	output reg [3:0] branchop_MEM;
	output reg [5:0] Opcode_MEM, Func_MEM;
	output reg [31:0] hi_lo_result_MEM;
	output reg [31:0] oder_MEM;
	output reg [31:2] PC_MEM;
	//output reg [31:0] CP0_Out_MEM;
	output reg [4:0] rs_MEM, rd_MEM;
	output reg Over_MEM;
	output reg is_eret_MEM;
	output reg is_mtc0_MEM;
	output reg branch_MEM;

	always @(posedge Clk or posedge Reset) 
	begin
		if(Reset | Clr_MEM) begin
			GprWrite_MEM <= 0;
			Mem2Gpr_MEM <= 0;
			MemWrite_MEM <= 0;
			ALU_Result_MEM <= 0;
			RD2_MEM <= 0;
			A3_MEM <= 0;
			Jal_addr_MEM <= 0;
			branchop_MEM <= 0;
			Opcode_MEM <= 0;
			Func_MEM <= 0;
			hi_lo_result_MEM <= 0;
			oder_MEM <= 0;
			PC_MEM <= 0;
			//CP0_Out_MEM <= 0;
			rs_MEM <= 0;
			rd_MEM <= 0;
			Over_MEM <= 0;
			is_eret_MEM <= 0;
			is_mtc0_MEM <= 0;
			branch_MEM <= 0;
		end
		else begin
			GprWrite_MEM <= GprWrite_EX;
			Mem2Gpr_MEM <= Mem2Gpr_EX;
			MemWrite_MEM <= MemWrite_EX;
			ALU_Result_MEM <= ALU_Result;
			RD2_MEM <= RD2_EX;
			A3_MEM <= A3;
			Jal_addr_MEM <= Jal_addr_EX;
			branchop_MEM <= branchop_EX;
			Opcode_MEM <= Opcode_EX;
			Func_MEM <= Func_EX;
			hi_lo_result_MEM <= hi_lo_result;
			oder_MEM <= oder_EX;
			PC_MEM <= PC_EX;
			//CP0_Out_MEM <= CP0_Out;
			rs_MEM <= rs_EX;
			rd_MEM <= rd_EX;
			Over_MEM <= Over;
			is_eret_MEM <= is_eret_EX;
			is_mtc0_MEM <= is_mtc0_EX;
			branch_MEM <= branch_EX;
		end
	end

endmodule

module pipe_reg_WB (
	Clk, Clr_WB, Reset, GprWrite, Mem2Gpr, RAM_Load, ALU_Result, A3_MEM, Jal_addr_MEM, 
		branchop_MEM, Opcode_MEM, Func_MEM, hi_lo_result_MEM, oder_MEM, CP0_Out_MEM, rs_MEM,      
		branch_MEM, DEV_to_CPU_RD_WB, Exception_WB, is_eret_MEM,
	GprWrite_WB, Mem2Gpr_WB, RAM_Load_WB, ALU_Result_WB, A3_WB, Jal_addr_WB, 
		branchop_WB, Opcode_WB, Func_WB, hi_lo_result_WB, oder_WB, CP0_Out_WB, rs_WB,
		branch_WB, DEV_to_CPU_RD, Exception, is_eret_WB   
);
	input Clk, Clr_WB, Reset;
	input GprWrite, Mem2Gpr;
	input [4:0] A3_MEM;
	input [31:0] RAM_Load, ALU_Result, Jal_addr_MEM;
	input [3:0] branchop_MEM;
	input [5:0] Opcode_MEM, Func_MEM;
	input [31:0] hi_lo_result_MEM;
	input [31:0] oder_MEM;
	input [31:0] CP0_Out_MEM;
	input [4:0] rs_MEM;
	input branch_MEM;
	input [31:0] DEV_to_CPU_RD;
	input Exception;
	input is_eret_MEM;
	output reg GprWrite_WB, Mem2Gpr_WB;
	output reg [4:0] A3_WB;
	output reg [31:0] RAM_Load_WB, ALU_Result_WB, Jal_addr_WB;
	output reg [3:0] branchop_WB;
	output reg [5:0] Opcode_WB, Func_WB;
	output reg [31:0] hi_lo_result_WB;
	output reg [31:0] oder_WB;
	output reg [31:0] CP0_Out_WB;
	output reg [4:0] rs_WB;
	output reg branch_WB;
	output reg [31:0] DEV_to_CPU_RD_WB;
	output reg Exception_WB;
	output reg is_eret_WB;

	always @(posedge Clk or posedge Reset) 
	begin
		if(Reset | Clr_WB) begin
			GprWrite_WB <= 0;
			Mem2Gpr_WB <= 0;
			A3_WB <= 0;
			RAM_Load_WB <= 0;
			ALU_Result_WB <= 0;
			Jal_addr_WB <= 0;
			branchop_WB <=0;
			Opcode_WB <= 0;
			Func_WB <= 0;
			hi_lo_result_WB <= 0;
			Opcode_WB <= 0;
			oder_WB <= 0;
			CP0_Out_WB <= 0;
			rs_WB <= 0;
			branch_WB <= 0;
			DEV_to_CPU_RD_WB <= 0;
			Exception_WB <= 0;
			is_eret_WB <= 0;
		end
		else begin
			GprWrite_WB <= GprWrite;
			Mem2Gpr_WB <= Mem2Gpr;
			A3_WB <= A3_MEM;
			RAM_Load_WB <= RAM_Load;
			ALU_Result_WB <= ALU_Result;
			Jal_addr_WB <= Jal_addr_MEM;
			branchop_WB <= branchop_MEM;
			Opcode_WB <= Opcode_MEM;
			Func_WB <= Func_MEM;
			hi_lo_result_WB <= hi_lo_result_MEM;
			oder_WB <= oder_MEM;
			CP0_Out_WB <= CP0_Out_MEM;
			rs_WB <= rs_MEM;
			branch_WB <= branch_MEM;
			DEV_to_CPU_RD_WB <= DEV_to_CPU_RD;
			Exception_WB <= Exception;
			is_eret_WB <= is_eret_MEM;
		end
	end

endmodule
