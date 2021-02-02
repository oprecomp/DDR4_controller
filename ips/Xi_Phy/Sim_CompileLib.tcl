source ip_setup.tcl

file mkdir $SIM_LIB_PATH/compile_simlib/modelsim
puts $MODELSIM_EXE_PATH
compile_simlib -simulator modelsim -simulator_exec_path $MODELSIM_EXE_PATH -family all -language all -library all -dir $SIM_LIB_PATH/compile_simlib/modelsim -force

cd $SIM_LIB_PATH/compile_simlib/modelsim
file copy modelsim.ini $MEMCTRL_DIR/validation/tb_ddr4_mem_ch_top
file copy modelsim.ini $MEMCTRL_DIR/validation/tb_ddr4_ch_ctrl
