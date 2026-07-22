/***************************************************************************************************

***************************************************************************************************/
module  Rs_Uart_Tx #(
    parameter       		Check_Mode  = 0  	//校验模式，0：无校验位，1：奇校验，2：偶校验
    )(
    input                   Clk,
    input                   Rst,
    
    input  [31:0]           Uart_Bps,			//时钟分频因子，波特率=f(clk)/Clk_Div
	
    input                   Tx_Wrreq,
    input  [7:0]			Tx_Wdata,
    output                  Tx_Ready,

    output                  Uart_Txd
    );
/*******************************************************************************
//  同步
*******************************************************************************/
reg             r_rst,
                rr_rst;
always @(posedge Clk)
begin
    r_rst   <=  Rst;
    rr_rst  <=  r_rst;
end
/*******************************************************************************
//  发送状态机
*******************************************************************************/
localparam  tx_size = Check_Mode>'d0 ? 12 : 11;
localparam	UART_TX_IDLE = 2'd0;
localparam	UART_TX_RDY  = 2'd1;
localparam	UART_TX_LOCK = 2'd2;
localparam	UART_TX_TDAT = 2'd3;

reg             r_uart_txd;
reg             bps_start;
wire [15:0]		r_uart_data;
reg  [3:0] 		data_cnt;
reg  [1:0] 		uart_tx_state;
always@(posedge Clk)
    if(rr_rst)begin
        r_uart_txd      <=1'b1;
        bps_start   	<=1'b0;
        uart_tx_state   <=UART_TX_IDLE;
    end else begin
        case(uart_tx_state)
            UART_TX_IDLE   :   begin
                                    r_uart_txd      <=1'b1;
									bps_start   	<=1'b0;
                                    uart_tx_state   <=Tx_Wrreq ? UART_TX_RDY : UART_TX_IDLE;
                                end
            //  发送准备
            UART_TX_RDY    :   begin
                                    r_uart_txd      <=1'b1;
									bps_start   	<=1'b0;
                                    uart_tx_state   <=UART_TX_LOCK;
                                end
            //  锁存数据
            UART_TX_LOCK   :   begin
									r_uart_txd      <=1'b1;
									bps_start   	<=1'b1;
                                    uart_tx_state   <=UART_TX_TDAT;
                                end
            //  发送数据：包括起始位+数据位+校验位（如果有）+停止位                    
            UART_TX_TDAT   :   begin
                                    bps_start   		<=1'b1;
									if(data_cnt==tx_size[3:0])begin
                                        r_uart_txd      <=1'b1;
                                        uart_tx_state   <=UART_TX_IDLE;
                                    end else begin
                                        r_uart_txd      <=r_uart_data[data_cnt];
                                        uart_tx_state   <=UART_TX_TDAT;
                                    end 
                                end
            default         :   begin
                                    bps_start   	<=1'b0;
									r_uart_txd      <=1'b1;
                                    uart_tx_state   <=UART_TX_IDLE;
                                end
        endcase
    end
assign Uart_Txd = r_uart_txd; 
assign Tx_Ready = uart_tx_state ==UART_TX_IDLE;
/*******************************************************************************
//  数据锁存
*******************************************************************************/
reg [7:0]	r_tx_wdata;
always @(posedge Clk)
    if(rr_rst)begin
        r_tx_wdata<='d0;
    end else begin
        r_tx_wdata<= Tx_Wrreq ? Tx_Wdata : r_tx_wdata; 
	end
/*******************************************************************************
//  校验位生成
*******************************************************************************/
reg       check_bit;
always @(posedge Clk)
    if(rr_rst)begin
        check_bit<='d1;
    end else if(Check_Mode==1)begin//奇校验:数据中1的个数为奇数，校验为0，否则为1
        check_bit<=~(^r_tx_wdata);
    end else if(Check_Mode==2)begin//偶校验:数据中1的个数为奇数，校验为1，否则为0
        check_bit<= (^r_tx_wdata);
    end else begin
        check_bit<= 'd1; 
	end
assign r_uart_data = {6'h3F,check_bit,r_tx_wdata,1'b0};
/*******************************************************************************
//  产生波特率
*******************************************************************************/
reg [31:0] 	rate_cnt;
reg     	bps_en;
always @(posedge Clk)
    if(rr_rst)begin
		rate_cnt	<='d0;
		bps_en		<='d0;
    end else if(bps_start)begin
        rate_cnt	<= rate_cnt <  Uart_Bps-1'b1 ? rate_cnt+1'b1 : 'd0;
        bps_en		<= rate_cnt == Uart_Bps-1'b1;
    end else begin
		rate_cnt	<='d0;
		bps_en 		<='d0;
	end
/*******************************************************************************
//  发送计数器
*******************************************************************************/
always @(posedge Clk)
    if(rr_rst)begin
		data_cnt <='d0;
    end else if(uart_tx_state==UART_TX_TDAT)begin
        data_cnt<= bps_en ? data_cnt+1'b1 : data_cnt;
    end else begin
		data_cnt<='d0;
	end
/*******************************************************************************
//  end
*******************************************************************************/

endmodule