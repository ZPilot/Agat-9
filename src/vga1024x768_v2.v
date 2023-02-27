module vga1024x768_v2(
	pclk,
	ramclk,
	sdramclk,
	
	hsync,
	vsync,
	rgb,
	
	read_vga,
	address,
	dout_vga,
	ready_vga,
	
	_ddensity,
	_es,
	_eps,
	_rvi,
	_pal,
	
	_pa,
	_c050, _c052, _c054,
	
	nmi,irq
);
input pclk;
input ramclk;
input sdramclk;

output hsync;
output vsync;
output [15:0]rgb;

output read_vga = ~(ready_vga|buff_agat_full) & start_ram;
output [23:0]address;
input  [15:0]dout_vga;
input  ready_vga;

input _ddensity;
input [3:0]_es;
input [1:0]_eps;
input [1:0]_rvi;
input [1:0]_pal;

input _pa;
input _c050, _c052, _c054;

output irq = (Yagat==47 || Yagat==72 || Yagat==95 || Yagat==119 || Yagat==143 || Yagat==168 || Yagat==191 || Yagat==215 || Yagat==239);
output nmi = visible_y;//vsync;
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire visible_x = x < 1024;
wire apl_visible_x = x>91 && x<936; //840 pixel
wire apl_visible_txt_x = x>91 && x<932; //840 pixel
wire new_adr = x > 1025 && x < 1027;
wire new_attr = x == 1025;
wire start_ram = x > 1029;
wire visible_y = y < 768;
wire visible = visible_x & rdn;//pa ? visible_y : apl_visible_x;

assign hsync = (x > 1023+24) && (x < 1024+24+136);
assign vsync = (y >  767+ 3) && (y <  768+ 3+  6);

reg [15:0]rgb = 0;
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// New attr
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg ddensity;
reg [3:0]es;
reg [1:0]eps;
reg [1:0]rvi;
reg [1:0]pal;

reg pa;
reg c050, c052, c054;

always @(posedge new_attr)begin
	ddensity <= _ddensity;
	es		<= _es;
	eps	<= _eps;
	rvi	<= _rvi;
	pal	<= _pal;
	pa		<= _pa;
	c050	<= _c050;
	c052	<= _c052;
	c054	<= _c054;
	end
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire v2v4 = Yapple[7] & Yapple[5];
wire apcombgr = v2v4 & c052;
wire aplreg = apcombgr | c050;
wire mgrvr = ~ddensity && &rvi;
wire [23:0]address = addr + count_ram_agat;
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [10:0]x=0;
reg [ 9:0]y=0;


reg [ 1:0]countYagat = 0;
reg [ 1:0]countYapple = 0;
reg [ 7:0]Yagat = 0;
reg [ 7:0]Yapple = 0;
reg [ 1:0]countXapple = 0;
reg [ 2:0]countX7apple = 0;
reg [ 5:0]Xapple = 0;

reg [23:0]addr = 0;

reg parity = 0;

wire x7clk = &countX7apple[2:1];

wire clkYapple = &countYapple;

