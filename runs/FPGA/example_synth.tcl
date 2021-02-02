source ./../../ips/Xi_Phy/ip_setup.tcl

file mkdir SYNTH

create_project -in_memory
set_part $PART

#set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

#set IP_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/IP/mig_phy
#set SYNTH_RES_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/SYNTH
#set CONST_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/CONST


cd $IP_PATH
set_property ip_output_repo ./mig_phy.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]

read_verilog -sv {
    ../../../axi_slice/axi_ar_buffer.sv
    ../../../axi_slice/axi_aw_buffer.sv
    ../../../axi_slice/axi_b_buffer.sv
    ../../../axi_slice/axi_r_buffer.sv
    ../../../axi_slice/axi_w_buffer.sv
    ../../../ems_lib/comp_sel_grt/comp_sel_grt.sv
    ../../../ems_lib/demux_1_4/demux_1_4.sv
    ../../../ems_lib/generic_fifo/generic_fifo.sv
    ../../../ems_lib/generic_fifo/bram_fifo_528x64.sv
    ../../../ems_lib/generic_fifo/bram_fifo_512x64.sv
    ../../../ems_lib/generic_fifo/bram_fifo_528x8.sv
    ../../../ems_lib/generic_fifo/bram_fifo_52x4.sv
    ../../../ems_lib/dual_clock_fifo/dual_clock_fifo.sv
    ../../../ems_lib/mux_generic/mux_generic.sv
    ../../../ems_lib/min_generic/lowest_nr_identifier.sv
    ../../../ems_lib/priority_arbiter_generic/priority_arbiter_generic.sv
    ../../../ems_lib/priority_arbiter_generic/priority_mux.sv
    ../../../ems_lib/priority_arbiter_generic/priority_encoder.sv
    ../../../ems_lib/pulp_clock_gating/pulp_clock_gating.sv
    ../../../ems_lib/lfsr/lfsr_gen.sv
    ../../../ems_lib/mem_tgen_checker/mem_tgen_checker.sv
    ../../../../implementation/syn/bankfsm_cmdmux_if/bankfsm_cmdmux_if.sv
    ../../../../implementation/syn/config_bus_slave/reg_bus_pkg.sv
    ../../../../implementation/syn/config_bus_slave/reg_bus_if.sv
    ../../../../implementation/syn/config_bus_slave/config_bus_slave.sv
    ../../../../implementation/syn/mem_ctrl/mem_ctrl_if.sv
    ../../../../implementation/syn/congen/congen.v
    ../../../../implementation/syn/axi_dram_if/axi_dram_if.sv
    ../../../../implementation/syn/ch_ctrl/ch_ctrl.sv
    ../../../../implementation/syn/ch_ctrl_bank_fsm/ch_ctrl_bank_fsm.sv
    ../../../../implementation/syn/bus_shuffler_4/bus_shuffler_4.sv
    ../../../../implementation/syn/cmd_mux/cmd_mux.sv
    ../../../../implementation/syn/ch_ctrl_rank_fsm/ch_ctrl_rank_fsm.sv
    ../../../../implementation/syn/ch_ctrl_rank_fsm/ch_ctrl_rank_fsm_wrapper.sv
    ../../../../implementation/syn/xiphy_if/bit_packing_xiphy_ultrascale.sv	
    ../../../../implementation/syn/xiphy_if/xiphy_ultrascale_if.sv	
    ../../../../validation/tb_ddr4_ch_ctrl/tb_ddr4_ch_ctrl.sv
}

read_ip -quiet ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci

# get all constraints files of the IP and do not include it in the resulting dcp file of this sysnthesis run output as its is already included in the dcp of the IP. When the dcp of IP is stiched to the design during implementation so does the IP contraints.
set xdc [get_files -all -of_objects [get_files ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci] -filter {name =~ "*.xdc"}]
puts $xdc
set_property used_in_implementation false [get_files $xdc]

# disabling auto generated example_design.xdc file
set ex_xdc [get_files -all -of_objects [get_files ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci] -filter {name =~ "*example_design.xdc"}]
set_property is_enabled false [get_files $ex_xdc]

# get all dcp files of the IP (balck box) and do not stictch it to the resulting dcp file of this sysnthesis run output (i.e OOC(Out of context) flow).  These dcp's are considered during the implemetation. This is a typical for OOC flow, also practiced in mig. 
set dcp [get_files -all -of_objects [get_files ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci] -filter {name =~ "*.dcp"}]
puts $dcp
set_property used_in_implementation false [get_files $dcp]

#foreach dcpn [get_files -quiet -all -filter file_type=="Design\ Checkpoint"] {
#    puts $dcpn
#  set_property used_in_implementation false $dcpn
#}

#### BRAM IP#####
read_ip -quiet ./../../../Xi_BRAM/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci

set_property used_in_implementation false [get_files -all ./../../../Xi_BRAM/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0_ooc.xdc]

read_ip -quiet ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.srcs/sources_1/ip/blk_mem_gen_528x64/blk_mem_gen_528x64.xci

