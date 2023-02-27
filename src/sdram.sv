//
// sdram.v
//
// Static RAM controller implementation using SDRAM MT48LC16M16A2
//
// Copyright (c) 2015-2019 Sorgelig
//
// Some parts of SDRAM code used from project:
// http://hamsterworks.co.nz/mediawiki/index.php/Simple_SDRAM_Controller
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------
//
// v2.1 - Add universal 8/16 bit mode.
//

module sdram
(
   input             init,        // reset to initialize RAM, heigh is active
   input             clk,         // clock ~100MHz
	output				init_ok,		 // init memory ok
                                  //
                                  // SDRAM_* - signals to the MT48LC16M16 chip
   inout  reg [15:0] SDRAM_DQ,    // 16 bit bidirectional data bus
   output reg [12:0] SDRAM_A,     // 13 bit multiplexed address bus
   output reg        SDRAM_DQML,  // two byte masks
   output reg        SDRAM_DQMH,  // 
   output reg  [1:0] SDRAM_BA,    // two banks
   output            SDRAM_nCS,   // a single chip select
   output            SDRAM_nWE,   // write enable
   output            SDRAM_nRAS,  // row address select
   output            SDRAM_nCAS,  // columns address select
   output            SDRAM_CKE,   // clock enable

                                  //
   input      [23:0] addr,        // 24 bit address 
   output     [15:0] dout,        // data output to cpu
   input      [15:0] din,         // data input from cpu
   input             we,          // cpu requests write
	input		  [ 1:0] dqm,			 // dqm write only
   input             rd,          // cpu requests read
   output reg        ready,       // dout is valid. Ready to accept new read/write.
	
	input      [23:0] addrvga,     // 24 bit address
	output     [15:0] doutvga,     // data output to cpu
	input             rdvga,       // cpu requests read
	output reg        readyvga     // dout is valid. Ready to accept new read/write.
);

assign SDRAM_CKE  = 1;
assign SDRAM_nCS  = 0;
assign SDRAM_nRAS = command[2];
assign SDRAM_nCAS = command[1];
assign SDRAM_nWE  = command[0];