always @(posedge pclk) begin
	x <= x + 1'b1;
	if(x==1343) begin x <= 0; y <= y + 1'b1; end
	if(y==805) y <= 0;
	if(x==1024) begin
		countYagat <= countYagat + 1'b1;
		countYapple <= countYapple + 1'b1;
		if(countYagat[1])begin countYagat <= 0; Yagat <=  Yagat + 1'b1; end
		if(clkYapple)Yapple <= Yapple + 1'b1;
	end
	if(apl_visible_x)begin
		countXapple <= countXapple + 1'b1;
		if(countXapple[1])begin
			countXapple <=0;
			countX7apple <= countX7apple + 1'b1;
			parity <= ~parity;
			if(x7clk)begin countX7apple <= 0; Xapple <=  Xapple + 1'b1;end
			end
	end
	if(!visible_x){countXapple,countX7apple,Xapple,rgb,parity} <= 0;
	if(!visible_y){Yagat,Yapple,countYagat,countYapple, rgb} <= 0;
	
	if(new_adr)
		case({pa,rvi})
		'b1_00:	addr <= {8'd0,es[3:1],    Yagat[7:1],6'd0};
		'b1_01:	addr <= {8'd0,es[3:1],    Yagat[7:1],6'd0};
		'b1_10:	addr <= {9'd0,es[2:1],eps,Yagat[7:3],6'd0};
		'b1_11: 	if(ddensity)addr <= {8'd0,es[3:1],	  Yagat[7:1],6'd0};
					else 			addr <= {8'd0,es[3:1],    Yagat[7:0],5'd0};
		default: if(aplreg)  addr <= {12'd0,c054,~c054,Yapple[5:3],Yapple[7:6],Yapple[7:6],3'b000}; 
					else  addr <= {10'd0,c054,Yapple[2:0],Yapple[5:3],Yapple[7:6],Yapple[7:6],3'b000};
		endcase
	//Вывод на экран
	if(visible)
		case({pa,rvi})
		//agat
		'b1_00: if(&x[1:0])rgb <= cgvrrgb;
		'b1_01: if(x[2])rgb <= cgsrrgb;
		'b1_10: if(!x[0])rgb <= t32rgb;
		'b1_11: if(!x[0])rgb <= mrgb;
		//apple
		default:if(countXapple[1]) if(aplreg)rgb <= t40rgb; else rgb <= aplgrrgb;
		endcase
	else rgb <= 0;
	
	end
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// RAM buffer count for Agat, string 64 byte
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [5:0]count_ram_agat = 0;
wire buff_agat_full = pa ? mgrvr ? count_ram_agat >30 : count_ram_agat > 62 : count_ram_agat > 38;
always @(posedge ramclk)
	if(start_ram)begin
		if(ready_vga)count_ram_agat <= buff_agat_full ? count_ram_agat : count_ram_agat + 1'b1;
	end else count_ram_agat <= 0;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// RAMbuffer for 1 screen string
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0]ramcachevgadata;
wire [ 5:0] rdaddr = pa ? mgrvr ? {1'b0,x[9:5]} : {x[9:5],1'b0} : Xapple;
wire [ 5:0] rdaddr1 = pa ? {x[9:5],1'b1} : Xapple + 1'b1;
wire rdn = pa ? visible_x : apl_visible_x;
ramcachevga cachevga1(
	.data(dout_vga),
	.wraddress({count_ram_agat}),
	.clock(sdramclk),
	.wren(ready_vga),
	
	.rdaddress(rdaddr),
	.rden(rdn),
	.q(ramcachevgadata)
	);

wire [15:0]ramcachevgacolor;
ramcachevga cachevga2(
	.data(dout_vga),
	.wraddress({count_ram_agat}),
	.clock(sdramclk),
	.wren(ready_vga),
	
	.rdaddress(rdaddr1),
	.rden(rdn),
	.q(ramcachevgacolor)
	);
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// 5Hz
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [4:0]cpount5hz = 0;
wire clk5hz = cpount5hz[4];
always @(posedge vsync) cpount5hz <= cpount5hz + 1'b1;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// АГАТ
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// T32/T64
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0]datatext  = ddensity ? x[4]?ramcachevgacolor:ramcachevgadata : ramcachevgadata;
wire [ 7:0]txt_color = es[0] ? ramcachevgacolor[15:8] : ramcachevgacolor[7:0];
wire [ 2:0]countbit  = ddensity ? x[3:1]:x[4:2];

