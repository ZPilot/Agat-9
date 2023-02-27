// megafunction wizard: %LPM_MUX%
// GENERATION: STANDARD
// VERSION: WM1.0
// MODULE: LPM_MUX 

// ============================================================
// File Name: cgvrcolor.v
// Megafunction Name(s):
// 			LPM_MUX
//
// Simulation Library Files(s):
// 			lpm
// ============================================================
// ************************************************************
// THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
//
// 20.1.1 Build 720 11/11/2020 SJ Standard Edition
// ************************************************************


//Copyright (C) 2020  Intel Corporation. All rights reserved.
//Your use of Intel Corporation's design tools, logic functions 
//and other software and tools, and any partner logic 
//functions, and any output files from any of the foregoing 
//(including device programming or simulation files), and any 
//associated documentation or information are expressly subject 
//to the terms and conditions of the Intel Program License 
//Subscription Agreement, the Intel Quartus Prime License Agreement,
//the Intel FPGA IP License Agreement, or other applicable license
//agreement, including, without limitation, that your use is for
//the sole purpose of programming logic devices manufactured by
//Intel and sold by Intel or its authorized distributors.  Please
//refer to the applicable agreement for further details, at
//https://fpgasoftware.intel.com/eula.


// synopsys translate_off
`timescale 1 ps / 1 ps
// synopsys translate_on
module cgvrcolor (
	clock,
	data0x,
	data1x,
	data2x,
	data3x,
	data4x,
	data5x,
	data6x,
	data7x,
	sel,
	result);

	input	  clock;
	input	[1:0]  data0x;
	input	[1:0]  data1x;
	input	[1:0]  data2x;
	input	[1:0]  data3x;
	input	[1:0]  data4x;
	input	[1:0]  data5x;
	input	[1:0]  data6x;
	input	[1:0]  data7x;
	input	[2:0]  sel;
	output	[1:0]  result;

	wire [1:0] sub_wire0;
	wire [1:0] sub_wire9 = data7x[1:0];
	wire [1:0] sub_wire8 = data6x[1:0];
	wire [1:0] sub_wire7 = data5x[1:0];
	wire [1:0] sub_wire6 = data4x[1:0];
	wire [1:0] sub_wire5 = data3x[1:0];
	wire [1:0] sub_wire4 = data2x[1:0];
	wire [1:0] sub_wire3 = data1x[1:0];
	wire [1:0] result = sub_wire0[1:0];
	wire [1:0] sub_wire1 = data0x[1:0];
	wire [15:0] sub_wire2 = {sub_wire9, sub_wire8, sub_wire7, sub_wire6, sub_wire5, sub_wire4, sub_wire3, sub_wire1};

	lpm_mux	LPM_MUX_component (
				.clock (clock),
				.data (sub_wire2),
				.sel (sel),
				.result (sub_wire0)
				// synopsys translate_off
				,
				.aclr (),
				.clken ()
				// synopsys translate_on
				);
	defparam
		LPM_MUX_component.lpm_pipeline = 1,
		LPM_MUX_component.lpm_size = 8,
		LPM_MUX_component.lpm_type = "LPM_MUX",
		LPM_MUX_component.lpm_width = 2,
		LPM_MUX_component.lpm_widths = 3;


endmodule

// ============================================================
// CNX file retrieval info
// ============================================================
// Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
// Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "0"
// Retrieval info: PRIVATE: new_diagram STRING "1"
// Retrieval info: LIBRARY: lpm lpm.lpm_components.all
// Retrieval info: CONSTANT: LPM_PIPELINE NUMERIC "1"
// Retrieval info: CONSTANT: LPM_SIZE NUMERIC "8"
// Retrieval info: CONSTANT: LPM_TYPE STRING "LPM_MUX"
// Retrieval info: CONSTANT: LPM_WIDTH NUMERIC "2"
// Retrieval info: CONSTANT: LPM_WIDTHS NUMERIC "3"
// Retrieval info: USED_PORT: clock 0 0 0 0 INPUT NODEFVAL "clock"
// Retrieval info: USED_PORT: data0x 0 0 2 0 INPUT NODEFVAL "data0x[1..0]"
// Retrieval info: USED_PORT: data1x 0 0 2 0 INPUT NODEFVAL "data1x[1..0]"
// Retrieval info: USED_PORT: data2x 0 0 2 0 INPUT NODEFVAL "data2x[1..0]"
// Retrieval info: USED_PORT: data3x 0 0 2 0 INPUT NODEFVAL "data3x[1..0]"
// Retrieval info: USED_PORT: data4x 0 0 2 0 INPUT NODEFVAL "data4x[1..0]"
// Retrieval info: USED_PORT: data5x 0 0 2 0 INPUT NODEFVAL "data5x[1..0]"
// Retrieval info: USED_PORT: data6x 0 0 2 0 INPUT NODEFVAL "data6x[1..0]"
// Retrieval info: USED_PORT: data7x 0 0 2 0 INPUT NODEFVAL "data7x[1..0]"
// Retrieval info: USED_PORT: result 0 0 2 0 OUTPUT NODEFVAL "result[1..0]"
// Retrieval info: USED_PORT: sel 0 0 3 0 INPUT NODEFVAL "sel[2..0]"
// Retrieval info: CONNECT: @clock 0 0 0 0 clock 0 0 0 0
// Retrieval info: CONNECT: @data 0 0 2 0 data0x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 2 data1x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 4 data2x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 6 data3x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 8 data4x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 10 data5x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 12 data6x 0 0 2 0
// Retrieval info: CONNECT: @data 0 0 2 14 data7x 0 0 2 0
// Retrieval info: CONNECT: @sel 0 0 3 0 sel 0 0 3 0
// Retrieval info: CONNECT: result 0 0 2 0 @result 0 0 2 0
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor.v TRUE
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor.inc FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor.cmp FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor.bsf FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor_inst.v FALSE
// Retrieval info: GEN_FILE: TYPE_NORMAL cgvrcolor_bb.v FALSE
// Retrieval info: LIB_FILE: lpm
