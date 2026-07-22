`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/02/07 14:04:34
// Design Name: 
// Module Name: Uart_pack_rx_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module Uart_pack_rx_top#(
	parameter					Sim_Flag	=	0
)(		
	input						clk_200,
	input						Rst,
	//fifo
	input						rd_clk,
	input						fifo_rd_en,
	output			[7:0]		fifo_dout,
	output						fifo_empty,
	//读出数据
	input			[7:0]		Rd_dat,
	input						Rd_dat_vld,
	input						Wr_End,//操作结束
	// output 		reg	[15:0]		Frm_Nmb,//当前接收包序�?
	output						Data_rdy,
	output		reg				last_pack,
	output		reg				Rx_Error,		//	接收错误标志（脉冲，持续1个周期）
	output						Rx_Busy,		//	固件包接收忙标志（DATA/EOF阶段为高�?
	//单包数据有效
	output		reg				Tx_Wrreq,		
	output		reg	[7:0]		Tx_Wdata,
	input						Tx_Ready,
	input						Rx_Wrreq,
	input			[7:0]		Rx_Wdata	
);
/**************************************************************************
//			复位同步
***************************************************************************/
reg				[2:0]		rrst;
always@(posedge clk_200)rrst <= {rrst[1:0],Rst};

assign	rst = rrst[2];
/**************************************************************************
//			接收主状态机
***************************************************************************/
reg				[3:0]			rx_state;
wire			[12:0]			fifo_rd_count;
reg				[15:0]			r_pack_head;
reg				[15:0]			Len_data;
reg				[15:0]			Frm_Nmb;
reg								r_pack_head_vld;
reg								head_flag;
reg				[15:0]			timeout_cnt;
reg								error;
reg								crc_ok;
reg				[7:0]			err_black;
reg								data_rdy;
reg								pack_head_cnt;
reg								fifo_rst;
reg								fifo_wr_en;
reg				[15:0]			len_cnt;

localparam  					IDLE	='d0,
								NUMB	='d1,
								LEN		='d2,
								DATA	='d3,
								EOF		='d4,
								OVER	='d5,
								ERROR	='d6;

localparam						TIME_OUT	=	20000;
localparam						PACK_HADE	=	16'h55AA;

always@(posedge clk_200)
	if(rst)begin
		rx_state <= IDLE;
		Frm_Nmb <= 'd0; 
		len_cnt <= 'd0;
		data_rdy <= 1'b0;
		fifo_wr_en <= 'd0;
		timeout_cnt <= 'd0;
		fifo_rst <= 1'b0;
		error <= 1'b0;
		Rx_Error <= 1'b0;
	end else case(rx_state)
		IDLE 		:	begin	
							rx_state <= head_flag ? NUMB : IDLE;
							fifo_rst <= 1'b0;	
							timeout_cnt <= 'd0;
							data_rdy <= 1'b0;
							error <= 1'b0;
							len_cnt <= 'd0;
							Rx_Error <= 1'b0;
							Frm_Nmb <= Frm_Nmb == Len_data ? 'd0 : Frm_Nmb;
						end
		NUMB		:	if(r_pack_head_vld)
							rx_state <= r_pack_head == Frm_Nmb ? LEN : ERROR;
						else
							rx_state <=  NUMB;
		LEN 		:	rx_state <= r_pack_head_vld ? DATA : LEN;
		DATA		:	if(Rx_Wrreq)begin
							fifo_wr_en <= 1'b1;
							data_rdy <= 1'b0;
							if(len_cnt == 'd4096 - 1'b1)begin
								rx_state <= EOF;
								len_cnt <= 'd0;
							end else begin
								len_cnt <= len_cnt + 1'b1;
							end
						end else begin
							fifo_wr_en <= 1'b0;
							fifo_rst <= fifo_rst;
							error <= 1'b0;	
						end
		
		EOF			:	if(timeout_cnt == TIME_OUT)begin//10us内没有接受到包尾认为数据无效，丢掉数据，生成错误标志
							rx_state <= ERROR;
							error <= 1'b1;
							timeout_cnt <= 'd0;
							fifo_wr_en <= 1'b0;
							fifo_rst <= 1'b1;
						end else begin
							fifo_wr_en <= 1'b0;
							rx_state <=  (crc_ok ? OVER : EOF);
							fifo_rst <= fifo_rst;
							error <= 1'b0;
							timeout_cnt <= timeout_cnt + 1;
						end
						
		OVER		:	begin
							Frm_Nmb <= Wr_End ? Frm_Nmb + 1'b1 : Frm_Nmb;
							rx_state <= Wr_End ? IDLE : OVER;
							data_rdy <= 1'b1;
						end
		ERROR		:	begin
							fifo_rst <= 1'b1;
							rx_state <= IDLE;
							Rx_Error <= 1'b1;	// 错误脉冲（一拍），下个周期进IDLE后清0
						end		
						
		default		:	rx_state <= IDLE;
	endcase

// DATA �? EOF 阶段为忙：此期间固件数据正在流入FIFO，禁止命令模块干�?
assign Rx_Busy = (rx_state != IDLE) || (tx_state != IDLE);

/**************************************************************************
//			发�?�主状�?�机
***************************************************************************/	
reg		[2:0]		tx_state;
wire				tx_fifo_empty;
reg					tx_fifo_rd;
wire	[12:0]		tx_fifo_rd_count;
reg		[2:0]		pol_cnt;
wire	[7:0]		tx_fifo_dout;
reg		[7:0]		tx_crc_reg;
reg		[15:0]		frm_tx;

reg		[2:0]		Uart_rdy;
wire				Uart_txdone;

always@(posedge clk_200)Uart_rdy <= {Uart_rdy[1:0],Tx_Ready};

assign Uart_txdone = ~Uart_rdy[2] & Uart_rdy[1];

always@(posedge clk_200)	
	if(rst)begin
		tx_state <= 0;
		pol_cnt <= 0;
		frm_tx <= 0;
		tx_crc_reg <= 0;
		Tx_Wrreq <= 0;
		tx_fifo_rd <= 1'd0;
	end else case(tx_state)
		0		:	begin
						tx_state <= tx_fifo_rd_count >= 'd4096-1 ? 1 : 0;
						tx_fifo_rd <= 1'd0;
						pol_cnt <= 1'd0;
						frm_tx <= frm_tx;
						tx_crc_reg <= 0;
						Tx_Wrreq <= 1'd0;
						Tx_Wdata <= 'd0;
					end	
		1		:	begin
						tx_state <= Uart_txdone ? 2 : 1;
						tx_fifo_rd <= 1'd0;
						frm_tx <= frm_tx;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : pol_cnt + 1) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= 'h55;
					end
		2		:	begin
						tx_state <= Uart_txdone ? 3 : 2;
						tx_fifo_rd <= 1'd0;
						frm_tx <= frm_tx;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : pol_cnt + 1) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= 'hAA;	
					end
		3		:	begin
						tx_state <= Uart_txdone ? 4 : 3;
						tx_fifo_rd <= 1'd0;
						frm_tx <= frm_tx;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : pol_cnt + 1) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= frm_tx[15:8];
					end 
		4		:	begin
						tx_state <= Uart_txdone ? 5 : 4;
						tx_fifo_rd <= 1'd0;
						frm_tx <= frm_tx;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : pol_cnt + 1) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= frm_tx[7:0];
					end 
		5		:	begin
						tx_state <= Uart_txdone ? 6 : 5;
						tx_fifo_rd <= 1'd0;
						frm_tx <= frm_tx;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : pol_cnt + 1) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= err_black;
					end 
		6		:	begin
						tx_state <= tx_fifo_empty && Tx_Ready  ? 7 : 6;//&& Uart_txdone
						tx_fifo_rd <= pol_cnt == 1 ? 1'b1 : 1'd0;
						Tx_Wrreq <= pol_cnt == 3 ? 1'b1:1'd0;
						frm_tx <= frm_tx;	
						Tx_Wdata <= Sim_Flag ? 'hA5 : tx_fifo_dout;
						tx_crc_reg <= pol_cnt == 3 ? tx_crc_reg ^ tx_fifo_dout : tx_crc_reg;
						if(tx_fifo_empty)
							pol_cnt <= 'd0;
						else 
							pol_cnt <= Tx_Ready ? pol_cnt + 1'b1: 'd0;
					end 
		7		:	begin
						tx_state <= Uart_txdone ? 0 : 7;
						frm_tx <= pol_cnt == 'd2 ? frm_tx + 1 : frm_tx;
						tx_fifo_rd <= 1'd0;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
						Tx_Wdata <= tx_crc_reg;
						tx_crc_reg <= tx_crc_reg;
						pol_cnt <= Uart_txdone ? 'd0 :  (pol_cnt== 7 ?  pol_cnt : (Tx_Ready ? pol_cnt + 1'b1: 'd0)) ;
						Tx_Wrreq <=pol_cnt == 'd2 ? 1'b1 : 1'b0;
					end
		default	:		tx_state <=  'd0;
	endcase

/**************************************************************************
//			发�?�FIFO
***************************************************************************/
fifo_8x8192  tx_fifo_bitdata_ins(
  .rst(rst),     	 	  // input wire rst
  .wr_clk				(clk_200				),                // input wire wr_clk
  .rd_clk				(clk_200				),                // input wire rd_clk
  .din					(Rd_dat					),                      // input wire [7 : 0] din
  .wr_en				(Rd_dat_vld				),                  // input wire wr_en
  .rd_en				(tx_fifo_rd				),                  // input wire rd_en
  .dout					(tx_fifo_dout			),                    // output wire [7 : 0] dout
  .full					(						),                    // output wire full
  .empty				(tx_fifo_empty			),                  // output wire empty
  .rd_data_count		(tx_fifo_rd_count		),  			// output wire [12 : 0] rd_data_count
  .wr_rst_busy			(						),      // output wire wr_rst_busy
  .rd_rst_busy			(						)      // output wire rd_rst_busy
);
/**************************************************************************
//			错误处理
***************************************************************************/
reg							err_black_vld;

always@(posedge clk_200)
	if(rst)begin
		err_black <= 'h5A;
		err_black_vld <= 'd0;
	end else case(rx_state)
		OVER	:	begin err_black <='h5A;err_black_vld <= Wr_End ? 'd1 : 'b0;  end
		ERROR	:	begin err_black <='hFF;err_black_vld <= 'd1;  end
		default	:	begin err_black <=err_black; err_black_vld <= 'd0; end
	endcase
/**************************************************************************
//			校验
***************************************************************************/
reg		[7:0]		crc_reg;

always@(posedge clk_200)
	if(rst)begin
		crc_reg <= 'd0;
		crc_ok <= 'd0;
	end else case(rx_state)
		IDLE	:	begin crc_reg <= 'd0;	crc_ok <= 'd0;end
		EOF		:	begin crc_reg <= crc_reg; crc_ok <= Rx_Wrreq ? (crc_reg == Rx_Wdata ? 'd1 : 'd0) : crc_ok;end	// 收到CRC字节后锁存结果，不被Rx_Wrreq=0清掉
		OVER	:	begin crc_reg <= 'd0; 	crc_ok <= 'd0;end
		ERROR	:	begin crc_reg <= 'd0;	crc_ok <= 'd0;end
		NUMB,LEN:	begin crc_reg <= 'd0;	crc_ok <= 'd0;end
		default	:	begin crc_reg <= Rx_Wrreq ? crc_reg ^ Rx_Wdata : crc_reg; crc_ok <= 'd0;end
	endcase

/**************************************************************************
//			包头/尾检�?
***************************************************************************/

always@(posedge clk_200)
	if(rst)begin
		r_pack_head <= 'd0;
		r_pack_head_vld <= 1'b0;
		pack_head_cnt <= 'd0;
	end else case(rx_state)
		IDLE	:	begin
					if(Rx_Wrreq)begin
						r_pack_head <= {r_pack_head[7:0],Rx_Wdata};
						pack_head_cnt <= Rx_Wdata == 'h55 ?	'd1 : 'd0 ;
						r_pack_head_vld <= pack_head_cnt == 'd1 ? 'd1 : 1'b0;
					end else begin
						r_pack_head <= r_pack_head;
						r_pack_head_vld <= 1'b0;
						pack_head_cnt <= pack_head_cnt;
					end
				end
		NUMB,LEN	:	begin
					if(Rx_Wrreq)begin
						r_pack_head <= {r_pack_head[7:0],Rx_Wdata};
						pack_head_cnt <= pack_head_cnt == 'd1 ?	 'd0: pack_head_cnt + 1'b1 ;
						r_pack_head_vld <= pack_head_cnt == 'd1 ? 'd1 : 1'b0;
					end else begin
						r_pack_head <= r_pack_head;
						r_pack_head_vld <= 1'b0;
						pack_head_cnt <= pack_head_cnt;
					end
				end	
		default		:begin	
						r_pack_head <= r_pack_head;
						r_pack_head_vld <= 1'b0;
						pack_head_cnt <= pack_head_cnt;
				end
	endcase

always@(posedge clk_200)
	if(rst)begin
		head_flag <= 'd0;
	end else if(rx_state == IDLE && r_pack_head_vld && r_pack_head == PACK_HADE)begin
		head_flag <= 'd1;
	end else begin
		head_flag <= 'd0;
	end
	
always@(posedge clk_200)
	if(rst)begin
		Len_data <= 'h1000;
	end else if(rx_state == LEN && r_pack_head_vld)begin
		Len_data <= r_pack_head;
	end else begin
		Len_data <= Len_data;
	end
always@(posedge clk_200)
	if(rst)begin
		last_pack <= Sim_Flag ? 1'b1 : 1'b0;
	end else if(Frm_Nmb == Len_data - 1'b1)begin
		last_pack <= 1;
	end else begin
		last_pack <= Sim_Flag ? 1'b1 : 1'b0;
	end
/**************************************************************************
//			仿真数据
***************************************************************************/
reg		[7:0]	Data_test;
reg		[20:0]	Data_test_cnt;
reg				Data_test_vld;
wire	start0 = 0;	

always@(posedge clk_200)
	if(rst)begin
		Data_test <= 'd0;
		Data_test_cnt <= 'd0;
		Data_test_vld <= 'd0;
	end else if(Sim_Flag)begin
		if(Data_test_vld)begin
			Data_test_vld <= 'd0;
		end else //if(Data_test_cnt > 'd255 && Data_test_cnt <= 'd8192 + 'd255)begin
			Data_test_vld <= 'd1;
		//end
		Data_test <= (Data_test_cnt[7:0]=='hFF)&&(Data_test_vld) ? Data_test + 1 : Data_test;
		Data_test_cnt <= Data_test_vld ? Data_test_cnt + 1 : ((Data_test_cnt <= 'd255 && (start0 | Sim_Flag) ) ? Data_test_cnt + 1: Data_test_cnt);//&& (start0) 
	end else begin
		Data_test <= 'd0;
		Data_test_cnt <= 'd0;
		Data_test_vld <= 'd0;
	end


assign	Data_rdy = Sim_Flag ? (fifo_rd_count >= 'd4096) : data_rdy;
/**************************************************************************
//			FIFO(数据足够才能�?)
***************************************************************************/
fifo_8x8192  fifo_bitdata_ins(
  .rst					(rst||fifo_rst							),     	 	  // input wire rst
  .wr_clk				(clk_200								),                // input wire wr_clk
  .rd_clk				(rd_clk									),                // input wire rd_clk
  .din					(Sim_Flag ? Data_test : Rx_Wdata		),                      // input wire [7 : 0] din
  .wr_en				(Sim_Flag ? Data_test_vld : fifo_wr_en	),                  // input wire wr_en
  .rd_en				(fifo_rd_en								),                  // input wire rd_en
  .dout					(fifo_dout								),                    // output wire [7 : 0] dout
  .full					(										),                    // output wire full
  .empty				(fifo_empty								),                  // output wire empty
  .rd_data_count		(fifo_rd_count							),  // output wire [12 : 0] rd_data_count
  .wr_rst_busy			(										),      // output wire wr_rst_busy
  .rd_rst_busy			(										)      // output wire rd_rst_busy
);
/**************************************************************************
//			Debug
***************************************************************************/
ila_top ila_data_ins (
	.clk(clk_200), // input wire clk
	.probe0			({'d0,fifo_rd_count,r_pack_head,len_cnt,Rx_Wrreq,Rx_Wdata,pol_cnt,rx_state,error,r_pack_head_vld,head_flag,fifo_wr_en,fifo_rst}), // input wire [31:0]  probe0  
	.probe1			({'d0,tx_crc_reg,Wr_End,crc_reg,Frm_Nmb,Data_test,Data_test_vld,fifo_rd_en,fifo_dout}), // input wire [31:0]  probe1
	.probe2			({'d0,timeout_cnt,tx_state,Tx_Wrreq,tx_fifo_empty,tx_fifo_rd,tx_fifo_rd_count,tx_fifo_dout,last_pack,crc_ok}) // input wire [31:0]  probe1
);
/**************************************************************************
//			end
***************************************************************************/	
endmodule