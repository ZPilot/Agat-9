module kcode(
	clk50,
	en,
	code_ps2,
	ctrl,
	shift,
	ruslat,
	code_agat
);
input  clk50;
input  en;
input  [15:0]code_ps2;
input  ctrl;
input  shift;
input  ruslat;
output [ 7:0]code_agat;

reg [ 7:0]code_agat = 0;

integer index;

always @(posedge clk50)
	if(en)begin
	for(index = 0; index < 73; index = index + 1) begin
		if(kcode[index][63:48]==code_ps2)
			case({ruslat,shift,ctrl})
			'b0_00: code_agat <= kcode[index][47:40];	// key
			'b0_01: code_agat <= kcode[index][39:32];	// key + ctrl
			'b0_10: code_agat <= kcode[index][31:24];	// key +shift
			
			'b1_00: code_agat <= kcode[index][23:16];	// key
			'b1_01: code_agat <= kcode[index][15: 8];	// key + ctrl
			'b1_10: code_agat <= kcode[index][ 7: 0];	// key +shift
			default: code_agat <= 0;
			endcase
		end
	end

reg [63:0]kcode[0:72];
initial begin
kcode[ 0] = {16'h006c, /* +KP_Home */		 8'h90,8'h90,8'h90, 8'h90,8'h90,8'h90};
kcode[ 1] = {16'h0075, /* +KP_Up */			 8'h91,8'h91,8'h91, 8'h91,8'h91,8'h91};
kcode[ 2] = {16'h007d, /* +KP_Prior */		 8'h92,8'h92,8'h92, 8'h92,8'h92,8'h92};
kcode[ 3] = {16'h006b, /* +KP_Left */		 8'h93,8'h93,8'h93, 8'h93,8'h93,8'h93};
kcode[ 4] = {16'h0073, /* +KP_Begin */		 8'h94,8'h94,8'h94, 8'h94,8'h94,8'h94};
kcode[ 5] = {16'h0074, /* +KP_Right */		 8'h9c,8'h9c,8'h9c, 8'h9c,8'h9c,8'h9c};
kcode[ 6] = {16'h0069, /* +KP_End */		 8'h9d,8'h9d,8'h9d, 8'h9d,8'h9d,8'h9d};
kcode[ 7] = {16'h0072, /* +KP_Down */		 8'h9e,8'h9e,8'h9e, 8'h9e,8'h9e,8'h9e};
kcode[ 8] = {16'h007a, /* +KP_Next */		 8'h9f,8'h9f,8'h9f, 8'h9f,8'h9f,8'h9f};
kcode[ 9] = {16'h0070, /* +KP_Insert */	 8'h81,8'h81,8'h81, 8'h81,8'h81,8'h81};
kcode[10] = {16'h0071, /* +KP_Delete */	 8'h82,8'h82,8'h82, 8'h82,8'h82,8'h82};
kcode[11] = {16'he05a, /* +KP_Enter */		 8'h83,8'h83,8'h83, 8'h83,8'h83,8'h83};
kcode[12] = {16'he070, /* +Insert */		 8'h81,8'h81,8'h81, 8'h81,8'h81,8'h81};
kcode[13] = {16'he06c, /* +Home */			 8'h82,8'h82,8'h82, 8'h82,8'h82,8'h82};
kcode[14] = {16'he07d, /* +Prior */			 8'h83,8'h83,8'h83, 8'h83,8'h83,8'h83};
kcode[15] = {16'he071, /* +Delete */		 8'h84,8'h84,8'h84, 8'h84,8'h84,8'h84};
kcode[16] = {16'he069, /* +End */			 8'h85,8'h85,8'h85, 8'h85,8'h85,8'h85};
kcode[17] = {16'he07a, /* +Next */			 8'h86,8'h86,8'h86, 8'h86,8'h86,8'h86};
kcode[18] = {16'he075, /* +Up */				 8'h99,8'h99,8'h99, 8'h99,8'h99,8'h99};
kcode[19] = {16'he072, /* +Down */			 8'h9a,8'h9a,8'h9a, 8'h9a,8'h9a,8'h9a};
kcode[20] = {16'he06b, /* +Left */			 8'h88,8'h88,8'h88, 8'h88,8'h88,8'h88};
kcode[21] = {16'he074, /* +Right */			 8'h95,8'h95,8'h95, 8'h95,8'h95,8'h95};
kcode[22] = {16'h0066, /* +BackSpace */	 8'h88,8'h88,8'h88, 8'h88,8'h88,8'h88};
kcode[23] = {16'h0076, /* +Escape */		 8'h9b,8'h9b,8'h9b, 8'h9b,8'h9b,8'h9b};
kcode[24] = {16'h005a, /* +Return */		 8'h8d,8'h8d,8'h8d, 8'h8d,8'h8d,8'h8d};
kcode[25] = {16'h0029, /* +space */			 8'ha0,8'ha0,8'ha0, 8'ha0,8'ha0,8'ha0};
kcode[26] = {16'h000e, /* +grave */			 8'hbb,8'h00,8'hab, 8'hbb,8'h00,8'hab};

kcode[27] = {16'h0016, /* +1 */				 8'hb1,8'h00,8'ha1, 8'hb1,8'h00,8'ha1};
kcode[28] = {16'h001e, /* +2 */				 8'hb2,8'h80,8'ha2, 8'hb2,8'h80,8'ha2};
kcode[29] = {16'h0026, /* +3 */				 8'hb3,8'h00,8'ha3, 8'hb3,8'h00,8'ha3};
kcode[30] = {16'h0025, /* +4 */				 8'hb4,8'h00,8'ha4, 8'hb4,8'h00,8'ha4};
kcode[31] = {16'h002e, /* +5 */				 8'hb5,8'h00,8'ha5, 8'hb5,8'h00,8'ha5};
kcode[32] = {16'h0036, /* +6 */				 8'hb6,8'h9e,8'hde, 8'hb6,8'h9e,8'hde};
kcode[33] = {16'h003d, /* +7 */				 8'hb7,8'h00,8'ha6, 8'hb7,8'h00,8'ha6};
kcode[34] = {16'h003e, /* +8 */				 8'hb8,8'h00,8'haa, 8'hb8,8'h00,8'haa};
kcode[35] = {16'h0046, /* +9 */				 8'hb9,8'h00,8'ha8, 8'hb9,8'h00,8'ha8};
kcode[36] = {16'h0045, /* +0 */				 8'hb0,8'h00,8'ha9, 8'hb0,8'h00,8'ha9};
kcode[37] = {16'h004e, /* +minus */			 8'had,8'h9f,8'hdf, 8'had,8'h9f,8'hdf};
kcode[38] = {16'h0055, /* +equal */			 8'hbd,8'h00,8'hab, 8'hbd,8'h00,8'hab};
kcode[39] = {16'h005d, /* +backslash */	 8'hdc,8'h9c,8'hfc, 8'hdc,8'h9c,8'hfc};

kcode[40] = {16'h001c, /* +a */				 8'hc1,8'h81,8'he1, 8'hc6,8'h81,8'he6};
kcode[41] = {16'h0032, /* +b */				 8'hc2,8'h82,8'he2, 8'hc9,8'h82,8'he9};
kcode[42] = {16'h0021, /* +c */				 8'hc3,8'h83,8'he3, 8'hd3,8'h83,8'hf3};
kcode[43] = {16'h0023, /* +d */				 8'hc4,8'h84,8'he4, 8'hd7,8'h84,8'hf7};
kcode[44] = {16'h0024, /* +e */				 8'hc5,8'h85,8'he5, 8'hd5,8'h85,8'hf5};
kcode[45] = {16'h002b, /* +f */				 8'hc6,8'h86,8'he6, 8'hc1,8'h86,8'he1};
kcode[46] = {16'h0034, /* +g */				 8'hc7,8'h87,8'he7, 8'hd0,8'h87,8'hf0};
kcode[47] = {16'h0033, /* +h */				 8'hc8,8'h88,8'he8, 8'hd2,8'h88,8'hf2};
kcode[48] = {16'h0043, /* +i */				 8'hc9,8'h89,8'he9, 8'hdb,8'h89,8'hfb};
kcode[49] = {16'h003b, /* +j */				 8'hca,8'h8a,8'hea, 8'hcf,8'h8a,8'hef};
kcode[50] = {16'h0042, /* +k */				 8'hcb,8'h8b,8'heb, 8'hcc,8'h8b,8'hec};
kcode[51] = {16'h004b, /* +l */				 8'hcc,8'h8c,8'hec, 8'hc4,8'h8c,8'he4};
kcode[52] = {16'h003a, /* +m */				 8'hcd,8'h8d,8'hed, 8'hd8,8'h8d,8'hf8};
kcode[53] = {16'h0031, /* +n */				 8'hce,8'h8e,8'hee, 8'hd4,8'h8e,8'hf4};
kcode[54] = {16'h0044, /* +o */				 8'hcf,8'h8f,8'hef, 8'hdd,8'h8f,8'hfd};
kcode[55] = {16'h004d, /* +p */				 8'hd0,8'h90,8'hf0, 8'hda,8'h90,8'hfa};
kcode[56] = {16'h0015, /* +q */				 8'hd1,8'h91,8'hf1, 8'hca,8'h91,8'hea};
kcode[57] = {16'h002d, /* +r */				 8'hd2,8'h92,8'hf2, 8'hcb,8'h92,8'heb};
kcode[58] = {16'h001b, /* +s */				 8'hd3,8'h93,8'hf3, 8'hd9,8'h93,8'hf9};
kcode[59] = {16'h002c, /* +t */				 8'hd4,8'h94,8'hf4, 8'hc5,8'h94,8'he5};
kcode[60] = {16'h003c, /* +u */				 8'hd5,8'h95,8'hf5, 8'hc7,8'h95,8'he7};
kcode[61] = {16'h002a, /* +v */				 8'hd6,8'h96,8'hf6, 8'hcd,8'h96,8'hed};
kcode[62] = {16'h001d, /* +w */				 8'hd7,8'h97,8'hf7, 8'hc3,8'h97,8'he3};
kcode[63] = {16'h0022, /* +x */				 8'hd8,8'h98,8'hf8, 8'hde,8'h98,8'hfe};
kcode[64] = {16'h0035, /* +y */				 8'hd9,8'h99,8'hf9, 8'hce,8'h99,8'hee};
kcode[65] = {16'h001a, /* +z */				 8'hda,8'h9a,8'hfa, 8'hd1,8'h9a,8'hf1};

kcode[66] = {16'h0054, /* +bracketleft */	 8'hdb,8'h9b,8'hfb, 8'hc8,8'h9b,8'he8};
kcode[67] = {16'h005b, /* +bracketright */ 8'hdd,8'h9d,8'hfd, 8'hdf,8'h9d,8'hff};

kcode[68] = {16'h0041, /* +comma */			 8'hac,8'h00,8'hbc, 8'hc2,8'h00,8'he2};
kcode[69] = {16'h0049, /* +period */		 8'hae,8'h00,8'hbe, 8'hc0,8'h00,8'he0};
kcode[70] = {16'h004a, /* +slash */			 8'haf,8'h00,8'hbf, 8'haf,8'h00,8'hbf};
kcode[71] = {16'h004c, /* +semicolon */	 8'hbb,8'h00,8'hba, 8'hd6,8'h00,8'hf6};
kcode[72] = {16'h0052, /* +apostrophe */	 8'ha7,8'h00,8'ha2, 8'hdc,8'h00,8'hfc};
end

endmodule
