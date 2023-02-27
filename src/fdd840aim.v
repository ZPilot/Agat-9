module fdd840aim(
	clkcpu,
	clk100,
	res,
	
	io_on,
	rom_on,
	rw,
	
	address,
	din,
	dout,
	doutask,
	
	nofdd,
	atrack,
	loadask,
	ram_write_addr,
	ram_di,
	ram_we
);
input			 clkcpu;
input			 clk100;
input			 res;

input 		 io_on;
input 		 rom_on;
input 		 rw;
	
input  [ 7:0] address;
input  [ 7:0] din;
output [ 7:0] dout;
output		  doutask;

output		  nofdd = rkfddsel;
output [ 7:0] atrack={track,rkhead};
input			  loadask;
input	 [13:0] ram_write_addr ;	//Address for track RAM
input	 [ 7:0] ram_di;				//Data to track RAM
input			  ram_we;				//RAM write enable
//-----------------------------------------------------------
/*reg [31:0] addrindisk = 0;
reg [8:0] arrdintrk = 0;
//always @(negedge byte_clk)begin
wire [3:0]bsec = sec[4:1];
always @(posedge clk)begin
	addrindisk = {24'd0,track,rkhead};
	addrindisk = addrindisk * 32'd21;
	addrindisk = addrindisk + bsec;
	//arrdintrk = arrdintrk << 8;
	arrdintrk = {sec[0],bytessec};
end*/
//-----------------------------------------------------------
assign doutask = (rom_on|io_on)&clkcpu;//io_on & rw;
assign dout = rom_on ? romdata : reg_data;

reg	[ 7:0] reg_data = 0;
//-----------------------------------------------------------
// S-reg
reg		 srdy  = 1'b0; //ready fdd
reg		 swp   = 1'b0; //write protect
reg  [1:0]fdd1 = 2'b00;
reg  [1:0]fdd2 = 2'b11;
wire		 s0sec;
wire		 s0trk;

wire [7:0]sreg = {srdy|(~rkonfdd),s0trk,swp,s0sec,fdd1,fdd2};
//-----------------------------------------------------------
// RK-reg
wire 		rkonfdd;
wire 		rkrw;
wire 		rkpkon;
wire 		rkhead;
wire 		rkfddsel;
wire 		rkdir;
wire 		rknop;
wire		rkpk;
reg [7:0]rk = 8'h00;

assign {rkonfdd,rkrw,rkpkon,rkhead,rkfddsel,rkdir,rknop,rkpk} = rk;
//-----------------------------------------------------------
wire c0y1, c0y2, c0y3, c0y4;
wire c0y5, c0y6, c0y7, c0y8;
wire c0y9, c0ya;
fddadr dc1(
	.data(address[3:0]),
	.eq01(c0y1),
	.eq02(c0y2),
	.eq03(c0y3),
	.eq04(c0y4),
	.eq05(c0y5),
	.eq06(c0y6),
	.eq07(c0y7),
	.eq08(c0y8),
	.eq09(c0y9),
	.eq0a(c0ya)
	);
//-----------------------------------------------------------
// RD-reg
reg byte_rdy = 1'b0;
reg sync_bit = 1'b1;
wire rdy_rst_all = ~rkonfdd|rdy_rst|rdy_rst1;
wire sync_rst_all = (~rkonfdd|sync_rst);
always @(posedge sync_set or posedge sync_rst_all)sync_bit <= sync_set ? 1'b0 : 1'b1;
always @(posedge byte_clk or posedge  rdy_rst_all)byte_rdy <= rdy_rst_all? 1'b0 : 1'b1;
//-----------------------------------------------------------
//
reg [7:0] spin = 8'd31;
wire		 spinrst = ~rkonfdd|res|byte_clk;

always @(posedge clkcpu or posedge spinrst) spin <= spinrst ? 8'd31 : spin + 8'd1;

reg  [12:0]addrbyte= 0;
reg  [ 7:0]diskdata = 0;
reg  sync_set = 0;
reg  rdy_rst1 = 1'b0;
wire byte_clk = spin[7];
reg  [ 2:0] nulsec = 0;
reg  [39:0] datnulsec = 0;

