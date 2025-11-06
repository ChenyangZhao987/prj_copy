`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 11:34:47
// Design Name: zcy
// Module Name: time_base_gen
// Project Name: XDMA_PCIe
// Target Devices: 
// Tool Versions: 
// Description: 参数化设计的CRC计算
//
//
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
module CRC_calculator #(
    parameter 	CRC_WIDTH    = 6,        // CRC校验位宽度（默认6位）
				DATA_WIDTH   = 18,       // 输入数据宽度（默认18位）
				POLYNOMIAL   = 6'b000011,// 多项式（CRC_WIDTH位，默认0x03）
				INIT_VALUE   = 6'b000000,// 初始值（CRC_WIDTH位，默认0x00）
				REFIN        = 1'b0,     // 输入是否反转（0=不反转，1=反转）
				REFOUT       = 1'b0      // 输出是否反转（0=不反转，1=反转）
)(
    input      [DATA_WIDTH-1:0]	data_in,  // 输入数据
    output reg [CRC_WIDTH-1:0] 	crc_out   // CRC输出（组合逻辑输出）
);

// wire		[DATA_WIDTH-1:0]		data_reg;
// assign data_reg = data_in[DATA_WIDTH-1:0];
/*******************************************************************************
// 		输入数据反转函数（根据REFIN参数选择是否反转）
*******************************************************************************/
function [DATA_WIDTH-1:0] reverse_input;
    input [DATA_WIDTH-1:0] data;
    integer i;
    begin
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            reverse_input[i] = data[DATA_WIDTH - 1 - i];
        end
    end
endfunction
/*******************************************************************************
// 		输出CRC反转函数（根据REFOUT参数选择是否反转）
*******************************************************************************/
function [CRC_WIDTH-1:0] reverse_output;
	input [CRC_WIDTH-1:0] crc;
	integer i;
	begin
		for (i = 0; i < CRC_WIDTH; i = i + 1) begin
			reverse_output[i] = crc[CRC_WIDTH - 1 - i];
		end
	end
endfunction

/*******************************************************************************
// 				CRC计算（核心）
*******************************************************************************/

    // 中间变量：处理后的输入数据（考虑REFIN）
(* MARK_DEBUG="true" *)wire [DATA_WIDTH-1:0] data_processed = REFIN ? reverse_input(data_in) : data_in;

    // 组合逻辑计算CRC（核心）
    reg [CRC_WIDTH-1:0] crc_reg;  // 组合逻辑内部寄存器（非时序寄存器）
    integer i;  // 循环变量
	reg current_bit;
    always @(*) begin
        crc_reg = INIT_VALUE;  // 初始化CRC寄存器（与原模块初始值一致）
        // 一次性处理所有输入位（替代时序逻辑的逐位移位）
        for (i = 0; i < DATA_WIDTH; i = i + 1) begin
            // 提取当前处理的位（与原时序逻辑的移位顺序一致）
            // 原时序逻辑中，数据左移，第i次处理的是data_processed[DATA_WIDTH-1 - i]
            current_bit = data_processed[DATA_WIDTH - 1 - i];
            
            // CRC计算核心：左移1位，最高位与当前数据位异或，若结果为1则与多项式异或
            crc_reg = {crc_reg[CRC_WIDTH-2:0], 1'b0} ^ 
                      ( ({CRC_WIDTH{(crc_reg[CRC_WIDTH-1] ^ current_bit)}}) & POLYNOMIAL );
        end
        // 输出处理（考虑REFOUT）
        crc_out = REFOUT ? reverse_output(crc_reg) : crc_reg;
    end

endmodule