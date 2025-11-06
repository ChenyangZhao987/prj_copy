`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 11:34:47
// Design Name: zcy
// Module Name: time_base_gen
// Project Name: XDMA_PCIe
// Target Devices: 
// Tool Versions: 
// Description: 生成时基信号
//
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module time_base_gen(
	input					clk,
	input					Rst,
	output		reg[15:0]	time_base
);
/*******************************************************************************
// 			复位同步 
*******************************************************************************/
reg		[2:0]		rst;
wire				r_rst;
always@(posedge clk) rst <= {rst[1:0],Rst};
	
assign r_rst = rst[2];
/*******************************************************************************
// 			生成时基信号
*******************************************************************************/
always@(posedge clk)
	if(r_rst)begin
		time_base <= 'd0;
	end else begin
		time_base <= time_base + 1;
	end

endmodule