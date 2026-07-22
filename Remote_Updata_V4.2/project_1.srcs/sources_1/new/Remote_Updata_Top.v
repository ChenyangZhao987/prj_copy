`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 16:45:07
// Design Name: 
// Module Name: Remote_Updata_Top
// Project Name: 
// Target Devices: xc7k325tffg900-2
// Flash: S25FL256S
// Tool Versions: Vivado 2022.1
// Description: Flash远程固件更新控制器顶层模块
//              支持UART协议接收固件包并写入SPI Flash
//              写入完成后通过ICAPE2触发热启动
// 
// Dependencies: Spi_Flash_Ctrl, Uart_pack_rx_top, Uart_TR_Top, ICAPE2_CTRL
// 
// Revision:
// Revision 0.01 - File Created
// Revision 0.02 - 参数化重构，提升可配置性
// Additional Comments:
// 
//  关键参数说明：
//   CLK_FREQ      : 系统主时钟频率(Hz)，由PLL输出决定，默认200MHz
//   UART_BAUD     : 串口波特率，默认3_000_000
//   UART_CHECK    : 串口校验模式，0无校验，1奇校验，2偶校验
//   SPI_BAUD      : SPI时钟频率(Hz)，默认10MHz
//   Spi_Width     : SPI数据线宽度，1=标准SPI，4=Quad SPI
//   FLASH_WR_SADDR: 固件写入Flash起始地址(字节对齐)
//   FLASH_BLK_SIZE: Block擦除大小(64KB)，用于判断擦除模式
//   FLASH_SEC_SIZE: Sector擦除大小(4KB)
//   PKG_PAGE_NUM  : 每包数据对应的Page写入次数(1Page=256B，4096B/256B=16)
//   PKG_DATA_SIZE : FIFO中每包有效数据量(字节)
//   IPROG_ADDR    : 热启动跳转地址(写入WBSTAR寄存器)
//
//////////////////////////////////////////////////////////////////////////////////
module Remote_Updata_Top#(
	parameter					Sim_Flg			=	0,				//	仿真模式标志，1=仿真
	//时钟
	parameter					CLK_FREQ		=	200_000_000,	//	主时钟频率(Hz)
	//串口
	parameter					UART_BAUD		=	1000000,			//	串口波特率(最高1M)
	parameter					UART_CHECK		=	0,				//	校验模式:0无校验,1奇校验,2偶校验
	//Flash/SPI参数
	parameter					Spi_Width		=	4,				//	SPI数据线宽,1=标准,4=Quad
	parameter					Spi_Dsize		=	Spi_Width == 1 ? 2 : 4,	//	SPI IO引脚数，自动计算
	parameter					SPI_BAUD		=	10_000_000,		//	SPI时钟频率(Hz)
	parameter					Time_1ms		=	Sim_Flg ? 20 : 20_000,	//	1ms对应时钟周期数(200MHz)
	//Flash地址参数
	parameter					FLASH_WR_SADDR	=	32'h0060_0000,	//	默认固件写入Flash起始地址
	parameter					FLASH_BLK_SIZE	=	32'h0001_0000,	//	Block擦除大小(64KB)
	parameter					FLASH_SEC_SIZE	=	32'h0000_1000,	//	Sector擦除大小(4KB)
	//写入参数
	parameter					PKG_DATA_SIZE	=	13'd4096,		//	FIFO中每包有效数据量(字节)
	//热启动
	parameter					IPROG_ADDR		=	29'h0060_0000,	//	默认热启动跳转地址(WBSTAR)
	//版本号
	parameter	[7:0]			VERSION_MAJOR	=	8'd03,			//	主版本号
	parameter	[7:0]			VERSION_MINOR	=	8'd01,			//	次版本号
	parameter	[7:0]			VERSION_PATCH	=	8'd02,			//	修订版本号
	//地址保护
	parameter	[31:0]			WR_ADDR_MIN		=	32'h0060_0000,	//	允许写入起始地址（含）
	parameter	[31:0]			WR_ADDR_MAX		=	32'h1FFE_0000	//	允许写入结束地址（不含）
)(
	input						clk_p, clk_n,					//	差分时钟输入
	input						Uart_Rx,						//	串口接收
	output						Uart_Tx,						//	串口发送
	output			reg[3:0]	Led,							//	心跳LED
	output						Flash_Spi_Csn,					//	Flash片选(低有效)
	inout		[Spi_Dsize-1:0]	Flash_Spi_Sdio				//	Flash SPI数据总线
);
/**************************************************************************
//			时钟复位
***************************************************************************/
// 时钟频率参数
localparam					LED_HALF_CNT	= CLK_FREQ / 2 - 1;		//	LED闪烁半周期计数值
localparam					UART_BPS_DIV	= Sim_Flg ? 32'd2 : CLK_FREQ / UART_BAUD;	//	串口分频系数
localparam					IPROG_DLY		=	11'd2000;		//	热启动触发延迟周期数
localparam					PKG_PAGE_NUM	=	PKG_DATA_SIZE / 'd256;			//	每包Page写入次数(4096B/256B=16)

wire				clk_200;
wire				clk_50;
wire				locked;
wire				F_SPI_SCK;

clk_wiz_0 pll(
    .clk_out1		(clk_200	),		// output clk_out1
	.clk_out2		(clk_50		),		// output clk_out2
    .locked			(locked		),		// output locked
	.clk_in1_p		(clk_p		),		// input  clk_in1_p
    .clk_in1_n		(clk_n		)		// input  clk_in1_n
);

reg		[2:0]		rst_rr;
wire				rst;
always@(posedge clk_200) rst_rr <= {rst_rr[1:0], locked};
assign	rst = ~rst_rr[2];

reg		[2:0]		rst_r50;
wire				rst_50;
always@(posedge clk_50) rst_r50 <= {rst_r50[1:0], locked};
assign	rst_50 = ~rst_r50[2];

/**************************************************************************
//			LED
***************************************************************************/
reg		[31:0]		cnt;
always@(posedge clk_200)
	if(rst)begin
		Led[3]	<= 1'b0;
		Led[2:0] <= 3'b011;
		cnt	<= 'd0;
	end else if(cnt == LED_HALF_CNT/2)begin
		Led[3:2] <= Led[3:2];
		Led[1:0] <=~Led[1:0];
		cnt	<= 'd0;
	end else begin
		cnt	<= cnt + 1'b1;
		Led	<= Led;
	end

/**************************************************************************
//				地址计算
//  说明：
//   r_saddr  : 当前包对应的Page写/读起始地址，4KB对齐
//   br_saddr : 当前包对应的Block擦除起始地址，64KB对齐
//  地址空间关系：
//   FLASH_WR_SADDR < FLASH_BLK_SIZE 时，直接从Sector擦除起始
//   FLASH_WR_SADDR >= FLASH_BLK_SIZE 时，启用Block擦除模式
//   FLASH_WR_SADDR为固件写入起始地址，Frm_Nmb为当前包序号(0-base)
***************************************************************************/
reg		[15:0]		Frm_Nmb;					//	当前写入包序号(0-base)
reg		[10:0]		ber_cnt;					//	Block擦除计数(64KB递增)

wire	[31:0]		r_saddr		= {(cmd_wr_saddr[31:12] + Frm_Nmb), 12'd0};	//	4KB对齐写入地址
wire	[31:0]		br_saddr	= {(cmd_wr_saddr[31:16] + ber_cnt), 16'd0};	//	64KB对齐擦除地址

/**************************************************************************
//				数据写入状态机
//  状态说明：
//   IDLE       : 等待串口数据就绪
//   INIT_START : Flash初始化，等待FIFO数据量满足一包要求
//   ERASE      : 执行擦除操作
//                  r_saddr < FLASH_BLK_SIZE: Sector擦除(4KB,类型2)
//                  r_saddr >= FLASH_BLK_SIZE: Block擦除(64KB,类型3)
//   WRITE      : 执行Page写入(每次256B，共PKG_PAGE_NUM次)
//   READ       : 执行Page回读校验(每次256B，共PKG_PAGE_NUM次)
//   WR_DONE    : 单包完成，判断是否为最后一包
***************************************************************************/
reg		[2:0]		state;
localparam			IDLE		= 3'd0,
					INIT_START	= 3'd1,
					ERASE		= 3'd2,
					WRITE		= 3'd3,
					READ		= 3'd4,
					WR_DONE		= 3'd5;

wire	[12:0]		flash_rd_count;				//	Flash内部FIFO数据量
reg		[2:0]		pol_cnt;					//	命令有效延迟计数

//命令操作接口
wire				Flash_C_rdy;				//	Flash控制器就绪
reg					Start_Inital;				//	启动Flash初始化
reg					Flash_C_Val;				//	命令有效脉冲
reg		[2:0]		Flash_C_Type;				//	操作类型:0写/1读/2Sector擦/3Block擦
reg		[13:0]		Flash_C_Num;				//	操作次数(从1开始)
reg		[31:0]		Flash_C_Saddr;				//	操作起始地址
wire				Flash_C_Cmplt;				//	操作完成标志
wire				last_pack;					//	最后一包标志
wire	[23:0]		Spi_C_Op_Num;				//	已操作次数

//数据接收
wire				data_rdy;					//	串口数据就绪(FIFO满一包)
reg					Wr_End;						//	单包写入结束脉冲
wire				Rx_Error;					//	串口接收错误脉冲

// wr_cnt: 跟踪首包是否已在目标地址擦除过(FLASH_WR_SADDR >= FLASH_BLK_SIZE时有效)
// 初始值PKG_PAGE_NUM，每完成一包Wr_End减1，减到0时归回PKG_PAGE_NUM
// 等于初始值PKG_PAGE_NUM时说明新Block边界，需重新擦除
reg		[7:0]		wr_cnt;
always@(posedge clk_200)
	if(rst)
		wr_cnt	<= PKG_PAGE_NUM;
	else if(wr_cnt == 'd0)
		wr_cnt	<= PKG_PAGE_NUM;
	else
		wr_cnt	<= Wr_End ? wr_cnt - 1'b1 : wr_cnt;

always@(posedge clk_200)
	if(rst)
		Frm_Nmb	<= 'd0;
	else if(Wr_End)
		Frm_Nmb	<= Frm_Nmb + 1'b1;
	else
		Frm_Nmb	<= Frm_Nmb;

always@(posedge clk_200)
	if(rst)begin
		state			<= IDLE;
		pol_cnt			<= 'd0;
		Wr_End			<= 1'b0;
		Flash_C_Val		<= 1'b0;
		ber_cnt			<= 'b0;
		Start_Inital	<= 1'b0;
		Flash_C_Type	<= 'd0;
		Flash_C_Num		<= 'd0;
		Flash_C_Saddr	<= 'h0;
	end else case(state)
		IDLE		:	begin
							state			<= data_rdy ? INIT_START : IDLE;
							Flash_C_Val		<= 1'b0;
							Start_Inital	<= 1'b0;
							Flash_C_Type	<= 'd0;
							Wr_End			<= 1'b0;
							Flash_C_Num		<= 'd0;
							pol_cnt			<= 'd0;
							Flash_C_Saddr	<= 'h0;
						end

		INIT_START	:	begin
							//	r_saddr >= FLASH_BLK_SIZE 时判断当前Block是否已擦除
							if(r_saddr >= FLASH_BLK_SIZE)
								state	<= (Flash_C_rdy && flash_rd_count >= PKG_DATA_SIZE) ?
										   (wr_cnt == PKG_PAGE_NUM ? ERASE : WRITE) : INIT_START;
							else
								state	<= (Flash_C_rdy && flash_rd_count >= PKG_DATA_SIZE) ?
										   ERASE : INIT_START;
							Flash_C_Val		<= 1'b0;
							Start_Inital	<= 1'b1;
							Wr_End			<= 1'b0;
							Flash_C_Type	<= 'd0;
							Flash_C_Num		<= 'd0;
							pol_cnt			<= 'd0;
							Flash_C_Saddr	<= r_saddr;
						end

		ERASE		:	begin
							state			<=  Flash_C_Cmplt ? WRITE : ERASE;
							Flash_C_Val		<= pol_cnt == 'd2 ? 1'b1 : 1'b0;
							Start_Inital	<= 1'b0;
							//	起始地址 >= FLASH_BLK_SIZE：Block擦除，否则Sector擦除
							Flash_C_Type	<= r_saddr >= FLASH_BLK_SIZE ? 'd3 : 'd2;
							Wr_End			<= 1'b0;
							Flash_C_Num		<= 'd1;
							if(Flash_C_Cmplt)begin
								pol_cnt	<= 'd0;
								ber_cnt	<= r_saddr >= FLASH_BLK_SIZE ? ber_cnt + 1'b1 : ber_cnt;
							end else begin
								pol_cnt	<= pol_cnt == 'd3 ? pol_cnt : pol_cnt + 1;
							end
							//	Block擦除用64KB对齐地址，Sector擦除用4KB对齐地址
							Flash_C_Saddr	<= r_saddr >= FLASH_BLK_SIZE ? br_saddr : r_saddr;
						end

		WRITE		:	begin
							state			<=  Flash_C_Cmplt ? READ : WRITE;
							Wr_End			<= 1'b0;
							Flash_C_Val		<= pol_cnt == 'd2 ? 1'b1 : 1'b0;
							Start_Inital	<= 1'b0;
							Flash_C_Type	<= 'd0;				//	Page写
							Flash_C_Num		<= PKG_PAGE_NUM;	//	每包16个Page(4096B)
							if(Flash_C_Cmplt)
								pol_cnt	<= 'd0;
							else
								pol_cnt	<= pol_cnt == 'd3 ? pol_cnt : pol_cnt + 1;
							Flash_C_Saddr	<= r_saddr;
						end

		READ		:	begin
							state			<=  Flash_C_Cmplt ? WR_DONE : READ;
							Flash_C_Val		<= pol_cnt == 'd2 ? 1'b1 : 1'b0;
							Start_Inital	<= 1'b0;
							Flash_C_Type	<= 'd1;				//	Page读
							Wr_End			<= 1'b0;
							Flash_C_Num		<= PKG_PAGE_NUM;
							if(Flash_C_Cmplt)
								pol_cnt	<= 'd0;
							else
								pol_cnt	<= pol_cnt == 'd3 ? pol_cnt : pol_cnt + 1;
							Flash_C_Saddr	<= r_saddr;
						end

		WR_DONE		:	begin
							state			<= last_pack ? IDLE : INIT_START;
							Flash_C_Val		<= 1'b0;
							Start_Inital	<= 1'b0;
							Wr_End			<= 1'b1;
							Flash_C_Type	<= 'd0;
							Flash_C_Num		<= 'd0;
							pol_cnt			<= 'd0;
							Flash_C_Saddr	<= Flash_C_Saddr;
						end
		default		:	state <= IDLE;
	endcase

/**************************************************************************
//				状态标志寄存器（供串口命令回包使用）
//  wr_success_flag : 全部包写入并回读校验完成后置1，下次IDLE清0
//  error_flag_r    : 任意错误发生时置1，下次IDLE清0
***************************************************************************/
reg					wr_success_flag;
reg					error_flag_r;

always@(posedge clk_200)
	if(rst)begin
		wr_success_flag	<= 1'b0;
		error_flag_r	<= 1'b0;
	end else begin
		// 错误脉冲置位
		if(Rx_Error)
			error_flag_r	<= 1'b1;
		// 新一轮更新开始时清除上次标志
		if(state == IDLE && data_rdy)begin
			wr_success_flag	<= 1'b0;
			error_flag_r	<= 1'b0;
		end
		// 最后一包完成，更新成功
		if(state == WR_DONE && last_pack)
			wr_success_flag	<= 1'b1;
	end

/**************************************************************************
//				FIFO数据转移
//  说明：INIT_START状态下将Uart_pack_rx_top的输出FIFO数据
//        搬运至Spi_Flash_Ctrl内部写入FIFO
//        采用乒乓读写方式：读使能高->下周期写使能高
***************************************************************************/
reg					fifo_wr_en;
wire	[7:0]		fifo_wrdata;

reg					fifo_rd_en;
wire	[7:0]		fifo_dout;
wire				fifo_empty;

always@(posedge clk_200)
	if(rst)
		fifo_rd_en	<= 1'b0;
	else if(state == INIT_START)begin
		if(fifo_rd_en)
			fifo_rd_en	<= 1'b0;
		else if(~fifo_empty)
			fifo_rd_en	<= 1'b1;
	end else
		fifo_rd_en	<= 1'b0;

always@(posedge clk_200)
	if(rst)
		fifo_wr_en	<= 1'b0;
	else
		fifo_wr_en	<= fifo_rd_en;		//	时序对齐：读使能延迟一拍后写

assign fifo_wrdata = fifo_dout;

/**************************************************************************
//				Flash控制器
***************************************************************************/
wire	[7:0]	Rd_dat;
wire			Rd_dat_vld;

Spi_Flash_Ctrl#(
	.Sim_Flg			(Sim_Flg		),
	.Spi_Width			(Spi_Width		),
	.Time_1ms			(Time_1ms		),
	.SPI_BAUD			(SPI_BAUD		)
)Spi_Flash_Ctrl_ins(
	.Clk				(clk_200		),
	.Rst				(rst			),
	.Start_Inital		(Start_Inital	),
	.Flash_Rd_dat		(Rd_dat			),
	.Flash_Rd_dat_vld	(Rd_dat_vld		),
	.fifo_wr_clk		(clk_200		),
	.fifo_wr_en			(fifo_wr_en		),
	.fifo_wrdata		(fifo_wrdata	),
	.fifo_rd_count		(flash_rd_count	),
	//命令操作接口
	.Flash_C_rdy		(Flash_C_rdy	),
	.Flash_C_Val		(Flash_C_Val	),
	.Flash_C_Type		(Flash_C_Type	),	//	0:Page写 1:Page读 2:Sector擦 3:Block擦
	.Flash_C_Num		(Flash_C_Num	),
	.Flash_C_Saddr		(Flash_C_Saddr	),
	.Flash_C_Cmplt		(Flash_C_Cmplt	),
	.Flash_Flash_Id		(				),
	.Spi_C_Op_Num		(Spi_C_Op_Num	),
	//Flash物理端口
	.F_SPI_CS			(Flash_Spi_Csn	),
	.Flash_Spi_Sdio		(Flash_Spi_Sdio	),
	.F_SPI_SCK			(F_SPI_SCK		)
);

/*******************************************************************************
//				串口接收打包模块
*******************************************************************************/
wire				pkg_Tx_Wrreq;			//	固件包回包写请求
wire				Tx_Ready;
wire	[7:0]		pkg_Tx_Wdata;			//	固件包回包数据
wire				Rx_Wrreq;
wire	[7:0]		Rx_Wdata;

Uart_pack_rx_top#(
	.Sim_Flag			(Sim_Flg		)
)Uart_pack_rx_top_ins(
	.clk_200			(clk_200		),
	.Rst				(rst			),
	//fifo
	.rd_clk				(clk_200		),
	.fifo_rd_en			(fifo_rd_en		),
	.fifo_dout			(fifo_dout		),
	.fifo_empty			(fifo_empty		),
	//回读数据
	.Rd_dat				(Sim_Flg ? 8'h12 : Rd_dat	),
	.Rd_dat_vld			(Rd_dat_vld		),
	.last_pack			(last_pack		),
	.Data_rdy			(data_rdy		),
	.Wr_End				(Wr_End			),
	//串口数据接口
	.Tx_Wrreq			(pkg_Tx_Wrreq	),
	.Tx_Ready			(Tx_Ready		),
	.Tx_Wdata			(pkg_Tx_Wdata	),
	.Rx_Wrreq			(Rx_Wrreq		),
	.Rx_Wdata			(Rx_Wdata		),
	.Rx_Error			(Rx_Error		),
	.Rx_Busy			(Rx_Busy		)
);

/**************************************************************************
//			串口命令回包模块
//  监听同一串口接收数据流，识别AA 55命令包后回复状态和版本号
//  发送总线优先级：固件包回包 > 命令回包
//  固件包DATA/EOF阶段 Rx_Busy=1，命令接收状态机被强制复位屏蔽
***************************************************************************/
wire				cmd_Tx_Wrreq;			//	命令回包写请求
wire	[7:0]		cmd_Tx_Wdata;			//	命令回包数据
wire				Rx_Busy;				//	固件包接收忙标志
wire				cmd_iprog;				//	命令触发热启动脉冲
wire	[31:0]		cmd_wr_saddr;			//	命令设置的固件写入起始地址
wire	[28:0]		cmd_iprog_addr;			//	命令设置的热启动跳转地址

Uart_Cmd_Resp#(
	.VERSION_MAJOR		(VERSION_MAJOR	),
	.VERSION_MINOR		(VERSION_MINOR	),
	.VERSION_PATCH		(VERSION_PATCH	),
	.DEF_WR_SADDR		(FLASH_WR_SADDR	),	//	默认写入地址由顶层参数传入
	.DEF_IPROG_ADDR		(IPROG_ADDR		),	//	默认热启动地址由顶层参数传入
	.WR_ADDR_MIN		(WR_ADDR_MIN	),	//	允许写入起始地址
	.WR_ADDR_MAX		(WR_ADDR_MAX	)	//	允许写入结束地址
)Uart_Cmd_Resp_ins(
	.clk				(clk_200		),
	.rst				(rst			),
	.busy_rst			(Rx_Busy		),	//	固件包接收忙时强制复位命令接收状态机
	//接收通道（与Uart_pack_rx_top共享串口接收数据流）
	.Rx_Wrreq			(Rx_Wrreq		),
	.Rx_Wdata			(Rx_Wdata		),
	//发送通道
	.Tx_Wrreq			(cmd_Tx_Wrreq	),
	.Tx_Wdata			(cmd_Tx_Wdata	),
	.Tx_Ready			(Tx_Ready		),
	//状态输入
	.work_state			(state[1:0]		),
	.wr_success			(wr_success_flag),
	.error_flag			(error_flag_r	),
	//命令输出
	.cmd_iprog			(cmd_iprog		),
	.cmd_wr_saddr		(cmd_wr_saddr	),
	.cmd_iprog_addr		(cmd_iprog_addr	)
);

//  发送总线仲裁：固件包回包优先，命令回包次之
wire				Tx_Wrreq	= pkg_Tx_Wrreq ? pkg_Tx_Wrreq : cmd_Tx_Wrreq;
wire	[7:0]		Tx_Wdata	= pkg_Tx_Wrreq ? pkg_Tx_Wdata : cmd_Tx_Wdata;

/**************************************************************************
//			串口收发接口
***************************************************************************/
Uart_TR_Top#(
	.Wdat_Width			(8				),
	.Check_Mode			(UART_CHECK		)
)Uart_TR_Top_ins(
	.Clk				(clk_200		),
	.Rst				(rst			),
	.Uart_Bps			(UART_BPS_DIV	),	//	串口分频系数
	.Tx_Wrreq			(Tx_Wrreq		),
	.Tx_Wdata			(Tx_Wdata		),
	.Tx_Ready			(Tx_Ready		),
	.Rx_Wrreq			(Rx_Wrreq		),
	.Rx_Wdata			(Rx_Wdata		),
	.Rs_Txd				(Uart_Tx		),
	.Rs_Rxd				(Uart_Rx		)
);
/**************************************************************************
//			热启动控制
//  触发来源：
//   1. 固件写入完成（state==WR_DONE && last_pack）：延迟IPROG_DLY周期后触发
//   2. 串口命令CMD=0x02（cmd_iprog脉冲）：立即触发（无延迟）
//  跳转地址：cmd_iprog_addr（由串口命令动态设置，默认值=IPROG_ADDR参数）
***************************************************************************/
reg		[10:0]	Iprog_cnt;
reg				Iprog;
	
always@(posedge clk_200)
	if(rst)
		Iprog_cnt	<= 11'd0;
	else if(state == WR_DONE && last_pack)
		Iprog_cnt	<= 11'd1;
	else if(Iprog_cnt >= 'd1)
		Iprog_cnt	<= Iprog_cnt + 1'b1;
	else
		Iprog_cnt	<= 11'd0;

reg	iprog;
always@(posedge clk_200)
	if(rst)begin
		iprog <= 1'b0; 
	end else if(cmd_iprog)begin
		iprog <= 1'b1; 
	end else begin
		iprog <= iprog;
	end

// 两种触发合并：固件完成延迟触发 OR 命令立即触发

always@(posedge clk_50) begin
	Iprog <= (Iprog_cnt >= IPROG_DLY) || iprog;
end 


ICAPE2_CTRL(
	.Clk			(clk_50			),	//	不得高于100MHz
	.Rst			(rst_50			),
	.Iprog			(Iprog			),	//	触发指示，上升沿有效
	.Warm_Baddr		(cmd_iprog_addr	),	//	热启动跳转地址（动态，默认=IPROG_ADDR）
	.Ready			(				)
);

/**************************************************************************
//			SPI时钟引脚
***************************************************************************/
(* keep = "true" *) wire unused_startupe;
(* keep = "true" *) STARTUPE2 #(
	.PROG_USR		("FALSE"	),
	.SIM_CCLK_FREQ	(0.0		)
) STARTUPE2_inst (
	.CFGCLK			(			),
	.CFGMCLK		(			),
	.EOS			(unused_startupe),
	.PREQ			(			),
	.CLK			(1'b0		),
	.GSR			(1'b0		),
	.GTS			(1'b0		),
	.KEYCLEARB		(1'b1		),
	.PACK			(1'b1		),
	.USRCCLKO		(F_SPI_SCK	),	//	用户SPI时钟
	.USRCCLKTS		(1'b0		),
	.USRDONEO		(1'b1		),
	.USRDONETS		(1'b1		)
);

/**************************************************************************
//				Debug
***************************************************************************/
ila_top ila_top_ins (
	.clk	(clk_200),
	.probe0	({'b0, Frm_Nmb, fifo_rd_en, fifo_dout, fifo_wr_en, fifo_wrdata, pol_cnt}),
	.probe1	({'b0, wr_cnt, state, data_rdy, Flash_C_rdy, Flash_C_Cmplt, flash_rd_count, Rd_dat_vld, Rd_dat}),
	.probe2	({'b0, r_saddr})
);

/**************************************************************************
//				end
***************************************************************************/
endmodule
