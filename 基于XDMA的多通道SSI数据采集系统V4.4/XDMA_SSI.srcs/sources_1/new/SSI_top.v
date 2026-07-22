`timescale 1ns / 1ps

module SSI_top#(
	parameter				S_CHANNEL			=	8,
							SIM_MODE			=	0,
							SIM_DATA_GEN		=	0,	// 1: 娴嬭瘯椤哄簭鏁帮紱0: 鐪熷疄SSI閲囬泦
	parameter	[31:0]		FPGA_VERSION		=	32'h2607_0221
)(
	// PCIe
	input							Pcie_rstn,
	input							Pcie_refclkp,
	input							Pcie_refclkn,
	input		[7:0]				Pcie_rxp,
	input		[7:0]				Pcie_rxn,
	output		[7:0]				Pcie_txp,
	output		[7:0]				Pcie_txn,

	// DDR
	input							DDR_SYS_CLK_clk_p,
	input							DDR_SYS_CLK_clk_n,
	input							DDR_sys_rst,
	output		[14:0]				DDR3_0_addr,
	output		[2:0]				DDR3_0_ba,
	output							DDR3_0_cas_n,
	output		[0:0]				DDR3_0_ck_n,
	output		[0:0]				DDR3_0_ck_p,
	output		[0:0]				DDR3_0_cke,
	output		[0:0]				DDR3_0_cs_n,
	output		[7:0]				DDR3_0_dm,
	inout		[63:0]				DDR3_0_dq,
	inout		[7:0]				DDR3_0_dqs_n,
	inout		[7:0]				DDR3_0_dqs_p,
	output		[0:0]				DDR3_0_odt,
	output							DDR3_0_ras_n,
	output							DDR3_0_reset_n,
	output							DDR3_0_we_n,

	// SSI
	output		[S_CHANNEL-1:0]		Scl,
	output		[S_CHANNEL-1:0]		Cs_n,
	input		[S_CHANNEL-1:0]		Sda,
	output		[S_CHANNEL-1:0]		RE_422,
	output		[S_CHANNEL-1:0]		DE_422,
	output		[7:0]				led
);

/*******************************************************************************
// 		鍩虹鏃堕挓澶嶄綅涓庡浐瀹氭柟鍚戞帶鍒?*******************************************************************************/
wire							pcie_rstn;
wire							pcie_refclk;
wire							user_lnk_up;
wire							xdma_axi_aclk;
wire							xdma_ax_aresetn;
wire							axi_rst;
wire							init_calib_complete;
wire							mmcm_locked;
wire							init_calib_complete_sync;
wire							mmcm_locked_sync;

assign axi_rst	= ~xdma_ax_aresetn;
assign RE_422	= {S_CHANNEL{1'b0}};
assign DE_422	= {S_CHANNEL{1'b1}};

generate
	if(SIM_MODE == 0)begin : pcie_input_buf
		IBUFDS_GTE2 refclk_ibuf (
			.CEB	(1'b0			),
			.I		(Pcie_refclkp	),
			.IB		(Pcie_refclkn	),
			.O		(pcie_refclk	),
			.ODIV2	(				)
		);

		IBUF sys_reset_n_ibuf (
			.I		(Pcie_rstn		),
			.O		(pcie_rstn		)
		);
	end else begin : sim_input_buf
		assign pcie_refclk	= Pcie_refclkp;
		assign pcie_rstn	= Pcie_rstn;
	end
endgenerate

/*******************************************************************************
// 		XDMA BRAM閰嶇疆鎺ュ彛
*******************************************************************************/
wire		[13:0]				bram_addr;
wire							bram_clk;
wire		[127:0]				bram_din;
wire		[127:0]				bram_dout;
wire							bram_en;
wire							bram_rst;
wire		[15:0]				bram_we;

wire		[127:0]				cfg_dout;
wire		[127:0]				cfg_din;

assign cfg_din		= bram_din;
assign bram_dout	= cfg_dout;

/*******************************************************************************
// 		DataMover S2MM鎺ュ彛
*******************************************************************************/
wire		[127:0]				s2mm_tdata;
wire		[15:0]				s2mm_tkeep;
wire							s2mm_tlast;
wire							s2mm_tready;
wire							s2mm_tvalid;
wire		[71:0]				s2mm_cmd_tdata;
wire							s2mm_cmd_tready;
wire							s2mm_cmd_tvalid;
wire		[7:0]				s2mm_sts_tdata;
wire		[0:0]				s2mm_sts_tkeep;
wire							s2mm_sts_tlast;
wire							s2mm_sts_tready;
wire							s2mm_sts_tvalid;

/*******************************************************************************
// 		閰嶇疆銆佺姸鎬佸拰閲囬泦鎺у埗淇″彿
*******************************************************************************/
wire							arb_ping_pang_sel;
wire		[S_CHANNEL-1:0]		data_acq_en;
wire		[7:0]				RX_SIZE;
wire							clear_int_en;
wire		[31:0]				single_sample;
wire		[31:0]				irq_sample_depth;
wire		[31:0]				irq_debug_status;
wire							cs_en;
wire		[2:0]				Scl_ctrl;
wire		[S_CHANNEL-1:0]		fifo_overflow;
wire		[31:0]				s2mm_write_addr;
wire		[31:0]				s2mm_block_count;
wire		[7:0]				s2mm_last_status;
wire							s2mm_status_error;
wire		[S_CHANNEL-1:0]		fifo_full;
wire		[S_CHANNEL-1:0]		fifo_empty;
wire		[S_CHANNEL*15-1:0]	fifo_rd_data_cnt;
wire		[31:0]				lost_frame_count;
wire		[S_CHANNEL-1:0]		error;
wire		[S_CHANNEL-1:0]		warning;
wire		[15:0]				current_channel;
wire							datamover_idle;
wire							transfer_done;
wire							transfer_error;
wire							arb_interrupt;
wire		[1:0]				arb_irq_pending_count;
wire							arb_irq_queue_full;
wire							arb_completed_bank_sel;
wire							acq_stop_pulse;
wire							acq_stop_reset;

assign fifo_overflow		= fifo_full;

/*******************************************************************************
// 		DDR鍒濆鍖栫姸鎬佸悓姝?*******************************************************************************/
reg			[2:0]				init_calib_complete_sync_r;
reg			[2:0]				mmcm_locked_sync_r;

always@(posedge bram_clk)
	if(bram_rst)begin
		init_calib_complete_sync_r	<= 3'd0;
		mmcm_locked_sync_r			<= 3'd0;
	end else begin
		init_calib_complete_sync_r	<= {init_calib_complete_sync_r[1:0],init_calib_complete};
		mmcm_locked_sync_r			<= {mmcm_locked_sync_r[1:0],mmcm_locked};
	end

assign init_calib_complete_sync	= init_calib_complete_sync_r[2];
assign mmcm_locked_sync			= mmcm_locked_sync_r[2];

/*******************************************************************************
// 		閰嶇疆瀵勫瓨鍣?*******************************************************************************/
cfg_reg_ctrl#(
	.S_CHANNEL			(S_CHANNEL				),
	.FPGA_VERSION		(FPGA_VERSION			)
)cfg_reg_ctrl_ins(
	.Clk				(bram_clk				),
	.Rst				(bram_rst				),
	.en_b				(bram_en				),
	.wen_b				(bram_we				),
	.addr_b				(bram_addr				),
	.din_b				(cfg_din				),
	.dout_b				(cfg_dout				),
	.RX_SIZE			(RX_SIZE				),
	.cs_en				(cs_en					),
	.Scl_ctrl			(Scl_ctrl				),
	.bank_sel			(arb_completed_bank_sel	),
	.ddr_init_done		(init_calib_complete_sync),
	.ddr_mmcm_locked	(mmcm_locked_sync		),
	.fifo_overflow		(fifo_overflow			),
	.s2mm_status_error	(s2mm_status_error		),
	.irq_debug_status	(irq_debug_status		),
	.lost_frame_count	(lost_frame_count		),
	.data_acq_en		(data_acq_en			),
	.clear_int_en		(clear_int_en			),
	.single_sample		(single_sample			),
	.irq_sample_depth	(irq_sample_depth		)
);

/*******************************************************************************
// 		SSI閲囬泦浠茶涓嶴2MM鍐橠DR
*******************************************************************************/
ssi_axis_arbiter#(
	.S_CHANNEL				(S_CHANNEL			),
	.CLK_T					(8					),
	.SIM_DATA_GEN			(SIM_DATA_GEN		),
	.CHANNEL_ADDR_OFFSET	(32'h0020_0000		),
	.PING_PANG_OFFSET		(32'h0010_0000		)
)ssi_axis_arbiter_ins(
	.Clk					(bram_clk			),
	.Rst					(bram_rst			),
	.Sda					(Sda				),
	.Scl					(Scl				),
	.Cs_n					(Cs_n				),
	.RX_SIZE				(RX_SIZE			),
	.cs_en					(cs_en				),
	.data_acq_en			(data_acq_en		),
	.Scl_ctrl				(Scl_ctrl			),
	.DMA_TRANSFER_SIZE		(single_sample[15:0]),
	.IRQ_TRANSFER_SIZE		(irq_sample_depth	),
	.int_clr				(clear_int_en		),
	.acq_stop_reset			(acq_stop_reset		),
	.error					(error				),
	.warning				(warning			),
	.fifo_rd_data_cnt		(fifo_rd_data_cnt	),
	.fifo_empty				(fifo_empty			),
	.fifo_full				(fifo_full			),
	.lost_frame_count		(lost_frame_count	),
	.current_channel		(current_channel	),
	.ping_pang_sel			(arb_ping_pang_sel	),
	.m_axis_tdata			(s2mm_tdata			),
	.m_axis_tvalid			(s2mm_tvalid		),
	.m_axis_tready			(s2mm_tready		),
	.m_axis_tlast			(s2mm_tlast			),
	.m_axis_tkeep			(s2mm_tkeep			),
	.s2mm_cmd_tdata			(s2mm_cmd_tdata		),
	.s2mm_cmd_tvalid		(s2mm_cmd_tvalid	),
	.s2mm_cmd_tready		(s2mm_cmd_tready	),
	.s2mm_sts_tdata			(s2mm_sts_tdata		),
	.s2mm_sts_tvalid		(s2mm_sts_tvalid	),
	.s2mm_sts_tready		(s2mm_sts_tready	),
	.s2mm_sts_tkeep			(s2mm_sts_tkeep[0]	),
	.s2mm_sts_tlast			(s2mm_sts_tlast		),
	.datamover_idle			(datamover_idle		),
	.transfer_done			(transfer_done		),
	.transfer_error			(transfer_error		),
	.interrupt				(arb_interrupt		),
	.irq_pending_count_o	(arb_irq_pending_count),
	.irq_queue_full_o		(arb_irq_queue_full	),
	.completed_bank_sel_o	(arb_completed_bank_sel),
	.s2mm_write_addr		(s2mm_write_addr	),
	.s2mm_block_count		(s2mm_block_count	),
	.s2mm_last_status		(s2mm_last_status	),
	.s2mm_status_error		(s2mm_status_error	)
);

/*******************************************************************************
// 		XDMA鐢ㄦ埛涓柇
*******************************************************************************/
wire							usr_irq_ack;
wire							usr_irq_req;
wire							irq_event;
wire							irq_req_set;
wire							irq_armed;
wire							irq_ack;
wire							acq_start_pulse;
wire							irq_buffer_pending;
wire							irq_buffer_req_set;
wire							irq_error_req_set;

reg								usr_irq_req_r;
reg								irq_event_d;
reg			[S_CHANNEL-1:0]		data_acq_en_d;
reg								irq_in_service;
reg								s2mm_error_notified;
reg			[3:0]				acq_stop_rst_shreg;

assign irq_buffer_pending	= (arb_irq_pending_count != 2'd0);
assign irq_buffer_req_set	= (!usr_irq_req_r) && (!irq_in_service) && (!clear_int_en) && (!acq_start_pulse) && (!acq_stop_pulse) && irq_buffer_pending;
assign irq_error_req_set	= (!usr_irq_req_r) && (!irq_in_service) && (!clear_int_en) && (!acq_start_pulse) && (!acq_stop_pulse) && (s2mm_status_error && !s2mm_error_notified);
assign irq_event			= (!irq_in_service) && (irq_buffer_pending | (s2mm_status_error && !s2mm_error_notified));
assign irq_req_set			= irq_buffer_req_set | irq_error_req_set;
assign irq_ack				= usr_irq_ack;
assign acq_start_pulse		= |(data_acq_en & ~data_acq_en_d);
assign acq_stop_pulse		= (|data_acq_en_d) && !(|data_acq_en);
assign acq_stop_reset		= |acq_stop_rst_shreg;
assign irq_armed			= (!usr_irq_req_r) && (!irq_in_service) && (!s2mm_status_error || s2mm_error_notified);

assign irq_debug_status = {
	15'd0,
	irq_in_service,
	arb_irq_queue_full,
	arb_irq_pending_count,
	acq_start_pulse,
	1'b0,
	s2mm_status_error,
	|fifo_overflow,
	arb_interrupt,
	clear_int_en,
	irq_req_set,
	irq_event_d,
	irq_event,
	irq_ack,
	irq_armed,
	usr_irq_req_r,
	usr_irq_req
};

always@(posedge bram_clk)
	if(bram_rst)begin
		data_acq_en_d		<= {S_CHANNEL{1'b0}};
		irq_event_d			<= 1'b0;
		acq_stop_rst_shreg	<= 4'd0;
	end else begin
		data_acq_en_d		<= data_acq_en;
		irq_event_d			<= irq_event;
		if(acq_stop_pulse)begin
			acq_stop_rst_shreg <= 4'hf;
		end else begin
			acq_stop_rst_shreg <= {1'b0,acq_stop_rst_shreg[3:1]};
		end
	end

always@(posedge bram_clk)
	if(bram_rst)begin
		usr_irq_req_r			<= 1'b0;
		irq_in_service			<= 1'b0;
		s2mm_error_notified		<= 1'b0;
	end else if(clear_int_en || acq_start_pulse || acq_stop_pulse)begin
		usr_irq_req_r			<= 1'b0;
		irq_in_service			<= 1'b0;
		s2mm_error_notified		<= 1'b0;
	end else if(irq_ack)begin
		usr_irq_req_r			<= 1'b0;
	end else if(irq_req_set)begin
		usr_irq_req_r			<= 1'b1;
		if(irq_buffer_req_set)begin
			irq_in_service <= 1'b1;
		end
		if(s2mm_status_error)begin
			s2mm_error_notified <= 1'b1;
		end
	end

assign usr_irq_req = usr_irq_req_r;

/*******************************************************************************
// 		LED
*******************************************************************************/
assign led[2]	= ~arb_ping_pang_sel;
assign led[1]	= ~usr_irq_req_r;
assign led[0]	= user_lnk_up;
assign led[7:3]	= 5'b11111;

/*******************************************************************************
// 		XDMA涓嶥DR绯荤粺
*******************************************************************************/
generate
	if(SIM_MODE == 0)begin : bd_path
		XDMA_wrapper XDMA_wrapper_ins (
			.BRAM_PORTA_0_addr			(bram_addr			),
			.BRAM_PORTA_0_clk			(bram_clk			),
			.BRAM_PORTA_0_din			(bram_din			),
			.BRAM_PORTA_0_dout			(bram_dout			),
			.BRAM_PORTA_0_en			(bram_en			),
			.BRAM_PORTA_0_rst			(bram_rst			),
			.BRAM_PORTA_0_we			(bram_we			),
			.DDR3_0_addr				(DDR3_0_addr		),
			.DDR3_0_ba					(DDR3_0_ba			),
			.DDR3_0_cas_n				(DDR3_0_cas_n		),
			.DDR3_0_ck_n				(DDR3_0_ck_n		),
			.DDR3_0_ck_p				(DDR3_0_ck_p		),
			.DDR3_0_cke					(DDR3_0_cke			),
			.DDR3_0_cs_n				(DDR3_0_cs_n		),
			.DDR3_0_dm					(DDR3_0_dm			),
			.DDR3_0_dq					(DDR3_0_dq			),
			.DDR3_0_dqs_n				(DDR3_0_dqs_n		),
			.DDR3_0_dqs_p				(DDR3_0_dqs_p		),
			.DDR3_0_odt					(DDR3_0_odt			),
			.DDR3_0_ras_n				(DDR3_0_ras_n		),
			.DDR3_0_reset_n				(DDR3_0_reset_n		),
			.DDR3_0_we_n				(DDR3_0_we_n		),
			.DDR_SYS_CLK_clk_n			(DDR_SYS_CLK_clk_n	),
			.DDR_SYS_CLK_clk_p			(DDR_SYS_CLK_clk_p	),
			.DDR_sys_rst				(DDR_sys_rst		),
			.M_AXIS_S2MM_STS_0_tdata	(s2mm_sts_tdata		),
			.M_AXIS_S2MM_STS_0_tkeep	(s2mm_sts_tkeep		),
			.M_AXIS_S2MM_STS_0_tlast	(s2mm_sts_tlast		),
			.M_AXIS_S2MM_STS_0_tready	(s2mm_sts_tready	),
			.M_AXIS_S2MM_STS_0_tvalid	(s2mm_sts_tvalid	),
			.S_AXIS_S2MM_0_tdata		(s2mm_tdata			),
			.S_AXIS_S2MM_0_tkeep		(s2mm_tkeep			),
			.S_AXIS_S2MM_0_tlast		(s2mm_tlast			),
			.S_AXIS_S2MM_0_tready		(s2mm_tready		),
			.S_AXIS_S2MM_0_tvalid		(s2mm_tvalid		),
			.S_AXIS_S2MM_CMD_0_tdata	(s2mm_cmd_tdata		),
			.S_AXIS_S2MM_CMD_0_tready	(s2mm_cmd_tready	),
			.S_AXIS_S2MM_CMD_0_tvalid	(s2mm_cmd_tvalid	),
			.init_calib_complete		(init_calib_complete),
			.mmcm_locked				(mmcm_locked		),
			.pcie_mgt_rxn				(Pcie_rxn			),
			.pcie_mgt_rxp				(Pcie_rxp			),
			.pcie_mgt_txn				(Pcie_txn			),
			.pcie_mgt_txp				(Pcie_txp			),
			.pcie_sys_clk				(pcie_refclk		),
			.pcie_sys_rst_n				(pcie_rstn			),
			.user_lnk_up				(user_lnk_up		),
			.usr_irq_ack				(usr_irq_ack		),
			.usr_irq_req				(usr_irq_req		),
			.xdma_ax_aresetn			(xdma_ax_aresetn	),
			.xdma_axi_aclk				(xdma_axi_aclk		)
		);
	end else begin : sim_bd_bypass
		reg		[13:0]		sim_bram_addr;
		reg		[127:0]		sim_bram_din;
		reg					sim_bram_en;
		reg		[15:0]		sim_bram_we;
		reg		[7:0]		sim_sts_tdata;
		reg					sim_sts_tvalid;
		reg					sim_sts_tlast;
		reg		[7:0]		sim_status_wait_cnt;
		reg		[31:0]		sim_cfg_state;
		reg		[31:0]		sim_cycle_cnt;
		reg		[31:0]		sim_cmd_cnt;
		reg		[31:0]		sim_data_cnt;
		reg		[15:0]		sim_irq_ack_shift;

		assign bram_clk				= pcie_refclk;
		assign bram_rst				= ~pcie_rstn;
		assign bram_addr			= sim_bram_addr;
		assign bram_din				= sim_bram_din;
		assign bram_en				= sim_bram_en;
		assign bram_we				= sim_bram_we;
		assign s2mm_cmd_tready		= 1'b1;
		assign s2mm_tready			= (sim_cycle_cnt[3:2] != 2'b10);
		assign s2mm_sts_tdata		= sim_sts_tdata;
		assign s2mm_sts_tkeep		= 1'b1;
		assign s2mm_sts_tlast		= sim_sts_tlast;
		assign s2mm_sts_tvalid		= sim_sts_tvalid;
		assign init_calib_complete	= 1'b1;
		assign mmcm_locked			= 1'b1;
		assign user_lnk_up			= 1'b1;
		assign xdma_ax_aresetn		= pcie_rstn;
		assign xdma_axi_aclk			= pcie_refclk;
		assign Pcie_txp				= 4'd0;
		assign Pcie_txn				= 4'd0;
		assign DDR3_0_addr			= 15'd0;
		assign DDR3_0_ba			= 3'd0;
		assign DDR3_0_cas_n			= 1'b1;
		assign DDR3_0_ck_n			= 1'b0;
		assign DDR3_0_ck_p			= 1'b0;
		assign DDR3_0_cke			= 1'b0;
		assign DDR3_0_cs_n			= 1'b1;
		assign DDR3_0_dm			= 8'd0;
		assign DDR3_0_odt			= 1'b0;
		assign DDR3_0_ras_n			= 1'b1;
		assign DDR3_0_reset_n		= 1'b0;
		assign DDR3_0_we_n			= 1'b1;
		assign usr_irq_ack			= sim_irq_ack_shift;

		task sim_reg_write;
			input	[13:0]	addr;
			input	[31:0]	data;
			begin
				sim_bram_addr	<= addr;
				sim_bram_din	<= {96'd0,data};
				sim_bram_en		<= 1'b1;
				sim_bram_we		<= 16'h000f;
			end
		endtask

		always@(posedge bram_clk)
			if(bram_rst)begin
				sim_bram_addr			<= 14'd0;
				sim_bram_din			<= 128'd0;
				sim_bram_en				<= 1'b0;
				sim_bram_we				<= 16'd0;
				sim_cfg_state			<= 32'd0;
				sim_cycle_cnt			<= 32'd0;
				sim_cmd_cnt				<= 32'd0;
				sim_data_cnt			<= 32'd0;
				sim_sts_tdata			<= 8'd0;
				sim_sts_tvalid			<= 1'b0;
				sim_sts_tlast			<= 1'b0;
				sim_status_wait_cnt		<= 8'd0;
				sim_irq_ack_shift		<= 16'd0;
			end else begin
				sim_cycle_cnt	<= sim_cycle_cnt + 1'b1;
				sim_bram_en		<= 1'b0;
				sim_bram_we		<= 16'd0;

				case(sim_cfg_state)
					32'd20	:	sim_reg_write(13'h050,32'd256);
					32'd21	:	sim_reg_write(13'h060,32'd1024);
					32'd22	:	sim_reg_write(13'h040,32'd24);
					32'd24	:	sim_reg_write(13'h030,32'd0);
					32'd26	:	sim_reg_write(13'h020,32'd1);
					32'd28	:	sim_reg_write(13'h000,{{(32-S_CHANNEL){1'b0}},{S_CHANNEL{1'b1}}});
					default	:	begin
								end
				endcase
				sim_cfg_state <= sim_cfg_state + 1'b1;

				if(s2mm_cmd_tvalid && s2mm_cmd_tready)begin
					sim_cmd_cnt <= sim_cmd_cnt + 1'b1;
				end

				if(s2mm_tvalid && s2mm_tready)begin
					sim_data_cnt <= sim_data_cnt + 1'b1;
					if(s2mm_tlast)begin
						sim_status_wait_cnt <= 8'd4;
					end
				end else if(sim_status_wait_cnt != 8'd0)begin
					sim_status_wait_cnt <= sim_status_wait_cnt - 1'b1;
				end

				if(sim_status_wait_cnt == 8'd1)begin
					sim_sts_tdata	<= 8'h80;
					sim_sts_tvalid	<= 1'b1;
					sim_sts_tlast	<= 1'b1;
				end else if(s2mm_sts_tvalid && s2mm_sts_tready)begin
					sim_sts_tdata	<= 8'd0;
					sim_sts_tvalid	<= 1'b0;
					sim_sts_tlast	<= 1'b0;
				end

				sim_irq_ack_shift <= {sim_irq_ack_shift[14:0],usr_irq_req};
				if(usr_irq_req)begin
					sim_reg_write(13'h010,32'd1);
				end
			end
	end
endgenerate

endmodule

