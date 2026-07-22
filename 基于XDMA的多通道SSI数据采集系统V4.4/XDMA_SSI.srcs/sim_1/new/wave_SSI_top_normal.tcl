restart

remove_wave -quiet *

add_wave /tb_SSI_top_sim/Pcie_refclkp
add_wave /tb_SSI_top_sim/Pcie_rstn
add_wave /tb_SSI_top_sim/dut/bram_clk
add_wave /tb_SSI_top_sim/dut/bram_rst

add_wave /tb_SSI_top_sim/dut/data_acq_en
add_wave /tb_SSI_top_sim/dut/cs_en
add_wave /tb_SSI_top_sim/dut/RX_SIZE
add_wave /tb_SSI_top_sim/dut/Scl_ctrl
add_wave /tb_SSI_top_sim/dut/single_sample
add_wave /tb_SSI_top_sim/dut/irq_sample_depth

add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/current_state
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/next_state
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/current_channel
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/transfer_channel
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/channel_done
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/ping_pang_select
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/channel_write_bytes

add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/ch_fifo_rd_en
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/fifo_rd_fire
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/fifo_read_count
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/fifo_data_valid
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/selected_fifo_count
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/selected_fifo_empty
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/selected_fifo_data

add_wave /tb_SSI_top_sim/dut/s2mm_cmd_tvalid
add_wave /tb_SSI_top_sim/dut/s2mm_cmd_tready
add_wave /tb_SSI_top_sim/dut/s2mm_cmd_tdata
add_wave /tb_SSI_top_sim/dut/s2mm_write_addr

add_wave /tb_SSI_top_sim/dut/s2mm_tvalid
add_wave /tb_SSI_top_sim/dut/s2mm_tready
add_wave /tb_SSI_top_sim/dut/s2mm_tlast
add_wave /tb_SSI_top_sim/dut/s2mm_tkeep
add_wave /tb_SSI_top_sim/dut/s2mm_tdata
add_wave /tb_SSI_top_sim/dut/ssi_axis_arbiter_ins/line_transferred

add_wave /tb_SSI_top_sim/dut/s2mm_sts_tvalid
add_wave /tb_SSI_top_sim/dut/s2mm_sts_tready
add_wave /tb_SSI_top_sim/dut/s2mm_sts_tdata
add_wave /tb_SSI_top_sim/dut/s2mm_last_status
add_wave /tb_SSI_top_sim/dut/s2mm_status_error
add_wave /tb_SSI_top_sim/dut/s2mm_block_count

add_wave /tb_SSI_top_sim/dut/arb_interrupt
add_wave /tb_SSI_top_sim/dut/arb_irq_pending_count
add_wave /tb_SSI_top_sim/dut/arb_irq_queue_full
add_wave /tb_SSI_top_sim/dut/arb_completed_bank_sel
add_wave /tb_SSI_top_sim/dut/usr_irq_req
add_wave /tb_SSI_top_sim/dut/usr_irq_ack
add_wave /tb_SSI_top_sim/dut/clear_int_en
add_wave /tb_SSI_top_sim/dut/irq_debug_status
add_wave /tb_SSI_top_sim/dut/led

run 200 us
wave zoom full
