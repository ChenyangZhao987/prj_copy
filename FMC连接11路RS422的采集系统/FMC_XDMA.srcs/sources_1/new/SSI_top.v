`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/23 11:34:47
// Design Name: zcy
// Module Name: fpga_top
// Project Name: XDMA_SSI
// Target Devices: 
// Tool Versions: 
// Description: 模块实现功能如下
//					PCIe接口管理和时钟处理
// 					多通道数据采集协调
// 					中断处理逻辑
// 					数据打包和CRC计算
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module SSI_top #(
	parameter					S_CHANNEL	=	2	//通道数量（支持 1：单通道、2：双通道、3：三通道、4:四通道）S_CHANNEL不能为0！
)(
    input  	      	 			Pcie_rstn,//PCIe复位
    input  	      	 			Pcie_refclkp, Pcie_refclkn,//PCIE参考时钟 100MHz
    input  	 [3:0]	 			Pcie_rxp, Pcie_rxn,
    output 	 [3:0]	 			Pcie_txp, Pcie_txn,
	output	[S_CHANNEL-1:0]		Scl,
	output	[S_CHANNEL-1:0]		Cs_n,
	input	[S_CHANNEL-1:0]		Sda,
	output	[S_CHANNEL-1:0]		RE_422,//第 S_CHANNEL-1 路 RS422 接收 RE 使能
	output	[S_CHANNEL-1:0]		DE_422,//第 S_CHANNEL-1 路 RS422 发送 DE 使能
	//led显示链路状态
	output						Led0
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

reg			[2:0]			rr_rst;
always@(posedge bram_clk_b) rr_rst <= {rr_rst[1:0],bram_rst_b};//复位
 wire						r_rst;

assign	r_rst	= rr_rst[2];

assign	Led0 = user_lnk_up;//LED显示链路状态

(* MARK_DEBUG="true" *)reg			[63:0]				data_reg		[0:S_CHANNEL-1];
(* MARK_DEBUG="true" *)wire			[S_CHANNEL-1:0]				scl1;
(* MARK_DEBUG="true" *)wire			[S_CHANNEL-1:0]				sda1;
assign scl1[0] = Scl[0];
assign sda1[0] = Sda[0];
assign RE_422  = 'd0;//发送使能：低电平有效
assign DE_422  = 2'b11;//接收使能：高电平有效

/*******************************************************************************
// 		配置寄存器
*******************************************************************************/
(* MARK_DEBUG="true" *)wire 		[15:0]			wen_b;
(* MARK_DEBUG="true" *)wire 		[12:0]			addr_b;
(* MARK_DEBUG="true" *)wire 						en_b;
(* MARK_DEBUG="true" *)wire 		[127:0]			dout_b ;
(* MARK_DEBUG="true" *)wire 		[127:0]			din_b;

wire			[S_CHANNEL-1:0]	ping_pang_sel;	//乒乓指示
(* MARK_DEBUG="true" *)wire			[S_CHANNEL-1:0]	data_acq_en; //采集使能
wire			[7:0]			RX_SIZE;//清中断标志
wire							clear_int_en;//清中断标志
(* MARK_DEBUG="true" *)wire			[16:0]			single_sample;//中断触发深度（单次采样次数）
wire							cs_en;	//片选使能
(* MARK_DEBUG="true" *)wire			[2:0]			Scl_ctrl;	//片选使能

cfg_reg_ctrl#(
	.S_CHANNEL					(S_CHANNEL				)
	)cfg_reg_ctrl_ins(
	.Clk						(bram_clk_b				),
	.Rst						(r_rst					),
	.en_b						(en_b					),
	.wen_b						(wen_b					),
	.addr_b						(addr_b					),
	.din_b						(din_b					),
	.dout_b						(dout_b					),
	.cs_en						(cs_en					),
	.Scl_ctrl					(Scl_ctrl				),
	.RX_SIZE    				(RX_SIZE				),//分辨率
	.ping_pang_sel				(ping_pang_sel			),//乒乓指示
	.data_acq_en				(data_acq_en			),//采集使能
	.clear_int_en				(clear_int_en			),//清中断标志
	.single_sample				(single_sample			) //中断触发深度（单次采样次数）	
);

/*******************************************************************************
// 	数据采集模块
*******************************************************************************/
(* MARK_DEBUG="true" *)wire	[S_CHANNEL-1:0]		irq_req;
(* MARK_DEBUG="true" *)wire	[S_CHANNEL-1:0]		error;
(* MARK_DEBUG="true" *)wire	[S_CHANNEL-1:0]		warning;
(* MARK_DEBUG="true" *)wire		[31:0]			ch_waddr	[0:S_CHANNEL-1];
(* MARK_DEBUG="true" *)wire		[63:0]			ch_wdata	[0:S_CHANNEL-1];
(* MARK_DEBUG="true" *)wire		[S_CHANNEL-1:0]	ch_wen; 

generate
    genvar i;  // 循环变量
    // 根据S_CHANNEL参数循环例化模块，i从0到S_CHANNEL-1
    for (i = 0; i < S_CHANNEL; i = i + 1) begin : ssi_channel
		unipath_data_collection#(
			.CLK_T				(8						),
			.CRC_EN				(0						)
			)unipath_data_collection_inst(
			//全局同步接口
			.Clk				(bram_clk_b				),//全局同步
			.Rst				(r_rst					),//全局同步
			//SSI硬件接口
			.Sda				(Sda[i]					),
			.Scl				(Scl[i]					),
			.Cs_n				(Cs_n[i]				),
			//配置接口
			.RX_SIZE			(RX_SIZE				),//全局同步
			.cs_en				(cs_en					),//全局同步
			.Scl_ctrl			(Scl_ctrl				),//采集时钟控制
			.data_acq_en		(data_acq_en[i]			),//通道i采集使能
			.single_sample		(single_sample			),//单次单区块数据数量全局同步
			.clear_int_en		(clear_int_en			),//清中断
			.irq_req			(irq_req[i]				),
			.error				(error[i]				),
			.warning			(warning[i]				),
			//写入请求接口
			.ch_waddr			(ch_waddr[i]			),
			.ch_wdata			(ch_wdata[i]			),
			.ch_wen				(ch_wen[i]				),
			.ping_pang_sel	    (ping_pang_sel[i]		)	
		);
		always@(posedge bram_clk_b)
			if(r_rst)begin
				data_reg[i] <= 'd0;
			end else if(ch_wen[i])begin
				data_reg[i] <=ch_wdata[i];
			end else begin
				data_reg[i] <=data_reg[i];
			end
			
    end
endgenerate

/*******************************************************************************
// 			地址分配与计算(分配4通道实际以S_CHANNEL为准)
*******************************************************************************/	
localparam OFFSET_CH0 = 'h0	;		//0-FFFF
localparam OFFSET_CH1 = 'h10000;	//10000-1FFFF
localparam OFFSET_CH2 = 'h20000;	//20000-2FFFF
localparam OFFSET_CH3 = 'h30000;	//30000-3FFFF
localparam MAX_LOCAL_ADDR = 'hFFFF;	//单通道最大本地地址（64KB==65536字节）
/*******************************************************************************
// 			写入bram
*******************************************************************************/

(* MARK_DEBUG="true" *)reg			[3:0]			cnt_with;
(* MARK_DEBUG="true" *)reg			[63:0]			befor_data;
(* MARK_DEBUG="true" *)reg			[31:0]			addr_s;
(* MARK_DEBUG="true" *)reg							en_s;
 wire			[15:0]			wen_s;
always@(posedge bram_clk_b)
	if(r_rst)begin
		cnt_with <= 'd0;
	end else case(cnt_with)
		0		:	cnt_with <= (|ch_wen) ? cnt_with + 1 : 'd0;//任何一个通道发起写请求计数器启动
		1,2,3,4	:	cnt_with <= (cnt_with == S_CHANNEL)? 'd0 : cnt_with + 1;  
		default	:	cnt_with <= 'd0;
	endcase 

always@(posedge bram_clk_b)
	if(r_rst)begin
		en_s <= 1'b0;
		addr_s <= 'd0;
	end else case(cnt_with)
		1:	begin//对应四个通道
				en_s <= data_acq_en[0]&&(ch_waddr[0] <= MAX_LOCAL_ADDR)? 1'b1 : 1'b0;
				addr_s <= ch_waddr[0] + OFFSET_CH0;//写入使能与地址跳变条件一致，不满足写入建立时间
			end
		2:	begin
				en_s <= data_acq_en[1]&&(ch_waddr[1] <= MAX_LOCAL_ADDR)? 1'b1 : 1'b0;
				addr_s <= ch_waddr[1] + OFFSET_CH1;
			end
		3:	begin
				en_s <= data_acq_en[2]&&(ch_waddr[2] <= MAX_LOCAL_ADDR)? 1'b1 : 1'b0;
				addr_s <= ch_waddr[2] + OFFSET_CH2;
			end 
		4:	begin
				en_s <= data_acq_en[3]&&(ch_waddr[3] <= MAX_LOCAL_ADDR)? 1'b1 : 1'b0;
				addr_s <= ch_waddr[3] + OFFSET_CH3;
			end
		default	:	begin en_s <= 1'b0;	addr_s <= addr_s; end
	endcase

always@(posedge bram_clk_b)
	if(r_rst)begin
		befor_data <= 64'd0;
	end else case(cnt_with)
		1	:	befor_data <= data_reg[0];
		2	:	befor_data <= data_reg[1];
		3	:	befor_data <= data_reg[2];
		4	:	befor_data <= data_reg[3];
		default:befor_data <= 'd0;
	endcase
	
// (* MARK_DEBUG="true" *)reg			[31:0]			addr_s;

// always@(posedge bram_clk_b)
	// if(r_rst)begin
		// addr_s <= 'd0;
	// end else begin//对地址打拍延迟一周期满足保持时间
		// addr_s <= addr_s;
	// end
	
assign wen_s = 16'b1111_1111_1111_1111;
/*******************************************************************************
// 				中断处理
*******************************************************************************/
(* MARK_DEBUG="true" *)wire					irq_all;
assign irq_all = &(irq_req | ~data_acq_en);//所有使能通道按位与，未使能通道忽略

wire						usr_irq_ack;
reg							usr_irq_req;
reg			[2:0]			irq_state0;
reg			[2:0]			irq_ack;
always@(posedge bram_clk_b)irq_ack<={irq_ack[1:0],usr_irq_ack};//同步
always@(posedge bram_clk_b)
	if(r_rst)begin
		usr_irq_req		<= 1'b0;
		irq_state0 	<= 'd0;
	end else
		case(irq_state0)
			0	:	begin
						irq_state0 <= irq_all ?  'd1 : 'd0;
						usr_irq_req	<= 1'b0;
					end 
			1	:	begin
						irq_state0 <= irq_ack[2] ?   'd2 : 'd1;
						usr_irq_req	<= 1'b1;
					end 
			2	:	begin
						irq_state0 <=(clear_int_en)? 'd0 : 'd2;
						usr_irq_req	<= 1'b0;
					end
			default	:	irq_state0 <= 'd0;
		endcase

/*******************************************************************************
// 			数据打包
*******************************************************************************/
(* MARK_DEBUG="true" *)wire			[15:0]			time_base;
(* MARK_DEBUG="true" *)wire			[127:0]			din_s;
(* MARK_DEBUG="true" *)wire			[127:0]			data_s_reg;
(* MARK_DEBUG="true" *)wire			[5:0]			CRC;

//CRC产生模块
CRC_calculator #(
	.CRC_WIDTH 				(6				), 	// CRC校验位宽度（默认6位）
	.DATA_WIDTH				(91				), 	// 输入数据宽度（默认18位）
	.POLYNOMIAL				(6'b000011		),	// 多项式（CRC_WIDTH位，默认0x03）
	.INIT_VALUE				(6'b000000		),	// 初始值（CRC_WIDTH位，默认0x00）
	.REFIN     				(1'b0			),	// 输入是否反转（0=不反转，1=反转，默认0）
	.REFOUT    				(1'b0			) 	// 输出是否反转（0=不反转，1=反转，默认0）
)uut(
    .data_in				({cnt_with, warning[cnt_with-1], error[cnt_with-1], 5'd0, time_base, befor_data}),  // 输入数据（宽度由DATA_WIDTH定义）
    .crc_out				(CRC			)  // CRC输出（宽度由CRC_WIDTH定义）
);	

//时基产生模块
time_base_gen time_base_gen(
	.clk				(bram_clk_b		),
	.Rst				(r_rst			),
	.time_base			(time_base		)
);	

//大小端序转换
assign din_s = {
	data_s_reg[7:0],   data_s_reg[15:8],  	data_s_reg[23:16], 	data_s_reg[31:24],
	data_s_reg[39:32], data_s_reg[47:40], 	data_s_reg[55:48], 	data_s_reg[63:56],
	data_s_reg[71:64], data_s_reg[79:72], 	data_s_reg[87:80], 	data_s_reg[95:88],
	data_s_reg[103:96],data_s_reg[111:104],	data_s_reg[119:112],data_s_reg[127:120]
};

//数据打包
assign	data_s_reg = {
	32'd0,			//d97-d127	无效位
	cnt_with,		//d93-d96 	通道标识位
	warning[cnt_with-1],//d92	警告位
	error[cnt_with-1],	//d91	错误位
	CRC,			//d85-d90 	CRC
	5'd0,			//d80-d84 	预留（默认0）
	time_base,		//d64-d79 	时基数据
	befor_data		//d63-d0 	采集数据
};
	
/*******************************************************************************
// 			xdma IP例化
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
	
	.BRAM_PORTB_0_addr		(addr_s				),
    .BRAM_PORTB_0_clk		(bram_clk_b			),
    .BRAM_PORTB_0_din		(din_s				),
    .BRAM_PORTB_0_dout		(					),
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