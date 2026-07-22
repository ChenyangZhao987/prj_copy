

`timescale 1ns / 1ps

/***************************************************************************************************
	FileName	:	icape2_module
	Author		:	lta
	Description	:	iCAPE2产生IPROG指令模块
	Revision	:	V1.0	2017-04-21
	Company		:	Xi'an iThor IT CO.,Ltd. 
	Copyright(c) 	2017 Xi'an iThor IT CO.,Ltd., All right reserved
	Modified	:	    
	  
***************************************************************************************************/
module  ICAPE2_CTRL (
    input           Clk,
    input           Rst,
    
    input           Iprog,          //  触发指示，上升沿有效
    input   [31:0]  Warm_Baddr,     //  热启动地址
    
    output          Ready
    );

/*******************************************************************************
//  同步
*******************************************************************************/
reg             r_rst,
                rr_rst;
reg             r_iprog,
                rr_iprog,
                r3_iprog;                
always @(posedge Clk)
begin
    r_rst   <=  Rst;
    rr_rst  <=  r_rst;
    r_iprog <= Iprog;
    rr_iprog<= r_iprog;
    r3_iprog<= rr_iprog;
end

/*******************************************************************************
//  状态机
*******************************************************************************/
localparam      IPROG_IDLE  = 2'd0,
                IPROG_START = 2'd1,
                IPROG_DATA  = 2'd2,
                IPROG_END   = 2'd3;
reg             r_icape_csn;
reg             r_icape_wr;
reg [2:0]       wr_cnt;
reg [1:0]       iprog_state;
always @(posedge Clk)
begin
    if(rr_rst)begin
        r_icape_csn <='b1;
        r_icape_wr  <='b1;
        iprog_state <=IPROG_IDLE;
    end else begin
        case(iprog_state)
            IPROG_IDLE  :   begin
                                r_icape_csn <='b1;
                                r_icape_wr  <='b1;
                                iprog_state <=rr_iprog&(~r3_iprog) ? IPROG_START : IPROG_IDLE;
                            end
            IPROG_START :   begin
                                r_icape_csn <='b1;
                                r_icape_wr  <='b0;
                                iprog_state <=IPROG_DATA;
                            end
            IPROG_DATA  :   begin
                                r_icape_csn <='b0;
                                r_icape_wr  <='b0;
                                iprog_state <=wr_cnt=='d7 ? IPROG_END : IPROG_DATA;
                            end
            IPROG_END   :   begin
                                r_icape_csn <='b1;
                                r_icape_wr  <='b0;
                                iprog_state <=IPROG_IDLE;
                            end
            default     :   begin
                                r_icape_csn <='b1;
                                r_icape_wr  <='b1;
                                iprog_state <=IPROG_IDLE;
                            end
        endcase                            
    end
end    

/*******************************************************************************
//  写计数器
*******************************************************************************/
always @(posedge Clk)
begin
    if(rr_rst)
        wr_cnt<='d0;
    else if(iprog_state==IPROG_DATA)
        wr_cnt<=wr_cnt+1'b1;
    else
        wr_cnt<='d0;
end
    
/*******************************************************************************
//  写数据
*******************************************************************************/
reg [31:0]      r_icape_din;
always @(posedge Clk)
begin
    if(rr_rst)
        r_icape_din<='d0;
    else if(iprog_state==IPROG_DATA)
        case(wr_cnt)
            3'd0    :   r_icape_din<=32'hFFFF_FFFF;     //  Dummy Word
            3'd1    :   r_icape_din<=32'hAA99_5566;     //  Sync Word
            3'd2    :   r_icape_din<=32'h2000_0000;     //  Type 1 NO OP
            3'd3    :   r_icape_din<=32'h3002_0001;     //  Type 1 Write 1 Words to WBSTAR
            3'd4    :   r_icape_din<={8'd0,Warm_Baddr[31:8]}; //  Warm Boot Start Address (Load the Desired Address)
            3'd5    :   r_icape_din<=32'h3000_8001;     //  Type 1 Write 1 Words to CMD
            3'd6    :   r_icape_din<=32'h0000_000F;     //  IPROG Command
            3'd7    :   r_icape_din<=32'h2000_0000;     //  Type 1 NO OP
            default :   r_icape_din<=32'd0;
        endcase
    else
        r_icape_din<='d0;
end

/*******************************************************************************
//  准备就绪
*******************************************************************************/
reg             r_ready;
always @(posedge Clk)
begin
    if(rr_rst)
        r_ready<='b0;
    else if(iprog_state==IPROG_IDLE)
        r_ready<='b1;
    else
        r_ready<='b0;
end
assign  Ready = r_ready;

/*******************************************************************************
//  字节位交换
*******************************************************************************/
wire[31:0]      icape_din;
genvar	i;
generate	
	for(i=0;i<8;i=i+1) begin : bitswap_inst	
	    assign icape_din[i]   = r_icape_din[7-i];
	    assign icape_din[8+i] = r_icape_din[15-i];
	    assign icape_din[16+i]= r_icape_din[23-i];
	    assign icape_din[24+i]= r_icape_din[31-i];
	end
endgenerate

/*******************************************************************************
//  ICAPE2例化
*******************************************************************************/
    ICAPE2      #(
                .DEVICE_ID  (32'h3651093    ),  // Specifies the pre-programmed Device ID value to be used for simulation purposes.
                .ICAP_WIDTH ("X32"          ),  // Specifies the input and output data width.
                .SIM_CFG_FILE_NAME("None"   )   // Specifies the Raw Bitstream (RBT) file to be parsed by the simulation model.
                )icape2_blk(
                .O      (),             // 32-bit output: Configuration data output bus
                .CLK    (Clk        ),  // 1-bit input: Clock Input
                .CSIB   (r_icape_csn),  // 1-bit input: Active-Low ICAP Enable
                .I      (icape_din  ),  // 32-bit input: Configuration data input bus
                .RDWRB  (r_icape_wr )   // 1-bit input: Read/Write Select input
                );

endmodule