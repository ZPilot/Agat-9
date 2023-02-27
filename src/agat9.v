module agat9(
	clk,
	nreset,
	nramrst,
	romselect,
	
	ram_rd,
	ram_wr,
	ram_address,
	ram_datain,
	ram_dataout,
	nwait,
	
	ddensity,
	es,
	eps,
	rvi,
	pal,
	
	vnmi,virq,
	
	sound, pa, pm,
	c050, c052, c054,
	
	//PS2_CLK,PS2_DAT,
	read_key, clr_key, rus_lat,code_key,
	
	//bus
	phi1,	addr,	din, dot,
	rw, ios,	ds
	
);
input  clk;
input  nreset;
input  nramrst;
input  romselect;
output ram_rd;
output ram_wr;
output [16:0]ram_address;
output [15:0]ram_datain;
input  [15:0]ram_dataout;
input  nwait;

output ddensity;
output [3:0]es;
output [1:0]eps;
output [1:0]rvi;
output [1:0]pal;

input vnmi,virq;

output sound;
output pa;
output pm;
output c050, c052, c054;

output read_key = C0[0] , clr_key = C0[1];
input  rus_lat;
input  [7:0]code_key;
//BUS
output phi1 = phi_1;
output [15:0]addr = AB;
input  [ 7:0]din;
output [ 7:0]dot = DO;
output rw;
output [ 5:0]ios = C[6:1];
output [ 5:0]ds  = C0['hE:9];
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	ROM
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Original Agat-9 rom
wire [7:0]rom_data;
dd6 d6(
	.address(AB[10:0]),
	.clock(clk),
	.q(rom_data)
	);
//if press PrintScreen + F12 key then include d6b rom. This operation clean zero page.
wire [7:0]rom_data_b;
dd6b d6b(
	.address(AB[10:0]),
	.clock(clk),
	.q(rom_data_b)
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
///NMI/IRQ
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire IRQ = ~virq|interruption;		// interrupt request
//wire NMI = ~vnmi|interruption;		// non-maskable interrupt request
reg NMI = 1'b1;
//reg IRQ = 1'b1;

always @(posedge NMI_ack or negedge vnmi)
	if(NMI_ack)NMI <= 1'b1;
	else NMI <= interruption;
	
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	CPU
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [15:0] AB;		// address bus CPU
reg  [ 7:0]	DI;		// data in, read bus
wire [ 7:0]	DO;		// data out, write bus
//wire			rw;

//wire 	RDY = 1'b1;	// Ready signal. Pauses CPU when RDY=0, not use this.
wire	SO	 = 1'b0;		// Set Overflow, not used.
wire 			SYNC;

clk_div#5 cpuclks(clk, cpuclk);

wire phi_0, phi_1, phi_2, cpuclk;
wire sysask = nwait;
wire NMI_ack;

agclk aclk(
	.clk(cpuclk),
	.n_reset(nramrst),
	.ask(sysask),
	.phi_0(phi_0), .phi_1(phi_1), .phi_2(phi_2)
	);

/*ag6502 cpu1( .phi_0(phi_0), .phi_1(phi_1), .phi_2(phi_2), .ab(AB),
				.read(rw), .db_in(DI), .db_out(DO), .rdy(1'b1),
				.rst(nreset), .irq(IRQ), .nmi(NMI), .so(SO), .sync(SYNC), .NMI_ack(NMI_ack));*/
				
T65 cpu1(.Mode(2'b00), .Res_n(nreset),.Enable(1'b1),
			.Clk(phi_1), .Rdy(1'b1), .Abort_n(1'b1), .IRQ_n(IRQ),
			.NMI_n(NMI), .SO_n(SO), .R_W_n(rw), .Sync(SYNC),
			.A(AB), .DI(DI), .DO(DO), .NMI_ack(NMI_ack));
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// nmi irq enable
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg interruption = 1'b1;
wire interreset = ~nreset|C0[2];

always @(posedge C0[4] or posedge interreset)interruption<=interreset ? 1'b1 : 1'b0;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//	Sound
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg	sound = 1'b0;
always @(posedge C0[3])sound <= ~sound;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 840aim
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire fddask = C[3]|C0['hb];
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 140
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire fddask_140 = C[6]|C0['hE];
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// pa/pm
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg  pa = 1'b1;
reg  pm = 1'b1;
wire npm = ~pm;

wire c0frw = ~rw & C0['hf];
always @(posedge c0frw or posedge romselect)if(romselect)pm <= 1'b1;else pm <= 1'b0;

wire rstpa = ~AB[3] & C0[5];
always @(posedge rstpa or posedge C[7]or posedge romselect)
	if(romselect)pa <= 1'b1;
	else pa <= rstpa ? 1'b0 : pm;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Сигналы ЦПУ и вспомогательные сигналы
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg blkram = 1'b1;
reg blkrom = 1'b1;
reg blkio = 1'b1;
reg dma = 1'b1;
wire lc_0,lc_wr,lc_rd,lc_d;
wire onrom_n,de,rp,cc,f,onram_n,w,a12f;
wire [ 7:0]C;
wire [15:0]C0;

wire romsel_n = ~dma|onrom_n|(f&de);

wire ram_rd = ~onram_n & w & phi_0;
wire ram_wr = ~(onram_n|w )& phi_0;

assign ram_datain = {DO,DO};
assign ram_address = {ABm,a12f,AB[11:0]};
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Входные данные для ЦПУ
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire cpuread = ~rw | phi_2;
always @(negedge cpuread)
	case({~romsel_n, ~onram_n, C[1] , C0[ 0], C0[6], fddask, C0[8] , C[7], fddask_140})
	'b100000000: DI <= romselect ? rom_data_b : rom_data;
	'b010000000: DI <= (ABm[0] ? ram_dataout[15:8] : ram_dataout[7:0]); //RAM
	'b001000000: DI <= {AB[7:4],ABm}; //Устройство распределения памяти или DK
	'b000100000: DI <= code_key;		//keyboard
	'b000010000: case(AB[2:0])
						'b000:   DI <={1'b0,AB[14:8]};	//Вход от магнитофона
						'b001:   DI <={1'b0,AB[14:8]};	//Кнопка 1 пульта
						'b010:   DI <={1'b0,AB[14:8]};	//Кнопка 2 пульта
						'b011:   DI <={~rus_lat,AB[14:8]}; //keyboard rus/lat
						'b100:   DI <={1'b0,AB[14:8]};	//Пульт 1
						'b101:   DI <={1'b0,AB[14:8]};	//Пульт 2
						default: DI <={1'b0,AB[14:8]};	//Не используется
					endcase
	'b000001000: DI <= din;									//FDD data FDD840K
	'b000000100: DI <= {4'b1100,lc_d,1'b0,lc_rd,~lc_wr};	//LC
	'b000000010: DI <= AB[7:0]; 							//{ddensity,es[2:0],eps,rvi}
	'b000000001: DI <= din;									//FDD data FDD140K
	default:     DI <= AB[15:8];
	endcase
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//wire [7:0] lc_reg = {4'b1100,lc_d,1'b0,lc_rd,~lc_wr};
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++	
d3 dd3(
	.address({npm,lc_rd,rw,lc_wr,AB[3],AB[1:0],lc_0}),
	.inclock(~cpuclk),
	.outaclr(romselect),	//(~nreset),
	.outclock(C0[8]),		//c08
	.q({lc_0,lc_wr,lc_rd,lc_d})
	);

d14 dd14(
	.address({1'b0,npm,blkrom,blkram,rw,lc_d,lc_rd,lc_wr,~(&AB[15:14]),AB[13:12]}),
	.clock(cpuclk),
	.q({onrom_n,de,rp,cc,f,onram_n,w,a12f})
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// C000-C00F
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire d52ena = ~(AB[11]|phi_1) & cc & blkio;

k555id7 d52(
	.data(AB[10:8]),
	.enable(d52ena),
	.eq0(C[0]), .eq1(C[1]), .eq2(C[2]), .eq3(C[3]),
	.eq4(C[4]), .eq5(C[5]), .eq6(C[6]), .eq7(C[7])
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//C000-C07F & C080-C0FF
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
k555id7_2 d9451(
	.data(AB[7:4]), .enable(C[0]),
	.eq0(C0[0]), .eq1(C0[1]), .eq2(C0[2]), .eq3(C0[3]),
	.eq4(C0[4]), .eq5(C0[5]), .eq6(C0[6]), .eq7(C0[7]),
	
	.eq8(C0[8]), .eq9(C0[9]), .eq10(C0['hA]), .eq11(C0['hB]),
	.eq12(C0['hC]), .eq13(C0['hD]), .eq14(C0['hE]), .eq15(C0['hF])
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Устройство распределения памяти
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [3:0]ABm;
wire dd21wren = ~rw & C[1] & pm;
wire [3:0]addrdd21 = cc ? AB[7:4] : {rp,AB[15:13]};
d21 dd21(
	.clock(~cpuclk),
	.data(AB[3:0]),
	.wraddress(AB[7:4]),
	.wren(dd21wren),
	.rdaddress(addrdd21),
	.q(ABm)
	);
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Управление режимами отображения
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg ddensity = 0;		//режим двойной плотности
reg [3:0]es  = 0;		//номер банка выводимого на экран
reg [1:0]eps = 0;		//номер банка для графических или номер четверти банка для текстовых режимов
reg [1:0]rvi = 0;		//видеорежим: 	00- цветной графический 256*256
							//					01- цветной графический 128*128
							//					10- тестовый Т32/Т64
							//					11- монохромный графический 256*256 256*512
reg B = 1'b1;
reg [2:0]tes = 0;
always @(*)begin
	casex({ddensity,pa,rvi})
		//apple
		'bx0_00: B<=1'b0;
		'bx0_01: B<=1'b0;
		'bx0_10: B<=1'b1;
		'bx0_11: B<=1'b1;
		//agat
		'bx1_00: B<=1'b1;
		'bx1_01: B<=1'b1;
		'b01_10: B<=1'b0;
		'b11_10: B<=1'b0;
		'b01_11: B<=1'b1;
		'b11_11: B<=1'b1;
		default: B<=B;
	endcase
	es <={eps[1]&B,tes};
	//es[3]<=eps[1]&B;
	end

always @(posedge C[7]){ddensity,tes,eps,rvi} <= AB[7:0];
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//Режимы ДК для Apple и палитры
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
reg c050 = 0,c052 = 0,c054 = 0;
reg [1:0]pal = 0;

always @(posedge C0[5])
	case(AB[3:1])
	//Apple
	'b000: c050 <= AB[0]; 	// c050 graph
	'b001: c052 <= AB[0]; 	// c052 comb
	'b010: c054 <= AB[0]; 	// c054 page
	//Pal
	'b100: pal[0] <= AB[0]; // c058
	'b101: pal[1] <= AB[0]; // c05A
	endcase

endmodule
