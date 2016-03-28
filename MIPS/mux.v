`timescale 1ns / 1ps

module mux_RegDst(
	rt, rd, RegDst, branchop_EX,
	out 
);
	input [4:0] rt, rd;
	input RegDst;
	input [3:0] branchop_EX;
	output [4:0] out;
	
	assign out = (RegDst == 0 & branchop_EX == 4'b0001) ? 5'b11111 //jal
			   : (RegDst == 0) ? rt  
			   : rd;
	
endmodule

module mux_WD(
	ALU_Result_WB, Load_Word, Jal_addr_WB, Mem2Gpr_WB, branchop_WB, 
		hi_lo_result_WB, Opcode_WB, Func_WB, CP0_Out_WB, rs_WB,   
	WD
);
	input [31:0] ALU_Result_WB, Load_Word, Jal_addr_WB, hi_lo_result_WB;
	input Mem2Gpr_WB;
	input [3:0] branchop_WB;
	input [5:0] Opcode_WB, Func_WB;
	input [31:0] CP0_Out_WB;
	input [4:0] rs_WB;
	output [31:0] WD;

	wire is_mf = (Opcode_WB == 6'b000000) & ((Func_WB == 6'b010000) | (Func_WB == 6'b010010));
	wire is_mf_CP0 = (Opcode_WB == 6'b010000) & (rs_WB == 5'b00000);
	
	assign WD = ((Mem2Gpr_WB == 0) & (is_mf_CP0 == 1)) ? CP0_Out_WB //从CP0取值
			  : ((Mem2Gpr_WB == 0) & (is_mf == 1)) ? hi_lo_result_WB //从HI LO寄存器取值
			  : ((Mem2Gpr_WB == 0) & (branchop_WB == 4'b0001)) ? Jal_addr_WB //jal
			  : ((Mem2Gpr_WB == 0) & (branchop_WB == 4'b1001)) ? Jal_addr_WB //jalr
			  : ((Mem2Gpr_WB == 0) & (branchop_WB != 4'b0001)) ? ALU_Result_WB 
			  : Load_Word;
	
endmodule

module mux_ALUSrc(
	RD2, EXT_Out, EXT32, ALUSrc
);
	input [31:0] RD2, EXT_Out;
	input ALUSrc;
	output [31:0] EXT32;
	
	assign EXT32 = (ALUSrc == 0) ? RD2 : EXT_Out;
	
endmodule

module mux_R_W_A (
	mux_RD_EX, RD_EX, WD, ALU_Result_MEM, hi_lo_result_MEM, CP0_Out_MEM, Jal_addr_MEM,  //for both RD1 RD2
	ALU_RD
);
	input [2:0] mux_RD_EX;
	input [31:0] RD_EX, WD, ALU_Result_MEM, hi_lo_result_MEM, CP0_Out_MEM, Jal_addr_MEM;
	output [31:0] ALU_RD;

	assign ALU_RD = (mux_RD_EX == 3'b100) ? CP0_Out_MEM
				  : (mux_RD_EX == 3'b000) ? RD_EX
				  : (mux_RD_EX == 3'b101) ? Jal_addr_MEM 
				  : (mux_RD_EX == 3'b001) ? WD 
				  : (mux_RD_EX == 3'b010) ? ALU_Result_MEM 
				  : hi_lo_result_MEM;

endmodule

module mux_RD_AM (
	RD, ALU_Result_MEM, mux_RD, hi_lo_result_MEM, Jal_addr_MEM, CP0_Out_MEM,
	RD_ID
);
	input [31:0] RD, ALU_Result_MEM, hi_lo_result_MEM, Jal_addr_MEM, CP0_Out_MEM;
	input [2:0] mux_RD;
	output [31:0] RD_ID;

	assign RD_ID = (mux_RD == 3'b100) ? CP0_Out_MEM
				 : (mux_RD == 3'b010) ? hi_lo_result_MEM 
				 : (mux_RD == 3'b001) ? ALU_Result_MEM
				 : (mux_RD == 3'b000) ? RD
				 : Jal_addr_MEM;

endmodule

module mux_J_PC (
	PC_ID, RD1_ID, oder_ID,
	J_PC_ID, B_PC_ID, Jr_PC_ID, Jal_PC_ID, Jal_addr
);
	input [31:0] oder_ID;
	input [31:2] PC_ID;
	input [31:0] RD1_ID;
	output [31:2] J_PC_ID;
	output [31:2] B_PC_ID;
	output [31:2] Jr_PC_ID;
	output [31:2] Jal_PC_ID;
	output [31:0] Jal_addr;

	assign J_PC_ID = {PC_ID[31:28], oder_ID[25:0]};
	assign B_PC_ID = {PC_ID + 1 + {{14{oder_ID[15]}}, oder_ID[15:0]}};
	assign Jr_PC_ID = (RD1_ID[31:2]);
	assign Jal_PC_ID = {PC_ID[31:28], oder_ID[25:0]};
	assign Jal_addr = {PC_ID + 2, 2'b00}; //PC+8

endmodule

module mux_PC (
	J_PC_ID, B_PC_ID, Jr_PC_ID, Jal_PC_ID, PC_IF, branch, rt, Br, 
		branchop, is_eret, EPC, ALU_RD2, RD2_MEM, Exception, is_mtc0_EX, 
		is_mtc0_MEM, rd_EX, rd_MEM,// IntReq, HWInt, Over, dm_Over, //Error, 
	NPC	
);
	input [31:2] J_PC_ID, B_PC_ID, Jr_PC_ID, Jal_PC_ID, PC_IF;
	input  branch;
	input [3:0] branchop;
	input [4:0] rt;
	input Br;
	//input IntReq;
	input Exception;//发生异常
	input is_eret;
	input [31:2] EPC;
	//input [31:0] RD2_ID; //转发mtc0信号
	input [31:0] ALU_RD2; //转发mtc0信号
	input [31:0] RD2_MEM;
	input [4:0] rd_EX, rd_MEM;
	input is_mtc0_EX, is_mtc0_MEM;
	output [31:2] NPC;
	wire [31:0] enter = 32'h00004180;
	
	assign NPC = (Exception === 1) ? enter[31:2] //异常与中断的入口
			   : ((is_eret === 1) & (is_mtc0_EX === 1) & (rd_EX === 14)) ? ALU_RD2[31:2] //当CP0[2]被复写时从EX转发mtc0
			   : ((is_eret === 1) & (is_mtc0_MEM === 1) & (rd_MEM === 14)) ? RD2_MEM[31:2] //当CP0[2]被复写时从MEM转发mtc0
			   : (is_eret === 1) ? EPC
			   : ((branch === 1) & (Br===1'b1)) ? B_PC_ID //beq
			   : ((branch === 1) & (Br===1'b1)) ? B_PC_ID //bne
			   : ((branch === 1) & (Br===1'b1)) ? B_PC_ID //blez
			   : ((branch === 1) & (Br===1'b1)) ? B_PC_ID //bgtz
			   : ((branch === 1) & (Br===1'b1) & (rt === 0)) ? B_PC_ID //bltz
			   : ((branch === 1) & (Br===1'b1) & (rt !== 0)) ? B_PC_ID //bgez
			   : ((branch === 1) & (branchop === 4'b0001)) ? Jal_PC_ID //jal
			   : ((branch === 1) & (branchop === 4'b0010)) ? Jr_PC_ID //jr
			   : ((branch === 1) & (branchop === 4'b0011)) ? J_PC_ID //j
			   : ((branch === 1) & (branchop === 4'b1001)) ? Jr_PC_ID //jalr
			   : PC_IF + 1;


endmodule

module mux_load_oder (
	Opcode_WB, ALU_Result_WB, RAM_Load_WB,
	Load_Word	
);
	input [5:0] Opcode_WB;
	input [31:0] ALU_Result_WB;
	input [31:0] RAM_Load_WB;
	//input [31:0] DEV_to_CPU_RD_WB;
	output [31:0] Load_Word;

	wire [1:0] lb_byte = ALU_Result_WB[1:0];
	wire lh_byte = ALU_Result_WB[1];
	wire [31:0] lb, lbu, lh, lhu;

	assign lb =  ((Opcode_WB == 6'b100000) & (lb_byte == 2'b00)) ? {{24{RAM_Load_WB[7]}}, RAM_Load_WB[7:0]} 
				:((Opcode_WB == 6'b100000) & (lb_byte == 2'b01)) ? {{24{RAM_Load_WB[15]}}, RAM_Load_WB[15:8]}
				:((Opcode_WB == 6'b100000) & (lb_byte == 2'b10)) ? {{24{RAM_Load_WB[23]}}, RAM_Load_WB[23:16]}
				:((Opcode_WB == 6'b100000) & (lb_byte == 2'b11)) ? {{24{RAM_Load_WB[31]}}, RAM_Load_WB[31:24]} 
				: 32'b0;
						
	assign lbu =  ((Opcode_WB == 6'b100100) & (lb_byte == 2'b00)) ? {24'b0, RAM_Load_WB[7:0]}
				: ((Opcode_WB == 6'b100100) & (lb_byte == 2'b01)) ? {24'b0, RAM_Load_WB[15:8]}
				: ((Opcode_WB == 6'b100100) & (lb_byte == 2'b10)) ? {24'b0, RAM_Load_WB[23:16]}
				: ((Opcode_WB == 6'b100100) & (lb_byte == 2'b11)) ? {24'b0, RAM_Load_WB[31:24]}
				: 32'b0;
	assign lh =  ((Opcode_WB == 6'b100001) & (lh_byte == 1'b0)) ? {{16{RAM_Load_WB[15]}}, RAM_Load_WB[15:0]}
				:((Opcode_WB == 6'b100001) & (lh_byte == 1'b1)) ? {{16{RAM_Load_WB[31]}}, RAM_Load_WB[31:16]}
				: 32'b0;
	assign lhu =  ((Opcode_WB == 6'b100101) & (lh_byte == 1'b0)) ? {16'b0, RAM_Load_WB[15:0]}
				: ((Opcode_WB == 6'b100101) & (lh_byte == 1'b1)) ? {16'b0, RAM_Load_WB[31:16]}
				: 32'b0;

	assign Load_Word = (lb != 0) ? lb
					 : (lbu != 0) ? lbu
					 : (lh != 0) ? lh
					 : (lhu != 0) ? lhu
					 : RAM_Load_WB;

endmodule

module mux_BE (
	Opcode_MEM, ALU_Result_MEM,
	BE	
);
	input [5:0] Opcode_MEM;
	input [31:0] ALU_Result_MEM;
	output [3:0] BE;

	wire [1:0] sb_byte = ALU_Result_MEM[1:0];
	wire sh_byte = ALU_Result_MEM[1];
	wire is_sb = (Opcode_MEM == 6'b101000);
	wire is_sh = (Opcode_MEM == 6'b101001);

	assign BE = ((is_sb) & (sb_byte == 2'b00)) ? 4'b0001
			  : ((is_sb) & (sb_byte == 2'b01)) ? 4'b0010
			  : ((is_sb) & (sb_byte == 2'b10)) ? 4'b0100 
			  : ((is_sb) & (sb_byte == 2'b11)) ? 4'b1000
			  : ((is_sh) & (sh_byte == 1'b0)) ? 4'b0011 
			  : ((is_sh) & (sh_byte == 1'b1)) ? 4'b1100 
			  : 4'b1111;

endmodule


module mux_shamt_EX_ALU_RD1 (
	shamt_EX, ALU_RD1, ALUOp_EX,
	ALU_RD1_Sel	
);
	input [4:0] shamt_EX;
	input [31:0] ALU_RD1;
	input [4:0] ALUOp_EX;
	output [31:0] ALU_RD1_Sel;

	assign ALU_RD1_Sel = ((ALUOp_EX == 5'b00110) //sll 
						| (ALUOp_EX == 5'b00111) //srl
						| (ALUOp_EX == 5'b01000)) //sra
						?  {27'b0, shamt_EX} : ALU_RD1;
endmodule

module mux_HI_LO (
	HI, LO, hi_lo_sel_EX, 
	hi_lo_result	
);
	input [31:0] HI, LO;
	input hi_lo_sel_EX;
	output [31:0] hi_lo_result;

	assign hi_lo_result = (hi_lo_sel_EX) ? LO : HI;

endmodule

/*module mux_dm_Over (
	ALU_Result_MEM, MemWrite_MEM, 
	dm_Over  	
);
	input [31:2] ALU_Result_MEM;
	input MemWrite_MEM;
	output dm_Over;

	assign dm_Over = (MemWrite_MEM & ((ALU_Result_MEM > 2047) | (ALU_Result_MEM < 0)));

endmodule*/