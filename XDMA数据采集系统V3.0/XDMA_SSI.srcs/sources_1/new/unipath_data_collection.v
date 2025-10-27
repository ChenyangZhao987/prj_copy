`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 11:34:47
// Design Name: zcy
// Module Name: unipath_data_collection
// Project Name: XDMA_PCIe
// Target Devices: 
// Tool Versions: 
// Description: 该模块为 XDMA_PCIe 项目的单通道数据采集核心模块，基于 SSI 接口实现数据的稳定采集、校验、存储与中断通知。核心功能包括：
// 					1、接收 SSI 硬件接口的串行数据（Sda），通过配置参数（Scl_ctrl、RX_SIZE 等）控制采集时钟（Scl）和片选（Cs_n），实现指定分辨率的数据采集；
// 					2、对采集数据进行 6 位 CRC 校验，剥离 CRC 字段后输出有效数据，同时检测 CRC 校验错误和设备状态异常，分别输出 error 和 warning 信号；
// 					3、支持可配置的单次采样数据量（single_sample），采用乒乓缓存机制（ping_pang_sel）将有效数据写入 BRAM，避免数据覆盖；
// 					4、当单块缓存数据写满时，生成中断请求（irq_req），支持外部清中断（clear_int_en）操作，实现数据采集与读取的同步协作；
// 					5、集成复位同步处理，确保模块在全局复位（Rst）时稳定初始化，保障采集流程的可靠性。
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module unipath_data_collection#(
	parameter				CLK_T				=	8
	)(
	//全局同步接口
	input					Clk,
	input					Rst,
	//SSI硬件接口
	input					Sda,
	output					Scl,
	output					Cs_n,
	//配置接口
	input		[7:0]		RX_SIZE,
	input					cs_en,
	input		[2:0]		Scl_ctrl,//采集时钟控制
	input					data_acq_en,//该通道采集使能
	input		[16:0]		single_sample,//单次单区块数据数量
	input					clear_int_en,//清中断
	output	reg				irq_req,
	output	reg				error,
	output	reg				warning,
	//写入请求接口
	output		[31:0]		ch_waddr,
	output	reg	[63:0]		ch_wdata,
	output	reg				ch_wen,
	output	reg				ping_pang_sel
);
/*******************************************************************************
// 		复位同步
*******************************************************************************/    
reg			[2:0]			rr_rst;
always@(posedge Clk) rr_rst <= {rr_rst[1:0],Rst};
 wire						r_rst;

assign	r_rst	= rr_rst[2];

/*******************************************************************************
// 		数据采集模块
*******************************************************************************/
(* MARK_DEBUG="true" *)wire			[63:0]			data_out;
(* MARK_DEBUG="true" *)wire							data_flag;
SSI_interface#(
		.CLK_T      (CLK_T					)  //时钟周期
	)SSI_interface_inst(
		.Phy_Clk    (Clk					),
		.Phy_Rst    (r_rst					),
		.Scl_ctrl   (Scl_ctrl				), //所有通道共用时钟控制
		.RX_SIZE    (RX_SIZE				), //分辨率
		.Ssclk      (Scl					), //通道的时钟
		.Cs_n       (Cs_n					), //通道的片选
		.cs_en      (cs_en					), //所有通道共用使能
		.Ssda       (Sda					), //通道的数据
		.Data_out   (data_out				), //通道的输出数据14bit 数据+4bit 状态+6bit CRC
		.Data_flag  (data_flag				)  //通道的数据稳定标志
);
/*******************************************************************************
// 		数据写入bram
*******************************************************************************/
reg				[13:0]		addr_sel;
reg				[27:0]		addr_s;
// (* MARK_DEBUG="true" *)wire						crc_valid ;
always@(*)begin
	case(single_sample)
		17'h0,17'h800	:	addr_sel = 14'h80;		//17'h800	
		17'h1,17'h1000	:	addr_sel = 14'h100;		//17'h1000	
		17'h2,17'h2000	:	addr_sel = 14'h200;		//17'h2000	
		17'h3,17'h4000	:	addr_sel = 14'h400;		//17'h4000	
		17'h4,17'h8000	:	addr_sel = 14'h800;		//17'h8000	
		// 17'h5,17'h10000	:	addr_sel = 14'h2000;	//17'h10000
		default:addr_sel = 14'h80;		//17'h800;
	endcase
end
	
reg							req_1;
reg							req_0;
reg							en_s1;
always@(posedge Clk)
	if(r_rst)begin
		en_s1 <= 1'b0;
		ch_wen  <= 1'b0;
	end else if( (addr_s == addr_sel && req_0) | (addr_s == ('h800 + addr_sel) && req_1) )begin
		en_s1 <= 1'b0;
		ch_wen  <= en_s1;
	end else begin
		en_s1 <= data_flag  && data_acq_en ? 1'b1 : 1'b0;
		ch_wen  <= en_s1;
	end 

always@(posedge Clk)
	if(r_rst)begin
		addr_s <= 'd0;
	end else if(~data_acq_en)begin
		addr_s <= 'd0;
	end else if(ch_wen && data_acq_en)begin
		if(addr_s == addr_sel)begin//基地址+深度
			addr_s <= ~req_0 ? 'h800 : addr_s;
		end else if(addr_s == ('h800 + addr_sel))begin//基地址+深度
			addr_s <= ~req_1 ? 'd0 : addr_s;
		end else begin
			addr_s <= addr_s + 1'b1;//数据64位8字节，每写一个数据，地址+8；
		end
	end else begin
		addr_s <= addr_s;
	end
	
assign ch_waddr = {addr_s,4'b0000};	//一个数据128bit，16字节（左移4位）	
/*******************************************************************************
// 			CRC
*******************************************************************************/
(* MARK_DEBUG="true" *)wire			[5:0]			crc_out	;
	
CRC_calculator #(
	.CRC_WIDTH 				(6				), 	// CRC校验位宽度
	.DATA_WIDTH				(18				), 	// 输入数据宽度
	.POLYNOMIAL				(6'b000011		),	// 多项式0x03
	.INIT_VALUE				(6'b000000		),	// 初始值0x00
	.REFIN     				(1'b0			),	// 输入是否反转（0=不反转，1=反转）
	.REFOUT    				(1'b0			) 	// 输出是否反转（0=不反转，1=反转）
)uut(
    .data_in				(data_out[18+5:6]),  // 输入数据（宽度由DATA_WIDTH定义）
    .crc_out				(crc_out		)  // CRC输出（宽度由CRC_WIDTH定义）
);

always@(posedge Clk)
	if(r_rst)begin
		ch_wdata 	<= 'd0;
		error		<= 'd0;
		warning		<= 'd0;
	end else begin
		ch_wdata 	<=  (data_flag && (crc_out == data_out[5:0])) ? {6'd0,data_out[63:6]} : ch_wdata;//剥离CRC
		error		<=	(data_flag && (crc_out != data_out[5:0]))? 1'b1 : 1'b0; 			//校验失败输出错误信号
		warning		<= 	(data_out[9:6] != 'd0 ) ? 1'b1 : 1'b0;								//设备状态位异常输出警告
	end 

/*******************************************************************************
// 				发起读请求中断
*******************************************************************************/
 reg			[2:0]			irq_state0;
always@(posedge Clk)
	if(r_rst)begin
		req_0		<= 1'b0;
		irq_state0 	<= 'd0;
	end else
		case(irq_state0)
			0	:	begin
						irq_state0 <= (addr_s == ('h800 + addr_sel)) && ch_wen && ~req_1 ?  'd1 : 'd0;
						req_0	<= 1'b0;
					end 
			1	:	begin
						irq_state0 <=( clear_int_en && (ping_pang_sel) )? 'd0 : 'd1;
						req_0	<= 1'b1;
					end
			default	:	irq_state0 <= 'd0;
		endcase


 reg			[2:0]			 irq_state1;

always@(posedge Clk)
	if(r_rst)begin
		req_1		<= 1'b0;
		irq_state1 	<= 'd0;
	end else
		case(irq_state1)
			0	:	begin
						irq_state1 <= (addr_s == addr_sel) && ch_wen && ~req_0 ?  'd1 : 'd0;
						req_1	<= 1'b0;
					end 
			1	:	begin
						irq_state1 <= ( clear_int_en && (~ping_pang_sel) ) ? 'd0 : 'd1;
						req_1	<= 1'b1;
					end
			default	:	irq_state1 <= 'd0;
		endcase

always@(posedge Clk)
	if(r_rst)begin
		irq_req <= 1'b0;
	end else begin
		irq_req <= (irq_state0 == 'd1) | (irq_state1 == 'd1 )  ? 1'b1 : 1'b0;
	end
/*******************************************************************************
// 			乒乓操作指示  
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		ping_pang_sel <= 1'b0;	//默认乒（0）操作
	end else begin
		ping_pang_sel <= clear_int_en && data_acq_en ? ~ping_pang_sel : ping_pang_sel;//读一次清一次中断，读完一次换另一块bram
	end
	

endmodule 