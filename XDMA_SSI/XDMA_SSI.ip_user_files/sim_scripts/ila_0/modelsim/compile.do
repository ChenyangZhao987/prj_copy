vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xil_defaultlib

vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xil_defaultlib  -incr -mfcu "+incdir+../../../../XDMA_SSI.gen/sources_1/ip/ila_0/hdl/verilog" "+incdir+D:/Xilinx/Vivado/Vivado/2022.1/data/xilinx_vip/include" \
"../../../../XDMA_SSI.gen/sources_1/ip/ila_0/sim/ila_0.v" \


vlog -work xil_defaultlib \
"glbl.v"

