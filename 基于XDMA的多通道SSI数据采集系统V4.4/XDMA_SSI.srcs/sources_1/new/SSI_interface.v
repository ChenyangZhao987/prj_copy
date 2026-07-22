`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 2025/09/28 17:34:00
// Design Name: zcy
// Module Name: sys_ctrl_cfg_reg
// Project Name: SSI_top
// Target Devices: 
// Tool Versions: 
// Description: 模块是 SSI_top 项目的配置核心，主要功能如下：
//					1、实现了多场景下的SSI接口协议解析；
//					2、支持时钟周期参数化，增加灵活性；
//					2、发送时钟速率、接收数据位宽的动态调整；
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module SSI_interface#(
	parameter				CLK_T		=	16,	//输入时钟周期	
							DATA_TIME	=	20000
)(
	input					Phy_Clk,
	input					Phy_Rst,
	input		[2:0]		Scl_ctrl,//发送时钟周期0：12.5MHz  1： 5MHz	
	input		[7:0]		RX_SIZE,
	output	reg				Ssclk,
	output	reg				Cs_n,
	input					cs_en,
	input					Ssda,
	output	reg	[63:0]		Data_out,
	output	reg				Data_flag
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
reg		[10:0]		CNT_MAX	;
always@(*)
	if(r_rst)begin
		CNT_MAX <= 100;
	end else case(Scl_ctrl)
		0	:	CNT_MAX <= 500;//ns 	//2MHz
		1	:	CNT_MAX <= 800;//ns 	//1.25MHz
		2	:	CNT_MAX <= 1000;//ns 	//1MHz
		3	:	CNT_MAX <= 1250;//ns 	//800KHz
		4	:	CNT_MAX <= 2000;//ns 	//500kHz
		default:CNT_MAX <= 800;//ns 	//1.25MHz 
	endcase
		
localparam				IDLE	=3'd0,//空闲
						START	=3'd1,//起始状态拉低CS_n
						RX_RDAT	=3'd3,//接收数据
						TP_WIAT	=3'd4;//死区时间 0.5*SDA_CTRL

wire		[31:0]			DEAD_T;
wire		[11:0]			STAT_T;
assign DEAD_T	=	( DATA_TIME / CLK_T )	; 	//20us
assign STAT_T	=	( 'd8 / CLK_T ) + 1;		//8ns

reg			[2:0]		rx_state;
reg			[15:0]		rev_cnt;
reg			[7:0]		bit_cnt;
reg			[15:0]		rate_cnt;
reg			[20:0]		nop_cnt;			
wire					neg_scl;

always@(posedge Phy_Clk)
	if(r_rst)begin
		rx_state <= IDLE;
	end else begin
		case(rx_state)
			IDLE	:	rx_state <= rate_cnt == 'd10 ? START : IDLE; 
			START	:	rx_state <= neg_scl ? RX_RDAT	: START;
			RX_RDAT	:	rx_state <= bit_cnt == RX_SIZE 	? TP_WIAT : RX_RDAT;
			TP_WIAT	:	rx_state <= nop_cnt == (DEAD_T) - 1 	? IDLE : TP_WIAT;
			default	:	rx_state <= IDLE;
		endcase
	end

/*******************************************************************************
// 				接收开始
*******************************************************************************/	
always@(posedge Phy_Clk) 
    if(r_rst)begin
		rev_cnt <= 'd0;
	end else if(rx_state == START)begin
		rev_cnt <= rev_cnt+1'b1;
	end else begin
		rev_cnt <= 'd0;
	end

/*******************************************************************************
// 				发送时钟
*******************************************************************************/
reg			[12:0]		scl_cnt;
always @(posedge Phy_Clk)
    if(r_rst)begin
		Ssclk <= 1'b1;
		scl_cnt <= 'd0;
	end else if(rx_state == RX_RDAT || rx_state == START)begin
		Ssclk 	<= scl_cnt == 'd1  ? ~Ssclk : Ssclk;
		scl_cnt <= scl_cnt == ((CNT_MAX/CLK_T)/2)-1'b1 ?'d0		: scl_cnt + 1'b1;
	end else begin
		Ssclk <= 1'b1;
		scl_cnt <= 'd0;
	end

reg			[2:0]		sclk;
always@(posedge Phy_Clk)sclk <= {sclk[1:0],Ssclk};

assign neg_scl = ~sclk[1] & sclk[2];

/*******************************************************************************
//  		接收数据计数器
*******************************************************************************/
always @(posedge Phy_Clk)
    if(r_rst)begin
        bit_cnt<='d0;
    end else if(rx_state == RX_RDAT)begin
        bit_cnt<= neg_scl	? bit_cnt + 1'b1 : bit_cnt;
    end else begin
        bit_cnt<='d0;
	end	

always @(posedge Phy_Clk)
    if(r_rst)begin
        rate_cnt<='d0;
    end else if(rx_state == IDLE)begin
        rate_cnt<=	rate_cnt+1'b1 ;
    end else begin
        rate_cnt<='d0;
	end	

/*******************************************************************************
// 			 移位寄存
*******************************************************************************/	
reg [63:0]	 r_shift_data;
always @(posedge Phy_Clk)
    if(r_rst)begin
        r_shift_data<='d0;
    end else if(rx_state == IDLE)begin
        r_shift_data<='d0;
    end else if(rx_state == RX_RDAT && neg_scl)begin
        r_shift_data<={r_shift_data[62:0],s_sda};
    end else begin
        r_shift_data<=r_shift_data;
	end	

always @(posedge Phy_Clk)
    if(r_rst)begin
		nop_cnt	<='d0;
    end else if(rx_state == TP_WIAT)begin
        nop_cnt <= nop_cnt+1'b1;
    end else begin
		nop_cnt <='d0;
	end	

/*******************************************************************************
//  	片选信号
*******************************************************************************/

always @(posedge Phy_Clk)
    if(r_rst)begin
		Cs_n <= 1'b1;
	end else if(cs_en)begin
		Cs_n <= rx_state == IDLE ? 1'b1 : 1'b0;
	end else begin
		Cs_n <= 1'b1;
	end
	
/*******************************************************************************
//  		数据输出
*******************************************************************************/	
always @(posedge Phy_Clk)
    if(r_rst)begin	
		Data_out <= 'd0;
		Data_flag <= 1'b0;
	end else  if(rx_state == TP_WIAT)begin
		Data_out  <= nop_cnt == 'd1 ? r_shift_data	: 	Data_out;
		Data_flag <= nop_cnt == 'd2 ? 1'b1			:	1'b0;
	end else begin
		Data_out <= Data_out;
		Data_flag <= 1'b0;
	end
	
/*******************************************************************************
// 				end                                                         
*******************************************************************************/	

endmodule