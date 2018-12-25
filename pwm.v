
module pwm(
	input wire nreset,
	input wire clk_pwm,
	input wire signed [47:0]data,
	input wire data_ready,
	output wire [7:0]color,
	output reg out
);

//not all 48 bits from source are important
//cut only neccessary bits range
parameter RANGE_H = 28;
localparam NUM_BITS = 11;

//data and data_ready may be in other clock domain, but they are slow relative to clk_pwm
reg [2:0]rdy;
reg rdy_r;
always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
	begin
		rdy <= 0;
		rdy_r <= 1'b0;
	end
	else
	begin
		rdy <= { rdy[1:0], data_ready };
		rdy_r <= (rdy[2:1]==2'b01);
	end

//convert signed wave into positive/unsigned/streightened
wire [47:0]pdata; assign pdata = data<0 ? (48'h0-data) : data;
reg [NUM_BITS-1:0]usefull;
always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
		usefull <= 0;
	else
	if( rdy_r )
		usefull <= pdata[RANGE_H:RANGE_H-NUM_BITS];

assign color = { 2'b00, usefull[NUM_BITS-1:NUM_BITS-6] };

reg [NUM_BITS-1:0]counter;
always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
		counter <= 0;
	else
	if( rdy_r )
		counter <= 0;
	else
		counter <= counter + 1;

always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
		out <= 0;
	else
		out <= usefull>counter;

endmodule
