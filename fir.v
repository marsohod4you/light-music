`timescale 1ns/1ps

module fir_filter(
		input wire nreset,
		input wire clk,
		input wire clk_pwm,
		input wire start, //impulse shows new audio sample is written into cyclic buffer head
		input wire [8:0]wr_head, //pointer where new sample written
		input wire [8:0]idata_addr, //cyclic audio buffer addressed by 9 address bits, 512 entries
		input wire signed [15:0]idata, //data sample from cyclic audio buffer
		output reg signed [31:0]filter_val,
		output reg pwm_out
	);

//fir coefficients contiguously extracted from filter embeddef memory
wire [8:0]rd_addr_coeff; 
assign rd_addr_coeff = 512 - idata_addr + wr_head;
wire signed [15:0]fir_coeff;
dp_mem_1clk_p #( .DATA_WIDTH(16), .ADDR_WIDTH(9), .RAM_DEPTH(1 << 9) )mem_coeff
	(
	.Clk( clk ),
	.Reset_N( nreset ),
	.we( 1'b0 ),
	.rd( nreset ),
	.wr_addr( 9'd0 ),
	.rd_addr( rd_addr_coeff ),
	.data_in( 16'd0 ),
	.data_out( fir_coeff )
	);

reg signed [31:0]filter_val_acc;
always @(posedge clk or negedge nreset)
	if( ~nreset )
	begin
		filter_val <= 0;
		filter_val_acc <=0;
	end
	else
	if( start )
	begin
		filter_val <= filter_val_acc;
		filter_val_acc <= fir_coeff * idata;
	end
	else
	begin
		filter_val_acc <= filter_val_acc + fir_coeff * idata;
	end

//start delayed 1 clock
reg start_;
always @( posedge clk or negedge nreset )
	if( ~nreset )
		start_ <= 0;
	else
		start_ <= start;

//convert signed wave into unsigned/streightened
wire [31:0]filter_val_positive; assign filter_val_positive = filter_val<0 ? (48'h0-filter_val) : filter_val;
reg  [31:0]filter_val_positive_r;
always @( posedge clk or negedge nreset )
	if( ~nreset )
		filter_val_positive_r <= 0;
	else
		filter_val_positive_r <= filter_val_positive;

//PWM partial register
reg [10:0]pwm;
reg [10:0]pwm_cnt;
always @( posedge clk or negedge nreset )
	if( ~nreset )
		pwm <= 0;
	else
	if( start_ )
	begin
		pwm <= filter_val_positive >> 20;
	end

always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
	begin
		pwm_cnt <= 0;
		pwm_out <= 1'b0;
	end
	else
	begin
		pwm_cnt <= pwm_cnt+1;
		pwm_out <= (pwm>8) ? (pwm_cnt<pwm) : 0;
	end	
	
endmodule

module fir(
		input wire nreset,
		input wire clock,
		input wire signed [15:0]idata,
		output wire signed [15:0]odata
	);

reg [1:0]clk_div;
always @(posedge clock or negedge nreset)
	if( ~nreset )
		clk_div <= 0;
	else
		clk_div <= clk_div + 1;

wire clk_pwm; assign clk_pwm = clock;
wire clk; assign clk = clk_div[1];

reg  [8:0]rd_addr;
reg  [8:0]wr_addr;

//read samples from cyclic buffer
always @(posedge clk or negedge nreset)
	if( ~nreset )
		rd_addr <= 0;
	else
		rd_addr <= rd_addr + 1;

//write (catch) new audio sample to cyclic buffer
reg wr;
always @(posedge clk or negedge nreset)
	if( ~nreset )
		wr <= 1'b0;
	else
		wr <= (rd_addr==9'h1ff);

always @(posedge clk or negedge nreset)
	if( ~nreset )
		wr_addr <= 0;
	else
	if( rd_addr==9'h1ff )
		wr_addr <= wr_addr + 1;

dp_mem_1clk_p #( .DATA_WIDTH(16), .ADDR_WIDTH(9), .RAM_DEPTH(1 << 9) )mem_samples
	(
	.Clk( clk ),
	.Reset_N( nreset ),
	.we( wr ),
	.rd( nreset ),
	.wr_addr( wr_addr ),
	.rd_addr( rd_addr ),
	.data_in( idata ),
	.data_out( odata )
	);

wire [31:0]filter_val_lp;
wire pwm_out_lp;
fir_filter low_pass_filter(
		.nreset( nreset ),
		.clk( clk ),
		.clk_pwm( clk_pwm ),
		.start( wr ),
		.wr_head( wr_addr ),
		.idata_addr( rd_addr ),
		.idata( odata ),
		.filter_val( filter_val_lp ),
		.pwm_out( pwm_out_lp )
	);

endmodule
