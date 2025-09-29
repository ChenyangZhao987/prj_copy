`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/22 15:22:57
// Design Name: 
// Module Name: text
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


module text;
	reg						Phy_Clk;
	reg						Phy_Rst;
	wire					Ssclk;
	reg						Ssda;
	wire	[15:0]			Data_out;
	wire					Data_flag;


initial	begin
	Phy_Clk = 1'b0;
	Phy_Rst = 1'b1;
	#50
	Phy_Rst = 1'b0;
end

always#2.5 Phy_Clk = ~Phy_Clk;


always@(posedge Ssclk)
	Ssda = $random % 2;
	

SSI_interface#(
	.RX_SIZE	(16),	//分辨率
	.CLK_T		(5),//输入时钟周期
	.SDA_CTRL	(0)//发送时钟周期0 ： 62.5KHz  1： 125KHz		2：
)SSI_interface_ins(
	.Phy_Clk(Phy_Clk),
	.Phy_Rst(Phy_Rst),
	.Ssclk(Ssclk),
	.Ssda(Ssda),
	.Data_out(Data_out),
	.Data_flag(Data_flag)
);
endmodule