wire [7:0]datazg;
wire [10:0]addrzg = pa ? {es[0] ? datatext[15:8] : datatext[7:0],Yagat[2:0]} : 
								 {1'b1,&ramcachevgadata[7:6],ramcachevgadata[5:0],Yapple[2:0]};
dd64 zg1(
	.address(addrzg),
	.clock(sdramclk),
	.q(datazg)
	);
wire [15:0] t32rgb;
pal_T32 plT32(
	.clk(pclk), .clk5hz(clk5hz), .pal(pal), .color(txt_color), .ddensity(ddensity), .data(datazg[~countbit]) ,.rgb(t32rgb)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ЦГВР
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ 1:0] cgvr;
wire [15:0] cgvrdata = x[4] ? ramcachevgacolor:ramcachevgadata;
wire [15:0] cgvrrgb;
cgvrcolor cgvr1(
	.data0x(cgvrdata[1:0]),
	.data1x(cgvrdata[3:2]),
	.data2x(cgvrdata[5:4]),
	.data3x(cgvrdata[7:6]),
	
	.data4x(cgvrdata[9:8]),
	.data5x(cgvrdata[11:10]),
	.data6x(cgvrdata[13:12]),
	.data7x(cgvrdata[15:14]),
	
	.sel({Yagat[0],~x[3:2]}),
	.clock(pclk),
	.result(cgvr)
	);
	
pal_cgvr plcgvr( 
	.clk(pclk),	.pal(pal), .color(cgvr), .rgb(cgvrrgb)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// ЦГCР
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ 3:0] cgsr;
wire [15:0] cgsrdata = x[4] ? ramcachevgacolor:ramcachevgadata;
wire [15:0] cgsrrgb;

cgsrcolor cgsr1(
	.data0x(cgsrdata[3:0]),
	.data1x(cgsrdata[7:4]),
	.data2x(cgsrdata[11:8]),
	.data3x(cgsrdata[15:12]),
	.sel({es[0],~x[3]}),
	.result(cgsr)
	);
pal_cgsr plcgsr(
	.clk(pclk), .color(cgsr), .rgb(cgsrrgb)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Монохромный графический режим 512/256 пикселей в строке
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0] mgrdata  = ddensity ? x[4]? ramcachevgacolor:ramcachevgadata : ramcachevgadata;
wire [ 7:0] mgrdatarg= ddensity ? Yagat[0] ? mgrdata[15:8]: mgrdata[7:0] : es[0] ? mgrdata[15:8] : mgrdata[7:0];
wire [15:0] mrgb;
wire [ 2:0] mcountbit = ddensity ? x[3:1]:x[4:2];

pal_mono plm1(
	.clk(pclk), .pal(pal), .data(mgrdatarg[~mcountbit]), .rgb(mrgb)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Apple T40
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0] t40rgb = apl_visible_txt_x ? t40rgb1 : 16'h0000;
wire [15:0] t40rgb1;

pal_T40 plT40(
	.clk(pclk), .clk5hz(clk5hz), .pal(pal), .color(ramcachevgadata[7:6]), .data(datazg[~(countX7apple) - 1'b1]) ,.rgb(t40rgb1)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Apple graph
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0] aplgrrgb;
wire [ 7:0] apldata    = c054 ? ramcachevgadata[7:0]  : ramcachevgadata[15:8];
wire [ 7:0] aplpredata = c054 ? ramcachevgacolor[7:0] : ramcachevgacolor[15:8];
wire prebit = x7clk ? aplpredata[0] : apldata[countX7apple + 1'b1];

pal_apple_gr appl_gr(
	.clk(~countXapple[1]), .bitc(apldata[countX7apple]), .prebit(prebit), .color(apldata[7]), .parity(parity), .rgb(aplgrrgb)
);
endmodule

//======================================================================================================================
//======================================================================================================================
//======================================================================================================================
//======================================================================================================================

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Color modules
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
module pal_cgvr(
	clk,
	pal, color, rgb
);
input  clk;
input  [ 1:0]pal;
input  [ 1:0]color;
output reg [15:0]rgb;

always @(posedge clk)
	case({pal, color})
	'b00_00: rgb <= 0;
	'b00_01: rgb <= {5'b11000,6'b000000,5'b00000};
	'b00_10: rgb <= {5'b00000,6'b110000,5'b00000};
	'b00_11: rgb <= {5'b00000,6'b000000,5'b11000};
	
	'b01_00: rgb <= {5'b11000,6'b110000,5'b11000};
	'b01_01: rgb <= {5'b11000,6'b000000,5'b00000};
	'b01_10: rgb <= {5'b00000,6'b110000,5'b00000};
	'b01_11: rgb <= {5'b00000,6'b000000,5'b11000};
	
	'b10_00: rgb <= 0;
	'b10_01: rgb <= 0;
	'b10_10: rgb <= {5'b00000,6'b110000,5'b00000};
	'b10_11: rgb <= {5'b00000,6'b000000,5'b11000};
	
	'b11_00: rgb <= 0;
	'b11_01: rgb <= {5'b11000,6'b000000,5'b00000};
	'b11_10: rgb <= 0;
	'b11_11: rgb <= {5'b00000,6'b000000,5'b11000};
	endcase
endmodule

module pal_T32(
	clk, clk5hz, pal, color, ddensity, data ,rgb
);
input  clk;
input  clk5hz;
input  [ 1:0]pal;
input  [ 7:0]color;
input  ddensity;
input  data;
output reg [15:0]rgb;

wire invers_symb = color[5] ? 1'b1 :
				  color[3] ? clk5hz : 1'b0;

always @(posedge clk)begin
	case({ddensity,pal,invers_symb})
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// T32
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'b0_00_0: rgb <= {~data & color[0],~data & color[0],3'd0, ~data & color[1],~data & color[1],4'd0, ~data & color[2],~data & color[2],3'd0};
	'b0_00_1: rgb <= { data & color[0], data & color[0],3'd0,  data & color[1], data & color[1],4'd0,  data & color[2], data & color[2],3'd0};
	
	'b0_01_0: rgb <= data ? {5'b00000,6'b000000,5'b10000} : {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0};
	'b0_01_1: rgb <= data ? {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0} : {5'b00000,6'b000000,5'b11000};
	
	'b0_10_0: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0};
	'b0_10_1: rgb <= data ? {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0} : {5'b00000,6'b000000,5'b00000};
	
	'b0_11_0: rgb <= data ? {5'b11000,6'b000000,5'b11000} : {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0};
	'b0_11_1: rgb <= data ? {color[0],color[0],3'd0, color[1],color[1],4'd0, color[2],color[2],3'd0} : {5'b11000,6'b000000,5'b11000};
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// T64
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'b1_00_0: rgb <= { data,data, 3'd0, data,data ,4'd0, data,data, 3'd0};
	'b1_00_1: rgb <= { data,data, 3'd0, data,data ,4'd0, data,data, 3'd0};
	
	'b1_01_0: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b11000,6'b110000,5'b11000};
	'b1_01_1: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b11000,6'b110000,5'b11000};
	
	'b1_10_0: rgb <= data ? {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};
	'b1_10_1: rgb <= data ? {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};
	
	'b1_11_0: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b00000,6'b110000,5'b00000};
	'b1_11_1: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b00000,6'b110000,5'b00000};
	
	endcase
	end
