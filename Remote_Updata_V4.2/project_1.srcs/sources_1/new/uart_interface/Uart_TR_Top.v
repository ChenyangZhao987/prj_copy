
module	Uart_TR_Top#(
	parameter   	Wdat_Width =  8,	
					Check_Mode =  0  //	校验模式:0无校验,1奇校验,2偶校验
	)(
	input			Clk,
	input			Rst,
	
    input   [31:0] 	Uart_Bps,
	
    input           Tx_Wrreq,
    input   [7:0]  	Tx_Wdata,
    output    	  	Tx_Ready,
    
    output          Rx_Wrreq,
    output  [7:0]   Rx_Wdata,
    
    output			Rs_Txd,		
	input		   	Rs_Rxd
);


/*******************************************************************************
//	UART 发送
*******************************************************************************/
Rs_Uart_Tx 	#(
	.Check_Mode 		(Check_Mode    	)
	)tx_blk(                 	
	.Clk				(Clk    		),
	.Rst				(Rst     		),

	.Uart_Bps			(Uart_Bps		),//  串口波特率分频系数=f(Clk)/Clk_Div
	
	.Tx_Wrreq			(Tx_Wrreq 		),	
	.Tx_Wdata			(Tx_Wdata		),
	.Tx_Ready   		(Tx_Ready		),
	.Uart_Txd   		(Rs_Txd			)
	);
/*******************************************************************************
//	UART 接收
*******************************************************************************/
Rs_Uart_Rx 	#(
 	.Check_Mode 		(Check_Mode		)
	)rx_blk(  
	.Clk				(Clk			),
	.Rst				(Rst			),
	
	.Uart_Bps			(Uart_Bps		),//  串口波特率分频系数=f(Clk)/Clk_Div
	
	.Rx_Wrreq			(Rx_Wrreq		),
	.Rx_Wdata			(Rx_Wdata		),
	.Uart_Rxd   		(Rs_Rxd			)
	);
/*******************************************************************************
//	end
*******************************************************************************/
endmodule
