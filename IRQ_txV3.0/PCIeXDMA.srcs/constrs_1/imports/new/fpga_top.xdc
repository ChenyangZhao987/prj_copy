
create_clock -name sys_clk -period 10 [get_ports i_pcie_refclkp]

set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS15} [get_ports Led0]
set_property PACKAGE_PIN Y24 [get_ports Pcie_rstn]
set_property IOSTANDARD LVCMOS33 [get_ports Pcie_rstn]
set_property PULLUP true [get_ports Pcie_rstn]
set_property PACKAGE_PIN U8 [get_ports Pcie_refclkp]

set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports Sig_Inp1]
set_property -dict {PACKAGE_PIN V27 IOSTANDARD LVCMOS33} [get_ports Sig_Out1]
set_property -dict {PACKAGE_PIN V26 IOSTANDARD LVCMOS33} [get_ports Sig_Out2]


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
