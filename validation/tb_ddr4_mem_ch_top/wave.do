onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/clk
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/rst_n
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_addr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_priority
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_id
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_act
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_cas
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_r_w
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_pre
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/bm_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/not_srvd_earliest_act
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/not_srvd_earliest_pre
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ord_qu_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/next_id
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/rm_stall
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_ack
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_grant
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cas_ack
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cas_grant
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cas_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_pre_ack
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_pre_grant
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_pre_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_addr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_n
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cmd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_valid
add wave -noupdate -group cmd_mux -radix unsigned /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_fe_id
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_fe_id_valid
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_write
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_read
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act2act_check
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_act2act
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_act2act_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act2act_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_act2act_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_act2act_slot_ovf
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/isact
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ACT2ACT_CTRL_CYCLES
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ACT2ACT_CTRL_SLOT
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act2act_check_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_act2act_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_act2act_q_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act2act_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_act2act_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_act2act_slot_ovf_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ACT2ACT_CTRL_CYCLES_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ACT2ACT_CTRL_SLOT_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_ccd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas2cas_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/iscas
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/iscas_n
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/iswrite
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/isread
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas2cas_check_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_cas2cas_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_cas2cas_q_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas2cas_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_cas2cas_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_cas2cas_slot_ovf_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/CAS2CAS_CTRL_CYCLES_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/CAS2CAS_CTRL_SLOT_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/wr2rd_check
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_wr2rd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_wr2rd_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/wr2rd_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/write_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_wr2rd_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_wr2rd_slot_ovf
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_DRAM_CYCLES
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_CTRL_CYCLES
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_CTRL_SLOT
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/wr2rd_check_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_wr2rd_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_wr2rd_q_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/wr2rd_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_wr2rd_slot_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_wr2rd_slot_ovf_l
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_DRAM_CYCLES_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_CTRL_CYCLES_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/WR2RD_CTRL_SLOT_L
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/rd2wr_check
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_rd2wr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_rd2wr_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/rd2wr_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/read_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_rd2wr_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/nxt_rd2wr_slot_ovf
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/RD2WR_DRAM_CYCLES
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/RD2WR_CTRL_CYCLES
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/RD2WR_CTRL_SLOT
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/acptd_act_req_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_addr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_grant_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_req_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_cmd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/prev_act_bg
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_addr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_id
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_slot_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/acptd_cas_req_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_slot_earliest
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_slot_earliest_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_req_halt
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_req_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_rw_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/safe_rw
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/prev_cas_r_w
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/latched_prev_cas_r_w
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_cmd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ord_qu_bank_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_send_stall_cas_cmd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_write_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_read_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_inhibit_next_id
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/prev_cas_bg
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/acptd_pre_req_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_slot
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_addr
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_bank
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_grant_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_req_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ispre_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ispre
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/ispre_n
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/same_slot_pre_cas
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/same_slot_pre_act
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cas_slot_plus1
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/act_slot_plus1
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/pre_cmd
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_addr_lcl
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_addr_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_bank_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cmd_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_cmd_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_valid_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_fe_id_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_fe_id_valid_lcl
add wave -noupdate -group cmd_mux -expand /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_n_lcl
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/cmd_mux_act_n_q
add wave -noupdate -group cmd_mux /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux/j
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/clk
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/rst_n
add wave -noupdate -group mem_ctrl_top -radix unsigned /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/AWID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/AWADDR
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/AWLEN
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/AWVALID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/AWREADY
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/WDATA
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/WLAST
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/WVALID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/WREADY
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/BID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/BRESP
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/BVALID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/BREADY
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ARID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ARADDR
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ARVALID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ARREADY
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RDATA
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RRESP
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RLAST
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RVALID
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/RREADY
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_addr
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_bank
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_cmd
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_act_n
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_cas_cmd_id
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_write
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_read
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/cal_done
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_w_data
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_w_grant
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_r_data
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_r_id
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_r_valid
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_r_grant
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_w_valid
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_cas_slot
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_cas_cmd_id_valid
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/ctrl_valid
add wave -noupdate -group mem_ctrl_top /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/reset_n_ctrl
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/sys_rst_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_sys_clk_p
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_sys_clk_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ui_clk_out
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ui_rst_n_out
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/AWID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/AWADDR
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/AWLEN
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/AWVALID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/AWREADY
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/WDATA
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/WLAST
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/WVALID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/WREADY
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/BID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/BRESP
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/BVALID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/BREADY
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ARID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ARADDR
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ARVALID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ARREADY
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RDATA
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RRESP
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RLAST
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RVALID
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/RREADY
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_act_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_adr
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_ba
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_bg
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_cke
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_odt
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_cs_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_ck_t
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_ck_c
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_reset_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_dm_dbi_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_dq
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_dqs_c
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_dqs_t
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_init_calib_complete
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_data_compare_error
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_addr
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_bank
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_cmd
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_data_cmd
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_cas_cmd_id
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_act_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_valid
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_cas_slot
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_write
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_read
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/cal_done
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_w_data
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_w_grant
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_r_data
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_r_id
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/ctrl_r_valid
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_clk
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/c0_ddr4_rst
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/dBufAdr
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/wrData
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/wrDataMask
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/rdData
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/rdDataAddr
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/rdDataEn
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/rdDataEnd
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/per_rd_done
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/rmw_rd_done
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/wrDataAddr
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/wrDataEn
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_ACT_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_ADR
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_BA
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_BG
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_CKE
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_CS_n
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mc_ODT
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mcCasSlot
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mcCasSlot2
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mcRdCAS
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/mcWrCAS
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/winInjTxn
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/winRmw
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/winBuf
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/winRank
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/tCWL
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/dbg_clk
add wave -noupdate -expand -group dut /tb_ddr4_mem_ch_top/dut/gt_data_ready
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rst_n
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/clk
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_req
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_cmd
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_addr
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_data
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_stall
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_read_data
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_read_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_read_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/fe_read_grant
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_addr
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_bank
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_cmd
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_act_n
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_cas_cmd_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_cas_cmd_id_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_write
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_read
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_cas_slot
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/cal_done
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_w_data
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_w_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_w_grant
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_r_data
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_r_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_r_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_r_grant
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/decoder_type
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/bus_rdy_lcl
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/init_done
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/congen_update_q
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/dram_init_addr
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/dram_init_bank
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/dram_init_cmd
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/dram_init_act_n
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_addr
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_bank
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_cmd
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_cas_cmd_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_cas_cmd_id_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_fe_stall
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/r_data
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/r_id
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/r_valid
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/r_grant
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/init_en
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/rm_act_n
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/ctrl_w_grant_sync
add wave -noupdate -group ch_ctrl /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/wr_buffer_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rst_n
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/clk
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/fe_req
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/fe_cmd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/fe_addr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/fe_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/fe_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/read_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/init_done
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/init_en
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_addr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_bank
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_act_n
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_cmd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_valid
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_cas_cmd_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_cas_cmd_id_valid
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_write
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_read
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_cas_slot
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_fsm_state
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bus_rdy
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/decoder_type
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/arefi_cntr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/arefi_cntr_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/AREFI_CTRL_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_done
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_req
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_stack_cnt
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_stack_cnt_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_incr_stack
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_incr_stack_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/near_to_aref
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/stop_aref_cntr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/aref_req_lmr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/RC_DRAM_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/RC_CTRL_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/RP_CTRL_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/RFC_CTRL_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ZQS_CTRL_CYCLES
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/PRE_AREF_CS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/PRE_AREF_NS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/counter_pre_aref_CS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/counter_pre_aref_NS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/pre_aref_done
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_pre_all
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_pre_all_pd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/start_pre_aref
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/start_aref
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/pre_aref_addr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/pre_aref_cmd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/zq_cntr_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/zq_cntr_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rg_req
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rg_req_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rg_done
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bus_rdy_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_req
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_row
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_row_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_row_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_row_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_col
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_col_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_col_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_col_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_bank
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_bank_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_bank_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_bank_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_cmd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_cmd_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_cmd_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_cmd_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ord_fifo_en
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ord_fifo_in
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_id_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_id_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/latched_id_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_priority
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_priority_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_ack
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_stall_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ad_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/congen_out
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_ack_comp
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/CS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/NS
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_bypass
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_en
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_idle
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_prechared
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_fsm_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_addr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_slot
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_priority
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_act
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_cas
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_r_w
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_pre
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/bm_bank
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_act_ack
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_act_grant
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_act_slot
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_cas_ack
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_cas_grant
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_cas_slot
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_pre_ack
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_pre_grant
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_pre_slot
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_stall_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/rm_stall
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/next_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ord_fifo_full_n
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ord_qu_bank
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/ord_fifo_out
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/priority_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/not_srvd_earliest_req_lcl
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/not_srvd_earliest_req_q
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/not_srvd_earliest_act
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/not_srvd_earliest_pre
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_addr
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_bank
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_act_n
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_cmd
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_valid
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_fe_id
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_fe_id_valid
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_write
add wave -noupdate -group rank_fsm /tb_ddr4_mem_ch_top/dut/mem_ctrl_top/mem_ctrl/ch_ctrl/RM/cmd_mux_read
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1192500000 ps} 0} {{Cursor 2} {4366875313 ps} 0}
quietly wave cursor active 2
configure wave -namecolwidth 225
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {31312696 ps}
