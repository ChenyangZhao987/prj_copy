`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 15:56:56
// Design Name: 
// Module Name: top_SSI
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


module top_SSI(
		input				Sys_clk_p,
		input				Sys_clk_n,
		
		input				Ssda,
		output				Ssclk
    );
	
/*******************************************************************************
// 	驱动例化
*******************************************************************************/	
wire  clk;//差分转单端
wire  Phy_Rst;
clk_wiz_0  clk_wiz(
    // Clock out ports
    .clk_out1(clk),     
    .locked(Phy_Rst),      
    .clk_in1_p(Sys_clk_p),    // input clk_in1_p
    .clk_in1_n(Sys_clk_n)
); 
	
	
/*******************************************************************************
// 	驱动例化
*******************************************************************************/
(* MARK_DEBUG="true" *)wire				Data_flag;	
(* MARK_DEBUG="true" *)wire	[15:0]		Data_out;	
SSI_interface#(
	.RX_SIZE	(16),	//分辨率
	.CLK_T		(5),//输入时钟周期
	.SDA_CTRL	(0)//发送时钟周期0 ： 62.5KHz  1： 125KHz		2：
)SSI_interface_ins(
	.Phy_Clk(clk),
	.Phy_Rst(~Phy_Rst),
	.Ssclk(Ssclk),
	.Ssda(Ssda),
	.Data_out(Data_out),
	.Data_flag(Data_flag)
);
/*******************************************************************************
// 	debug
*******************************************************************************/	
wire		[18:0]		probe0;
(* MARK_DEBUG="true" *)wire					sda,sclk;
assign	sda = Ssda;
assign sclk = Ssclk;	
	ila_0 ila_ins (
	.clk(clk), // input wire clk

	.probe0(probe0) // input wire [16:0] probe0
);
	
assign	probe0[15:0] = Data_out;
assign	probe0[16] = Data_flag;
assign	probe0[17] = sda;
assign	probe0[18] = sclk;

	
	
endmodule
