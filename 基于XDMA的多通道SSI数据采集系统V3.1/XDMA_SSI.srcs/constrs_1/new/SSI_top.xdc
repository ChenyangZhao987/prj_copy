
create_clock -period 10.000 -name sys_clk [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS15} [get_ports Led0]
set_property PACKAGE_PIN Y24 [get_ports Pcie_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports Pcie_rstn]
set_property PULLUP true [get_ports Pcie_rstn]
set_property PACKAGE_PIN U8 [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports {Scl[0]}]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports {Sda[0]}]
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports {Cs_n[0]}]

set_property -dict {PACKAGE_PIN P29 IOSTANDARD LVCMOS33} [get_ports {Scl[1]}]
set_property -dict {PACKAGE_PIN R30 IOSTANDARD LVCMOS33} [get_ports {Sda[1]}]
set_property -dict {PACKAGE_PIN T30 IOSTANDARD LVCMOS33} [get_ports {Cs_n[1]}]

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

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list bram_clk_b]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {addr_b[0]} {addr_b[1]} {addr_b[2]} {addr_b[3]}]]
create_debug_core u_ila_1 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_1]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_1]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_1]
set_property C_DATA_DEPTH 8192 [get_debug_cores u_ila_1]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_1]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_1]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_1]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_1]
set_property port_width 1 [get_debug_ports u_ila_1/clk]
connect_debug_port u_ila_1/clk [get_nets [list nolabel_line305/XDMA_i/xdma_0/inst/XDMA_xdma_0_0_pcie2_to_pcie3_wrapper_i/pcie2_ip_i/inst/inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/PIPE_USERCLK2]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe0]
set_property port_width 91 [get_debug_ports u_ila_1/probe0]
connect_debug_port u_ila_1/probe0 [get_nets [list {uut/data_processed[0]} {uut/data_processed[1]} {uut/data_processed[2]} {uut/data_processed[3]} {uut/data_processed[4]} {uut/data_processed[5]} {uut/data_processed[6]} {uut/data_processed[7]} {uut/data_processed[8]} {uut/data_processed[9]} {uut/data_processed[10]} {uut/data_processed[11]} {uut/data_processed[12]} {uut/data_processed[13]} {uut/data_processed[14]} {uut/data_processed[15]} {uut/data_processed[16]} {uut/data_processed[17]} {uut/data_processed[18]} {uut/data_processed[19]} {uut/data_processed[20]} {uut/data_processed[21]} {uut/data_processed[22]} {uut/data_processed[23]} {uut/data_processed[24]} {uut/data_processed[25]} {uut/data_processed[26]} {uut/data_processed[27]} {uut/data_processed[28]} {uut/data_processed[29]} {uut/data_processed[30]} {uut/data_processed[31]} {uut/data_processed[32]} {uut/data_processed[33]} {uut/data_processed[34]} {uut/data_processed[35]} {uut/data_processed[36]} {uut/data_processed[37]} {uut/data_processed[38]} {uut/data_processed[39]} {uut/data_processed[40]} {uut/data_processed[41]} {uut/data_processed[42]} {uut/data_processed[43]} {uut/data_processed[44]} {uut/data_processed[45]} {uut/data_processed[46]} {uut/data_processed[47]} {uut/data_processed[48]} {uut/data_processed[49]} {uut/data_processed[50]} {uut/data_processed[51]} {uut/data_processed[52]} {uut/data_processed[53]} {uut/data_processed[54]} {uut/data_processed[55]} {uut/data_processed[56]} {uut/data_processed[57]} {uut/data_processed[58]} {uut/data_processed[59]} {uut/data_processed[60]} {uut/data_processed[61]} {uut/data_processed[62]} {uut/data_processed[63]} {uut/data_processed[64]} {uut/data_processed[65]} {uut/data_processed[66]} {uut/data_processed[67]} {uut/data_processed[68]} {uut/data_processed[69]} {uut/data_processed[70]} {uut/data_processed[71]} {uut/data_processed[72]} {uut/data_processed[73]} {uut/data_processed[74]} {uut/data_processed[75]} {uut/data_processed[76]} {uut/data_processed[77]} {uut/data_processed[78]} {uut/data_processed[79]} {uut/data_processed[80]} {uut/data_processed[81]} {uut/data_processed[82]} {uut/data_processed[83]} {uut/data_processed[84]} {uut/data_processed[85]} {uut/data_processed[86]} {uut/data_processed[87]} {uut/data_processed[88]} {uut/data_processed[89]} {uut/data_processed[90]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe1]
set_property port_width 18 [get_debug_ports u_ila_1/probe1]
connect_debug_port u_ila_1/probe1 [get_nets [list {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[0]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[1]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[2]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[3]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[4]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[5]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[6]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[7]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[8]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[9]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[10]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[11]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[12]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[13]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[14]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[15]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[16]} {ssi_channel[1].unipath_data_collection_inst/uut/data_processed[17]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe2]
set_property port_width 64 [get_debug_ports u_ila_1/probe2]
connect_debug_port u_ila_1/probe2 [get_nets [list {ssi_channel[1].unipath_data_collection_inst/data_out[0]} {ssi_channel[1].unipath_data_collection_inst/data_out[1]} {ssi_channel[1].unipath_data_collection_inst/data_out[2]} {ssi_channel[1].unipath_data_collection_inst/data_out[3]} {ssi_channel[1].unipath_data_collection_inst/data_out[4]} {ssi_channel[1].unipath_data_collection_inst/data_out[5]} {ssi_channel[1].unipath_data_collection_inst/data_out[6]} {ssi_channel[1].unipath_data_collection_inst/data_out[7]} {ssi_channel[1].unipath_data_collection_inst/data_out[8]} {ssi_channel[1].unipath_data_collection_inst/data_out[9]} {ssi_channel[1].unipath_data_collection_inst/data_out[10]} {ssi_channel[1].unipath_data_collection_inst/data_out[11]} {ssi_channel[1].unipath_data_collection_inst/data_out[12]} {ssi_channel[1].unipath_data_collection_inst/data_out[13]} {ssi_channel[1].unipath_data_collection_inst/data_out[14]} {ssi_channel[1].unipath_data_collection_inst/data_out[15]} {ssi_channel[1].unipath_data_collection_inst/data_out[16]} {ssi_channel[1].unipath_data_collection_inst/data_out[17]} {ssi_channel[1].unipath_data_collection_inst/data_out[18]} {ssi_channel[1].unipath_data_collection_inst/data_out[19]} {ssi_channel[1].unipath_data_collection_inst/data_out[20]} {ssi_channel[1].unipath_data_collection_inst/data_out[21]} {ssi_channel[1].unipath_data_collection_inst/data_out[22]} {ssi_channel[1].unipath_data_collection_inst/data_out[23]} {ssi_channel[1].unipath_data_collection_inst/data_out[24]} {ssi_channel[1].unipath_data_collection_inst/data_out[25]} {ssi_channel[1].unipath_data_collection_inst/data_out[26]} {ssi_channel[1].unipath_data_collection_inst/data_out[27]} {ssi_channel[1].unipath_data_collection_inst/data_out[28]} {ssi_channel[1].unipath_data_collection_inst/data_out[29]} {ssi_channel[1].unipath_data_collection_inst/data_out[30]} {ssi_channel[1].unipath_data_collection_inst/data_out[31]} {ssi_channel[1].unipath_data_collection_inst/data_out[32]} {ssi_channel[1].unipath_data_collection_inst/data_out[33]} {ssi_channel[1].unipath_data_collection_inst/data_out[34]} {ssi_channel[1].unipath_data_collection_inst/data_out[35]} {ssi_channel[1].unipath_data_collection_inst/data_out[36]} {ssi_channel[1].unipath_data_collection_inst/data_out[37]} {ssi_channel[1].unipath_data_collection_inst/data_out[38]} {ssi_channel[1].unipath_data_collection_inst/data_out[39]} {ssi_channel[1].unipath_data_collection_inst/data_out[40]} {ssi_channel[1].unipath_data_collection_inst/data_out[41]} {ssi_channel[1].unipath_data_collection_inst/data_out[42]} {ssi_channel[1].unipath_data_collection_inst/data_out[43]} {ssi_channel[1].unipath_data_collection_inst/data_out[44]} {ssi_channel[1].unipath_data_collection_inst/data_out[45]} {ssi_channel[1].unipath_data_collection_inst/data_out[46]} {ssi_channel[1].unipath_data_collection_inst/data_out[47]} {ssi_channel[1].unipath_data_collection_inst/data_out[48]} {ssi_channel[1].unipath_data_collection_inst/data_out[49]} {ssi_channel[1].unipath_data_collection_inst/data_out[50]} {ssi_channel[1].unipath_data_collection_inst/data_out[51]} {ssi_channel[1].unipath_data_collection_inst/data_out[52]} {ssi_channel[1].unipath_data_collection_inst/data_out[53]} {ssi_channel[1].unipath_data_collection_inst/data_out[54]} {ssi_channel[1].unipath_data_collection_inst/data_out[55]} {ssi_channel[1].unipath_data_collection_inst/data_out[56]} {ssi_channel[1].unipath_data_collection_inst/data_out[57]} {ssi_channel[1].unipath_data_collection_inst/data_out[58]} {ssi_channel[1].unipath_data_collection_inst/data_out[59]} {ssi_channel[1].unipath_data_collection_inst/data_out[60]} {ssi_channel[1].unipath_data_collection_inst/data_out[61]} {ssi_channel[1].unipath_data_collection_inst/data_out[62]} {ssi_channel[1].unipath_data_collection_inst/data_out[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe3]
set_property port_width 6 [get_debug_ports u_ila_1/probe3]
connect_debug_port u_ila_1/probe3 [get_nets [list {ssi_channel[1].unipath_data_collection_inst/crc_out[0]} {ssi_channel[1].unipath_data_collection_inst/crc_out[1]} {ssi_channel[1].unipath_data_collection_inst/crc_out[2]} {ssi_channel[1].unipath_data_collection_inst/crc_out[3]} {ssi_channel[1].unipath_data_collection_inst/crc_out[4]} {ssi_channel[1].unipath_data_collection_inst/crc_out[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe4]
set_property port_width 18 [get_debug_ports u_ila_1/probe4]
connect_debug_port u_ila_1/probe4 [get_nets [list {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[0]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[1]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[2]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[3]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[4]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[5]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[6]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[7]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[8]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[9]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[10]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[11]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[12]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[13]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[14]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[15]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[16]} {ssi_channel[0].unipath_data_collection_inst/uut/data_processed[17]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe5]
set_property port_width 6 [get_debug_ports u_ila_1/probe5]
connect_debug_port u_ila_1/probe5 [get_nets [list {ssi_channel[0].unipath_data_collection_inst/crc_out[0]} {ssi_channel[0].unipath_data_collection_inst/crc_out[1]} {ssi_channel[0].unipath_data_collection_inst/crc_out[2]} {ssi_channel[0].unipath_data_collection_inst/crc_out[3]} {ssi_channel[0].unipath_data_collection_inst/crc_out[4]} {ssi_channel[0].unipath_data_collection_inst/crc_out[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe6]
set_property port_width 64 [get_debug_ports u_ila_1/probe6]
connect_debug_port u_ila_1/probe6 [get_nets [list {ssi_channel[0].unipath_data_collection_inst/data_out[0]} {ssi_channel[0].unipath_data_collection_inst/data_out[1]} {ssi_channel[0].unipath_data_collection_inst/data_out[2]} {ssi_channel[0].unipath_data_collection_inst/data_out[3]} {ssi_channel[0].unipath_data_collection_inst/data_out[4]} {ssi_channel[0].unipath_data_collection_inst/data_out[5]} {ssi_channel[0].unipath_data_collection_inst/data_out[6]} {ssi_channel[0].unipath_data_collection_inst/data_out[7]} {ssi_channel[0].unipath_data_collection_inst/data_out[8]} {ssi_channel[0].unipath_data_collection_inst/data_out[9]} {ssi_channel[0].unipath_data_collection_inst/data_out[10]} {ssi_channel[0].unipath_data_collection_inst/data_out[11]} {ssi_channel[0].unipath_data_collection_inst/data_out[12]} {ssi_channel[0].unipath_data_collection_inst/data_out[13]} {ssi_channel[0].unipath_data_collection_inst/data_out[14]} {ssi_channel[0].unipath_data_collection_inst/data_out[15]} {ssi_channel[0].unipath_data_collection_inst/data_out[16]} {ssi_channel[0].unipath_data_collection_inst/data_out[17]} {ssi_channel[0].unipath_data_collection_inst/data_out[18]} {ssi_channel[0].unipath_data_collection_inst/data_out[19]} {ssi_channel[0].unipath_data_collection_inst/data_out[20]} {ssi_channel[0].unipath_data_collection_inst/data_out[21]} {ssi_channel[0].unipath_data_collection_inst/data_out[22]} {ssi_channel[0].unipath_data_collection_inst/data_out[23]} {ssi_channel[0].unipath_data_collection_inst/data_out[24]} {ssi_channel[0].unipath_data_collection_inst/data_out[25]} {ssi_channel[0].unipath_data_collection_inst/data_out[26]} {ssi_channel[0].unipath_data_collection_inst/data_out[27]} {ssi_channel[0].unipath_data_collection_inst/data_out[28]} {ssi_channel[0].unipath_data_collection_inst/data_out[29]} {ssi_channel[0].unipath_data_collection_inst/data_out[30]} {ssi_channel[0].unipath_data_collection_inst/data_out[31]} {ssi_channel[0].unipath_data_collection_inst/data_out[32]} {ssi_channel[0].unipath_data_collection_inst/data_out[33]} {ssi_channel[0].unipath_data_collection_inst/data_out[34]} {ssi_channel[0].unipath_data_collection_inst/data_out[35]} {ssi_channel[0].unipath_data_collection_inst/data_out[36]} {ssi_channel[0].unipath_data_collection_inst/data_out[37]} {ssi_channel[0].unipath_data_collection_inst/data_out[38]} {ssi_channel[0].unipath_data_collection_inst/data_out[39]} {ssi_channel[0].unipath_data_collection_inst/data_out[40]} {ssi_channel[0].unipath_data_collection_inst/data_out[41]} {ssi_channel[0].unipath_data_collection_inst/data_out[42]} {ssi_channel[0].unipath_data_collection_inst/data_out[43]} {ssi_channel[0].unipath_data_collection_inst/data_out[44]} {ssi_channel[0].unipath_data_collection_inst/data_out[45]} {ssi_channel[0].unipath_data_collection_inst/data_out[46]} {ssi_channel[0].unipath_data_collection_inst/data_out[47]} {ssi_channel[0].unipath_data_collection_inst/data_out[48]} {ssi_channel[0].unipath_data_collection_inst/data_out[49]} {ssi_channel[0].unipath_data_collection_inst/data_out[50]} {ssi_channel[0].unipath_data_collection_inst/data_out[51]} {ssi_channel[0].unipath_data_collection_inst/data_out[52]} {ssi_channel[0].unipath_data_collection_inst/data_out[53]} {ssi_channel[0].unipath_data_collection_inst/data_out[54]} {ssi_channel[0].unipath_data_collection_inst/data_out[55]} {ssi_channel[0].unipath_data_collection_inst/data_out[56]} {ssi_channel[0].unipath_data_collection_inst/data_out[57]} {ssi_channel[0].unipath_data_collection_inst/data_out[58]} {ssi_channel[0].unipath_data_collection_inst/data_out[59]} {ssi_channel[0].unipath_data_collection_inst/data_out[60]} {ssi_channel[0].unipath_data_collection_inst/data_out[61]} {ssi_channel[0].unipath_data_collection_inst/data_out[62]} {ssi_channel[0].unipath_data_collection_inst/data_out[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe7]
set_property port_width 6 [get_debug_ports u_ila_1/probe7]
connect_debug_port u_ila_1/probe7 [get_nets [list {CRC[0]} {CRC[1]} {CRC[2]} {CRC[3]} {CRC[4]} {CRC[5]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe8]
set_property port_width 32 [get_debug_ports u_ila_1/probe8]
connect_debug_port u_ila_1/probe8 [get_nets [list {addr_s[0]} {addr_s[1]} {addr_s[2]} {addr_s[3]} {addr_s[4]} {addr_s[5]} {addr_s[6]} {addr_s[7]} {addr_s[8]} {addr_s[9]} {addr_s[10]} {addr_s[11]} {addr_s[12]} {addr_s[13]} {addr_s[14]} {addr_s[15]} {addr_s[16]} {addr_s[17]} {addr_s[18]} {addr_s[19]} {addr_s[20]} {addr_s[21]} {addr_s[22]} {addr_s[23]} {addr_s[24]} {addr_s[25]} {addr_s[26]} {addr_s[27]} {addr_s[28]} {addr_s[29]} {addr_s[30]} {addr_s[31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe9]
set_property port_width 64 [get_debug_ports u_ila_1/probe9]
connect_debug_port u_ila_1/probe9 [get_nets [list {befor_data[0]} {befor_data[1]} {befor_data[2]} {befor_data[3]} {befor_data[4]} {befor_data[5]} {befor_data[6]} {befor_data[7]} {befor_data[8]} {befor_data[9]} {befor_data[10]} {befor_data[11]} {befor_data[12]} {befor_data[13]} {befor_data[14]} {befor_data[15]} {befor_data[16]} {befor_data[17]} {befor_data[18]} {befor_data[19]} {befor_data[20]} {befor_data[21]} {befor_data[22]} {befor_data[23]} {befor_data[24]} {befor_data[25]} {befor_data[26]} {befor_data[27]} {befor_data[28]} {befor_data[29]} {befor_data[30]} {befor_data[31]} {befor_data[32]} {befor_data[33]} {befor_data[34]} {befor_data[35]} {befor_data[36]} {befor_data[37]} {befor_data[38]} {befor_data[39]} {befor_data[40]} {befor_data[41]} {befor_data[42]} {befor_data[43]} {befor_data[44]} {befor_data[45]} {befor_data[46]} {befor_data[47]} {befor_data[48]} {befor_data[49]} {befor_data[50]} {befor_data[51]} {befor_data[52]} {befor_data[53]} {befor_data[54]} {befor_data[55]} {befor_data[56]} {befor_data[57]} {befor_data[58]} {befor_data[59]} {befor_data[60]} {befor_data[61]} {befor_data[62]} {befor_data[63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe10]
set_property port_width 9 [get_debug_ports u_ila_1/probe10]
connect_debug_port u_ila_1/probe10 [get_nets [list {addr_b[4]} {addr_b[5]} {addr_b[6]} {addr_b[7]} {addr_b[8]} {addr_b[9]} {addr_b[10]} {addr_b[11]} {addr_b[12]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe11]
set_property port_width 32 [get_debug_ports u_ila_1/probe11]
connect_debug_port u_ila_1/probe11 [get_nets [list {ch_waddr[1][0]} {ch_waddr[1][1]} {ch_waddr[1][2]} {ch_waddr[1][3]} {ch_waddr[1][4]} {ch_waddr[1][5]} {ch_waddr[1][6]} {ch_waddr[1][7]} {ch_waddr[1][8]} {ch_waddr[1][9]} {ch_waddr[1][10]} {ch_waddr[1][11]} {ch_waddr[1][12]} {ch_waddr[1][13]} {ch_waddr[1][14]} {ch_waddr[1][15]} {ch_waddr[1][16]} {ch_waddr[1][17]} {ch_waddr[1][18]} {ch_waddr[1][19]} {ch_waddr[1][20]} {ch_waddr[1][21]} {ch_waddr[1][22]} {ch_waddr[1][23]} {ch_waddr[1][24]} {ch_waddr[1][25]} {ch_waddr[1][26]} {ch_waddr[1][27]} {ch_waddr[1][28]} {ch_waddr[1][29]} {ch_waddr[1][30]} {ch_waddr[1][31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe12]
set_property port_width 64 [get_debug_ports u_ila_1/probe12]
connect_debug_port u_ila_1/probe12 [get_nets [list {ch_wdata[0][0]} {ch_wdata[0][1]} {ch_wdata[0][2]} {ch_wdata[0][3]} {ch_wdata[0][4]} {ch_wdata[0][5]} {ch_wdata[0][6]} {ch_wdata[0][7]} {ch_wdata[0][8]} {ch_wdata[0][9]} {ch_wdata[0][10]} {ch_wdata[0][11]} {ch_wdata[0][12]} {ch_wdata[0][13]} {ch_wdata[0][14]} {ch_wdata[0][15]} {ch_wdata[0][16]} {ch_wdata[0][17]} {ch_wdata[0][18]} {ch_wdata[0][19]} {ch_wdata[0][20]} {ch_wdata[0][21]} {ch_wdata[0][22]} {ch_wdata[0][23]} {ch_wdata[0][24]} {ch_wdata[0][25]} {ch_wdata[0][26]} {ch_wdata[0][27]} {ch_wdata[0][28]} {ch_wdata[0][29]} {ch_wdata[0][30]} {ch_wdata[0][31]} {ch_wdata[0][32]} {ch_wdata[0][33]} {ch_wdata[0][34]} {ch_wdata[0][35]} {ch_wdata[0][36]} {ch_wdata[0][37]} {ch_wdata[0][38]} {ch_wdata[0][39]} {ch_wdata[0][40]} {ch_wdata[0][41]} {ch_wdata[0][42]} {ch_wdata[0][43]} {ch_wdata[0][44]} {ch_wdata[0][45]} {ch_wdata[0][46]} {ch_wdata[0][47]} {ch_wdata[0][48]} {ch_wdata[0][49]} {ch_wdata[0][50]} {ch_wdata[0][51]} {ch_wdata[0][52]} {ch_wdata[0][53]} {ch_wdata[0][54]} {ch_wdata[0][55]} {ch_wdata[0][56]} {ch_wdata[0][57]} {ch_wdata[0][58]} {ch_wdata[0][59]} {ch_wdata[0][60]} {ch_wdata[0][61]} {ch_wdata[0][62]} {ch_wdata[0][63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe13]
set_property port_width 64 [get_debug_ports u_ila_1/probe13]
connect_debug_port u_ila_1/probe13 [get_nets [list {ch_wdata[1][0]} {ch_wdata[1][1]} {ch_wdata[1][2]} {ch_wdata[1][3]} {ch_wdata[1][4]} {ch_wdata[1][5]} {ch_wdata[1][6]} {ch_wdata[1][7]} {ch_wdata[1][8]} {ch_wdata[1][9]} {ch_wdata[1][10]} {ch_wdata[1][11]} {ch_wdata[1][12]} {ch_wdata[1][13]} {ch_wdata[1][14]} {ch_wdata[1][15]} {ch_wdata[1][16]} {ch_wdata[1][17]} {ch_wdata[1][18]} {ch_wdata[1][19]} {ch_wdata[1][20]} {ch_wdata[1][21]} {ch_wdata[1][22]} {ch_wdata[1][23]} {ch_wdata[1][24]} {ch_wdata[1][25]} {ch_wdata[1][26]} {ch_wdata[1][27]} {ch_wdata[1][28]} {ch_wdata[1][29]} {ch_wdata[1][30]} {ch_wdata[1][31]} {ch_wdata[1][32]} {ch_wdata[1][33]} {ch_wdata[1][34]} {ch_wdata[1][35]} {ch_wdata[1][36]} {ch_wdata[1][37]} {ch_wdata[1][38]} {ch_wdata[1][39]} {ch_wdata[1][40]} {ch_wdata[1][41]} {ch_wdata[1][42]} {ch_wdata[1][43]} {ch_wdata[1][44]} {ch_wdata[1][45]} {ch_wdata[1][46]} {ch_wdata[1][47]} {ch_wdata[1][48]} {ch_wdata[1][49]} {ch_wdata[1][50]} {ch_wdata[1][51]} {ch_wdata[1][52]} {ch_wdata[1][53]} {ch_wdata[1][54]} {ch_wdata[1][55]} {ch_wdata[1][56]} {ch_wdata[1][57]} {ch_wdata[1][58]} {ch_wdata[1][59]} {ch_wdata[1][60]} {ch_wdata[1][61]} {ch_wdata[1][62]} {ch_wdata[1][63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe14]
set_property port_width 2 [get_debug_ports u_ila_1/probe14]
connect_debug_port u_ila_1/probe14 [get_nets [list {ch_wen[0]} {ch_wen[1]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe15]
set_property port_width 32 [get_debug_ports u_ila_1/probe15]
connect_debug_port u_ila_1/probe15 [get_nets [list {ch_waddr[0][0]} {ch_waddr[0][1]} {ch_waddr[0][2]} {ch_waddr[0][3]} {ch_waddr[0][4]} {ch_waddr[0][5]} {ch_waddr[0][6]} {ch_waddr[0][7]} {ch_waddr[0][8]} {ch_waddr[0][9]} {ch_waddr[0][10]} {ch_waddr[0][11]} {ch_waddr[0][12]} {ch_waddr[0][13]} {ch_waddr[0][14]} {ch_waddr[0][15]} {ch_waddr[0][16]} {ch_waddr[0][17]} {ch_waddr[0][18]} {ch_waddr[0][19]} {ch_waddr[0][20]} {ch_waddr[0][21]} {ch_waddr[0][22]} {ch_waddr[0][23]} {ch_waddr[0][24]} {ch_waddr[0][25]} {ch_waddr[0][26]} {ch_waddr[0][27]} {ch_waddr[0][28]} {ch_waddr[0][29]} {ch_waddr[0][30]} {ch_waddr[0][31]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe16]
set_property port_width 4 [get_debug_ports u_ila_1/probe16]
connect_debug_port u_ila_1/probe16 [get_nets [list {cnt_with[0]} {cnt_with[1]} {cnt_with[2]} {cnt_with[3]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe17]
set_property port_width 2 [get_debug_ports u_ila_1/probe17]
connect_debug_port u_ila_1/probe17 [get_nets [list {data_acq_en[0]} {data_acq_en[1]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe18]
set_property port_width 128 [get_debug_ports u_ila_1/probe18]
connect_debug_port u_ila_1/probe18 [get_nets [list {din_s[0]} {din_s[1]} {din_s[2]} {din_s[3]} {din_s[4]} {din_s[5]} {din_s[6]} {din_s[7]} {din_s[8]} {din_s[9]} {din_s[10]} {din_s[11]} {din_s[12]} {din_s[13]} {din_s[14]} {din_s[15]} {din_s[16]} {din_s[17]} {din_s[18]} {din_s[19]} {din_s[20]} {din_s[21]} {din_s[22]} {din_s[23]} {din_s[24]} {din_s[25]} {din_s[26]} {din_s[27]} {din_s[28]} {din_s[29]} {din_s[30]} {din_s[31]} {din_s[32]} {din_s[33]} {din_s[34]} {din_s[35]} {din_s[36]} {din_s[37]} {din_s[38]} {din_s[39]} {din_s[40]} {din_s[41]} {din_s[42]} {din_s[43]} {din_s[44]} {din_s[45]} {din_s[46]} {din_s[47]} {din_s[48]} {din_s[49]} {din_s[50]} {din_s[51]} {din_s[52]} {din_s[53]} {din_s[54]} {din_s[55]} {din_s[56]} {din_s[57]} {din_s[58]} {din_s[59]} {din_s[60]} {din_s[61]} {din_s[62]} {din_s[63]} {din_s[64]} {din_s[65]} {din_s[66]} {din_s[67]} {din_s[68]} {din_s[69]} {din_s[70]} {din_s[71]} {din_s[72]} {din_s[73]} {din_s[74]} {din_s[75]} {din_s[76]} {din_s[77]} {din_s[78]} {din_s[79]} {din_s[80]} {din_s[81]} {din_s[82]} {din_s[83]} {din_s[84]} {din_s[85]} {din_s[86]} {din_s[87]} {din_s[88]} {din_s[89]} {din_s[90]} {din_s[91]} {din_s[92]} {din_s[93]} {din_s[94]} {din_s[95]} {din_s[96]} {din_s[97]} {din_s[98]} {din_s[99]} {din_s[100]} {din_s[101]} {din_s[102]} {din_s[103]} {din_s[104]} {din_s[105]} {din_s[106]} {din_s[107]} {din_s[108]} {din_s[109]} {din_s[110]} {din_s[111]} {din_s[112]} {din_s[113]} {din_s[114]} {din_s[115]} {din_s[116]} {din_s[117]} {din_s[118]} {din_s[119]} {din_s[120]} {din_s[121]} {din_s[122]} {din_s[123]} {din_s[124]} {din_s[125]} {din_s[126]} {din_s[127]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe19]
set_property port_width 64 [get_debug_ports u_ila_1/probe19]
connect_debug_port u_ila_1/probe19 [get_nets [list {data_reg[0][0]} {data_reg[0][1]} {data_reg[0][2]} {data_reg[0][3]} {data_reg[0][4]} {data_reg[0][5]} {data_reg[0][6]} {data_reg[0][7]} {data_reg[0][8]} {data_reg[0][9]} {data_reg[0][10]} {data_reg[0][11]} {data_reg[0][12]} {data_reg[0][13]} {data_reg[0][14]} {data_reg[0][15]} {data_reg[0][16]} {data_reg[0][17]} {data_reg[0][18]} {data_reg[0][19]} {data_reg[0][20]} {data_reg[0][21]} {data_reg[0][22]} {data_reg[0][23]} {data_reg[0][24]} {data_reg[0][25]} {data_reg[0][26]} {data_reg[0][27]} {data_reg[0][28]} {data_reg[0][29]} {data_reg[0][30]} {data_reg[0][31]} {data_reg[0][32]} {data_reg[0][33]} {data_reg[0][34]} {data_reg[0][35]} {data_reg[0][36]} {data_reg[0][37]} {data_reg[0][38]} {data_reg[0][39]} {data_reg[0][40]} {data_reg[0][41]} {data_reg[0][42]} {data_reg[0][43]} {data_reg[0][44]} {data_reg[0][45]} {data_reg[0][46]} {data_reg[0][47]} {data_reg[0][48]} {data_reg[0][49]} {data_reg[0][50]} {data_reg[0][51]} {data_reg[0][52]} {data_reg[0][53]} {data_reg[0][54]} {data_reg[0][55]} {data_reg[0][56]} {data_reg[0][57]} {data_reg[0][58]} {data_reg[0][59]} {data_reg[0][60]} {data_reg[0][61]} {data_reg[0][62]} {data_reg[0][63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe20]
set_property port_width 64 [get_debug_ports u_ila_1/probe20]
connect_debug_port u_ila_1/probe20 [get_nets [list {data_reg[1][0]} {data_reg[1][1]} {data_reg[1][2]} {data_reg[1][3]} {data_reg[1][4]} {data_reg[1][5]} {data_reg[1][6]} {data_reg[1][7]} {data_reg[1][8]} {data_reg[1][9]} {data_reg[1][10]} {data_reg[1][11]} {data_reg[1][12]} {data_reg[1][13]} {data_reg[1][14]} {data_reg[1][15]} {data_reg[1][16]} {data_reg[1][17]} {data_reg[1][18]} {data_reg[1][19]} {data_reg[1][20]} {data_reg[1][21]} {data_reg[1][22]} {data_reg[1][23]} {data_reg[1][24]} {data_reg[1][25]} {data_reg[1][26]} {data_reg[1][27]} {data_reg[1][28]} {data_reg[1][29]} {data_reg[1][30]} {data_reg[1][31]} {data_reg[1][32]} {data_reg[1][33]} {data_reg[1][34]} {data_reg[1][35]} {data_reg[1][36]} {data_reg[1][37]} {data_reg[1][38]} {data_reg[1][39]} {data_reg[1][40]} {data_reg[1][41]} {data_reg[1][42]} {data_reg[1][43]} {data_reg[1][44]} {data_reg[1][45]} {data_reg[1][46]} {data_reg[1][47]} {data_reg[1][48]} {data_reg[1][49]} {data_reg[1][50]} {data_reg[1][51]} {data_reg[1][52]} {data_reg[1][53]} {data_reg[1][54]} {data_reg[1][55]} {data_reg[1][56]} {data_reg[1][57]} {data_reg[1][58]} {data_reg[1][59]} {data_reg[1][60]} {data_reg[1][61]} {data_reg[1][62]} {data_reg[1][63]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe21]
set_property port_width 128 [get_debug_ports u_ila_1/probe21]
connect_debug_port u_ila_1/probe21 [get_nets [list {dout_b[0]} {dout_b[1]} {dout_b[2]} {dout_b[3]} {dout_b[4]} {dout_b[5]} {dout_b[6]} {dout_b[7]} {dout_b[8]} {dout_b[9]} {dout_b[10]} {dout_b[11]} {dout_b[12]} {dout_b[13]} {dout_b[14]} {dout_b[15]} {dout_b[16]} {dout_b[17]} {dout_b[18]} {dout_b[19]} {dout_b[20]} {dout_b[21]} {dout_b[22]} {dout_b[23]} {dout_b[24]} {dout_b[25]} {dout_b[26]} {dout_b[27]} {dout_b[28]} {dout_b[29]} {dout_b[30]} {dout_b[31]} {dout_b[32]} {dout_b[33]} {dout_b[34]} {dout_b[35]} {dout_b[36]} {dout_b[37]} {dout_b[38]} {dout_b[39]} {dout_b[40]} {dout_b[41]} {dout_b[42]} {dout_b[43]} {dout_b[44]} {dout_b[45]} {dout_b[46]} {dout_b[47]} {dout_b[48]} {dout_b[49]} {dout_b[50]} {dout_b[51]} {dout_b[52]} {dout_b[53]} {dout_b[54]} {dout_b[55]} {dout_b[56]} {dout_b[57]} {dout_b[58]} {dout_b[59]} {dout_b[60]} {dout_b[61]} {dout_b[62]} {dout_b[63]} {dout_b[64]} {dout_b[65]} {dout_b[66]} {dout_b[67]} {dout_b[68]} {dout_b[69]} {dout_b[70]} {dout_b[71]} {dout_b[72]} {dout_b[73]} {dout_b[74]} {dout_b[75]} {dout_b[76]} {dout_b[77]} {dout_b[78]} {dout_b[79]} {dout_b[80]} {dout_b[81]} {dout_b[82]} {dout_b[83]} {dout_b[84]} {dout_b[85]} {dout_b[86]} {dout_b[87]} {dout_b[88]} {dout_b[89]} {dout_b[90]} {dout_b[91]} {dout_b[92]} {dout_b[93]} {dout_b[94]} {dout_b[95]} {dout_b[96]} {dout_b[97]} {dout_b[98]} {dout_b[99]} {dout_b[100]} {dout_b[101]} {dout_b[102]} {dout_b[103]} {dout_b[104]} {dout_b[105]} {dout_b[106]} {dout_b[107]} {dout_b[108]} {dout_b[109]} {dout_b[110]} {dout_b[111]} {dout_b[112]} {dout_b[113]} {dout_b[114]} {dout_b[115]} {dout_b[116]} {dout_b[117]} {dout_b[118]} {dout_b[119]} {dout_b[120]} {dout_b[121]} {dout_b[122]} {dout_b[123]} {dout_b[124]} {dout_b[125]} {dout_b[126]} {dout_b[127]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe22]
set_property port_width 2 [get_debug_ports u_ila_1/probe22]
connect_debug_port u_ila_1/probe22 [get_nets [list {error[0]} {error[1]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe23]
set_property port_width 128 [get_debug_ports u_ila_1/probe23]
connect_debug_port u_ila_1/probe23 [get_nets [list {data_s_reg[0]} {data_s_reg[1]} {data_s_reg[2]} {data_s_reg[3]} {data_s_reg[4]} {data_s_reg[5]} {data_s_reg[6]} {data_s_reg[7]} {data_s_reg[8]} {data_s_reg[9]} {data_s_reg[10]} {data_s_reg[11]} {data_s_reg[12]} {data_s_reg[13]} {data_s_reg[14]} {data_s_reg[15]} {data_s_reg[16]} {data_s_reg[17]} {data_s_reg[18]} {data_s_reg[19]} {data_s_reg[20]} {data_s_reg[21]} {data_s_reg[22]} {data_s_reg[23]} {data_s_reg[24]} {data_s_reg[25]} {data_s_reg[26]} {data_s_reg[27]} {data_s_reg[28]} {data_s_reg[29]} {data_s_reg[30]} {data_s_reg[31]} {data_s_reg[32]} {data_s_reg[33]} {data_s_reg[34]} {data_s_reg[35]} {data_s_reg[36]} {data_s_reg[37]} {data_s_reg[38]} {data_s_reg[39]} {data_s_reg[40]} {data_s_reg[41]} {data_s_reg[42]} {data_s_reg[43]} {data_s_reg[44]} {data_s_reg[45]} {data_s_reg[46]} {data_s_reg[47]} {data_s_reg[48]} {data_s_reg[49]} {data_s_reg[50]} {data_s_reg[51]} {data_s_reg[52]} {data_s_reg[53]} {data_s_reg[54]} {data_s_reg[55]} {data_s_reg[56]} {data_s_reg[57]} {data_s_reg[58]} {data_s_reg[59]} {data_s_reg[60]} {data_s_reg[61]} {data_s_reg[62]} {data_s_reg[63]} {data_s_reg[64]} {data_s_reg[65]} {data_s_reg[66]} {data_s_reg[67]} {data_s_reg[68]} {data_s_reg[69]} {data_s_reg[70]} {data_s_reg[71]} {data_s_reg[72]} {data_s_reg[73]} {data_s_reg[74]} {data_s_reg[75]} {data_s_reg[76]} {data_s_reg[77]} {data_s_reg[78]} {data_s_reg[79]} {data_s_reg[80]} {data_s_reg[81]} {data_s_reg[82]} {data_s_reg[83]} {data_s_reg[84]} {data_s_reg[85]} {data_s_reg[86]} {data_s_reg[87]} {data_s_reg[88]} {data_s_reg[89]} {data_s_reg[90]} {data_s_reg[91]} {data_s_reg[92]} {data_s_reg[93]} {data_s_reg[94]} {data_s_reg[95]} {data_s_reg[96]} {data_s_reg[97]} {data_s_reg[98]} {data_s_reg[99]} {data_s_reg[100]} {data_s_reg[101]} {data_s_reg[102]} {data_s_reg[103]} {data_s_reg[104]} {data_s_reg[105]} {data_s_reg[106]} {data_s_reg[107]} {data_s_reg[108]} {data_s_reg[109]} {data_s_reg[110]} {data_s_reg[111]} {data_s_reg[112]} {data_s_reg[113]} {data_s_reg[114]} {data_s_reg[115]} {data_s_reg[116]} {data_s_reg[117]} {data_s_reg[118]} {data_s_reg[119]} {data_s_reg[120]} {data_s_reg[121]} {data_s_reg[122]} {data_s_reg[123]} {data_s_reg[124]} {data_s_reg[125]} {data_s_reg[126]} {data_s_reg[127]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe24]
set_property port_width 2 [get_debug_ports u_ila_1/probe24]
connect_debug_port u_ila_1/probe24 [get_nets [list {irq_req[0]} {irq_req[1]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe25]
set_property port_width 17 [get_debug_ports u_ila_1/probe25]
connect_debug_port u_ila_1/probe25 [get_nets [list {single_sample[0]} {single_sample[1]} {single_sample[2]} {single_sample[3]} {single_sample[4]} {single_sample[5]} {single_sample[6]} {single_sample[7]} {single_sample[8]} {single_sample[9]} {single_sample[10]} {single_sample[11]} {single_sample[12]} {single_sample[13]} {single_sample[14]} {single_sample[15]} {single_sample[16]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe26]
set_property port_width 16 [get_debug_ports u_ila_1/probe26]
connect_debug_port u_ila_1/probe26 [get_nets [list {time_base[0]} {time_base[1]} {time_base[2]} {time_base[3]} {time_base[4]} {time_base[5]} {time_base[6]} {time_base[7]} {time_base[8]} {time_base[9]} {time_base[10]} {time_base[11]} {time_base[12]} {time_base[13]} {time_base[14]} {time_base[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe27]
set_property port_width 2 [get_debug_ports u_ila_1/probe27]
connect_debug_port u_ila_1/probe27 [get_nets [list {warning[0]} {warning[1]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe28]
set_property port_width 16 [get_debug_ports u_ila_1/probe28]
connect_debug_port u_ila_1/probe28 [get_nets [list {wen_b[0]} {wen_b[1]} {wen_b[2]} {wen_b[3]} {wen_b[4]} {wen_b[5]} {wen_b[6]} {wen_b[7]} {wen_b[8]} {wen_b[9]} {wen_b[10]} {wen_b[11]} {wen_b[12]} {wen_b[13]} {wen_b[14]} {wen_b[15]}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe29]
set_property port_width 1 [get_debug_ports u_ila_1/probe29]
connect_debug_port u_ila_1/probe29 [get_nets [list {ssi_channel[0].unipath_data_collection_inst/data_flag}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe30]
set_property port_width 1 [get_debug_ports u_ila_1/probe30]
connect_debug_port u_ila_1/probe30 [get_nets [list {ssi_channel[1].unipath_data_collection_inst/data_flag}]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe31]
set_property port_width 1 [get_debug_ports u_ila_1/probe31]
connect_debug_port u_ila_1/probe31 [get_nets [list en_b]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe32]
set_property port_width 1 [get_debug_ports u_ila_1/probe32]
connect_debug_port u_ila_1/probe32 [get_nets [list en_s]]
create_debug_port u_ila_1 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_1/probe33]
set_property port_width 1 [get_debug_ports u_ila_1/probe33]
connect_debug_port u_ila_1/probe33 [get_nets [list irq_all]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets bram_clk_b]