always @(posedge byte_clk or posedge res)
	if(res)begin
		addrbyte <=13'd0;
		diskdata <= 0;
		{sync_set,rdy_rst1} <= 2'b00;
		nulsec <= 0;
		datnulsec <= 0;
	end else begin
		{sync_set,rdy_rst1} <= 2'b00;
		if(!loadask)begin  diskdata <= 8'hAA;end
		else case(ram_do[15:8])
				'h01: begin {sync_set,rdy_rst1} <= 2'b10; diskdata <= ram_do[7:0]; nulsec <= 0; end
				'h02: begin addrbyte <=13'd0; diskdata <= ram_do[7:0]; end
				default:	begin diskdata <= ram_do[7:0]; 
						   if(nulsec < 4)begin datnulsec <= {datnulsec[31:0],ram_do[7:0]}; nulsec<=nulsec + 1'b1; end
							end
				endcase
			if(addrbyte < 13'h193F)addrbyte <= addrbyte + 1'b1;
			else addrbyte <= 0;
		end
//-----------------------------------------------------------
//	buffer on singl track
//-----------------------------------------------------------
wire [15:0]ram_do;
reg  [12:0]_addrbyte = 0;
always @(*)
	case(atrack[1:0])
	'b01: _addrbyte <= addrbyte + 13'd64;
	'b10: _addrbyte <= addrbyte + 13'd128;
	'b11: _addrbyte <= addrbyte + 13'd192;
	default: _addrbyte <= addrbyte;
	endcase

disk2aim_ram d2aimram(
	.wraddress(ram_write_addr),
	.wrclock(clk100),
	.data(ram_di),
	.wren(ram_we),
	
	.rdaddress(_addrbyte),
	.rdclock(byte_clk),
	.q(ram_do)
	);

//-----------------------------------------------------------
reg		 ok_op    = 0;
reg		 sync_rst = 0;
reg		 rdy_rst  = 0;
reg [7:0] vv55_14  = 0;
reg [7:0] vv55_15  = 0;

always @(posedge clk100 or posedge res)
	if(res)begin
		track 	<= 7'd1;
		sync_rst <= 1'b0;
		ok_op 	<= 0;
		rk			<= 0;
		rdy_rst 	<= 1'b0;
		vv55_14  <= 0;
		vv55_15  <= 0;
	end else if(io_on) begin
		sync_rst <= 1'b0;
		rdy_rst 	<= 1'b0;
		if(!ok_op)begin
			ok_op <= 1'b1;
			//-----------------------------------------------------------
			case({rw,address[3:0]})
			//-----------------------------------------------------------
			// write
			'b0_0010: rk <= din;
			'b0_0011: begin vv55_14 <= 8'hFF;
				if(!din[7]) begin rk[din[3:1]] <= din[0]; {rdy_rst,sync_rst} <= 2'b11;								end
				else 			if(din==8'h9B) begin rk <= 0;																		end
				end
			'b0_0111: vv55_15 <= din;
			'b0_1001: begin track <= rkdir ? track < 79 ? track + 7'd1 : 7'd79:
											 track > 0 ? track - 7'd1 : 7'd0;													end
			//-----------------------------------------------------------
			// read
			'b1_0001: reg_data <= sreg;
			'b1_0011: reg_data <= vv55_14;
			'b1_0100: begin reg_data <= diskdata; rdy_rst 	<= 1'b1; 													end
			'b1_0110: begin reg_data <={byte_rdy,sync_bit,6'd0}; 															end
			'b1_0111: reg_data <= vv55_15;
			'b1_1010: begin sync_rst <= 1'b1;																					end
			endcase
			//-----------------------------------------------------------
			end
		end else ok_op <= 0;
//-----------------------------------------------------------
reg [6:0] track = 7'd1;

assign s0sec = |datnulsec[7:0];
assign s0trk = |track;//{track[6:0],rkhead};
//-----------------------------------------------------------
// boot rom
wire [7:0] romdata;
romfdd840 romfdd1(
	.address (address),
	.clock	(clk100),
	.q			(romdata)
	);

endmodule
