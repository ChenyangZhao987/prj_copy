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
module SPI_interface#(
	parameter			CPOL		= 0	,
						CPHA		= 0	,
						Spi_Width	= 1	,
						Spi_Dsize	= Spi_Width == 1 ? 2 : 4,
						CLK_FREQ	= 100_000_000,
						Sim_Flg 	= 0
)(
	input				Clk,
	input				Rst,
	input	[7:0]		Cmd_in,
	input				Cmd_Type,//0:写操作 1：读操作
	input	[31:0]		Cmd_Len,//高三位为命令+地址长度
	input				Cmd_vld,
	input	[7:0]		Data_in,
	input				Data_vld,
	output	reg			Tx_done,
	output	reg			Cmplt,
	output	reg[7:0]	Rd_dat,
	output	reg			Rd_dat_vld,
	input	[31:0]		SPI_BAUD,//8Mhz	
	//SPI物理接口
	output				F_SPI_SCK,	
	output				F_SPI_CS,
	inout	[Spi_Width-1:0]	Flash_Spi_Sdio
);
/**************************************************************************
//			复位同步
***************************************************************************/
reg		[2:0]	r_rst;
wire			rst;
always@(posedge Clk) r_rst <= {r_rst[1:0],Rst};
	
assign	rst = r_rst[2];
reg		[2:0]		cur_state,next_state;
localparam			IDLE	=3'd0,
					START	=3'd1,
					TX_CMD	=3'd2,
					TX_DATA	=3'd3,
					DONE	=3'd4;
