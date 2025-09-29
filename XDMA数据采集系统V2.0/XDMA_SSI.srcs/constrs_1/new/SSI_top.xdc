
create_clock -period 10.000 -name sys_clk [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS15} [get_ports Led0]
set_property PACKAGE_PIN Y24 [get_ports Pcie_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports Pcie_rstn]
set_property PULLUP true [get_ports Pcie_rstn]
set_property PACKAGE_PIN U8 [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports Ssclk]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports Ssda]
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports Cs_n]


#set_property PACKAGE_PIN W2   [get_ports { Pcie_txp[0] }];
#set_property PACKAGE_PIN AA2  [get_ports { Pcie_txp[1] }];
#set_property PACKAGE_PIN AC2  [get_ports { Pcie_txp[2] }];
#set_property PACKAGE_PIN AE2  [get_ports { Pcie_txp[3] }];
#set_property PACKAGE_PIN AG2  [get_ports { Pcie_txp[4] }];
#set_property PACKAGE_PIN AH4  [get_ports { Pcie_txp[5] }];
#set_property PACKAGE_PIN AJ2  [get_ports { Pcie_txp[6] }];
#set_property PACKAGE_PIN AK4  [get_ports { Pcie_txp[7] }];

#set_property PACKAGE_PIN Y4   [get_ports { Pcie_rxn[0] }];
#set_property PACKAGE_PIN AA6  [get_ports { Pcie_rxn[1] }];
#set_property PACKAGE_PIN AB4  [get_ports { Pcie_rxn[2] }];
#set_property PACKAGE_PIN AC6  [get_ports { Pcie_rxn[3] }];
#set_property PACKAGE_PIN AD4  [get_ports { Pcie_rxn[4] }];
#set_property PACKAGE_PIN AE6  [get_ports { Pcie_rxn[5] }];
#set_property PACKAGE_PIN AF4  [get_ports { Pcie_rxn[6] }];
#set_property PACKAGE_PIN AG6  [get_ports { Pcie_rxn[7] }];

set_property BITSTREAM.STARTUP.DONEPIPE YES [current_design]
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

#write_cfgmem  -format mcs -size 32 -interface SPIx4 -loadbit {up 0x00000000 "../../..//PCIeXDMA.runs/impl_1/fpga_top.bit" } -file "../../..//PCIeXDMA.runs/impl_1//fpga_top"





