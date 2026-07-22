
create_clock -period 10.000 -name sys_clk [get_ports Pcie_refclkp]

set_property PACKAGE_PIN Y24 [get_ports Pcie_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports Pcie_rstn]
set_property PULLUP true [get_ports Pcie_rstn]
set_property PACKAGE_PIN U8 [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports {Cs_n[0]}]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS33} [get_ports {Cs_n[1]}]
set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports {Cs_n[2]}]
set_property -dict {PACKAGE_PIN U29 IOSTANDARD LVCMOS33} [get_ports {Cs_n[3]}]
set_property -dict {PACKAGE_PIN V30 IOSTANDARD LVCMOS33} [get_ports {Cs_n[4]}]
set_property -dict {PACKAGE_PIN T30 IOSTANDARD LVCMOS33} [get_ports {Cs_n[5]}]
set_property -dict {PACKAGE_PIN R30 IOSTANDARD LVCMOS33} [get_ports {Cs_n[6]}]
set_property -dict {PACKAGE_PIN P29 IOSTANDARD LVCMOS33} [get_ports {Cs_n[7]}]
# -------------------------- 通道0.约束 -----------------------

set_property PACKAGE_PIN AE28 [get_ports {RE_422[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[0]}]

set_property PACKAGE_PIN AF28 [get_ports {DE_422[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[0]}]


set_property PACKAGE_PIN AH26 [get_ports {Scl[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[0]}]

set_property PACKAGE_PIN AF26 [get_ports {Sda[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[0]}]

# -------------------------- 通道1.约束 -----------------------

set_property PACKAGE_PIN AD27 [get_ports {RE_422[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[1]}]

set_property PACKAGE_PIN AA28 [get_ports {DE_422[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[1]}]


set_property PACKAGE_PIN AD28 [get_ports {Scl[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[1]}]

set_property PACKAGE_PIN W29 [get_ports {Sda[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[1]}]

# -------------------------- 通道2.约束 -----------------------

set_property PACKAGE_PIN AE30 [get_ports {RE_422[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[2]}]

set_property PACKAGE_PIN AE29 [get_ports {DE_422[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[2]}]


set_property PACKAGE_PIN AD29 [get_ports {Scl[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[2]}]

set_property PACKAGE_PIN W27 [get_ports {Sda[2]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[2]}]

# -------------------------- 通道3.约束 -----------------------

set_property PACKAGE_PIN Y30 [get_ports {RE_422[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[3]}]

set_property PACKAGE_PIN AA30 [get_ports {DE_422[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[3]}]


set_property PACKAGE_PIN AF30 [get_ports {Scl[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[3]}]

set_property PACKAGE_PIN AB30 [get_ports {Sda[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[3]}]

# -------------------------- 通道4.约束 -----------------------

set_property PACKAGE_PIN AJ27 [get_ports {RE_422[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[4]}]

set_property PACKAGE_PIN AJ26 [get_ports {DE_422[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[4]}]


set_property PACKAGE_PIN AK28 [get_ports {Scl[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[4]}]

set_property PACKAGE_PIN AC30 [get_ports {Sda[4]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[4]}]

# -------------------------- 通道5.约束 -----------------------

set_property PACKAGE_PIN AG30 [get_ports {RE_422[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[5]}]

set_property PACKAGE_PIN AJ28 [get_ports {DE_422[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[5]}]


set_property PACKAGE_PIN AH30 [get_ports {Scl[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[5]}]

set_property PACKAGE_PIN AD26 [get_ports {Sda[5]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[5]}]

# -------------------------- 通道6.约束 -----------------------

set_property PACKAGE_PIN AB28 [get_ports {RE_422[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[6]}]

set_property PACKAGE_PIN AC29 [get_ports {DE_422[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[6]}]


set_property PACKAGE_PIN AG28 [get_ports {Scl[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[6]}]

set_property PACKAGE_PIN Y29 [get_ports {Sda[6]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[6]}]

# -------------------------- 通道7.约束 -----------------------

set_property PACKAGE_PIN Y26 [get_ports {RE_422[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {RE_422[7]}]

set_property PACKAGE_PIN AA26 [get_ports {DE_422[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {DE_422[7]}]


set_property PACKAGE_PIN AA27 [get_ports {Scl[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Scl[7]}]

set_property PACKAGE_PIN AB29 [get_ports {Sda[7]}]
set_property IOSTANDARD LVCMOS25 [get_ports {Sda[7]}]


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

set_property PACKAGE_PIN AJ13 [get_ports DDR_sys_rst]
set_property IOSTANDARD LVCMOS15 [get_ports DDR_sys_rst]


set_property PACKAGE_PIN AK11 [get_ports {led[6]}]
set_property PACKAGE_PIN AJ12 [get_ports {led[7]}]
set_property PACKAGE_PIN AK10 [get_ports {led[5]}]
set_property PACKAGE_PIN AJ11 [get_ports {led[4]}]
set_property PACKAGE_PIN AH12 [get_ports {led[3]}]
set_property PACKAGE_PIN AF12 [get_ports {led[2]}]
set_property PACKAGE_PIN AG13 [get_ports {led[1]}]
set_property PACKAGE_PIN AE13 [get_ports {led[0]}]


set_property IOSTANDARD LVCMOS15 [get_ports {led[7]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS15 [get_ports {led[0]}]

# MIG status bits are asynchronous to the XDMA/BRAM register clock. They are
# sampled by explicit synchronizers in SSI_top before software reads them.
set_false_path -to [get_pins -hierarchical *init_calib_complete_sync_r_reg[0]/D]
set_false_path -to [get_pins -hierarchical *mmcm_locked_sync_r_reg[0]/D]
