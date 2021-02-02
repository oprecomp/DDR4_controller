source ip_setup.tcl

file mkdir IP/bram_512x64

create_project -force bram IP/bram_512x64 -part $PART
create_ip -name blk_mem_gen -vendor xilinx.com -library ip -version 8.4 -module_name blk_mem_gen_0

set_property -dict [list CONFIG.Memory_Type {Simple_Dual_Port_RAM} CONFIG.Write_Width_A {512} CONFIG.Write_Depth_A {64} CONFIG.Read_Width_A {512} CONFIG.Operating_Mode_A {NO_CHANGE} CONFIG.Enable_A {Always_Enabled} CONFIG.Write_Width_B {512} CONFIG.Read_Width_B {512} CONFIG.Enable_B {Always_Enabled} CONFIG.Register_PortA_Output_of_Memory_Primitives {false} CONFIG.Register_PortB_Output_of_Memory_Primitives {false} CONFIG.Port_B_Clock {200} CONFIG.Port_B_Enable_Rate {100}] [get_ips blk_mem_gen_0]

generate_target {instantiation_template} [get_files $IP_DIR/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]
#update_compile_order -fileset sources_1

generate_target all [get_files  $IP_DIR/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]

catch { config_ip_cache -export [get_ips -all blk_mem_gen_0] }

export_ip_user_files -of_objects [get_files $IP_DIR/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -no_script -sync -force -quiet

create_ip_run [get_files -of_objects [get_fileset sources_1] $IP_DIR/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci]

launch_runs -jobs 4 blk_mem_gen_0_synth_1

export_simulation -of_objects [get_files $IP_DIR/IP/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/blk_mem_gen_0.xci] -simulator modelsim -directory $IP_DIR/IP/bram_512x64/bram.ip_user_files/sim_scripts -ip_user_files_dir $IP_DIR/IP/bram_512x64/bram.ip_user_files -ipstatic_source_dir $IP_DIR/IP/bram_512x64/bram.ip_user_files/ipstatic -lib_map_path $SIM_LIB_PATH -use_ip_compiled_libs -force -quiet