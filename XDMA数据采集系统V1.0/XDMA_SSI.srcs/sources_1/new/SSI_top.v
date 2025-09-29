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
/*******************************************************************************
// 		数据采集模块
*******************************************************************************/


SSI_interface#(
		.RX_SIZE				(24			),//16位分辨率
		.CLK_T					(16			),	//输入时钟周期
		.SDA_CTRL				(1			)	//发送时钟周期  0：1.52MHz  1： 62.5KHz		
	)SSI_interface_ins(
		.Phy_Clk				(bram_clk_b	),//62.5MHz
		.Phy_Rst				(r_rst		),
		.Ssclk					(Ssclk		),
		.Cs_n					(Cs_n		),
		.Ssda					(Ssda		),
		.Data_out				(data_out	),
		.Data_flag				(data_flag	)
	);
	
/*******************************************************************************
// 			text
******************************************************************************* /
(* MARK_DEBUG="true" *)reg			[5:0]			cct;
always@(posedge bram_clk_b)
	if(r_rst)begin
		cct <= 'd0;
	end else begin
		cct <= cct + 1'b1;
	end
	
assign data_flag =  cct == 6'b111111 ? 1'b1 : 1'b0;

always@(posedge bram_clk_b)
	if(r_rst)
		data_out <= 'd0;
	else if(addr_s < 'h200)begin
		data_out <= data_flag ? data_out + 1'b1 : data_out; 
	end else begin
		data_out <=  data_out;
	end
	
/*******************************************************************************
// 		数据位宽转换：24bit转64bit
*******************************************************************************/
(* MARK_DEBUG="true" *)reg			[63:0]			din_reg;
(* MARK_DEBUG="true" *)reg							en_s1;
(* MARK_DEBUG="true" *)reg			[3:0]			reg_cnt;

(* MARK_DEBUG="true" *)reg							en_s;	
(* MARK_DEBUG="true" *)wire			[7:0]			wen_s;
(* MARK_DEBUG="true" *)reg			[9:0]			addr_s;
(* MARK_DEBUG="true" *)wire			[63:0]			din_s;
(* MARK_DEBUG="true" *)wire			[63:0]			dout_s;

(* MARK_DEBUG="true" *)wire		[31:0]			data_all;

