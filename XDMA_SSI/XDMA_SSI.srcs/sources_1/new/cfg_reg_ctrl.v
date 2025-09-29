`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 2025/09/17 11:34:47
// Design Name: zcy
// Module Name: sys_ctrl_cfg_reg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 模块实现了 “外部主控 - 采集系统” 的控制接口，核心功能流程如下：
//						1、外部主控通过总线写入 addr_b/din_b/en_b，配置 single_sample（中断触发深度）；
//						2、主控写入 “启动命令”（addr_b=00 或 10 写 01），data_acq_en 置 1，采集系统启动；
//						3、采集系统按 single_sample 次数采集数据，存入当前乒乓缓冲区（ping_pang_sel=0）；
//						4、采集完成后触发中断，主控读取数据并写入 addr_b=20 清中断；
//						5、清中断时 ping_pang_sel 翻转，下次采集存入另一缓冲区，避免冲突；
//						6、主控写入 “停止命令”（addr_b=08 或 10 写 00），data_acq_en 置 0，采集停止。
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module cfg_reg_ctrl(
	input					Clk,
	input					Rst,
	input					en_b,
	input	[7:0]			wen_b,
	input	[11:0]			addr_b,
	input	[63:0]			din_b,
	output	reg[63:0]		dout_b,
	output	reg				cs_en,
	output	reg				Sda_ctrl,
	output	reg				ping_pang_sel,	//乒乓指示
	output	reg				data_acq_en, //采集使能
	output	reg				clear_int_en,//清中断标志
	output	reg[2:0]		single_sample//中断触发深度（单次采样次数）	
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
    end else if(addr_b == 12'h20) begin
		clear_int_en <= en_b ?  1'b1 : 1'b0;  // 断言清中断标志
	end else begin
		clear_int_en <= 1'b0;
	end
  
/*******************************************************************************
// 			乒乓操作指示  
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		ping_pang_sel <= 1'b0;	//默认乒（0）操作
	end else begin
		ping_pang_sel <= clear_int_en ? ~ping_pang_sel : ping_pang_sel;//读一次清一次中断，读完一次换另一块bram
	end

/*******************************************************************************
// 			采集使能 
*******************************************************************************/
//开始
(* MARK_DEBUG="true" *)reg					stat_data;
(* MARK_DEBUG="true" *)reg					stop_data;

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

always@(posedge Clk)
	if(r_rst)begin
		stat_data <= 1'b0;
	end else if((addr_b == 12'h00) |(addr_b == 12'h10 && din_b[byte_en*8 +: 8]  == 8'h01))begin
		stat_data <= en_b ?  1'b1 : 1'b0;
	end else begin
		stat_data <= 1'b0;
	end
	
//停止	
always@(posedge Clk)
	if(r_rst)begin
		stop_data <= 1'b0;
	end else if((addr_b ==12'h08)|(addr_b == 12'h10 && din_b[byte_en*8 +: 8]  == 8'h00))begin
		stop_data <= en_b ?  1'b1 : 1'b0;
	end else begin
		stop_data <= 1'b0;
	end
	
//采集使能 
always@(posedge Clk)
	if(r_rst)begin
		data_acq_en <= 1'b0;
	end else if(stat_data)begin
		data_acq_en <= 1'b1;
	end else if(stop_data)begin
		data_acq_en <= 1'b0;
	end else begin
		data_acq_en <= data_acq_en;
	end

/*******************************************************************************
// 			中断触发深度（单次采样次数）	
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		single_sample <= 3'd0;
	end else if(addr_b == 12'h28)begin
		single_sample <= en_b ? din_b[2:0] : single_sample;
	end else begin
		single_sample <= single_sample;
	end
/*******************************************************************************
// 			片选使能	
*******************************************************************************/
(* MARK_DEBUG="true" *)reg					stat_cs;
(* MARK_DEBUG="true" *)reg					stop_cs;
always@(posedge Clk)
	if(r_rst)begin
		stat_cs <= 1'b0;
	end else if((addr_b == 12'h30 && din_b[byte_en*8 +: 8]  == 8'h01))begin
		stat_cs <= en_b ?  1'b1 : 1'b0;
	end else begin
		stat_cs <= 1'b0;
	end
	
//停止	
always@(posedge Clk)
	if(r_rst)begin
		stop_cs <= 1'b0;
	end else if((addr_b == 12'h30 && din_b[byte_en*8 +: 8]  == 8'h00))begin
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
(* MARK_DEBUG="true" *)reg					stat_scl;
(* MARK_DEBUG="true" *)reg					stop_scl;
always@(posedge Clk)
	if(r_rst)begin
		stat_scl <= 1'b0;
	end else if((addr_b == 12'h40 && din_b[byte_en*8 +: 8]  == 8'h01))begin
		stat_scl <= en_b ?  1'b1 : 1'b0;
	end else begin
		stat_scl <= 1'b0;
	end
	
//停止	
always@(posedge Clk)
	if(r_rst)begin
		stop_scl <= 1'b0;
	end else if((addr_b == 12'h40 && din_b[byte_en*8 +: 8]  == 8'h00))begin
		stop_scl <= en_b ?  1'b1 : 1'b0;
	end else begin
		stop_scl <= 1'b0;
	end
	
always@(posedge Clk)
	if(r_rst)begin
		Sda_ctrl <= 1'b0;
	end else if(stat_scl)begin
		Sda_ctrl <= 1'b1;
	end else if(stop_scl)begin
		Sda_ctrl <= 1'b0;
	end else begin
		Sda_ctrl <= Sda_ctrl;
	end
	
/*******************************************************************************
// 			输出	
*******************************************************************************/	
always@(*)begin
	case(addr_b)
		12'h00	:	dout_b = data_acq_en;
		12'h08	:	dout_b = data_acq_en;
		12'h10	:	dout_b = data_acq_en;
		12'h18	:	dout_b = ping_pang_sel;
		12'h28	:	dout_b = single_sample;
		default	:	dout_b = 64'h0;
	endcase
end
/*******************************************************************************
// 			end	
*******************************************************************************/
endmodule 