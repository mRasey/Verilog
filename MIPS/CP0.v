`timescale 1ns / 1ps

module CP0(
	Clk, Reset, PC_MEM, DEV_break_SUM, RD2_MEM, //Over_MEM, dm_Over, //PC_ID, PC_EX, Over, dm_Over,  CPO_In,
		Opcode_MEM, rs_MEM, rd_MEM, is_eret, branch_WB,
	CP0_Out_MEM, EPC, IntReq, Exception //, Error 
);

	input Clk, Reset;// Over_MEM, dm_Over;
	input [31:2] PC_MEM;//PC_ID, PC_EX, 
	input [7:2] DEV_break_SUM;//HWInt[7:2]
	input [4:0] rd_MEM;
	//input [31:0] CPO_In;
	input [31:0] RD2_MEM;
	input [5:0] Opcode_MEM;
	input [4:0] rs_MEM;
	input is_eret;
	input branch_WB;
	//input Over_MEM, dm_Over;
	output [31:0] CP0_Out_MEM;
	output IntReq;
	output Exception;
	//output reg Error;
	wire [31:0] SR_Out = {16'b0, im, 8'b0, EXL, IE};
	wire [31:0] CAUSE_Out = {16'b0, IP, 3'b0, ExcCode, 2'b0};
	wire [31:0] EPC_Out = {EPC, 2'b00};
	wire is_mt = (Opcode_MEM == 6'b010000) & (rs_MEM == 5'b00100);

	output [31:2] EPC; //存储异常发生时的PC地址
	reg [15:10] IP;//对应外部设备中断源
	reg [6:2] ExcCode;//异常/中断类型编码值
	reg [15:10] im;//6个im位控制6个外部设备的中断
	reg [31:0] PrID;//处理器ID,包含公司以及芯片信息
	reg IE;//全局中断使能位
	reg EXL;//异常级，禁止中断

	reg [31:0] CP0 [0:3];

	assign Exception = IntReq;// | Over_MEM | dm_Over;
	assign CP0_Out_MEM= (rd_MEM == 12) ? SR_Out
				  	  : (rd_MEM == 13) ? CAUSE_Out
				  	  : (rd_MEM == 14) ? EPC_Out
				  	  : 32'b0;
	assign IntReq = (DEV_break_SUM & im) & (!EXL) & IE;
	assign EPC = CP0[2][31:2];

	always @ (posedge Clk or posedge Reset) begin
		IP <= DEV_break_SUM;

		if(Reset) begin
			IE <= 1;
			EXL <= 0;
			IP <= 0;
			im <= 6'b111111;
			PrID <= 0;
			ExcCode <= 0;
			PrID <= 32'h20150726;
			CP0[0] <= 65297; //status 1111 1111 0001 0001
			CP0[1] <= 0; //cause
			CP0[2] <= 0; //epc
			CP0[3] <= 32'h20150726;
			//Error <= 0;
		end
	/*************MTC0***************/
		if(is_mt) begin //中断时不写入
			if((rd_MEM == 12) & (!IntReq)) begin 
				{im, EXL, IE} = {RD2_MEM[15:10], RD2_MEM[1], RD2_MEM[0]};
				CP0[0] = {16'b0, im, 8'b0, EXL, IE};
			end
			/*else if(rd_MEM == 13) begin
				{IP, ExcCode} = {RD2_MEM[15:10], RD2_MEM[6:2]};
				CP0[1] = {16'b0, IP, 10'b0};
			end*/ //CAUSE寄存器不能写入	
			else if((rd_MEM == 14) & (!IntReq)) begin
				CP0[2] <= RD2_MEM;
			end
		end
	/*************Exception*************/
		if(IntReq) begin //外部设备中断
			if(branch_WB)
				CP0[2] <= {PC_MEM - 1, 2'b00};//跳转指令保存PC-1
			else
				CP0[2] <= {PC_MEM, 2'b00};//保存PC
			IP <= DEV_break_SUM;//保存外部中断状态
			ExcCode <= 0;
			EXL <= 1; //立刻改变使得中断停止,禁止中断
		end
		/*else if(Over_MEM) begin
			ExcCode <= 12;//ALU结果溢出
			CP0[2] <= PC_MEM + 1;
			//IE <= 1;
		end
		else if(dm_Over) begin
			ExcCode <= 4;//取址溢出
			CP0[2] <= PC_MEM + 1;
			//IE <= 1;
		end
	/**************eret****************/
		if(is_eret)
			EXL <= 0; //可以再次中断
		
	end

endmodule