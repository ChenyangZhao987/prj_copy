`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2025/09/17 11:34:47
// Design Name: zcy
// Module Name: cfg_reg_ctrl
// Project Name: XDMA_SSI
// Target Devices:
// Tool Versions:
// Description: 配置寄存器控制模块
//
// Revision:
// Revision 0.03 - Register function decoupled, original function unchanged
//
//////////////////////////////////////////////////////////////////////////////////

module cfg_reg_ctrl #(
	parameter				S_CHANNEL		=	2,
	parameter	[31:0]		FPGA_VERSION	=	32'h0002_0001
)(
	input					Clk,
	input					Rst,

	input					en_b,
	input	[15:0]			wen_b,
	input	[12:0]			addr_b,
	input	[31:0]			din_b,
	output	reg [31:0]		dout_b,

	output	reg [7:0]		RX_SIZE,
	output	reg				cs_en,
	output	reg [2:0]		Scl_ctrl,

	input					bank_sel,
	input					ddr_init_done,
	input					ddr_mmcm_locked,
	input	[S_CHANNEL-1:0]	fifo_overflow,

	input					s2mm_status_error,

	input	[31:0]			irq_debug_status,
	input	[31:0]			lost_frame_count,

	output	reg [S_CHANNEL-1:0]	data_acq_en,
	output	reg				clear_int_en,
	output	reg [31:0]		single_sample,
	output	reg [31:0]		irq_sample_depth
);

/*******************************************************************************
// 			寄存器地址定义
*******************************************************************************/
localparam	[12:0]			REG_DATA_ACQ_EN			=	13'h000;
localparam	[12:0]			REG_CLEAR_INT			=	13'h010;
localparam	[12:0]			REG_CS_EN				=	13'h020;
localparam	[12:0]			REG_SCL_CTRL			=	13'h030;
localparam	[12:0]			REG_RX_SIZE				=	13'h040;
localparam	[12:0]			REG_DMA_DEPTH			=	13'h050;
localparam	[12:0]			REG_IRQ_DEPTH			=	13'h060;

localparam	[12:0]			REG_BANK_SEL			=	13'h100;
localparam	[12:0]			REG_SYS_STATUS			=	13'h110;
localparam	[12:0]			REG_LOST_FRAME_COUNT	=	13'h120;
localparam	[12:0]			REG_FPGA_VERSION		=	13'h130;

/*******************************************************************************
// 			复位同步
*******************************************************************************/
reg		[2:0]	rst;
wire			r_rst;

always @(posedge Clk) begin
	rst <= {rst[1:0], Rst};
end

assign r_rst = rst[2];

/*******************************************************************************
// 			写使能
*******************************************************************************/
wire	reg_wr_en;

assign reg_wr_en = en_b && (|wen_b);

/*******************************************************************************
// 			各寄存器写使能译码
*******************************************************************************/
wire	wr_data_acq_en;
wire	wr_clear_int;
wire	wr_cs_en;
wire	wr_scl_ctrl;
wire	wr_rx_size;
wire	wr_dma_depth;
wire	wr_irq_depth;

assign wr_data_acq_en	= reg_wr_en && (addr_b == REG_DATA_ACQ_EN);
assign wr_clear_int		= reg_wr_en && (addr_b == REG_CLEAR_INT);
assign wr_cs_en			= reg_wr_en && (addr_b == REG_CS_EN);
assign wr_scl_ctrl		= reg_wr_en && (addr_b == REG_SCL_CTRL);
assign wr_rx_size		= reg_wr_en && (addr_b == REG_RX_SIZE);
assign wr_dma_depth		= reg_wr_en && (addr_b == REG_DMA_DEPTH);
assign wr_irq_depth		= reg_wr_en && (addr_b == REG_IRQ_DEPTH);

/*******************************************************************************
// 			REG_DATA_ACQ_EN : 采集使能
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		data_acq_en <= {S_CHANNEL{1'b0}};
	end else if (wr_data_acq_en) begin
		data_acq_en <= din_b[S_CHANNEL-1:0];
	end
end

/*******************************************************************************
// 			REG_CS_EN : 片选使能
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		cs_en <= 1'b0;
	end else if (wr_cs_en) begin
		cs_en <= din_b[0];
	end
end

/*******************************************************************************
// 			REG_SCL_CTRL : 采集时钟控制
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		Scl_ctrl <= 3'd0;
	end else if (wr_scl_ctrl) begin
		Scl_ctrl <= din_b[2:0];
	end
end

/*******************************************************************************
// 			REG_RX_SIZE : 接收位宽
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		RX_SIZE <= 8'd17;
	end else if (wr_rx_size) begin
		RX_SIZE <= din_b[7:0];
	end
end

/*******************************************************************************
// 			REG_DMA_DEPTH : DMA 单次采样深度
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		single_sample <= 32'd512;
	end else if (wr_dma_depth) begin
		single_sample <= { din_b[31:4], 4'd0};
	end
end

/*******************************************************************************
// 			REG_IRQ_DEPTH : 中断触发深度
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		irq_sample_depth <= 32'd32768;
	end else if (wr_irq_depth) begin
		irq_sample_depth <= (din_b[31:4] > 28'h000FF80) ?
							32'h000F_F800 :
							{din_b[31:4], 4'd0};
	end
end

/*******************************************************************************
// 			REG_CLEAR_INT : 清中断脉冲
*******************************************************************************/
always @(posedge Clk) begin
	if (r_rst) begin
		clear_int_en <= 1'b0;
	end else begin
		clear_int_en <= wr_clear_int && din_b[0];
	end
end

/*******************************************************************************
// 			读回寄存器
*******************************************************************************/
always @(*) begin
	case (addr_b)
		REG_DATA_ACQ_EN		:	dout_b = {{(32-S_CHANNEL){1'b0}}, data_acq_en};
		REG_CLEAR_INT		:	dout_b = 32'd0;
		REG_CS_EN			:	dout_b = {31'd0, cs_en};
		REG_SCL_CTRL		:	dout_b = {29'd0, Scl_ctrl};
		REG_RX_SIZE			:	dout_b = {24'd0, RX_SIZE};
		REG_DMA_DEPTH		:	dout_b = single_sample;
		REG_IRQ_DEPTH		:	dout_b = irq_sample_depth;

		REG_BANK_SEL		:	dout_b = {30'd0, (irq_debug_status[14:13] != 2'd0), bank_sel};

		REG_SYS_STATUS		:	dout_b = {
									22'd0,
									irq_debug_status[16],
									irq_debug_status[15],
									irq_debug_status[14:13],
									bank_sel,
									(irq_debug_status[14:13] != 2'd0),
									s2mm_status_error,
									|fifo_overflow,
									ddr_mmcm_locked,
									ddr_init_done
								};

		REG_LOST_FRAME_COUNT:	dout_b = lost_frame_count;
		REG_FPGA_VERSION	:	dout_b = FPGA_VERSION;

		default				:	dout_b = 32'h0000_0000;
	endcase
end

endmodule
