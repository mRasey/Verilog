`timescale 1ns / 1ps

module alu(
	A, B, ALUOp_EX, //shamt_EX, //Zero, 
	Result, Over, Great, Less, Zero //, U_Small, Small
    );
	input [31:0] A;
	input [31:0] B;
	input [4:0] ALUOp_EX;
	//input [4:0] shamt_EX;
	//input Is_Move;
	output [31:0] Result;
	output Over;
	output Zero;
	output Great;
	output Less;
	//output U_Small;
	//output Small;

	//wire shamt_ext = {31'b0, shamt_EX};
	wire [63:0] sra_result = $signed({{32{B[31]}}, B}) >> $signed(A[4:0]);
	 
	assign Result = (ALUOp_EX == 5'b00000) ? ($signed(A) + $signed(B)) //add
			   	  : (ALUOp_EX == 5'b00001) ? ($signed(A) - $signed(B)) //sub
			   	  : (ALUOp_EX == 5'b00010) ? (A | B) //or
			   	  : (ALUOp_EX == 5'b00011) ? (A & B) //and
			   	  : (ALUOp_EX == 5'b00100) ? (A ^ B) //xor
			   	  : (ALUOp_EX == 5'b00101) ? ~(A | B) //nor
			   	  : (ALUOp_EX == 5'b00110) ? $signed(B) << $signed(A[4:0]) //sll
			   	  : (ALUOp_EX == 5'b00111) ? $signed(B) >> $signed(A[4:0]) //srl
			   	  : (ALUOp_EX == 5'b01000) ? sra_result[31:0] //sra
			   	  : (ALUOp_EX == 5'b01001) ? $signed(B) << $signed(A[4:0])  //sllv
			   	  : (ALUOp_EX == 5'b01010) ? $signed(B) >> $signed(A[4:0])  //srlv
			   	  : (ALUOp_EX == 5'b01011) ? sra_result[31:0] //srav
			   	  : (ALUOp_EX == 5'b01100) ? (($signed(A) < $signed(B)) ? 1 : 0) //slt
			   	  : (ALUOp_EX == 5'b01101) ? (($signed(A) < $signed(B)) ? 1 : 0) //slti
			   	  : (ALUOp_EX == 5'b01110) ? ((A < B) ? 1 : 0) //sltu
			   	  : (ALUOp_EX == 5'b10000) ? (A + B) //addu
			   	  : (ALUOp_EX == 5'b10001) ? (A - B) //subu
			   	  : ((A < B) ? 1 : 0); //sltiu

	wire [32:0] add_result = $signed({A[31], A}) + $signed({B[31], B});
	wire [32:0] sub_result = {A[31], A} - {B[31], B};

	assign Zero = ($signed(A) == $signed(B));
	assign Great = ($signed(A) > $signed(B));
	assign Less = ($signed(A) < $signed(B));
	assign Over = ((ALUOp_EX == 5'b00000) & (add_result[32] != add_result[31]))
				| ((ALUOp_EX == 5'b00001) & (sub_result[32] != sub_result[31]));

endmodule