// no burst configured
localparam BURST_LENGTH        = 3'b011;   // 000=1, 001=2, 010=4, 011=8
localparam ACCESS_TYPE         = 1'b0;     // 0=sequential, 1=interleaved
localparam CAS_LATENCY         = 3'd2;     // 2 for < 100MHz, 3 for >100MHz
localparam OP_MODE             = 2'b00;    // only 00 (standard operation) allowed
localparam NO_WRITE_BURST      = 1'b1;     // 0= write burst enabled, 1=only single access write
localparam MODE                = {3'b000, NO_WRITE_BURST, OP_MODE, CAS_LATENCY, ACCESS_TYPE, BURST_LENGTH};

localparam sdram_startup_cycles= 14'd12100;// 100us, plus a little more, @ 100MHz //14'd6050;//50 mhz
localparam cycles_per_refresh  = 14'd780;  // (64000*100)/8192-1 Calc'd as (64ms @ 100MHz)/8192 rose //14'd390;// 50 mhz
localparam startup_refresh_max = 14'b11111111111111;

// SDRAM commands
wire [2:0] CMD_NOP             = 3'b111;
wire [2:0] CMD_ACTIVE          = 3'b011;
wire [2:0] CMD_READ            = 3'b101;
wire [2:0] CMD_WRITE           = 3'b100;
wire [2:0] CMD_PRECHARGE       = 3'b010;
wire [2:0] CMD_AUTO_REFRESH    = 3'b001;
wire [2:0] CMD_LOAD_MODE       = 3'b000;

reg [13:0] refresh_count = startup_refresh_max - sdram_startup_cycles;
reg [ 2:0] command;
reg [8:0] save_addr;

reg [15:0] data;
reg [15:0] datavga;
assign dout = data;
assign doutvga = datavga;

typedef enum
{
	STATE_STARTUP,
	STATE_OPEN_1, STATE_OPEN_2,
	STATE_IDLE,	  STATE_IDLE_1, STATE_IDLE_2, STATE_IDLE_3,
	STATE_IDLE_4, STATE_IDLE_5, STATE_IDLE_6, STATE_IDLE_7,
	
	STATE_IDLE_8, STATE_IDLE_9, STATE_IDLE_10, STATE_IDLE_11,
	STATE_IDLE_12,STATE_IDLE_13,STATE_IDLE_14
} state_t;

always @(posedge clk) begin
	reg old_we, old_rd;
	reg old_rdvga;
	reg [CAS_LATENCY+7:0] data_ready_delay; // 8 burst read

	reg [15:0] new_data;
	reg  [1:0] new_dqm;
	reg        new_we;
	reg        new_rd;
	reg        new_rdvga;
	reg        save_we = 1;
	reg		  vga;
	
	reg  [1:0] new_dqmcpu;

	state_t state = STATE_STARTUP;

	SDRAM_DQ <= 16'bZ;
	command <= CMD_NOP;
	refresh_count  <= refresh_count+1'b1;

	data_ready_delay <= {1'b0, data_ready_delay[CAS_LATENCY+7:1]};
	
	if(|data_ready_delay[7:0])begin
		if(vga){readyvga, datavga} <= {1'b1, SDRAM_DQ};
		else 	 {ready, data}  		<= {1'b1, SDRAM_DQ};
	end else begin ready <= save_we; readyvga <= 0; end///!!!!!!!!!! not is right

	case(state)
		STATE_STARTUP: begin
			SDRAM_A    <= 0;
			SDRAM_BA   <= 0;

			if (refresh_count == startup_refresh_max-31) begin
				command     <= CMD_PRECHARGE;
				SDRAM_A[10] <= 1;  // all banks
				SDRAM_BA    <= 2'b00;
			end
			if (refresh_count == startup_refresh_max-23) begin
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-15) begin
				command     <= CMD_AUTO_REFRESH;
			end
			if (refresh_count == startup_refresh_max-7) begin
				command     <= CMD_LOAD_MODE;
				SDRAM_A     <= MODE;
			end

			if(!refresh_count) begin
				state   <= STATE_IDLE;
				refresh_count <= 0;
			end
		end

		STATE_IDLE_14: state <= STATE_IDLE_13;
		STATE_IDLE_13: state <= STATE_IDLE_12;
		STATE_IDLE_12: state <= STATE_IDLE_11;
		STATE_IDLE_11: state <= STATE_IDLE_10;
		STATE_IDLE_10: state <= STATE_IDLE_9;
		STATE_IDLE_9:  state <= STATE_IDLE_8;
		STATE_IDLE_8:  state <= STATE_IDLE_4;
		
		
		STATE_IDLE_7: begin
							state <= STATE_IDLE_6;
							{ready,readyvga,vga} <= 3'b000; //до снятия wr/rd
			end
		STATE_IDLE_6: state <= STATE_IDLE_5;
		STATE_IDLE_5: state <= STATE_IDLE_4;
		STATE_IDLE_4: state <= STATE_IDLE_3;
		STATE_IDLE_3: state <= STATE_IDLE_2;
		STATE_IDLE_2: begin state <= STATE_IDLE_1; if(save_we)ready <= 1; end // Set bit ready for save op.
		STATE_IDLE_1: begin
			state      <= STATE_IDLE;
			// mask possible refresh to reduce colliding.
			if(refresh_count > cycles_per_refresh) begin
				state    <= STATE_IDLE_7;
				command  <= CMD_AUTO_REFRESH;
				refresh_count <= 0;
			end
		end

		STATE_IDLE: begin
			// Priority is to issue a refresh if one is outstanding
			{SDRAM_DQMH,SDRAM_DQML} <= 2'b00;
			init_ok <= 1'b1;
			{ready,readyvga,vga} <= 3'b000; //до снятия wr/rd
			if(refresh_count > (cycles_per_refresh<<1)) state <= STATE_IDLE_1;
			else if(new_rdvga) begin
					new_rdvga <= 0;
					save_we	 <= 0;
					save_addr <= addrvga[8:0];
					state     <= STATE_OPEN_1;
					command   <= CMD_ACTIVE;
					SDRAM_A   <= addrvga[21:9];
					SDRAM_BA  <= addrvga[23:22];
					vga		 <= 1'b1;
					new_dqm	 <= 2'b00;
				end
				else if(new_rd | new_we) begin
					new_we    <= 0;
					new_rd    <= 0;
					save_addr <= addr[8:0];
					save_we   <= new_we;
					state     <= STATE_OPEN_1;
					command   <= CMD_ACTIVE;
					SDRAM_A   <= addr[21:9];
					SDRAM_BA  <= addr[23:22];
					vga		 <= 1'b0;
					new_dqm	 <= new_dqmcpu;
				end
		end

		STATE_OPEN_1: state <= STATE_OPEN_2;

		STATE_OPEN_2: begin
			SDRAM_A     <= {4'b0010, save_addr};
			if(save_we) begin
				command  <= CMD_WRITE;
				SDRAM_DQ <= new_data;
				{SDRAM_DQMH,SDRAM_DQML} <= new_dqm;
				//ready    <= 1;
				state    <= STATE_IDLE_2;
			end
			else begin
				command  <= CMD_READ;
				data_ready_delay[CAS_LATENCY+7] <= 1;
				state    <= STATE_IDLE_14;
			end
		end
	endcase

	if(init) begin
		state <= STATE_STARTUP;
		refresh_count <= startup_refresh_max - sdram_startup_cycles;
		init_ok <= 1'b0;
	end

	old_we <= we;
	if(we & ~old_we) begin
		{ready, new_we, new_data, new_dqmcpu} <= {1'b0, 1'b1, din, dqm};
	end

	old_rd <= rd;
	if(rd & ~old_rd) begin
		{ready, new_rd,new_dqmcpu} <= {1'b0, 1'b1, 2'b00};
	end
	
	old_rdvga <= rdvga;
	if(rdvga & ~old_rdvga) begin
		{readyvga, new_rdvga} <= {1'b0, 1'b1};
	end

end
endmodule