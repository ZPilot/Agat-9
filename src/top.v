module top(
	clk50,
	n_rst,
	
	sound, leds, led0,
	
	PS2_CLK,PS2_DAT,
	
	dig, seg,
	
	hsync,vsync,rgb,
	
	SD_cd, SD_clk, SD_cs,
	SD_datain, SD_dataout,
	
	SD_clk_140, SD_cs_140,
	SD_datain_140, SD_dataout_140,

	SDRAM_DQ,    // 16 bit bidirectional data bus
	SDRAM_A,     // 13 bit multiplexed address bus
	SDRAM_DQML,  // two byte masks
	SDRAM_DQMH,  // 
	SDRAM_BA,    // two banks
	SDRAM_nCS,   // a single chip select
	SDRAM_nWE,   // write enable
	SDRAM_nRAS,  // row address select
	SDRAM_nCAS,  // columns address select
	SDRAM_CKE,   // clock enable
	SDRAM_CLK    // clock
);
input clk50;
input n_rst;

output sound;

inout  PS2_CLK;
inout  PS2_DAT;

output [2:0] dig;
output [7:0] seg;

output hsync;
output vsync;
output [15:0]rgb;

input  SD_cd;
output SD_clk;
output SD_cs;
output SD_datain;
input  SD_dataout;

output SD_clk_140;
output SD_cs_140;
output SD_datain_140;
input  SD_dataout_140;

output led0 = ~prnscr;
output [4:0]leds = {~SD_active,~SD_active_140,~nofdd,~pa,~pm};
	
inout  [15:0] SDRAM_DQ;    // 16 bit bidirectional data bus
output [12:0] SDRAM_A;     // 13 bit multiplexed address bus
output        SDRAM_DQML;  // two byte masks
output        SDRAM_DQMH;  // 
output [ 1:0] SDRAM_BA;    // two banks
output        SDRAM_nCS;   // a single chip select
output        SDRAM_nWE;   // write enable
output        SDRAM_nRAS;  // row address select
output        SDRAM_nCAS;  // columns address select
output        SDRAM_CKE;   // clock enable
output        SDRAM_CLK;   // clock
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire sysclk,ramclk,pclk,n_ramrst;//keyclk
sysclk cristall1(
	.inclk0(clk50),
	.c0(sysclk),
	.c1(ramclk),
	.c2(SDRAM_CLK),
	.c3(pclk),
	//.c4(keyclk),
	.locked(n_ramrst)
	);
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	HEX
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg [7:0]hexdat = 0;
always @(*)
	case(disk)
	'b00:hexdat <= sel_disk_a0;
	'b01:hexdat <= sel_disk_a1;
	'b10:hexdat <= sel_disk_b0;
	'b11:hexdat <= sel_disk_b1;
	endcase
