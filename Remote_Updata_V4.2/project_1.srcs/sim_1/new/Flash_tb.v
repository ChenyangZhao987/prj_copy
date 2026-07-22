`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 09:17:14
// Design Name: 
// Module Name: tb
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


module Flash_tb;
	
	
	
	reg							clk_p,clk_n;
	wire 		[3:0]				Flash_Spi_Sdio;
	wire						F_SPI_CS;
	// reg							Start_Updata0;
	// reg							Start_Updata1;
	wire							Uart_Rx = 1'b1;
	wire							Uart_Tx ;// = 1'b1
	
	initial begin
		// Uart_Rx = 1'b1;
		// Uart_Tx = 1'b1;
		clk_p = 1'b0;
		// Start_Updata0 =1'd0;
		// Start_Updata1 = 0;
		clk_n  = 1'b1;
		// #30
		// Start_Updata0 =1'd1;
		// #100000
		// Start_Updata0 =1'd0;
		// #1000
		// Start_Updata1 = 1;
	end
	
	always#5 clk_p = ~clk_p;
	always#5 clk_n = ~clk_n;
	
	
Top_App #(
		.Sim_Flg 	(1		)
)Top_App_ins(
		.clk_p		(clk_p		),
		.clk_n		(clk_n		),
		// .start0		(Start_Updata0			),
		// .start1		(Start_Updata1			),
		.Uart_Rx	(Uart_Rx			),
		.Uart_Tx	(Uart_Tx			),
		.Flash_Spi_Sdio		(Flash_Spi_Sdio	),
		.Flash_Spi_Csn	(F_SPI_CS	)
);

endmodule
