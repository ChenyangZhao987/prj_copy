`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:  
// 
// Create Date: 2025/09/30 17:34:00
// Design Name: zcy
// Module Name: 
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description:
//              
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module BISS_C_interface#(
	parameter				CLK_T 			= 5,	
							MA_CLK_FREQ		= 10_000_000,  // MA目标时钟频率（默认10MHz，BISS典型值）
							SYS_CLK_MAX_FREQ= 100_000_000,  // 系统时钟最大频率（100MHz）
							TIMEOUT_MAX   	= 100 ,			// Timeout最大等待周期（防死锁，单位：系统时钟周期）
							RX_SIZE			= 32
)(	
	input 					Clk,
	input					Rst,
	output	reg				MA,
	input					SLO, 
	
    input 		[7:0]     	cfg_scd_width,	//接收数据位宽	数据[RX_SIZE-1 : 0]+错误标志[0]+警告标志[0]+crc校验[cfg_crc_width-1 :0]
    input 		[3:0]     	cfg_crc_width,	//crc校验多项式宽度
    input 		[31:0]     	cfg_ma_freq,	//分频系数
    input 		[16:0]     	cfg_crc_poly,	//CRC生成多项式
	input					Biss_en,		//外部驱动接收数据使能
    output reg             	error_flag,	//编码器错误标志
    output reg             	warn_flag,	//编码器警告标志
    output reg         	 	crc_err,	//CRC校验错误 
    output reg          	timeout_err,//通信超时错误
	output reg[RX_SIZE-1:0]	Data_out,	//解析后的编码器位置数据
	output reg				Data_valid	//位置数据有效	
);
/*******************************************************************************
// 			复位同步 信号同步
*******************************************************************************/	
reg			[2:0]		Phy_Rst1;
always@(posedge Clk)
	Phy_Rst1 <= {Phy_Rst1[1:0],Rst};

wire	r_rst;
assign  r_rst = Phy_Rst1[2];

reg			[2:0]		slo1;
always@(posedge Clk)
	slo1 <= {slo1[1:0],SLO};
	
reg			[2:0]		sclk;
always@(posedge Clk)sclk <= {sclk[1:0],MA};
wire				pos_scl;
assign pos_scl = sclk[1] & ~sclk[2];

/*******************************************************************************
// 			 内部参数与信号定义
*******************************************************************************/
//通信状态编码 
localparam				IDLE		=	3'd0,	//空闲
						ACK			=	3'd1,	//应答位
						START		=	3'd2,	//起始状态
						RX_RDAT		=	3'd3,	//接收数据
						ST_TIMEOUT	=	3'd4;	//死区时间 
						RX_PREP	=	3'd5;	//死区时间 
						
reg			[2:0]		state;						
//MA时钟分频参数（系统时钟→MA时钟，50%占空比） 
localparam 				MA_DIV_MAX   = SYS_CLK_MAX_FREQ / 1_000_000;  // 最大分频系数（1MHz MA对应100分频）
reg 		[15:0]		ma_div;                                        // 实际分频系数（=clk_sys/cfg_ma_freq）
reg 		[15:0]		scl_cnt;                                    // 分频计数器
reg      		  		ma_clk;                                        // 内部MA时钟（50%占空比）
//SL信号处理（同步+边沿检测） 
reg 		[1:0] 		sl_sync;                                        // 两级同步（防亚稳态）
reg       				sl_ack_det;                                     // SL拉低检测（从机ACK应答）

//数据接收与校验 
reg 		[7:0]  		scd_rx_cnt;                                    // SCD接收位数计数器
reg 		[63:0] 		scd_shift_reg;                                  // SCD移位寄存器（最大64位）
reg 		[15:0] 		crc_reg;                                       // CRC校验寄存器（兼容16位）
reg 		       		crc_calc_en;                                   // CRC计算使能

// 超时控制
reg 		[15:0] 		timeout_cnt;                                   // 超时计数器

/*******************************************************************************
// 				SLO信号处理 
*******************************************************************************/

// 4.2 SL下降沿检测(原始ACK信号)
always @(posedge Clk) begin
    if (r_rst) begin
        sl_ack_det <= 1'b0;
    end else begin
        sl_ack_det <= (slo1[2] == 1'b1) && (slo1[1] == 1'b0);
    end
end
// 4.3 ACK信号寄存
// 功能：在ST_START和ST_ACK状态寄存SL下降沿，进入ST_TRANSMIT/ST_TIMEOUT时清除
reg			sl_ack_latch;
always @(posedge Clk) begin
    if (r_rst) begin
        sl_ack_latch <= 1'b0;
    end else begin
        // 进入数据接收或Timeout阶段时清除寄存
        if (state == RX_RDAT || state == ST_TIMEOUT) begin
            sl_ack_latch <= 1'b0;
        end
        // 在START或ACK状态检测到下降沿时置位寄存
        else if ((state == START || state == ACK) && sl_ack_det) begin
            sl_ack_latch <= 1'b1;
        end
    end
end
/*******************************************************************************
// 				接收状态机 
*******************************************************************************/
always@(posedge Clk)
	if(r_rst)begin
		state 		<= IDLE;
        MA     	  	<= 1'b1;
		scd_rx_cnt  <= 8'd0;
		timeout_cnt	<= 16'd0;
		error_flag 	<= 1'b0;
        warn_flag  	<= 1'b0;
        crc_err    	<= 1'b0;
		timeout_err	<= 1'b0;
		Data_valid 	<= 1'b0;
	end else case(state)
		IDLE	:	if(Biss_en) state <= START; else state <= IDLE;
		START	:	begin
						MA <= ma_clk;  // 输出MA时钟
						timeout_cnt <= timeout_cnt + 16'd1;
						if (timeout_cnt >= TIMEOUT_MAX) begin
							timeout_err <= 1'b1; // 超时判断
							state <= IDLE;
						end else if(pos_scl) begin  // MA上升沿（分频计数器满）
							scd_rx_cnt <= scd_rx_cnt + 8'd1;
							if (scd_rx_cnt == 2'd2) begin  // 已输出2个脉冲（0→1计数满）
								state <= ACK;
								timeout_cnt <= 16'd0;
								scd_rx_cnt <= 8'd0;  // 重置SCD接收计数
							end
						end
					end
					
		ACK		:	begin
						MA <= ma_clk;  // 输出MA时钟
						timeout_cnt <= timeout_cnt + 16'd1;
						if (timeout_cnt >= TIMEOUT_MAX) begin
							timeout_err <= 1'b1; // 超时判断
							state <= IDLE;
						end else if(sl_ack_latch)begin
							state <= RX_PREP;
							timeout_cnt <= 16'd0;
							scd_rx_cnt <= 8'd0; 
						end
					end
					
		RX_PREP		:	begin
						MA <= ma_clk;  // 输出MA时钟
						timeout_cnt <= timeout_cnt + 16'd1;
						if (timeout_cnt >= TIMEOUT_MAX) begin
							timeout_err <= 1'b1; // 超时判断
							state <= IDLE;
						end else if(pos_scl)begin//ACK下降沿后的第一个MA上升沿跳转接收数据
							state <= RX_RDAT;
							timeout_cnt <= 16'd0;
							scd_rx_cnt <= 8'd0; 
						end
					end			
  			
		RX_RDAT	:	begin
						MA <= ma_clk;  // 输出MA时钟
						crc_calc_en <= 1'b1;  // 使能CRC计算
						timeout_cnt <= timeout_cnt + 16'd1;
						if (timeout_cnt >= TIMEOUT_MAX) begin
							timeout_err <= 1'b1; // 超时判断
							state <= IDLE;
						end else if(pos_scl)begin
							scd_shift_reg <= {scd_shift_reg[62:0], slo1[2]};  // 左移，MSB在前
							scd_rx_cnt <= scd_rx_cnt + 8'd1;
							if(scd_rx_cnt == cfg_scd_width - 1)begin
								state <= ST_TIMEOUT;
								crc_calc_en <= 1'b0;  // 停止CRC计算
								timeout_cnt <= 16'd0;
							end
						end
					end			
					
		ST_TIMEOUT: begin
				MA <= 1'b1;  // 输出MA时钟
                // 超时判断：Timeout阶段超时
                if (timeout_cnt >= TIMEOUT_MAX) begin
                    timeout_err <= 1'b1;
                    state <= IDLE;
                end
                // 从机应答完成（SL拉高），解析SCD数据
                else if (slo1[2] == 1'b1) begin
                    // 解析SCD字段（通用格式：位置+Error+Warn+CRC，需与编码器匹配）
                    // 示例：SCD = [位置位(cfg_scd_width - cfg_crc_width - 2):0] + Warn(1) + Error(1) + CRC(cfg_crc_width)
                    if (cfg_crc_width == 4'd6) begin
                        Data_out   <= scd_shift_reg[cfg_scd_width - 1 : 6 + 2];  // 位置数据
                        error_flag <= scd_shift_reg[6 + 1];  // Error位（CRC前2位）
                        warn_flag  <= scd_shift_reg[6];       // Warn位（CRC前1位）
                    end else if (cfg_crc_width == 4'd16) begin
                        Data_out   <= scd_shift_reg[cfg_scd_width - 1 : 16 + 2];
                        error_flag <= scd_shift_reg[16 + 1];
                        warn_flag  <= scd_shift_reg[16];
                    end else begin
                        Data_out   <= 'd0;
                        error_flag <= 1'b0;
                        warn_flag  <= 1'b0;
                    end

                    // CRC校验：结果为0则通过
                    crc_err <= (cfg_crc_width == 4'd6) ? (crc_reg[5:0] != 6'd0) : (crc_reg != 16'd0);

                    // 数据有效：无超时+无CRC错误
                    Data_valid <= (timeout_err == 1'b0) && (crc_err == 1'b0) ? 1'b1 : 1'b0;

                    // 回到IDLE，等待下一次通信
                    state <= IDLE ;
                end
            end		
							
	endcase

/*******************************************************************************
// 				输出时钟 
*******************************************************************************/
// 复位时根据配置的MA频率计算分频系数（clk_sys / cfg_ma_freq）
always @(posedge Clk) begin
    if (r_rst) begin
        ma_div <= 16'd10;  // 默认10分频（100MHz→10MHz MA）
    end else begin
        if (cfg_ma_freq > 0) begin
            ma_div <= SYS_CLK_MAX_FREQ / cfg_ma_freq;  // 整数分频（需确保clk_sys是cfg_ma_freq的整数倍）
        end else begin
            ma_div <= 16'd10;  // 频率配置错误时默认10MHz
        end
    end
end

// (* MARK_DEBUG="true" *)reg			[12:0]		scl_cnt;
always @(posedge Clk)
    if(r_rst)begin
		ma_clk	<= 1'b1;  // IDLE时MA默认高电平
		scl_cnt	<= 'd0;
	end else begin
        if (scl_cnt == ma_div - 1) begin
            scl_cnt <= 16'd0;
            ma_clk  <= ~ma_clk;  // 分频翻转，生成50%占空比
        end else begin
            scl_cnt <= scl_cnt + 16'd1;
        end
    end
end

/*******************************************************************************
// 					CRC校验模块
*******************************************************************************/
always @(posedge Clk)  pos_scl1 <= pos_scl;//CRC计算延时1时钟周期，确保采样和校验计算错开

always @(posedge Clk) begin
    if (r_rst) begin
        crc_reg <= 16'hffff;  // 初始值全1（BISS协议规定）
    end else if (crc_calc_en && pos_scl1) begin  // MA上升沿更新CRC
        if (cfg_crc_width == 4'd6) begin  // 6位CRC计算
            reg crc_xor;
            crc_xor = crc_reg[5] ^ slo1[2];  // 最高位与当前数据异或
            crc_reg[5:0] = {crc_reg[4:0], 1'b0} ^ (crc_xor ? cfg_crc_poly[5:0] : 6'b0);
            crc_reg[15:6] = 10'd0;  // 高10位无效
        end else if (cfg_crc_width == 4'd16) begin  // 16位CRC计算
            reg crc_xor;
            crc_xor = crc_reg[15] ^ slo1[2];
            crc_reg = {crc_reg[14:0], 1'b0} ^ (crc_xor ? cfg_crc_poly : 16'b0);
        end
    end
end

endmodule
