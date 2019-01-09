
module clocker(
	input wire clk96M,
	output reg clk2_4M,
	output wire clk24M
);

reg [1:0]cnt0;
always @( posedge clk96M )
	cnt0 <= cnt0+1;
assign clk24M = cnt0[1];

reg [7:0]cnt1;
always @( posedge clk96M )
begin
	if( cnt1==39)
		cnt1 <= 0;
	else
		cnt1 <= cnt1+1;
	clk2_4M <= (cnt1==39);
end

endmodule
