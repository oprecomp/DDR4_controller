source ./../../ips/Xi_Phy/ip_setup.tcl

file mkdir BIT
set_part $PART

#set IP_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/IP/mig_phy
#set IMPL_RES_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/IMPL
#set BIT_RES_PATH c:/MyFiles/chirag/projects/FPGA_ctrl/try/mig_phy_only_ip_ex/BIT

cd $IMPL_RES_PATH
open_checkpoint example_top_routed.dcp

cd $IP_PATH
add_file ./mig_phy.srcs/sources_1/ip/ddr4_0/sw/calibration_0/Debug/calibration_ddr.elf
set_property SCOPED_TO_REF ddr4_0 [get_files -all ./mig_phy.srcs/sources_1/ip/ddr4_0/sw/calibration_0/Debug/calibration_ddr.elf]

set_property SCOPED_TO_CELLS inst/u_ddr_cal_riu/mcs0/inst/microblaze_I [get_files -all ./mig_phy.srcs/sources_1/ip/ddr4_0/sw/calibration_0/Debug/calibration_ddr.elf]

cd $BIT_RES_PATH
catch { write_mem_info -force example_top.mmi }
  write_bitstream -force example_top.bit 
  catch { write_sysdef -hwdef example_top.hwdef -bitfile example_top.bit -meminfo example_top.mmi -file example_top.sysdef }
  catch {write_debug_probes -quiet -force example_top}
catch {file copy -force example_top.ltx debug_nets.ltx}				  
