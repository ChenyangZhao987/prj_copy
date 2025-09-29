`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 2025/09/17 11:34:47
// Design Name: zcy
// Module Name: sys_ctrl_cfg_reg
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
module SSI_interface#(
	parameter			RX_SIZE		=	16,	//分辨率
						CLK_T		=	5,	//输入时钟周期
						SDA_CTRL	=	0	//发送时钟周期0 ： 62.5KHz  1： 125KHz		2：
)(
	input						Phy_Clk,
	input						Phy_Rst,
	output	reg					Ssclk,
	input						Ssda,
	output	reg	[RX_SIZE-1:0]	Data_out,
	output	reg					Data_flag
);

/*******************************************************************************
// 				复位同步 信号同步
*******************************************************************************/	
reg			[2:0]		Phy_Rst1;
always@(posedge Phy_Clk)
	Phy_Rst1 <= {Phy_Rst1[1:0],Phy_Rst};
	
wire	r_rst;
assign r_rst = Phy_Rst1[2];

reg			[2:0]		sda;
always@(posedge Phy_Clk)sda <= {sda[1:0],Ssda};
wire					s_sda;
assign s_sda = sda[2];
/*******************************************************************************
// 				接收状态机  
*******************************************************************************/
wire	[10:0]		CNT_MAX	;
assign CNT_MAX = SDA_CTRL == 0 ? 660 : 16000 ;

localparam				IDLE	=3'd0,//空闲
						START	=3'd1,//起始状态第一个Ssclk周期
						T_DV	=3'd2,//t_DV数据有效时间等待（16ns）
						RX_RDAT	=3'd3,//接收数据
						TP_WIAT	=3'd4;//死区时间
						
wire		[15:0]			DEAD_T;
wire		[11:0]			STAT_T;
assign DEAD_T	=	( 'd53_000 / CLK_T ) + 1	;		//	
assign STAT_T	=	( CNT_MAX / CLK_T );

(* MARK_DEBUG="true" *)reg			[2:0]		rx_state;
(* MARK_DEBUG="true" *)reg			[15:0]		rev_cnt;
(* MARK_DEBUG="true" *)reg			[5:0]		bit_cnt;
(* MARK_DEBUG="true" *)reg			[15:0]		rate_cnt;
(* MARK_DEBUG="true" *)reg			[20:0]		nop_cnt;										
always@(posedge Phy_Clk)
	if(r_rst)begin
		rx_state <= IDLE;
	end else begin
		case(rx_state)
			IDLE	:	rx_state <= START;
			START	:	rx_state <= rev_cnt == (STAT_T - 1) ? T_DV	: START;
			T_DV	:	rx_state <= rate_cnt == 'd2 ? RX_RDAT : T_DV;
			RX_RDAT	:	rx_state <= bit_cnt == RX_SIZE 	? TP_WIAT : RX_RDAT;
			TP_WIAT	:	rx_state <= nop_cnt == DEAD_T 	? IDLE : TP_WIAT;
			default	:	rx_state <= IDLE;
		endcase
	end

/*******************************************************************************
// 				接收开始
*******************************************************************************/	
always @(posedge Phy_Clk)
    if(r_rst)begin
		rev_cnt<='d0;
	end else if(rx_state==START)begin
		rev_cnt<=rev_cnt+1'b1;
	end else begin
		rev_cnt<='d0;
	end
	
/*******************************************************************************
// 				发送时钟
*******************************************************************************/
(* MARK_DEBUG="true" *)reg			[12:0]		scl_cnt;
always @(posedge Phy_Clk)
    if(r_rst)begin
		Ssclk <= 1'b0;
		scl_cnt <= 'd0;
	end else if(rx_state != TP_WIAT )begin
		Ssclk 	<= scl_cnt == 'd1  ? ~Ssclk : Ssclk;
		scl_cnt <= scl_cnt == ((CNT_MAX/CLK_T)/2)-1'b1 ?'d0		: scl_cnt + 1'b1;
	end else begin
		Ssclk <= 1'b0;
		scl_cnt <= 'd0;
	end

reg			[2:0]		sclk;
always@(posedge Phy_Clk)sclk <= {sclk[1:0],Ssclk};
wire				neg_scl;
assign neg_scl = ~sclk[1] & sclk[2];

/*******************************************************************************
//  		接收数据计数器
*******************************************************************************/
always @(posedge Phy_Clk)
    if(r_rst)begin
        bit_cnt<='d0;
    end else if(rx_state==RX_RDAT)begin
        bit_cnt<=	neg_scl	? bit_cnt+1'b1 : bit_cnt;
    end else begin
        bit_cnt<='d0;
	end	

always @(posedge Phy_Clk)
    if(r_rst)begin
        rate_cnt<='d0;
    end else if(rx_state==T_DV)begin
        rate_cnt<=	rate_cnt+1'b1 ;
    end else begin
        rate_cnt<='d0;
	end	

/*******************************************************************************
// 			 移位寄存
*******************************************************************************/	
reg [RX_SIZE-1:0]	 r_shift_data;
always @(posedge Phy_Clk)
    if(r_rst)begin
        r_shift_data<='d0;
    end else if(rx_state==IDLE)begin
        r_shift_data<='d0;
    end else if(rx_state==RX_RDAT && neg_scl)begin
        r_shift_data<={r_shift_data[RX_SIZE-2:0],s_sda};
    end else begin
        r_shift_data<=r_shift_data;
	end	
	
/*******************************************************************************
//  		数据输出
*******************************************************************************/	
always @(posedge Phy_Clk)
    if(r_rst)begin	
		Data_out <= 'd0;
		Data_flag <= 1'b0;
	end else  if(rx_state==TP_WIAT)begin
		Data_out  <= nop_cnt == 'd1 ? r_shift_data	: 	Data_out;
		Data_flag <= nop_cnt == 'd2 ? 1'b1			:	1'b0;
	end else begin
		Data_out <= Data_out;
		Data_flag <= 1'b0;
	end
		
/*******************************************************************************
//  		死区时间
*******************************************************************************/	
always @(posedge Phy_Clk)
    if(r_rst)begin
		nop_cnt	<='d0;
    end else if(rx_state== TP_WIAT)begin
        nop_cnt <= nop_cnt+1'b1;
    end else begin
		nop_cnt <='d0;
	end		
	
/*******************************************************************************
// 				end                                                         
*******************************************************************************/
endmodule