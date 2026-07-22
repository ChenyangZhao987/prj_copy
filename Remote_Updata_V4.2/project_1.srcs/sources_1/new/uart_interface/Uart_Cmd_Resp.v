`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Uart_Cmd_Resp
// Description: 串口命令接收与回包
//   统一帧格式: AA 55 CMD [ADDR[4]] [DATA[N]] CRC
//
//   命令定义:
//   0x01: 查询状态
//   0x02: 热启动
//   0x03: 设置写入地址
//   0x04: 设置热启动地址
//   0x05: 64KB擦除
//   0x06: 内部验证（擦除→写递增数→读验证）
//   0x07: 写Page(256B)
//   0x08: 读Page(256B)
//////////////////////////////////////////////////////////////////////////////////
module Uart_Cmd_Resp #(
	parameter	[47:0]	PROG_NAME		=	"GOLDEN",
	parameter	[7:0]	VERSION_MAJOR	=	8'h03,
	parameter	[7:0]	VERSION_MINOR	=	8'h19,
	parameter	[7:0]	VERSION_PATCH	=	8'd0,
	parameter	[31:0]	DEF_WR_SADDR	=	32'h0060_0000,
	parameter	[28:0]	DEF_IPROG_ADDR	=	29'h0060_0000,
	parameter	[31:0]	WR_ADDR_MIN		=	32'h0060_0000,
	parameter	[31:0]	WR_ADDR_MAX		=	32'h1FFF_FF00
)(
	input				clk,
	input				rst,
	// UART接口
	input				Rx_Wrreq,
	input		[7:0]	Rx_Wdata,
	output	reg			Tx_Wrreq,
	output	reg	[7:0]	Tx_Wdata,
	input				Tx_Ready,
	// 状态输入
	input		[1:0]	work_state,
	input				wr_success,
	input				error_flag,
	// 固件更新控制
	output	reg			cmd_iprog,
	output	reg	[31:0]	cmd_wr_saddr,
	output	reg	[28:0]	cmd_iprog_addr,
	// ========== 统一Flash操作接口 ==========
	output	reg	[31:0]	flash_addr,			// 操作地址
	output	reg	[7:0]	flash_wr_data,		// 写入数据
	input		[7:0]	flash_rd_data,		// 读取数据
	input				flash_rd_valid,		// 读数据有效
	output	reg	[2:0]	flash_op_type,		// 操作类型:	
	output	reg			flash_op_req,		// 操作请求
	// input				flash_op_ack,		// 请求已接收
	input				flash_op_done,		// 操作完成（整Page）
	output	reg			flash_wr_vld		// 
);

/***************************************************************
//						接收状态机
***************************************************************/
localparam				IDLE	='d0,
						RX_55	='d1,
						RX_CMD	='d2,
						RX_ADDR	='d3,
						RX_DATA ='d4,
						RX_CRC	='d5,
						RX_WAIT	='d6;		// 等待发送完成状态
						
reg			[2:0]		rx_state;
reg			[7:0]		cmd_reg;
reg			[7:0]		crc_reg;
reg			[31:0]		addr_reg;
reg			[31:0]		timeout_cnt;
reg			[10:0]		pol_cnt;

always@(posedge clk)
	if(rst)begin
		rx_state <= IDLE;
		addr_reg <= 'd600000;
		flash_wr_vld <= 'd0;
		flash_wr_data <= 'd0;
		timeout_cnt <= 'd0;
		pol_cnt	<= 'd0;
		cmd_reg <= 'd1;
		crc_reg	<= 'd0;
	end else case(rx_state)
		IDLE	:	begin
						rx_state <= (Rx_Wrreq && Rx_Wdata == 'hAA) ? RX_55 : IDLE;
						flash_wr_vld <= 1'b0 ;
						cmd_reg <= cmd_reg;
						crc_reg	<= (Rx_Wrreq && Rx_Wdata == 'hAA)? 'hAA : 'd0;
					end
		RX_55 	:	begin
						if(Rx_Wrreq && Rx_Wdata == 'h55)begin
							rx_state <= RX_CMD;
							crc_reg	<= Rx_Wdata ^ crc_reg;
						end else if(Rx_Wrreq)begin
							rx_state <= Rx_Wdata == 'hAA ? RX_55 : IDLE;
							crc_reg	<= crc_reg;
						end
					end
					
		RX_CMD	:	begin
						if(Rx_Wrreq)begin
							cmd_reg <= Rx_Wdata;
							timeout_cnt <= 'd0;
							crc_reg	<= Rx_Wdata ^ crc_reg;
							case(Rx_Wdata)
								1,2	:	rx_state <= RX_CRC;
								3,4,5,6,7,8	:	rx_state <= RX_ADDR;
								default	:	rx_state <= IDLE;
							endcase
						end else if(timeout_cnt >= 'd20000)begin
							rx_state <= IDLE;
							timeout_cnt <= 'd0;
							crc_reg <= 'd0;
						end else begin
							timeout_cnt <= timeout_cnt + 1'b1;
						end
					end
					
		RX_ADDR	:	begin
						if(Rx_Wrreq)begin
							addr_reg <= {addr_reg[23:0],Rx_Wdata};
							crc_reg	<= Rx_Wdata ^ crc_reg;
							timeout_cnt <= 'd0;
							rx_state <=  pol_cnt == 'd3 ?  (cmd_reg == 'd7 ? RX_DATA : RX_CRC) : RX_ADDR;
							pol_cnt <= pol_cnt == 'd3 ? 'd0 : pol_cnt + 1;
						end else if(timeout_cnt >= 'd20000)begin
							rx_state <= IDLE;
							timeout_cnt <= 'd0;
							crc_reg <= 'd0;
						end else begin
							timeout_cnt <= timeout_cnt + 1'b1;
						end
					end	
					
		RX_DATA	:	begin
						if(Rx_Wrreq)begin
							flash_wr_vld <= 1'b1 ;
							rx_state <=  pol_cnt == 'd255 ? RX_CRC : RX_DATA;
							flash_wr_data <= Rx_Wdata;
							crc_reg	<= Rx_Wdata ^ crc_reg;
							pol_cnt<= pol_cnt == 'd255 ? 'd0 : pol_cnt + 1;
						end else begin
							flash_wr_vld <= 1'b0 ;
							pol_cnt<= pol_cnt;
							flash_wr_data <= flash_wr_data;
						end
					end
					
		RX_CRC 	:	begin
						crc_reg	<= crc_reg;
						flash_wr_vld <= 1'b0 ;
						// 接收完CRC后跳转到WAIT状态，等待发送完成
						rx_state <= Rx_Wrreq ? (crc_reg == Rx_Wdata ? RX_WAIT:IDLE) : RX_CRC;
					end
					
		RX_WAIT :	begin
						// 等待发送状态机完全完成（IDLE状态），在此期间不接收新命令
						rx_state <= (tx_state == TX_CRC) ? IDLE : RX_WAIT;
					end
					
		default	:	rx_state <= IDLE;
	endcase
			
/***************************************************************
//						指令处理
***************************************************************/
wire	crc_ok  = (rx_state == RX_CRC && Rx_Wrreq &&crc_reg == Rx_Wdata);
wire	addr_ok = (addr_reg >= WR_ADDR_MIN && addr_reg < WR_ADDR_MAX);
reg  [7:0]	data_reg [0:255];
reg	 [10:0]	tx_cnt;
reg			[3:0] 	tx_state;
reg	[7:0]		ack_reg;
reg			ack_flag;
reg	[7:0]		active_cmd;		// 当前正在处理的命令，在响应触发时锁存

//上电自动发送
reg		[10:0]	power_on_cnt;
always@(posedge clk)
	if(rst)begin
		power_on_cnt <= 'd0;
	end else begin
		power_on_cnt <= power_on_cnt == 'd50 ? power_on_cnt : power_on_cnt + 1;
	end
wire			power_on = (power_on_cnt == 'd49);

always@(posedge clk)
	if(rst)begin
		ack_flag <= 1'b0;
		ack_reg <= 'hFF;
		cmd_iprog <= 1'b0;
		cmd_wr_saddr <= 'h600000;
		cmd_iprog_addr <= 'h600000;
		flash_addr <= 'd0;
		flash_op_req <= 'd0;
		flash_op_type <= 'd0;//1：Page写
		                     //2：Page读 
		                     //3: Block擦除
		tx_cnt <= 'd0;       // 初始化计数器
		active_cmd <= 'd0;   // 初始化当前处理命令
	end else begin
		// 使用cmd_reg进行命令处理，但在触发响应时锁存到active_cmd
		case(cmd_reg)
		1	:	begin
					// 只在命令接收完成或上电时触发响应，发送过程中不触发
					if(tx_state == IDLE && (rx_state == RX_WAIT || power_on))begin
						ack_flag <= 1'b1;
						active_cmd <= cmd_reg;  // 锁存当前命令
					end
					ack_reg <= crc_ok ? 'h5A:ack_reg;
				end

		2	:	begin
					cmd_iprog <= crc_ok ? 1'b1 : 1'b0;
					if(tx_state == IDLE && rx_state == RX_WAIT)begin
						ack_flag <= 1'b1;
						active_cmd <= cmd_reg;
					end
					ack_reg <= crc_ok ? 'h5A:ack_reg;
				end
		3	:	begin
					cmd_wr_saddr <= crc_ok && addr_ok ? addr_reg : cmd_wr_saddr;
					if(tx_state == IDLE && rx_state == RX_WAIT)begin
						ack_flag <= 1'b1;
						active_cmd <= cmd_reg;
					end
					ack_reg <= crc_ok ? 'h5A:ack_reg;
				end
		4	:	begin
					cmd_iprog_addr <= crc_ok && addr_ok? addr_reg : cmd_iprog_addr;
					if(tx_state == IDLE && rx_state == RX_WAIT)begin
						ack_flag <= 1'b1;
						active_cmd <= cmd_reg;
					end
					ack_reg <= crc_ok ? 'h5A:ack_reg;
				end
		5	:	begin
					// 使用边沿检测，只在crc_ok第一次为真时赋值
					if(crc_ok)begin
						flash_addr <= addr_reg;
						flash_op_req <= addr_ok ?1'b1 : 1'b0;
						flash_op_type <= 'd3;
						active_cmd <= cmd_reg;	// 在CRC校验通过时立即锁存命令
					end else begin
						flash_op_req <= 1'b0;
					end
					if(tx_state == IDLE && flash_op_done)begin
						ack_flag <= 1'b1;
					end
					ack_reg <= flash_op_done ? 'h5A:ack_reg;
				end
				
		6	:	begin
					//保留
				end
				
		7	:	begin
					// 使用边沿检测，只在crc_ok第一次为真时赋值
					if(crc_ok)begin
						flash_addr <= addr_reg;
						flash_op_req <= addr_ok ? 1'b1 : 1'b0;
						flash_op_type <= 'd1;
						active_cmd <= cmd_reg;	// 在CRC校验通过时立即锁存命令
					end else begin
						flash_op_req <= 1'b0;
					end
					if(tx_state == IDLE && flash_op_done)begin
						ack_flag <= 1'b1;
					end
					ack_reg <= (crc_ok && addr_ok) ? 'h5A : (crc_ok ? 'hFF : ack_reg);
				end
		8	:	begin
					// 命令接收阶段：CRC校验通过后启动Flash读取操作
					// 使用边沿检测，只在crc_ok第一次为真时赋值
					if(crc_ok )begin
						flash_addr <= addr_reg;
						flash_op_req <= addr_ok ? 1'b1 : 1'b0;
						flash_op_type <= 'd2;
						ack_reg <= addr_ok ? 'h5A : 'hFF;
						tx_cnt <= 'd0;  // 重置计数器
						active_cmd <= cmd_reg;	// 在CRC校验通过时立即锁存命令
					end else begin
						flash_op_req <= 1'b0;
					end
					// 数据读取：等待flash_rd_valid有效时存储数据
					if(flash_rd_valid && tx_cnt <= 'd255)begin
						data_reg[tx_cnt] <= flash_rd_data;
						tx_cnt <= tx_cnt + 1;
					end
					// 当读取完成256字节后，设置ack_flag触发发送（只设置一次）
					if(tx_state == IDLE && tx_cnt == 'd255 && flash_rd_valid)begin
						ack_flag <= 1'b1;
					end
					// 在新命令开始时重置状态
					if(rx_state == RX_CMD)begin
						tx_cnt <= 'd0;
						ack_flag <= 1'b0;
					end
				end
		default	:begin	flash_op_req <= 1'b0;ack_reg <= 'hFF;end
	endcase
	// 发送状态机正在工作时清除ack_flag，防止重复发送
	if(tx_state != IDLE)
		ack_flag <= 1'b0;
end

/***************************************************************
//						发送状态机
***************************************************************/
localparam 			TX_AA	=1,
					TX_55	=2,
					TX_CMD	=3,
					TX_INFO	=4,
					TX_ACK	=5,
					TX_DATA =6,
					TX_CRC 	=7;


reg			[7:0] 	tx_crc_reg;

reg		[2:0]		Uart_rdy;
reg		[2:0]		pal_cnt;
wire				Uart_txdone;

always@(posedge clk)Uart_rdy <= {Uart_rdy[1:0],Tx_Ready};

assign Uart_txdone = ~Uart_rdy[2] & Uart_rdy[1];

reg		[7:0]		info;
reg		[10:0]		info_cnt;

always@(*)begin
	case(info_cnt)
		0	:	info = {4'd0, error_flag, wr_success, work_state};
		1	:	info = VERSION_MAJOR; 
		2   :   info = VERSION_MINOR;
		3   :   info = VERSION_PATCH;
		4   :   info = PROG_NAME[47:40];
		5   :   info = PROG_NAME[39:32];
		6   :   info = PROG_NAME[31:24];
		7   :   info = PROG_NAME[23:16];
		8   :   info = PROG_NAME[15:8];
		9   :   info = PROG_NAME[7:0];
		default	:	info = 0; 
	endcase	
end


always@(posedge clk)
	if(rst)begin
		Tx_Wrreq <= 'd0;
	    Tx_Wdata <= 'd0;
		pal_cnt <= 'd0;
		info_cnt <= 'd0;
		tx_crc_reg <= 'd0;
	end else begin
		case(tx_state)
		IDLE	:	begin
						if(ack_flag)begin
							tx_state <= TX_AA;
						end else begin
							tx_state <= IDLE;
						end
						pal_cnt <= 'd0;
						tx_crc_reg<= 'd0;
						Tx_Wdata <= 'd0;
						info_cnt <= 'd0;
						Tx_Wrreq <= 'd0;
					end
		TX_AA	:	begin
						tx_state <= Uart_txdone ? TX_55 : TX_AA;
						Tx_Wdata <= 'hAA;
						pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= 'hAA ^ tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
					end
		TX_55	:	begin
						tx_state <= Uart_txdone ? TX_CMD : TX_55;
						Tx_Wdata <= 'h55;
						pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= 'h55 ^ tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
					end
		TX_CMD	:	begin
						tx_state <= Uart_txdone ? (active_cmd == 1 ? TX_INFO : TX_ACK) : TX_CMD;
						Tx_Wdata <= active_cmd;
						pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= active_cmd ^ tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
					end
		
		TX_INFO	:	begin
						info_cnt <= Uart_txdone ? (info_cnt == 9 ? info_cnt : info_cnt + 1'b1) : info_cnt;
						Tx_Wdata <= info;
						pal_cnt <= Uart_txdone  ?  'd0  :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= Uart_txdone ? info ^ tx_crc_reg :tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
						tx_state <= Uart_txdone && info_cnt == 'd9 ? TX_CRC : TX_INFO;
					end

		TX_ACK	:	begin
						tx_state <= Uart_txdone ? (active_cmd == 8 ? TX_DATA : TX_CRC) : TX_ACK;
						Tx_Wdata <= ack_reg;
						pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= ack_reg ^ tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
					end

		TX_DATA	:	begin
						if(info_cnt == 'd256)begin
							info_cnt <= info_cnt == 'd256 ? 'd0 : info_cnt;
							tx_state <= info_cnt == 'd256 ? TX_CRC : TX_DATA;
						end else begin
							info_cnt <= Uart_txdone ? info_cnt + 1'b1 : info_cnt;
							Tx_Wdata <= data_reg[info_cnt];
							pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt== 7 ?  pal_cnt : pal_cnt + 1) ;
							tx_crc_reg <= Uart_txdone ? data_reg[info_cnt] ^ tx_crc_reg :tx_crc_reg;
							Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
						end 
					end
		
		TX_CRC	:	begin
						info_cnt <= 'd0;
						tx_state <= Uart_txdone ? IDLE : TX_CRC;
						Tx_Wdata <= tx_crc_reg;
						pal_cnt <= Uart_txdone ? 'd0 :  (pal_cnt == 7 ?  pal_cnt : pal_cnt + 1) ;
						tx_crc_reg <= tx_crc_reg;
						Tx_Wrreq <= pal_cnt == 'd2 ? 1'b1 : 1'b0;
					end
		default	:Tx_Wrreq <= 1'b0;
	endcase
end

ila_0 flash_ctrl_ila(
	.clk(clk), // input wire clk
	.probe0 ({cmd_iprog_addr}), // input wire [31:0]  probe0  
	.probe1 ({'d0,Rx_Wrreq,Rx_Wdata,Tx_Wrreq,Tx_Wdata,tx_state,rx_state}), // input wire [31:0]  probe1 
	.probe2 ({'d0,flash_wr_data,rst,cmd_reg,ack_reg}), // input wire [31:0]  probe2 
	.probe3 ({'d0,flash_rd_data,info,flash_op_req}), // input wire [31:0]  probe3 
	.probe4 ({'d0,addr_ok,flash_rd_valid,flash_wr_vld,flash_op_type,tx_crc_reg}), // input wire [31:0]  probe4 
	.probe5 ({'d0,tx_cnt,info_cnt,crc_ok,ack_flag}), // input wire [31:0]  probe5 
	.probe6 ({'d0,flash_op_done,rx_state}), // input wire [31:0]  probe6 
	.probe7 ({'d0,Tx_Ready,Uart_txdone,tx_cnt}), // input wire [31:0]  probe7 
	.probe8 ({addr_reg}) // input wire [31:0]  probe8 
);

endmodule 