connect_debug_port u_ila_0/clk [get_nets [list nolabel_line294/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]


connect_debug_port u_ila_0/clk [get_nets [list nolabel_line297/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]

connect_debug_port u_ila_0/clk [get_nets [list nolabel_line302/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]

connect_debug_port u_ila_0/clk [get_nets [list nolabel_line295/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]
connect_debug_port u_ila_0/probe4 [get_nets [list {cct[0]} {cct[1]} {cct[2]} {cct[3]} {cct[4]} {cct[5]}]]

connect_debug_port u_ila_0/clk [get_nets [list nolabel_line298/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]





connect_debug_port u_ila_0/clk [get_nets [list nolabel_line304/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/userclk1_i1.usrclk1_i1_0]]
connect_debug_port u_ila_0/probe20 [get_nets [list clear_int_en0]]
connect_debug_port u_ila_0/probe21 [get_nets [list clear_int_en1]]

connect_debug_port u_ila_1/clk [get_nets [list nolabel_line267/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1_0]]
connect_debug_port u_ila_1/probe6 [get_nets [list {irq_ack0[0]} {irq_ack0[1]} {irq_ack0[2]}]]
connect_debug_port u_ila_1/probe18 [get_nets [list {irq_ack1[0]} {irq_ack1[1]} {irq_ack1[2]}]]
connect_debug_port u_ila_1/probe19 [get_nets [list {usr_irq_req[0]} {usr_irq_req[1]}]]
connect_debug_port u_ila_1/probe21 [get_nets [list {usr_irq_ack[0]} {usr_irq_ack[1]}]]


connect_debug_port u_ila_0/clk [get_nets [list nolabel_line271/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1_0]]



connect_debug_port u_ila_0/clk [get_nets [list nolabel_line273/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1_0]]
connect_debug_port u_ila_0/probe35 [get_nets [list nolabel_line83/stat_data]]
connect_debug_port u_ila_0/probe36 [get_nets [list nolabel_line83/stop_data]]

connect_debug_port u_ila_0/clk [get_nets [list nolabel_line278/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1_0]]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list bram_clk_b]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 3 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {addr_b[0]} {addr_b[1]} {addr_b[2]}]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list nolabel_line276/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1_0]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 21 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {SSI_interface_ins/nop_cnt[0]} {SSI_interface_ins/nop_cnt[1]} {SSI_interface_ins/nop_cnt[2]} {SSI_interface_ins/nop_cnt[3]} {SSI_interface_ins/nop_cnt[4]} {SSI_interface_ins/nop_cnt[5]} {SSI_interface_ins/nop_cnt[6]} {SSI_interface_ins/nop_cnt[7]} {SSI_interface_ins/nop_cnt[8]} {SSI_interface_ins/nop_cnt[9]} {SSI_interface_ins/nop_cnt[10]} {SSI_interface_ins/nop_cnt[11]} {SSI_interface_ins/nop_cnt[12]} {SSI_interface_ins/nop_cnt[13]} {SSI_interface_ins/nop_cnt[14]} {SSI_interface_ins/nop_cnt[15]} {SSI_interface_ins/nop_cnt[16]} {SSI_interface_ins/nop_cnt[17]} {SSI_interface_ins/nop_cnt[18]} {SSI_interface_ins/nop_cnt[19]} {SSI_interface_ins/nop_cnt[20]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 6 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {SSI_interface_ins/bit_cnt[0]} {SSI_interface_ins/bit_cnt[1]} {SSI_interface_ins/bit_cnt[2]} {SSI_interface_ins/bit_cnt[3]} {SSI_interface_ins/bit_cnt[4]} {SSI_interface_ins/bit_cnt[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 16 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {SSI_interface_ins/rate_cnt[0]} {SSI_interface_ins/rate_cnt[1]} {SSI_interface_ins/rate_cnt[2]} {SSI_interface_ins/rate_cnt[3]} {SSI_interface_ins/rate_cnt[4]} {SSI_interface_ins/rate_cnt[5]} {SSI_interface_ins/rate_cnt[6]} {SSI_interface_ins/rate_cnt[7]} {SSI_interface_ins/rate_cnt[8]} {SSI_interface_ins/rate_cnt[9]} {SSI_interface_ins/rate_cnt[10]} {SSI_interface_ins/rate_cnt[11]} {SSI_interface_ins/rate_cnt[12]} {SSI_interface_ins/rate_cnt[13]} {SSI_interface_ins/rate_cnt[14]} {SSI_interface_ins/rate_cnt[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 16 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {SSI_interface_ins/rev_cnt[0]} {SSI_interface_ins/rev_cnt[1]} {SSI_interface_ins/rev_cnt[2]} {SSI_interface_ins/rev_cnt[3]} {SSI_interface_ins/rev_cnt[4]} {SSI_interface_ins/rev_cnt[5]} {SSI_interface_ins/rev_cnt[6]} {SSI_interface_ins/rev_cnt[7]} {SSI_interface_ins/rev_cnt[8]} {SSI_interface_ins/rev_cnt[9]} {SSI_interface_ins/rev_cnt[10]} {SSI_interface_ins/rev_cnt[11]} {SSI_interface_ins/rev_cnt[12]} {SSI_interface_ins/rev_cnt[13]} {SSI_interface_ins/rev_cnt[14]} {SSI_interface_ins/rev_cnt[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 13 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {SSI_interface_ins/scl_cnt[0]} {SSI_interface_ins/scl_cnt[1]} {SSI_interface_ins/scl_cnt[2]} {SSI_interface_ins/scl_cnt[3]} {SSI_interface_ins/scl_cnt[4]} {SSI_interface_ins/scl_cnt[5]} {SSI_interface_ins/scl_cnt[6]} {SSI_interface_ins/scl_cnt[7]} {SSI_interface_ins/scl_cnt[8]} {SSI_interface_ins/scl_cnt[9]} {SSI_interface_ins/scl_cnt[10]} {SSI_interface_ins/scl_cnt[11]} {SSI_interface_ins/scl_cnt[12]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 3 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {SSI_interface_ins/rx_state[0]} {SSI_interface_ins/rx_state[1]} {SSI_interface_ins/rx_state[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 9 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list {addr_b[3]} {addr_b[4]} {addr_b[5]} {addr_b[6]} {addr_b[7]} {addr_b[8]} {addr_b[9]} {addr_b[10]} {addr_b[11]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 64 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list {dout_b[0]} {dout_b[1]} {dout_b[2]} {dout_b[3]} {dout_b[4]} {dout_b[5]} {dout_b[6]} {dout_b[7]} {dout_b[8]} {dout_b[9]} {dout_b[10]} {dout_b[11]} {dout_b[12]} {dout_b[13]} {dout_b[14]} {dout_b[15]} {dout_b[16]} {dout_b[17]} {dout_b[18]} {dout_b[19]} {dout_b[20]} {dout_b[21]} {dout_b[22]} {dout_b[23]} {dout_b[24]} {dout_b[25]} {dout_b[26]} {dout_b[27]} {dout_b[28]} {dout_b[29]} {dout_b[30]} {dout_b[31]} {dout_b[32]} {dout_b[33]} {dout_b[34]} {dout_b[35]} {dout_b[36]} {dout_b[37]} {dout_b[38]} {dout_b[39]} {dout_b[40]} {dout_b[41]} {dout_b[42]} {dout_b[43]} {dout_b[44]} {dout_b[45]} {dout_b[46]} {dout_b[47]} {dout_b[48]} {dout_b[49]} {dout_b[50]} {dout_b[51]} {dout_b[52]} {dout_b[53]} {dout_b[54]} {dout_b[55]} {dout_b[56]} {dout_b[57]} {dout_b[58]} {dout_b[59]} {dout_b[60]} {dout_b[61]} {dout_b[62]} {dout_b[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 3 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list {irq_ack[0]} {irq_ack[1]} {irq_ack[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 8 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list {wen_b[0]} {wen_b[1]} {wen_b[2]} {wen_b[3]} {wen_b[4]} {wen_b[5]} {wen_b[6]} {wen_b[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 8 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list {wen_s[0]} {wen_s[1]} {wen_s[2]} {wen_s[3]} {wen_s[4]} {wen_s[5]} {wen_s[6]} {wen_s[7]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 64 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list {din_reg[0]} {din_reg[1]} {din_reg[2]} {din_reg[3]} {din_reg[4]} {din_reg[5]} {din_reg[6]} {din_reg[7]} {din_reg[8]} {din_reg[9]} {din_reg[10]} {din_reg[11]} {din_reg[12]} {din_reg[13]} {din_reg[14]} {din_reg[15]} {din_reg[16]} {din_reg[17]} {din_reg[18]} {din_reg[19]} {din_reg[20]} {din_reg[21]} {din_reg[22]} {din_reg[23]} {din_reg[24]} {din_reg[25]} {din_reg[26]} {din_reg[27]} {din_reg[28]} {din_reg[29]} {din_reg[30]} {din_reg[31]} {din_reg[32]} {din_reg[33]} {din_reg[34]} {din_reg[35]} {din_reg[36]} {din_reg[37]} {din_reg[38]} {din_reg[39]} {din_reg[40]} {din_reg[41]} {din_reg[42]} {din_reg[43]} {din_reg[44]} {din_reg[45]} {din_reg[46]} {din_reg[47]} {din_reg[48]} {din_reg[49]} {din_reg[50]} {din_reg[51]} {din_reg[52]} {din_reg[53]} {din_reg[54]} {din_reg[55]} {din_reg[56]} {din_reg[57]} {din_reg[58]} {din_reg[59]} {din_reg[60]} {din_reg[61]} {din_reg[62]} {din_reg[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 64 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list {din_s[0]} {din_s[1]} {din_s[2]} {din_s[3]} {din_s[4]} {din_s[5]} {din_s[6]} {din_s[7]} {din_s[8]} {din_s[9]} {din_s[10]} {din_s[11]} {din_s[12]} {din_s[13]} {din_s[14]} {din_s[15]} {din_s[16]} {din_s[17]} {din_s[18]} {din_s[19]} {din_s[20]} {din_s[21]} {din_s[22]} {din_s[23]} {din_s[24]} {din_s[25]} {din_s[26]} {din_s[27]} {din_s[28]} {din_s[29]} {din_s[30]} {din_s[31]} {din_s[32]} {din_s[33]} {din_s[34]} {din_s[35]} {din_s[36]} {din_s[37]} {din_s[38]} {din_s[39]} {din_s[40]} {din_s[41]} {din_s[42]} {din_s[43]} {din_s[44]} {din_s[45]} {din_s[46]} {din_s[47]} {din_s[48]} {din_s[49]} {din_s[50]} {din_s[51]} {din_s[52]} {din_s[53]} {din_s[54]} {din_s[55]} {din_s[56]} {din_s[57]} {din_s[58]} {din_s[59]} {din_s[60]} {din_s[61]} {din_s[62]} {din_s[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 3 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list {irq_state1[0]} {irq_state1[1]} {irq_state1[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe14]
set_property port_width 24 [get_debug_ports u_ila_1/probe14]
connect_debug_port u_ila_1/probe14 [get_nets [list {data_out[0]} {data_out[1]} {data_out[2]} {data_out[3]} {data_out[4]} {data_out[5]} {data_out[6]} {data_out[7]} {data_out[8]} {data_out[9]} {data_out[10]} {data_out[11]} {data_out[12]} {data_out[13]} {data_out[14]} {data_out[15]} {data_out[16]} {data_out[17]} {data_out[18]} {data_out[19]} {data_out[20]} {data_out[21]} {data_out[22]} {data_out[23]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe15]
set_property port_width 4 [get_debug_ports u_ila_1/probe15]
connect_debug_port u_ila_1/probe15 [get_nets [list {reg_cnt[0]} {reg_cnt[1]} {reg_cnt[2]} {reg_cnt[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe16]
set_property port_width 64 [get_debug_ports u_ila_1/probe16]
connect_debug_port u_ila_1/probe16 [get_nets [list {din_b[0]} {din_b[1]} {din_b[2]} {din_b[3]} {din_b[4]} {din_b[5]} {din_b[6]} {din_b[7]} {din_b[8]} {din_b[9]} {din_b[10]} {din_b[11]} {din_b[12]} {din_b[13]} {din_b[14]} {din_b[15]} {din_b[16]} {din_b[17]} {din_b[18]} {din_b[19]} {din_b[20]} {din_b[21]} {din_b[22]} {din_b[23]} {din_b[24]} {din_b[25]} {din_b[26]} {din_b[27]} {din_b[28]} {din_b[29]} {din_b[30]} {din_b[31]} {din_b[32]} {din_b[33]} {din_b[34]} {din_b[35]} {din_b[36]} {din_b[37]} {din_b[38]} {din_b[39]} {din_b[40]} {din_b[41]} {din_b[42]} {din_b[43]} {din_b[44]} {din_b[45]} {din_b[46]} {din_b[47]} {din_b[48]} {din_b[49]} {din_b[50]} {din_b[51]} {din_b[52]} {din_b[53]} {din_b[54]} {din_b[55]} {din_b[56]} {din_b[57]} {din_b[58]} {din_b[59]} {din_b[60]} {din_b[61]} {din_b[62]} {din_b[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe17]
set_property port_width 29 [get_debug_ports u_ila_1/probe17]
connect_debug_port u_ila_1/probe17 [get_nets [list {addr_s[0]} {addr_s[1]} {addr_s[2]} {addr_s[3]} {addr_s[4]} {addr_s[5]} {addr_s[6]} {addr_s[7]} {addr_s[8]} {addr_s[9]} {addr_s[10]} {addr_s[11]} {addr_s[12]} {addr_s[13]} {addr_s[14]} {addr_s[15]} {addr_s[16]} {addr_s[17]} {addr_s[18]} {addr_s[19]} {addr_s[20]} {addr_s[21]} {addr_s[22]} {addr_s[23]} {addr_s[24]} {addr_s[25]} {addr_s[26]} {addr_s[27]} {addr_s[28]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe18]
set_property port_width 3 [get_debug_ports u_ila_1/probe18]
connect_debug_port u_ila_1/probe18 [get_nets [list {irq_state0[0]} {irq_state0[1]} {irq_state0[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe19]
set_property port_width 3 [get_debug_ports u_ila_1/probe19]
connect_debug_port u_ila_1/probe19 [get_nets [list {single_sample[0]} {single_sample[1]} {single_sample[2]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe20]
set_property port_width 64 [get_debug_ports u_ila_1/probe20]
connect_debug_port u_ila_1/probe20 [get_nets [list {dout_s[0]} {dout_s[1]} {dout_s[2]} {dout_s[3]} {dout_s[4]} {dout_s[5]} {dout_s[6]} {dout_s[7]} {dout_s[8]} {dout_s[9]} {dout_s[10]} {dout_s[11]} {dout_s[12]} {dout_s[13]} {dout_s[14]} {dout_s[15]} {dout_s[16]} {dout_s[17]} {dout_s[18]} {dout_s[19]} {dout_s[20]} {dout_s[21]} {dout_s[22]} {dout_s[23]} {dout_s[24]} {dout_s[25]} {dout_s[26]} {dout_s[27]} {dout_s[28]} {dout_s[29]} {dout_s[30]} {dout_s[31]} {dout_s[32]} {dout_s[33]} {dout_s[34]} {dout_s[35]} {dout_s[36]} {dout_s[37]} {dout_s[38]} {dout_s[39]} {dout_s[40]} {dout_s[41]} {dout_s[42]} {dout_s[43]} {dout_s[44]} {dout_s[45]} {dout_s[46]} {dout_s[47]} {dout_s[48]} {dout_s[49]} {dout_s[50]} {dout_s[51]} {dout_s[52]} {dout_s[53]} {dout_s[54]} {dout_s[55]} {dout_s[56]} {dout_s[57]} {dout_s[58]} {dout_s[59]} {dout_s[60]} {dout_s[61]} {dout_s[62]} {dout_s[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe21]
set_property port_width 32 [get_debug_ports u_ila_1/probe21]
connect_debug_port u_ila_1/probe21 [get_nets [list {data_all[0]} {data_all[1]} {data_all[2]} {data_all[3]} {data_all[4]} {data_all[5]} {data_all[6]} {data_all[7]} {data_all[8]} {data_all[9]} {data_all[10]} {data_all[11]} {data_all[12]} {data_all[13]} {data_all[14]} {data_all[15]} {data_all[16]} {data_all[17]} {data_all[18]} {data_all[19]} {data_all[20]} {data_all[21]} {data_all[22]} {data_all[23]} {data_all[24]} {data_all[25]} {data_all[26]} {data_all[27]} {data_all[28]} {data_all[29]} {data_all[30]} {data_all[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe22]
set_property port_width 1 [get_debug_ports u_ila_1/probe22]
connect_debug_port u_ila_1/probe22 [get_nets [list clear_int_en]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe23]
set_property port_width 1 [get_debug_ports u_ila_1/probe23]
connect_debug_port u_ila_1/probe23 [get_nets [list cs_1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe24]
set_property port_width 1 [get_debug_ports u_ila_1/probe24]
connect_debug_port u_ila_1/probe24 [get_nets [list cs_en]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe25]
set_property port_width 1 [get_debug_ports u_ila_1/probe25]
connect_debug_port u_ila_1/probe25 [get_nets [list data_acq_en]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe26]
set_property port_width 1 [get_debug_ports u_ila_1/probe26]
connect_debug_port u_ila_1/probe26 [get_nets [list data_flag]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe27]
set_property port_width 1 [get_debug_ports u_ila_1/probe27]
connect_debug_port u_ila_1/probe27 [get_nets [list en_b]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe28]
set_property port_width 1 [get_debug_ports u_ila_1/probe28]
connect_debug_port u_ila_1/probe28 [get_nets [list en_s]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe29]
set_property port_width 1 [get_debug_ports u_ila_1/probe29]
connect_debug_port u_ila_1/probe29 [get_nets [list en_s1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe30]
set_property port_width 1 [get_debug_ports u_ila_1/probe30]
connect_debug_port u_ila_1/probe30 [get_nets [list ping_pang_sel]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe31]
set_property port_width 1 [get_debug_ports u_ila_1/probe31]
connect_debug_port u_ila_1/probe31 [get_nets [list r_rst]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe32]
set_property port_width 1 [get_debug_ports u_ila_1/probe32]
connect_debug_port u_ila_1/probe32 [get_nets [list req_0]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe33]
set_property port_width 1 [get_debug_ports u_ila_1/probe33]
connect_debug_port u_ila_1/probe33 [get_nets [list req_1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe34]
set_property port_width 1 [get_debug_ports u_ila_1/probe34]
connect_debug_port u_ila_1/probe34 [get_nets [list sclk1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe35]
set_property port_width 1 [get_debug_ports u_ila_1/probe35]
connect_debug_port u_ila_1/probe35 [get_nets [list sda1]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe36]
set_property port_width 1 [get_debug_ports u_ila_1/probe36]
connect_debug_port u_ila_1/probe36 [get_nets [list Sda_ctrl]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe37]
set_property port_width 1 [get_debug_ports u_ila_1/probe37]
connect_debug_port u_ila_1/probe37 [get_nets [list nolabel_line85/stat_cs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe38]
set_property port_width 1 [get_debug_ports u_ila_1/probe38]
connect_debug_port u_ila_1/probe38 [get_nets [list nolabel_line85/stat_data]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe39]
set_property port_width 1 [get_debug_ports u_ila_1/probe39]
connect_debug_port u_ila_1/probe39 [get_nets [list nolabel_line85/stat_scl]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe40]
set_property port_width 1 [get_debug_ports u_ila_1/probe40]
connect_debug_port u_ila_1/probe40 [get_nets [list nolabel_line85/stop_cs]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe41]
set_property port_width 1 [get_debug_ports u_ila_1/probe41]
connect_debug_port u_ila_1/probe41 [get_nets [list nolabel_line85/stop_data]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe42]
set_property port_width 1 [get_debug_ports u_ila_1/probe42]
connect_debug_port u_ila_1/probe42 [get_nets [list nolabel_line85/stop_scl]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe43]
set_property port_width 1 [get_debug_ports u_ila_1/probe43]
connect_debug_port u_ila_1/probe43 [get_nets [list usr_irq_ack]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe44]
set_property port_width 1 [get_debug_ports u_ila_1/probe44]
connect_debug_port u_ila_1/probe44 [get_nets [list usr_irq_req]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets bram_clk_b]
