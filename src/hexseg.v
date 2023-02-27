`define REVERS(RESULT, SOURCE) \
  RESULT = {SOURCE[7],SOURCE[0],SOURCE[1],SOURCE[2],SOURCE[3],SOURCE[4],SOURCE[5],SOURCE[6]}

module segm(
	clk,
	num0,
	num1,
	num2,

	dig,
	seg
);

	input clk;
	input [3:0]num0;
	input [3:0]num1;
	input [3:0]num2;
	
	output [2:0]dig;
	output [7:0]seg;
	
	reg [32:0] counter=32'd0;
	reg [ 2:0] seg_dig=2'd0;
	reg _step=1'b0;
	reg [ 7:0] tmpseg = 8'd0;
	wire step;
	
	assign step=_step;
	assign dig=seg_dig;
	assign seg=_seg;
	
	parameter T1MS = 32'd250000;
	//parameter T1MS = 32'd1;
	parameter reg [16*8:0]SGM={
		8'b01101100, //F
		8'b01101101, //E
		8'b00011111, //d
		8'b01100101, //C
		8'b00101111, //b
		8'b01111110, //A
		8'b01111011, //9
		8'b01111111, //8
		8'b01010010, //7
		8'b01101111, //6
		8'b01101011, //5
		8'b00111010, //4
		8'b01011011, //3
		8'b01011101, //2
		8'b00010010, //1
		8'b01110111  //0
	};
	
	always @(posedge clk)
	begin
		if(counter == T1MS)
		begin
			counter<=0;
			_step<=1;
		end
		else
		begin
			counter<=counter+32'd1;
			_step<=0;
		end
	end
	
	reg [7:0]_seg=8'd0;
	reg [1:0]i=2'd0;
	
	always @(posedge step)
	begin
		i<=i+2'd1;
		case(i)
		0: begin
				seg_dig<=3'b001;
				tmpseg=~SGM[num0*8 +: 8];
				`REVERS(_seg, tmpseg);
			end
		1: begin
				seg_dig<=3'b010;
				tmpseg=~SGM[num1*8 +: 8];
				`REVERS(_seg, tmpseg);
			end
		2: begin
				seg_dig<=3'b100;
				tmpseg=~SGM[num2*8 +: 8];
				`REVERS(_seg, tmpseg);
				i<=2'd0;
			end
		endcase
	end
endmodule
