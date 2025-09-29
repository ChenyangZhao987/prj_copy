path %psth%;D:\Xilinx\Vivado\Vivado\2022.1\bin
start "C:\Windows\System32\cmd.exe" 
@echo Produce the vivado project.
 
set cache_floder=.Xil
cd  %~dp0
if exist %~dp0%cache_floder% ( 
    echo The floder is exist.
    pause
) else (
    vivado -source PCIe_XDMA.tcl
)
exit