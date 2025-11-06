`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 2025/09/17 11:34:47
// Design Name: zcy
// Module Name: sys_ctrl_cfg_reg
// Project Name: XDMA_SSI
// Target Devices: 
// Tool Versions: 
// Description: 模块实现了 “外部主控 - 采集系统” 的多通道控制接口，核心功能流程如下：
//						1、外部主控通过总线写入 addr_b/din_b/en_b，配置 single_sample（中断触发深度）；
//						2、主控写入 “启动命令”（addr_b=00 或 10 写 通道标识），data_acq_en 置 1，对应通道采集系统启动；
//						3、采集系统按 single_sample 次数采集数据，存入当前乒乓缓冲区（ping_pang_sel=0）；
//						4、采集完成后触发中断，主控读取数据并写入 addr_b=40 清中断；
//						5、清中断时 ping_pang_sel 翻转，下次采集存入另一缓冲区，避免冲突；
//						6、主控写入 “停止命令”（addr_b=08 或 10 写 通道标识），data_acq_en 置 0，对应通道采集停止。
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module cfg_reg_ctrl#(
	parameter				S_CHANNEL	=	2	//通道数量（支持 1：单通道、2：双通道）
)(
	input					Clk,
	input					Rst,
	input					en_b,
	input	[15:0]			wen_b,
	input	[12:0]			addr_b,
	input	[127:0]			din_b,
	output	reg[127:0]		dout_b,
	output	reg[7:0]		RX_SIZE,
	output	reg				cs_en,
	output	reg	[2:0]		Scl_ctrl,
	input	[S_CHANNEL-1:0]	ping_pang_sel,	//乒乓指示
	output	reg[S_CHANNEL-1:0]	data_acq_en, //采集使能
	output	reg				clear_int_en,//清中断标志
	output	reg[16:0]		single_sample//中断触发深度（单次采样次数）	
);
/*******************************************************************************
// 			复位同步 
*******************************************************************************/
reg		[2:0]		rst;
wire				r_rst;
always@(posedge Clk) rst <= {rst[1:0],Rst};
	
assign r_rst = rst[2];

/*******************************************************************************
// 			清中断标志  
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
        clear_int_en <= 1'b0;//写入地址20+偏移地址00 == 04
    end else if(addr_b == 12'h40) begin
		clear_int_en <= en_b ?  1'b1 : 1'b0;  // 断言清中断标志
	end else begin
		clear_int_en <= 1'b0;
	end

/*******************************************************************************
// 			采集使能 
*******************************************************************************/

 reg		[S_CHANNEL-1:0]			stat_data;
 reg		[S_CHANNEL-1:0]			stop_data;

reg			[3:0]				byte_en;
always@(*)begin
	case(wen_b)
		16'b0000_0000_0000_0001	:	byte_en <= 'd0;	//低字节
		16'b0000_0000_0000_0010	:	byte_en <= 'd1;
		16'b0000_0000_0000_0100	:	byte_en <= 'd2;
		16'b0000_0000_0000_1000	:	byte_en <= 'd3;
		16'b0000_0000_0001_0000	:	byte_en <= 'd4;
		16'b0000_0000_0010_0000	:	byte_en <= 'd5;
		16'b0000_0000_0100_0000	:	byte_en <= 'd6;
		16'b0000_0000_1000_0000	:	byte_en <= 'd7;
		16'b0000_0001_0000_0000	:	byte_en <= 'd8;	
		16'b0000_0010_0000_0000	:	byte_en <= 'd9;
		16'b0000_0100_0000_0000	:	byte_en <= 'd10;
		16'b0000_1000_0000_0000	:	byte_en <= 'd11;
		16'b0001_0000_0000_0000	:	byte_en <= 'd12;
		16'b0010_0000_0000_0000	:	byte_en <= 'd13;
		16'b0100_0000_0000_0000	:	byte_en <= 'd14;
		16'b1000_0000_0000_0000	:	byte_en <= 'd15;//高字节
		default			:	byte_en <= 'd0;
	endcase
end

generate
	genvar ch;  // 循环变量
    // 根据S_CHANNEL参数循环例化模块，i从0到S_CHANNEL-1
    for (ch = 0; ch < S_CHANNEL; ch = ch + 1) begin : ssi_channel  // 块名用于区分不同实例   
		//开始
		always@(posedge Clk)
			if(r_rst)begin
				stat_data[ch] <= 1'b0;
			end else if((addr_b == 12'h00 && din_b[byte_en*8 +: 8]  == ch) |(addr_b == 12'h20 && din_b[byte_en*8 +: 8]  == 8'h01))begin
				stat_data[ch] <= en_b ?  1'b1 : 1'b0;
			end else begin
				stat_data[ch] <= 1'b0;
			end
			
		//停止	
		always@(posedge Clk)
			if(r_rst)begin
				stop_data[ch] <= 1'b0;
			end else if((addr_b ==12'h10 && din_b[byte_en*8 +: 8]  == ch)|(addr_b == 12'h20 && din_b[byte_en*8 +: 8]  == 8'h00))begin
				stop_data[ch] <= en_b ?  1'b1 : 1'b0;
			end else begin
				stop_data[ch] <= 1'b0;
			end
		//采集使能 
		always@(posedge Clk)
			if(r_rst)begin
				data_acq_en[ch] <= 1'b0;
			end else if(stat_data[ch])begin
				data_acq_en[ch] <= 1'b1;
			end else if(stop_data[ch])begin
				data_acq_en[ch] <= 1'b0;
			end else begin
				data_acq_en[ch] <= data_acq_en[ch];
			end	
    end
endgenerate
/*******************************************************************************
// 			动态调节接收位宽（接收分辨率）	
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		RX_SIZE <= 8'd24;
	end else if(addr_b == 13'h80)begin
		RX_SIZE <= en_b ? din_b[byte_en*8 +: 8] : RX_SIZE;
	end else begin
		RX_SIZE <= RX_SIZE;
	end	
/*******************************************************************************
// 			中断触发深度（单次采样次数）	
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		single_sample <= 17'd0;
	end else if(addr_b == 13'h50)begin
		single_sample <= en_b ? din_b[16:0] : single_sample;
	end else begin
		single_sample <= single_sample;
	end
/*******************************************************************************
// 			片选使能	
*******************************************************************************/
 reg					stat_cs;
 reg					stop_cs;
always@(posedge Clk)
	if(r_rst)begin
		stat_cs <= 1'b0;
	end else if((addr_b == 12'h60 && din_b[byte_en*8 +: 8]  == 8'h01))begin
		stat_cs <= en_b ?  1'b1 : 1'b0;
	end else begin
		stat_cs <= 1'b0;
	end
	
//停止	
always@(posedge Clk)
	if(r_rst)begin
		stop_cs <= 1'b0;
	end else if((addr_b == 12'h60 && din_b[byte_en*8 +: 8]  == 8'h00))begin
		stop_cs <= en_b ?  1'b1 : 1'b0;
	end else begin
		stop_cs <= 1'b0;
	end
	
always@(posedge Clk)
	if(r_rst)begin
		cs_en <= 1'b1;
	end else if(stat_cs)begin
		cs_en <= 1'b1;
	end else if(stop_cs)begin
		cs_en <= 1'b0;
	end else begin
		cs_en <= cs_en;
	end
/*******************************************************************************
// 			采集时钟控制
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		Scl_ctrl <= 'd1;
	end else if(addr_b == 13'h70)begin
		Scl_ctrl <= en_b ? din_b[byte_en*8 +: 8] : Scl_ctrl;
	end else begin
		Scl_ctrl <= Scl_ctrl;
	end

/*******************************************************************************
// 			输出	
*******************************************************************************/	
always@(*)begin
	case(addr_b)
		12'h00	:	dout_b = data_acq_en;
		12'h10	:	dout_b = data_acq_en;
		12'h20	:	dout_b = data_acq_en;
		12'h30	:	dout_b = ping_pang_sel;
		13'h50	:	dout_b = single_sample;
		13'h60	:	dout_b = cs_en;
		13'h70	:	dout_b = Scl_ctrl;
		13'h80	:	dout_b = RX_SIZE;
		default	:	dout_b = 64'h0;
	endcase
end
/*******************************************************************************
// 			end	
*******************************************************************************/
endmodule 