endmodule

module pal_cgsr(
	clk, color, rgb
);
input  clk;
input  [ 3:0]color;
output reg [15:0]rgb;

always @(posedge clk)
	case(color)
	'b0_000: rgb <= 0;
	'b0_001: rgb <= {5'b11000,6'b000000,5'b00000};
	'b0_010: rgb <= {5'b00000,6'b110000,5'b00000};
	'b0_011: rgb <= {5'b11000,6'b110000,5'b00000};
	'b0_100: rgb <= {5'b00000,6'b000000,5'b11000};
	'b0_101: rgb <= {5'b11000,6'b000000,5'b11000};
	'b0_110: rgb <= {5'b00000,6'b110000,5'b11000};
	'b0_111: rgb <= {5'b11000,6'b110000,5'b11000};
	
	'b1_000: rgb <= 0;
	'b1_001: rgb <= {5'b10000,6'b000000,5'b00000};
	'b1_010: rgb <= {5'b00000,6'b100000,5'b00000};
	'b1_011: rgb <= {5'b10000,6'b100000,5'b00000};
	'b1_100: rgb <= {5'b00000,6'b000000,5'b10000};
	'b1_101: rgb <= {5'b10000,6'b000000,5'b10000};
	'b1_110: rgb <= {5'b00000,6'b100000,5'b10000};
	'b1_111: rgb <= {5'b10000,6'b100000,5'b10000};
	endcase
endmodule

module pal_mono(
	clk, pal, data,rgb
);
input  clk;
input  [ 1:0]pal;
input  data;
output reg [15:0]rgb;

always @(posedge clk)
	case(pal)
	'b00: rgb <= { data,data, 3'd0, data,data ,4'd0, data,data, 3'd0};
	'b01: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b11000,6'b110000,5'b10000};
	'b10: rgb <= data ? {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};	
	'b11: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b00000,6'b110000,5'b00000};
	endcase

endmodule


module pal_apple_gr(
	clk, bitc, prebit, color, parity, rgb
);
input  clk;
input  bitc;
input  prebit;
input  color;
input  parity;
output reg [15:0]rgb;

reg oldbit = 0;

always @(posedge clk)begin
	if((oldbit|prebit)&bitc) rgb <= {5'b11000,6'b110000,5'b11000};
	else if(parity) rgb <= bitc ? color ? {5'b11000,6'b000000,5'b00000}: {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};
		  else		 rgb <= bitc ? color ? {5'b00000,6'b000000,5'b11000}: {5'b11000,6'b000000,5'b11000} : {5'b00000,6'b000000,5'b00000};
	oldbit <= bitc;
end

endmodule

module pal_T40(
	clk, clk5hz, pal, color, data ,rgb
);
input  clk;
input  clk5hz;
input  [ 1:0]pal;
input  [ 1:0]color;
input  data;
output reg [15:0]rgb;

wire invers_symb = color[1] ? 1'b1 : color[0] ? clk5hz : 1'b0;
	
always @(posedge clk)begin
	case({pal,invers_symb})
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	// T40
	//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	'b00_0: rgb <= ~{ data,data, 3'd0, data,data ,4'd0, data,data, 3'd0};
	'b00_1: rgb <= { data,data, 3'd0, data,data ,4'd0, data,data, 3'd0};
	
	'b01_0: rgb <= !data ? {5'b00000,6'b000000,5'b00000} : {5'b11000,6'b110000,5'b11000};
	'b01_1: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b11000,6'b110000,5'b11000};
	
	'b10_0: rgb <= !data ? {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};
	'b10_1: rgb <= data ? {5'b00000,6'b110000,5'b00000} : {5'b00000,6'b000000,5'b00000};
	
	'b11_0: rgb <= !data ? {5'b00000,6'b000000,5'b00000} : {5'b00000,6'b110000,5'b00000};
	'b11_1: rgb <= data ? {5'b00000,6'b000000,5'b00000} : {5'b00000,6'b110000,5'b00000};
	endcase
	end
endmodule
