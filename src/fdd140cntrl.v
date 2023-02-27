module fdd140cntrl(
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
	
	sel_disk_b0, sel_disk_b1
);
input  clk;
input  clkcpu;
input  nreset;

input  io_on;
input  rom_on;
input  rw;
	
input  [ 7:0] address;
input  [ 7:0] din;
output [ 7:0] dout = io_on|rom_on ? fdd_data140 : 8'h00;

input  SD_cd;
output SD_clk;
output SD_cs;
output SD_datain;
input  SD_dataout;
output SD_active = |stepsd_140[2:1];
output nofdd;

input [7:0] sel_disk_b0;
input [7:0] sel_disk_b1;
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// FDD 140
//++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
wire [ 7:0] fdd_data140;
wire [ 5:0] track_140;
wire			D1_ACTIVE,D2_ACTIVE;
wire [12:0] ram_write_addr;
wire [ 7:0] ram_di;
wire			ram_we;
wire [12:0]	track_addr;


fdd140 k140(
	 .clk				  	(clk),
    .clkcpu			 	(~clkcpu),
    .rom_on      		(rom_on),
    .io_on  			(io_on),
    .RESET          	(~nreset),
    .A              	(address),
    .D_IN           	(din),
    .D_OUT          	(fdd_data140),
    .TRACK          	(track_140),
    .track_addr		(track_addr),
    .nofdd				(nofdd),
    .ram_write_addr  (ram_write_addr),
    .ram_di          (ram_di),
    .ram_we          (ram_we)
    );

wire cardinit_140;
wire readok_140;

sd_top#13 sdcrd2(
	.clk(clk),
	.n_rst(nreset),
	
	.cardinit(cardinit_140),
	
	.read(readsd_140), .sec(secsd_140),
	.readok(readok_140),
	
	.mydata_o(ram_di),
	.addrwrite(ram_write_addr),
	.wren(ram_we),
	
	.SD_cd(SD_cd), .SD_clk(SD_clk), .SD_cs(SD_cs),
	.SD_datain(SD_datain), .SD_dataout(SD_dataout)
);

reg  readsd_140 = 0;
reg  [ 5:0]oldatrack_140 = 6'h3F;
reg  [31:0]secsd_140 = 32'hFFFFFFFF;
reg  [ 2:0]stepsd_140 = 0;
//reg  sdask_140 = 0;
reg  oldfdd_140 = 0;
//wire nofdd;

//secsd_140 <= 32'd13 * oldatrack_140;
wire [31:0]SECSD140_OT = (oldatrack_140<<3) + (oldatrack_140<<2) + oldatrack_140;
//secsd_140 <=  32'd455 * sel_disk_b1 + secsd_140;
wire [31:0]SECSD140_B0 = (sel_disk_b0<<8) + (sel_disk_b0<<7) + (sel_disk_b0<<6) + (sel_disk_b0<<2) + (sel_disk_b0<<1) + sel_disk_b0;
wire [31:0]SECSD140_B1 = (sel_disk_b1<<8) + (sel_disk_b1<<7) + (sel_disk_b1<<6) + (sel_disk_b1<<2) + (sel_disk_b1<<1) + sel_disk_b1;

reg  [ 7:0]old_sel_disk_b0 = 8'd255;
reg  [ 7:0]old_sel_disk_b1 = 8'd255;

always @(posedge clk or negedge nreset)
	if(!nreset)begin
		readsd_140 <= 0;
		oldatrack_140 <= 6'h3F;
		secsd_140 <= 32'hFFFFFFFF;
		stepsd_140 <= 0;
		//sdask_140 <= 0;
		old_sel_disk_b0 = 8'd255;
		old_sel_disk_b1 = 8'd255;
	end else 
		case(stepsd_140)
		'd0 : if(cardinit_140)stepsd_140 <= 3'd1;
		'd1 : if(clkcpu && (oldatrack_140!=track_140 || oldfdd_140!=nofdd || old_sel_disk_b0!=sel_disk_b0 || old_sel_disk_b1!=sel_disk_b1))
				begin
					oldatrack_140<=track_140; oldfdd_140 <= nofdd; stepsd_140 <= 3'd2;
					old_sel_disk_b0<=sel_disk_b0; old_sel_disk_b1<=sel_disk_b1;
				end
		'd2 : begin secsd_140 <= SECSD140_OT; stepsd_140 <= 3'd3; end
		'd3 : if(oldfdd_140)begin secsd_140 <=  SECSD140_B1 + secsd_140; stepsd_140 <= 3'd4; end
				else		 	  begin secsd_140 <=  SECSD140_B0 + secsd_140; stepsd_140 <= 3'd4; end
		'd4 : begin readsd_140 <= 1'b1; stepsd_140 <= 3'd5; end
		'd5 : if(!readok_140)begin readsd_140 <= 1'b0; stepsd_140 <= 3'd6; end
		'd6 : if(readok_140)stepsd_140 <= 3'd7;
		default: stepsd_140 <= 3'd1;
		endcase


endmodule
