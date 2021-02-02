###############################################################################
# TU KL MIG Phy IP Setup
# AUTHOR: Chirag Sudarshan
# DATE  : 15.01.2020
# Script: ip_setup.tcl
###############################################################################

#Full Path of the location where TU-KL memory controller is cloned - Should be configured
set MEMCTRL_DIR C:/MyFiles/chirag/memctrl/Open_source_FPGA/DDR4_controller

#Do not disturb
set IP_DIR $MEMCTRL_DIR/ips/Xi_BRAM

#Set the location for Xilinx specific Modelsim compiled lib - Should be configured
#set SIM_LIB_PATH "C:/Users/chirag/project_3/project_1.cache/compile_simlib/modelsim"
set SIM_LIB_PATH "$MEMCTRL_DIR/validation"

#Set the Modelsim executatble folder path
set MODELSIM_EXE_PATH "C:/modeltech64_2019.1/win64"

#Should be configured
#set PART "xcvu3p-ffvc1517-2-e"
set PART "xcvu095-ffvb2104-2-e"
