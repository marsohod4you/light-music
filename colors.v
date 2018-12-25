
module colors(
    input clk,
	 input button,
    output data
    );

wire [15:0]w_num;
wire w_req;
wire w_sync;

reg [23:0]rgb = 0;

always @(posedge clk )
	if( w_req )
		if( button )
			rgb <= w_sync ? 0 : { {6{w_num[2]}}, 2'b00, {6{w_num[1]}}, 2'b00, {6{w_num[0]}}, 2'b00 };
		else
			rgb <= 0;

LED_tape #( .NUM_LEDS(160), .NUM_RESET_LEDS(10) ) uut(
    .clk( clk ),
    .RGB( rgb ) ,
    .data( data ),
    .num( w_num ),
	 .sync( w_sync ),
    .req( w_req )
    );
	 
endmodule
