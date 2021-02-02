puts {
  ModelSimSE general compile script version 1.1
  Copyright (c) Doulos June 2004, SD
}
# set mydir [pwd]
# puts $mydir

# Simply change the project settings in this section
# for each new project. There should be no need to
# modify the rest of the script.

source ../../ips/Xi_Phy/ip_setup.tcl

set PHY_PATH  $IP_DIR/IP/mig_phy
set BRAM_PATH  $IP_DIR/../Xi_BRAM/IP
puts $PHY_PATH

set library_file_list "
		       xi_phy {
			       $PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_0/sim/bd_9054_microblaze_I_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_1/sim/bd_9054_rst_0_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_2/sim/bd_9054_ilmb_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_3/sim/bd_9054_dlmb_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_4/sim/bd_9054_dlmb_cntlr_0.vhd \
	    $PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_5/sim/bd_9054_ilmb_cntlr_0.vhd \
	    $PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_6/sim/bd_9054_lmb_bram_I_0.v \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_7/sim/bd_9054_second_dlmb_cntlr_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_8/sim/bd_9054_second_ilmb_cntlr_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_9/sim/bd_9054_second_lmb_bram_I_0.v \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/ip/ip_10/sim/bd_9054_iomodule_0_0.vhd \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/bd_0/sim/bd_9054.v \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_0/sim/ddr4_0_microblaze_mcs.v \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy_behav.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/phy/ddr4_phy_v2_2_xiphy.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/iob/ddr4_phy_v2_2_iob_byte.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/iob/ddr4_phy_v2_2_iob.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/clocking/ddr4_phy_v2_2_pll.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_tristate_wrapper.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_riuor_wrapper.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_control_wrapper.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_byte_wrapper.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/xiphy_files/ddr4_phy_v2_2_xiphy_bitslice_wrapper.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/phy/ddr4_0_phy_ddr4.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/ip_top/ddr4_0_phy.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/example_tb_phy.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/data/dlib/ultrascale/ddr4_sdram/tb/ddrx_cal_mc_odt.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/glbl.v \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/ddr4_model/arch_package.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/ddr4_model/interface.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/ddr4_model/proj_package.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/ddr4_model.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/clocking/ddr4_v2_2_infrastructure.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_xsdb_bram.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_write.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_wr_byte.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_wr_bit.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_sync.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_read.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_rd_en.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_pi.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_mc_odt.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_debug_microblaze.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_cplx_data.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_cplx.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_config_rom.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_addr_decode.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_top.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal_xsdb_arbiter.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_cal.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_chipscope_xsdb_slave.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_v2_2_dp_AB9.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/ip_top/ddr4_0.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal/ddr4_0_ddr4_cal_riu.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/ip_top/ddr4_0_ddr4.sv \
$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/microblaze_mcs_0.sv \
    glbl.v }

    blk_mem_gen {
    			$BRAM_PATH/bram_512x64/bram.ip_user_files/ipstatic/simulation/blk_mem_gen_v8_4.v \
		$BRAM_PATH/bram_512x64/bram.srcs/sources_1/ip/blk_mem_gen_0/sim/blk_mem_gen_0.v \
			$BRAM_PATH/bram_528x64/bram_528x64.ip_user_files/ipstatic/simulation/blk_mem_gen_v8_4.v \
		$BRAM_PATH/bram_528x64/bram_528x64.srcs/sources_1/ip/blk_mem_gen_528x64/sim/blk_mem_gen_528x64.v \
			$BRAM_PATH/bram_528x8/bram_528x8.ip_user_files/ipstatic/simulation/blk_mem_gen_v8_4.v \
		      $BRAM_PATH/bram_528x8/bram_528x8.srcs/sources_1/ip/blk_mem_gen_528x8/sim/blk_mem_gen_528x8.v \
		$BRAM_PATH/bram_52x4/bram_52x4.ip_user_files/ipstatic/simulation/blk_mem_gen_v8_4.v \
	 	$BRAM_PATH/bram_52x4/bram_52x4.srcs/sources_1/ip/blk_mem_gen_52x4/sim/blk_mem_gen_52x4.v \
  		$VIVADO_FOLDER_PATH/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv \
		$VIVADO_FOLDER_PATH/data/ip/xpm/xpm_VCOMP.vhd 
		}

    work {
	../../ips/axi_slice/axi_ar_buffer.sv
	../../ips/axi_slice/axi_aw_buffer.sv
	../../ips/axi_slice/axi_b_buffer.sv
	../../ips/axi_slice/axi_r_buffer.sv
	../../ips/axi_slice/axi_w_buffer.sv
	../../ips/ems_lib/comp_sel_grt/comp_sel_grt.sv
	../../ips/ems_lib/demux_1_4/demux_1_4.sv
	../../ips/ems_lib/generic_fifo/generic_fifo.sv
	../../ips/ems_lib/generic_fifo/bram_fifo_512x64.sv
	../../ips/ems_lib/generic_fifo/bram_fifo_528x64.sv
	../../ips/ems_lib/generic_fifo/bram_fifo_528x8.sv
        ../../ips/ems_lib/generic_fifo/bram_fifo_52x4.sv
	../../ips/ems_lib/dual_clock_fifo/dual_clock_fifo.sv
	../../ips/ems_lib/mux_generic/mux_generic.sv
	../../ips/ems_lib/min_generic/lowest_nr_identifier.sv
	../../ips/ems_lib/priority_arbiter_generic/priority_arbiter_generic.sv
	../../ips/ems_lib/priority_arbiter_generic/priority_mux.sv
	../../ips/ems_lib/priority_arbiter_generic/priority_encoder.sv
	../../ips/ems_lib/pulp_clock_gating/pulp_clock_gating.sv
	../../ips/ems_lib/axi_tgen/params_tgen_axi.sv
	../../ips/ems_lib/axi_tgen/TGEN_AXI_GENERIC.sv
	../../implementation/syn/config_bus_slave/reg_bus_pkg.sv
	../../implementation/syn/config_bus_slave/reg_bus_if.sv
	../../implementation/syn/config_bus_slave/config_bus_slave.sv
	../../implementation/syn/mem_ctrl/mem_ctrl_if.sv
	../../implementation/syn/congen/congen.v
	../../implementation/syn/axi_dram_if/axi_dram_if.sv
	../../implementation/syn/ch_ctrl/ch_ctrl.sv
	../../implementation/syn/ch_ctrl_bank_fsm/ch_ctrl_bank_fsm.sv
	../../implementation/syn/bankfsm_cmdmux_if/bankfsm_cmdmux_if.sv
	../../implementation/syn/bus_shuffler_4/bus_shuffler_4.sv
	../../implementation/syn/cmd_mux/cmd_mux.sv
	../../implementation/syn/mem_ctrl/mem_ctrl.sv
	../../implementation/syn/ch_ctrl_rank_fsm/ch_ctrl_rank_fsm.sv
	../../implementation/syn/ch_ctrl_rank_fsm/ch_ctrl_rank_fsm_wrapper.sv
	../../implementation/syn/mem_ctrl_top/mem_ctrl_top.sv
        ../../implementation/syn/ddr4_mem_ch_top/ddr4_mem_ch_top.sv
        ../../implementation/syn/xiphy_if/bit_packing_xiphy_ultrascale.sv	
        ../../implementation/syn/xiphy_if/xiphy_ultrascale_if.sv	
	tb_ddr4_mem_ch_top.sv}
		      "	

