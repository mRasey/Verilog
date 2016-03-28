`timescale 1ns / 1ps

module controller(
	Opcode, Func, rt, rs, ALUOp, EXTOp, MemWrite, GprWrite, Mem2Gpr, ALUSrc, 
		RegDst, branch, branchop, mnd, 
    mndop, mnd_we, hi_lo_sel, HiLo, is_eret, is_mtc0 // Is_Move 
);
	input [5:0] Opcode, Func;
	input [4:0] rt, rs;
	output [1:0] EXTOp;
	output [3:0] branchop;
	output [4:0] ALUOp;
	output [1:0] mndop;
	output mnd, mnd_we;
	output hi_lo_sel;
	output HiLo;
	output MemWrite, GprWrite, Mem2Gpr, ALUSrc, RegDst, branch;
	output is_eret;
	output is_mtc0;
	
	
	wire lb = (Opcode == 6'b100000);///
	wire lbu = (Opcode == 6'b100100);///
	wire lh = (Opcode == 6'b100001);///
	wire lhu = (Opcode == 6'b100101);///
	wire sb = (Opcode == 6'b101000);///
	wire sh = (Opcode == 6'b101001);///
	wire lw = (Opcode == 6'b100011);///
	wire sw = (Opcode == 6'b101011);///

	wire add = (Opcode == 6'b000000) & (Func == 6'b100000);///
	wire sub = (Opcode == 6'b000000) & (Func == 6'b100010);///
	wire addu = (Opcode == 6'b000000) & (Func == 6'b100001);///
	wire subu = (Opcode == 6'b000000) & (Func == 6'b100011);///
	wire xori = (Opcode == 6'b001110);///
	wire And = (Opcode == 6'b000000) & (Func == 6'b100100);///
	wire Or = (Opcode == 6'b000000) & (Func == 6'b100101);///
	wire Xor = (Opcode == 6'b000000) & (Func == 6'b100110);///
	wire Nor = (Opcode == 6'b000000) & (Func == 6'b100111);///
	wire addi = (Opcode == 6'b001000);///
	wire addiu = (Opcode == 6'b001001);///
	wire andi = (Opcode == 6'b001100);///
	wire ori = (Opcode == 6'b001101);///
	wire lui = (Opcode == 6'b001111);///

	wire mult = (Opcode == 6'b000000) & (Func == 6'b011000);///
	wire multu = (Opcode == 6'b000000) & (Func == 6'b011001);///
	wire div = (Opcode == 6'b000000) & (Func == 6'b011010);///
	wire divu = (Opcode == 6'b000000) & (Func == 6'b011011);///
	wire mfhi = (Opcode == 6'b000000) & (Func == 6'b010000);///
	wire mflo = (Opcode == 6'b000000) & (Func == 6'b010010);///
	wire mthi = (Opcode == 6'b000000) & (Func == 6'b010001);///
	wire mtlo = (Opcode == 6'b000000) & (Func == 6'b010011);///

	wire sll = (Opcode == 6'b000000) & (Func == 6'b000000);///
	wire srl = (Opcode == 6'b000000) & (Func == 6'b000010);///
	wire sra = (Opcode == 6'b000000) & (Func == 6'b000011);///
	wire sllv = (Opcode == 6'b000000) & (Func == 6'b000100);///
	wire srlv = (Opcode == 6'b000000) & (Func == 6'b000110);///
	wire srav = (Opcode == 6'b000000) & (Func == 6'b000111);///
	
	wire bne = (Opcode == 6'b000101); // !=  0100
	wire blez = (Opcode == 6'b000110);// <= 0 0101
	wire bgtz = (Opcode == 6'b000111);// > 0 0110
	wire bltz = (Opcode == 6'b000001) & (rt == 0); // < 0 0111
	wire bgez = (Opcode == 6'b000001) & (rt != 0); // >= 0 1000
	wire beq = (Opcode == 6'b000100);/// 1111
	wire jalr = (Opcode == 6'b000000) & (Func == 6'b001001); // 1001
	wire jal = (Opcode == 6'b000011);/// 0001
	wire jr = (Opcode == 6'b000000) & (Func == 6'b001000);/// 0010
	wire j = (Opcode == 6'b000010);/// 0011

	wire slt = (Opcode == 6'b000000) & (Func == 6'b101010);/// 
	wire slti = (Opcode == 6'b001010);///
	wire sltiu = (Opcode == 6'b001011);///
	wire sltu = (Opcode == 6'b000000) & (Func == 6'b101011);///
	
	wire mfc0 = (Opcode == 6'b010000) & (rs == 5'b00000);
	wire mtc0 = (Opcode == 6'b010000) & (rs == 5'b00100);
	wire eret = (Opcode == 6'b010000) & (Func == 6'b011000);
	

	assign RegDst = addu | add | subu | sub | Xor | Nor | Or | And | sll | jalr
					| srl | sra | sllv | srlv | srav | slt | sltu | mfhi | mflo;
	assign ALUSrc = ori | andi | addi | addiu | xori | lui 
					| lw | lb | lbu | lh | lhu | sb | sh | sw
					| slti | sltiu;
	assign Mem2Gpr = lw | lb | lbu | lh | lhu;
	assign GprWrite = ori | addu | add | subu | sub | Xor | xori | andi 
					| addi | addiu | Nor | Or | And | jal | lw | lui | lb 
					| lbu | lh | lhu | sll | srl | sra | sllv | srlv | srav
					| jalr| slt | slti | sltiu | sltu | mfhi | mflo | mfc0;
	assign MemWrite = sw | sb | sh;
	assign branch = beq | jal | jr | j | bne | blez | bgtz | bltz | bgez | jalr;
	assign EXTOp = {lui, 
					ori | xori};

	assign ALUOp = {addu | addiu | subu,
					sltiu | sltu | slti | slt | sra | sllv | srlv | srav,
					sltiu | sltu | slti | slt | Xor | xori | Nor | sll | srl,
					sltiu | sltu | ori | Or | And | andi | sll | srl | srlv | srav,
					sltiu | slti | beq | sub | And | andi | Nor | srl | sllv | srav | subu};

	assign branchop = {bgez | jalr,
					   bne | blez | bgtz | bltz,
					   jr | j | bgtz | bltz,  
					   jal | j | blez | bltz | jalr};

	assign mndop = {divu | div, mult | div};
	assign mnd = divu | div | mult | multu;
	assign mnd_we = mthi | mtlo; //乘除法写使能
	assign hi_lo_sel = mflo; //0 读HI，1 读LO
	assign HiLo = mthi; //0 写LO，1 写HI
	assign is_eret = eret;
	assign is_mtc0 = mtc0;
	//assign is_mfhi_lo = mfhi | mflo;
	//assign Is_Move = sll | srl | sllv | srlv | sra | srav;
	
endmodule
