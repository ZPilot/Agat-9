module fdd140(
	input				clk,
   input				clkcpu,
   input				rom_on,
   input				io_on,
   input				RESET,
   input	[ 7:0]	A,
   input	[ 7:0]	D_IN,					// From 6502
   output[ 7:0]	D_OUT,				//To 6502
   output[ 5:0]	TRACK,				//Current track (0-34)
   output[12:0]	track_addr,
   output			nofdd,
   input	[12:0]	ram_write_addr ,	//Address for track RAM
   input	[ 7:0]	ram_di,				//Data to track RAM
   input				ram_we				//RAM write enable
);

reg	[ 3:0]motor_phase;
reg			drive_on;
reg			drive2_select;
//reg			q6, q7;

wire	[ 7:0]rom_dout;

//	Current phase of the head.  This is in half-steps to assign
//	a unique position to the case, say, when both phase 0 and phase 1 are
//	on simultaneously.  phase(7 downto 2) is the track number
reg	[ 7:0]phase;		//0 - 139

//	Storage for one track worth of data in "nibblized" form
//Double-ported RAM for holding a track
wire	[ 7:0]ram_do;
//  -- Dual-ported RAM holding the contents of the track
disk_II_ram track_memory(
	.clock(clk),
	.wraddress(ram_write_addr),
	.wren(ram_we),
	.data(ram_di),
	.rdaddress(track_byte_addr),
	.rden(byte_clk),
	.q(ram_do)
	);

//  -- Lower bit indicates whether disk data is "valid" or not
//  -- RAM address is track_byte_addr(14 downto 1)
//  -- This makes it look to the software like new data is constantly
//  -- being read into the shift register, which indicates the data is
//  -- not yet ready.

always @(posedge clk or posedge RESET)
	if(RESET)begin
		motor_phase <= 0;
      drive_on <= 0;
      drive2_select <= 0;
      //q6 <= 0;
      //q7 <= 0;
	end else
		if(io_on)begin
			if(!A[3])motor_phase[A[2:1]] <= A[0];		//-- C0X0 - C0X7
			else
				case(A[2:1])
				'b00: drive_on <= A[0];						//-- C0X8 - C0X9
            'b01: drive2_select <= A[0];				//-- C0XA - C0XB
            //'b10: q6 <= A[0];								//-- C0XC - C0XD
            //'b11:	q7 <= A[0];								//-- C0XE - C0XF
				endcase
		end

//assign D1_ACTIVE = ~drive2_select & drive_on;
//assign D2_ACTIVE =  drive2_select & drive_on;
assign nofdd = drive2_select;

//  -- There are two cases:
//  --
//  --  Current phase is odd (between two poles)
//  --        |
//  --        V
//  -- -3-2-1 0 1 2 3 
//  --  X   X   X   X
//  --  0   1   2   3
//  --
//  --
//  --  Current phase is even (under a pole)
//  --          |
//  --          V
//  -- -4-3-2-1 0 1 2 3 4
//  --  X   X   X   X   X
//  --  0   1   2   3   0
//  --

reg	[ 3:0] rel_phase;

always @(posedge clk)
	if(RESET)begin
		phase <= 8'd0;
		rel_phase <= 0;
	end else begin
      rel_phase = motor_phase;
		case(phase[2:1])
		'b00: rel_phase = {rel_phase[1:0],rel_phase[3:2]};
      'b01: rel_phase = {rel_phase[2:0],rel_phase[3]  };
      'b11: rel_phase = {rel_phase[0],  rel_phase[3:1]};
      endcase
		
		if(phase[0])
			case(rel_phase)
			'b0001: phase = 2   < phase ? phase - 8'd3 : 8'd0;
			'b0010: phase = 0   < phase ? phase - 8'd1 : 8'd0;
			'b0011: phase = 1   < phase ? phase - 8'd2 : 8'd0;
			'b0100: phase = 139 > phase ? phase + 8'd1 : 8'd139;
			'b0101: phase = 0   < phase ? phase - 8'd1 : 8'd0;
			'b0111: phase = 0   < phase ? phase - 8'd1 : 8'd0;
			'b1000: phase = 137 > phase ? phase + 8'd3 : 8'd139;
			'b1010: phase = 139 > phase ? phase + 8'd1 : 8'd139;
			'b1011: phase = 0   < phase ? phase - 8'd1 : 8'd0;
			endcase
		else case(rel_phase)
			'b00001: phase = 1   < phase ? phase - 8'd2 : 8'd0;
			'b00011: phase = 0   < phase ? phase - 8'd1 : 8'd0;
			'b00100: phase = 138 > phase ? phase + 8'd2 : 8'd139;
			'b00110: phase = 139 > phase ? phase + 8'd1 : 8'd139;
			'b01001: phase = 139 > phase ? phase + 8'd1 : 8'd139;
			'b01010: phase = 138 > phase ? phase + 8'd2 : 8'd139;
			'b01011: phase = 1   < phase ? phase - 8'd2 : 8'd0;
			endcase
	end
	
assign TRACK = phase[7:2];
//  -- Go to the next byte when the disk is accessed or if the counter times out

reg	[12:0]track_byte_addr;
wire			read_disk;		//When C0XC accessed

reg	[7:0] byte_delay;

reg [7:0] spin = 8'd1;//8'd31;
wire 		 byte_clk = spin[7]|read_disk;
wire		 spinrst = ~drive_on|RESET|byte_clk;

always @(posedge clkcpu or posedge spinrst) spin <= spinrst ? 8'd31 : spin + 8'd1; //spin <={spin[6:0],spin[7]};
	
always @(negedge byte_clk or negedge drive_on)
	if(!drive_on)track_byte_addr <= 13'd4559;
	else track_byte_addr = track_byte_addr == 13'd6655 ? 13'd0 : track_byte_addr + 13'd1;
	
disk_ii_rom rom_ii(
   .addr(A[7:0]),
   .clk(clk),
   .dout(rom_dout)
	);

assign read_disk 	= io_on && A[3:0] == 4'hC;		// -- C0XC
assign D_OUT		= rom_on ? rom_dout : ram_do;
assign track_addr = track_byte_addr;

endmodule
