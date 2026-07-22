set_property PACKAGE_PIN AG10 [get_ports clk_p]
set_property PACKAGE_PIN AH10 [get_ports clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_p]
set_property IOSTANDARD DIFF_SSTL15 [get_ports clk_n]
#create_clock -period 5.000 -name clk_in [get_ports clk_p]

set_property PACKAGE_PIN P24 [get_ports {Flash_Spi_Sdio[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Flash_Spi_Sdio[0]}]
set_property PULLUP TRUE [get_ports {Flash_Spi_Sdio[0]}]

set_property PACKAGE_PIN R25 [get_ports {Flash_Spi_Sdio[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Flash_Spi_Sdio[1]}]
set_property PULLUP TRUE [get_ports {Flash_Spi_Sdio[1]}]

set_property PACKAGE_PIN R20 [get_ports {Flash_Spi_Sdio[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Flash_Spi_Sdio[2]}]
set_property PULLUP TRUE [get_ports {Flash_Spi_Sdio[2]}]

set_property PACKAGE_PIN R21 [get_ports {Flash_Spi_Sdio[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {Flash_Spi_Sdio[3]}]
set_property PULLUP TRUE [get_ports {Flash_Spi_Sdio[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports Flash_Spi_Csn]
set_property PACKAGE_PIN U19 [get_ports Flash_Spi_Csn]
set_property PULLUP TRUE [get_ports Flash_Spi_Csn]

set_property PACKAGE_PIN Y20 [get_ports Uart_Tx]
set_property IOSTANDARD LVCMOS33 [get_ports Uart_Tx]

set_property PACKAGE_PIN W26 [get_ports Uart_Rx]
set_property IOSTANDARD LVCMOS33 [get_ports Uart_Rx]

set_property PACKAGE_PIN AG13 [get_ports {Led[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {Led[0]}]

set_property PACKAGE_PIN AF12 [get_ports {Led[1]}]
set_property IOSTANDARD LVCMOS18 [get_ports {Led[1]}]

set_property PACKAGE_PIN AH12 [get_ports {Led[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {Led[2]}]

set_property PACKAGE_PIN AK10 [get_ports {Led[3]}]
set_property IOSTANDARD LVCMOS18 [get_ports {Led[3]}]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]	
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]


set_property BITSTREAM.CONFIG.CONFIGFALLBACK ENABLE	[current_design]
#set_property BITSTREAM.CONFIG.NEXT_CONFIG_ADDR 32'h00600000  [current_design]


set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]




