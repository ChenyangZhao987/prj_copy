`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/09/12 11:34:47
// Design Name: 
// Module Name: fpga_top
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


module fpga_top (
    output wire       o_led0,
    input  wire       i_pcie_rstn,
    input  wire       i_pcie_refclkp, i_pcie_refclkn,
    input  wire [0:0] i_pcie_rxp, i_pcie_rxn,
    output wire [0:0] o_pcie_txp, o_pcie_txn
);
    
wire  pcie_rstn;
wire  pcie_refclk;

// Ref clock input buffer ----------------------------------------------
IBUFDS_GTE2 refclk_ibuf (
    .CEB             ( 1'b0              ),
    .I               ( i_pcie_refclkp    ),
    .IB              ( i_pcie_refclkn    ),
    .O               ( pcie_refclk       ),
    .ODIV2           (                   )
);

// Reset input buffer ----------------------------------------------
IBUF   sys_reset_n_ibuf (
    .I               ( i_pcie_rstn       ),
    .O               ( pcie_rstn         )
);

// block design's top (the HDL wrapper) ----------------------------------------------
xdma_bram_wrapper xdma_bram_wrapper_i (
    .pcie_mgt_0_rxn  ( i_pcie_rxn        ),
    .pcie_mgt_0_rxp  ( i_pcie_rxp        ),
    .pcie_mgt_0_txn  ( o_pcie_txn        ),
    .pcie_mgt_0_txp  ( o_pcie_txp        ),
    .sys_clk_0       ( pcie_refclk       ),
    .sys_rst_n_0     ( pcie_rstn         ),
    .user_lnk_up_0   ( o_led0            )
);

endmodule