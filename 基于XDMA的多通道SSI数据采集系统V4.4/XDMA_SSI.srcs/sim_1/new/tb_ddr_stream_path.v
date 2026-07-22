`timescale 1ns / 1ps

module tb_ddr_stream_path;

localparam S_CHANNEL   = 2;
localparam DATA_WIDTH  = 128;
localparam FIFO_AW     = 3;
localparam BLOCK_BEATS = 4;

reg clk = 1'b0;
reg rst = 1'b1;

always #5 clk = ~clk;

reg  [S_CHANNEL-1:0]              fifo_s_valid;
wire [S_CHANNEL-1:0]              fifo_s_ready;
reg  [S_CHANNEL*DATA_WIDTH-1:0]   fifo_s_data;
wire [S_CHANNEL*DATA_WIDTH-1:0]   fifo_m_data;
wire [S_CHANNEL-1:0]              fifo_m_valid;
wire [S_CHANNEL-1:0]              fifo_m_ready;
wire [S_CHANNEL-1:0]              fifo_full;
wire [S_CHANNEL-1:0]              fifo_empty;
wire [S_CHANNEL-1:0]              fifo_overflow;

genvar ch;
generate
    for (ch = 0; ch < S_CHANNEL; ch = ch + 1) begin : g_fifo
        axis_packet_fifo #(
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(FIFO_AW)
        ) dut_fifo (
            .clk      (clk),
            .rst      (rst),
            .s_data   (fifo_s_data[ch*DATA_WIDTH +: DATA_WIDTH]),
            .s_valid  (fifo_s_valid[ch]),
            .s_ready  (fifo_s_ready[ch]),
            .m_data   (fifo_m_data[ch*DATA_WIDTH +: DATA_WIDTH]),
            .m_valid  (fifo_m_valid[ch]),
            .m_ready  (fifo_m_ready[ch]),
            .full     (fifo_full[ch]),
            .empty    (fifo_empty[ch]),
            .overflow (fifo_overflow[ch]),
            .level    ()
        );
    end
endgenerate

wire [DATA_WIDTH-1:0] arb_tdata;
wire                  arb_tvalid;
wire                  arb_tready;
wire [0:0]            arb_channel;

ssi_axis_arbiter #(
    .S_CHANNEL(S_CHANNEL),
    .DATA_WIDTH(DATA_WIDTH)
) dut_arbiter (
    .clk           (clk),
    .rst           (rst),
    .s_valid       (fifo_m_valid),
    .s_ready       (fifo_m_ready),
    .s_data        (fifo_m_data),
    .m_data        (arb_tdata),
    .m_valid       (arb_tvalid),
    .m_ready       (arb_tready),
    .grant_channel (arb_channel)
);

reg         enable = 1'b0;
reg         clear_error = 1'b0;
reg         init_calib_complete = 1'b0;
wire [127:0] m_axis_tdata;
wire [15:0]  m_axis_tkeep;
wire         m_axis_tlast;
reg          m_axis_tready = 1'b1;
wire         m_axis_tvalid;
wire [71:0]  m_axis_cmd_tdata;
reg          m_axis_cmd_tready = 1'b1;
wire         m_axis_cmd_tvalid;
reg  [7:0]   s_axis_sts_tdata = 8'h00;
reg          s_axis_sts_tvalid = 1'b0;
reg          s_axis_sts_tlast = 1'b0;
wire         s_axis_sts_tready;
wire         block_done;
wire [31:0]  write_addr;
wire [31:0]  block_count;
wire [7:0]   last_status;
wire         status_error;

s2mm_block_writer #(
    .BLOCK_BEATS(BLOCK_BEATS),
    .DDR_BASE_ADDR(32'h0000_0000),
    .DDR_LIMIT_ADDR(32'h0000_0080)
) dut_writer (
    .clk                 (clk),
    .rst                 (rst),
    .enable              (enable),
    .clear_error         (clear_error),
    .init_calib_complete (init_calib_complete),
    .s_axis_tdata        (arb_tdata),
    .s_axis_tvalid       (arb_tvalid),
    .s_axis_tready       (arb_tready),
    .m_axis_tdata        (m_axis_tdata),
    .m_axis_tkeep        (m_axis_tkeep),
    .m_axis_tlast        (m_axis_tlast),
    .m_axis_tready       (m_axis_tready),
    .m_axis_tvalid       (m_axis_tvalid),
    .m_axis_cmd_tdata    (m_axis_cmd_tdata),
    .m_axis_cmd_tready   (m_axis_cmd_tready),
    .m_axis_cmd_tvalid   (m_axis_cmd_tvalid),
    .s_axis_sts_tdata    (s_axis_sts_tdata),
    .s_axis_sts_tvalid   (s_axis_sts_tvalid),
    .s_axis_sts_tlast    (s_axis_sts_tlast),
    .s_axis_sts_tready   (s_axis_sts_tready),
    .block_done          (block_done),
    .write_addr          (write_addr),
    .block_count         (block_count),
    .last_status         (last_status),
    .status_error        (status_error)
);

reg [127:0] expected_data [0:7];
integer data_index = 0;
integer cmd_index = 0;
integer done_count = 0;

task fail;
    input [8*120-1:0] msg;
    begin
        $display("FAIL: %0s at %0t", msg, $time);
        $finish;
    end
endtask

function [127:0] pkt;
    input [7:0] channel_id;
    input [7:0] sample_id;
    begin
        pkt = {112'h0, channel_id, sample_id};
    end
endfunction

task push_both;
    input [127:0] ch0_data;
    input [127:0] ch1_data;
    begin
        @(posedge clk);
        if (fifo_s_ready != 2'b11) begin
            fail("fifo was not ready for paired push");
        end
        fifo_s_data[0*DATA_WIDTH +: DATA_WIDTH] <= ch0_data;
        fifo_s_data[1*DATA_WIDTH +: DATA_WIDTH] <= ch1_data;
        fifo_s_valid <= 2'b11;
        @(posedge clk);
        fifo_s_valid <= 2'b00;
        fifo_s_data <= {S_CHANNEL*DATA_WIDTH{1'b0}};
    end
endtask

always @(posedge clk) begin
    if (!rst && m_axis_cmd_tvalid && m_axis_cmd_tready) begin
        if (m_axis_cmd_tdata[22:0] != BLOCK_BEATS * 16) begin
            fail("unexpected command byte count");
        end
        if (m_axis_cmd_tdata[23] != 1'b1) begin
            fail("command increment bit was not set");
        end
        if (m_axis_cmd_tdata[30] != 1'b1) begin
            fail("command EOF bit was not set");
        end
        if (cmd_index == 0 && m_axis_cmd_tdata[63:32] != 32'h0000_0000) begin
            fail("first command address mismatch");
        end
        if (cmd_index == 1 && m_axis_cmd_tdata[63:32] != 32'h0000_0040) begin
            fail("second command address mismatch");
        end
        cmd_index = cmd_index + 1;
    end
end

always @(posedge clk) begin
    if (!rst && m_axis_tvalid && m_axis_tready) begin
        if (m_axis_tkeep != 16'hFFFF) begin
            fail("tkeep mismatch");
        end
        if (m_axis_tdata !== expected_data[data_index]) begin
            $display("Expected %032h", expected_data[data_index]);
            $display("Actual   %032h", m_axis_tdata);
            fail("stream data mismatch");
        end
        if (((data_index % BLOCK_BEATS) == BLOCK_BEATS-1) && !m_axis_tlast) begin
            fail("missing tlast on block boundary");
        end
        if (((data_index % BLOCK_BEATS) != BLOCK_BEATS-1) && m_axis_tlast) begin
            fail("early tlast");
        end
        data_index = data_index + 1;
    end
end

always @(posedge clk) begin
    if (!rst && block_done) begin
        done_count = done_count + 1;
    end
end

initial begin
    fifo_s_valid = 2'b00;
    fifo_s_data = {S_CHANNEL*DATA_WIDTH{1'b0}};

    expected_data[0] = pkt(8'h00, 8'h00);
    expected_data[1] = pkt(8'h01, 8'h00);
    expected_data[2] = pkt(8'h00, 8'h01);
    expected_data[3] = pkt(8'h01, 8'h01);
    expected_data[4] = pkt(8'h00, 8'h02);
    expected_data[5] = pkt(8'h01, 8'h02);
    expected_data[6] = pkt(8'h00, 8'h03);
    expected_data[7] = pkt(8'h01, 8'h03);

    repeat (5) @(posedge clk);
    rst <= 1'b0;

    push_both(expected_data[0], expected_data[1]);
    push_both(expected_data[2], expected_data[3]);
    push_both(expected_data[4], expected_data[5]);
    push_both(expected_data[6], expected_data[7]);

    repeat (2) @(posedge clk);
    enable <= 1'b1;
    init_calib_complete <= 1'b1;

    wait (data_index == 8);
    repeat (4) @(posedge clk);

    if (cmd_index != 2) begin
        fail("unexpected command count");
    end
    if (done_count != 2) begin
        fail("unexpected block_done count");
    end
    if (block_count != 2) begin
        fail("unexpected block_count");
    end
    if (write_addr != 32'h0000_0000) begin
        fail("unexpected write_addr after two blocks");
    end
    if (|fifo_overflow) begin
        fail("fifo overflow asserted unexpectedly");
    end

    @(posedge clk);
    s_axis_sts_tdata <= 8'h80;
    s_axis_sts_tvalid <= 1'b1;
    s_axis_sts_tlast <= 1'b1;
    @(posedge clk);
    s_axis_sts_tvalid <= 1'b0;
    s_axis_sts_tlast <= 1'b0;
    repeat (2) @(posedge clk);
    if (!status_error || last_status != 8'h80) begin
        fail("status error latch failed");
    end

    clear_error <= 1'b1;
    @(posedge clk);
    clear_error <= 1'b0;
    repeat (2) @(posedge clk);
    if (status_error) begin
        fail("status error clear failed");
    end

    $display("PASS: DDR stream path test completed");
    $finish;
end

initial begin
    #5000;
    fail("simulation timeout");
end

endmodule
