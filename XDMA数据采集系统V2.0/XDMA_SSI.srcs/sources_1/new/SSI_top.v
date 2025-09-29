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
//					SSI驱动采集16位数据和数据使能
//					将采集的数据移位寄存为64位的可传输数据
//					将数据通过乒乓操作并在中断和清中断的控制下写入BRAM
//					Bypass通道配置寄存器和清中断命令
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module SSI_top (
    input  wire       	Pcie_rstn,
    input  wire       	Pcie_refclkp, Pcie_refclkn,//PCIE参考时钟 100MHz
    input  wire [1:0] 	Pcie_rxp, Pcie_rxn,
    output wire [1:0] 	Pcie_txp, Pcie_txn,
	output				Ssclk,
	output				Cs_n,
	input				Ssda,
	//led显示链路状态
	output	wire		Led0
);
/*******************************************************************************
// 		复位同步
*******************************************************************************/    
wire  pcie_rstn;
wire  Pcie_refclk;//差分转单端
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

wire						bram_rst_b;
wire						bram_clk_b;
wire						user_lnk_up;
reg			[63:0]			data_reg;

reg			[2:0]			rr_rst;
always@(posedge bram_clk_b) rr_rst <= {rr_rst[1:0],bram_rst_b};
(* MARK_DEBUG="true" *)wire						r_rst;

assign	r_rst	= rr_rst[2];

assign	Led0 = user_lnk_up;//LED显示链路状态

(* MARK_DEBUG="true" *)wire			[23:0]				data_out;
(* MARK_DEBUG="true" *)wire								data_flag;
(* MARK_DEBUG="true" *)wire								sda1,sclk1,cs_1;
assign	sda1 = Ssda;
assign	cs_1 = Cs_n;
assign sclk1 = Ssclk;
/*******************************************************************************
// 		配置寄存器
*******************************************************************************/
(* MARK_DEBUG="true" *)wire 		[7:0]			wen_b;
(* MARK_DEBUG="true" *)wire 		[11:0]			addr_b;
(* MARK_DEBUG="true" *)wire 						en_b;
(* MARK_DEBUG="true" *)wire 		[63:0]			dout_b ;
(* MARK_DEBUG="true" *)wire 		[63:0]			din_b;

(* MARK_DEBUG="true" *)wire							ping_pang_sel;	//乒乓指示
(* MARK_DEBUG="true" *)wire							data_acq_en; //采集使能
(* MARK_DEBUG="true" *)wire							clear_int_en;//清中断标志
(* MARK_DEBUG="true" *)wire		[2:0]				single_sample;//中断触发深度（单次采样次数）
(* MARK_DEBUG="true" *)wire							cs_en;	//片选使能
(* MARK_DEBUG="true" *)wire							Sda_ctrl;	//片选使能

cfg_reg_ctrl(
	.Clk						(bram_clk_b		),
	.Rst						(r_rst			),
	.en_b						(en_b			),
	.wen_b						(wen_b			),
	.addr_b						(addr_b			),
	.din_b						(din_b			),
	.dout_b						(dout_b			),
	.cs_en						(cs_en			),
	.Sda_ctrl					(Sda_ctrl		),
	.ping_pang_sel				(ping_pang_sel	),//乒乓指示
	.data_acq_en				(data_acq_en	),//采集使能
	.clear_int_en				(clear_int_en	),//清中断标志
	.single_sample				(single_sample	) //中断触发深度（单次采样次数）	
);
/*******************************************************************************
// 		数据采集模块
*******************************************************************************/
SSI_interface#(
		.RX_SIZE				(24				),	//16位分辨率
		.CLK_T					(8				)	//输入时钟周期/ns
		
	)SSI_interface_ins(
		.Phy_Clk				(bram_clk_b		),
		.Phy_Rst				(r_rst			),
		.Sda_ctrl				(Sda_ctrl		),	//发送时钟周期  0：12.5MHz  1： 5MHz	
		.Ssclk					(Ssclk			),
		.Cs_n					(Cs_n			),
		.cs_en					(cs_en			),
		.Ssda					(Ssda			),
		.Data_out				(data_out		),
		.Data_flag				(data_flag		)
	);
	
