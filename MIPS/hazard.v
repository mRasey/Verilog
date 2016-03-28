`timescale 1ns / 1ps

module hazard(
	branch, Mem2Gpr_EX, Mem2Gpr_MEM, GprWrite_EX, GprWrite_MEM, GprWrite_WB, rs, 
	rt, rs_EX, rt_EX, A3, A3_MEM, A3_WB, oder_ID, Busy, mnd, Opcode_EX, Func_EX, 
	branchop, branchop_EX, branchop_MEM, mnd_we, Opcode_MEM, Func_MEM, IntReq, mnd_EX,
	rs_MEM, Exception, is_eret, //Over_MEM, dm_Over, Error, HWInt, 
	//
	En_IF, En_ID, mux_RD1, mux_RD2, Clr_IF, Clr_ID, Clr_EX, Clr_MEM, Clr_WB, mux_RD1_EX, 
	mux_RD2_EX
);
	input branch, Mem2Gpr_EX, Mem2Gpr_MEM, GprWrite_EX, GprWrite_MEM, GprWrite_WB;
	input [4:0] rs, rt, rs_EX, rt_EX, A3, A3_MEM, A3_WB;
	input [3:0] branchop, branchop_EX, branchop_MEM;
	input [31:0] oder_ID;
	input [5:0] Opcode_EX, Func_EX;
	input [5:0] Opcode_MEM, Func_MEM;
	input Busy, mnd, mnd_we, mnd_EX;
	input IntReq;
	input [4:0] rs_MEM;
	input is_eret;
	//input Over_MEM;
	//input dm_Over;
	input Exception;
	//input [7:2] HWInt;
	output En_IF, En_ID, Clr_IF, Clr_ID, Clr_EX, Clr_MEM, Clr_WB;
	output [2:0] mux_RD1_EX, mux_RD2_EX, mux_RD1, mux_RD2;

	wire [5:0] Opcode = oder_ID[31:25];
	wire [5:0] Func = oder_ID[5:0];

	wire is_mf = ((Opcode == 6'b000000) & (Func == 6'b010000))
			   | ((Opcode == 6'b000000) & (Func == 6'b010010));
	wire is_mf_EX = ((Opcode_EX == 6'b000000) & (Func_EX == 6'b010000))
				  | ((Opcode_EX == 6'b000000) & (Func_EX == 6'b010010));
	wire is_mf_MEM = ((Opcode_MEM == 6'b000000) & (Func_MEM == 6'b010000))
				   | ((Opcode_MEM == 6'b000000) & (Func_MEM == 6'b010010));
	wire is_mfc0 = ((Opcode_MEM == 6'b010000) & (rs_MEM == 5'b00000));
				 //| ((Opcode_MEM == 6'b010000) & (rs_MEM == 5'b00100))

	wire load_break = ((rs == rt_EX) | (rt == rt_EX)) & Mem2Gpr_EX;
	wire branch_break = (branch & GprWrite_EX & ((A3 == rs) | (A3 == rt))) //与上一条指令冲突
					  | (branch & Mem2Gpr_MEM & ((A3_MEM == rs) | (A3_MEM == rt))); //与load指令冲突
	//wire jr_break = branch  &  ((branchop == 4'b0010) | (branchop == 4'b1001))  &  ((A3 == rs) | (A3_MEM == rs));
	wire mult_break = (Busy || mnd_EX) & (mnd | mnd_we | is_mf); //当要继续使用乘法器或要写入 读出HI LO时阻断
	wire is_jal = ((Opcode_MEM == 6'b000000) & (Func_MEM == 6'b001001)) | (Opcode_MEM == 6'b000011);

	assign mux_RD1_EX = ((rs_EX != 0) & (rs_EX == A3_MEM) & GprWrite_MEM & is_mfc0) ? 3'b100 //由MFC0过来
					  : ((rs_EX != 0) & (rs_EX == A3_MEM) & GprWrite_MEM & is_mf_MEM) ? 3'b011 //由乘法过来
					  : ((rs_EX != 0) & (rs_EX == A3_MEM) & GprWrite_MEM & is_jal) ? 3'b101 //由PC+8过来 
					  : ((rs_EX != 0) & (rs_EX == A3_MEM) & GprWrite_MEM) ? 3'b010 //由ALU过来
					  : ((rs_EX != 0) & (rs_EX == A3_WB) & GprWrite_WB) ? 3'b001 //由WD过来
					  : 3'b000;
	assign mux_RD2_EX = ((rt_EX != 0) & (rt_EX == A3_MEM) & GprWrite_MEM & is_mfc0) ? 3'b100 //由MFC0过来
					  : ((rt_EX != 0) & (rt_EX == A3_MEM) & GprWrite_MEM & is_mf_MEM) ? 3'b011 //由乘法过来
					  : ((rt_EX != 0) & (rt_EX == A3_MEM) & GprWrite_MEM & is_jal) ? 3'b101 //由PC+8过来 
					  : ((rt_EX != 0) & (rt_EX == A3_MEM) & GprWrite_MEM) ? 3'b010 //由ALU过来
					  : ((rt_EX != 0) & (rt_EX == A3_WB) & GprWrite_WB) ? 3'b001 //由WD过来 
					  : 3'b000;
	assign mux_RD1 = ((rs != 0) & (rs == A3_MEM) & GprWrite_MEM & is_mfc0) ? 3'b100 //由MFC0过来
				   : ((rs != 0) & (rs == A3_MEM) & GprWrite_MEM & is_mf_MEM) ? 3'b010 //由乘法过来
				   : ((rs != 0) & (rs == A3_MEM) & GprWrite_MEM & is_jal) ? 3'b011 //由PC+8过来 
				   : ((rs != 0) & (rs == A3_MEM) & GprWrite_MEM) ? 3'b001 //由ALU过来
				   : 3'b000;
	assign mux_RD2 = ((rt != 0) & (rt == A3_MEM) & GprWrite_MEM & is_mfc0) ? 3'b100 //由MFC0过来
				   : ((rt != 0) & (rt == A3_MEM) & GprWrite_MEM & is_mf_MEM) ? 3'b010 //由乘法过来
				   : ((rt != 0) & (rt == A3_MEM) & GprWrite_MEM & is_jal) ? 3'b011 //由PC+8过来 
				   : ((rt != 0) & (rt == A3_MEM) & GprWrite_MEM) ? 3'b001 //由ALU过来
				   : 3'b000;

	//wire jr_break = (branchop == 2'b10) & ((rs == A3) | (rs == A3_MEM) | (rs == A3_WB));
	//wire addu_break = (A3_WB == rs) & (Opcode == 6'b000000) & (Func == 6'b100001);
					  
	assign En_ID = !(load_break | branch_break | mult_break);
	assign En_IF = !(load_break | branch_break | mult_break);
	assign Clr_IF = 0;
	assign Clr_ID = Exception | is_eret; 
	assign Clr_EX = load_break | branch_break | mult_break | Exception;
	assign Clr_MEM = Exception; 
	assign Clr_WB = Exception;

endmodule
