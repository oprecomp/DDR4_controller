###############################################################################
# TU KL MIG Phy IP Generator Script
# AUTHOR: Chirag Sudarshan
# DATE  : 30.11.2019
# Script: Mig_phy_only_ip.tcl
###############################################################################

source ip_setup.tcl

file mkdir IP/mig_phy

create_project -force mig_phy IP/mig_phy -part $PART
create_ip -name ddr4 -vendor xilinx.com -library ip -version 2.2 -module_name $IP_NAME
#set_property -dict [list CONFIG.Phy_Only {Phy_Only_Single} CONFIG.C0.DDR4_TimePeriod {1250} CONFIG.C0.DDR4_InputClockPeriod {3334} CONFIG.C0.DDR4_CLKOUT0_DIVIDE {6} CONFIG.C0.DDR4_MemoryType {Components} CONFIG.C0.DDR4_MemoryPart {MT40A1G8PM-075E} CONFIG.C0.DDR4_DataWidth {64} CONFIG.C0.DDR4_CasLatency {11} CONFIG.C0.DDR4_CasWriteLatency {11}] [get_ips $IP_NAME]
set_property -dict [list CONFIG.Phy_Only {Phy_Only_Single} CONFIG.C0.DDR4_TimePeriod {1250} CONFIG.C0.DDR4_InputClockPeriod {5000} CONFIG.C0.DDR4_CLKOUT0_DIVIDE {7} CONFIG.C0.DDR4_MemoryType {Components} CONFIG.C0.DDR4_MemoryPart {MT40A1G8PM-075E} CONFIG.C0.DDR4_DataWidth {64} CONFIG.C0.DDR4_CasLatency {11} CONFIG.C0.DDR4_CasWriteLatency {11}] [get_ips $IP_NAME]


generate_target {instantiation_template} [get_files $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci]
#update_compile_order -fileset sources_1

generate_target all [get_files $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci]

catch { config_ip_cache -export [get_ips -all $IP_NAME] }

export_ip_user_files -of_objects [get_files $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci] -no_script -sync -force -quiet

create_ip_run [get_files -of_objects [get_fileset sources_1] $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci]

launch_runs -jobs 4 ${IP_NAME}_synth_1

generate_target {example} [get_files $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci]

#move the files in folder tb/ddr4_model/ to tb. This is done for simulation, as the auto gen sim scripts expects dram model files in tb folder
set contents [glob -directory $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/tb/ddr4_model/ * ]
foreach item $contents {
	file copy $item $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/tb/ddr_model/.. }

#move the files in folder tb/ddr4_model/ to tb. This is done for simulation, as the auto gen sim scripts expects dram model files in tb folder
#file copy  $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/tb/ddr_model/ $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/tb/

set projDir [get_property DIRECTORY [current_project]]
set importDir [file join $projDir imports]
puts $importDir
file mkdir $importDir

set_property TOP [lindex [find_top] 0] [current_fileset]

#export_ip_user_files -no_script -force

#compile_simlib -simulator modelsim -simulator_exec_path {C:/modeltech64_2019.1/win64} -family all -language all -library all -dir {$sim_lib_path} -force

export_simulation -of_objects [get_files $IP_DIR/IP/mig_phy/mig_phy.srcs/sources_1/ip/$IP_NAME/${IP_NAME}.xci] -simulator modelsim -directory $IP_DIR/IP/mig_phy/mig_phy.ip_user_files/sim_scripts -ip_user_files_dir $IP_DIR/IP/mig_phy/mig_phy.ip_user_files -ipstatic_source_dir $IP_DIR/IP/mig_phy/mig_phy.ip_user_files/ipstatic -lib_map_path $SIM_LIB_PATH -use_ip_compiled_libs -force -quiet

#export_simulation  -lib_map_path "c:/Users/chirag/project_3/project_1.cache/compile_simlib/modelsim" -directory "SIM" -simulator modelsim -use_ip_compiled_libs

#this is only a fix for windows PC . On linux PC this line will not make any difference
file mkdir $IP_DIR/IP/mig_phy/mig_phy.ip_user_files/sim_scripts/$IP_NAME/modelsim/modelsim_lib

close_project
