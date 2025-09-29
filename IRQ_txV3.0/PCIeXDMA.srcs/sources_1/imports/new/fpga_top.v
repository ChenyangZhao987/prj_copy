`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 11:34:47
// Design Name: zcy
// Module Name: fpga_top
// Project Name: XDMA_PCIe
// Target Devices: 
// Tool Versions: 
// Description: 模块实现功能如下
//				1、PC配置寄存器控制个功能使能
// 				1、使能控制下输出信号1输出100Hz方波信号邦线回环至 输入信号1
// 				2、使能控制下以方波上升沿输出pcie中断发起标志
// 				2、PC配置清中断命令，输出清中断标志
// 				3、以中断发起标志和清中断标志向PC发送和撤销中断
//              4、输出信号2 PC主机清除中断后，FPGA翻转输出信号2的电平
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module fpga_top (
    input  wire       	Pcie_rstn,
    input  wire       	Pcie_refclkp, Pcie_refclkn,//PCIE参考时钟 100MHz
    input  wire [0:0] 	Pcie_rxp, Pcie_rxn,
    output wire [0:0] 	Pcie_txp, Pcie_txn,
	//外部中断发起信号
	input				Sig_Inp1,//输入信号100Hz的方波信号
	//输出信号
	output	reg			Sig_Out1, //输出信号1输出100Hz方波信号
	output	reg			Sig_Out2,  //输出信号2：PC主机清除中断后，FPGA翻转输出信号2的电平
	//led显示链路状态
	output	wire		Led0
);
/*******************************************************************************
// 	时钟复位
*******************************************************************************/    
wire  pcie_rstn;
wire  Pcie_refclk;
IBUFDS_GTE2 refclk_ibuf (
    .CEB             ( 1'b0         	),
    .I               ( Pcie_refclkp  	),
    .IB              ( Pcie_refclkn  	),
    .O               ( Pcie_refclk    	),
    .ODIV2           (                	)
);

// Reset input buffer
IBUF   sys_reset_n_ibuf (
    .I               ( Pcie_rstn       	),
    .O               ( pcie_rstn       	)
);

wire	barm_clk_m,bram_clk_b,bram_rst_m,bram_rst_b;

/*******************************************************************************
// 	复位同步
*******************************************************************************/ 
reg			[2:0]			rr_rst;
always@(posedge bram_clk_b) 
	rr_rst <= {rr_rst[1:0],bram_rst_b};

wire						r_rst;
assign	r_rst = rr_rst[2];
/*******************************************************************************
// 	定时器100Hz
*******************************************************************************/
(*MARK_DEBUG="true"*)wire					irq_en;
(*MARK_DEBUG="true"*)wire                	wave_en;
(*MARK_DEBUG="true"*)wire                	clear_int_en;

reg		[31:0]		sig_cnt;
always@(posedge bram_clk_b)
	if(r_rst)begin
		sig_cnt  <= 'd0;
		Sig_Out1 <= 'd0;
	end else if(wave_en)begin
		sig_cnt  <= sig_cnt == 'd312500-1'b1		? 'd0 		: sig_cnt + 1'b1;
		Sig_Out1 <= sig_cnt == 'd312500-1'b1		? ~Sig_Out1 : Sig_Out1;
	end else begin
		sig_cnt  <= 'd0;
		Sig_Out1 <=	'd0;
	end

/*******************************************************************************
// 	清中断标志，翻转输出信号2的电平
*******************************************************************************/
(*MARK_DEBUG="true"*)reg	[1:0]	irq_state;

(*MARK_DEBUG="true"*)wire 	[12:0]	addr_m;   
(*MARK_DEBUG="true"*)wire 	[63:0]	din_m; 
wire 	[63:0]	dout_m;	
(*MARK_DEBUG="true"*)wire 			en_m;     
(*MARK_DEBUG="true"*)wire 	[7:0]	wen_m;     
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[12:0]	addr_b;    
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[63:0]	din_b;     
wire 	[63:0] 	dout_b;    
(*MARK_DEBUG="true"*)wire 			en_b;          
(*MARK_DEBUG="true"*)wire 	[7:0]	wen_b;     


always@(posedge bram_clk_b)
	if(r_rst)begin
		Sig_Out2 <= 'd0;
	end else begin
		Sig_Out2 <= clear_int_en&& (irq_state=='d2) ? ~Sig_Out2 : Sig_Out2;
	end
	

/*******************************************************************************
// 		外部中断发起信号处理
*******************************************************************************/
(* MARK_DEBUG="true" *)reg		[14:0]	in_cnt;
(* MARK_DEBUG="true" *)wire				usr_irq_ack;
(* MARK_DEBUG="true" *)reg				usr_irq_req;
(* MARK_DEBUG="true" *)wire				user_lnk_up;

(* MARK_DEBUG="true" *)reg		[2:0]	s_sig_in1;
always@(posedge bram_clk_b)s_sig_in1<={s_sig_in1[1:0],Sig_Inp1};//同步

//消抖计数器
always@(posedge bram_clk_b)
	if(r_rst)begin
		in_cnt <= 'd0;
	end else if(s_sig_in1[2]&& user_lnk_up && irq_state == 'd0 && irq_en)begin//输入信号1上升沿驱动发起中断
		if(in_cnt == 'd6249)//100us
			in_cnt <= in_cnt;
		else 
			in_cnt <= in_cnt + 1'b1;
	end else begin
		in_cnt <= 'd0;
	end 

//输出4时钟周期的脉冲信号用于驱动产生中断
reg				ss_sig_in;
reg		[2:0]	ss_cnt;
always@(posedge bram_clk_b)
	if(r_rst)begin
		ss_cnt <= 'd0;
		ss_sig_in <= 1'b0;
	end else begin
		ss_sig_in 	<= in_cnt == 'd6249 && ss_cnt < 'd4 && irq_en	? 1'b1 : 1'b0;
		ss_cnt		<= in_cnt != 'd6249 ?	'd0 :  ss_cnt == 'd4 ? ss_cnt : ss_cnt + 1'b1;
	end
	
//脉冲信号到来，链路正常发起中断请求，等待ack后拉低
(* MARK_DEBUG="true" *)reg		[2:0]	irq_ack;
always@(posedge bram_clk_b)irq_ack<={irq_ack[1:0],usr_irq_ack};//同步
always@(posedge bram_clk_b)
	if(r_rst)begin
		usr_irq_req <= 1'b0;
		irq_state <= 'd0;
	end else if(user_lnk_up)begin
		case(irq_state)
			0	:	begin
						irq_state <= ss_sig_in ?  'd1 : 'd0;
						usr_irq_req <= 1'b0;
					end 
			1	:	begin	
						irq_state <= irq_ack[2] ?   'd2 : 'd1;
						usr_irq_req <= 1'b1;
					end 
			2	:	begin
						irq_state <= clear_int_en ? 'd0 : 'd2;
						usr_irq_req <= 1'b0;
					end
			default	:	irq_state <= 'd0;
		endcase
	end else begin
		irq_state <= 'd0;
		usr_irq_req <= 'd0;
	end
	
	assign	 Led0 = user_lnk_up;
/*******************************************************************************
// 				配置寄存器控制                                                        
*******************************************************************************/
(* MARK_DEBUG="true" *)wire					en_s;	
(* MARK_DEBUG="true" *)wire		[7:0]		wen_s;
(* MARK_DEBUG="true" *)wire		[12:0]		addr_s;
(* MARK_DEBUG="true" *)wire		[63:0]		din_s;
(* MARK_DEBUG="true" *)wire		[63:0]		dout_s;
sys_ctrl_cfg_reg sys_ctrl_cfg_reg_ins(
	.bram_clk_b				(bram_clk_b			),
	.bram_rst_b				(bram_rst_b			),
	.addr_b					(addr_b				),
	.din_b					(din_b				),
	.en_b					(en_b				),
	.wen_b					(wen_b				), 
	.sig_in					(s_sig_in1[2]		),
	.irq_state				(irq_state			),
	.en_s					(en_s				),
	.wen_s					(wen_s				),
	.addr_s					(addr_s				),
	.din_s					(din_s				),
	.dout_s					(dout_s				),
	.irq_en					(irq_en				),	
	.wave_en				(wave_en			),
	.clear_int_en			(clear_int_en		)
);


/*******************************************************************************
// 				pcie block design例化                                                               
*******************************************************************************/
xdma_bram_wrapper xdma_bram_wrapper_i (
	.BRAM_PORTA_0_addr		( addr_b        	),
	.BRAM_PORTA_0_clk		( bram_clk_b    	),
    .BRAM_PORTA_0_din		( din_b        		),
    .BRAM_PORTA_0_dout		( dout_b			),
    .BRAM_PORTA_0_en		( en_b        		),
    .BRAM_PORTA_0_rst		( bram_rst_b        ),
    .BRAM_PORTA_0_we		( wen_b        		),
    .BRAM_PORTA_1_addr		( addr_m       	 	),
    .BRAM_PORTA_1_clk		( barm_clk_m        ),
    .BRAM_PORTA_1_din		( din_m        		),
    .BRAM_PORTA_1_dout		( dout_m        	),
    .BRAM_PORTA_1_en		( en_m        		),
    .BRAM_PORTA_1_rst		( bram_rst_m      	),
    .BRAM_PORTA_1_we		( wen_m        		),
    .pcie_mgt_rxn  			( Pcie_rxn        	),
    .pcie_mgt_rxp  			( Pcie_rxp        	),
    .pcie_mgt_txn  			( Pcie_txn        	),
    .pcie_mgt_txp  			( Pcie_txp        	),
    .sys_clk_0       		( Pcie_refclk       ),
    .sys_rst_n_0     		( pcie_rstn         ),
    .user_lnk_up   			( user_lnk_up      	),
	.usr_irq_ack			( usr_irq_ack      	),
	.usr_irq_req			( usr_irq_req      	)
);

/*******************************************************************************
// 				block ram                                                          
*******************************************************************************/

blk_mem_gen_0 blk_mem_0 (
  .clka						(barm_clk_m			),            // input wire clka
  .rsta						(r_rst			),            // input wire rsta
  .ena						(en_s				),              // input wire ena
  .wea						(wen_s				),              // input wire [7 : 0] wea
  .addra					({19'd0,addr_s}		),          // input wire [31 : 0] addra
  .dina						(din_s				),            // input wire [63 : 0] dina
  .douta					(dout_s				),          // output wire [63 : 0] douta
  
  .clkb						(bram_clk_b			),            // input wire clkb
  .rstb						(r_rst				),            // input wire rstb
  .enb						(en_b				),              // input wire enb
  .web						(wen_b				),              // input wire [7 : 0] web
  .addrb					({19'd0,addr_b}		),          // input wire [31 : 0] addrb
  .dinb						(din_b				),            // input wire [63 : 0] dinb
  .doutb					(dout_b				),          // output wire [63 : 0] doutb
  .rsta_busy				(					),  // output wire rsta_busy
  .rstb_busy				(					)  // output wire rstb_busy
);

blk_mem_gen_0 blk_mem_1 (
	.clka					(barm_clk_m			),            // input wire clka
	.rsta					(bram_rst_m			),            // input wire rsta
	.ena					(en_m				),              // input wire ena
	.wea					(wen_m				),              // input wire [7 : 0] wea
	.addra					({19'd0,addr_m}		),          // input wire [31 : 0] addra
	.dina					(din_m				),            // input wire [63 : 0] dina
	.douta					(dout_m				),          // output wire [63 : 0] douta
	.clkb					(bram_clk_b			),            // input wire clkb
	.rstb					(r_rst				),            // input wire rstb
	.enb					('d0				),              // input wire enb
	.web					(8'd0				),              // input wire [7 : 0] web
	.addrb					({19'd0,addr_b}		),          // input wire [31 : 0] addrb
	.dinb					(din_b				),            // input wire [63 : 0] dinb
	.doutb					(					),          // output wire [63 : 0] doutb
	.rsta_busy				(					),  // output wire rsta_busy
	.rstb_busy				(					)  // output wire rstb_busy
);

/*******************************************************************************
// 				debug                                                          
*******************************************************************************/

endmodule