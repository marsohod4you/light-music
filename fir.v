`timescale 1ns/1ps

module fir(
		input wire nreset,
		input wire fir_clk,
		input wire signed [15:0]idata,
		output wire signed [15:0]odata
	);

reg [1:0]clk_div;
always @(posedge fir_clk or negedge nreset)
	if( ~nreset )
		clk_div <= 0;
	else
		clk_div <= clk_div + 1;

wire clk_pwm; assign clk_pwm = fir_clk;
wire clk; assign clk = clk_div[1];

reg  [8:0]rd_addr;
wire [8:0]rd_addr_coeff;
reg  [8:0]wr_addr;

//read samples from cyclic buffer
always @(posedge clk or negedge nreset)
	if( ~nreset )
		rd_addr <= 0;
	else
		rd_addr <= rd_addr + 1;

//write (catch) new audio sample to cyclic buffer
reg wr;
//delayed wr
reg wr_; 
always @(posedge clk or negedge nreset)
	if( ~nreset )
	begin
		wr <= 1'b0;
		wr_ <= 1'b0;
	end
	else
	begin
		wr_ <= wr;
		wr <= (rd_addr==9'h1ff);
	end

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

//low-pass filter coefficients
wire signed [15:0]coeff_lp;
assign rd_addr_coeff = 512 - rd_addr + wr_addr;
dp_mem_1clk_p #( .DATA_WIDTH(16), .ADDR_WIDTH(9), .RAM_DEPTH(1 << 9) )mem_lp_coeff
	(
	.Clk( clk ),
	.Reset_N( nreset ),
	.we( 1'b0 ),
	.rd( nreset ),
	.wr_addr( 9'd0 ),
	.rd_addr( rd_addr_coeff ),
	.data_in( 16'd0 ),
	.data_out( coeff_lp )
	);

reg signed [31:0]filter_lp;
wire [31:0]filter_lp_positive; assign filter_lp_positive = filter_lp<0 ? (48'h0-filter_lp) : filter_lp;
reg signed [31:0]filter_lp_acc;
always @(posedge clk or negedge nreset)
	if( ~nreset )
	begin
		filter_lp <= 0;
		filter_lp_acc <=0;
	end
	else
	if( wr )
	begin
		filter_lp <= filter_lp_acc;
		filter_lp_acc <= coeff_lp * odata;
	end
	else
	begin
		filter_lp_acc <= filter_lp_acc + coeff_lp * odata;
	end
	
//convert signed wave into unsigned

//PWM partial register
reg [10:0]pwm;
reg [10:0]pwm_cnt;
always @( posedge clk or negedge nreset )
	if( ~nreset )
		pwm <= 0;
	else
	if( wr_ )
	begin
		pwm <= filter_lp_positive >> 20;
	end

reg pwm_out;
always @( posedge clk_pwm or negedge nreset )
	if( ~nreset )
	begin
		pwm_cnt <= 0;
		pwm_out <= 1'b0;
	end
	else
	begin
		pwm_cnt <= pwm_cnt+1;
		pwm_out <= (pwm_cnt<pwm);
	end	
	
endmodule
