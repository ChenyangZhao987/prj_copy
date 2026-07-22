/***************************************************************************************************
				Uart接收
***************************************************************************************************/
module  Rs_Uart_Rx #(
    parameter 				Check_Mode  = 0              //	校验模式:0无校验,1奇校验,2偶校验
    )(
    input               	Clk,
    input               	Rst,
	
    input   [31:0]       	Uart_Bps,                    	
    output              	Rx_Wrreq,
    output  [7:0] 			Rx_Wdata,
                        	
    input               	Uart_Rxd
    );
/*******************************************************************************
//  	同步
*******************************************************************************/

reg             r_rst,
                rr_rst;
reg             r_uart_rxd,
                rr_uart_rxd;
always @(posedge Clk)
begin
    r_rst   	<=  Rst;
    rr_rst  	<=  r_rst;
	r_uart_rxd  <=  Uart_Rxd;
    rr_uart_rxd <=  r_uart_rxd;
end
/*******************************************************************************
//  	接收状态机
*******************************************************************************/
localparam  	rx_size = Check_Mode>'d0 ? 'd11 : 'd10;
localparam  	UART_RX_IDLE = 2'd0;
localparam  	UART_RX_RDAT = 2'd1;
localparam  	UART_RX_LOCK = 2'd2;

reg	[19:0]		rev_cnt;
reg [19:0]      rate_cnt;
reg [3:0]       data_cnt;
reg [1:0]       uart_rx_state;
reg [2:0]       nop_cnt;
always @(posedge Clk)
    if(rr_rst)begin
        uart_rx_state<=UART_RX_IDLE;
    end else begin
        case(uart_rx_state)
            UART_RX_IDLE    :   uart_rx_state<=rev_cnt==Uart_Bps[19:1] ? UART_RX_RDAT : UART_RX_IDLE;
            UART_RX_RDAT    :   uart_rx_state<=data_cnt==rx_size-1'b1 && rate_cnt==Uart_Bps-1'b1 ? UART_RX_LOCK : UART_RX_RDAT;
            UART_RX_LOCK    :   uart_rx_state<=nop_cnt=='d7 ? UART_RX_IDLE : UART_RX_LOCK;
            default         :   uart_rx_state<=UART_RX_IDLE;
        endcase
    end
/*******************************************************************************
//  接收起始位检测
*******************************************************************************/
always @(posedge Clk)
    if(rr_rst)begin
		rev_cnt<='d0;
	end else if(uart_rx_state==UART_RX_IDLE && rr_uart_rxd=='b0)begin
		rev_cnt<=rev_cnt+1'b1;
	end else begin
		rev_cnt<='d0;
	end
/*******************************************************************************
//  接收数据计数器
*******************************************************************************/
always @(posedge Clk)
    if(rr_rst)begin
        data_cnt<='d0;
    end else if(uart_rx_state==UART_RX_RDAT)begin
        data_cnt<=rate_cnt=='d2 ? data_cnt+1'b1 : data_cnt;
    end else begin
        data_cnt<='d0;
	end
/*******************************************************************************
// 波特率计数器
*******************************************************************************/
always @(posedge Clk)
    if(rr_rst)begin
		rate_cnt	<='d0;
    end else if(uart_rx_state==UART_RX_RDAT)begin
        rate_cnt	<= rate_cnt <  Uart_Bps-1'b1 ? rate_cnt+1'b1 : 'd0;
    end else begin
		rate_cnt	<='d0;
	end
/*******************************************************************************
// 锁存等待计数器
*******************************************************************************/
always @(posedge Clk)
    if(rr_rst)begin
		nop_cnt	<='d0;
    end else if(uart_rx_state==UART_RX_LOCK)begin
        nop_cnt	<= nop_cnt+1'b1;
    end else begin
		nop_cnt	<='d0;
	end
/*******************************************************************************
//  移位寄存
*******************************************************************************/
reg [10:0]	 r_shift_data;
always @(posedge Clk)
    if(rr_rst)begin
        r_shift_data<='d0;
    end else if(uart_rx_state==UART_RX_IDLE)begin
        r_shift_data<='d0;
    end else if(uart_rx_state==UART_RX_RDAT && rate_cnt=='d2)begin
        r_shift_data<={rr_uart_rxd,r_shift_data[10:1]};
    end else begin
        r_shift_data<=r_shift_data;
	end
/*******************************************************************************
//  停止位判断
    停止位不为1的数据应该剔除
*******************************************************************************/
reg                 r_rx_val;
reg [rx_size-1:0]   r_rx_dat;
always @(posedge Clk)
    if(rr_rst)begin
        r_rx_val<='b0;
        r_rx_dat<='d0;
    end else if(uart_rx_state==UART_RX_LOCK && nop_cnt=='d7 && rr_uart_rxd==1'b1)begin
        r_rx_val<='b1;
        r_rx_dat<=r_shift_data[10:11-rx_size];
    end else begin
        r_rx_val<='b0;
        r_rx_dat<=r_rx_dat;
    end
/*******************************************************************************
// 校验位生成
*******************************************************************************/
reg       check_bit;
always @(posedge Clk)
    if(rr_rst)begin
        check_bit<='d0;
    end else if(Check_Mode==1)begin	
        check_bit<=~(^r_rx_dat[9:2]);
    end else if(Check_Mode==2)begin	
        check_bit<= (^r_rx_dat[9:2]);
    end else begin
        check_bit<= 'd1; 
	end
/*******************************************************************************
//  数据输出
*******************************************************************************/
reg                 rr_rx_val;
reg [rx_size-1:0]   rr_rx_dat;
always @(posedge Clk)
begin
    rr_rx_val<=r_rx_val;
    rr_rx_dat<=r_rx_dat;
end    
reg       	r_rx_wrreq;
reg [7:0] 	r_rx_wdata;
always @(posedge Clk)
    if(rr_rst)begin
        r_rx_wrreq<='b0;
        r_rx_wdata<='d0;  
    end else if(rr_rx_val==1'b1 && (Check_Mode=='d0 ||(Check_Mode>'d0 && check_bit==rr_rx_dat[rx_size-1])))begin                          
        r_rx_wrreq<='b1;
        r_rx_wdata<=rr_rx_dat[9:2];
    end else begin
        r_rx_wrreq<='b0;
        r_rx_wdata<=r_rx_wdata;
    end  
assign  Rx_Wrreq = r_rx_wrreq;
assign  Rx_Wdata = r_rx_wdata;
/*******************************************************************************
//  end
*******************************************************************************/
endmodule