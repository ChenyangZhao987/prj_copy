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
// 				1、输出信号1输出100Hz方波信号邦线回环至 输入信号1
// 				2、以方波上升沿输出pcie中断发起标志
// 				2、AXI接收PC端清中断命令，输出清中断标志
// 				3、以中断发起标志和清中断标志向PC发送和撤销中断
//              4、输出信号2：PC主机清除中断后，FPGA翻转输出信号2的电平
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
	input				Sig_Inp1,
	//输出信号
	output	reg			Sig_Out1,
	output	reg			Sig_Out2,  
	//led显示链路状态
	output	wire		Led0
);
/*******************************************************************************
// 	时钟复位
*******************************************************************************/    
wire  pcie_rstn;
wire  Pcie_refclk;
IBUFDS_GTE2 refclk_ibuf (
    .CEB             ( 1'b0              ),
    .I               ( Pcie_refclkp   		),
    .IB              ( Pcie_refclkn   		),
    .O               ( Pcie_refclk       ),
    .ODIV2           (                   )
);

// Reset input buffer
IBUF   sys_reset_n_ibuf (
    .I               ( Pcie_rstn       ),
    .O               ( pcie_rstn         )
);

wire	barm_clk_m,barm_clk_b,barm_rst_m,barm_rst_b;
/*******************************************************************************
// 	定时器100Hz
*******************************************************************************/
reg		[31:0]		sig_cnt;
always@(posedge barm_clk_b)
	if(barm_rst_b)begin
		sig_cnt  <= 'd0;
		Sig_Out1 <= 'd0;
	end else begin
		sig_cnt  <= sig_cnt == 'd312500-1'b1		? 'd0 		: sig_cnt + 1'b1;
		Sig_Out1 <= sig_cnt == 'd312500-1'b1		? ~Sig_Out1 : Sig_Out1;
	end

/*******************************************************************************
// 	清中断标志，翻转输出信号2的电平
*******************************************************************************/
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[12:0]	addr_m;   
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[63:0]	din_m; 
wire 	[63:0]	dout_m;	
(*MARK_DEBUG="true"*)wire 			en_m;     
(*MARK_DEBUG="true"*)wire 	[7:0]	wen_m;     
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[12:0]	addr_b;    
(*KEEP = "true",MARK_DEBUG="true"*)wire 	[63:0]	din_b;     
wire 	[63:0] 	dout_b;    
(*MARK_DEBUG="true"*)wire 			en_b;          
(*MARK_DEBUG="true"*)wire 	[7:0]	wen_b;     
(* MARK_DEBUG="true" *)reg				[9:0]		text;
reg		pc_clear_int_flag;

reg		[3:0]			byte_en;
always@(*)begin
	case(wen_b)
		8'b0000_0001	:	byte_en <= 'd0;	
		8'b0000_0010	:	byte_en <= 'd1;
		8'b0000_0100	:	byte_en <= 'd2;
		8'b0000_1000	:	byte_en <= 'd3;
		8'b0001_0000	:	byte_en <= 'd4;
		8'b0010_0000	:	byte_en <= 'd5;
		8'b0100_0000	:	byte_en <= 'd6;
		8'b1000_0000	:	byte_en <= 'd7;
		default			:	byte_en <= 'd0;
	endcase
end
	
always@(posedge barm_clk_b)
	if(barm_rst_b)begin
        pc_clear_int_flag <= 1'b0;
		text <= 'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址38+偏移地址00 == 38
        if(addr_b == 32'h38 && din_b[((byte_en * 8)+ 7):(byte_en * 8)] == 8'h7A) begin
            pc_clear_int_flag <= 1'b1;  // 断言清中断标志
			text <= text + 1'b1; 
        end else begin
            pc_clear_int_flag <= 1'b0;
			text <= text;
        end
    end else begin
        pc_clear_int_flag <= 1'b0;
		text <= text;
    end

always@(posedge barm_clk_b)
	if(barm_rst_b)begin
		Sig_Out2 <= 'd0;
	end else begin
		Sig_Out2 <= pc_clear_int_flag ? ~Sig_Out2 : Sig_Out2;
	end
	

/*******************************************************************************
// 		外部中断发起信号处理
*******************************************************************************/
(* MARK_DEBUG="true" *)reg		[14:0]	in_cnt;
(* MARK_DEBUG="true" *)wire				usr_irq_ack;
(* MARK_DEBUG="true" *)reg				usr_irq_req;
(* MARK_DEBUG="true" *)wire				user_lnk_up;
(* MARK_DEBUG="true" *)reg		[1:0]	irq_state;
(* MARK_DEBUG="true" *)reg		[2:0]	s_sig_in1;
always@(posedge barm_clk_b)s_sig_in1<={s_sig_in1[1:0],Sig_Inp1};//同步

//消抖计数器
always@(posedge barm_clk_b)
	if(barm_rst_b)begin
		in_cnt <= 'd0;
	end else if(s_sig_in1[2] && user_lnk_up && irq_state == 'd0)begin
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
always@(posedge barm_clk_b)
	if(barm_rst_b)begin
		ss_cnt <= 'd0;
		ss_sig_in <= 1'b0;
	end else begin
		ss_sig_in 	<= in_cnt == 'd6249 && ss_cnt < 'd4	? 1'b1 : 1'b0;
		ss_cnt		<= in_cnt != 'd6249 ?	'd0 :  ss_cnt == 'd4 ? ss_cnt : ss_cnt + 1'b1;
	end
	
//脉冲信号到来，链路正常发起中断请求，等待ack后拉低
(* MARK_DEBUG="true" *)reg		[2:0]	irq_ack;
always@(posedge barm_clk_b)irq_ack<={irq_ack[1:0],usr_irq_ack};//同步
always@(posedge barm_clk_b)
	if(barm_rst_b)begin
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
						irq_state <= pc_clear_int_flag ? 'd0 : 'd2;
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
// 				pcie block design例化                                                               
*******************************************************************************/
xdma_bram_wrapper xdma_bram_wrapper_i (
	.BRAM_PORTA_0_addr		( addr_b        	),
	.BRAM_PORTA_0_clk		( barm_clk_b    	),
    .BRAM_PORTA_0_din		( din_b        		),
    .BRAM_PORTA_0_dout		( dout_b			),
    .BRAM_PORTA_0_en		( en_b        		),
    .BRAM_PORTA_0_rst		( barm_rst_b        ),
    .BRAM_PORTA_0_we		( wen_b        		),
    .BRAM_PORTA_1_addr		( addr_m       	 	),
    .BRAM_PORTA_1_clk		( barm_clk_m        ),
    .BRAM_PORTA_1_din		( din_m        		),
    .BRAM_PORTA_1_dout		( dout_m        	),
    .BRAM_PORTA_1_en		( en_m        		),
    .BRAM_PORTA_1_rst		( barm_rst_m      	),
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

blk_mem_gen_0 blk_mem_gen_ins (
  .clka(barm_clk_m),            // input wire clka
  .rsta(barm_rst_m),            // input wire rsta
  .ena(en_m),              // input wire ena
  .wea(wen_m),              // input wire [7 : 0] wea
  .addra({'d0,addr_m}),          // input wire [31 : 0] addra
  .dina(din_m),            // input wire [63 : 0] dina
  .douta(dout_m),          // output wire [63 : 0] douta
  
  .clkb(barm_clk_b),            // input wire clkb
  .rstb(barm_rst_b),            // input wire rstb
  .enb(en_b),              // input wire enb
  .web(wen_b),              // input wire [7 : 0] web
  .addrb({'d0,addr_b}),          // input wire [31 : 0] addrb
  .dinb(din_b),            // input wire [63 : 0] dinb
  .doutb(dout_b),          // output wire [63 : 0] doutb
  .rsta_busy(rsta_busy),  // output wire rsta_busy
  .rstb_busy(rstb_busy)  // output wire rstb_busy
);



/*******************************************************************************
// 				debug                                                          
*******************************************************************************/
wire	[208:0]		dbg_pcie0;
ila_0   pcie_ila_blk(
		.clk    					(barm_clk_b    					),
		.probe0 					(dbg_pcie0   					)
		); 	


	assign dbg_pcie0[0] = usr_irq_req;
	assign dbg_pcie0[1] = usr_irq_ack;
	assign dbg_pcie0[2] = ss_sig_in;
	assign dbg_pcie0[3] = pc_clear_int_flag;
	assign dbg_pcie0[5:4] = irq_state;
	assign dbg_pcie0[18:6] = addr_b;
	assign dbg_pcie0[102:38] = din_b;
	assign dbg_pcie0[103] =	en_b;
	assign dbg_pcie0[104] =	pc_clear_int_flag;
	assign dbg_pcie0[105] =	Sig_Inp1;
	assign dbg_pcie0[118:106] =	addr_m;
	assign	dbg_pcie0[128:119]=text;
	assign dbg_pcie0[199:138] =din_b;
	assign dbg_pcie0[200] = en_m;
	assign dbg_pcie0[208:201] = wen_m;




endmodule