assign data_all	= {2'b00,data_out[23:10],4'b0000,data_out[9:6],2'b00,data_out[5:0]};//14bit 数据+4bit 状态+6bit CRC

always@(posedge bram_clk_b)
	if(r_rst)begin
		data_reg <= 'd0;
	end else begin
		data_reg <= data_flag ? {data_reg[31:0],data_all} : data_reg;
	end 
		
always@(posedge bram_clk_b)
	if(r_rst)begin
		reg_cnt <= 'd0;
		din_reg <= 'd0;
	end else if(data_flag)begin
		reg_cnt <=  reg_cnt == 'd1 ? 'd0 : reg_cnt + 1'b1;
		din_reg <= 	reg_cnt == 'd1 ? {data_reg[31:0],data_all}: din_reg;
	end else begin
		reg_cnt <= reg_cnt;
		din_reg <= din_reg;
	end

/*******************************************************************************
// 		数据写入bram
*******************************************************************************/
(* MARK_DEBUG="true" *)reg				req_1;
(* MARK_DEBUG="true" *)reg				req_0;
always@(posedge bram_clk_b)
	if(r_rst)begin	
		en_s1 <= 1'b0;
		en_s  <= 1'b0;
	end else if((addr_s == 'h100 && req_0) | (addr_s == 'h200 && req_1) )begin
		en_s1 <= 1'b0;
		en_s  <= en_s1;
	end else begin
		en_s1 <= data_flag && reg_cnt == 'd1 ? 1'b1 : 1'b0;
		en_s  <= en_s1;
	end

always@(posedge bram_clk_b)
	if(r_rst)
		addr_s <= 'd0;
	else if(en_s)begin
		if(addr_s == 'h100)begin
			addr_s <= ~req_0 ? addr_s + 1'b1 : addr_s;
		end else if(addr_s == 'h200)begin
			addr_s <= ~req_1 ? 'd0 : addr_s;
		end else begin
			addr_s <= addr_s + 1'b1;
		end
	end
	
assign din_s = {din_reg[7:0],din_reg[15:8],din_reg[23:16],din_reg[31:24],din_reg[39:32],din_reg[47:40],din_reg[55:48],din_reg[63:56]};//大小端序转换
		
assign wen_s = 8'b1111_1111;
/*******************************************************************************
// 			发起读请求中断
*******************************************************************************/
(* MARK_DEBUG="true" *)wire			[1:0]			usr_irq_ack;
(* MARK_DEBUG="true" *)reg			[1:0]		 	usr_irq_req;

(* MARK_DEBUG="true" *)reg							clear_int_en0;
(* MARK_DEBUG="true" *)reg							clear_int_en1;

(* MARK_DEBUG="true" *)reg			[2:0]			irq_ack0;
(* MARK_DEBUG="true" *)reg			[2:0]			irq_state0;

always@(posedge bram_clk_b)irq_ack0<={irq_ack0[1:0],usr_irq_ack[0]};//同步
always@(posedge bram_clk_b)
	if(r_rst)begin
		usr_irq_req[0] <= 1'b0;
		req_0	<= 1'b0;
		irq_state0 <= 'd0;
	end else
		case(irq_state0)
			0	:	begin
						irq_state0 <= addr_s == 'h200 && en_s && ~req_1 ?  'd1 : 'd0;
						req_0	<= 1'b0;
						usr_irq_req[0] <= 1'b0;
					end 
			1	:	begin	
						irq_state0 <= irq_ack0[2] ?   'd2 : 'd1;
						req_0	<= 1'b1;
						usr_irq_req[0] <= 1'b1;
					end 
			2	:	begin
						irq_state0 <= clear_int_en0 ? 'd0 : 'd2;
						req_0	<= 1'b1;
						usr_irq_req[0] <= 1'b0;
					end
			default	:	irq_state0 <= 'd0;
		endcase
	

(* MARK_DEBUG="true" *)reg		[2:0]	irq_ack1;
(* MARK_DEBUG="true" *)reg		[2:0]	irq_state1;

always@(posedge bram_clk_b)irq_ack1<={irq_ack1[1:0],usr_irq_ack[1]};//同步
always@(posedge bram_clk_b)
	if(r_rst)begin
		usr_irq_req[1] <= 1'b0;
		req_1	<= 1'b0;
		irq_state1 <= 'd0;
	end else 
		case(irq_state1)
			0	:	begin
						irq_state1 <= addr_s == 'h100 && en_s && ~req_0 ?  'd1 : 'd0;
						req_1	<= 1'b0;
						usr_irq_req[1] <= 1'b0;
					end 
			1	:	begin	
						irq_state1 <= irq_ack1[2] ?   'd2 : 'd1;
						req_1	<= 1'b1;
						usr_irq_req[1] <= 1'b1;
					end 
			2	:	begin
						irq_state1 <= clear_int_en1 ? 'd0 : 'd2;
						req_1	<= 1'b1;
						usr_irq_req[1] <= 1'b0;
					end
			default	:	irq_state1 <= 'd0;
		endcase
	
/*******************************************************************************
// 			Bypass通道清中断
*******************************************************************************/
wire 		[7:0]			wen_b;
wire 		[11:0]			addr_b;
wire 						en_b;
wire 		[63:0]			dout_b = 64'd0;
wire 		[63:0]			din_b;

reg		[3:0]				byte_en;
always@(*)begin
	case(wen_b)
		8'b0000_0001	:	byte_en <= 'd0;	//低字节
		8'b0000_0010	:	byte_en <= 'd1;
		8'b0000_0100	:	byte_en <= 'd2;
		8'b0000_1000	:	byte_en <= 'd3;
		8'b0001_0000	:	byte_en <= 'd4;
		8'b0010_0000	:	byte_en <= 'd5;
		8'b0100_0000	:	byte_en <= 'd6;
		8'b1000_0000	:	byte_en <= 'd7;//高字节
		default			:	byte_en <= 'd0;
	endcase
end

always@(posedge bram_clk_b)
	if(r_rst)begin
        clear_int_en0 <= 1'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址38+偏移地址00 == 38
        if(addr_b == 12'h38 && din_b[byte_en*8 +: 8]  == 8'h7A) begin
            clear_int_en0 <= 1'b1;  // 断言清中断标志
        end else begin
            clear_int_en0 <= 1'b0;
        end
    end else begin
        clear_int_en0 <= 1'b0;
    end

always@(posedge bram_clk_b)
	if(r_rst)begin
        clear_int_en1 <= 1'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址38+偏移地址00 == 38
        if(addr_b == 12'h40 && din_b[byte_en*8 +: 8]  == 8'h7A) begin
            clear_int_en1 <= 1'b1;  // 断言清中断标志
        end else begin
            clear_int_en1 <= 1'b0;
        end
    end else begin
        clear_int_en1 <= 1'b0;
    end


/*******************************************************************************
// 	xdma IP例化
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
	.BRAM_PORTB_0_addr		({19'd0,addr_s,3'b000}	),
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
    .axi_aclk_0				(			),
    .axi_aresetn_0			(			),
    .sys_clk_0				(Pcie_refclk		),
    .sys_rst_n_0			(pcie_rstn			),
    .user_lnk_up_0			(user_lnk_up		),
    .usr_irq_ack_0			(usr_irq_ack		),
    .usr_irq_req_0			(usr_irq_req		)
	);
/*******************************************************************************
// 	end
*******************************************************************************/  
wire		[94:0]		probe0;
(* MARK_DEBUG="true" *)wire					sda1,sclk1,cs_1;
assign	sda1 = Ssda;
assign	cs_1 = Cs_n;
assign sclk1 = Ssclk;	
	ila_0 ila_ins (
	.clk(bram_clk_b), // input wire clk

	.probe0(probe0) // input wire [16:0] probe0
);
	
assign	probe0[15:0] = data_out;
assign	probe0[16] 	= data_flag;
assign	probe0[17] 	= sda1;
assign	probe0[18] 	= sclk1;
assign	probe0[28:19] = addr_s;
assign	probe0[29] = en_s;
assign	probe0[93:30] = din_reg;
assign	probe0[94] = r_rst;
//assign	probe0[77:65] = scl_cnt;

endmodule 