set top_level              work.tb_ddr4_mem_ch_top
#set includes              "+incdir+../../ips/ddr3.phy.verilog/implementation/sim/1G_H70_QIMONDA +incdir+../../ips/ddr3.phy.verilog/implementation/syn/light_phy/"
proc AddWave {} {
    noview wave
    
}
proc DeleteWave {} {
#	delete wave /*
}


# After sourcing the script from ModelSim for the
# first time use these commands to recompile.

proc r  {} {uplevel #0 source run.tcl}
proc rr {} {global last_compile_time
    set last_compile_time 0
    r                   }
proc q  {} {quit -force }

#Does this installation support Tk?
set tk_ok 1
if [catch {package require Tk}] {set tk_ok 0}

# Prefer a fixed point font for the transcript
set PrefMain(font) {Courier 10 roman normal}

# Compile out of date files
set time_now [clock seconds]
if [catch {set last_compile_time}] {
    set last_compile_time 0
}
foreach {library file_list} $library_file_list {
    vlib $library
    vmap work $library
    foreach file $file_list {
	puts $file
	if { $last_compile_time < [file mtime $file] } {
	    if [regexp {.vhdl?$} $file] {
		vcom -93 $file
	    } else {
		vlog -incr -sv $file "+incdir+../../implementation/syn/mem_ctrl/"  "+incdir+$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/ip_1/rtl/map" "+incdir+$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb/ddr4_model" "+incdir+$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/tb" "+incdir+$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/ip_top" "+incdir+$PHY_PATH/mig_phy.srcs/sources_1/ip/ddr4_0/rtl/cal" "+define+DDR4" "+define+FPGA" "+define+SIMULATION" "+define+PULP_FPGA_EMUL" 
	    }
	    set last_compile_time 0
	}
    }
}


set last_compile_time $time_now

# Load the simulation
# Performing a simulation for debug
#eval vopt +acc $top_level -o top
# Performing a simulation for regression
#eval vopt $top_level -o top

eval vsim -voptargs="+acc" -t ps -L microblaze_v11_0_1 -L blk_mem_gen -L xi_phy -L lib_cdc_v1_0_2 -L proc_sys_reset_v5_0_13 -L lmb_v10_v3_0_9 -L lmb_bram_if_cntlr_v4_0_16 -L blk_mem_gen_v8_4_3 -L iomodule_v3_1_4 -L unisims_ver -L unimacro_ver -L secureip -L xpm $top_level xi_phy.glbl

do {wave.do}

# No optimization slow
#eval vsim -t ps $top_level
#eval vsim -t ps $top_level
# If waves are required
#if [llength $wave_patterns] {
#		noview wave
#		foreach pattern $wave_patterns {
				#add wave $pattern
#				$wave_patterns
#		}
#		configure wave -signalnamewidth 1
##		foreach {radix signals} $wave_radices {
##				foreach signal $signals {
##						catch {property wave -radix $radix $signal}
##				}
#		}
#}

#AddWave
DeleteWave
configure wave -signalnamewidth 1

# Run the simulation
run -all

# If waves are required
#if [llength $wave_patterns] {
if $tk_ok {wave zoomfull}
#}

puts {
Script commands are:
  r = Recompile changed and dependent files
 rr = Recompile everything
  q = Quit without confirmation
}

# How long since project began?
if {[file isfile start_time.txt] == 0} {
		set f [open start_time.txt w]
		puts $f "Start time was [clock seconds]"
		close $f
} else {
		set f [open start_time.txt r]
		set line [gets $f]
		close $f
		regexp {\d+} $line start_time
		set total_time [expr ([clock seconds]-$start_time)/60]
		puts "Project time is $total_time minutes"
}

