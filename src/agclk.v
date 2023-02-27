module agclk(
	clk,
	n_reset,
	
	ask,
	
	phi_0, phi_1, phi_2
);
input clk;
input n_reset;
input ask;

output reg phi_0 = 1'b1, phi_1 = 0, phi_2 = 1'b1;

reg [3:0]clkstep = 0;
always @(posedge clk)
	if(!n_reset)begin
		{phi_0, phi_1, phi_2} <= 3'b101;
		clkstep <=0;
	end else
		case(clkstep)
		//'d0: clkstep <= {3'b000,ask};
		'd0: begin if(ask)clkstep <= 'd2; phi_0 <= 1'b0; end
		//'d1: clkstep <= 'd2;
		'd2: begin clkstep <= 'd3; phi_2 <= 1'b0; end
		'd3: begin clkstep <= 'd4; phi_1 <= 1'b1; end
		'd4: clkstep <= 'd5;
		'd5: clkstep <= 'd7;
		'd7: begin clkstep <= 'd8; phi_0 <= 1'b1; end
		'd8: begin clkstep <= 'd9; phi_1 <= 1'b0; end
		'd9: begin clkstep <='d10; phi_2 <= 1'b1; end
		'd10:clkstep <= 'd0;
		endcase

endmodule



module clk_div(input clk, output clk1);
parameter divide = 16;

integer count = divide;
reg clksys = 0;
assign clk1 = !divide ? clk : clksys;

always @(posedge clk)
	case(divide)
	0: clksys <= 0;
	1: clksys <= ~clksys;
	default:
		if(!count)begin count <= divide; clksys <= ~clksys; end
		else count <= count - 1;
	endcase
endmodule