segm hex1(
	.clk	(clk50),
	.num0	(hexdat[3:0]),
	.num2	({2'b00,disk}+1'b1),
	.num1	(hexdat[7:4]),

	.dig	(dig),
	.seg	(seg)
	);
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Controller sdram read BURST_LENGTH 8 and casche read controller
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [23:0] address = {7'd0,ram_address};
wire [23:0] address_toram;
wire [15:0] datain;
wire [15:0] dataout;
wire n_wait;

assign dqm = {~address_toram[13],address_toram[13]};
assign addr = {8'd0,address_toram[16:14],address_toram[12:0]};
//casche read controller
qyou qu1(
	.clk(SDRAM_CLK),
	.clkram(ramclk),
	.n_rst(n_reset),
	//interface from CPU
	.address(address),
	.datain(datain),
	.dataout(dataout),
	.read(ramrd),
	.write(ramwr),
	.n_wait(n_wait),
	//intrface to RAM
	.address_ram(address_toram),
	.datafromram(dout),
	.datatoram(din),
	.readram(rd),
	.writeram(we),
	.ready(ready)
);
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire we;
wire rd;
wire ready;
wire n_reset;

wire [23:0] addr;		// 24 bit address 
wire [15:0] dout;		// data output to cpu
wire [15:0] din; 		// data input from cpu
wire [ 1:0] dqm; 		// dqm write only
//+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Controller sdram read BURST_LENGTH 8
sdram ram1
(
	.init(~n_ramrst), 			// reset to initialize RAM .init(~(n_ramrst&n_rst)),
	.clk(ramclk),         		// clock ~100MHz
	.init_ok(n_reset),		 	// init memory ok
                              //
										// SDRAM_* - signals to the MT48LC16M16 chip
	.SDRAM_DQ	(SDRAM_DQ),    // 16 bit bidirectional data bus
	.SDRAM_A		(SDRAM_A),     // 13 bit multiplexed address bus
	.SDRAM_DQML	(SDRAM_DQML),  // two byte masks
	.SDRAM_DQMH	(SDRAM_DQMH),  // 
	.SDRAM_BA	(SDRAM_BA),    // two banks
	.SDRAM_nCS	(SDRAM_nCS),   // a single chip select
	.SDRAM_nWE	(SDRAM_nWE),   // write enable
	.SDRAM_nRAS	(SDRAM_nRAS),  // row address select
	.SDRAM_nCAS	(SDRAM_nCAS),  // columns address select
	.SDRAM_CKE	(SDRAM_CKE),   // clock enable

										//
   .addr(addr),        			// 24 bit address 
   .dout(dout),        			// data output to cpu
   .din(din),         			// data input from cpu
   .we(we),          			// cpu requests write
	.dqm(dqm),			 			// dqm write only
   .rd(rd),          			// cpu requests read
   .ready(ready),      			// dout is valid. Ready to accept new read/write.
	
	.addrvga(address_vga),  	// 24 bit address
	.doutvga(doutvga),      	// data output to cpu
	.rdvga(read_vga),       	// cpu requests read
	.readyvga(readyvga)     	// dout is valid. Ready to accept new read/write.
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// VGA controller
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire read_vga;
wire [23:0]address_vga;
wire readyvga;
wire [15:0] doutvga;
wire nmi,irq;

vga1024x768_v2 vga(
	.pclk(pclk),
	.ramclk(ramclk),
	.sdramclk(SDRAM_CLK),

	.hsync(hsync),
	.vsync(vsync),
	.rgb(rgb),
	
	.read_vga(read_vga),
	.address(address_vga),
	.dout_vga(doutvga),
	.ready_vga(readyvga),
	
	._ddensity(ddensity),
	._es(es),
	._eps(eps),
	._rvi(rvi),
	._pal(pal),
	
	._pa(pa),
	._c050(c050), ._c052(c052), ._c054(c054),
	
	.nmi(nmi),
	.irq(irq)
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Agat 9 logic
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire ramrd;
wire ramwr;
wire [16:0]ram_address;

wire ddensity;
wire [3:0]es;
wire [1:0]eps;
wire [1:0]rvi;
wire [1:0]pal;
wire pa,pm;
wire c050, c052, c054;

wire SD_active, SD_active_140;
wire nofdd;
//BUS
wire phi1;
wire [15:0]addr_bus;
wire [ 7:0]din_bus = fdd140data|fdd840data;
wire [ 7:0]dot_bus;
wire rw;
wire [ 5:0]ios;
wire [ 5:0]ds;

wire n_reset_agat = n_reset&n_rst&(~reset_key);

agat9 agat(
	.clk(sysclk),
	.nreset(n_reset_agat),
	.nramrst(n_ramrst),
	
	.romselect(prnscr),
	
	.ram_rd(ramrd),
	.ram_wr(ramwr),
	.ram_address(ram_address),
	.ram_datain(datain),
	.ram_dataout(dataout),
	.nwait(n_wait),
	
	.ddensity(ddensity),
	.es(es),
	.eps(eps),
	.rvi(rvi),
	.pal(pal),
	
	.vnmi(nmi), .virq(irq),
	
	.sound(sound),
	.pa(pa),
	.pm(pm),
	
	.c050(c050), .c052(c052), .c054(c054),
	
	.read_key(read_key), .clr_key(clr_key), .rus_lat(rus_lat), .code_key(code_key),
	
	//bus
	.phi1(phi1), .addr(addr_bus), .din(din_bus), .dot(dot_bus),
	.rw(rw), .ios(ios), .ds(ds)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Keyboard
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire read_key,clr_key;
wire rus_lat;
wire [7:0]code_key;
wire reset_key;
wire prnscr;
wire [1:0]disk;
wire [7:0] sel_disk_a0;
wire [7:0] sel_disk_a1;
wire [7:0] sel_disk_b0;
wire [7:0] sel_disk_b1;

mag_keys mkey(
	.clk50(clk50),
	.n_rst(n_ramrst),
	
	.read_key(read_key),
	.clr_key(clr_key),
	.rus_lat(rus_lat),
	.prnscr(prnscr),
	.code_key(code_key),
	
	.reset_key(reset_key),
	.disk(disk),
	.sel_disk_a0(sel_disk_a0), .sel_disk_a1(sel_disk_a1),
	.sel_disk_b0(sel_disk_b0), .sel_disk_b1(sel_disk_b1),
	
	.PS2_CLK(PS2_CLK),
	.PS2_DAT(PS2_DAT)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Slot x3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 840aim - insert slot x3
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [7:0] fdd840data;
fdd840cntrl k1(
	.clk(sysclk),
	.clkcpu(phi1),
	.nreset(n_reset_agat),
	
	.io_on(ds[2]),
	.rom_on(ios[2]),
	.rw(rw),
	
	.address(addr_bus[7:0]),
	.din(dot_bus),
	.dout(fdd840data),
	
	.SD_cd(SD_cd), .SD_clk(SD_clk), .SD_cs(SD_cs),
	.SD_datain(SD_datain), .SD_dataout(SD_dataout),
	.SD_active(SD_active), .nofdd(nofdd),
	
	.sel_disk_a0(sel_disk_a0), .sel_disk_a1(sel_disk_a1)
);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Slot x6
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 140
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [7:0] fdd140data;
wire nofdd_140;
fdd140cntrl k2(
	.clk(sysclk),
	.clkcpu(phi1),
	.nreset(n_reset_agat),
	
	.io_on(ds[5]),
	.rom_on(ios[5]),
	.rw(rw),
	
	.address(addr_bus[7:0]),
	.din(dot_bus),
	.dout(fdd140data),
	
	.SD_cd(0), .SD_clk(SD_clk_140), .SD_cs(SD_cs_140),
	.SD_datain(SD_datain_140), .SD_dataout(SD_dataout_140),
	.SD_active(SD_active_140), .nofdd(nofdd_140),
	
	.sel_disk_b0(sel_disk_b0), .sel_disk_b1(sel_disk_b1)
);
endmodule