set_property used_in_implementation false [get_files -all ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.srcs/sources_1/ip/blk_mem_gen_528x64/blk_mem_gen_528x64_ooc.xdc]

read_ip -quiet ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.srcs/sources_1/ip/blk_mem_gen_528x8/blk_mem_gen_528x8.xci

set_property used_in_implementation false [get_files -all ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.srcs/sources_1/ip/blk_mem_gen_528x8/blk_mem_gen_528x8_ooc.xdc]

read_ip -quiet ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.srcs/sources_1/ip/blk_mem_gen_52x4/blk_mem_gen_52x4.xci

set_property used_in_implementation false [get_files -all ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.srcs/sources_1/ip/blk_mem_gen_52x4/blk_mem_gen_52x4_ooc.xdc]

# Mark all dcp files as not used in implementation to prevent them from being
# stitched into the results of this synthesis run. Any black boxes in the
# design are intentionally left as such for best results. Dcp files will be
# stitched into the design at a later time, either when this synthesis run is
# opened, or when it is stitched into a dependent implementation run.

set dcp [get_files -all -of_objects [get_files ./../../../Xi_BRAM/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -filter {name =~ "*.dcp"}]
puts $dcp
set_property used_in_implementation false [get_files $dcp]

set dcp [get_files -all -of_objects [get_files ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.srcs/sources_1/ip/blk_mem_gen_528x64/blk_mem_gen_528x64.xci] -filter {name =~ "*.dcp"}]
puts $dcp
set_property used_in_implementation false [get_files $dcp]

set dcp [get_files -all -of_objects [get_files ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.srcs/sources_1/ip/blk_mem_gen_528x8/blk_mem_gen_528x8.xci] -filter {name =~ "*.dcp"}]
puts $dcp
set_property used_in_implementation false [get_files $dcp]

set dcp [get_files -all -of_objects [get_files ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.srcs/sources_1/ip/blk_mem_gen_52x4/blk_mem_gen_52x4.xci] -filter {name =~ "*.dcp"}]
puts $dcp
set_property used_in_implementation false [get_files $dcp]

##### END BRAM#####


set_property used_in_implementation false [get_files -all ./mig_phy.srcs/sources_1/ip/ddr4_0/sw/calibration_0/Debug/calibration_ddr.elf]

set_property used_in_implementation false [get_files -all ./mig_phy.srcs/sources_1/ip/ddr4_0/ip_0/mb_bootloop_le.elf]

set_property used_in_implementation false [get_files -all ./mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_0/data/mb_bootloop_le.elf]

cd $CONST_PATH
#read_xdc ./example_design_ADM_9V3.xdc
#set_property used_in_implementation false [get_files ./example_design_ADM_9V3.xdc]
#set_property processing_order LATE [get_files ./example_design_ADM_9V3.xdc]
read_xdc ./example_design.xdc
set_property used_in_implementation false [get_files ./example_design.xdc]
set_property processing_order LATE [get_files ./example_design.xdc]

cd $IP_PATH
read_xdc ./mig_phy.runs/ddr4_0_synth_1/dont_touch.xdc
set_property used_in_implementation false [get_files ./mig_phy.runs/ddr4_0_synth_1/dont_touch.xdc]

read_xdc ./../../../Xi_BRAM/IP/bram_512x64/bram.runs/blk_mem_gen_0_synth_1/dont_touch.xdc
set_property used_in_implementation false [get_files ./../../../Xi_BRAM/IP/bram_512x64/bram.runs/blk_mem_gen_0_synth_1/dont_touch.xdc]

read_xdc ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.runs/blk_mem_gen_528x64_synth_1/dont_touch.xdc
set_property used_in_implementation false [get_files ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.runs/blk_mem_gen_528x64_synth_1/dont_touch.xdc]

read_xdc ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.runs/blk_mem_gen_528x8_synth_1/dont_touch.xdc
set_property used_in_implementation false [get_files ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.runs/blk_mem_gen_528x8_synth_1/dont_touch.xdc]

read_xdc ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.runs/blk_mem_gen_52x4_synth_1/dont_touch.xdc
set_property used_in_implementation false [get_files ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.runs/blk_mem_gen_52x4_synth_1/dont_touch.xdc]

cd $SYNTH_RES_PATH
file mkdir .Xil
synth_design -top tb_ddr4_ch_ctrl -flatten_hierarchy rebuilt -include_dirs  ../../../validation/tb_ddr4_ch_ctrl/ -verilog_define FPGA -verilog_define DDR4 -verilog_define SYNTHESIS -verilog_define PULP_FPGA_EMUL -verilog_define NEW_TGEN > synth.log
# disable binary constraint mode for synth run checkpoints
set_param constraints.enableBinaryConstraints false
write_xdc -force -file synth.xdc
write_checkpoint -force -noxdef example_top_synth.dcp
write_verilog example_top_synth.v -force -mode design 
report_utilization -file example_top_utilization_synth.rpt -pb example_top_utilization_synth.pb
report_timing_summary -file timing_syn.rpt
