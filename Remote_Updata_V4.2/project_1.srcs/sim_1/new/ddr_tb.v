`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/13 10:00:19
// Design Name: 
// Module Name: ddr_tb
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


module ddr_tb;
	
	reg			sys_clk_p;
	reg			sys_clk_n;
	reg				rst;
	
	initial begin
		sys_clk_p = 1'b0;
		// sys_clk_n = 1'b1;
		rst = 1'b1;
		#1000
		rst = 1'b0;
	end
	
	always#2.5 sys_clk_p = ~sys_clk_p;
	
	assign sys_clk_n = ~sys_clk_p;
	
	
	
	
	
ddr_top (
    // DDR 硬件物理接口
   .DDR3_0_dq		(),
   .DDR3_0_dqs_n	(),
   .DDR3_0_dqs_p	(),
   .DDR3_0_addr		(),
   .DDR3_0_ba		(),
   .DDR3_0_cas_n	(),
   .DDR3_0_ck_n		(),
   .DDR3_0_ck_p		(),
   .DDR3_0_cke		(),
   .DDR3_0_cs_n		(),
   .DDR3_0_dm		(),
   .DDR3_0_odt		(),
   .DDR3_0_ras_n	(),	
   .DDR3_0_reset_n	(),	
   .DDR3_0_we_n		(),

    // 系统时钟 + 复位
    .sys_clk_n_0	(sys_clk_n),
    .sys_clk_p_0	(sys_clk_p),
    .DDR_rst_0  	(rst)
);	
	
endmodule
