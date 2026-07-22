`timescale 1ns / 1ps

module tb_SSI_top_sim;

localparam S_CHANNEL = 2;

reg                       Pcie_rstn;
reg                       Pcie_refclkp;
reg                       Pcie_refclkn;
reg      [7:0]            Pcie_rxp;
reg      [7:0]            Pcie_rxn;
wire     [7:0]            Pcie_txp;
wire     [7:0]            Pcie_txn;

reg                       DDR_SYS_CLK_clk_p;
reg                       DDR_SYS_CLK_clk_n;
reg                       DDR_sys_rst;
wire     [14:0]           DDR3_0_addr;
wire     [2:0]            DDR3_0_ba;
wire                      DDR3_0_cas_n;
wire     [0:0]            DDR3_0_ck_n;
wire     [0:0]            DDR3_0_ck_p;
wire     [0:0]            DDR3_0_cke;
wire     [0:0]            DDR3_0_cs_n;
wire     [7:0]            DDR3_0_dm;
wire     [63:0]           DDR3_0_dq;
wire     [7:0]            DDR3_0_dqs_n;
wire     [7:0]            DDR3_0_dqs_p;
wire     [0:0]            DDR3_0_odt;
wire                      DDR3_0_ras_n;
wire                      DDR3_0_reset_n;
wire                      DDR3_0_we_n;

wire     [S_CHANNEL-1:0]  Scl;
wire     [S_CHANNEL-1:0]  Cs_n;
reg      [S_CHANNEL-1:0]  Sda;
wire     [S_CHANNEL-1:0]  RE_422;
wire     [S_CHANNEL-1:0]  DE_422;
wire     [7:0]            led;

integer                   sim_error_count;
integer                   irq_rise_count;
integer                   irq_ack_rise_count;
integer                   s2mm_beat_count;
integer                   ch_idx;
reg                       usr_irq_req_d;
reg                       usr_irq_ack_d;
reg      [63:0]           expect_data[0:S_CHANNEL-1];
reg      [3:0]            mon_ch;
reg      [63:0]           mon_data;
reg      [63:0]           mon_mark;

always #5 Pcie_refclkp = ~Pcie_refclkp;
always #5 Pcie_refclkn = ~Pcie_refclkn;
always #5 DDR_SYS_CLK_clk_p = ~DDR_SYS_CLK_clk_p;
always #5 DDR_SYS_CLK_clk_n = ~DDR_SYS_CLK_clk_n;

SSI_top #(
    .S_CHANNEL          (S_CHANNEL),
    .SIM_MODE           (1),
    .SIM_DATA_GEN       (1)
) dut (
    .Pcie_rstn          (Pcie_rstn),
    .Pcie_refclkp       (Pcie_refclkp),
    .Pcie_refclkn       (Pcie_refclkn),
    .Pcie_rxp           (Pcie_rxp),
    .Pcie_rxn           (Pcie_rxn),
    .Pcie_txp           (Pcie_txp),
    .Pcie_txn           (Pcie_txn),
    .DDR_SYS_CLK_clk_p  (DDR_SYS_CLK_clk_p),
    .DDR_SYS_CLK_clk_n  (DDR_SYS_CLK_clk_n),
    .DDR_sys_rst        (DDR_sys_rst),
    .DDR3_0_addr        (DDR3_0_addr),
    .DDR3_0_ba          (DDR3_0_ba),
    .DDR3_0_cas_n       (DDR3_0_cas_n),
    .DDR3_0_ck_n        (DDR3_0_ck_n),
    .DDR3_0_ck_p        (DDR3_0_ck_p),
    .DDR3_0_cke         (DDR3_0_cke),
    .DDR3_0_cs_n        (DDR3_0_cs_n),
    .DDR3_0_dm          (DDR3_0_dm),
    .DDR3_0_dq          (DDR3_0_dq),
    .DDR3_0_dqs_n       (DDR3_0_dqs_n),
    .DDR3_0_dqs_p       (DDR3_0_dqs_p),
    .DDR3_0_odt         (DDR3_0_odt),
    .DDR3_0_ras_n       (DDR3_0_ras_n),
    .DDR3_0_reset_n     (DDR3_0_reset_n),
    .DDR3_0_we_n        (DDR3_0_we_n),
    .Scl                (Scl),
    .Cs_n               (Cs_n),
    .Sda                (Sda),
    .RE_422             (RE_422),
    .DE_422             (DE_422),
    .led                (led)
);

initial begin
    Pcie_rstn         = 1'b0;
    Pcie_refclkp      = 1'b0;
    Pcie_refclkn      = 1'b1;
    Pcie_rxp          = 8'd0;
    Pcie_rxn          = 8'd0;
    DDR_SYS_CLK_clk_p = 1'b0;
    DDR_SYS_CLK_clk_n = 1'b1;
    DDR_sys_rst       = 1'b1;
    Sda               = {S_CHANNEL{1'b0}};
    sim_error_count   = 0;
    irq_rise_count    = 0;
    irq_ack_rise_count= 0;
    s2mm_beat_count   = 0;
    usr_irq_req_d     = 1'b0;
    usr_irq_ack_d     = 1'b0;
    for(ch_idx = 0; ch_idx < S_CHANNEL; ch_idx = ch_idx + 1)
        expect_data[ch_idx] = 64'd0;

    repeat(20) @(posedge Pcie_refclkp);
    Pcie_rstn   = 1'b1;
    DDR_sys_rst = 1'b0;

    repeat(20000) @(posedge Pcie_refclkp);
    $display("SIM DONE: usr_irq_req=%b block_count=%0d last_status=0x%02x write_addr=0x%08x ping_pang=%0d current_channel=%0d",
        dut.usr_irq_req,
        dut.s2mm_block_count,
        dut.s2mm_last_status,
        dut.s2mm_write_addr,
        dut.arb_ping_pang_sel,
        dut.current_channel
    );
    $display("SIM CHECK: irq_rise_count=%0d irq_ack_rise_count=%0d s2mm_beat_count=%0d sim_error_count=%0d",
        irq_rise_count,
        irq_ack_rise_count,
        s2mm_beat_count,
        sim_error_count
    );
    if(irq_rise_count == 0)begin
        $display("SIM ERROR: first irq did not rise after acquisition start");
        sim_error_count = sim_error_count + 1;
    end
    if(s2mm_beat_count == 0)begin
        $display("SIM ERROR: no s2mm data beat observed");
        sim_error_count = sim_error_count + 1;
    end
    if(sim_error_count == 0)
        $display("SIM PASS");
    else
        $display("SIM FAIL");
    $finish;
end

always @(posedge Pcie_refclkp) begin
    if(!Pcie_rstn)begin
        usr_irq_req_d      <= 1'b0;
        usr_irq_ack_d      <= 1'b0;
        irq_rise_count     <= 0;
        irq_ack_rise_count <= 0;
        s2mm_beat_count    <= 0;
        for(ch_idx = 0; ch_idx < S_CHANNEL; ch_idx = ch_idx + 1)
            expect_data[ch_idx] <= 64'd0;
    end else begin
        usr_irq_req_d <= dut.usr_irq_req;
        usr_irq_ack_d <= dut.usr_irq_ack;

        if(dut.usr_irq_req && !usr_irq_req_d)begin
            irq_rise_count <= irq_rise_count + 1;
            if(irq_rise_count < 8)
                $display("[%0t] IRQ rise: block_count=%0d ping_pang=%0d irq_status=0x%08x",
                    $time,
                    dut.s2mm_block_count,
                    dut.arb_ping_pang_sel,
                    dut.irq_debug_status
                );
        end

        if(dut.usr_irq_ack && !usr_irq_ack_d)begin
            irq_ack_rise_count <= irq_ack_rise_count + 1;
            if(irq_ack_rise_count < 8)
                $display("[%0t] IRQ ack", $time);
        end

        if(dut.s2mm_tvalid && dut.s2mm_tready)begin
            mon_ch   = dut.ssi_axis_arbiter_ins.transfer_channel[3:0];
            mon_mark = dut.s2mm_tdata[127:64];
            mon_data = dut.s2mm_tdata[63:0];
            s2mm_beat_count <= s2mm_beat_count + 1;
            if(mon_ch < S_CHANNEL)begin
                if(mon_mark[31:28] !== mon_ch)begin
                    $display("SIM ERROR: channel %0d id mismatch, high64=0x%016x at beat %0d",
                        mon_ch,
                        mon_mark,
                        s2mm_beat_count
                    );
                    sim_error_count = sim_error_count + 1;
                end
                if(mon_data !== expect_data[mon_ch])begin
                    $display("SIM ERROR: channel %0d data mismatch, got %0d expect %0d at beat %0d",
                        mon_ch,
                        mon_data,
                        expect_data[mon_ch],
                        s2mm_beat_count
                    );
                    sim_error_count = sim_error_count + 1;
                end
                expect_data[mon_ch] <= expect_data[mon_ch] + 1'b1;
            end else begin
                $display("SIM ERROR: invalid channel id %0d", mon_ch);
                sim_error_count = sim_error_count + 1;
            end
        end
    end
end

endmodule
