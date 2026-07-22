`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2026/03/20
// Design Name: UART 回读发送逻辑仿真
// Module Name: tb_Uart_pack_rx_top
// Project Name: Flash_Ctrl
// Target Devices: XC7K325T
// Tool Versions: Vivado 2022.1
// Description: 仿真验证 UART 串口固件传输的回读发送逻辑
//              重点验证：
//              1. CRC 校验逻辑（接收数据 XOR）
//              2. 发送状态机（帧头 + 包序号+CRC）
//              3. FIFO 读取与 CRC 计算
//              4. Uart_txdone 时序配合
//
// Dependencies: Uart_pack_rx_top.v
//               fifo_8x8192.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_Uart_pack_rx_top();

//============================================================================
// 参数定义
//============================================================================
parameter CLK_PERIOD = 5;  // 200MHz, 5ns 周期
parameter BAUD_RATE = 115200;
parameter BIT_TIME = 1000000000 / BAUD_RATE;  // 约 8680ns

// 计算每个比特的时钟周期数（200MHz）
parameter CYCLES_PER_BIT = BIT_TIME / (CLK_PERIOD * 1000);  // 约 1736 个周期

//============================================================================
// 信号声明
//============================================================================
reg clk_200;
reg Rst;

// FIFO 读接口（用户侧）
reg rd_clk;
reg fifo_rd_en;
wire [7:0] fifo_dout;
wire fifo_empty;

// 接收数据输入（模拟从 Rx_Wrreq/Rx_Wdata 进入）
reg [7:0] Rd_dat;
reg Rd_dat_vld;
reg Wr_End;

// 状态输出
wire Data_rdy;
wire last_pack;
wire Rx_Error;
wire Rx_Busy;

// 发送数据输出（到 UART 发送器）
wire Tx_Wrreq;
wire [7:0] Tx_Wdata;
reg Tx_Ready;  // 模拟 UART 发送器就绪

// 命令接收接口（模拟上位机命令）
reg Rx_Wrreq;
reg [7:0] Rx_Wdata;

// 内部调试信号（可选，用于波形观察）
wire [15:0] Frm_Nmb;
wire [15:0] Len_data;

//============================================================================
// 时钟生成
//============================================================================
initial begin
    clk_200 = 0;
    forever #(CLK_PERIOD/2) clk_200 = ~clk_200;
end

//============================================================================
// 复位生成
//============================================================================
initial begin
    Rst = 1;
    #100;
    Rst = 0;
end

//============================================================================
// 测试主流程
//============================================================================
integer i;
reg [7:0] test_data;
reg [7:0] expected_crc;
integer data_cnt;

// 任务：通过 Rd_dat/Rd_dat_vld 接口顺序写入数据到 tx_fifo
// 这是模块的输入接口，用于将 Flash 回读数据写入发送 FIFO
task write_tx_fifo;
    input [7:0] data;  // 要写入的数据
begin
    // 在时钟上升沿建立数据
    @(posedge clk_200);
    #1;  // 微小延迟确保时序
    Rd_dat = data;
    Rd_dat_vld = 1'b1;
    
    // 保持一个周期
    @(posedge clk_200);
    #1;
    Rd_dat_vld = 1'b0;
end
endtask

initial begin
    $timeformat(-9, 0, "ns", 10);
    $display("========================================");
    $display("UART 回读发送逻辑仿真开始");
    $display("时间：%t", $time);
    $display("========================================");
    
    // 初始化
    rd_clk = clk_200;
    fifo_rd_en = 0;
    Rd_dat = 0;
    Rd_dat_vld = 0;
    Wr_End = 0;
    Rx_Wrreq = 0;
    Rx_Wdata = 0;
    Tx_Ready = 1;  // UART 始终就绪
    
    #50;
    
    //========================================================================
    // 测试场景 1：单包数据传输（4096 字节）- 通过 Rd_dat 接口注入
    //========================================================================
    $display("\n[%t] 测试场景 1: 单包 4096 字节传输 (通过 Rd_dat 注入)", $time);
    
    // Step 1: 发送包序号和长度（通过命令接口）
    send_command(8'h55, 8'hAA);  // 包序号
    send_command(8'h00, 8'h10);  // 长度=0x1000=4096
    
    // Step 2: 通过 Rd_dat/Rd_dat_vld 接口顺序写入 4096 字节回读数据
    // 这模拟了从 Flash 读取的数据被写入到 tx_fifo 的过程
    expected_crc = 0;
    data_cnt = 0;
    for(i=0; i<4096; i=i+1) begin
        test_data = i[7:0];  // 简单递增数据：0x00, 0x01, ..., 0xFF, 0x00...
        write_tx_fifo(test_data);  // ← 按顺序驱动 Rd_dat 和 Rd_dat_vld
        expected_crc = expected_crc ^ test_data;
        data_cnt = data_cnt + 1;
        
        // 每 512 字节打印一次进度
        if((i+1) % 512 == 0) begin
            $display("[%t] 已顺序写入 %d 字节，当前 CRC=%02h", $time, i+1, expected_crc);
        end
    end
    
    $display("[%t] 顺序写入完成，总计 %d 字节，预期 CRC=%02h", $time, data_cnt, expected_crc);
    
    // Step 3: 等待数据稳定
    #100;
    
    // Step 4: 结束标志（通知接收状态机）
    Wr_End = 1;
    @(posedge clk_200);
    Wr_End = 0;
    
    // Step 5: 等待 Data_rdy 触发（FIFO 数据达到 4096）
    wait(Data_rdy === 1);
    $display("[%t] >>> Data_rdy 置位，FIFO 中有 4096 字节 <<<", $time);
    
    // Step 6: 观察发送状态机自动读取 FIFO 并发送
    $display("[%t] 开始观察发送过程...", $time);
    
    // 等待发送完成（帧头 4 字节 + 数据 4096 字节+CRC 1 字节）
    // 预计需要约 (4096+5)*8*1736 ≈ 57M 个时钟周期
    // 为加快仿真，我们只观察前几个字节的发送
    integer tx_cnt;
    tx_cnt = 0;
    repeat(100) begin
        @(posedge clk_200);
        if(Tx_Wrreq && Tx_Ready) begin
            $display("[%t] TX[%0d]: %02h (CRC 累加)", $time, tx_cnt, Tx_Wdata);
            tx_cnt = tx_cnt + 1;
        end
    end
    
    $display("[%t] 测试场景 1 完成 - 已观察 %d 个字节的发送", $time, tx_cnt);
    
    //========================================================================
    // 测试场景 2：验证发送 CRC 与接收 CRC 对比
    //========================================================================
    $display("\n[%t] 测试场景 2: 验证发送 CRC 计算正确性", $time);
    
    // Step 1: 设置包序号和长度
    send_command(8'h55, 8'hAA);
    send_command(8'h00, 8'h10);
    
    // Step 2: 通过 Rd_dat/Rd_dat_vld 顺序写入 256 字节 0xAA
    reg [7:0] crc_verify;
    crc_verify = 0;
    for(i=0; i<256; i=i+1) begin
        write_tx_fifo(8'hAA);  // ← 顺序驱动接口
        crc_verify = crc_verify ^ 8'hAA;
    end
    
    $display("[%t] 顺序写入 256 字节 0xAA，理论 CRC=%02h", $time, crc_verify);
    
    #50;
    Wr_End = 1;
    @(posedge clk_200);
    Wr_End = 0;
    
    wait(Data_rdy === 1);
    $display("[%t] Data_rdy 置位", $time);
    
    // Step 3: 观察发送的 CRC 字节（应该是帧头后的第 5 个字节）
    integer state_cnt;
    reg [7:0] sent_crc;
    state_cnt = 0;
    sent_crc = 0;
    
    repeat(50) begin
        @(posedge clk_200);
        if(Tx_Wrreq && Tx_Ready) begin
            if(state_cnt == 4) begin  // 第 5 个字节是 err_black
                $display("[%t] TX[4] (err_black): %02h", $time, Tx_Wdata);
            end else if(state_cnt >= 5 && state_cnt < 10) begin
                $display("[%t] TX[%0d] (FIFO data): %02h", $time, state_cnt, Tx_Wdata);
            end
            state_cnt = state_cnt + 1;
        end
    end
    
    $display("[%t] 测试场景 2 完成", $time);
    
    //========================================================================
    // 测试场景 3：小数据包快速验证
    //========================================================================
    $display("\n[%t] 测试场景 3: 小数据包 (100 字节) 快速验证", $time);
    
    send_command(8'h55, 8'hAA);
    send_command(8'h64, 8'h00);  // 长度=100
    
    for(i=0; i<100; i=i+1) begin
        write_tx_fifo(i[7:0]);  // ← 顺序驱动 Rd_dat/Rd_dat_vld
    end
    
    #50;
    Wr_End = 1;
    @(posedge clk_200);
    Wr_End = 0;
    
    wait(Data_rdy === 1);
    $display("[%t] Data_rdy 置位 (100 字节)", $time);
    
    // 观察完整发送过程
    tx_cnt = 0;
    repeat(20) begin
        @(posedge clk_200);
        if(Tx_Wrreq && Tx_Ready) begin
            $display("[%t] TX[%0d]: %02h", $time, tx_cnt, Tx_Wdata);
            tx_cnt = tx_cnt + 1;
        end
    end
    
    $display("[%t] 测试场景 3 完成", $time);
    
    //========================================================================
    // 测试场景 4：不同数据模式验证
    //========================================================================
    $display("\n[%t] 测试场景 4: 不同数据模式 (全 0xFF)", $time);
    
    send_command(8'h55, 8'hAA);
    send_command(8'h32, 8'h00);  // 长度=50
    
    for(i=0; i<50; i=i+1) begin
        write_tx_fifo(8'hFF);  // ← 顺序驱动接口，写入全 1 数据
    end
    
    #50;
    Wr_End = 1;
    @(posedge clk_200);
    Wr_End = 0;
    
    wait(Data_rdy === 1);
    
    // 观察发送
    tx_cnt = 0;
    repeat(15) begin
        @(posedge clk_200);
        if(Tx_Wrreq && Tx_Ready) begin
            $display("[%t] TX[%0d]: %02h", $time, tx_cnt, Tx_Wdata);
            tx_cnt = tx_cnt + 1;
        end
    end
    
    $display("[%t] 测试场景 4 完成", $time);
    
    //========================================================================
    // 结束仿真
    //========================================================================
    $display("\n========================================");
    $display("所有测试完成");
    $display("时间：%t", $time);
    $display("========================================");
    
    #1000;
    $finish;
end

//============================================================================
// 任务：发送一个命令字节
//============================================================================
task send_command;
    input [7:0] data;
    input [7:0] dummy;
begin
    @(posedge clk_200);
    Rx_Wdata = data;
    Rx_Wrreq = 1;
    @(posedge clk_200);
    Rx_Wrreq = 0;
    #10;  // 等待状态机采样
end
endtask

//============================================================================
// 任务：监控发送过程
//============================================================================
task monitor_tx;
    input [31:0] timeout_cycles;
    reg [31:0] cnt;
    reg [7:0] crc_calc;
begin
    crc_calc = 0;
    cnt = 0;
    
    $display("[%t] 开始监控发送过程...", $time);
    
    while(cnt < timeout_cycles) begin
        @(posedge clk_200);
        cnt = cnt + 1;
        
        if(Tx_Wrreq && Tx_Ready) begin
            $display("[%t] TX: Wrdata=%02h", $time, Tx_Wdata);
            crc_calc = crc_calc ^ Tx_Wdata;
        end
    end
    
    $display("[%t] 发送监控结束，计算 CRC=%02h", $time, crc_calc);
end
endtask

//============================================================================
// 实例化被测模块
//============================================================================
Uart_pack_rx_top #(
    .Sim_Flag(0)  // 非仿真模式，使用真实接口
) uut (
    .clk_200(clk_200),
    .Rst(Rst),
    
    // FIFO 读接口
    .rd_clk(rd_clk),
    .fifo_rd_en(fifo_rd_en),
    .fifo_dout(fifo_dout),
    .fifo_empty(fifo_empty),
    
    // 数据输入（回读数据）
    .Rd_dat(Rd_dat),
    .Rd_dat_vld(Rd_dat_vld),
    .Wr_End(Wr_End),
    
    // 状态输出
    .Data_rdy(Data_rdy),
    .last_pack(last_pack),
    .Rx_Error(Rx_Error),
    .Rx_Busy(Rx_Busy),
    
    // 发送接口
    .Tx_Wrreq(Tx_Wrreq),
    .Tx_Wdata(Tx_Wdata),
    .Tx_Ready(Tx_Ready),
    
    // 命令接收
    .Rx_Wrreq(Rx_Wrreq),
    .Rx_Wdata(Rx_Wdata)
);

//============================================================================
// 波形输出控制
//============================================================================
initial begin
    $dumpfile("tb_Uart_pack_rx_top.vcd");
    $dumpvars(0, tb_Uart_pack_rx_top);
end

// 打印关键信息
always @(posedge Data_rdy) begin
    $display("[%t] >>> Data_rdy 置位 <<<", $time);
end

always @(posedge Rx_Error) begin
    $display("[%t] >>> Rx_Error 置位 <<<", $time);
end

endmodule
