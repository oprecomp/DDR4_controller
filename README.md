# SYSTEM-VERILOG CODE for DDR4 Memory Controller with XILINX Phy

Designed by: TU Kaiserslatern (https://ems.eit.uni-kl.de/)

This is the first FPGA version of a DDR4 memory controller for Transprecision Computing.  This DDR4 controller is migrated from our DDR3 memory controller that was originally desined as an ASIC IP. In the future, we will optimize the design for different FPGA platforms.

## Folder Organization
* bitstreams <-- FPGA bit files and debug files for various boards 
* doc <-- Documentation of the DRAM-Controller
* implementation/syn <-- RTL-Models
* ips <-- contains submodules, shared design libraries and proprietary test modules 
* validation <-- Holds all Testbenchs (each Testbench has its own folder)

## Xilinx Phy IP generation, BRAM IP generation and setting up libraries for simulation
### Requirements:
* Vivado 2019.1
* Modelsim 2019.1 64-bit

### Configuration:
* Open file ips/Xi_Phy/ip_setup.tcl
* Open file ips/Xi_BRAM/ip_setup.tcl
* Configure MEMCTRL_DIR  : Path where our DDR4 controller (dram.ctrl.verilog) is cloned. Enter the full path including "DDR4_controller"
* Configure SIM_LIB_PATH (optional) : Path where you would like to store the Xilinx specific simulation library for Modelsim. Default config is correct.
* If you have the pre-compiled library for Modelsim, then set SIM_LIB_PATH to that path. Also copy modelsim.ini file to validation/tb_ddr4_mem_ch_top folder and validation/tb_ddr4_ch_ctrl folder
* Configure MODELSIM_EXE_PATH : Folder where the modelsim execution is located. Eg. "C:/modeltech64_2019.1/win64"
* Configure VIVADO_FOLDER_PATH : Vivado source directory. Eg. "C:/Xilinx/Vivado/2019.1"
* Configure PART to used FPGA device number.
* Configure IP_NAME (optional)
* Open ips/Xi_Phy/Mig_Phy_only_ip.tcl
* Configure Mig Phy reference clock and DRAM timings. Current configuration corresponds to Reference clk = 200MHz (i.e. HTG-VKUS-V095 Board clk), DRAM clk = 800MHz, DQ = 64, CL = 11 and CWL = 11. For more details refer PG150.

### IP Generation and Sim Lib Setup:
* Open Command prompt or terminal
* Change directory to ips/Xi_Phy: cd <ips/Xi_Phy folder>
* Execute: vivado -mode batch -source Sim_CompileLib.tcl
* Execute: vivado -mode batch -source Mig_phy_only_ip.tcl
* Change directory to ips/Xi_Phy: cd <ips/Xi_BRAM folder>
* Execute: vivado -mode batch -source BRAM_512x64.tcl
* Execute: vivado -mode batch -source BRAM_52x4.tcl
* Execute: vivado -mode batch -source BRAM_528x64.tcl
* Execute: vivado -mode batch -source BRAM_528x8.tcl
* Note that the tcl scripts are tested only on Windows 10 - For linux, please contact Chirag Sudarshan (Sudarshan@eit.uni-kl.de).
* Note: please wait for IP synthesis to be complete. Before proceeding to further steps please wait until the file "\__synthesis_is_complete__" is generated for all the Xilinx IPs. E.g. "ips/Xi_Phy/IP/mig_phy/mig_phy.runs/ddr4_0_synth_1/\__synthesis_is_complete__" , "ips/Xi_BRAM/IP/bram_528x64/bram_528x64.runs/blk_mem_gen_528x64_synth_1/\__synthesis_is_complete__" 

## For Integration
* Refer example Simulation Top of the complete Memory Controller Channel (i.e. TG <-> AXI <-> MEM_CNTRL <-> Xi-PHY <-> DRAM Model) in folder "validation/tb_ddr4_mem_ch_top/tb_ddr4_mem_ch_top.sv"

## Simulation and Testbench
* This version has 2 testbenches a)"validation/tb_ddr4_mem_ch_top/tb_ddr4_mem_ch_top.sv b) "validation/tb_ddr4_ch_ctrl/tb_ddr4_ch_ctrl.sv"
* sys_clk_i frequency (see clock generation in testbench) should be same as the configured CONFIG.C0.DDR4_InputClockPeriod in ips/Xi_Phy/Mig_Phy_only_ip.tcl file.
* Synthesisable testbench (including top) : "validation/tb_ddr4_ch_ctrl/tb_ddr4_ch_ctrl.sv". NEW_TGEN has to be defined in the synthesis tcl scripts.  

## Synthesis, Implementation and Bit file generation.
* XDC File: Store the xdc file in the folder "runs/FPGA/CONST". The example xdc files for FPGA xcvu095-ffvb2104-2-e (i.e. example_design.xdc) and xcvu3p-ffvc1517-2-e (i.e. example_design_ADM_9V3.xdc) can be found in the folder  "runs/FPGA/CONST".
* example_synth.tcl, example_impl.tcl and example_bit.tcl are the example tcl files for Synthesis, Implementation and Bit file generation, respectively. 
* Set the xdc file path in example_synth.tcl (line 128 to line 133) and example_impl.tcl file (line 19 to line 22)
* Synthesis: vivado -mode batch -source example_synth.tcl -> Output files and Logs can be found in folder "SYNTH"
* Implementation: vivado -mode batch -source example_impl.tcl -> Output files and Logs can be found in folder "IMPL"
* Bit File: vivado -mode batch -source example_bit.tcl -> Output files and Logs can be found in folder "BIT"
* This DDR4 controller is tested on FPGA xcvu095-ffvb2104-2-e , HTG-VKUS-V095 board, CT4GSFS824A.C8FBD2 DDR4 DIMM.


## Limitations for this Release
* AXI interface only supports burst-length of one at this moment (AXI slave was taken from one of the previous projects - AXI slave require update and improvements)
* Tested at this moment only with parameters specified in tb_ddr4_ch_ctrl.sv. Change of these parameters require generation of appropriate BRAM IPs and Xi_Phy. 

## TODO
* Enable Power Down
* AXI with variable burst-length
* Latency optimizations.
