module mring_fifo(
	wrreq,
	data,
	
	rdreq,
	kcode,
	
	bfull,
	bempty
);
input  wrreq;
input  [7:0]data;

input  rdreq;
output [7:0]kcode;

output bfull;
output bempty;


reg  [7:0]bfifo[0:7];
reg  [2:0]start = 0;
reg  [2:0]stop = 0;

assign bfull =  stop == (start-1);
assign bempty = stop == start;
assign kcode = bfifo[start];

always @(posedge wrreq)
	if(!bfull)begin bfifo[stop] = data; stop = stop + 1'b1; bfifo[stop] = 8'd0; end
	
always @(posedge rdreq)
	if(!bempty)begin start <= start + 1'b1; end

endmodule
