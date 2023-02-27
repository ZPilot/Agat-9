module qyou(
	clk,
	clkram,
	n_rst,
	//interface to CPU
	address,
	datain,
	dataout,
	read,
	write,
	n_wait,
	//intrface to RAM
	address_ram,
	datafromram,
	datatoram,
	readram,
	writeram,
	ready
);
input clk;
input clkram;
input n_rst;
input  [23:0] address;
input  [15:0] datain;
output [15:0] dataout;
input  read;
input  write;
input  ready;

output [23:0] address_ram = writeram? address : {address[23:3],3'b000};
input  [15:0] datafromram;
output [15:0] datatoram = datain;
output readram;
output writeram;
output n_wait;

reg readram = 0;
reg writeram = 0;
reg n_wait = 1'b1;
reg [23:0] address_ram_ch = 24'h1; // address_ram_ch not equ 1! It's first step

wire nocahe = address_ram_ch != {address[23:3],3'b000};
reg idle = 1'b0;
reg readop = 0;
reg writeop = 0;

always @(posedge clk or negedge n_rst)
	if(!n_rst)begin
		{readram, writeram, n_wait} = 3'b001;
		address_ram_ch <= 24'h1;
		idle <= 1'b0;
		readop <= 0;
		writeop <= 0;
	end else 
		if(ready)begin
			idle <= 1'b1;
			if(readop)address_ram_ch <= {address[23:3],3'b000};
			if(!nocahe && writeop)address_ram_ch <= 24'h1;
			readram <=0; writeram <=0;
		end else begin
		
			if(idle)n_wait <=1'b1;
			
			if(read)begin
				if(!readop){readram,n_wait,readop} <= {nocahe,~nocahe,nocahe};
			end else begin if(readop)idle <= 1'b0; readop <= 0; end
			
			if(write)begin
				if(!writeop){writeram,n_wait,writeop} <= 3'b101;
			end else begin if(writeop)idle <= 1'b0; writeop <= 0; end
		end

reg [2:0]countbyte = 0;
always @(posedge clkram or negedge n_rst)
	if(!n_rst)countbyte <= 0;
	else if(ready & readop)countbyte <= countbyte + 1'b1;
		  else countbyte <= 0;

ramcache rmch1(
	.clock(clk),
	.data(datafromram),
	.wraddress({1'b0,countbyte}),
	.wren(ready & readop),
	
	.rdaddress({1'b0,address[2:0]}),
	.q(dataout)
	);
endmodule
