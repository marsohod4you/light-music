`timescale 1ns / 1ps

module tb_leds;

reg clk=0;
always
	begin
	#5; clk = ~clk;
	end

reg key;
wire w_data;

colors colors_inst(
    .clk( clk ),
	.button( key ),
    .data( w_data )
    );
	
initial
begin
	$dumpfile("out.vcd");
	$dumpvars(0,tb_leds);
	key = 1'b0;
	#100;
	@(posedge clk); #0;
	key = 1'b1;
	
	#50000;
	$finish();
end
	
endmodule

