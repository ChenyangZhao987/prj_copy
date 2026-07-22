`timescale 1ns / 1ps

module tb_ssi_axis_arbiter;

localparam S_CHANNEL = 2;

reg                         Clk;
reg                         Rst;
reg     [S_CHANNEL-1:0]     Sda;
wire    [S_CHANNEL-1:0]     Scl;
wire    [S_CHANNEL-1:0]     Cs_n;

reg     [7:0]               RX_SIZE;
reg                         cs_en;
reg     [S_CHANNEL-1:0]     data_acq_en;
reg     [2:0]               Scl_ctrl;
reg     [15:0]              DMA_TRANSFER_SIZE;
reg                         int_clr;
wire    [S_CHANNEL-1:0]     error;
wire    [S_CHANNEL-1:0]     warning;
wire    [S_CHANNEL*14-1:0]  fifo_rd_data_cnt;
wire    [S_CHANNEL-1:0]     fifo_empty;
wire    [S_CHANNEL-1:0]     fifo_full;
wire    [15:0]              current_channel;
wire                        ping_pang_sel;

wire    [127:0]             m_axis_tdata;
wire                        m_axis_tvalid;
reg                         m_axis_tready;
wire                        m_axis_tlast;
wire    [15:0]              m_axis_tkeep;

wire    [71:0]              s2mm_cmd_tdata;
wire                        s2mm_cmd_tvalid;
reg                         s2mm_cmd_tready;

reg     [7:0]               s2mm_sts_tdata;
reg                         s2mm_sts_tvalid;
wire                        s2mm_sts_tready;
reg                         s2mm_sts_tkeep;
reg                         s2mm_sts_tlast;

wire                        datamover_idle;
wire                        transfer_done;
wire                        transfer_error;
wire                        interrupt;
wire    [31:0]              s2mm_write_addr;
wire    [31:0]              s2mm_block_count;
wire    [7:0]               s2mm_last_status;
wire                        s2mm_status_error;

reg     [31:0]              cycle_cnt;
reg     [7:0]               status_wait_cnt;
reg     [31:0]              cmd_cnt;
reg     [31:0]              beat_cnt;
reg     [31:0]              interrupt_cnt;

always #5 Clk = ~Clk;

ssi_axis_arbiter #(
    .S_CHANNEL              (S_CHANNEL          ),
    .CLK_T                  (8                  ),
    .SIM_DATA_GEN           (1                  ),
    .CHANNEL_ADDR_OFFSET    (32'h0010_0000      ),
    .PING_PANG_OFFSET       (32'h0008_0000      )
)dut(
    .Clk                    (Clk                ),
    .Rst                    (Rst                ),
    .Sda                    (Sda                ),
    .Scl                    (Scl                ),
    .Cs_n                   (Cs_n               ),
    .RX_SIZE                (RX_SIZE            ),
    .cs_en                  (cs_en              ),
    .data_acq_en            (data_acq_en        ),
    .Scl_ctrl               (Scl_ctrl           ),
    .DMA_TRANSFER_SIZE      (DMA_TRANSFER_SIZE  ),
    .int_clr                (int_clr            ),
    .error                  (error              ),
    .warning                (warning            ),
    .fifo_rd_data_cnt       (fifo_rd_data_cnt   ),
    .fifo_empty             (fifo_empty         ),
    .fifo_full              (fifo_full          ),
    .current_channel        (current_channel    ),
    .ping_pang_sel          (ping_pang_sel      ),
    .m_axis_tdata           (m_axis_tdata       ),
    .m_axis_tvalid          (m_axis_tvalid      ),
    .m_axis_tready          (m_axis_tready      ),
    .m_axis_tlast           (m_axis_tlast       ),
    .m_axis_tkeep           (m_axis_tkeep       ),
    .s2mm_cmd_tdata         (s2mm_cmd_tdata     ),
    .s2mm_cmd_tvalid        (s2mm_cmd_tvalid    ),
    .s2mm_cmd_tready        (s2mm_cmd_tready    ),
    .s2mm_sts_tdata         (s2mm_sts_tdata     ),
    .s2mm_sts_tvalid        (s2mm_sts_tvalid    ),
    .s2mm_sts_tready        (s2mm_sts_tready    ),
    .s2mm_sts_tkeep         (s2mm_sts_tkeep     ),
    .s2mm_sts_tlast         (s2mm_sts_tlast     ),
    .datamover_idle         (datamover_idle     ),
    .transfer_done          (transfer_done      ),
    .transfer_error         (transfer_error     ),
    .interrupt              (interrupt          ),
    .s2mm_write_addr        (s2mm_write_addr    ),
    .s2mm_block_count       (s2mm_block_count   ),
    .s2mm_last_status       (s2mm_last_status   ),
    .s2mm_status_error      (s2mm_status_error  )
);

initial begin
    Clk                 = 1'b0;
    Rst                 = 1'b1;
    Sda                 = {S_CHANNEL{1'b0}};
    RX_SIZE             = 8'd24;
    cs_en               = 1'b1;
    data_acq_en         = {S_CHANNEL{1'b1}};
    Scl_ctrl            = 3'd0;
    DMA_TRANSFER_SIZE   = 16'd4096;
    int_clr             = 1'b0;
    m_axis_tready       = 1'b0;
    s2mm_cmd_tready     = 1'b0;
    s2mm_sts_tdata      = 8'd0;
    s2mm_sts_tvalid     = 1'b0;
    s2mm_sts_tkeep      = 1'b1;
    s2mm_sts_tlast      = 1'b0;
    cycle_cnt           = 32'd0;
    status_wait_cnt     = 8'd0;
    cmd_cnt             = 32'd0;
    beat_cnt            = 32'd0;
    interrupt_cnt       = 32'd0;

    repeat(20) @(posedge Clk);
    Rst = 1'b0;

    repeat(120000) @(posedge Clk);
    $display("SIM TIMEOUT: cmd_cnt=%0d beat_cnt=%0d interrupt_cnt=%0d", cmd_cnt, beat_cnt, interrupt_cnt);
    $finish;
end

always@(posedge Clk)
    if(Rst)begin
        s2mm_cmd_tready <= 1'b0;
        cmd_cnt         <= 32'd0;
    end else begin
        s2mm_cmd_tready <= 1'b1;
        if(s2mm_cmd_tvalid && s2mm_cmd_tready)begin
            cmd_cnt <= cmd_cnt + 1'b1;
            $display("[%0t] CMD ch=%0d addr=0x%08x btt=%0d", $time, current_channel, s2mm_cmd_tdata[55:24], s2mm_cmd_tdata[22:0]);
        end
    end

always@(posedge Clk)
    if(Rst)begin
        cycle_cnt       <= 32'd0;
        m_axis_tready   <= 1'b0;
        beat_cnt        <= 32'd0;
    end else begin
        cycle_cnt       <= cycle_cnt + 1'b1;
        m_axis_tready   <= (cycle_cnt[3:2] != 2'b10);
        if(m_axis_tvalid && m_axis_tready)begin
            beat_cnt <= beat_cnt + 1'b1;
            if(m_axis_tlast || beat_cnt[11:0] == 12'd0)begin
                $display("[%0t] DATA ch=%0d last=%0d data[63:0]=0x%016x", $time, current_channel, m_axis_tlast, m_axis_tdata[63:0]);
            end
        end
    end

always@(posedge Clk)
    if(Rst)begin
        status_wait_cnt     <= 8'd0;
        s2mm_sts_tdata      <= 8'd0;
        s2mm_sts_tvalid     <= 1'b0;
        s2mm_sts_tlast      <= 1'b0;
    end else begin
        if(m_axis_tvalid && m_axis_tready && m_axis_tlast)begin
            status_wait_cnt <= 8'd4;
        end else if(status_wait_cnt != 8'd0)begin
            status_wait_cnt <= status_wait_cnt - 1'b1;
        end

        if(status_wait_cnt == 8'd1)begin
            s2mm_sts_tdata  <= 8'h80;
            s2mm_sts_tvalid <= 1'b1;
            s2mm_sts_tlast  <= 1'b1;
        end else if(s2mm_sts_tvalid && s2mm_sts_tready)begin
            s2mm_sts_tdata  <= 8'd0;
            s2mm_sts_tvalid <= 1'b0;
            s2mm_sts_tlast  <= 1'b0;
        end
    end

always@(posedge Clk)
    if(Rst)begin
        int_clr         <= 1'b0;
        interrupt_cnt   <= 32'd0;
    end else if(interrupt)begin
        interrupt_cnt <= interrupt_cnt + 1'b1;
        int_clr <= 1'b1;
        $display("[%0t] INTERRUPT ping_pang_sel=%0d", $time, ping_pang_sel);
        if(interrupt_cnt == 32'd3)begin
            $display("SIM PASS: cmd_cnt=%0d beat_cnt=%0d interrupt_cnt=%0d", cmd_cnt, beat_cnt, interrupt_cnt + 1'b1);
            $finish;
        end
    end else begin
        int_clr <= 1'b0;
    end

endmodule
