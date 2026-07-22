`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/07 16:45:07
// Design Name: 
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
module Spi_Flash_Ctrl#(
	parameter 							Sim_Flg			=	0,
										Spi_Width		=	4,
										Spi_Dsize		=	Spi_Width==1 ? 2 : 4,	//	SPI Flash数据总线位宽，外部无需例化，内部自动计算
										Wfifo_Depth		=	13,// FIFO深度 = 2^Wfifo_Depth
										Time_1ms		=	200_000,
										SPI_BAUD		=	10_000_000	//	SPI时钟频率(Hz)
)(			
	input								Clk,
	input								Rst,
	input								Start_Inital,
	//读写通道			
	output	reg[7:0]					Flash_Rd_dat,
	output	reg							Flash_Rd_dat_vld,
				
	input								fifo_wr_clk,
	input								fifo_wr_en,
	input		[7:0]					fifo_wrdata,
	output		[Wfifo_Depth-1:0]		fifo_rd_count,
	//命令操作接口
	output	reg							Flash_C_rdy,	//Flash准备就绪
	input								Flash_C_Val,	//读写操作有效
	input		[2:0]					Flash_C_Type,	//读写操作类型			0：Page写
												//								1：Page读
												//                  			2: Sector擦除 
												//				  				3: Block擦除
	input		[13:0]					Flash_C_Num,	//	读写操作次数从1开始
	input		[31:0]					Flash_C_Saddr,	//	读写起始地址
	output	reg							Flash_C_Cmplt,	//	操作完成标志
	output	reg	[23:0]					Flash_Flash_Id,	//	Flash JEDEC ID
	output		[23:0]					Spi_C_Op_Num,	//	已操作次数
	//Flash物理端口
	output								F_SPI_SCK,
	output								F_SPI_CS,
	inout	[Spi_Dsize-1:0]				Flash_Spi_Sdio
);
/**************************************************************************
//			同步
***************************************************************************/
wire					rst;
reg			[2:0]		rst_rr;
always@(posedge Clk)rst_rr <= {rst_rr[1:0],Rst};
assign 	rst = rst_rr[2];

//指令寄存
reg			[2:0]		cmd_type;	
reg			[13:0]		cmd_num;	
reg			[31:0]		cmd_saddr;//操作地址
always@(posedge Clk)
	if(rst)begin
		cmd_type <= 'd0;
		cmd_num <= 'd0;
		cmd_saddr <= 'd0;
	end else if(Flash_C_Val)begin
		cmd_type <= Flash_C_Type;
		cmd_num <= Flash_C_Num;
		cmd_saddr <=Flash_C_Saddr;
	end else begin
		cmd_type <= cmd_type;
		cmd_num <= cmd_num;
		cmd_saddr <= cmd_saddr;
	end

//操作次数计算
reg			[12:0]		num_cnt;

assign Spi_C_Op_Num = num_cnt;
//延时计算time_cnt
reg				[31:0]		time_cnt;
localparam			Time_100ms = 100*Time_1ms,
					Time_100us = Time_1ms/10;

wire [2:0]	Dummy = 'd4;
//地址

wire [19:0]	r_seradd = cmd_saddr[31:12] + num_cnt;//4k对齐，低12位直接给零
wire [31:0]	cmd_seradd = {r_seradd,12'd0};//4k对齐，低12位直接给零

wire [15:0]	r_beradd = cmd_saddr[31:16] + num_cnt;//64k对齐，低16位直接给零
wire [31:0]	cmd_beradd = {r_beradd,16'd0};//64k对齐，低16位直接给零

wire [23:0]	r_ppadd = cmd_saddr[31:8] + num_cnt;//256B对齐，低8位直接给零
wire [31:0]	cmd_ppadd = {r_ppadd,8'd0};//256B对齐，低8位直接给零
/**************************************************************************
//			发送状态机
***************************************************************************/
reg				[6:0]		state;
wire						Tx_done;
wire						Cmplt;
reg				[7:0]		Cmd_in;
reg							Cmd_Type;
reg				[10:0]		wr_cnt;
reg				[28:0]		data_len;
reg				[2:0]		cmd_len;
reg				[7:0]		vld_cnt;
reg							Cmd_vld;
reg							id_ok;
reg							addr_ok;
reg							spd_ok;
reg							device_rdy;
reg							erase_err_flag;
wire	[7:0]				Rd_dat;
wire						Rd_dat_vld;


localparam 					IDLE		=7'd0,
							RD_ID		=7'd1,
							BRWR		=7'd2,
							BRRD		=7'd3,
							QUAD_WREN	=7'd4,
							QUAD_EN		=7'd5,
							QUADRD		=7'd6,
							INIT_DONE	=7'd7,
							RD_ST_INIT	=7'd27,
							CTRL_CMD_RD	=7'd8,
							//Sector擦除
							SER_WREN	=7'd9,
							SER_EN		=7'd10,
							WIAT_SER	=7'd11,
							SER_RDST	=7'd12,
							//Block擦除
							BER_WREN	=7'd13,
							BER_EN		=7'd14,
							WIAT_BER	=7'd15,
							BER_RDST	=7'd16,
							//PAGE写
							PW_WREN		=7'd17,
							WREN_BK		=7'd18,//响应命令
							PAGE_WR		=7'd19,
							WIAT_PW		=7'd20,
							RD_PW_ST	=7'd21,
							//PAGE读
							PAGE_RD		=7'd22,
							JUDGE_PR	=7'd23,//判断PAGE读是否满足指定次数
							//错误处理
							ID_ERR		=7'd24,
							ERASE_ERR	=7'd25;
							

always@(posedge Clk)
	if(rst)begin
		Cmd_in <= 'd0;
		Cmd_vld <= 'd0;
		Flash_C_rdy <= 'd0;
		data_len <= 'd0;
		cmd_len <= 'd0;
		Flash_C_Cmplt <= 1'b0;
		Cmd_Type <= 'd0;
		wr_cnt <= 'd0;
		vld_cnt <= 'd0;
	end else case(state)
		//等待远程更新使能
		IDLE	:	begin
						state <= Start_Inital ? RD_ID : IDLE;	
						Cmd_in <= 'd0;
						Cmd_vld <= 'd0;
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd0;
						Flash_C_Cmplt <= 1'b0;
						Cmd_Type <= 'd0;
						wr_cnt <= 'd0;
						vld_cnt <= 'd0;
					end
					
		//读取设备ID		
		RD_ID	:	begin
						state <= (id_ok&&Cmplt)?BRWR:RD_ID;//ID错误循环读取(S25FL256S芯片第一次读ID不一定读的出来)
						Cmd_in <= 'h9F;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin //&& Tx_done
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end	
		
		//地址状态寄存器(该命令无需提前写使能)		
		BRWR	:	begin
						state <= Cmplt ? BRRD:BRWR;
						Cmd_in <= wr_cnt =='d0 ? 'h17 : 'h80;
						Cmd_Type <= 1'b0;//写操作
						Flash_C_rdy <= 1'b0;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						data_len <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin //&& Tx_done
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end
		
		//读取地址状态
		BRRD	:	begin
						state <= Cmplt ? (addr_ok ? ( Spi_Width == 4 ? QUAD_WREN : INIT_DONE) : BRWR) : BRRD;
						Cmd_in <= 'h16;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin //&& Tx_done
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end	
		//quad速率命令之前，先使能WREN
		QUAD_WREN	:	begin
							state <= Cmplt ? QUAD_EN:QUAD_WREN;
							Cmd_in <= 'h06;
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							// vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							data_len <= 'd0;
							cmd_len <= 'd1;
							if(Cmplt)begin //&& Tx_done
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		//传输速率				
		QUAD_EN	:	begin
							state <= Cmplt ? QUADRD:QUAD_EN;
							Cmd_Type <= 1'b0;//写操作
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd3;
							if(Cmplt)begin //&& Tx_done
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
							case(wr_cnt)
								0 :Cmd_in <= 'h01;
								1 :Cmd_in <= 'h00;
								2 :Cmd_in <= 'h02;
								default :Cmd_in <= 'h01;	
							endcase
						end
		//读取传输速率				
		QUADRD	:	begin
						state <= Cmplt ? (spd_ok ? RD_ST_INIT : QUAD_WREN) : QUADRD;
						Cmd_in <= 'h35;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin //&& Tx_done
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end	
					
		RD_ST_INIT:	begin	
						state <= Cmplt&device_rdy ?INIT_DONE : RD_ST_INIT;
						Cmd_in <= 'h05;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin //&& Tx_done
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end
					
		//初始化完毕等待外部命令		
		INIT_DONE:	begin
						state <= Flash_C_Val ? CTRL_CMD_RD : INIT_DONE;
						Cmd_in <= 'd0;
						Cmd_vld <= 'd0;
						data_len <= 'd0;
						Flash_C_Cmplt <= 1'b0;
						Flash_C_rdy <= 'd1;
						cmd_len <= 'd0;
						Cmd_Type <= 'd0;
						wr_cnt <= 'd0;
						vld_cnt <= 'd0;
					end
		//读取控制命令
		CTRL_CMD_RD	:begin
						Cmd_in <= 'd0;
						Cmd_vld <= 'd0;
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd0;
						Cmd_Type <= 'd0;
						wr_cnt <= 'd0;
						vld_cnt <= 'd0;
						case(cmd_type)
							0	:	state <= PW_WREN; //page写
							1	:	state <= PAGE_RD; //page读
							2	:	state <= SER_WREN; //Sector擦除
							3	:	state <= BER_WREN; //Block擦除
							default : state <= CTRL_CMD_RD;
						endcase
					end
				
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//Page写
		//	写使能
		PW_WREN		:begin
						state <= Cmplt ? PAGE_WR:PW_WREN;
						Cmd_in <= 'h06;
						Cmd_Type <= 1'b0;//写操作
						Flash_C_rdy <= 1'b0;	
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						data_len <= 'd0;
						cmd_len <= 'd1;
						if(Cmplt)begin 
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end

		//启动Page写
		PAGE_WR	:	begin
							state <= Cmplt ? WIAT_PW:PAGE_WR;
							case(wr_cnt)
								0 :Cmd_in <= spd_ok ? 'h34 : 'h02;
								1 :Cmd_in <= cmd_ppadd[31:24];
								2 :Cmd_in <= cmd_ppadd[23:16];
								3 :Cmd_in <= cmd_ppadd[15:8];
								4 :Cmd_in <= cmd_ppadd[7:0];
								default :Cmd_in <= Cmd_in;	
							endcase
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd256;
							cmd_len <= 'd5;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		
		//等待编程
		WIAT_PW	:		begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= time_cnt >= Time_100us/2 ? RD_PW_ST : WIAT_PW;//等待50us
						end	
						
		RD_PW_ST:		begin	
							state <=	// (erase_err_flag && Cmplt) ? ERASE_ERR : //有错误，进错误态
										(device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? INIT_DONE : //完成且是最后一次
										(device_rdy && Cmplt) ? PW_WREN : //完成不是最后一次回写使能
										RD_PW_ST; 
							Flash_C_Cmplt <= (device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? 1'b1 : 1'b0; //完成且是最后一次
							Cmd_in <= 'h05;
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							Cmd_Type <= 1'b1;//读操作
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd2;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end	
						
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//Page读
		PAGE_RD		:	begin
							state <= Cmplt ? JUDGE_PR : PAGE_RD;
							case(wr_cnt)
								0 :Cmd_in <= spd_ok ? 'h6C : 'h03;
								1 :Cmd_in <= cmd_ppadd[31:24];
								2 :Cmd_in <= cmd_ppadd[23:16];
								3 :Cmd_in <= cmd_ppadd[15:8];
								4 :Cmd_in <= cmd_ppadd[7:0];
								default :Cmd_in <= Cmd_in;	
							endcase
							Cmd_Type <= 1'b1;//读操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd256 + Dummy;//快速读芯片会先输出4字节FF用于内部处理，需要剔除
							cmd_len <= 'd5;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						
						end
        JUDGE_PR	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Flash_C_Cmplt <= (num_cnt == cmd_num - 1'b1) ? 1'b1 : 1'b0; //完成且是最后一次
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <=  (num_cnt == cmd_num - 1'b1) ? INIT_DONE : PAGE_RD;
						end

		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//Sector擦除
		//	擦除写使能
		SER_WREN	:	begin
							state <= Cmplt ? SER_EN:SER_WREN;
							Cmd_in <= 'h06;
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd0;
							cmd_len <= 'd1;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		//Sector擦除
		SER_EN	:	begin
							state <= Cmplt ? WIAT_SER:SER_EN;
							case(wr_cnt)
								0 :Cmd_in <= 'h20;
								1 :Cmd_in <= cmd_seradd[31:24];
								2 :Cmd_in <= cmd_seradd[23:16];
								3 :Cmd_in <= cmd_seradd[15:8];
								4 :Cmd_in <= cmd_seradd[7:0];
								default :Cmd_in <= Cmd_in;	
							endcase
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd0;
							cmd_len <= 'd5;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		
		//等待擦除延时
		WIAT_SER	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= time_cnt >= Time_1ms*40 ? SER_RDST : WIAT_SER;//等待100ms
						end
			
		SER_RDST	:begin
						 state <=	(erase_err_flag && Cmplt) ? ERASE_ERR : //有错误，进错误态
									(device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? INIT_DONE : //完成且是最后一次
									(device_rdy && Cmplt&& (num_cnt != cmd_num - 1'b1)) ? SER_WREN : //完成不是最后一次回写使能
									SER_RDST; 
						Flash_C_Cmplt <= (device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? 1'b1 : 1'b0; //完成且是最后一次
						Cmd_in <= 'h05;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin 
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end	
		ERASE_ERR	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= ERASE_ERR;//擦除错误
						end					
		///////////////////////////////////////////////////////////////////////////////////////////////////////////////
		//Block擦除
		//	擦除写使能
		BER_WREN	:	begin
							state <= Cmplt ? BER_EN:BER_WREN;
							Cmd_in <= 'h06;
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd0;
							cmd_len <= 'd1;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		//Block擦除
		BER_EN	:	begin
							state <= Cmplt ? WIAT_BER:BER_EN;
							case(wr_cnt)
								0 :Cmd_in <= 'hD8;
								1 :Cmd_in <= cmd_beradd[31:24];
								2 :Cmd_in <= cmd_beradd[23:16];
								3 :Cmd_in <= cmd_beradd[15:8];
								4 :Cmd_in <= cmd_beradd[7:0];
								default :Cmd_in <= Cmd_in;	
							endcase
							Cmd_Type <= 1'b0;//写操作
							Flash_C_rdy <= 1'b0;	
							Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
							data_len <= 'd0;
							cmd_len <= 'd5;
							if(Cmplt)begin 
								wr_cnt <= 'd0;
								vld_cnt <= 'd0;
							end else begin
								wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
								vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
							end
						end
		
		//等待擦除延时
		WIAT_BER	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= time_cnt >= Time_100ms*2 ? BER_RDST : WIAT_BER;//等待1ms
						end
						
		//读取状态寄存器判断擦除是否满足指定次数	
		BER_RDST	:begin
						 state <=	(erase_err_flag && Cmplt) ? ERASE_ERR : //有错误，进错误态
									(device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? INIT_DONE : //完成且是最后一次
									(device_rdy && Cmplt) ? BER_WREN : //完成不是最后一次回写使能
									BER_RDST; 
						Flash_C_Cmplt <= (device_rdy && Cmplt && (num_cnt == cmd_num - 1'b1)) ? 1'b1 : 1'b0; //完成且是最后一次
						Cmd_in <= 'h05;
						Cmd_vld <= vld_cnt == 2 ? 1'b1 : 1'b0;
						Cmd_Type <= 1'b1;//读操作
						data_len <= 'd0;
						Flash_C_rdy <= 'd0;
						cmd_len <= 'd2;
						if(Cmplt)begin 
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
						end else begin
							wr_cnt <= Tx_done ? wr_cnt + 1 : wr_cnt;
							vld_cnt <= vld_cnt == 3 ? vld_cnt : vld_cnt + 1;
						end
					end
		//////////////////////////////////////////////////////////////////////////////////////////////////////			
		//擦除错误			
		ERASE_ERR	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= ERASE_ERR;//擦除错误
						end	
						
		//ID错误			
		ID_ERR	:	begin
							Cmd_in <= 'd0;
							Cmd_vld <= 'd0;
							data_len <= 'd0;
							Flash_C_rdy <= 'd0;
							cmd_len <= 'd0;
							Cmd_Type <= 'd0;
							wr_cnt <= 'd0;
							vld_cnt <= 'd0;
							state <= ID_ERR;//擦除错误
						end
		default	:	begin state <= IDLE; end
	endcase
	
	
	
/*******************************************************************************
// 	JEDEC ID
*******************************************************************************/
//Flash ID：0x01	
always@(posedge Clk)
	if(rst)begin
		id_ok <= Sim_Flg ? 1'b1:'d0;
		Flash_Flash_Id <= 'd0;
	end else if(state == RD_ID && Rd_dat_vld && Rd_dat == 'h01)begin
		id_ok <=  1'b1;
		Flash_Flash_Id <= {Flash_Flash_Id[15:0],Rd_dat};
	end else begin
		id_ok <= id_ok;
		Flash_Flash_Id <= Flash_Flash_Id;
	end
	
//读取地址状态为4字节地址模式
always@(posedge Clk)
	if(rst)
		addr_ok <= Sim_Flg ? 1'b1:'d0;
	else if(state == BRRD && Rd_dat_vld && Rd_dat == 'h80)
		addr_ok <=  1'b1;
	else 
		addr_ok <= addr_ok;
/*******************************************************************************
// 	状态寄存器
*******************************************************************************/
		
//读取传输速率为quad模式
always@(posedge Clk)
	if(rst)
		spd_ok <= Sim_Flg ? 1'b1:'d0;
	else if(state == QUADRD && Rd_dat_vld && Rd_dat == 'h02)
		spd_ok <=  1'b1;
	else 
		spd_ok <= spd_ok;	
		
//读取擦除/编程状态
always@(posedge Clk)
	if(rst)begin
		device_rdy <='d0;
	end else if(Sim_Flg == 1'b1 )begin
		device_rdy <=   1'b1;
	end else if(state == SER_RDST |state == BER_RDST | state == RD_PW_ST| state == RD_ST_INIT)begin
		if(Rd_dat_vld)
			device_rdy <=  Rd_dat[0] == 1'b0 ? 1'b1 : 1'b0;
		else 
			device_rdy <= device_rdy;
	end else 
		device_rdy <= 'd0;
		
//读取擦除ERROR
always@(posedge Clk)
	if(rst)begin
		erase_err_flag <= 'd0;
	end else if(Sim_Flg == 1'b1 )begin
		erase_err_flag <=   1'b0;
	end else if(state == SER_RDST )begin
		// erase_err_flag <=  Rd_dat_vld && Rd_dat[5] == 1'b1 ? 1'b1 : erase_err_flag;	
		if(Rd_dat_vld)
			erase_err_flag <=  Rd_dat[5] == 1'b1 ? 1'b1 : 1'b0;
		else 
			erase_err_flag <=erase_err_flag;
	end else 
		erase_err_flag <= 'd0;
		
/*******************************************************************************
// 	擦除和编程操作等待时间
*******************************************************************************/
always@(posedge Clk)
	if(rst)begin
		time_cnt <= 'd0;
	end else case(state)
		WIAT_SER	:	time_cnt <= time_cnt + 1'b1 ;//延时计数
		WIAT_BER	:	time_cnt <= time_cnt + 1'b1 ;//延时计数
		WIAT_PW		:	time_cnt <= time_cnt + 1'b1 ;//延时计数
		default		:	time_cnt <= 'd0;
	endcase
	
/*******************************************************************************
// 	读/写次数统计
*******************************************************************************/
	
always@(posedge Clk)//操作次数计算
	if(rst)begin
		num_cnt <= 'd0;
	end else case(state)
		INIT_DONE	:	num_cnt <= 'd0;
		SER_RDST	:	num_cnt <= (device_rdy&&Cmplt) ? num_cnt + 1'b1 : num_cnt;//擦除次数计数
		BER_RDST	:	num_cnt <= (device_rdy&&Cmplt) ? num_cnt + 1'b1 : num_cnt;//擦除次数计数
		RD_PW_ST	:	num_cnt <= (device_rdy&&Cmplt) ? num_cnt + 1'b1 : num_cnt;//擦除次数计数
		JUDGE_PR	:	num_cnt <= num_cnt + 1'b1 ;//擦除次数计数
		default		:	num_cnt <= num_cnt;
	endcase
	
/*******************************************************************************
// 		生成递增数(仿真用)
*******************************************************************************/
reg						Data_vld;
reg		[7:0]			Data_in;
always@(posedge Clk)
	if(rst)begin
		Data_vld <= 'd0;
		Data_in	 <= 'd0;
	end else if(state == PAGE_WR && wr_cnt >= 'd4 && wr_cnt <= 'd256 +'d4 - 1)begin
		Data_vld <= Tx_done;
		Data_in	 <= Tx_done ? Data_in + 1'b1 : Data_in;
	end else begin
		Data_vld <= 'd0;
		Data_in	 <= 'd0;
	end
/*******************************************************************************
// 		FIFO读
*******************************************************************************/
reg						fifo_rd_en;
wire		[7:0]		fifo_dout;
reg						fifo_dout_vld;
always@(posedge Clk)
	if(rst)begin
		fifo_rd_en <= 'd0;
	end else if(state == PAGE_WR && wr_cnt >= 'd4 && wr_cnt <= 'd256 +'d4 - 1)begin
		fifo_rd_en <= Tx_done;
	end else begin
		fifo_rd_en <= 'd0;
	end
	
always@(posedge Clk)	
	if(rst)begin
		fifo_dout_vld <= 1'b0;
	end else begin
		fifo_dout_vld <= fifo_rd_en;
	end 

//输出回读数据
always@(posedge Clk) 
	if(rst)
		Flash_Rd_dat <= 'd0;
	else 
		Flash_Rd_dat <= (state == PAGE_RD) & (wr_cnt >'d8) & Rd_dat_vld ? Rd_dat : Flash_Rd_dat;//剔除Dummy

always@(posedge Clk)
	if(rst)
		Flash_Rd_dat_vld <= 'd0;
	else 
		Flash_Rd_dat_vld  <= (state == PAGE_RD) & (wr_cnt > 'd8) ? Rd_dat_vld : Flash_Rd_dat_vld;//剔除Dummy

/**************************************************************************
//				FIFO缓存
***************************************************************************/ 
// wire			fifo_rd_en;
// wire	[7:0]	fifo_rdat;
fifo_8x8192 fifo_updata_ins (
  .rst						(rst  |	Flash_C_Cmplt			),                      // input wire rst
  .wr_clk					(fifo_wr_clk					),                // input wire wr_clk
  .rd_clk					(Clk							),                // input wire rd_clk
  .din						(fifo_wrdata					),                      // input wire [7 : 0] din
  .wr_en					(fifo_wr_en						),                  // input wire wr_en
  .rd_en					(fifo_rd_en						),                  // input wire rd_en
  .dout						(fifo_dout						),                    // output wire [7 : 0] dout
  .full						(								),                    // output wire full
  .empty					(								),                  // output wire empty
  .rd_data_count			(fifo_rd_count					),  // output wire [12 : 0] rd_data_count
  .wr_rst_busy				(								),      // output wire wr_rst_busy
  .rd_rst_busy				(								)      // output wire rd_rst_busy
);

/**************************************************************************
//			SPI物理层
***************************************************************************/
SPI_interface#(
	.CPOL					(0								),
	.CPHA					(0								),
	.Spi_Width				(Spi_Width						),
	.CLK_FREQ				(200_000_000					),
	.Sim_Flg 				(Sim_Flg   						)
)SPI_Phy_ins(	
	.Clk					(Clk							),
	.Rst					(rst							),
	.Cmd_Type				(Cmd_Type						),
	.Cmd_in					(Cmd_in							),
	.Cmplt					(Cmplt							),
	.Cmd_Len				({cmd_len,data_len}				),//高三位为命令+地址长度
	.Cmd_vld				(Cmd_vld						),
	.Data_in				(Sim_Flg ? Data_in	: fifo_dout	),
	.Data_vld				(Sim_Flg ? Data_vld	: fifo_dout_vld) ,
	.Tx_done				(Tx_done						),
	.Rd_dat					(Rd_dat							),
	.Rd_dat_vld				(Rd_dat_vld						),
	.SPI_BAUD				(SPI_BAUD						),	//	SPI时钟频率，由上层参数透传
	//SPI物理接口	
	.F_SPI_SCK				(F_SPI_SCK						),	
	.F_SPI_CS				(F_SPI_CS						),
	.Flash_Spi_Sdio			(Flash_Spi_Sdio					)
);
/**************************************************************************
//			debug
*************************************************************************** /
ila_0 flash_ctrl_ila(
	.clk(Clk), // input wire clk
	.probe0 ({'d0,cmd_seradd}), // input wire [31:0]  probe0  
	.probe1 ({'d0,Tx_done,Cmplt,erase_err_flag,device_rdy,Start_Inital,num_cnt}), // input wire [31:0]  probe1 
	.probe2 ({'d0,Rd_dat,Rd_dat_vld}), // input wire [31:0]  probe2 
	.probe3 ({'d0,data_len}), // input wire [31:0]  probe3 
	.probe4 ({'d0,cmd_len}), // input wire [31:0]  probe4 
	.probe5 ({'d0,state,Cmd_Type}), // input wire [31:0]  probe5 
	.probe6 ({'d0,id_ok,addr_ok,spd_ok,Cmd_in,Flash_C_rdy,Flash_C_Val,Flash_C_Type,Flash_C_Num}), // input wire [31:0]  probe6 
	.probe7 ({'d0,wr_cnt,fifo_wrdata,fifo_wr_en}), // input wire [31:0]  probe7 
	.probe8 ({'d0,vld_cnt,fifo_wr_en,Cmd_vld}) // input wire [31:0]  probe8 
);
/**************************************************************************
//			end
***************************************************************************/
endmodule 