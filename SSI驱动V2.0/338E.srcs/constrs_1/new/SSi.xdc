set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports Ssclk]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports Ssda]
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports Cs_n]
set_property VCCAUX_IO DONTCARE [get_ports Sys_clk_p]

set_property IOSTANDARD DIFF_SSTL15 [get_ports Sys_clk_p]



set_property IOSTANDARD DIFF_SSTL15 [get_ports Sys_clk_n]

set_property PACKAGE_PIN AG10 [get_ports Sys_clk_p]
set_property PACKAGE_PIN AH10 [get_ports Sys_clk_n]
#create_clock -name Sys_clk -period 5.0 [get_ports Sys_clk_p]



#connect_debug_port u_ila_0/probe2 [get_nets [list sclk]]
#connect_debug_port u_ila_0/probe3 [get_nets [list sda]]
#connect_debug_port dbg_hub/clk [get_nets clk]








connect_debug_port u_ila_0/probe2 [get_nets [list {rate_cnt[0]} {rate_cnt[1]} {rate_cnt[2]} {rate_cnt[3]} {rate_cnt[4]} {rate_cnt[5]} {rate_cnt[6]} {rate_cnt[7]} {rate_cnt[8]} {rate_cnt[9]} {rate_cnt[10]} {rate_cnt[11]} {rate_cnt[12]} {rate_cnt[13]} {rate_cnt[14]} {rate_cnt[15]}]]




create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 65536 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_wiz/inst/clk_out1]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 16 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {rate_cnt[0]} {rate_cnt[1]} {rate_cnt[2]} {rate_cnt[3]} {rate_cnt[4]} {rate_cnt[5]} {rate_cnt[6]} {rate_cnt[7]} {rate_cnt[8]} {rate_cnt[9]} {rate_cnt[10]} {rate_cnt[11]} {rate_cnt[12]} {rate_cnt[13]} {rate_cnt[14]} {rate_cnt[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 24 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {Data_out[0]} {Data_out[1]} {Data_out[2]} {Data_out[3]} {Data_out[4]} {Data_out[5]} {Data_out[6]} {Data_out[7]} {Data_out[8]} {Data_out[9]} {Data_out[10]} {Data_out[11]} {Data_out[12]} {Data_out[13]} {Data_out[14]} {Data_out[15]} {Data_out[16]} {Data_out[17]} {Data_out[18]} {Data_out[19]} {Data_out[20]} {Data_out[21]} {Data_out[22]} {Data_out[23]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 21 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list {nop_cnt[0]} {nop_cnt[1]} {nop_cnt[2]} {nop_cnt[3]} {nop_cnt[4]} {nop_cnt[5]} {nop_cnt[6]} {nop_cnt[7]} {nop_cnt[8]} {nop_cnt[9]} {nop_cnt[10]} {nop_cnt[11]} {nop_cnt[12]} {nop_cnt[13]} {nop_cnt[14]} {nop_cnt[15]} {nop_cnt[16]} {nop_cnt[17]} {nop_cnt[18]} {nop_cnt[19]} {nop_cnt[20]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 3 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list {rx_state[0]} {rx_state[1]} {rx_state[2]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 13 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list {scl_cnt[0]} {scl_cnt[1]} {scl_cnt[2]} {scl_cnt[3]} {scl_cnt[4]} {scl_cnt[5]} {scl_cnt[6]} {scl_cnt[7]} {scl_cnt[8]} {scl_cnt[9]} {scl_cnt[10]} {scl_cnt[11]} {scl_cnt[12]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe5]
set_property port_width 16 [get_debug_ports u_ila_0/probe5]
connect_debug_port u_ila_0/probe5 [get_nets [list {rev_cnt[0]} {rev_cnt[1]} {rev_cnt[2]} {rev_cnt[3]} {rev_cnt[4]} {rev_cnt[5]} {rev_cnt[6]} {rev_cnt[7]} {rev_cnt[8]} {rev_cnt[9]} {rev_cnt[10]} {rev_cnt[11]} {rev_cnt[12]} {rev_cnt[13]} {rev_cnt[14]} {rev_cnt[15]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe6]
set_property port_width 6 [get_debug_ports u_ila_0/probe6]
connect_debug_port u_ila_0/probe6 [get_nets [list {bit_cnt[0]} {bit_cnt[1]} {bit_cnt[2]} {bit_cnt[3]} {bit_cnt[4]} {bit_cnt[5]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe7]
set_property port_width 1 [get_debug_ports u_ila_0/probe7]
connect_debug_port u_ila_0/probe7 [get_nets [list cs_n]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe8]
set_property port_width 1 [get_debug_ports u_ila_0/probe8]
connect_debug_port u_ila_0/probe8 [get_nets [list Data_flag]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe9]
set_property port_width 1 [get_debug_ports u_ila_0/probe9]
connect_debug_port u_ila_0/probe9 [get_nets [list sclk1]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe10]
set_property port_width 1 [get_debug_ports u_ila_0/probe10]
connect_debug_port u_ila_0/probe10 [get_nets [list sda1]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets Phy_Clk]
