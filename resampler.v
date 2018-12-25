
module resampler(
	input wire nreset,
	input wire adc_clk,
	input wire clk,		//clock 512 higher then adc_clock
	input wire signed [47:0]data,
	output wire out_clk,
	output reg [11:0]out
);

parameter RANGE_H = 28;

//make new clock 16 times less then existing adc clock
reg [3:0]cnt0;
wire new_adc_clock; assign new_adc_clock = cnt0[3];
always @( posedge adc_clk or negedge nreset )
	if( ~nreset )
		cnt0 <= 0;
	else
		cnt0 <= cnt0 + 1;

always @( posedge new_adc_clock or negedge nreset )
	if( ~nreset )
		out <= 0;
	else
		out <= data[RANGE_H:RANGE_H-11]+12'h800;
			
reg [3:0]cnt1;
always @( posedge clk or negedge nreset )
	if( ~nreset )
		cnt1 <= 0;
	else
		cnt1 <= cnt1 + 1;		
assign out_clk = cnt1[3];

		
endmodule
