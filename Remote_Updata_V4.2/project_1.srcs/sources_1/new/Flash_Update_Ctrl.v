`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: Flash_Update_Ctrl
// Description: Flash固件更新控制器
//              1. 固件更新：从FIFO读数据写入Flash
//              2. 调试命令：空闲时接收统一flash_op接口转接给Flash控制器
//////////////////////////////////////////////////////////////////////////////////
module Flash_Update_Ctrl #(
    parameter                   Sim_Flg         = 0,
    parameter                   CLK_FREQ        = 200_000_000,
    parameter                   Spi_Width       = 4,
    parameter                   Spi_Dsize       = Spi_Width == 1 ? 2 : 4,
    parameter                   SPI_BAUD        = 10_000_000,
    parameter                   Time_1ms        = Sim_Flg ? 20 : 20_000,
    parameter                   FLASH_BLK_SIZE  = 32'h0001_0000,
    parameter                   PKG_DATA_SIZE   = 'd4096,
    parameter                   FLASH_SEC_SIZE  = 32'h0000_1000,  
    parameter [31:0]            WR_ADDR_MIN     = 32'h0060_0000,
    parameter [31:0]            WR_ADDR_MAX     = 32'h1FFE_0000
)(
    input                       clk,
    input                       rst,
    // 固件更新数据FIFO接口
    output                      fifo_rd_en,
    input   [7:0]               fifo_dout,
    input                       fifo_empty,
    input                       data_rdy,
	// input	[31:0]				PKG_DATA_SIZE,
    output  	               	Wr_End,
    // 回读数据接口
    output  [7:0]               Rd_dat,
    output                      Rd_dat_vld,
	input						last_pack,
    input                       Rx_Busy,
    // 命令接口
    input   [31:0]              cmd_wr_saddr,
    
    //调试接口
    input   [31:0]              flash_addr,
    input   [7:0]               flash_wr_data,
    input  	             		flash_wr_vld, 	
    output  [7:0]               flash_rd_data,
    output                      flash_rd_valid,
    input   [2:0]               flash_op_type,
    input                       flash_op_req,
    output  reg                 flash_op_done,
    
    // 状态输出
    output  [1:0]               work_state,
    output                      wr_success,
    output                      error_flag,
    
    // Flash物理接口
    output                      Flash_Spi_Csn,
    inout   [Spi_Dsize-1:0]     Flash_Spi_Sdio
);

// 操作类型定义
localparam  OP_NONE     = 3'd0,		
            OP_WRITE    = 3'd1,    	//1：Page写
            OP_READ     = 3'd2,   	//2：Page读 
            OP_ERASE    = 3'd3;   	//3: Block擦除 

// 状态定义
localparam  DEBUG_CMD	 = 4'd1,
            INIT_START  = 4'd0,
            ERASE       = 4'd2,
            WRITE       = 4'd3,
            READ        = 4'd4,
            WR_DONE     = 4'd5,
            // 调试命令状态
            DBG_ERASE   = 4'd6,
            DBG_WRITE   = 4'd7,
            DBG_READ    = 4'd8,
            DBG_DONE    = 4'd9;

reg [3:0] state;
assign work_state = state[1:0];

wire [31:0] PKG_PAGE_NUM = PKG_DATA_SIZE / 'd256;

/***************************************************************************
// 地址计算
***************************************************************************/
reg [15:0] Frm_Nmb;
reg [10:0] ber_cnt;

wire	[31:0]		r_saddr		= {(cmd_wr_saddr[31:12] + Frm_Nmb), 12'd0};		//	4KB对齐写入地址
wire	[31:0]		br_saddr	= {(cmd_wr_saddr[31:16] + ber_cnt), 16'd0};		//	64KB对齐擦除地址
/***************************************************************************
// Flash控制器接口
***************************************************************************/
wire [12:0] flash_rd_count;
reg [2:0]   pol_cnt;

wire        Flash_C_rdy;
reg         Start_Inital;
reg         Flash_C_Val;
reg [2:0]   Flash_C_Type;	//读写操作类型		0：Page写
							//					1：Page读
							//               	2: Sector擦除 
							//				 	3: Block擦除
reg [13:0]  Flash_C_Num;
reg [31:0]  Flash_C_Saddr;
wire        Flash_C_Cmplt;
wire [23:0] Spi_C_Op_Num;

reg         Wr_End_reg;
reg 	last_pack_reg;
assign Wr_End = Wr_End_reg;

/***************************************************************************
// 主状态机
***************************************************************************/

reg [5:0] wr_cnt;
always@(posedge clk)
if(rst) begin
    state           <= INIT_START;
    Flash_C_Val     <= 1'b0;
    Start_Inital    <= 1'b0;
    Flash_C_Type    <= 3'd0;
    Flash_C_Num     <= 14'd0;
    Flash_C_Saddr   <= 32'd0;
    pol_cnt         <= 3'd0;
    Wr_End_reg      <= 1'b0;
    ber_cnt         <= 11'd0;
    flash_op_done   <= 1'b0;
end else begin
    flash_op_done   <= 1'b0;
    case(state)
        DEBUG_CMD: begin
            pol_cnt <= 3'd0;
            Flash_C_Saddr <= flash_addr;
            case(flash_op_type)
                OP_WRITE: begin
                    state <= DBG_WRITE;
                    Flash_C_Type <= 3'd0;   // Page写
                    Flash_C_Num <= 14'd1;
                end
                OP_READ: begin
                    state <= DBG_READ;
                    Flash_C_Type <= 3'd1;   // Page读
                    Flash_C_Num <= 14'd1;
                end
                OP_ERASE: begin
                    state <= DBG_ERASE;
                    Flash_C_Type <= 3'd3;   // Block擦除
                    Flash_C_Num <= 14'd1;
                end
                default: state <= DEBUG_CMD;
            endcase
        end

        // ========== 调试命令：擦除 ==========
        DBG_ERASE: begin
			state <= Flash_C_Cmplt ? DBG_DONE : DBG_ERASE;
            Flash_C_Val <= (pol_cnt == 3'd2) ? 1'b1 : 1'b0;
            Start_Inital <= 1'b0;
            Flash_C_Type <=  3'd3;
            Flash_C_Num <= 14'd1;
            if(Flash_C_Cmplt) begin
                pol_cnt <= 3'd0;
            end else begin
                pol_cnt <= (pol_cnt == 3'd3) ? pol_cnt : pol_cnt + 1'b1;
            end
            Flash_C_Saddr <= flash_addr;
        end

        // ========== 调试命令：写入 ==========
        DBG_WRITE: begin
			state <= Flash_C_Cmplt ? DBG_DONE : DBG_WRITE;
            Flash_C_Val <= (pol_cnt == 3'd2) ? 1'b1 : 1'b0;
            Start_Inital <= 1'b0;
            Flash_C_Type <=  3'd0;
            Flash_C_Num <= 14'd1;
            if(Flash_C_Cmplt) begin
                pol_cnt <= 3'd0;
            end else begin
                pol_cnt <= (pol_cnt == 3'd3) ? pol_cnt : pol_cnt + 1'b1;
            end
            Flash_C_Saddr <= flash_addr;
        end

        // ========== 调试命令：读取 ==========
        DBG_READ: begin
            state <= Flash_C_Cmplt ? DBG_DONE : DBG_READ;
            Flash_C_Val <= (pol_cnt == 3'd2) ? 1'b1 : 1'b0;
            Start_Inital <= 1'b0;
            Flash_C_Type <=  3'd1;
            Flash_C_Num <= 14'd1;
            if(Flash_C_Cmplt) begin
                pol_cnt <= 3'd0;
            end else begin
                pol_cnt <= (pol_cnt == 3'd3) ? pol_cnt : pol_cnt + 1'b1;
            end
            Flash_C_Saddr <= flash_addr;
        end

        DBG_DONE: begin
            // 在操作完成后，等待FIFO为空再返回INIT_START
            // 防止残留数据影响下一次操作
            state <= (flash_rd_count == 0) ? INIT_START : DBG_DONE;
			flash_op_done   <= (flash_rd_count == 0) ? 1'b1 : 1'b0;
            Flash_C_Val <= 1'b0;
            pol_cnt <= 3'd0;
        end

        // ========== 固件更新流程 ==========
		INIT_START	:	begin
			//	r_saddr >= FLASH_BLK_SIZE 时判断当前Block是否已擦除
			if(r_saddr >= FLASH_BLK_SIZE)
				state	<= (Flash_C_rdy && flash_rd_count >= PKG_DATA_SIZE) ?
						(wr_cnt == PKG_PAGE_NUM ? ERASE : WRITE) : (flash_op_req ? DEBUG_CMD : INIT_START);
			else
				state	<= (Flash_C_rdy && flash_rd_count >= PKG_DATA_SIZE) ?
						ERASE : (flash_op_req ? DEBUG_CMD : INIT_START);
			Flash_C_Val		<= 1'b0;
			Start_Inital	<= 1'b1;
			Wr_End_reg			<= 1'b0;
			Flash_C_Type	<= 'd0;
			Flash_C_Num		<= 'd0;
			pol_cnt			<= 'd0;
			Flash_C_Saddr	<= r_saddr;
		end
       

        ERASE: begin
			state		<=  Flash_C_Cmplt ? WRITE : ERASE;
			Flash_C_Val	<= pol_cnt == 'd2 ? 1'b1 : 1'b0;
			Start_Inital<= 1'b0;
			//	起始地址 >= FLASH_BLK_SIZE：Block擦除，否则Sector擦除
			Flash_C_Type<= r_saddr >= FLASH_BLK_SIZE ? 'd3 : 'd2;
			Wr_End_reg		<= 1'b0;
			Flash_C_Num	<= 'd1;
			if(Flash_C_Cmplt)begin
				pol_cnt	<= 'd0;
				ber_cnt	<= r_saddr >= FLASH_BLK_SIZE ? ber_cnt + 1'b1 : ber_cnt;
			end else begin
				pol_cnt	<= pol_cnt == 'd3 ? pol_cnt : pol_cnt + 1;
			end
			//	Block擦除用64KB对齐地址，Sector擦除用4KB对齐地址
			Flash_C_Saddr	<= r_saddr >= FLASH_BLK_SIZE ? br_saddr : r_saddr;
        end

        WRITE: begin
            state <= Flash_C_Cmplt ? READ : WRITE;
            Wr_End_reg <= 1'b0;
            Flash_C_Val <= (pol_cnt == 3'd2) ? 1'b1 : 1'b0;
            Start_Inital <= 1'b0;
            Flash_C_Type <= 3'd0;
            Flash_C_Num <= PKG_PAGE_NUM;
            if(Flash_C_Cmplt)
                pol_cnt <= 3'd0;
            else
                pol_cnt <= (pol_cnt == 3'd3) ? pol_cnt : pol_cnt + 1'b1;
            Flash_C_Saddr <= r_saddr;
        end

        READ: begin
            state <= Flash_C_Cmplt ? WR_DONE : READ;
            Flash_C_Val <= (pol_cnt == 3'd2) ? 1'b1 : 1'b0;
            Start_Inital <= 1'b0;
            Flash_C_Type <= 3'd1;
            Wr_End_reg <= 1'b0;
            Flash_C_Num <= PKG_PAGE_NUM;
            if(Flash_C_Cmplt)
                pol_cnt <= 3'd0;
            else
                pol_cnt <= (pol_cnt == 3'd3) ? pol_cnt : pol_cnt + 1'b1;
            Flash_C_Saddr <= r_saddr;
        end
		
        WR_DONE: begin
            state <= INIT_START;
            Flash_C_Val <= 1'b0;
            Start_Inital <= 1'b0;
            Wr_End_reg <= 1'b1;
			ber_cnt <= last_pack ? 'd0 : ber_cnt;
        end

        default: state <= INIT_START;
    endcase
end


/***************************************************************************
// 写入计数
***************************************************************************/
always@(posedge clk)
	if(rst)
		Frm_Nmb	<= 'd0;
	else if(Wr_End)
		Frm_Nmb	<= last_pack ? 'd0 : Frm_Nmb + 1'b1;
	else
		Frm_Nmb	<= Frm_Nmb;
		
always@(posedge clk)
	if(rst)
		wr_cnt	<= PKG_PAGE_NUM;
	else if(wr_cnt == 'd0)
		wr_cnt	<= PKG_PAGE_NUM;
	else
		wr_cnt	<= Wr_End ? wr_cnt - 1'b1 : wr_cnt;
/***************************************************************************
// 状态标志
***************************************************************************/
reg wr_success_flag;
reg error_flag_r;

assign wr_success = wr_success_flag;
assign error_flag = error_flag_r;

always@(posedge clk)
if(rst) begin
    wr_success_flag <= 1'b0;
    error_flag_r <= 1'b0;
end else begin
    if(Rx_Busy && state != DEBUG_CMD)
        error_flag_r <= 1'b1;
    if(state == DEBUG_CMD && data_rdy) begin
        wr_success_flag <= 1'b0;
        error_flag_r <= 1'b0;
    end
    if(state == WR_DONE && last_pack_reg)
        wr_success_flag <= 1'b1;
end

/***************************************************************************
// FIFO数据转移
***************************************************************************/
wire        flash_fifo_wr_en;
wire [7:0]  flash_fifo_wrdata;
reg         fifo_rd_en_int;
reg         wr_en_reg;

always@(posedge clk)
	if(rst)
		wr_en_reg	<= 1'b0;
	else  
		wr_en_reg <=  fifo_rd_en_int;
		
assign	flash_fifo_wr_en = flash_wr_vld | wr_en_reg;
assign flash_fifo_wrdata = flash_wr_vld ? flash_wr_data : fifo_dout;

always@(posedge clk)
if(rst)
    fifo_rd_en_int <= 1'b0;
else if(state == INIT_START || state == DBG_DONE) begin
    // 在INIT_START和DBG_DONE状态都允许读取FIFO
    // DBG_DONE状态用于清空残留数据
    if(fifo_rd_en_int)
        fifo_rd_en_int <= 1'b0;
    else if(~fifo_empty)
        fifo_rd_en_int <= 1'b1;
end else
    fifo_rd_en_int <= 1'b0;

assign fifo_rd_en = fifo_rd_en_int;

wire	[7:0]	Rd_dat_r;
wire			Rd_dat_vld_r;


// 读数据输出
assign flash_rd_data = Rd_dat_r;
assign flash_rd_valid = Rd_dat_vld_r && (state == DBG_READ);

assign Rd_dat = Rd_dat_r;
assign Rd_dat_vld = Rd_dat_vld_r && (state == READ);

/***************************************************************************
// Flash控制器
***************************************************************************/
wire F_SPI_SCK;

Spi_Flash_Ctrl #(
    .Sim_Flg    (Sim_Flg),
    .Spi_Width  (Spi_Width),
    .Time_1ms   (Time_1ms),
    .SPI_BAUD   (SPI_BAUD)
) Spi_Flash_Ctrl_ins (
    .Clk            (clk),
    .Rst            (rst),
    .Start_Inital   (Start_Inital),
    .Flash_Rd_dat   (Rd_dat_r),
    .Flash_Rd_dat_vld(Rd_dat_vld_r),
    .fifo_wr_clk    (clk),
    .fifo_wr_en     (flash_fifo_wr_en),
    .fifo_wrdata    (flash_fifo_wrdata),
    .fifo_rd_count  (flash_rd_count),
    .Flash_C_rdy    (Flash_C_rdy),
    .Flash_C_Val    (Flash_C_Val),
    .Flash_C_Type   (Flash_C_Type),
    .Flash_C_Num    (Flash_C_Num),
    .Flash_C_Saddr  (Flash_C_Saddr),
    .Flash_C_Cmplt  (Flash_C_Cmplt),
    .Flash_Flash_Id (),
    .Spi_C_Op_Num   (Spi_C_Op_Num),
    .F_SPI_CS       (Flash_Spi_Csn),
    .Flash_Spi_Sdio (Flash_Spi_Sdio),
    .F_SPI_SCK      (F_SPI_SCK)
);

//***************************************************************************
// SPI时钟引脚
//***************************************************************************
(* keep = "true" *) wire unused_startupe;
(* keep = "true" *) STARTUPE2 #(
    .PROG_USR       ("FALSE"),
    .SIM_CCLK_FREQ  (0.0)
) STARTUPE2_inst (
    .CFGCLK         (),
    .CFGMCLK        (),
    .EOS            (unused_startupe),
    .PREQ           (),
    .CLK            (1'b0),
    .GSR            (1'b0),
    .GTS            (1'b0),
    .KEYCLEARB      (1'b1),
    .PACK           (1'b1),
    .USRCCLKO       (F_SPI_SCK),
    .USRCCLKTS      (1'b0),
    .USRDONEO       (1'b1),
    .USRDONETS      (1'b1)
);
/***************************************************************************
// SPI时钟引脚
***************************************************************************/

ila_0 flash_ila(
	.clk(clk), // input wire clk
	.probe0 ({'d0,flash_addr}), // input wire [31:0]  probe0  
	.probe1 ({'d0,flash_rd_count,Flash_C_rdy}), // input wire [31:0]  probe1 
	.probe2 ({'d0,Flash_C_Cmplt}), // input wire [31:0]  probe2 
	.probe3 ({'d0,wr_data_next}), // input wire [31:0]  probe3 
	.probe4 ({'d0,flash_op_type}), // input wire [31:0]  probe4 
	.probe5 ({'d0,Flash_C_Val,wr_cnt}), // input wire [31:0]  probe5 
	.probe6 ({'d0,state,Wr_End_reg,flash_fifo_wr_en,flash_fifo_wrdata}), // input wire [31:0]  probe6 
	.probe7 (Flash_C_Saddr), // input wire [31:0]  probe7 
	.probe8 ({'d0,Flash_C_Type,Flash_C_Val,flash_wr_vld}) // input wire [31:0]  probe8 
);


/***************************************************************************
// end
***************************************************************************/

endmodule
