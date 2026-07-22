`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/05/21
// Design Name: zcy
// Module Name: ssi_fifo_channel
// Project Name: XDMA_SSI
// Target Devices:
// Tool Versions:
// Description: 单通道SSI采集、状态生成、时基打包并写入128bit FIFO
//
// Dependencies: SSI_interface, fifo_128x16384
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module ssi_fifo_channel#(
	parameter				CLK_T				=	8,
							SIM_DATA_GEN		=	0,
	parameter	[3:0]		CH_ID				=	4'd0
	)(
	input					Clk,
	input					Rst,
	input					Sda,
	output					Scl,
	output					Cs_n,
	input		[7:0]		RX_SIZE,
	input					cs_en,
	input					data_acq_en,
	input		[2:0]		Scl_ctrl,
	input		[3:0]		data_status_bits,
	input					acq_stop_reset,
	output	reg				error,
	output	reg				warning,
	input					fifo_rd_en,
	output		[127:0]		fifo_rd_data,
	output					fifo_empty,
	output					fifo_full,
	output		[14:0]		fifo_rd_data_cnt,
	output					lost_frame_event
);

/*******************************************************************************
// 		复位同步
*******************************************************************************/
reg			[2:0]			rr_rst;
wire						r_rst;
wire						local_rst;

always@(posedge Clk)
	rr_rst <= {rr_rst[1:0],Rst};

assign	r_rst	= rr_rst[2];
assign	local_rst = r_rst | acq_stop_reset;

/*******************************************************************************
// 		SSI数据采集/测试数据源
// SIM_DATA_GEN = 1: 使用内部顺序数测试源，便于验证 DDR 数据连续性。
// SIM_DATA_GEN = 0: 使用真实 SSI_interface 输出数据。
*******************************************************************************/
wire		[63:0]			ssi_data;
reg		[7:0]			ssi_data_cnt;
wire						ssi_data_flag;

generate
	if(SIM_DATA_GEN)begin : sim_src_gen
		reg		[63:0]		sim_data_cnt;

		assign Scl				= 1'b1;
		assign Cs_n				= 1'b1;
		assign ssi_data			= {47'd0,sim_data_cnt[16:0]};
		assign ssi_data_flag	= data_acq_en && ssi_data_cnt == 31'd100;

		always@(posedge Clk)
			if(local_rst)begin
				ssi_data_cnt	<= 64'd0;
				sim_data_cnt	<= 64'd0;
			end else if(data_acq_en)begin
				sim_data_cnt	<= ssi_data_flag ? sim_data_cnt + 1'b1 : sim_data_cnt ;
				ssi_data_cnt	<= ssi_data_cnt + 1'b1;
			end
	end else begin : ssi_src_rx
		SSI_interface#(
				.CLK_T      (CLK_T					),
				.DATA_TIME	(20_000					)
			)SSI_interface_inst(
				.Phy_Clk    (Clk					),
				.Phy_Rst    (local_rst|(~data_acq_en)),
				.Scl_ctrl   (Scl_ctrl				),
				.RX_SIZE    (RX_SIZE				),
				.Ssclk      (Scl					),
				.Cs_n       (Cs_n					),
				.cs_en      (cs_en					),
				.Ssda       (Sda					),
				.Data_out   (ssi_data				),
				.Data_flag  (ssi_data_flag			)
		);
	end
endgenerate

/*******************************************************************************
// 			错误和警告
*******************************************************************************/
wire		[63:0]			fifo_sample_data;
wire						fifo_warning;
wire						fifo_error;
wire		[5:0]			fifo_crc;
wire						fifo_near_full;
reg							lost_frame_error;

assign fifo_near_full		= (fifo_rd_data_cnt >= 15'd1536);
assign lost_frame_event		= ssi_data_flag && data_acq_en && fifo_full;
assign fifo_sample_data		= {47'd0,ssi_data[16:0]};
assign fifo_warning			= fifo_near_full;
assign fifo_error			= lost_frame_error;
assign fifo_crc				= 6'd0;

always@(posedge Clk)
	if(local_rst)begin
		lost_frame_error <= 1'b0;
	end else if(lost_frame_event)begin
		lost_frame_error <= 1'b1;
	end

always@(posedge Clk)
	if(local_rst)begin
		error	<= 1'b0;
		warning	<= 1'b0;
	end else if(ssi_data_flag)begin
		error	<= fifo_error;
		warning	<= fifo_warning;
	end else begin
		error	<= 1'b0;
		warning	<= 1'b0;
	end

/*******************************************************************************
// 			时基数据
*******************************************************************************/
reg			[15:0]			time_base;
reg			[31:0]			frame_count;

always@(posedge Clk)
	if(local_rst)begin
		time_base <= 16'd0;
	end else begin
		time_base <= time_base + 1'b1;
	end

always@(posedge Clk)
	if(local_rst)begin
		frame_count <= 32'd0;
	end else if(ssi_data_flag && data_acq_en)begin
		frame_count <= frame_count + 1'b1;
	end

/*******************************************************************************
// 			数据打包
// d127-d96	帧计数
// d95-d92	通道标识位
// d91		警告位
// d90		错误位
// d89-d84	预留
// d83-d80	运行状态位
// d79-d64	时基数据
// d63-d0	采集数据
*******************************************************************************/
wire		[127:0]			fifo_wr_data;
wire						fifo_wr_en;

assign fifo_wr_en = ssi_data_flag && data_acq_en && ~fifo_full;
assign fifo_wr_data = {
	frame_count,
	CH_ID,
	fifo_warning,
	fifo_error,
	fifo_crc,
	data_status_bits,
	time_base,
	fifo_sample_data
};

/*******************************************************************************
// 			数据FIFO
*******************************************************************************/
wire						wr_rst_busy;
wire						rd_rst_busy;

fifo_128x16384 fifo_128x16384_inst (
	.rst			(local_rst			),
	.wr_clk			(Clk				),
	.rd_clk			(Clk				),
	.din			(fifo_wr_data		),
	.wr_en			(fifo_wr_en			),
	.rd_en			(fifo_rd_en			),
	.dout			(fifo_rd_data		),
	.full			(fifo_full			),
	.empty			(fifo_empty			),
	.rd_data_count	(fifo_rd_data_cnt	),
	.wr_rst_busy	(wr_rst_busy		),
	.rd_rst_busy	(rd_rst_busy		)
);

endmodule
