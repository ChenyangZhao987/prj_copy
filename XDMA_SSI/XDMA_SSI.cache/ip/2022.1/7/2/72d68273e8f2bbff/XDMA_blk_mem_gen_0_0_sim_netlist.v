// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.1 (win64) Build 3526262 Mon Apr 18 15:48:16 MDT 2022
// Date        : Tue Sep 23 11:33:14 2025
// Host        : DESKTOP-VQGIJDC running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode funcsim -rename_top decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix -prefix
//               decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_ XDMA_blk_mem_gen_0_0_sim_netlist.v
// Design      : XDMA_blk_mem_gen_0_0
// Purpose     : This verilog netlist is a functional simulation representation of the design and should not be modified
//               or synthesized. This netlist cannot be used for SDF annotated simulation.
// Device      : xc7k325tffg900-2
// --------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

(* CHECK_LICENSE_TYPE = "XDMA_blk_mem_gen_0_0,blk_mem_gen_v8_4_5,{}" *) (* downgradeipidentifiedwarnings = "yes" *) (* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.1" *) 
(* NotValidForBitStream *)
module decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix
   (clka,
    rsta,
    ena,
    wea,
    addra,
    dina,
    douta,
    clkb,
    rstb,
    enb,
    web,
    addrb,
    dinb,
    doutb,
    rsta_busy,
    rstb_busy);
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTA, MEM_SIZE 4096, MEM_WIDTH 64, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *) input clka;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA RST" *) input rsta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA EN" *) input ena;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA WE" *) input [7:0]wea;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA ADDR" *) input [31:0]addra;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DIN" *) input [63:0]dina;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTA DOUT" *) output [63:0]douta;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB CLK" *) (* x_interface_parameter = "XIL_INTERFACENAME BRAM_PORTB, MEM_SIZE 8192, MEM_WIDTH 32, MEM_ECC NONE, MASTER_TYPE BRAM_CTRL, READ_WRITE_MODE READ_WRITE, READ_LATENCY 1" *) input clkb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB RST" *) input rstb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB EN" *) input enb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB WE" *) input [3:0]web;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB ADDR" *) input [31:0]addrb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DIN" *) input [31:0]dinb;
  (* x_interface_info = "xilinx.com:interface:bram:1.0 BRAM_PORTB DOUT" *) output [31:0]doutb;
  output rsta_busy;
  output rstb_busy;

  wire [31:0]addra;
  wire [31:0]addrb;
  wire clka;
  wire clkb;
  wire [63:0]dina;
  wire [31:0]dinb;
  wire [63:0]douta;
  wire [31:0]doutb;
  wire ena;
  wire enb;
  wire rsta;
  wire rsta_busy;
  wire rstb;
  wire rstb_busy;
  wire [7:0]wea;
  wire [3:0]web;
  wire NLW_U0_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_arready_UNCONNECTED;
  wire NLW_U0_s_axi_awready_UNCONNECTED;
  wire NLW_U0_s_axi_bvalid_UNCONNECTED;
  wire NLW_U0_s_axi_dbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_rlast_UNCONNECTED;
  wire NLW_U0_s_axi_rvalid_UNCONNECTED;
  wire NLW_U0_s_axi_sbiterr_UNCONNECTED;
  wire NLW_U0_s_axi_wready_UNCONNECTED;
  wire NLW_U0_sbiterr_UNCONNECTED;
  wire [31:0]NLW_U0_rdaddrecc_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_bid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_bresp_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdaddrecc_UNCONNECTED;
  wire [31:0]NLW_U0_s_axi_rdata_UNCONNECTED;
  wire [3:0]NLW_U0_s_axi_rid_UNCONNECTED;
  wire [1:0]NLW_U0_s_axi_rresp_UNCONNECTED;

  (* C_ADDRA_WIDTH = "32" *) 
  (* C_ADDRB_WIDTH = "32" *) 
  (* C_ALGORITHM = "1" *) 
  (* C_AXI_ID_WIDTH = "4" *) 
  (* C_AXI_SLAVE_TYPE = "0" *) 
  (* C_AXI_TYPE = "1" *) 
  (* C_BYTE_SIZE = "8" *) 
  (* C_COMMON_CLK = "0" *) 
  (* C_COUNT_18K_BRAM = "0" *) 
  (* C_COUNT_36K_BRAM = "2" *) 
  (* C_CTRL_ECC_ALGO = "NONE" *) 
  (* C_DEFAULT_DATA = "0" *) 
  (* C_DISABLE_WARN_BHV_COLL = "0" *) 
  (* C_DISABLE_WARN_BHV_RANGE = "0" *) 
  (* C_ELABORATION_DIR = "./" *) 
  (* C_ENABLE_32BIT_ADDRESS = "1" *) 
  (* C_EN_DEEPSLEEP_PIN = "0" *) 
  (* C_EN_ECC_PIPE = "0" *) 
  (* C_EN_RDADDRA_CHG = "0" *) 
  (* C_EN_RDADDRB_CHG = "0" *) 
  (* C_EN_SAFETY_CKT = "1" *) 
  (* C_EN_SHUTDOWN_PIN = "0" *) 
  (* C_EN_SLEEP_PIN = "0" *) 
  (* C_EST_POWER_SUMMARY = "Estimated Power for IP     :     10.4716 mW" *) 
  (* C_FAMILY = "kintex7" *) 
  (* C_HAS_AXI_ID = "0" *) 
  (* C_HAS_ENA = "1" *) 
  (* C_HAS_ENB = "1" *) 
  (* C_HAS_INJECTERR = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MEM_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_A = "0" *) 
  (* C_HAS_MUX_OUTPUT_REGS_B = "0" *) 
  (* C_HAS_REGCEA = "0" *) 
  (* C_HAS_REGCEB = "0" *) 
  (* C_HAS_RSTA = "1" *) 
  (* C_HAS_RSTB = "1" *) 
  (* C_HAS_SOFTECC_INPUT_REGS_A = "0" *) 
  (* C_HAS_SOFTECC_OUTPUT_REGS_B = "0" *) 
  (* C_INITA_VAL = "0" *) 
  (* C_INITB_VAL = "0" *) 
  (* C_INIT_FILE = "NONE" *) 
  (* C_INIT_FILE_NAME = "no_coe_file_loaded" *) 
  (* C_INTERFACE_TYPE = "0" *) 
  (* C_LOAD_INIT_FILE = "0" *) 
  (* C_MEM_TYPE = "2" *) 
  (* C_MUX_PIPELINE_STAGES = "0" *) 
  (* C_PRIM_TYPE = "1" *) 
  (* C_READ_DEPTH_A = "1024" *) 
  (* C_READ_DEPTH_B = "2048" *) 
  (* C_READ_LATENCY_A = "1" *) 
  (* C_READ_LATENCY_B = "1" *) 
  (* C_READ_WIDTH_A = "64" *) 
  (* C_READ_WIDTH_B = "32" *) 
  (* C_RSTRAM_A = "0" *) 
  (* C_RSTRAM_B = "0" *) 
  (* C_RST_PRIORITY_A = "CE" *) 
  (* C_RST_PRIORITY_B = "CE" *) 
  (* C_SIM_COLLISION_CHECK = "ALL" *) 
  (* C_USE_BRAM_BLOCK = "1" *) 
  (* C_USE_BYTE_WEA = "1" *) 
  (* C_USE_BYTE_WEB = "1" *) 
  (* C_USE_DEFAULT_DATA = "0" *) 
  (* C_USE_ECC = "0" *) 
  (* C_USE_SOFTECC = "0" *) 
  (* C_USE_URAM = "0" *) 
  (* C_WEA_WIDTH = "8" *) 
  (* C_WEB_WIDTH = "4" *) 
  (* C_WRITE_DEPTH_A = "1024" *) 
  (* C_WRITE_DEPTH_B = "2048" *) 
  (* C_WRITE_MODE_A = "WRITE_FIRST" *) 
  (* C_WRITE_MODE_B = "WRITE_FIRST" *) 
  (* C_WRITE_WIDTH_A = "64" *) 
  (* C_WRITE_WIDTH_B = "32" *) 
  (* C_XDEVICEFAMILY = "kintex7" *) 
  (* downgradeipidentifiedwarnings = "yes" *) 
  (* is_du_within_envelope = "true" *) 
  decalper_eb_ot_sdeen_pot_pi_dehcac_xnilix_blk_mem_gen_v8_4_5 U0
       (.addra({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,addra[12:3],1'b0,1'b0,1'b0}),
        .addrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,addrb[12:2],1'b0,1'b0}),
        .clka(clka),
        .clkb(clkb),
        .dbiterr(NLW_U0_dbiterr_UNCONNECTED),
        .deepsleep(1'b0),
        .dina(dina),
        .dinb(dinb),
        .douta(douta),
        .doutb(doutb),
        .eccpipece(1'b0),
        .ena(ena),
        .enb(enb),
        .injectdbiterr(1'b0),
        .injectsbiterr(1'b0),
        .rdaddrecc(NLW_U0_rdaddrecc_UNCONNECTED[31:0]),
        .regcea(1'b0),
        .regceb(1'b0),
        .rsta(rsta),
        .rsta_busy(rsta_busy),
        .rstb(rstb),
        .rstb_busy(rstb_busy),
        .s_aclk(1'b0),
        .s_aresetn(1'b0),
        .s_axi_araddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arburst({1'b0,1'b0}),
        .s_axi_arid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_arready(NLW_U0_s_axi_arready_UNCONNECTED),
        .s_axi_arsize({1'b0,1'b0,1'b0}),
        .s_axi_arvalid(1'b0),
        .s_axi_awaddr({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awburst({1'b0,1'b0}),
        .s_axi_awid({1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awlen({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_awready(NLW_U0_s_axi_awready_UNCONNECTED),
        .s_axi_awsize({1'b0,1'b0,1'b0}),
        .s_axi_awvalid(1'b0),
        .s_axi_bid(NLW_U0_s_axi_bid_UNCONNECTED[3:0]),
        .s_axi_bready(1'b0),
        .s_axi_bresp(NLW_U0_s_axi_bresp_UNCONNECTED[1:0]),
        .s_axi_bvalid(NLW_U0_s_axi_bvalid_UNCONNECTED),
        .s_axi_dbiterr(NLW_U0_s_axi_dbiterr_UNCONNECTED),
        .s_axi_injectdbiterr(1'b0),
        .s_axi_injectsbiterr(1'b0),
        .s_axi_rdaddrecc(NLW_U0_s_axi_rdaddrecc_UNCONNECTED[31:0]),
        .s_axi_rdata(NLW_U0_s_axi_rdata_UNCONNECTED[31:0]),
        .s_axi_rid(NLW_U0_s_axi_rid_UNCONNECTED[3:0]),
        .s_axi_rlast(NLW_U0_s_axi_rlast_UNCONNECTED),
        .s_axi_rready(1'b0),
        .s_axi_rresp(NLW_U0_s_axi_rresp_UNCONNECTED[1:0]),
        .s_axi_rvalid(NLW_U0_s_axi_rvalid_UNCONNECTED),
        .s_axi_sbiterr(NLW_U0_s_axi_sbiterr_UNCONNECTED),
        .s_axi_wdata({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wlast(1'b0),
        .s_axi_wready(NLW_U0_s_axi_wready_UNCONNECTED),
        .s_axi_wstrb({1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0,1'b0}),
        .s_axi_wvalid(1'b0),
        .sbiterr(NLW_U0_sbiterr_UNCONNECTED),
        .shutdown(1'b0),
        .sleep(1'b0),
        .wea(wea),
        .web(web));
endmodule
`pragma protect begin_protected
`pragma protect version = 1
`pragma protect encrypt_agent = "XILINX"
`pragma protect encrypt_agent_info = "Xilinx Encryption Tool 2022.1"
`pragma protect key_keyowner="Synopsys", key_keyname="SNPS-VCS-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
RgPKnWr9n0dGgttm3akiFhAlfB96usOQYxnEmPhGyTGg1AbizYAjGPWLXBWl50n/d0IA71ci4aJB
wt6mtfyNADm3ZReK7D3mKu037BOgxryoEwwf1kiC6q/PllxsdAgEMfQrfHJ3E2AzSpdYjoxVYito
y0JW6CUDcWvWa4WV0EA=

`pragma protect key_keyowner="Aldec", key_keyname="ALDEC15_001", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
M0l6KpOGH3jL8eRt3NCD7e2USYnkg5H9GAnE1PKmnjiouFN3Y8kjWA2PZDAQLm9UW+TsC1HeVlzO
WjNCHkjR/6ubCsIcWfpPZWdIuAenlsyq8Y9l6b8vMj8JSbDEOiFF/GHSbKsn22MJdDJKEhHFK6GV
s8gR2vywRFwG69gIRE4qGhVB+WIg8GJrDpDMYH6lCjMkTrjXuKDUcNlJN3NPLuhJ7tsditwf1pr5
moJRmGpJnip/rGm0g4o4A6ev4CtePjoao8C1wFtzHkERX9oenhh7cGjDMejU5IrLv8NxFnLj1FpB
9MuF1beTU20NI5oAn6zLiLiOtXjf0ghU3AN4DA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VELOCE-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=128)
`pragma protect key_block
hAsrUfp6Qgjm8yBjNYTEtQmVQmMxzL8TE/3oiQSxSI3+yEkXAbQCXkT9mo+LCdv+fGECOB0istHd
eLtbsiYbxjxNxYkXiUrRE5O+aSxynIray+uF9DJigTEUZu8JJXUbzxK4DDUu1Lm9tpGps4+Prz1m
0gkj13RT/Y/418s2VTw=

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-VERIF-SIM-RSA-2", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
BP/54Wm/GJmb1jy0bxWJJX4aiKyiWPVh4X3VL30BQrmX4PlEsNKzBJH3Qu8IIYERfnFP0ifAgboa
vypMQ5Ed0BrMePGkWIgT6I8hxJCMFpHdkSK7m1giSKyZzFfTOrVqoNFXE+qdzLfY1J5hBWCvouYo
jllavK4N3gF9FLScH2AUWYVMcVth2QPaTAU2NLnAUNH8kgtBjBfc8/KbPPTznD1QNVqvFstzcbTA
hGQ1ETVPvINQ0KqxxAG5PRhtQD4+pC+hr/Tvk+RSvGyBOfy9zE86OXkJiYs9dSFhNiMFmCPL9DBO
se4OxNNC0/7aBtb1mkSEA9YFDYEb9jS7Jasy2A==

`pragma protect key_keyowner="Real Intent", key_keyname="RI-RSA-KEY-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
SnzT9DVH3xlEN8nrr2YrlvTO5qj7L22d7WaBcuKyTaiHoIwwFHrC4HQbfs0TAwkdWcOgmJoATPSF
F6qm0KiddbrlERF3MfKUldeGBJtqLdX+zGw7+3JD7S+HB9dIMOFOHy+IiCZp1/Pz8epKpi238cel
rcVoJQKz406wmXDvOo8KsT+XhRLs9BVCrBErPGGXKYDk6NXAp0duOgQE9DbslzMU83M/kUC7uERV
tQW02240peKQFp2elEZC7Tetvgp0TaFTtJiKN45REi8GQUCKGa85JjNIk1qb/+k95TIIP1xrHirc
6iX7qbwnPetv8TVu2NjkZ0WDEK5RXdOXcxBwHA==

`pragma protect key_keyowner="Xilinx", key_keyname="xilinxt_2021_07", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
erkR82V0jX8ytva+9MzEs0c75Z7j7TsgxWRLNAUfbbU28i+U9YzuZlSfYU75M0f9jx1gvxtBrfKv
cNHVdkR+i5zfHDZsDwfMEEBhs8wzDCKqe+eex6BBEvlIOesCPXrr2RozQgaQ1PBh/os2Arfu+873
BjsVxFJkbhpzIqlddOo/XZV9Yi+eih7A7pXXEBR6IL7Poo4Ka49MiVQU0xJrDTm+ddOuMPDRRD7g
dsxS/uzdcBcO2myV6g/7YH/C2Ce9s6+UywJN/0JeXSqwA7bsBqqnfFicVAT0lckLopMLiuzK7dsN
EwhFeqoetciFrDIj9+o0xDMWBZhgNP1u68vURA==

`pragma protect key_keyowner="Metrics Technologies Inc.", key_keyname="DSim", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
R+BI65BKLT0I9hEtsxGnDyM5XY9gzULeTPOSDXvd3KWOzZJAx6C0xlbyZcFZhAEG/QIK2yd0wAi6
IUWxyF/sx3HsqKjhVi5KxnpuXDBOZVoj811O7JukedFVmDW7OHGtBkuiJ5X5irw7mfsEKRQmF/1i
V6lj9HYHZEjxtDeZjACsLY4y1QxWalSKT4HIMOHznBLL8dLbGMlS+ZmFuFn0gcwZavVl7gTkTtkf
W0gn01A9ru7NKsf+iLX0kj4dgItPu9N2g02M1vWQ9UUQEVvfV7lUc7GY1suibrD8aEkhH9S7lZ7n
bFsT4qxyvzg8ML6v4g4v7N6VuyhEtgFgNd725Q==

`pragma protect key_keyowner="Atrenta", key_keyname="ATR-SG-RSA-1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=384)
`pragma protect key_block
jNUVKiwH68vHsU54idgvKwaVJcoxTUuxfgrQpbpmM/IpesWA3wHsGzYClwAxkKzw3KRnFyQqTWcZ
yj1EQ2CMBxlJ0kyNbZW8OK8pXzeigToZ0U6Aq3Gy+j7wBbhe83wE1Ygn82sK8dHTEulvaRLn/c5r
ispy1s7jMKIvYNzoUuZrgyBQyfaYmdqUia8XlQjFd+VwzhTXKwzvmaqHWyaHjfBKeCooO7+oUxMG
OJg83W54EVe9ronFQ8Wr9EOL8ia7qelCAgyQe/bC0HHCoMAm8apI7sX23iMR/wMiPP5V2bQzycy+
rBX/+SWkqSeIE1FLm+muFPvrE7iLwJaW8d1fzdFFjAZ5aIXArbWNfwbK8S0TczXc9lEzmpb69rwA
UJIrs4alo81qGQ32UFhjuMQjX75O9Od1HWHDj5PFaT/Ja5Ly+bK8Cc3gfO6dCE81m7d+B2JBZ/Hl
tBA19QuOAYwT2EIPOdpaVtCULb33cWODWu3qQFhZMmDzKTb3kwpcr0LL

`pragma protect key_keyowner="Cadence Design Systems.", key_keyname="CDS_RSA_KEY_VER_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
MnzcA2swaxH1LRacKDou0ZmiiMRETbWIdHgeBgyQz7ILronsXLoB/C20WuFNGEVSiL2/51EZ6MXZ
vMHI8fFcMQCJcuTBDBibUMKv6bXI9s8fTbtrBZppbF/R1icG5JYhqmX4aRnv4W/dxJRjI2L35nLN
Y48E9OfgfkD1sr+IRwx8WEKFmUhuk8dLe0VOK7ywe3XEcneYvrz+HhPj16bGmNfMwNnDgZ3gKKZD
hRnys+jzvAX3HyISrErWXhMKrhWMxXeTNFJCqNQ0LWAVHQYwyKnF5xVpyXSuGNSIrva+QXqOrZBG
3VNLirNVtMRiKLfwZeMaqvswkqBDAa53utlAAA==

`pragma protect key_keyowner="Synplicity", key_keyname="SYNP15_1", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
d0xXkKtsKM8GvXhDZr16p1+oE3uBtD04BJ76eGGIEj/CFECfHVy9qsJ43oSKjas0+AJr4GFFnVb6
X7gJV6MmX/OboC9ier5joUCGz0mxVzkRZK9a+LPEDcg0K6+cLE36kr+FfxW9Uk2816EHBCMCf5mK
A4eAhSmAb5Nq74F/q0quiG416npbny7faiQ+xmPDfYYiM3UuMKaD4iE8ODlz1w5xThPllWESf3LZ
NTkw6fozyTqZ47vvE21O3dgIGAY1v+C6BwlCK24VwPJa1xs9csY+qTk31j5jjAc1ExlB6QF7t9UH
lk70qdNPWxT87OH7kFT8UvPO1D6BTC3/WkDZfA==

`pragma protect key_keyowner="Mentor Graphics Corporation", key_keyname="MGC-PREC-RSA", key_method="rsa"
`pragma protect encoding = (enctype="BASE64", line_length=76, bytes=256)
`pragma protect key_block
LYhdzKTvo93uJrAaiP5OfCDuOnu2BSvPnxlv6I7h2n1+xHtj34LNNKzWEgOg9dUV9cYDaHYUjjEt
DKdWcz6mZ61d5qyxAhpv67fc90v7JVgtOAcT94/Yb+AuLxXFcGA6Gic7uoJtUgz6JmTnb22Dxdjc
KuIewDj4IOTfP8XGXKTaF+cNp0CFrQgTAcVSQFyLFxr0I/9h3S+GZLecA7ntEeHEOfCJzPvy0ddi
7MCdQWECLb+fXC0IAn8V95TumcpINiRAX1BHi9IGJ4QoMrb3jOCrPkFhDMTJj2aiImUWdi/l/0QE
d7wcXlgIEYVeoKYUOJ4mqy+zZPUbLNeOPADUDQ==

`pragma protect data_method = "AES128-CBC"
`pragma protect encoding = (enctype = "BASE64", line_length = 76, bytes = 59568)
`pragma protect data_block
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
43pI
`pragma protect end_protected
`ifndef GLBL
`define GLBL
`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;
    parameter GRES_WIDTH = 10000;
    parameter GRES_START = 10000;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    wire GRESTORE;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;
    wire FCSBO_GLBL;
    wire [3:0] DO_GLBL;
    wire [3:0] DI_GLBL;
   
    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;
    reg GRESTORE_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (strong1, weak0) GSR = GSR_int;
    assign (strong1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;
    assign (strong1, weak0) GRESTORE = GRESTORE_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

    initial begin 
	GRESTORE_int = 1'b0;
	#(GRES_START);
	GRESTORE_int = 1'b1;
	#(GRES_WIDTH);
	GRESTORE_int = 1'b0;
    end

endmodule
`endif
