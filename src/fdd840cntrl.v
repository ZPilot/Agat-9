module fdd840cntrl(
	clk,
	clkcpu,
	nreset,
	
	io_on,
	rom_on,
	rw,
	
	address,
	din,
	dout,
	
	SD_cd, SD_clk, SD_cs,
	SD_datain, SD_dataout,
	SD_active, nofdd,
	
	sel_disk_a0, sel_disk_a1
);
input  clk;
input  clkcpu;
input  nreset;

input  io_on;
input  rom_on;
input  rw;
	
input  [ 7:0] address;
input  [ 7:0] din;
output [ 7:0] dout = io_on|rom_on ? fdd_data : 8'h00;

input  SD_cd;
output SD_clk;
output SD_cs;
output SD_datain;
input  SD_dataout;
output SD_active = |stepsd[2:1];
output nofdd;

input [7:0] sel_disk_a0;
input [7:0] sel_disk_a1;

//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 840aim
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ 7:0]fdd_data;
wire		  fddask;
wire		  nofdd;

fdd840aim fdd840(
	.clkcpu	(~clkcpu),
	.clk100	(clk),
	.res		(~nreset),
	
	.io_on	(io_on),
	.rom_on	(rom_on),
	.rw		(rw),
	
	.address (address),
	.din		(din),
	.dout		(fdd_data),
	.doutask (fddask),
	
	.nofdd	(nofdd),
	.atrack	(atrack),
	.loadask (sdask),
	.ram_write_addr(addrwrite),
	.ram_di	(mydata_o),
	.ram_we	(sd_chach_wren)
);
wire cardinit;
wire readok;
wire [ 7:0]mydata_o;
wire [13:0]addrwrite;
wire sd_chach_wren;

sd_top#26 sdcrd1(
	.clk(clk),
	.n_rst(nreset),
	
	.cardinit(cardinit),
	
	.read(readsd), .sec(secsd),
	.readok(readok),
	
	.mydata_o(mydata_o),
	.addrwrite(addrwrite),
	.wren(sd_chach_wren),
	
	.SD_cd(SD_cd), .SD_clk(SD_clk), .SD_cs(SD_cs),
	.SD_datain(SD_datain), .SD_dataout(SD_dataout)
);
wire [ 7:0]atrack;
reg  readsd = 0;
reg  [ 7:0]oldatrack = 8'hFF;
reg  [31:0]secsd = 32'hFFFFFFFF;
reg  [ 2:0]stepsd = 0;
reg sdask = 0;
reg oldfdd = 0;

//secsd <=  32'd4040 * sel_disk_a1 + (secsd>>9); 
wire [31:0]SECSD_A0=(sel_disk_a0<<11) + (sel_disk_a0<<10) + (sel_disk_a0<<9) + (sel_disk_a0<<8) + (sel_disk_a0<<7) + (sel_disk_a0<<6) + (sel_disk_a0<<3);
wire [31:0]SECSD_A1=(sel_disk_a1<<11) + (sel_disk_a1<<10) + (sel_disk_a1<<9) + (sel_disk_a1<<8) + (sel_disk_a1<<7) + (sel_disk_a1<<6) + (sel_disk_a1<<3);
//secsd <=  32'h3280 * oldatrack; 12928
wire [31:0]SECSD_OT=(oldatrack<<13) + (oldatrack<<12) + (oldatrack<<9) + (oldatrack<<7); 

always @(posedge clk or negedge nreset)
	if(!nreset)begin
		readsd <= 0;
		oldatrack <= 8'hFF;
		secsd <= 32'hFFFFFFFF;
		stepsd <= 0;
		sdask <= 0;
	end else 
		case(stepsd)
		'd0 : if(cardinit)stepsd <= 3'd1;
		'd1 : if(clkcpu && (oldatrack!=atrack || oldfdd!=nofdd))begin oldatrack <= atrack; oldfdd <= nofdd; stepsd <= 3'd2; sdask <= 0; end
		'd2 : begin secsd <=  SECSD_OT; stepsd <= 3'd3; end
		'd3 : if(oldfdd)begin secsd <=  SECSD_A1 + (secsd>>9); stepsd <= 3'd4; end
				else 		 begin secsd <=  SECSD_A0 + (secsd>>9); stepsd <= 3'd4; end
		'd4 : begin readsd <= 1'b1; stepsd <= 3'd5; end
		'd5 : if(!readok)begin readsd <= 1'b0; stepsd <= 3'd6; end
		'd6 : if(readok)stepsd <= 3'd7;
		default: begin stepsd <= 3'd1; sdask <= 1'b1; end
		endcase

endmodule
