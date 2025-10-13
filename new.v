module biss_host_fpga #(
    parameter SYS_CLK_MAX_FREQ = 100_000_000,  // 系统时钟最大频率（100MHz）
    parameter POS_DATA_WIDTH    = 32,           // 位置数据位宽（32位）
    parameter TIMEOUT_MAX       = 16'd1000      // 超时阈值（系统时钟周期，防死锁）
) (
    input  wire                     clk_sys,
    input  wire                     rst_n,
    input  wire                     biss_start,
    input  wire [31:0]              cfg_ma_freq,
    input  wire [7:0]               cfg_scd_width,
    input  wire [3:0]               cfg_crc_width,
    input  wire [15:0]              cfg_crc_poly,
    input  wire                     cfg_cdm_bit,
    input  wire                     sl_in,
    output reg                      ma_out,
    output reg [POS_DATA_WIDTH-1:0] pos_data,
    output reg                      error_flag,
    output reg                      warn_flag,
    output reg                      crc_err,
    output reg                      timeout_err,
    output reg                      data_valid,
    output reg [2:0]                curr_state
);

// -------------------------- 1. 内部参数与信号定义 --------------------------
// 通信状态编码
localparam ST_IDLE      = 3'd0;  // 空闲（MA高，等待启动）
localparam ST_START     = 3'd1;  // START阶段（输出2个MA脉冲）
localparam ST_TRANSMIT  = 3'd2;  // 传输阶段（MA持续脉冲，接收SCD）
localparam ST_TIMEOUT   = 3'd3;  // Timeout阶段（MA复用为CDM，等待SL拉高）

// MA时钟分频参数（系统时钟→MA时钟，50%占空比）
localparam MA_DIV_MAX   = SYS_CLK_MAX_FREQ / 1_000_000;  // 最大分频系数（1MHz MA对应100分频）
reg [15:0] ma_div;                                        // 实际分频系数（=clk_sys/cfg_ma_freq）
reg [15:0] ma_div_cnt;                                    // 分频计数器
reg        ma_clk;                                        // 内部MA时钟（50%占空比）

// SL信号处理（同步+边沿检测）
reg [1:0] sl_sync;                                        // 两级同步（防亚稳态）
reg        sl_ack_det;                                    // SL拉低检测（从机ACK应答）

// 数据接收与校验
reg [7:0]  scd_rx_cnt;                                    // SCD接收位数计数器
reg [63:0] scd_shift_reg;                                  // SCD移位寄存器（最大64位）
reg [15:0] crc_reg;                                       // CRC校验寄存器（兼容16位）
reg        crc_calc_en;                                   // CRC计算使能

// 超时控制
reg [15:0] timeout_cnt;                                   // 超时计数器

// -------------------------- 2. 初始化：计算MA分频系数 --------------------------
// 复位时根据配置的MA频率计算分频系数（clk_sys / cfg_ma_freq）
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        ma_div <= 16'd10;  // 默认10分频（100MHz→10MHz MA）
    end else begin
        if (cfg_ma_freq > 0) begin
            ma_div <= SYS_CLK_MAX_FREQ / cfg_ma_freq;  // 整数分频（需确保clk_sys是cfg_ma_freq的整数倍）
        end else begin
            ma_div <= 16'd10;  // 频率配置错误时默认10MHz
        end
    end
end

// -------------------------- 3. MA时钟生成（50%占空比） --------------------------
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        ma_div_cnt <= 16'd0;
        ma_clk     <= 1'b1;  // IDLE时MA默认高电平
    end else begin
        if (ma_div_cnt == ma_div - 1) begin
            ma_div_cnt <= 16'd0;
            ma_clk     <= ~ma_clk;  // 分频翻转，生成50%占空比
        end else begin
            ma_div_cnt <= ma_div_cnt + 16'd1;
        end
    end
end

