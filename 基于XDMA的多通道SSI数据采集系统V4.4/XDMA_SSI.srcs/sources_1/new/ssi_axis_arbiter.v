`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2026/05/21
// Design Name: zcy
// Module Name: ssi_axis_arbiter
// Project Name: XDMA_SSI
// Target Devices:
// Tool Versions:
// Description: 多通道 SSI FIFO 仲裁，通过 DataMover S2MM 写入 DDR
//
// Dependencies: ssi_fifo_channel, SSI_interface, CRC_calculator, fifo_128x16384
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
module ssi_axis_arbiter#(
	parameter				S_CHANNEL			=	2,
	parameter				CLK_T				=	8,
							SIM_DATA_GEN		=	0,
	parameter	[31:0]		CHANNEL_ADDR_OFFSET	=	32'h0020_0000,
	parameter	[31:0]		PING_PANG_OFFSET	=	32'h0010_0000
	)(
	// 时钟复位
	input							Clk,
	input							Rst,
	// SSI 硬件接口
	input		[S_CHANNEL-1:0]		Sda,
	output		[S_CHANNEL-1:0]		Scl,
	output		[S_CHANNEL-1:0]		Cs_n,
	// 配置与状态接口
	input		[7:0]				RX_SIZE,
	input							cs_en,
	input		[S_CHANNEL-1:0]		data_acq_en,
	input		[2:0]				Scl_ctrl,
	input		[15:0]				DMA_TRANSFER_SIZE,
	input		[31:0]				IRQ_TRANSFER_SIZE,
	input							int_clr,
	input							acq_stop_reset,
	output		[S_CHANNEL-1:0]		error,
	output		[S_CHANNEL-1:0]		warning,
	output		[S_CHANNEL*15-1:0]	fifo_rd_data_cnt,
	output		[S_CHANNEL-1:0]		fifo_empty,
	output		[S_CHANNEL-1:0]		fifo_full,
	output	reg	[31:0]				lost_frame_count,
	output	reg	[15:0]				current_channel,
	output							ping_pang_sel,
	//AXI Stream(DataMover S2MM)
	output		[127:0]				m_axis_tdata,
	output	reg						m_axis_tvalid,
	input							m_axis_tready,
	output							m_axis_tlast,
	output		[15:0]				m_axis_tkeep,
	// DataMover S2MM 命令接口
	output		[71:0]				s2mm_cmd_tdata,
	output	reg						s2mm_cmd_tvalid,
	input							s2mm_cmd_tready,
	//DataMover S2MM status
	input		[7:0]				s2mm_sts_tdata,
	input							s2mm_sts_tvalid,
	output	reg						s2mm_sts_tready,
	input							s2mm_sts_tkeep,
	input							s2mm_sts_tlast,
	//transfer status
	output							datamover_idle,
	output	reg						transfer_done,
	output	reg						transfer_error,
	output	reg						interrupt,
	output		[1:0]				irq_pending_count_o,
	output							irq_queue_full_o,
	output							completed_bank_sel_o,
	output		[31:0]				s2mm_write_addr,
	output	reg	[31:0]				s2mm_block_count,
	output	reg	[7:0]				s2mm_last_status,
	output	reg						s2mm_status_error
);

/*******************************************************************************
// 		复位同步
*******************************************************************************/
reg			[2:0]			rr_rst;
wire						r_rst;

always@(posedge Clk)
	rr_rst <= {rr_rst[1:0],Rst};

assign	r_rst	= rr_rst[2];

/*******************************************************************************
// 		状态机定义
*******************************************************************************/
localparam					IDLE			=	3'd0,
							SEND_CMD		=	3'd1,
							TRANSFER_DATA	=	3'd2,
							WAIT_COMPLETE	=	3'd3,
							COMPLETE		=	3'd4,
							ERROR			=	3'd5;

reg			[2:0]			current_state;
reg			[2:0]			next_state;

assign datamover_idle = (current_state == IDLE);

/*******************************************************************************
// 		多通道 SSI FIFO 例化
*******************************************************************************/
wire		[S_CHANNEL-1:0]		ch_fifo_rd_en;
wire		[127:0]				ch_fifo_rd_data[0:S_CHANNEL-1];
wire		[14:0]				ch_fifo_rd_count[0:S_CHANNEL-1];
wire		[S_CHANNEL-1:0]		ch_lost_frame_event;
wire		[3:0]				data_status_bits;

genvar ch;
generate
	for(ch = 0; ch < S_CHANNEL; ch = ch + 1)begin : ssi_channel
		ssi_fifo_channel#(
			.CLK_T			(CLK_T			),
			.SIM_DATA_GEN	(SIM_DATA_GEN	),
			.CH_ID			(ch[3:0]		)
		)ssi_fifo_channel_inst(
			.Clk				(Clk									),
			.Rst				(r_rst									),
			.Sda				(Sda[ch]								),
			.Scl				(Scl[ch]								),
			.Cs_n				(Cs_n[ch]								),
			.RX_SIZE			(RX_SIZE								),
			.cs_en				(cs_en									),
			.data_acq_en		(data_acq_en[ch]						),
			.Scl_ctrl			(Scl_ctrl								),
			.data_status_bits	(data_status_bits						),
			.acq_stop_reset		(acq_stop_reset							),
			.error				(error[ch]								),
			.warning			(warning[ch]							),
			.fifo_rd_en			(ch_fifo_rd_en[ch]						),
			.fifo_rd_data		(ch_fifo_rd_data[ch]					),
			.fifo_empty			(fifo_empty[ch]							),
			.fifo_full			(fifo_full[ch]							),
			.fifo_rd_data_cnt	(ch_fifo_rd_count[ch]					),
			.lost_frame_event	(ch_lost_frame_event[ch]				)
		);

		assign fifo_rd_data_cnt[ch*15 +: 15] = ch_fifo_rd_count[ch];
	end
endgenerate

/*******************************************************************************
// 		当前操作通道 FIFO 选择
*******************************************************************************/
reg			[127:0]			selected_fifo_data;
reg			[14:0]			selected_fifo_count;
reg							selected_fifo_empty;
reg			[S_CHANNEL-1:0]	fifo_rd_en_r;
reg			[15:0]			transfer_channel;
wire		[15:0]			fifo_select_channel;
reg			[1:0]			irq_pending_count;
reg							pending_bank_select;
wire		[1:0]			irq_pending_after_clear;
wire						irq_queue_full;
integer						i;

assign fifo_select_channel 		= (current_state == IDLE) ? current_channel : transfer_channel;
assign irq_pending_after_clear 	= (int_clr && (irq_pending_count != 2'd0)) ? (irq_pending_count - 1'b1) : irq_pending_count;
assign irq_queue_full 			= (irq_pending_count == 2'd2);
assign irq_pending_count_o 		= irq_pending_count;
assign irq_queue_full_o 		= irq_queue_full;
assign completed_bank_sel_o 	= pending_bank_select;

always@(*)begin
	selected_fifo_data	= 128'd0;
	selected_fifo_count	= 15'd0;
	selected_fifo_empty	= 1'b1;
	for(i = 0; i < S_CHANNEL; i = i + 1)begin
		if(fifo_select_channel == i[15:0])begin
			selected_fifo_data	= ch_fifo_rd_data[i];
			selected_fifo_count	= ch_fifo_rd_count[i];
			selected_fifo_empty	= fifo_empty[i];
		end
	end
end

assign ch_fifo_rd_en = fifo_rd_en_r;
assign m_axis_tdata  = selected_fifo_data;
assign m_axis_tkeep  = 16'hffff;

/*******************************************************************************
// 		DataMover 命令与地址生成
*******************************************************************************/
wire		[31:0]			dma_addr;
wire		[22:0]			cmd_btt;
wire						cmd_type;
wire		[5:0]			cmd_dsa;
wire						cmd_eof;
wire						cmd_drr;
wire		[3:0]			cmd_tag;
wire		[3:0]			cmd_rsvd;
wire		[3:0]			cmd_xcache;
wire		[3:0]			cmd_xuser;
reg							ping_pang_select;
reg			[31:0]			channel_write_bytes[0:S_CHANNEL-1];
wire		[31:0]			dma_transfer_bytes;
wire		[31:0]			dma_transfer_words;
wire		[31:0]			irq_transfer_bytes;
wire		[31:0]			current_channel_base_addr;
wire		[31:0]			current_channel_offset_addr;

assign dma_transfer_bytes		= (DMA_TRANSFER_SIZE == 16'd0) ? 32'd16 : {16'd0,DMA_TRANSFER_SIZE};
assign dma_transfer_words		= (dma_transfer_bytes[3:0] == 4'd0) ? (dma_transfer_bytes >> 4) : ((dma_transfer_bytes >> 4) + 1'b1);
assign irq_transfer_bytes		= (IRQ_TRANSFER_SIZE < dma_transfer_bytes) ? dma_transfer_bytes : IRQ_TRANSFER_SIZE;
assign current_channel_base_addr	= current_channel * CHANNEL_ADDR_OFFSET + (ping_pang_select ? PING_PANG_OFFSET : 32'd0);
assign current_channel_offset_addr	= channel_write_bytes[current_channel];
assign dma_addr			= current_channel_base_addr + current_channel_offset_addr;
assign s2mm_write_addr	= dma_addr;
assign cmd_btt			= dma_transfer_bytes[22:0];
assign cmd_type			= 1'b1;
assign cmd_dsa			= 6'd0;
assign cmd_eof			= 1'b1;
assign cmd_drr			= 1'b0;
assign cmd_tag			= current_channel[3:0];
assign cmd_rsvd			= 4'd0;
assign cmd_xcache		= 4'd0;
assign cmd_xuser		= 4'd0;
assign ping_pang_sel	= ping_pang_select;
assign data_status_bits = {
	irq_queue_full,
	ping_pang_select,
	(irq_pending_count == 2'd2),
	(irq_pending_count != 2'd0)
};

assign s2mm_cmd_tdata	= {cmd_xuser,cmd_xcache,cmd_rsvd,cmd_tag,dma_addr,cmd_drr,cmd_eof,cmd_dsa,cmd_type,cmd_btt};

/*******************************************************************************
// 		主状态机
*******************************************************************************/
reg			[31:0]			line_transferred;
wire						current_channel_ready;
wire						round_done;
wire						round_done_after_error;
wire						current_channel_done_after_chunk;
wire		[31:0]			current_channel_next_bytes;
reg			[S_CHANNEL-1:0]	channel_done;
reg			[S_CHANNEL-1:0]	current_channel_mask;

always@(*)begin
	current_channel_mask = {S_CHANNEL{1'b0}};
	current_channel_mask[current_channel] = 1'b1;
end

assign current_channel_next_bytes		= channel_write_bytes[current_channel] + dma_transfer_bytes;
assign current_channel_done_after_chunk	= (current_channel_next_bytes >= irq_transfer_bytes);
assign current_channel_ready			= (!irq_queue_full) && data_acq_en[current_channel] && !channel_done[current_channel] && (selected_fifo_count >= dma_transfer_words);
assign round_done						= (((channel_done | (current_channel_done_after_chunk ? current_channel_mask : {S_CHANNEL{1'b0}})) & data_acq_en) == data_acq_en);
assign round_done_after_error			= (((channel_done | current_channel_mask) & data_acq_en) == data_acq_en);

always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		current_state <= IDLE;
	end else begin
		current_state <= next_state;
	end

always@(*)begin
	case(current_state)
		IDLE			:	next_state = current_channel_ready ? SEND_CMD : IDLE;
		SEND_CMD		:	next_state = (s2mm_cmd_tvalid && s2mm_cmd_tready) ? TRANSFER_DATA : SEND_CMD;
		TRANSFER_DATA	:	next_state = (m_axis_tvalid && m_axis_tready && (line_transferred == dma_transfer_words - 1'b1)) ? WAIT_COMPLETE : TRANSFER_DATA;
		WAIT_COMPLETE	:	begin
								if(s2mm_sts_tvalid && s2mm_sts_tdata[7])
									next_state = COMPLETE;
								else if(s2mm_sts_tvalid && (s2mm_sts_tdata[6] | s2mm_sts_tdata[5] | s2mm_sts_tdata[4]))
									next_state = ERROR;
								else
									next_state = WAIT_COMPLETE;
							end
		COMPLETE		:	next_state = IDLE;
		ERROR			:	next_state = IDLE;
		default			:	next_state = IDLE;
	endcase
end

/*******************************************************************************
// 		DataMover 状态返回处理
*******************************************************************************/
always@(*)begin
	case(current_state)
		SEND_CMD	:	s2mm_cmd_tvalid = 1'b1;
		default		:	s2mm_cmd_tvalid = 1'b0;
	endcase
end

always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		s2mm_sts_tready <= 1'b0;
	end else begin
		s2mm_sts_tready <= (current_state == WAIT_COMPLETE);
	end

always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		s2mm_last_status	<= 8'd0;
		s2mm_status_error	<= 1'b0;
	end else if(int_clr)begin
		s2mm_status_error	<= 1'b0;
	end else if(s2mm_sts_tvalid && s2mm_sts_tready)begin
		s2mm_last_status	<= s2mm_sts_tdata;
		s2mm_status_error	<= s2mm_sts_tdata[6] | s2mm_sts_tdata[5] | s2mm_sts_tdata[4];
	end

/*******************************************************************************
// 		FIFO 读出到 AXI Stream
*******************************************************************************/
reg							fifo_data_valid;
reg			[31:0]			fifo_read_count;
wire						fifo_rd_fire;

assign fifo_rd_fire = (current_state == TRANSFER_DATA) && m_axis_tready && (!selected_fifo_empty) && (fifo_read_count < dma_transfer_words);

always@(*)begin
	fifo_rd_en_r = {S_CHANNEL{1'b0}};
	if(fifo_rd_fire)begin
		fifo_rd_en_r[transfer_channel] = 1'b1;
	end
end

always@(*)begin
	case(current_state)
		TRANSFER_DATA	:	m_axis_tvalid = fifo_data_valid;
		default			:	m_axis_tvalid = 1'b0;
	endcase
end

always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		fifo_data_valid <= 1'b0;
	end else if(current_state != TRANSFER_DATA)begin
		fifo_data_valid <= 1'b0;
	end else if(m_axis_tready)begin
		fifo_data_valid <= fifo_rd_fire;
	end

always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		fifo_read_count <= 32'd0;
	end else if(current_state == IDLE)begin
		fifo_read_count <= 32'd0;
	end else if(fifo_rd_fire)begin
		fifo_read_count <= fifo_read_count + 1'b1;
	end

assign m_axis_tlast = m_axis_tvalid && m_axis_tready && (line_transferred == dma_transfer_words - 1'b1);

/*******************************************************************************
// 		通道轮询、乒乓切换与中断排队控制
*******************************************************************************/
always@(posedge Clk)
	if(r_rst || acq_stop_reset)begin
		current_channel		<= 16'd0;
		transfer_channel	<= 16'd0;
		channel_done		<= {S_CHANNEL{1'b0}};
		ping_pang_select	<= 1'b0;
		line_transferred	<= 32'd0;
		transfer_done		<= 1'b0;
		transfer_error		<= 1'b0;
		interrupt			<= 1'b0;
		irq_pending_count	<= 2'd0;
		pending_bank_select	<= 1'b0;
		s2mm_block_count	<= 32'd0;
		lost_frame_count	<= 32'd0;
		for(i = 0; i < S_CHANNEL; i = i + 1)begin
			channel_write_bytes[i] <= 32'd0;
		end
	end else begin
		transfer_done	<= 1'b0;
		transfer_error	<= 1'b0;

		if(|ch_lost_frame_event)begin
			lost_frame_count <= lost_frame_count + 1'b1;
		end

		if(int_clr)begin
			irq_pending_count <= irq_pending_after_clear;
			interrupt <= (irq_pending_after_clear != 2'd0);
			if(irq_pending_count == 2'd2)begin
				pending_bank_select <= ~pending_bank_select;
			end
		end

		case(current_state)
			IDLE			:	begin
									line_transferred <= 32'd0;
									if(current_channel_ready)begin
										transfer_channel <= current_channel;
									end else if(!irq_queue_full && !current_channel_ready)begin
										current_channel <= (current_channel == S_CHANNEL - 1) ? 16'd0 : current_channel + 1'b1;
									end
								end
			TRANSFER_DATA	:	begin
									if(m_axis_tvalid && m_axis_tready)
										line_transferred <= line_transferred + 1'b1;
								end
			COMPLETE		:	begin
									transfer_done <= 1'b1;
									s2mm_block_count <= s2mm_block_count + 1'b1;
									channel_write_bytes[current_channel] <= current_channel_done_after_chunk ? 32'd0 : current_channel_next_bytes;
									if(round_done)begin
										current_channel		<= 16'd0;
										channel_done		<= {S_CHANNEL{1'b0}};
										ping_pang_select	<= ~ping_pang_select;
										interrupt			<= 1'b1;
										irq_pending_count	<= (irq_pending_after_clear == 2'd2) ? 2'd2 : (irq_pending_after_clear + 1'b1);
										if(irq_pending_after_clear == 2'd0)begin
											pending_bank_select <= ping_pang_select;
										end
										for(i = 0; i < S_CHANNEL; i = i + 1)begin
											channel_write_bytes[i] <= 32'd0;
										end
									end else begin
										channel_done[current_channel] <= current_channel_done_after_chunk;
										current_channel		<= (current_channel == S_CHANNEL - 1) ? 16'd0 : current_channel + 1'b1;
									end
								end
			ERROR			:	begin
									transfer_error <= 1'b1;
									s2mm_block_count <= s2mm_block_count + 1'b1;
									if(round_done_after_error)begin
										current_channel		<= 16'd0;
										channel_done		<= {S_CHANNEL{1'b0}};
										ping_pang_select	<= ~ping_pang_select;
										interrupt			<= 1'b1;
										irq_pending_count	<= (irq_pending_after_clear == 2'd2) ? 2'd2 : (irq_pending_after_clear + 1'b1);
										if(irq_pending_after_clear == 2'd0)begin
											pending_bank_select <= ping_pang_select;
										end
										for(i = 0; i < S_CHANNEL; i = i + 1)begin
											channel_write_bytes[i] <= 32'd0;
										end
									end else begin
										channel_done[current_channel] <= 1'b1;
										current_channel		<= (current_channel == S_CHANNEL - 1) ? 16'd0 : current_channel + 1'b1;
									end
								end
			default			:	begin
								end
		endcase
	end

endmodule
