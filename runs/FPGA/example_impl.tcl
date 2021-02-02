source ./../../ips/Xi_Phy/ip_setup.tcl

file mkdir IMPL

create_project -in_memory
set_part $PART

#set IP_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/IP/mig_phy
#set IMPL_RES_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/IMPL
#set SYNTH_RES_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/SYNTH
#set CONST_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/CONST

cd $IP_PATH
set_property ip_output_repo ./mig_phy.cache/ip [current_project]
set_property ip_cache_permissions {read write} [current_project]
set_property XPM_LIBRARIES XPM_MEMORY [current_project]

cd $CONST_PATH
#read_xdc example_design_ADM_9V3.xdc
#set_property processing_order LATE [get_files example_design_ADM_9V3.xdc]
read_xdc example_design.xdc
set_property processing_order LATE [get_files example_design.xdc]


cd $SYNTH_RES_PATH
add_file ./example_top_synth.dcp

cd $IP_PATH
read_ip -quiet ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci
read_ip -quiet ./../../../Xi_BRAM/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci
read_ip -quiet ./../../../Xi_BRAM/IP/bram_528x64/bram_528x64.srcs/sources_1/ip/blk_mem_gen_528x64/blk_mem_gen_528x64.xci
read_ip -quiet ./../../../Xi_BRAM/IP/bram_528x8/bram_528x8.srcs/sources_1/ip/blk_mem_gen_528x8/blk_mem_gen_528x8.xci
read_ip -quiet ./../../../Xi_BRAM/IP/bram_52x4/bram_52x4.srcs/sources_1/ip/blk_mem_gen_52x4/blk_mem_gen_52x4.xci
# disabling auto generated example_design.xdc file
set ex_xdc [get_files -all -of_objects [get_files ./mig_phy.srcs/sources_1/ip/ddr4_0/ddr4_0.xci] -filter {name =~ "*example_design.xdc"}]
set_property is_enabled false [get_files $ex_xdc]



link_design -top tb_ddr4_ch_ctrl

cd $IMPL_RES_PATH
write_hwdef -force -file example_top.hwdef

opt_design -aggressive_remap -bufg_opt > impl.log
write_checkpoint -force example_top_opt.dcp
report_drc -file example_top_drc_opted.rpt -pb example_top_drc_opted.pb -rpx example_top_drc_opted.rpx

place_design -directive ExtraNetDelay_high >> impl.log
#place_design >> impl.log
place_design -post_place_opt >> impl.log
phys_opt_design  -directive AggressiveExplore
write_checkpoint -force example_top_placed.dcp
report_io -file example_top_io_placed.rpt
report_utilization -file example_top_utilization_placed.rpt -pb example_top_utilization_placed.pb
report_control_sets -verbose -file example_top_control_sets_placed.rpt

route_design >> impl.log
write_checkpoint -force example_top_routed.dcp
write_verilog example_top_impl.v -force -mode design
report_drc -file example_top_drc_routed.rpt -pb example_top_drc_routed.pb -rpx example_top_drc_routed.rpx
report_methodology -file example_top_methodology_drc_routed.rpt -pb example_top_methodology_drc_routed.pb -rpx example_top_methodology_drc_routed.rpx
report_power -file example_top_power_routed.rpt -pb example_top_power_summary_routed.pb -rpx example_top_power_routed.rpx
report_route_status -file example_top_route_status.rpt -pb example_top_route_status.pb
report_timing_summary -max_paths 10 -file example_top_timing_summary_routed.rpt -pb example_top_timing_summary_routed.pb -rpx example_top_timing_summary_routed.rpx -warn_on_violation
report_incremental_reuse -file example_top_incremental_reuse_routed.rpt
report_clock_utilization -file example_top_clock_utilization_routed.rpt
report_bus_skew -warn_on_violation -file example_top_bus_skew_routed.rpt -pb example_top_bus_skew_routed.pb -rpx example_top_bus_skew_routed.rpx