// -------------------------- 4. SL信号同步与ACK检测 --------------------------
// 4.1 SL两级同步（消除亚稳态，适配跨时钟域）
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        sl_sync <= 2'b11;  // IDLE时SL默认高电平
    end else begin
        sl_sync <= {sl_sync[0], sl_in};  // 同步到系统时钟域
    end
end

// 4.2 检测SL下降沿（从机ACK应答：收到MA后拉低SL）
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        sl_ack_det <= 1'b0;
    end else begin
        sl_ack_det <= (sl_sync[1] == 1'b1) && (sl_sync[0] == 1'b0);  // 前高后低=下降沿
    end
end

// -------------------------- 5. 通信状态机（主机核心控制逻辑） --------------------------
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        curr_state   <= ST_IDLE;
        ma_out       <= 1'b1;
        scd_rx_cnt   <= 8'd0;
        scd_shift_reg<= 64'd0;
        crc_reg      <= 16'hffff;  // CRC初始值（BISS协议默认全1）
        crc_calc_en  <= 1'b0;
        timeout_cnt  <= 16'd0;
        pos_data     <= {POS_DATA_WIDTH{1'b0}};
        error_flag   <= 1'b0;
        warn_flag    <= 1'b0;
        crc_err      <= 1'b0;
        timeout_err  <= 1'b0;
        data_valid   <= 1'b0;
    end else begin
        case (curr_state)
            // 状态1：IDLE（空闲）→ 收到start信号进入START阶段
            ST_IDLE: begin
                ma_out       <= 1'b1;  // IDLE时MA高电平
                scd_rx_cnt   <= 8'd0;
                crc_reg      <= 16'hffff;
                crc_calc_en  <= 1'b0;
                timeout_cnt  <= 16'd0;
                timeout_err  <= 1'b0;
                crc_err      <= 1'b0;
                data_valid   <= 1'b0;

                if (biss_start) begin  // 外部触发通信
                    curr_state <= ST_START;
                end else begin
                    curr_state <= ST_IDLE;
                end
            end

            // 状态2：START阶段（输出2个MA脉冲，触发从机锁存数据）
            ST_START: begin
                ma_out <= ma_clk;  // 输出MA时钟
                timeout_cnt <= timeout_cnt + 16'd1;

                // 超时判断：超过阈值未完成2个脉冲，报超时
                if (timeout_cnt >= TIMEOUT_MAX) begin
                    timeout_err <= 1'b1;
                    curr_state <= ST_IDLE;
                end
                // 检测MA上升沿，计数2个脉冲后进入TRANSMIT
                else if (ma_clk && (ma_div_cnt == ma_div - 1)) begin  // MA上升沿（分频计数器满）
                    scd_rx_cnt <= scd_rx_cnt + 8'd1;
                    if (scd_rx_cnt >= 2'd1) begin  // 已输出2个脉冲（0→1计数满）
                        curr_state <= ST_TRANSMIT;
                        scd_rx_cnt <= 8'd0;  // 重置SCD接收计数
                        timeout_cnt <= 16'd0;
                    end
                end
            end

            // 状态3：TRANSMIT阶段（MA持续脉冲，同步接收SCD数据）
            ST_TRANSMIT: begin
                ma_out <= ma_clk;  // 输出MA时钟
                crc_calc_en <= 1'b1;  // 使能CRC计算
                timeout_cnt <= timeout_cnt + 16'd1;

                // 超时判断：接收SCD超时
                if (timeout_cnt >= TIMEOUT_MAX) begin
                    timeout_err <= 1'b1;
                    curr_state <= ST_IDLE;
                end
                // MA上升沿：锁存SL数据到SCD移位寄存器
                else if (ma_clk && (ma_div_cnt == ma_div - 1)) begin
                    scd_shift_reg <= {scd_shift_reg[62:0], sl_sync[0]};  // 左移，MSB在前
                    scd_rx_cnt <= scd_rx_cnt + 8'd1;

                    // 接收完所有SCD位，进入Timeout阶段
                    if (scd_rx_cnt >= cfg_scd_width - 1) begin  // 计数从0开始，满width-1即完成
                        curr_state <= ST_TIMEOUT;
                        crc_calc_en <= 1'b0;  // 停止CRC计算
                        timeout_cnt <= 16'd0;
                    end
                end
            end

            // 状态4：Timeout阶段（MA复用为CDM，解析数据+校验）
            ST_TIMEOUT: begin
                // MA复用为CDM：cfg_cdm_bit=0→高，1→低
                ma_out <= (cfg_cdm_bit == 1'b0) ? 1'b1 : 1'b0;
                timeout_cnt <= timeout_cnt + 16'd1;

                // 超时判断：Timeout阶段超时
                if (timeout_cnt >= TIMEOUT_MAX) begin
                    timeout_err <= 1'b1;
                    curr_state <= ST_IDLE;
                end
                // 从机应答完成（SL拉高），解析SCD数据
                else if (sl_sync[0] == 1'b1) begin
                    // 解析SCD字段（通用格式：位置+Error+Warn+CRC，需与编码器匹配）
                    // 示例：SCD = [位置位(cfg_scd_width - cfg_crc_width - 2):0] + Warn(1) + Error(1) + CRC(cfg_crc_width)
                    if (cfg_crc_width == 4'd6) begin
                        pos_data   <= scd_shift_reg[cfg_scd_width - 1 : 6 + 2];  // 位置数据
                        error_flag <= scd_shift_reg[6 + 1];  // Error位（CRC前1位）
                        warn_flag  <= scd_shift_reg[6];       // Warn位（CRC前2位）
                    end else if (cfg_crc_width == 4'd16) begin
                        pos_data   <= scd_shift_reg[cfg_scd_width - 1 : 16 + 2];
                        error_flag <= scd_shift_reg[16 + 1];
                        warn_flag  <= scd_shift_reg[16];
                    end else begin
                        pos_data   <= {POS_DATA_WIDTH{1'b0}};
                        error_flag <= 1'b0;
                        warn_flag  <= 1'b0;
                    end

                    // CRC校验：结果为0则通过
                    crc_err <= (cfg_crc_width == 4'd6) ? (crc_reg[5:0] != 6'd0) : 
                                                       (crc_reg != 16'd0);

                    // 数据有效：无超时+无CRC错误
                    data_valid <= (timeout_err == 1'b0) && (crc_err == 1'b0) ? 1'b1 : 1'b0;

                    // 回到IDLE，等待下一次通信
                    curr_state <= ST_IDLE;
                end
            end

            default: curr_state <= ST_IDLE;
        endcase
    end
end

// -------------------------- 6. CRC校验模块（可配置6/16位） --------------------------
always @(posedge clk_sys or negedge rst_n) begin
    if (!rst_n) begin
        crc_reg <= 16'hffff;  // 初始值全1（BISS协议规定）
    end else if (crc_calc_en && ma_clk && (ma_div_cnt == ma_div - 1)) begin  // MA上升沿更新CRC
        if (cfg_crc_width == 4'd6) begin  // 6位CRC计算
            reg crc_xor;
            crc_xor = crc_reg[5] ^ sl_sync[0];  // 最高位与当前数据异或
            crc_reg[5:0] = {crc_reg[4:0], 1'b0} ^ (crc_xor ? cfg_crc_poly[5:0] : 6'b0);
            crc_reg[15:6] = 10'd0;  // 高10位无效
        end else if (cfg_crc_width == 4'd16) begin  // 16位CRC计算
            reg crc_xor;
            crc_xor = crc_reg[15] ^ sl_sync[0];
            crc_reg = {crc_reg[14:0], 1'b0} ^ (crc_xor ? cfg_crc_poly : 16'b0);
        end
    end
end

endmodule