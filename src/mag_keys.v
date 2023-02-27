module mag_keys(
	clk50,
	n_rst,
	
	read_key,
	clr_key,
	rus_lat,
	prnscr,
	code_key,
	
	reset_key,
	
	disk,
	sel_disk_a0, sel_disk_a1,
	sel_disk_b0, sel_disk_b1,
	
	PS2_CLK,
	PS2_DAT
	
);
input  clk50;
input  n_rst;

input  read_key;
input  clr_key;
output rus_lat = scrlock;
output prnscr;
output [7:0]code_key = read_key ? outcode : 8'd0;

output reset_key;
output [1:0] disk;
output [7:0] sel_disk_a0 = disk_nom[0];
output [7:0] sel_disk_a1 = disk_nom[1];
output [7:0] sel_disk_b0 = disk_nom[2];
output [7:0] sel_disk_b1 = disk_nom[3];
	
inout	 PS2_CLK;
inout  PS2_DAT;

//--------------------------------------------------------
//
//--------------------------------------------------------
wire [7:0]received_data;
wire received_data_en;

reg [ 7:0]the_command = 0;
reg send_command = 0;
wire command_was_sent;
wire error_communication_timed_out;

altera_up_ps2 ps2(
	// Inputs
	.clk(clk50),
	.reset(~n_rst),

	.the_command(the_command),
	.send_command(send_command),

	// Bidirectionals
	.PS2_CLK(PS2_CLK),					// PS2 Clock
 	.PS2_DAT(PS2_DAT),					// PS2 Data

	// Outputs
	.command_was_sent(command_was_sent),
	.error_communication_timed_out(error_communication_timed_out),

	.received_data(received_data),
	.received_data_en(received_data_en)	// If 1 - new data has been received
);
wire empty;
wire full;

reg [9:0]keycode;
reg upkey = 1'b0;
reg append_key = 0;
reg shift = 0, rshift = 0 ,caps = 0, numlock = 0;
reg [2:0]skipcode = 0;
reg brk = 0 , prnscr = 0, scrlock = 0;
reg ctrl = 0, rctrl = 0;
reg reset_key = 0;

reg [1:0]disk = 0;
reg [7:0]disk_nom[0:3];

always @(posedge received_data_en or negedge n_rst)
	if(!n_rst)begin
		upkey <= 1'b0;
		append_key <= 0;
		{shift,rshift,numlock,ctrl, rctrl,disk} <= 0;
		skipcode <= 0;
		{brk,prnscr,scrlock,caps,reset_key} <= 0;
	end else if(skipcode)skipcode <= skipcode - 1'b1;
		 else begin
			keycode[9:8] <= 2'b00;
			case(received_data)
			'hf0: upkey <= 1'b1;	// key up
			'he0: append_key <= 1'b1;	// appent key
			'he1: begin skipcode <= 3'b111; brk <=~brk; end	//Start Pause/Brk
			'h12: begin shift    <= ~upkey; append_key <= 1'b0; upkey <= 1'b0; end	//LShift
			'h59: begin rshift   <= ~upkey; upkey <= 1'b0; end	//RShift
			'h14: begin if(append_key) rctrl <= ~upkey; else ctrl <= ~upkey; append_key <= 1'b0; upkey <= 1'b0; end // LCtrl/RCtrl
			'h58: if(!upkey) caps    <= ~caps;    else upkey <= 1'b0; 	//capsLock
			'h77: if(!upkey) numlock <= ~numlock; else upkey <= 1'b0; 	//numlock 
			'h7e: if(!upkey) scrlock <= ~scrlock; else upkey <= 1'b0; 	//ScrLock  (rus/lat)
			'h7c: if(append_key) begin prnscr <= ~upkey; append_key <= 1'b0; upkey <= 1'b0; end //Print Screen
					else begin keycode <= {append_key,~(upkey|brk),received_data}; upkey = 1'b0; end	// *
			'h07: begin reset_key <= ~upkey; upkey <= 1'b0; end //	F12 => reset Agat
			'hfa: ;//ask keyboard? not use this
			default: if(!brk)begin keycode <= {append_key,~upkey,received_data}; upkey <= 1'b0; append_key <= 1'b0; end // any keys
						else begin
							case({upkey,append_key,received_data})
							'b0_0_00010110: disk <= 2'b00; // kcode 16 ("1")
							'b0_0_00011110: disk <= 2'b01; // kcode 1E ("2")
							'b0_0_00100110: disk <= 2'b10; // kcode 26 ("3")
							'b0_0_00100101: disk <= 2'b11; // kcode 25 ("4")
							
							'b0_1_01110101: disk_nom[disk] <= disk_nom[disk] + 1'b1; // kcode E075 ("up")
							'b0_1_01110010: disk_nom[disk] <= disk_nom[disk] - 1'b1; // kcode E072 ("down")
							default: ;
							endcase
							upkey <= 1'b0; append_key <= 1'b0;
						end
			endcase
		end

reg scrlock_old = 0, caps_old = 0, numlock_old = 0;
reg [1:0] count_set = 0;

always @(posedge clk50 or negedge n_rst)
	if(!n_rst){count_set,scrlock_old,caps_old,numlock_old} = 0;
	else
		case(count_set)
		'b00: if(scrlock != scrlock_old || caps_old!=caps || numlock_old!=numlock)begin the_command <= 8'hED; send_command <= 1'b1; count_set <= 'b01; end
		'b01: begin 
					if(command_was_sent) send_command <= 1'b0;
					if(received_data == 'hFA || received_data == 'hFE) count_set <= 'b10;
				end
		'b10: if(!command_was_sent)begin the_command <= {5'b00000,caps,numlock,scrlock}; send_command <= 1'b1; count_set <= 'b11; end
		'b11: if( command_was_sent)begin send_command <= 1'b0; count_set <= 'b00; scrlock_old <= scrlock; caps_old <= caps; numlock_old <= numlock; end
		endcase

wire [7:0] code_agat;
kcode kcd(
	.clk50(clk50),
	.en(keycode[8]),
	.code_ps2({keycode[9] ? 8'he0:8'h00,keycode[7:0]}),
	.ctrl(ctrl|rctrl),
	.shift(shift|rshift),
	.ruslat(rus_lat),
	.code_agat(code_agat)
);
//Буфер клавиатуры

wire [ 7:0]outcode;
wire key_ok = |code_agat;
mring_fifo mff1(
	.wrreq(~(received_data_en|full) & keycode[8] & key_ok),
	.data(code_agat),
	
	.rdreq(~empty & clr_key),
	.kcode(outcode),
	
	.bfull(full),
	.bempty(empty)
);

//Это тоже работает, но без буфера
/*wire key_ok = |code_agat;
wire kwr = ~received_data_en & keycode[8] & key_ok;
reg [ 7:0]outcode = 8'd0;

always @(posedge kwr or posedge clr_key)
	if(clr_key)outcode[7] <= 1'b0;
	else outcode <= code_agat;*/

endmodule