/*******************************************************************************
// 		数据位宽转换：24bit转64bit
*******************************************************************************/
(* MARK_DEBUG="true" *)reg			[63:0]			din_reg;
(* MARK_DEBUG="true" *)reg							en_s1;
(* MARK_DEBUG="true" *)reg			[3:0]			reg_cnt;
(* MARK_DEBUG="true" *)reg							en_s;	
(* MARK_DEBUG="true" *)wire			[7:0]			wen_s;
(* MARK_DEBUG="true" *)reg			[28:0]			addr_s;
(* MARK_DEBUG="true" *)wire			[63:0]			din_s;
(* MARK_DEBUG="true" *)wire			[63:0]			dout_s;
(* MARK_DEBUG="true" *)wire			[31:0]			data_all;

assign data_all	= {2'b00,data_out[23:10],4'b0000,data_out[9:6],2'b00,data_out[5:0]};//14bit 数据+4bit 状态+6bit CRC

always@(posedge bram_clk_b)
	if(r_rst)begin
		data_reg <= 'd0;
	end else begin
		data_reg <= data_flag && data_acq_en ? {data_reg[31:0],data_all} : data_reg;
	end 
		
always@(posedge bram_clk_b)
	if(r_rst)begin
		reg_cnt <= 'd0;
		din_reg <= 'd0;
	end else if(data_flag && data_acq_en)begin
		reg_cnt <=  reg_cnt == 'd1 ? 'd0 : reg_cnt + 1'b1;
		din_reg <= 	reg_cnt == 'd1 ? {data_reg[31:0],data_all}: din_reg;
	end else begin
		reg_cnt <= reg_cnt;
		din_reg <= din_reg;
	end

/*******************************************************************************
// 		数据写入bram
*******************************************************************************/
reg		[13:0]		addr_sel;

always@(*)begin
	case(single_sample)
		0	:	addr_sel = 14'h100;		//17'h800;
		1	:	addr_sel = 14'h200;		//17'h1000;
		2	:	addr_sel = 14'h400;		//17'h2000;
		3	:	addr_sel = 14'h800;		//17'h4000;
		4	:	addr_sel = 14'h1000;	//17'h8000;
		5	:	addr_sel = 14'h2000;	//17'h10000;
		default:addr_sel = 14'h100;		//17'h800;
	endcase
end

(* MARK_DEBUG="true" *)reg				req_1;
(* MARK_DEBUG="true" *)reg				req_0;
always@(posedge bram_clk_b)
	if(r_rst)begin	
		en_s1 <= 1'b0;
		en_s  <= 1'b0;
	end else if( (addr_s == addr_sel && req_0) | (addr_s == ('h10000 + addr_sel) && req_1) )begin
		en_s1 <= 1'b0;
		en_s  <= en_s1;
	end else begin
		en_s1 <= data_flag && reg_cnt == 'd1 && data_acq_en ? 1'b1 : 1'b0;
		en_s  <= en_s1;
	end

always@(posedge bram_clk_b)
	if(r_rst)begin
		addr_s <= 'd0;
	end else if(en_s && data_acq_en)begin
		if(addr_s == addr_sel)begin//基地址+深度
			addr_s <= ~req_0 ? 'h10000 : addr_s;
		end else if(addr_s == ('h10000 + addr_sel))begin//基地址+深度
			addr_s <= ~req_1 ? 'd0 : addr_s;
		end else begin
			addr_s <= addr_s + 1'b1;
		end
	end else begin
		addr_s <= addr_s;
	end
	
assign din_s = {din_reg[7:0],din_reg[15:8],din_reg[23:16],din_reg[31:24],din_reg[39:32],din_reg[47:40],din_reg[55:48],din_reg[63:56]};//大小端序转换
		
assign wen_s = 8'b1111_1111;
/*******************************************************************************
// 			发起读请求中断
*******************************************************************************/
(* MARK_DEBUG="true" *)wire			[0:0]			usr_irq_ack;
(* MARK_DEBUG="true" *)reg			[0:0]		 	usr_irq_req;

(* MARK_DEBUG="true" *)reg			[2:0]			irq_ack;
(* MARK_DEBUG="true" *)reg			[2:0]			irq_state0;

always@(posedge bram_clk_b)irq_ack<={irq_ack[1:0],usr_irq_ack};//同步
always@(posedge bram_clk_b)
	if(r_rst)begin
		// usr_irq_req[0] <= 1'b0;
		req_0	<= 1'b0;
		irq_state0 <= 'd0;
	end else
		case(irq_state0)
			0	:	begin
						irq_state0 <= (addr_s == ('h10000 + addr_sel)) && en_s && ~req_1 ?  'd1 : 'd0;
						req_0	<= 1'b0;
						// usr_irq_req[0] <= 1'b0;
					end 
			1	:	begin	
						irq_state0 <= irq_ack[2] ?   'd2 : 'd1;
						req_0	<= 1'b1;
						// usr_irq_req[0] <= 1'b1;
					end 
			2	:	begin
						irq_state0 <=( clear_int_en && (ping_pang_sel) )? 'd0 : 'd2;
						req_0	<= 1'b1;
						// usr_irq_req[0] <= 1'b0;
					end
			default	:	irq_state0 <= 'd0;
		endcase
	

(* MARK_DEBUG="true" *)reg		[2:0]	irq_state1;

always@(posedge bram_clk_b)
	if(r_rst)begin
		// usr_irq_req[1] <= 1'b0;
		req_1	<= 1'b0;
		irq_state1 <= 'd0;
	end else 
		case(irq_state1)
			0	:	begin
						irq_state1 <= (addr_s == addr_sel) && en_s && ~req_0 ?  'd1 : 'd0;
						req_1	<= 1'b0;
						// usr_irq_req[1] <= 1'b0;
					end 
			1	:	begin	
						irq_state1 <= irq_ack[2] ?   'd2 : 'd1;
						req_1	<= 1'b1;
						// usr_irq_req[1] <= 1'b1;
					end 
			2	:	begin
						irq_state1 <= ( clear_int_en && (~ping_pang_sel) ) ? 'd0 : 'd2;
						req_1	<= 1'b1;
						// usr_irq_req[1] <= 1'b0;
					end
			default	:	irq_state1 <= 'd0;
		endcase
	
always@(posedge bram_clk_b)
	if(r_rst)begin
		usr_irq_req <= 1'b0;
	end else begin
		usr_irq_req <= ( irq_state0 == 'd1) | (irq_state1 == 'd1 )  ? 1'b1 : 1'b0;
	end
	
/*******************************************************************************
// 		xdma IP例化
*******************************************************************************/  
// wire	Phy_Clk;
XDMA_wrapper (
	.BRAM_PORTA_0_addr		(addr_b				),
    .BRAM_PORTA_0_clk		(bram_clk_b			),
    .BRAM_PORTA_0_din		(din_b				),
    .BRAM_PORTA_0_dout		(dout_b				),
    .BRAM_PORTA_0_en		(en_b				),
    .BRAM_PORTA_0_rst		(bram_rst_b			),
    .BRAM_PORTA_0_we		(wen_b				),
	
	.BRAM_PORTB_0_addr		({addr_s,3'b000}	),
    .BRAM_PORTB_0_clk		(bram_clk_b			),
    .BRAM_PORTB_0_din		(din_s				),
    .BRAM_PORTB_0_dout		(dout_s				),
    .BRAM_PORTB_0_en		(en_s				),
    .BRAM_PORTB_0_rst		(r_rst				),
    .BRAM_PORTB_0_we		(wen_s				),
	.pcie_mgt_0_rxn			(Pcie_rxn			),
    .pcie_mgt_0_rxp			(Pcie_rxp			),
    .pcie_mgt_0_txn			(Pcie_txn			),
    .pcie_mgt_0_txp			(Pcie_txp			),
    .axi_aclk_0				(					),
    .axi_aresetn_0			(					),
    .sys_clk_0				(Pcie_refclk		),
    .sys_rst_n_0			(pcie_rstn			),
    .user_lnk_up_0			(user_lnk_up		),
    .usr_irq_ack_0			(usr_irq_ack		),
    .usr_irq_req_0			(usr_irq_req		)
	);
	
/*******************************************************************************
// 	end
*******************************************************************************/


endmodule 
	