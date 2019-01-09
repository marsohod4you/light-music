
module div4(
	input wire clk,
	output wire out_clk
);

reg [1:0]cnt=0;
always @( posedge clk )
	cnt <= cnt+1;
	
assign out_clk = cnt[1];

endmodule
