
module colorsRGB(
    input clk,
	 input wire [7:0]clr_red,
	 input wire [7:0]clr_green,
	 input wire [7:0]clr_blue,
	 output data
    );

wire [15:0]w_num;
wire w_req;
wire w_sync;

wire [7:0]red;
wire [7:0]green;
wire [7:0]blue;
mod_bit_reverse #(.NUM_BITS(8)) my_reverse_module1( .in(clr_red),   .out(red) );
mod_bit_reverse #(.NUM_BITS(8)) my_reverse_module2( .in(clr_green), .out(green) );
mod_bit_reverse #(.NUM_BITS(8)) my_reverse_module3( .in(clr_blue),  .out(blue) );

wire [23:0]next_rgb;
assign next_rgb = 
	w_num<85  ? { blue,  8'h00, 8'h00 } :
	w_num<190 ? { 8'h00, red,   8'h00 } :
					{ 8'h00, 8'h00, green } ;

reg  [23:0]rgb = 0;
always @(posedge clk )
	if( w_req )
	begin
			rgb <= w_sync ? 0 : next_rgb;
	end

LED_tape #( .NUM_LEDS(256), .NUM_RESET_LEDS(10) ) uut(
    .clk( clk ),
    .RGB( rgb ) ,
    .data( data ),
    .num( w_num ),
	 .sync( w_sync ),
    .req( w_req )
    );
	 
endmodule

module mod_bit_reverse( in, out );
parameter NUM_BITS = 16;
input wire [NUM_BITS-1:0]in;
output wire [NUM_BITS-1:0]out;
genvar i;
generate
  for(i=0; i<NUM_BITS; i=i+1)
  begin : x
    assign out[NUM_BITS-1-i] = in[i];
  end
endgenerate
endmodule
