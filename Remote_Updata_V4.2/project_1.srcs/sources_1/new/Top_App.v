`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Top_App
// Description: 应用顶层模块
//              集成串口通信接口和Flash更新控制器
//////////////////////////////////////////////////////////////////////////////////
module Top_App #(
    parameter                   Sim_Flg         = 0,
    parameter                   CLK_FREQ        = 200_000_000,
    parameter                   UART_BAUD       = 1000000,
    parameter                   UART_CHECK      = 0,
    parameter [47:0]            PROG_NAME       = "Updata",
    parameter [7:0]             VERSION_MAJOR   = 8'd4,
    parameter [7:0]             VERSION_MINOR   = 8'd5,
    parameter [7:0]             VERSION_PATCH   = 8'd0,
    parameter                   Spi_Width       = 4,
    parameter                   Spi_Dsize       = Spi_Width == 1 ? 2 : 4,
    parameter                   SPI_BAUD        = 10_000_000,
    parameter                   Time_1ms        = Sim_Flg ? 20 : 20_000,
    parameter [31:0]            FLASH_WR_SADDR  = 32'h0060_0000,
    parameter [31:0]            FLASH_BLK_SIZE  = 32'h0001_0000,
    parameter [31:0]            FLASH_SEC_SIZE  = 32'h0000_1000,
    parameter [13:0]            PKG_DATA_SIZE   = 14'd4096,
    parameter [28:0]            IPROG_ADDR      = 29'h0060_0000,
    parameter [31:0]            WR_ADDR_MIN     = 32'h0060_0000,
    parameter [31:0]            WR_ADDR_MAX     = 32'h1FFF_FFFF
)(
    input                       clk_p,
    input                       clk_n,
    input                       Uart_Rx,
    output                      Uart_Tx,
    output  [3:0]               Led,
    output                      Flash_Spi_Csn,
    inout   [Spi_Dsize-1:0]     Flash_Spi_Sdio
);

//***************************************************************************
// 时钟复位
//***************************************************************************
localparam LED_HALF_CNT = CLK_FREQ / 2 - 1;

wire clk_200, clk_50, locked;

clk_wiz_0 pll (
    .clk_out1   (clk_200),
    .clk_out2   (clk_50),
    .locked     (locked),
    .clk_in1_p  (clk_p),
    .clk_in1_n  (clk_n)
);

reg [2:0] rst_rr;
wire rst;
always@(posedge clk_200) rst_rr <= {rst_rr[1:0], locked};
assign rst = ~rst_rr[2];

reg [2:0] rst_r50;
wire rst_50;
always@(posedge clk_50) rst_r50 <= {rst_r50[1:0], locked};
assign rst_50 = ~rst_r50[2];

//***************************************************************************
// LED控制
//***************************************************************************
reg [31:0] cnt;
reg [3:0]  led_reg;

always@(posedge clk_200)
if(rst) begin
    led_reg <= 4'b0011;
    cnt <= 'd0;
end else if(cnt == LED_HALF_CNT/2) begin
    led_reg[1:0] <= ~led_reg[1:0];
    cnt <= 'd0;
end else begin
    cnt <= cnt + 1'b1;
end

assign Led = led_reg;

//***************************************************************************
// 互联信号
//***************************************************************************
// 数据FIFO接口
wire        fifo_rd_en;
wire [7:0]  fifo_dout;
wire        fifo_empty;
wire        data_rdy;

// 回读数据接口
wire [7:0]  Rd_dat;
wire        Rd_dat_vld;
wire        Wr_End;
wire        last_pack;
wire        Rx_Error;
wire        Rx_Busy;

// 状态接口
wire [1:0]  work_state;
wire        wr_success;
wire        error_flag;

// 命令接口
wire        cmd_iprog;
wire [31:0] cmd_wr_saddr;
wire [31:0] cmd_iprog_addr;

// ========== 统一Flash操作接口 ==========
wire [31:0] flash_addr;
wire [7:0]  flash_wr_data;
wire [7:0]  flash_rd_data;
wire        flash_rd_valid;
wire [2:0]  flash_op_type;
wire        flash_op_req;
wire        flash_op_done;
wire        flash_wr_vld;

//***************************************************************************
// 串口通信接口模块
//***************************************************************************
Uart_Interface #(
    .Sim_Flg        (Sim_Flg),
    .CLK_FREQ       (CLK_FREQ),
    .UART_BAUD      (UART_BAUD),
    .UART_CHECK     (UART_CHECK),
    .PROG_NAME      (PROG_NAME),
    .VERSION_MAJOR  (VERSION_MAJOR),
    .VERSION_MINOR  (VERSION_MINOR),
    .VERSION_PATCH  (VERSION_PATCH),
    .WR_ADDR_MIN    (WR_ADDR_MIN),
    .WR_ADDR_MAX    (WR_ADDR_MAX),
    .DEF_WR_SADDR   (FLASH_WR_SADDR),
    .DEF_IPROG_ADDR (IPROG_ADDR)
) Uart_Interface_ins (
    .clk            (clk_200),
    .rst            (rst),
    .Uart_Rx        (Uart_Rx),
    .Uart_Tx        (Uart_Tx),
    .fifo_rd_en     (fifo_rd_en),
    .fifo_dout      (fifo_dout),
    .fifo_empty     (fifo_empty),
    .data_rdy       (data_rdy),
    .Rd_dat         (Rd_dat),
    .Rd_dat_vld     (Rd_dat_vld),
    .Wr_End         (Wr_End),
    .last_pack      (last_pack),
    .Rx_Error       (Rx_Error),
    .Rx_Busy        (Rx_Busy),
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
    .flash_op_done  (flash_op_done),
    .flash_wr_vld   (flash_wr_vld)
);

//***************************************************************************
// Flash更新控制器
//***************************************************************************
Flash_Update_Ctrl #(
    .Sim_Flg        (Sim_Flg),
    .CLK_FREQ       (CLK_FREQ),
    .Spi_Width      (Spi_Width),
    .Spi_Dsize      (Spi_Dsize),
    .SPI_BAUD       (SPI_BAUD),
    .Time_1ms       (Time_1ms),
    .FLASH_BLK_SIZE (FLASH_BLK_SIZE),
    .FLASH_SEC_SIZE (FLASH_SEC_SIZE),
    .PKG_DATA_SIZE  (PKG_DATA_SIZE),
    .WR_ADDR_MIN    (WR_ADDR_MIN),
    .WR_ADDR_MAX    (WR_ADDR_MAX)
) Flash_Update_Ctrl_ins (
    .clk            (clk_200),
    .rst            (rst),
    // 固件更新数据接口
    .fifo_rd_en     (fifo_rd_en),
    .fifo_dout      (fifo_dout),
    .fifo_empty     (fifo_empty),
    .data_rdy       (data_rdy),
    .Rd_dat         (Rd_dat),
    .Rd_dat_vld     (Rd_dat_vld),
    .Wr_End         (Wr_End),
    .last_pack      (last_pack),
    // .Rx_Error       (Rx_Error),
    .Rx_Busy        (Rx_Busy),
    .cmd_wr_saddr   (cmd_wr_saddr),
    // 统一Flash操作接口
    .flash_addr     (flash_addr),
    .flash_wr_data  (flash_wr_data),
    .flash_rd_data  (flash_rd_data),
    .flash_rd_valid (flash_rd_valid),
    .flash_op_type  (flash_op_type),
    .flash_op_req   (flash_op_req),
    // .flash_op_ack   (flash_op_ack),
    .flash_op_done  (flash_op_done),
    .flash_wr_vld   (flash_wr_vld),
    // 状态输出
    .work_state     (work_state),
    .wr_success     (wr_success),
    .error_flag     (error_flag),
    // Flash物理接口
    .Flash_Spi_Csn  (Flash_Spi_Csn),
    .Flash_Spi_Sdio (Flash_Spi_Sdio)
);

//***************************************************************************
// 		热启动控制
//***************************************************************************
reg iprog_cmd_reg;

always@(posedge clk_200)
if(rst)
    iprog_cmd_reg <= 1'b0;
else if(cmd_iprog)
    iprog_cmd_reg <= 1'b1;

reg		[31:0]	Iprog_cnt;
always@(posedge clk_200)
	if(rst)
		Iprog_cnt <= 'd0;
	else if(iprog_cmd_reg)
		Iprog_cnt <= Iprog_cnt == 'd200_000_000 ? Iprog_cnt:Iprog_cnt + 1'b1;
	else 
		Iprog_cnt <= Iprog_cnt;

ICAPE2_CTRL ICAPE2_CTRL_ins (
    .Clk        (clk_50),
    .Rst        (rst_50),
    .Iprog      (Iprog_cnt == 'd200_000_000),
    .Warm_Baddr (cmd_iprog_addr),
    .Ready      ()
);

endmodule
