`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer: 
// 
// Create Date: 2025/09/16 11:34:47
// Design Name: zcy
// Module Name: sys_ctrl_cfg_reg
// Project Name: XDMA_PCIe
// Target Devices: 
// Tool Versions: 
// Description: 模块实现功能如下
// 				接收PC寄存器配置:
//					1:中断使能寄存器：'h50地址任意字节写入'h01;
//					2:脉冲使能寄存器：'h48地址任意字节写入'h01;
//					3:清中断寄存器  ：'h38地址任意字节写入'h7A;
//					3:中断延时寄存器：'h40地址;
// 				
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module sys_ctrl_cfg_reg(
	input					bram_clk_b,
	input					bram_rst_b,
	
	//pc写
	input	 	[12:0]		addr_b,
	input	 	[63:0]		din_b,
	input	 				en_b,
	input	 	[7:0]		wen_b, 
	
	//中断延时
	input					sig_in,
	input		[1:0]		irq_state,
	output	reg				en_s,
	output		[7:0]		wen_s,
	output		[12:0]		addr_s,
	output	reg	[63:0]		din_s,
	input		[63:0]		dout_s,
	
	//使能
	output		reg			irq_en,
	output		reg			wave_en,
	output		reg			clear_int_en
);
/*******************************************************************************
// 	复位同步
*******************************************************************************/ 
reg			[2:0]			rr_rst;
always@(posedge bram_clk_b) 
	rr_rst <= {rr_rst[1:0],bram_rst_b};

wire						r_rst;
assign	r_rst = rr_rst[2];

/*******************************************************************************
// 		字节使能
*******************************************************************************/
reg		[3:0]			byte_en;
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

/*******************************************************************************
// 			清中断寄存器：清中断标志
*******************************************************************************/
always@(posedge bram_clk_b)
	if(r_rst)begin
        clear_int_en <= 1'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址38+偏移地址00 == 38
        if(addr_b == 13'h38 && din_b[byte_en*8 +: 8]  == 8'h7A) begin
            clear_int_en <= 1'b1;  // 断言清中断标志
        end else begin
            clear_int_en <= 1'b0;
        end
    end else begin
        clear_int_en <= 1'b0;
    end


/*******************************************************************************
// 			中断使能寄存器
*******************************************************************************/
always@(posedge bram_clk_b)
	if(r_rst)begin
        irq_en <= 1'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址50+偏移地址00 == 50
        if(addr_b == 13'h50) begin
			case(din_b[byte_en*8 +: 8] )
				8'h01 : irq_en <= 1'b1; 
				8'h0F : irq_en <= 1'b0;
				default:irq_en <= irq_en;
			endcase					
        end else begin
            irq_en <= irq_en;
        end
    end else begin
        irq_en <= irq_en;
    end


/*******************************************************************************
// 			脉冲使能寄存器
*******************************************************************************/
always@(posedge bram_clk_b)
	if(r_rst)begin
        wave_en <= 1'b0;
    end else if(en_b && (wen_b[byte_en] == 1'b1) ) begin  // 仅在写使能有效时判断
        //写入地址48+偏移地址00 == 48
        if(addr_b == 13'h48) begin
			case(din_b[byte_en*8 +: 8] )
				8'h01 : wave_en <= 1'b1; 
				8'h0F : wave_en <= 1'b0;
				default:wave_en <= wave_en;
			endcase					
        end else begin
            wave_en <= wave_en;
        end
    end else begin
        wave_en <= wave_en;
    end
/*******************************************************************************
// 			中断延时计算：中断信号拉高 —>清中断命令到来
*******************************************************************************/
reg			[31:0]			irq_cnt;
reg			[1:0]			cnt_state;
wire		[63:0]			din_reg;
always@(posedge bram_clk_b)
	if(r_rst)begin
		irq_cnt <= 'd0;
		cnt_state <= 'd0;
	end else case(cnt_state)
		0	:	begin
					irq_cnt <= 'd0;
					if(irq_state=='d0 && sig_in)
						cnt_state <= 'd1;
					else 
						cnt_state <= 'd0;
				end 

		1	:	begin
					irq_cnt <= irq_cnt + 1'b1;
					if(clear_int_en)
						cnt_state <= 'd2;
					else 
						cnt_state <= 'd1;
				end 
				
		2	:	begin
					irq_cnt <= irq_cnt;
					if(en_s)
						cnt_state <= 'd0;
					else 
						cnt_state <= 'd2;
				end 		
		default	: begin	cnt_state <= 'd0; irq_cnt <= 'd0; end 
	endcase




assign addr_s = 13'h40;
assign wen_s = 8'b1111_1111;
assign din_reg = (irq_cnt<<4)/1000;	//计数器值*周期（16ns）/1000 = 延时/us
always@(posedge bram_clk_b)
	if(rr_rst)begin
		din_s <= 'd0;
	end else begin 
		din_s <= {din_reg[7:0],din_reg[15:8],din_reg[23:16],din_reg[31:24],din_reg[39:32],din_reg[47:40],din_reg[55:48],din_reg[63:56]};//大小端序转换
	end

always@(posedge bram_clk_b)
	if(r_rst)begin	
		en_s <= 1'b0;
	end else if(cnt_state == 'd2)begin
		en_s <= 1'b1;
	end else begin
		en_s <= 1'b0;
	end

endmodule