reg		[2:0]	cmd_len;
reg		[28:0]	data_len;
always@(posedge Clk) cmd_len <=(cur_state == IDLE)? Cmd_Len[31:29]	:cmd_len ;
always@(posedge Clk) data_len<=(cur_state == IDLE)? Cmd_Len[28:0]	:data_len ;					
reg		[2:0]	rd_flag;	
always@(posedge Clk)	
	if(rst)begin
		rd_flag <= 'd0;
	end else case(rd_flag)
		0	:	if(Cmd_Type == 'd1 && Cmd_vld && data_len == 'd0)//当前操作为读操作同时数据长度为0（读寄存器）
					rd_flag <= 'd1; 
				else 
					rd_flag <=(Cmd_Type == 'd1 && Cmd_vld) ? 'd2 : 'd0;//当前操作为读操作时
					
		1	:	if(cur_state == DONE)rd_flag <= 'd0;//置位控制信号
		2	:	if(cur_state == TX_DATA)rd_flag <= 'd1;//读数据和读寄存器区分
		default:	rd_flag <= 'd0;
	endcase
/**************************************************************************
//			主状态机
***************************************************************************/
reg		[15:0]		scl_cnt;
wire [2:0]	BIT_CNT_MAX = Spi_Width == 1 ? 'd7 : 'd1;
wire[15:0]tx_clk = Sim_Flg ? 500: 1_000_000_000/SPI_BAUD;//200
wire[15:0]in_clk = Sim_Flg ? 50: 1_000_000_000/CLK_FREQ;//5

wire [15:0]SCL_CNT_MAX = (tx_clk/in_clk)/2;

reg		[15:0]		len_cnt;
reg 	[3:0]		bit_cnt;
reg 	[7:0]		wiat_cs;
always@(posedge Clk)
	if(rst)begin
		cur_state <= IDLE;
	end else begin
		cur_state <= next_state;
	end
	
always@(*)begin
	case(cur_state)
		IDLE	:	if(Cmd_vld) next_state = START;else next_state = IDLE;
		START	:	next_state = wiat_cs == 'd50 ? TX_CMD : START;
		TX_CMD	:	if(len_cnt == cmd_len && (scl_cnt == SCL_CNT_MAX)) begin//&& bit_cnt == 'd7&&scl_cnt == SCL_CNT_MAX
						next_state = (data_len == 0) ? DONE : TX_DATA;
					end else begin
						next_state = TX_CMD;
					end
		TX_DATA : 	if(len_cnt == data_len&& (scl_cnt == SCL_CNT_MAX))
						next_state = DONE; 
					else 
						next_state = TX_DATA;//&& bit_cnt == BIT_CNT_MAX
						
		DONE	:	next_state =  wiat_cs == 'd50 ? IDLE:DONE;
		default	:	next_state = IDLE;
	endcase
end	
	
always@(posedge Clk)
	if(rst)begin
		Cmplt <= 'd0;
	end else begin
		Cmplt <= cur_state == DONE && wiat_cs == 'd50 ? 1'b1 : 'd0;
	end
	
always@(posedge Clk)
	if(rst)begin	
		wiat_cs <= 'd0;
	end else if(cur_state == START|cur_state == DONE)begin
		wiat_cs <=  (wiat_cs >= 8'd50) ? wiat_cs : wiat_cs + 1'b1;	//	饱和封顶，防止溢出绕回
	end else begin
		wiat_cs <= 'd0;
	end
	
/**************************************************************************
//					发送时钟生成
***************************************************************************/
reg					spi_scl;

always@(posedge Clk)
	if(rst)begin
		spi_scl <= CPOL;
		scl_cnt <= 'd0;
	end else if( cur_state == TX_CMD | cur_state == TX_DATA )begin
		if(scl_cnt == SCL_CNT_MAX)begin
			spi_scl <= ~spi_scl;
			scl_cnt <= 'd0;
		end else begin
			spi_scl <= spi_scl;
			scl_cnt <= scl_cnt + 1'b1;
		end
	end else begin
		spi_scl <= CPOL;
		scl_cnt <= 'd0;
	end

wire scl_flag = scl_cnt == 1 ? 1 : 0;

wire edge_flag = (spi_scl==CPHA) && scl_flag ;

wire rx_scl_flag = scl_cnt == SCL_CNT_MAX ? 1 : 0;

wire rx_edge_flag = (spi_scl==CPHA) && rx_scl_flag ;

/**************************************************************************
//					加载数据
***************************************************************************/

always@(posedge Clk)
	if(rst)begin
		bit_cnt <= 'd0;
		Tx_done <= 'd0;
		len_cnt <= 'd0;
	end else case(cur_state)
		TX_CMD : begin
					if(len_cnt == cmd_len&& (scl_cnt == SCL_CNT_MAX))begin//
						bit_cnt <= 'd0;
						len_cnt <= 'd0;
						Tx_done <= 1'b0;
					end else begin
						if(bit_cnt == 'd7&&rx_edge_flag)begin
							bit_cnt <= 'd0;
							Tx_done <= 1'b1;
							len_cnt <= len_cnt + 1'b1;
						end else begin
							bit_cnt <= rx_edge_flag ? bit_cnt + 1'b1 : bit_cnt;
							Tx_done <= 1'b0;
						end
					end
				end
		
		TX_DATA : begin
					if(len_cnt == data_len&& (scl_cnt == SCL_CNT_MAX))begin
						len_cnt <= 'd0;
						Tx_done <= 1'b0;
					end else begin
						if(bit_cnt == BIT_CNT_MAX&&rx_edge_flag)begin
							bit_cnt <= 'd0;
							Tx_done <= 1'b1;
							len_cnt <= len_cnt + 1'b1;
						end else begin
							bit_cnt <= rx_edge_flag ? bit_cnt + 1'b1 : bit_cnt;
							Tx_done <= 1'b0;
						end
					end
				end
				
		default	:	begin bit_cnt <= 'd0; len_cnt <= len_cnt;Tx_done <= 1'b0;end
	endcase
	
reg		[7:0]		tdp;	

always@(posedge Clk)
	if(rst)begin	
		tdp <= 'd0;
	end else begin
		tdp <= Cmd_in;
	end
	
reg		[7:0]		tdp_data;	

always@(posedge Clk)
	if(rst)begin	
		tdp_data <= 'd0;
	end else begin
		tdp_data <= (Data_vld) ? Data_in : tdp_data;
	end
/**************************************************************************
//					发送数据
***************************************************************************/
reg				io0_tx,io1_tx,io2_tx,io3_tx;

always@(posedge Clk)
	if(rst)begin
		io0_tx <= 1'b0;//DI
		io1_tx <= 1'b0;//DO
		io2_tx <= 1'b0;
		io3_tx <= 1'b0;
	end else if(cur_state == START && wiat_cs < 'd20) begin
		io0_tx <= tdp[7]; // 预加载命令MSB，确保CS拉低前MOSI稳定
		io1_tx <= 1'b0;
		io2_tx <= 1'b0;
		io3_tx <= 1'b0;
	end else if(edge_flag)begin 
		if(Spi_Width == 4)begin
			if(cur_state == TX_CMD)begin
				io0_tx <= tdp[7-bit_cnt];
				io1_tx <= 1'b0;//DO
				io2_tx <= 1'b0;
				io3_tx <= 1'b0;
			end else if(rd_flag== 'd0)begin
				case(bit_cnt)
					0: begin  // 第1个有效沿：发送高4位[7:4]
						io3_tx <= tdp_data[7];
						io2_tx <= tdp_data[6];
						io1_tx <= tdp_data[5];
						io0_tx <= tdp_data[4];
					end
					1: begin  // 第2个有效沿：发送低4位[3:0]
						io3_tx <= tdp_data[3];
						io2_tx <= tdp_data[2];
						io1_tx <= tdp_data[1];
						io0_tx <= tdp_data[0];
					end
				endcase
			end else begin
				io0_tx <= 1'b0;
				io1_tx <= 1'b0;//DO
				io2_tx <= 1'b0;
				io3_tx <= 1'b0;
			end
		end else begin	
			io0_tx <= cur_state == TX_CMD ? tdp[7-bit_cnt] : tdp_data[7-bit_cnt];
			io1_tx <= 1'b0;//DO
			io2_tx <= 1'b0;
			io3_tx <= 1'b0;
		end
	end 
/**************************************************************************
//					接收数据
***************************************************************************/
wire     	   io0_rx	= Flash_Spi_Sdio[0];    
wire     	   io1_rx	= Flash_Spi_Sdio[1];    
wire     	   io2_rx	= Flash_Spi_Sdio[2];    
wire     	   io3_rx	= Flash_Spi_Sdio[3];    

always@(posedge Clk) begin
    if(rst) begin
        Rd_dat <= 8'd0;
        Rd_dat_vld <= 1'b0;
    end else if(cur_state == TX_DATA)begin
		if(rx_edge_flag && rd_flag == 'd1) begin  
			if(Spi_Width == 4) begin
				case(bit_cnt)
					0: begin  
						Rd_dat[3] <= io3_rx;
						Rd_dat[2] <= io2_rx;
						Rd_dat[1] <= io1_rx;
						Rd_dat[0] <= io0_rx;
					end
					1: begin  
						Rd_dat <= {Rd_dat[3:0],io3_rx, io2_rx, io1_rx, io0_rx};
						Rd_dat_vld <= 1'b1;  
					end
				endcase
			end else begin
				Rd_dat[7-bit_cnt] <= io1_rx;
				Rd_dat_vld <= (bit_cnt == 'd7) ? 1'b1 : 1'b0;
			end
		end else begin
			Rd_dat_vld <= 1'b0;
		end
	end else if(cur_state == TX_CMD&&(rx_edge_flag && rd_flag == 'd1)&&len_cnt!=0)begin//剔除第一个命令
		Rd_dat[7-bit_cnt] <= io1_rx;
		Rd_dat_vld <= (bit_cnt == 'd7) ? 1'b1 : 1'b0;
	end	else begin
		Rd_dat <=Rd_dat;
		Rd_dat_vld <=  1'b0;
	end
end

/**************************************************************************
//					片选
***************************************************************************/
reg				cs_n;
always@(posedge Clk)
	if(rst)begin	
		cs_n <= 1'b1;
	end else case(cur_state) // cur_state == TX_CMD | cur_state == TX_DATA
		IDLE		:	cs_n <= 1'b1;
		START		:	cs_n <= wiat_cs >= 'd30 ? 1'b0 :  1'b1;
		TX_CMD		:	cs_n <= 1'b0;
		TX_DATA		:	cs_n <= 1'b0;
		DONE		:	cs_n <= wiat_cs >= 'd30 ? 1'b1 :  1'b0;
		default		:	cs_n <= 1'b1;
	endcase
/**************************************************************************
//					三态控制
***************************************************************************/
reg		io0_z,io1_z,io2_z,io3_z;


always@(posedge Clk)	
	if(rst)begin
		io0_z <= 'd0;
		io1_z <= 'd0;
		io2_z <= 'd0; 
		io3_z <= 'd0;
	end else if(Spi_Width == 4)begin
		case(cur_state)
			IDLE 	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			START	: begin	io0_z <= 'd1;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			TX_CMD	:  begin
						io0_z <= 'd1;
						io1_z <= 'd0; 
						io2_z <= 'd0; 
						io3_z <= 'd0; 
						end
			TX_DATA	: begin
						io0_z <= rd_flag == 'd0 ? 'd1:'d0; //控制信号为1释放总线读数据
						io1_z <= rd_flag == 'd0 ? 'd1:'d0; 
						io2_z <= rd_flag == 'd0 ? 'd1:'d0; 
						io3_z <= rd_flag == 'd0 ? 'd1:'d0; 
					end
			DONE	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			default	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
		endcase
	end else begin
		case(cur_state)
			IDLE 	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			START	: begin	io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			TX_CMD	: begin
						io0_z <= 'd1; //控制信号为1释放总线读数据
						io1_z <= 'd0; 
						io2_z <= 'd0; 
						io3_z <= 'd0; 
						end
			TX_DATA	: begin
						io0_z <= 'd1; //控制信号为1释放总线读数据
						io1_z <= 'd0; 
						io2_z <= 'd0; 
						io3_z <= 'd0; 
					end
			DONE	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
			default	: begin io0_z <= 'd0;io1_z <= 'd0;io2_z <= 'd0; io3_z <= 'd0;end
		endcase
	end	
	
assign F_SPI_CS 	= cs_n;
assign F_SPI_SCK 	= spi_scl;
assign Flash_Spi_Sdio[0] 	= io0_z ? io0_tx : 1'bz;
assign Flash_Spi_Sdio[1]	= io1_z ? io1_tx : 1'bz;
assign Flash_Spi_Sdio[2]	= io2_z ? io2_tx : 1'bz;
assign Flash_Spi_Sdio[3] 	= io3_z ? io3_tx : 1'bz;

wire	io0	= io0_z ? io0_tx : io0_rx;
wire	io1	= io1_z ? io1_tx : io1_rx;
wire	io2	= io2_z ? io2_tx : io2_rx;
wire	io3	= io3_z ? io3_tx : io3_rx;

/**************************************************************************
//					debug
*************************************************************************** /
(* keep = "true" *)ila_0 flash_ctrl_ila1(
	.clk(Clk), // input wire clk
	.probe0 ({'d0,tdp}), // input wire [31:0]  probe0  
	.probe1 ({'d0,cmd_len,data_len}), // input wire [31:0]  probe1 
	.probe2 ({'d0,cur_state,len_cnt}), // input wire [31:0]  probe2 
	.probe3 ({'d0,SCL_CNT_MAX}), // input wire [31:0]  probe3 
	.probe4 ({'d0,rx_edge_flag,edge_flag, spi_scl,Tx_done,bit_cnt}), // input wire [31:0]  probe4 
	.probe5 ({'d0,scl_cnt}), // input wire [31:0]  probe5 
	.probe6 ({'d0,wiat_cs,rd_flag}), // input wire [31:0]  probe6 
	.probe7 ({'d0,Cmd_in,Cmplt}), // input wire [31:0]  probe7 
	.probe8 ({'d0,rst,cs_n,io0,io1,io2,io3,Rd_dat_vld,Rd_dat,Cmd_vld}) // input wire [31:0]  probe8 
);

/**************************************************************************
//					end
***************************************************************************/
endmodule 