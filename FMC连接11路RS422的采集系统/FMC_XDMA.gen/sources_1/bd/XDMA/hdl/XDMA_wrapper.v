//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
//Date        : Fri Oct 17 14:40:59 2025
//Host        : DESKTOP-VQGIJDC running 64-bit major release  (build 9200)
//Command     : generate_target XDMA_wrapper.bd
//Design      : XDMA_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module XDMA_wrapper
   (BRAM_PORTA_0_addr,
    BRAM_PORTA_0_clk,
    BRAM_PORTA_0_din,
    BRAM_PORTA_0_dout,
    BRAM_PORTA_0_en,
    BRAM_PORTA_0_rst,
    BRAM_PORTA_0_we,
    BRAM_PORTB_0_addr,
    BRAM_PORTB_0_clk,
    BRAM_PORTB_0_din,
    BRAM_PORTB_0_dout,
    BRAM_PORTB_0_en,
    BRAM_PORTB_0_rst,
    BRAM_PORTB_0_we,
    axi_aclk_0,
    axi_aresetn_0,
    pcie_mgt_0_rxn,
    pcie_mgt_0_rxp,
    pcie_mgt_0_txn,
    pcie_mgt_0_txp,
    sys_clk_0,
    sys_rst_n_0,
    user_lnk_up_0,
    usr_irq_ack_0,
    usr_irq_req_0);
  output [12:0]BRAM_PORTA_0_addr;
  output BRAM_PORTA_0_clk;
  output [127:0]BRAM_PORTA_0_din;
  input [127:0]BRAM_PORTA_0_dout;
  output BRAM_PORTA_0_en;
  output BRAM_PORTA_0_rst;
  output [15:0]BRAM_PORTA_0_we;
  input [31:0]BRAM_PORTB_0_addr;
  input BRAM_PORTB_0_clk;
  input [127:0]BRAM_PORTB_0_din;
  output [127:0]BRAM_PORTB_0_dout;
  input BRAM_PORTB_0_en;
  input BRAM_PORTB_0_rst;
  input [15:0]BRAM_PORTB_0_we;
  output axi_aclk_0;
  output axi_aresetn_0;
  input [3:0]pcie_mgt_0_rxn;
  input [3:0]pcie_mgt_0_rxp;
  output [3:0]pcie_mgt_0_txn;
  output [3:0]pcie_mgt_0_txp;
  input sys_clk_0;
  input sys_rst_n_0;
  output user_lnk_up_0;
  output [0:0]usr_irq_ack_0;
  input [0:0]usr_irq_req_0;

  wire [12:0]BRAM_PORTA_0_addr;
  wire BRAM_PORTA_0_clk;
  wire [127:0]BRAM_PORTA_0_din;
  wire [127:0]BRAM_PORTA_0_dout;
  wire BRAM_PORTA_0_en;
  wire BRAM_PORTA_0_rst;
  wire [15:0]BRAM_PORTA_0_we;
  wire [31:0]BRAM_PORTB_0_addr;
  wire BRAM_PORTB_0_clk;
  wire [127:0]BRAM_PORTB_0_din;
  wire [127:0]BRAM_PORTB_0_dout;
  wire BRAM_PORTB_0_en;
  wire BRAM_PORTB_0_rst;
  wire [15:0]BRAM_PORTB_0_we;
  wire axi_aclk_0;
  wire axi_aresetn_0;
  wire [3:0]pcie_mgt_0_rxn;
  wire [3:0]pcie_mgt_0_rxp;
  wire [3:0]pcie_mgt_0_txn;
  wire [3:0]pcie_mgt_0_txp;
  wire sys_clk_0;
  wire sys_rst_n_0;
  wire user_lnk_up_0;
  wire [0:0]usr_irq_ack_0;
  wire [0:0]usr_irq_req_0;

  XDMA XDMA_i
       (.BRAM_PORTA_0_addr(BRAM_PORTA_0_addr),
        .BRAM_PORTA_0_clk(BRAM_PORTA_0_clk),
        .BRAM_PORTA_0_din(BRAM_PORTA_0_din),
        .BRAM_PORTA_0_dout(BRAM_PORTA_0_dout),
        .BRAM_PORTA_0_en(BRAM_PORTA_0_en),
        .BRAM_PORTA_0_rst(BRAM_PORTA_0_rst),
        .BRAM_PORTA_0_we(BRAM_PORTA_0_we),
        .BRAM_PORTB_0_addr(BRAM_PORTB_0_addr),
        .BRAM_PORTB_0_clk(BRAM_PORTB_0_clk),
        .BRAM_PORTB_0_din(BRAM_PORTB_0_din),
        .BRAM_PORTB_0_dout(BRAM_PORTB_0_dout),
        .BRAM_PORTB_0_en(BRAM_PORTB_0_en),
        .BRAM_PORTB_0_rst(BRAM_PORTB_0_rst),
        .BRAM_PORTB_0_we(BRAM_PORTB_0_we),
        .axi_aclk_0(axi_aclk_0),
        .axi_aresetn_0(axi_aresetn_0),
        .pcie_mgt_0_rxn(pcie_mgt_0_rxn),
        .pcie_mgt_0_rxp(pcie_mgt_0_rxp),
        .pcie_mgt_0_txn(pcie_mgt_0_txn),
        .pcie_mgt_0_txp(pcie_mgt_0_txp),
        .sys_clk_0(sys_clk_0),
        .sys_rst_n_0(sys_rst_n_0),
        .user_lnk_up_0(user_lnk_up_0),
        .usr_irq_ack_0(usr_irq_ack_0),
        .usr_irq_req_0(usr_irq_req_0));
endmodule
