`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Uart_Interface
// Description: 串口通信顶层模块
//              集成串口收发、命令响应、固件包接收功能
//              对外提供统一的Flash操作接口
//////////////////////////////////////////////////////////////////////////////////
module Uart_Interface #(
    parameter                   Sim_Flg         = 0,
    parameter                   CLK_FREQ        = 200_000_000,
    parameter                   UART_BAUD       = 1000000,
    parameter                   UART_CHECK      = 0,
    parameter [47:0]            PROG_NAME       = "Updata",
    parameter [7:0]             VERSION_MAJOR   = 8'd1,
    parameter [7:0]             VERSION_MINOR   = 8'd0,
    parameter [7:0]             VERSION_PATCH   = 8'd0,
    parameter [31:0]            WR_ADDR_MIN     = 32'h0060_0000,
    parameter [31:0]            WR_ADDR_MAX     = 32'h1FFE_0000,
    parameter [31:0]            DEF_WR_SADDR    = 32'h0060_0000,
    parameter [28:0]            DEF_IPROG_ADDR  = 29'h0060_0000
)(
    input                       clk,
    input                       rst,
    
    // 串口物理接口
    input                       Uart_Rx,
    output                      Uart_Tx,
    
    // 固件包数据FIFO接口
    output                      fifo_rd_clk,
    input                       fifo_rd_en,
    output  [7:0]               fifo_dout,
    output                      fifo_empty,
    output                      data_rdy,
    
    // 回读数据接口
    input   [7:0]               Rd_dat,
    input                       Rd_dat_vld,
    input                       Wr_End,
    output                      last_pack,
    output                      Rx_Error,
    output                      Rx_Busy,
    
    // 状态接口
    input   [1:0]               work_state,
    input                       wr_success,
    input                       error_flag,
    
    // 命令输出接口
    output                      cmd_iprog,
    output  [31:0]              cmd_wr_saddr,
    output  [28:0]              cmd_iprog_addr,
    
    // ========== 统一Flash操作接口 ==========
    output  [31:0]              flash_addr,
    output  [7:0]               flash_wr_data,
    input   [7:0]               flash_rd_data,
    input                       flash_rd_valid,
    output  [2:0]               flash_op_type,//1：Page写
	                                          //2：Page读 
	                                          //3: Block擦除 
    output                      flash_op_req,
    input                       flash_op_ack,
    input                       flash_op_done,
    input                       flash_wr_vld
);

localparam UART_BPS_DIV = Sim_Flg ? 32'd2 : CLK_FREQ / UART_BAUD;

// 串口收发接口
wire        Tx_Ready;
wire        Rx_Wrreq;
wire [7:0]  Rx_Wdata;

// 固件包回包
wire        pkg_Tx_Wrreq;
wire [7:0]  pkg_Tx_Wdata;

// 命令回包
wire        cmd_Tx_Wrreq;
wire [7:0]  cmd_Tx_Wdata;

//***************************************************************************
// 固件包接收模块
//***************************************************************************
Uart_pack_rx_top #(
    .Sim_Flag   (Sim_Flg)
) Uart_pack_rx_top_ins (
    .clk_200    (clk),
    .Rst        (rst),
    .rd_clk     (fifo_rd_clk),
    .fifo_rd_en (fifo_rd_en),
    .fifo_dout  (fifo_dout),
    .fifo_empty (fifo_empty),
    .Rd_dat     (Rd_dat),
    .Rd_dat_vld (Rd_dat_vld),
    .Wr_End     (Wr_End),
    .Data_rdy   (data_rdy),
    .last_pack  (last_pack),
    .Rx_Error   (Rx_Error),
    .Rx_Busy    (Rx_Busy),
    .Tx_Wrreq   (pkg_Tx_Wrreq),
    .Tx_Ready   (Tx_Ready),
    .Tx_Wdata   (pkg_Tx_Wdata),
    .Rx_Wrreq   (Rx_Wrreq),
    .Rx_Wdata   (Rx_Wdata)
);

//***************************************************************************
// 命令响应模块
//***************************************************************************
Uart_Cmd_Resp #(
    .PROG_NAME      (PROG_NAME),
    .VERSION_MAJOR  (VERSION_MAJOR),
    .VERSION_MINOR  (VERSION_MINOR),
    .VERSION_PATCH  (VERSION_PATCH),
    .DEF_WR_SADDR   (DEF_WR_SADDR),
    .DEF_IPROG_ADDR (DEF_IPROG_ADDR),
    .WR_ADDR_MIN    (WR_ADDR_MIN),
    .WR_ADDR_MAX    (WR_ADDR_MAX)
) Uart_Cmd_Resp_ins (
    .clk            (clk),
    .rst            (rst),
    .Rx_Wrreq       (Rx_Wrreq),
    .Rx_Wdata       (Rx_Wdata),
    .Tx_Wrreq       (cmd_Tx_Wrreq),
    .Tx_Wdata       (cmd_Tx_Wdata),
    .Tx_Ready       (Tx_Ready),
    .work_state     (work_state),
    .wr_success     (wr_success),
    .error_flag     (error_flag),
    .cmd_iprog      (cmd_iprog),
    .cmd_wr_saddr   (cmd_wr_saddr),
    .cmd_iprog_addr (cmd_iprog_addr),
    // 统一Flash操作接口
    .flash_addr     (flash_addr),
    .flash_wr_data  (flash_wr_data),
    .flash_rd_data  (flash_rd_data),
    .flash_rd_valid (flash_rd_valid),
    .flash_op_type  (flash_op_type),
    .flash_op_req   (flash_op_req),
    .flash_wr_vld   (flash_wr_vld),
    .flash_op_done  (flash_op_done)
    // .wr_data_next   (wr_data_next)
);

//***************************************************************************
// 发送总线仲裁
//***************************************************************************
wire        Tx_Wrreq = pkg_Tx_Wrreq ? pkg_Tx_Wrreq : cmd_Tx_Wrreq;
wire [7:0]  Tx_Wdata = pkg_Tx_Wrreq ? pkg_Tx_Wdata : cmd_Tx_Wdata;

//***************************************************************************
// 串口收发模块
//***************************************************************************
Uart_TR_Top #(
    .Wdat_Width (8),
    .Check_Mode (UART_CHECK)
) Uart_TR_Top_ins (
    .Clk        (clk),
    .Rst        (rst),
    .Uart_Bps   (UART_BPS_DIV),
    .Tx_Wrreq   (Tx_Wrreq),
    .Tx_Wdata   (Tx_Wdata),
    .Tx_Ready   (Tx_Ready),
    .Rx_Wrreq   (Rx_Wrreq),
    .Rx_Wdata   (Rx_Wdata),
    .Rs_Txd     (Uart_Tx),
    .Rs_Rxd     (Uart_Rx)
);

assign fifo_rd_clk = clk;

endmodule
