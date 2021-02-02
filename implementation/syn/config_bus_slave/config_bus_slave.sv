`include "light_phy.svh"
module regbus_slave_DDR3config_8bit // DRAM config bus Frames are 8 bit width
  #(
    //parameter type atype = logic,
    parameter ADDR_WIDTH = 9,
    parameter DATA_WIDTH = 8,// don't change
    parameter DRAM_ADDR_WIDTH = 16,
    //Defaults
    parameter RRD_DRAM_CYCLES = 4,
    parameter WTR_DRAM_CYCLES = 4,
    parameter CCD_DRAM_CYCLES = 4,
    parameter RP_DRAM_CYCLES = 6,
    parameter RTP_DRAM_CYCLES = 4,
    parameter WR_DRAM_CYCLES = 6,
    parameter RCD_DRAM_CYCLES = 6,
    parameter RAS_DRAM_CYCLES = 15,
    parameter FAW_DRAM_CYCLES = 16,
    parameter ZQS_DRAM_CYCLES = 64,
    parameter AREFI_DRAM_CYCLES = 2880,//7.8us
    parameter RFC_DRAM_CYCLES = 44,//1Gb 110ns
    parameter CL = 6,
    parameter CWL = 5,
    parameter BL = 8,
    parameter RG_REF_NUM_ROW_PER_REF = 4,
    parameter RG_REF_START_ADDR = 0,
    parameter RG_REF_END_ADDR =2**(15+3)-1,
    parameter RON_DATA = 5'b10011,
    parameter RTT_DATA = 5'b10000,//cRTT_60,
    parameter RON_ADR_CMD = 5'b10011,
    parameter PU_EN_OCD_CAL = 5'b01001,
    parameter PD_EN_OCD_CAL = 5'b01001,
    parameter DISABLE_OCD_CAL = 1'b0,
    parameter DISABLE_DLL_CAL = 1'b0,
    parameter TD_CTRL_N_DATA = 0,
    parameter TD_CTRL_N_ADR_CMD = 0,
    parameter TDQS_TRIM_N_DATA = 0,
    parameter TDQS_TRIM_N_ADR_CMD = 0,
    parameter DELAY_DQS_OFFSET = 0,
    parameter DELAY_CLK_OFFSET = 0,
    parameter MRS_INIT_REG0 = 16'b0000_0101_0010_0000,
    parameter MRS_INIT_REG1 = 16'b0000_0000_0100_0000,
    parameter MRS_INIT_REG2 = 16'b0000_0000_0000_0000,
    parameter MRS_INIT_REG3 = 16'b0000_0000_0000_0000,

    // Defualts to configure gongen for BRC in case of 1Gb device
    parameter CONGEN_CONFIG_C3  = 5'd0,
    parameter CONGEN_CONFIG_C4  = 5'd1,
    parameter CONGEN_CONFIG_C5  = 5'd2,
    parameter CONGEN_CONFIG_C6  = 5'd3,
    parameter CONGEN_CONFIG_C7  = 5'd4,
    parameter CONGEN_CONFIG_C8  = 5'd5,
    parameter CONGEN_CONFIG_C9  = 5'd6,
    parameter CONGEN_CONFIG_C10 = 5'd26,
    //c10 used only for 8 Gb, in such case c10 = d7 and all others are +1
    parameter CONGEN_CONFIG_R0  = 5'd7,
    parameter CONGEN_CONFIG_R1  = 5'd8,
    parameter CONGEN_CONFIG_R2  = 5'd9,
    parameter CONGEN_CONFIG_R3  = 5'd10,
    parameter CONGEN_CONFIG_R4  = 5'd11,
    parameter CONGEN_CONFIG_R5  = 5'd12,
    parameter CONGEN_CONFIG_R6  = 5'd13,
    parameter CONGEN_CONFIG_R7  = 5'd14,
    parameter CONGEN_CONFIG_R8  = 5'd15,
    parameter CONGEN_CONFIG_R9  = 5'd16,
    parameter CONGEN_CONFIG_R10 = 5'd17,
    parameter CONGEN_CONFIG_R11 = 5'd18,
    parameter CONGEN_CONFIG_R12 = 5'd19,
    parameter CONGEN_CONFIG_R13 = 5'd20,
    parameter CONGEN_CONFIG_R14 = 5'd24,
    parameter CONGEN_CONFIG_R15 = 5'd25,
    parameter CONGEN_CONFIG_B0  = 5'd21,
    parameter CONGEN_CONFIG_B1  = 5'd22,
    parameter CONGEN_CONFIG_B2  = 5'd23,
    parameter CONGEN_XOR_SEL = 3'b0
    )
   (
    input 	       rst_n,
    reg_bus_if.slave bus,
    dram_global_timing_if.rp dram_t_rm,
    dram_bank_timing_if.rp dram_t_bm,
    dram_aref_zq_timing_if.rp aref_zq,
    dram_rg_ref_if.rp rg_ref,
    phy_config_if.mem_cntrl phy_cal,
    mode_reg_config_if.rp mode_reg,
    congen_if.rp congen,
    input [7:0]        mc_status,
    input [7:0]        dram_init_status_1,
    input [7:0]        dram_init_status_2,
    input [31:0]       phy_status_reg_1,
    input [31:0]       phy_status_reg_2,
    input 	       time_check_done,
    input 	       time_check_passed,
    input 	       init_done,
    input 	       phy_cal_config_done,
    input 	       mode_reg_config_done,
    output logic       disable_dll_cal,
    output logic       bypass_bus_rdy,
    output logic [8:0] delay_dqs_offset,
    output logic [8:0] delay_clk_offset,
    output logic       time_check_start,
    output logic       phy_cal_reg_update,
    output logic       mode_reg_update,
    output logic       rg_ref_update,
    output logic       congen_update
    );

   localparam NUM_OF_REG_LOG2 = 2**(ADDR_WIDTH-2); // -2 bucause addr are 32 bit granular. but data width is only 8 bit

   logic [NUM_OF_REG_LOG2-1:0] reg_wvalid_lcl;
   logic [NUM_OF_REG_LOG2-1:0][DATA_WIDTH-1:0] reg_wdata_lcl;
   logic [ADDR_WIDTH-1:0] 		       bus_waddr_lcl;
   logic [ADDR_WIDTH-1:0] 		       bus_raddr_lcl;
   logic [8:0] 			       delay_dqs_offset_lcl;
   logic [8:0] 			       delay_clk_offset_lcl;
   logic 				       wready,rready;
   logic 				       werror,rerror;
   logic 				       disable_dll_cal_lcl;
   logic 				       bypass_bus_rdy_lcl;

   dram_global_timing_if dram_t_rm_lcl();
   dram_bank_timing_if dram_t_bm_lcl();
   dram_aref_zq_timing_if aref_zq_lcl();
   dram_rg_ref_if
     #(.DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH)) rg_ref_lcl();
   phy_config_if phy_cal_lcl();
   mode_reg_config_if mode_reg_lcl();
   congen_if congen_lcl();

   always_ff @(posedge bus.clk, negedge rst_n)
     begin
	if(!rst_n) begin
	   dram_t_rm.WTR_DRAM_CYCLES <= WTR_DRAM_CYCLES;
	   dram_t_rm.RRD_DRAM_CYCLES <= RRD_DRAM_CYCLES;
	   aref_zq.AREFI_DRAM_CYCLES <= AREFI_DRAM_CYCLES;
	   aref_zq.RFC_DRAM_CYCLES <= RFC_DRAM_CYCLES;
	   dram_t_rm.FAW_DRAM_CYCLES <= FAW_DRAM_CYCLES;
	   aref_zq.ZQS_DRAM_CYCLES <= ZQS_DRAM_CYCLES;
	   aref_zq.ZQS_DISABLE <= 1'b0;
	   aref_zq.DISABLE_REF <= 1'b0;
	   dram_t_rm.BL <= BL;
	   dram_t_rm.CWL <= CWL;
	   dram_t_rm.CL <= CL;
	   dram_t_bm.RP_DRAM_CYCLES <= RP_DRAM_CYCLES;
	   dram_t_bm.RTP_DRAM_CYCLES <= RTP_DRAM_CYCLES;
	   dram_t_bm.WR_DRAM_CYCLES <= WR_DRAM_CYCLES;
	   dram_t_bm.RCD_DRAM_CYCLES <= RCD_DRAM_CYCLES;
	   dram_t_bm.RAS_DRAM_CYCLES <= RAS_DRAM_CYCLES;
	   rg_ref.start_addr <= RG_REF_START_ADDR;
	   rg_ref.end_addr <= RG_REF_END_ADDR;
	   rg_ref.num_row_per_ref <= RG_REF_NUM_ROW_PER_REF;
	   rg_ref.rrd_dram_clk_cycle <= RRD_DRAM_CYCLES;
	   rg_ref.ras_dram_clk_cycle <= RAS_DRAM_CYCLES;
	   rg_ref.rp_dram_clk_cycle <= RP_DRAM_CYCLES;
	   rg_ref.en <= 1'b0;
	   phy_cal.ron_data <=RON_DATA;
	   phy_cal.rtt_data <=RTT_DATA;
	   phy_cal.ron_adr_cmd <=RON_ADR_CMD;
	   phy_cal.pu_en_ocd_cal <=PU_EN_OCD_CAL;
	   phy_cal.pd_en_ocd_cal <=PD_EN_OCD_CAL;
	   phy_cal.disable_ocd_cal <=DISABLE_OCD_CAL;
	   disable_dll_cal <=DISABLE_DLL_CAL;
	   bypass_bus_rdy <=1'b0;
	   phy_cal.td_ctrl_n_data <=TD_CTRL_N_DATA;
	   phy_cal.tdqs_trim_n_data <=TDQS_TRIM_N_DATA;
	   phy_cal.td_ctrl_n_adr_cmd <=TD_CTRL_N_ADR_CMD;
	   phy_cal.tdqs_trim_n_adr_cmd <=TDQS_TRIM_N_ADR_CMD;
	   delay_dqs_offset <=DELAY_DQS_OFFSET;
	   delay_clk_offset <=DELAY_CLK_OFFSET;
	   mode_reg.mr0 <= MRS_INIT_REG0;
	   mode_reg.mr1 <= MRS_INIT_REG1;
	   mode_reg.mr2 <= MRS_INIT_REG2;
	   mode_reg.mr3 <= MRS_INIT_REG3;
	   congen.c3 <= CONGEN_CONFIG_C3;
	   congen.c4 <= CONGEN_CONFIG_C4;
	   congen.c5 <= CONGEN_CONFIG_C5;
	   congen.c6 <= CONGEN_CONFIG_C6;
	   congen.c7 <= CONGEN_CONFIG_C7;
	   congen.c8 <= CONGEN_CONFIG_C8;
	   congen.c9 <= CONGEN_CONFIG_C9;
	   congen.c10 <= CONGEN_CONFIG_C10;
	   congen.r0 <= CONGEN_CONFIG_R0;
	   congen.r1 <= CONGEN_CONFIG_R1;
	   congen.r2 <= CONGEN_CONFIG_R2;
	   congen.r3 <= CONGEN_CONFIG_R3;
	   congen.r4 <= CONGEN_CONFIG_R4;
	   congen.r5 <= CONGEN_CONFIG_R5;
	   congen.r6 <= CONGEN_CONFIG_R6;
	   congen.r7 <= CONGEN_CONFIG_R7;
	   congen.r8 <= CONGEN_CONFIG_R8;
	   congen.r9 <= CONGEN_CONFIG_R9;
	   congen.r10 <= CONGEN_CONFIG_R10;
	   congen.r11 <= CONGEN_CONFIG_R11;
	   congen.r12 <= CONGEN_CONFIG_R12;
	   congen.r13 <= CONGEN_CONFIG_R13;
	   congen.r14 <= CONGEN_CONFIG_R14;
	   congen.r15 <= CONGEN_CONFIG_R15;
	   congen.b0 <= CONGEN_CONFIG_B0;
	   congen.b1 <= CONGEN_CONFIG_B1;
	   congen.b2 <= CONGEN_CONFIG_B2;
	   congen.xor_sel <= CONGEN_XOR_SEL;
	end // if (bus.rst_n)
	else begin
	   dram_t_rm.WTR_DRAM_CYCLES <= dram_t_rm_lcl.WTR_DRAM_CYCLES;
	   dram_t_rm.RRD_DRAM_CYCLES <= dram_t_rm_lcl.RRD_DRAM_CYCLES;
	   aref_zq.AREFI_DRAM_CYCLES <= aref_zq_lcl.AREFI_DRAM_CYCLES;
	   aref_zq.RFC_DRAM_CYCLES <= aref_zq_lcl.RFC_DRAM_CYCLES;
	   dram_t_rm.FAW_DRAM_CYCLES <= dram_t_rm_lcl.FAW_DRAM_CYCLES;
	   aref_zq.ZQS_DRAM_CYCLES <= aref_zq_lcl.ZQS_DRAM_CYCLES;
	   aref_zq.ZQS_DISABLE <= aref_zq_lcl.ZQS_DISABLE;
	   aref_zq.DISABLE_REF <= aref_zq_lcl.DISABLE_REF;
	   dram_t_rm.BL <= dram_t_rm_lcl.BL;
	   dram_t_rm.CWL <= dram_t_rm_lcl.CWL;
	   dram_t_rm.CL <= dram_t_rm_lcl.CL;
	   dram_t_bm.RP_DRAM_CYCLES <= dram_t_bm_lcl.RP_DRAM_CYCLES;
	   dram_t_bm.RTP_DRAM_CYCLES <= dram_t_bm_lcl.RTP_DRAM_CYCLES;
	   dram_t_bm.WR_DRAM_CYCLES <= dram_t_bm_lcl.WR_DRAM_CYCLES;
	   dram_t_bm.RCD_DRAM_CYCLES <= dram_t_bm_lcl.RCD_DRAM_CYCLES;
	   dram_t_bm.RAS_DRAM_CYCLES <= dram_t_bm_lcl.RAS_DRAM_CYCLES;
	   rg_ref.start_addr <= rg_ref_lcl.start_addr;
	   rg_ref.end_addr <= rg_ref_lcl.end_addr;
	   rg_ref.num_row_per_ref <= rg_ref_lcl.num_row_per_ref;
	   rg_ref.rrd_dram_clk_cycle <= rg_ref_lcl.rrd_dram_clk_cycle;
	   rg_ref.ras_dram_clk_cycle <= rg_ref_lcl.ras_dram_clk_cycle;
	   rg_ref.rp_dram_clk_cycle <= rg_ref_lcl.rp_dram_clk_cycle;
	   rg_ref.en <= rg_ref_lcl.en;
	   phy_cal.ron_data <= phy_cal_lcl.ron_data;
	   phy_cal.rtt_data <= phy_cal_lcl.rtt_data;
	   phy_cal.ron_adr_cmd <= phy_cal_lcl.ron_adr_cmd;
	   phy_cal.pu_en_ocd_cal <= phy_cal_lcl.pu_en_ocd_cal;
	   phy_cal.pd_en_ocd_cal <= phy_cal_lcl.pd_en_ocd_cal;
	   phy_cal.disable_ocd_cal <= phy_cal_lcl.disable_ocd_cal;
	   disable_dll_cal <=disable_dll_cal_lcl;
	   bypass_bus_rdy <=bypass_bus_rdy_lcl;
	   phy_cal.td_ctrl_n_data <= phy_cal_lcl.td_ctrl_n_data;
	   phy_cal.tdqs_trim_n_data <= phy_cal_lcl.tdqs_trim_n_data;
	   phy_cal.td_ctrl_n_adr_cmd <= phy_cal_lcl.td_ctrl_n_adr_cmd;
	   phy_cal.tdqs_trim_n_adr_cmd <= phy_cal_lcl.tdqs_trim_n_adr_cmd;
	   delay_dqs_offset <= delay_dqs_offset_lcl;
	   delay_clk_offset <= delay_clk_offset_lcl;
	   mode_reg.mr0 <= mode_reg_lcl.mr0;
	   mode_reg.mr1 <= mode_reg_lcl.mr1;
	   mode_reg.mr2 <= mode_reg_lcl.mr2;
	   mode_reg.mr3 <= mode_reg_lcl.mr3;
	   congen.c3 <= congen_lcl.c3;
	   congen.c4 <= congen_lcl.c4;
	   congen.c5 <= congen_lcl.c5;
	   congen.c6 <= congen_lcl.c6;
	   congen.c7 <= congen_lcl.c7;
	   congen.c8 <= congen_lcl.c8;
	   congen.c9 <= congen_lcl.c9;
	   congen.c10 <= congen_lcl.c10;
	   congen.r0 <= congen_lcl.r0;
	   congen.r1 <= congen_lcl.r1;
	   congen.r2 <= congen_lcl.r2;
	   congen.r3 <= congen_lcl.r3;
	   congen.r4 <= congen_lcl.r4;
	   congen.r5 <= congen_lcl.r5;
	   congen.r6 <= congen_lcl.r6;
	   congen.r7 <= congen_lcl.r7;
	   congen.r8 <= congen_lcl.r8;
	   congen.r9 <= congen_lcl.r9;
	   congen.r10 <= congen_lcl.r10;
	   congen.r11 <= congen_lcl.r11;
	   congen.r12 <= congen_lcl.r12;
	   congen.r13 <= congen_lcl.r13;
	   congen.r14 <= congen_lcl.r14;
	   congen.r15 <= congen_lcl.r15;
	   congen.b0 <= congen_lcl.b0;
	   congen.b1 <= congen_lcl.b1;
	   congen.b2 <= congen_lcl.b2;
	   congen.xor_sel <= congen_lcl.xor_sel;
	end // else: !if(bus.rst_n)
     end // always_ff @ (posedge bus.clk, negedge bus.rst_n)

   assign bus_waddr_lcl = (bus.valid && bus.write)?bus.addr:reg_bus_pkg::IDLE;
   assign bus_raddr_lcl = (bus.valid && !bus.write)?bus.addr:reg_bus_pkg::IDLE;

   // write block
   always_comb
     begin
	werror = 1'b0;
	mode_reg_update = 1'b0;
	rg_ref_update = 1'b0;
	phy_cal_reg_update = 1'b0;
	time_check_start = 1'b0;
	congen_update = 1'b0;
	reg_wdata_lcl = '0;
	reg_wvalid_lcl = 1'b0;
	  begin
	     case((bus_waddr_lcl >> 2)) // to make it 4 byte addressable for pulp
	       reg_bus_pkg::WTR_RRD:begin
		  reg_wdata_lcl[reg_bus_pkg::WTR_RRD] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::WTR_RRD] = 1'b1;
	       end
	       reg_bus_pkg::CWL_CL:begin
		  reg_wdata_lcl[reg_bus_pkg::CWL_CL] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CWL_CL] = 1'b1;
	       end
	       reg_bus_pkg::RP_RTP:begin
		  reg_wdata_lcl[reg_bus_pkg::RP_RTP] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RP_RTP] = 1'b1;
	       end
	       reg_bus_pkg::WR:begin
		  reg_wdata_lcl[reg_bus_pkg::WR] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::WR] = 1'b1;
	       end
	       reg_bus_pkg::BL_RCD:begin
		  reg_wdata_lcl[reg_bus_pkg::BL_RCD] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::BL_RCD] = 1'b1;
	       end
	       reg_bus_pkg::RAS:begin
		  reg_wdata_lcl[reg_bus_pkg::RAS] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RAS] = 1'b1;
	       end
	       reg_bus_pkg::FAW:begin
		  reg_wdata_lcl[reg_bus_pkg::FAW] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::FAW] = 1'b1;
	       end
	       reg_bus_pkg::ZQS:begin
		  reg_wdata_lcl[reg_bus_pkg::ZQS] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::ZQS] = 1'b1;
	       end
	       reg_bus_pkg::AREF:begin
		  reg_wdata_lcl[reg_bus_pkg::AREF] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::AREF] = 1'b1;
	       end
	       reg_bus_pkg::AREF_1:begin
		  reg_wdata_lcl[reg_bus_pkg::AREF_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::AREF_1] = 1'b1;
	       end
	       reg_bus_pkg::AREF_2:begin
		  reg_wdata_lcl[reg_bus_pkg::AREF_2] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::AREF_2] = 1'b1;
	       end
	       reg_bus_pkg::RFC:begin
		  reg_wdata_lcl[reg_bus_pkg::RFC] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RFC] = 1'b1;
	       end
	       reg_bus_pkg::RFC_1:begin
		  reg_wdata_lcl[reg_bus_pkg::RFC_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RFC_1] = 1'b1;
	       end
	       reg_bus_pkg::TREG_END:begin
		  reg_wdata_lcl = '0;
		  reg_wvalid_lcl = 1'b0;
		  time_check_start = 1'b1;
	       end
	       reg_bus_pkg::DISABLE_REF:begin
		  reg_wdata_lcl[reg_bus_pkg::DISABLE_REF] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DISABLE_REF] = 1'b1;
	       end
	       reg_bus_pkg::DRV_IMP_RON_DATA:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RON_DATA] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RON_DATA] = 1'b1;
	       end
	       reg_bus_pkg::DRV_IMP_RON_ADDR:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RON_ADDR] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RON_ADDR] = 1'b1;
	       end
	       reg_bus_pkg::DRV_IMP_RTT_DATA:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RTT_DATA] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RTT_DATA] = 1'b1;
	       end
	       reg_bus_pkg::DRV_SLEW:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_SLEW] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_SLEW] = 1'b1;
	       end
	       reg_bus_pkg::DRV_DLL_CAL_DIS:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_DLL_CAL_DIS] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_DLL_CAL_DIS] = 1'b1;
	       end
	       reg_bus_pkg::DRV_END:begin
		  reg_wdata_lcl = '0;
		  reg_wvalid_lcl = 1'b0;
		  phy_cal_reg_update = 1'b1;
	       end
	       reg_bus_pkg::DRV_OCD_CAL_PU:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_PU] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_PU] = 1'b1;
	       end
	       reg_bus_pkg::DRV_OCD_CAL_PD:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_PD] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_PD] = 1'b1;
	       end
	       reg_bus_pkg::DRV_OCD_CAL_DIS:begin
		  reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_DIS] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_DIS] = 1'b1;
	       end
	       reg_bus_pkg::BYPASS_BUS_RDY:begin
		  reg_wdata_lcl[reg_bus_pkg::BYPASS_BUS_RDY] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::BYPASS_BUS_RDY] = 1'b1;
	       end
	       reg_bus_pkg::DQS_OFFSET:begin
		  reg_wdata_lcl[reg_bus_pkg::DQS_OFFSET] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DQS_OFFSET] = 1'b1;
	       end
	       reg_bus_pkg::DQS_OFFSET_1:begin
		  reg_wdata_lcl[reg_bus_pkg::DQS_OFFSET_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::DQS_OFFSET_1] = 1'b1;
	       end
	       reg_bus_pkg::CLK_OFFSET:begin
		  reg_wdata_lcl[reg_bus_pkg::CLK_OFFSET] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CLK_OFFSET] = 1'b1;
	       end
	       reg_bus_pkg::CLK_OFFSET_1:begin
		  reg_wdata_lcl[reg_bus_pkg::CLK_OFFSET_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CLK_OFFSET_1] = 1'b1;
	       end
	       reg_bus_pkg::MR0:begin
		  reg_wdata_lcl[reg_bus_pkg::MR0] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR0] = 1'b1;
	       end
	       reg_bus_pkg::MR0_1:begin
		  reg_wdata_lcl[reg_bus_pkg::MR0_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR0_1] = 1'b1;
	       end
	       reg_bus_pkg::MR1:begin
		  reg_wdata_lcl[reg_bus_pkg::MR1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR1] = 1'b1;
	       end
	       reg_bus_pkg::MR1_1:begin
		  reg_wdata_lcl[reg_bus_pkg::MR1_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR1_1] = 1'b1;
	       end
	       reg_bus_pkg::MR2:begin
		  reg_wdata_lcl[reg_bus_pkg::MR2] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR2] = 1'b1;
	       end
	       reg_bus_pkg::MR2_1:begin
		  reg_wdata_lcl[reg_bus_pkg::MR2_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR2_1] = 1'b1;
	       end
	       reg_bus_pkg::MR3:begin
		  reg_wdata_lcl[reg_bus_pkg::MR3] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR3] = 1'b1;
	       end
	       reg_bus_pkg::MR3_1:begin
		  reg_wdata_lcl[reg_bus_pkg::MR3_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::MR3_1] = 1'b1;
	       end
	       reg_bus_pkg::MODE_END:begin
		  reg_wdata_lcl = '0;
		  reg_wvalid_lcl = 1'b0;
		   mode_reg_update = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_START_ADDR:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_START_ADDR] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_START_ADDR] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_START_ADDR_1:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_START_ADDR_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_START_ADDR_1] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_END_ADDR:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_END_ADDR] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_END_ADDR] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_END_ADDR_1:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_END_ADDR_1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_END_ADDR_1] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_NUM_ROW_PER_REF:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_NUM_ROW_PER_REF:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_EN_RASMIN:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_EN_RASMIN] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_EN_RASMIN] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_RP_RRD:begin
		  reg_wdata_lcl[reg_bus_pkg::RG_REF_RP_RRD] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::RG_REF_RP_RRD] = 1'b1;
	       end
	       reg_bus_pkg::RG_REF_END:begin
		  reg_wdata_lcl = '0;
		  rg_ref_update = 1'b1;
		  reg_wvalid_lcl = 1'b0;
	       end
	       reg_bus_pkg::CONGEN_C3:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C3] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C3] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C4:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C4] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C4] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C5:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C5] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C5] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C6:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C6] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C6] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C7:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C7] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C7] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C8:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C8] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C8] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C9:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C9] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C9] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_C10:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_C10] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_C10] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R0:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R0] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R0] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R1:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R1] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R2:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R2] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R2] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R3:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R3] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R3] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R4:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R4] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R4] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R5:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R5] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R5] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R6:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R6] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R6] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R7:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R7] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R7] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R8:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R8] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R8] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R9:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R9] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R9] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R10:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R10] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R10] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R11:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R11] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R11] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R12:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R12] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R12] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R13:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R13] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R13] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R14:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R14] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R14] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_R15:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_R15] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_R15] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_B0:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_B0] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_B0] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_B1:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_B1] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_B1] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_B2:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_B2] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_B2] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_XOR_SEL:begin
		  reg_wdata_lcl[reg_bus_pkg::CONGEN_XOR_SEL] = bus.wdata;
		  reg_wvalid_lcl[reg_bus_pkg::CONGEN_XOR_SEL] = 1'b1;
	       end
	       reg_bus_pkg::CONGEN_END:begin
		  reg_wdata_lcl = '0;
		  congen_update = 1'b1;
		  reg_wvalid_lcl = 1'b0;
	       end
	       default:begin
		  reg_wdata_lcl = '0;
		  reg_wvalid_lcl = 1'b0;
		  werror = bus.valid && bus.write;
	       end
	     endcase // case (addr)
	     wready = bus.valid && bus.write;
	  end // if (bus.valid && bus.write)
     end // always_comb

   assign dram_t_rm_lcl.WTR_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::WTR_RRD])?
					  reg_wdata_lcl[reg_bus_pkg::WTR_RRD][7:4]:
					  dram_t_rm.WTR_DRAM_CYCLES;
   assign dram_t_rm_lcl.RRD_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::WTR_RRD])?
					  reg_wdata_lcl[reg_bus_pkg::WTR_RRD][3:0]:
					  dram_t_rm.RRD_DRAM_CYCLES;
   assign dram_t_rm_lcl.CWL = (!init_done && !time_check_done &&
			       reg_wvalid_lcl[reg_bus_pkg::CWL_CL])?
			      reg_wdata_lcl[reg_bus_pkg::CWL_CL][7:4]:
			      dram_t_rm.CWL;
   assign dram_t_rm_lcl.CL = (!init_done && !time_check_done &&
			      reg_wvalid_lcl[reg_bus_pkg::CWL_CL])?
			     reg_wdata_lcl[reg_bus_pkg::CWL_CL][3:0]:
			     dram_t_rm.CL;
   assign dram_t_bm_lcl.RP_DRAM_CYCLES = (!init_done && !time_check_done &&
					  reg_wvalid_lcl[reg_bus_pkg::RP_RTP])?
					 reg_wdata_lcl[reg_bus_pkg::RP_RTP][7:4]:
					 dram_t_bm.RP_DRAM_CYCLES;
   assign dram_t_bm_lcl.RTP_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::RP_RTP])?
					  reg_wdata_lcl[reg_bus_pkg::RP_RTP][3:0]:
					  dram_t_bm.RTP_DRAM_CYCLES;
   assign dram_t_bm_lcl.WR_DRAM_CYCLES = (!init_done && !time_check_done &&
					  reg_wvalid_lcl[reg_bus_pkg::WR])?
					 reg_wdata_lcl[reg_bus_pkg::WR]:
					 dram_t_bm.WR_DRAM_CYCLES;
   assign dram_t_rm_lcl.BL = (!init_done && !time_check_done &&
			      reg_wvalid_lcl[reg_bus_pkg::BL_RCD])?
			     reg_wdata_lcl[reg_bus_pkg::BL_RCD][7:4]:
			     dram_t_rm.BL;
   assign dram_t_bm_lcl.RCD_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::BL_RCD])?
					  reg_wdata_lcl[reg_bus_pkg::BL_RCD][3:0]:
					  dram_t_bm.RCD_DRAM_CYCLES;
   assign dram_t_bm_lcl.RAS_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::RAS])?
					  reg_wdata_lcl[reg_bus_pkg::RAS]:
					  dram_t_bm.RAS_DRAM_CYCLES;
   assign dram_t_rm_lcl.FAW_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::FAW])?
					  reg_wdata_lcl[reg_bus_pkg::FAW]:
					  dram_t_rm.FAW_DRAM_CYCLES;
   assign aref_zq_lcl.ZQS_DISABLE = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::ZQS])?
					  reg_wdata_lcl[reg_bus_pkg::ZQS][7]:
					  aref_zq.ZQS_DISABLE;
   assign aref_zq_lcl.ZQS_DRAM_CYCLES = (!init_done && !time_check_done &&
					   reg_wvalid_lcl[reg_bus_pkg::ZQS])?
					  reg_wdata_lcl[reg_bus_pkg::ZQS][6:0]:
					  aref_zq.ZQS_DRAM_CYCLES;
   assign aref_zq_lcl.AREFI_DRAM_CYCLES[7:0] = (!init_done && !time_check_done &&
						  reg_wvalid_lcl[reg_bus_pkg::AREF])?
						 reg_wdata_lcl[reg_bus_pkg::AREF]:
						 aref_zq.AREFI_DRAM_CYCLES[7:0];
   assign aref_zq_lcl.AREFI_DRAM_CYCLES[15:8] = (!init_done && !time_check_done &&
						  reg_wvalid_lcl[reg_bus_pkg::AREF_1])?
						 reg_wdata_lcl[reg_bus_pkg::AREF_1]:
						 aref_zq.AREFI_DRAM_CYCLES[15:8];
   assign aref_zq_lcl.AREFI_DRAM_CYCLES[19:16] = (!init_done && !time_check_done &&
						    reg_wvalid_lcl[reg_bus_pkg::AREF_2])?
						   reg_wdata_lcl[reg_bus_pkg::AREF_2][3:0]:
						   aref_zq.AREFI_DRAM_CYCLES[19:16];
   assign aref_zq_lcl.RFC_DRAM_CYCLES[7:0] = (!init_done && !time_check_done &&
						reg_wvalid_lcl[reg_bus_pkg::RFC])?
					       reg_wdata_lcl[reg_bus_pkg::RFC]:
					       aref_zq.RFC_DRAM_CYCLES[7:0];
   assign aref_zq_lcl.RFC_DRAM_CYCLES[8] = (!init_done && !time_check_done &&
						reg_wvalid_lcl[reg_bus_pkg::RFC_1])?
					       reg_wdata_lcl[reg_bus_pkg::RFC_1][0]:
					       aref_zq.RFC_DRAM_CYCLES[8:8];
   assign aref_zq_lcl.DISABLE_REF = (reg_wvalid_lcl[reg_bus_pkg::DISABLE_REF])?
				    reg_wdata_lcl[reg_bus_pkg::DISABLE_REF]:
				     aref_zq.DISABLE_REF;
   assign rg_ref_lcl.start_addr[7:0] = (!init_done &&
					reg_wvalid_lcl[reg_bus_pkg::RG_REF_START_ADDR])?
				       reg_wdata_lcl[reg_bus_pkg::RG_REF_START_ADDR]:
				       rg_ref.start_addr[7:0];
   assign rg_ref_lcl.start_addr[15:8] = (!init_done &&
					reg_wvalid_lcl[reg_bus_pkg::RG_REF_START_ADDR_1])?
				       reg_wdata_lcl[reg_bus_pkg::RG_REF_START_ADDR_1]:
				       rg_ref.start_addr[15:8];
   assign rg_ref_lcl.end_addr[7:0] = (!init_done &&
					reg_wvalid_lcl[reg_bus_pkg::RG_REF_END_ADDR])?
				       reg_wdata_lcl[reg_bus_pkg::RG_REF_END_ADDR]:
				       rg_ref.end_addr[7:0];
   assign rg_ref_lcl.end_addr[15:8] = (!init_done &&
					reg_wvalid_lcl[reg_bus_pkg::RG_REF_END_ADDR_1])?
				       reg_wdata_lcl[reg_bus_pkg::RG_REF_END_ADDR_1]:
				       rg_ref.end_addr[15:8];
   assign rg_ref_lcl.num_row_per_ref = (!init_done &&
					reg_wvalid_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF])?
				       reg_wdata_lcl[reg_bus_pkg::RG_REF_NUM_ROW_PER_REF]:
				       rg_ref.num_row_per_ref;
   assign rg_ref_lcl.en = (!init_done &&
			   reg_wvalid_lcl[reg_bus_pkg::RG_REF_EN_RASMIN])?
			  reg_wdata_lcl[reg_bus_pkg::RG_REF_EN_RASMIN][7]:
			  rg_ref.en;
   assign rg_ref_lcl.ras_dram_clk_cycle = (!init_done &&
					   reg_wvalid_lcl[reg_bus_pkg::RG_REF_EN_RASMIN])?
					  reg_wdata_lcl[reg_bus_pkg::RG_REF_EN_RASMIN][5:0]:
					  rg_ref.ras_dram_clk_cycle;
   assign rg_ref_lcl.rp_dram_clk_cycle = (!init_done &&
					  reg_wvalid_lcl[reg_bus_pkg::RG_REF_RP_RRD])?
					 reg_wdata_lcl[reg_bus_pkg::RG_REF_RP_RRD][7:4]:
					 rg_ref.rp_dram_clk_cycle;
   assign rg_ref_lcl.rrd_dram_clk_cycle = (!init_done &&
					  reg_wvalid_lcl[reg_bus_pkg::RG_REF_RP_RRD])?
					 reg_wdata_lcl[reg_bus_pkg::RG_REF_RP_RRD][3:0]:
					 rg_ref.rrd_dram_clk_cycle;
   assign phy_cal_lcl.ron_data = (!init_done && !phy_cal_config_done &&
				 reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RON_DATA])?
				 reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RON_DATA][4:0]:
				 phy_cal.ron_data;
   assign phy_cal_lcl.ron_adr_cmd = (!init_done && !phy_cal_config_done &&
				    reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RON_ADDR])?
				    reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RON_ADDR][4:0]:
				    phy_cal.ron_adr_cmd;
   assign phy_cal_lcl.rtt_data = (!init_done && !phy_cal_config_done &&
				 reg_wvalid_lcl[reg_bus_pkg::DRV_IMP_RTT_DATA])?
				 reg_wdata_lcl[reg_bus_pkg::DRV_IMP_RTT_DATA][4:0]:
				 phy_cal.rtt_data;
   assign phy_cal_lcl.td_ctrl_n_data = (!init_done && !phy_cal_config_done &&
					 reg_wvalid_lcl[reg_bus_pkg::DRV_SLEW])?
					 reg_wdata_lcl[reg_bus_pkg::DRV_SLEW][5:4]:
					 phy_cal.td_ctrl_n_data;
   assign phy_cal_lcl.tdqs_trim_n_data = (!init_done && !phy_cal_config_done &&
					 reg_wvalid_lcl[reg_bus_pkg::DRV_SLEW])?
					 reg_wdata_lcl[reg_bus_pkg::DRV_SLEW][3:3]:
					 phy_cal.tdqs_trim_n_data;
   assign phy_cal_lcl.td_ctrl_n_adr_cmd = (!init_done && !phy_cal_config_done &&
					  reg_wvalid_lcl[reg_bus_pkg::DRV_SLEW])?
					  reg_wdata_lcl[reg_bus_pkg::DRV_SLEW][2:1]:
					  phy_cal.td_ctrl_n_adr_cmd;
   assign phy_cal_lcl.tdqs_trim_n_adr_cmd = (!init_done && !phy_cal_config_done &&
					    reg_wvalid_lcl[reg_bus_pkg::DRV_SLEW])?
					    reg_wdata_lcl[reg_bus_pkg::DRV_SLEW][0:0]:
					    phy_cal.tdqs_trim_n_adr_cmd;
   assign disable_dll_cal_lcl = (!init_done &&
				 reg_wvalid_lcl[reg_bus_pkg::DRV_DLL_CAL_DIS])?
				reg_wdata_lcl[reg_bus_pkg::DRV_DLL_CAL_DIS][0:0]:
				disable_dll_cal;
   assign phy_cal_lcl.pu_en_ocd_cal = (reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_PU])?
				      reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_PU][4:0]:
				      phy_cal.pu_en_ocd_cal;
   assign phy_cal_lcl.pd_en_ocd_cal = (reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_PD])?
				      reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_PD][4:0]:
				      phy_cal.pd_en_ocd_cal;
   assign phy_cal_lcl.disable_ocd_cal = (reg_wvalid_lcl[reg_bus_pkg::DRV_OCD_CAL_DIS])?
				      reg_wdata_lcl[reg_bus_pkg::DRV_OCD_CAL_DIS][0:0]:
				      phy_cal.disable_ocd_cal;
   assign bypass_bus_rdy_lcl = (reg_wvalid_lcl[reg_bus_pkg::BYPASS_BUS_RDY])?
				      reg_wdata_lcl[reg_bus_pkg::BYPASS_BUS_RDY][0:0]:
				      bypass_bus_rdy;
   assign delay_dqs_offset_lcl[7:0] = (reg_wvalid_lcl[reg_bus_pkg::DQS_OFFSET])?
				      reg_wdata_lcl[reg_bus_pkg::DQS_OFFSET]:
				      delay_dqs_offset[7:0];
   assign delay_dqs_offset_lcl[8] = (reg_wvalid_lcl[reg_bus_pkg::DQS_OFFSET_1])?
				       reg_wdata_lcl[reg_bus_pkg::DQS_OFFSET_1]:
				       delay_dqs_offset[8];
   assign delay_clk_offset_lcl[7:0] = (reg_wvalid_lcl[reg_bus_pkg::CLK_OFFSET])?
				      reg_wdata_lcl[reg_bus_pkg::CLK_OFFSET]:
				      delay_clk_offset[7:0];
   assign delay_clk_offset_lcl[8] = (reg_wvalid_lcl[reg_bus_pkg::CLK_OFFSET_1])?
				       reg_wdata_lcl[reg_bus_pkg::CLK_OFFSET_1]:
				       delay_clk_offset[8];
   assign mode_reg_lcl.mr0[7:0] = (!init_done && !mode_reg_config_done &&
				  reg_wvalid_lcl[reg_bus_pkg::MR0])?
				  reg_wdata_lcl[reg_bus_pkg::MR0]:
				  mode_reg.mr0[7:0];
   assign mode_reg_lcl.mr0[15:8] = (!init_done && !mode_reg_config_done &&
				   reg_wvalid_lcl[reg_bus_pkg::MR0_1])?
				   reg_wdata_lcl[reg_bus_pkg::MR0_1]:
				   mode_reg.mr0[15:8];
   assign mode_reg_lcl.mr1[7:0] = (!init_done && !mode_reg_config_done &&
				  reg_wvalid_lcl[reg_bus_pkg::MR1])?
				  reg_wdata_lcl[reg_bus_pkg::MR1]:
				  mode_reg.mr1[7:0];
   assign mode_reg_lcl.mr1[15:8] = (!init_done && !mode_reg_config_done &&
				   reg_wvalid_lcl[reg_bus_pkg::MR1_1])?
				   reg_wdata_lcl[reg_bus_pkg::MR1_1]:
				   mode_reg.mr1[15:8];
   assign mode_reg_lcl.mr2[7:0] = (!init_done && !mode_reg_config_done &&
				  reg_wvalid_lcl[reg_bus_pkg::MR2])?
				  reg_wdata_lcl[reg_bus_pkg::MR2]:
				  mode_reg.mr2[7:0];
   assign mode_reg_lcl.mr2[15:8] = (!init_done && !mode_reg_config_done &&
				   reg_wvalid_lcl[reg_bus_pkg::MR2_1])?
				   reg_wdata_lcl[reg_bus_pkg::MR2_1]:
				   mode_reg.mr2[15:8];
   assign mode_reg_lcl.mr3[7:0] = (!init_done && !mode_reg_config_done &&
				  reg_wvalid_lcl[reg_bus_pkg::MR3])?
				  reg_wdata_lcl[reg_bus_pkg::MR3]:
				  mode_reg.mr3[7:0];
   assign mode_reg_lcl.mr3[15:8] = (!init_done && !mode_reg_config_done &&
				   reg_wvalid_lcl[reg_bus_pkg::MR3_1])?
				   reg_wdata_lcl[reg_bus_pkg::MR3_1]:
				   mode_reg.mr3[15:8];
   assign congen_lcl.c3 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C3])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C3]:
			  congen.c3;
   assign congen_lcl.c4 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C4])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C4]:
			  congen.c4;
   assign congen_lcl.c5 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C5])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C5]:
			  congen.c5;
   assign congen_lcl.c6 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C6])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C6]:
			  congen.c6;
   assign congen_lcl.c7 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C7])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C7]:
			  congen.c7;
   assign congen_lcl.c8 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C8])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C8]:
			  congen.c8;
   assign congen_lcl.c9 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C9])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C9]:
			  congen.c9;
   assign congen_lcl.c10 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_C10])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_C10]:
			  congen.c10;
   assign congen_lcl.r0 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R0])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R0]:
			  congen.r0;
   assign congen_lcl.r1 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R1])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R1]:
			  congen.r1;
   assign congen_lcl.r2 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R2])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R2]:
			  congen.r2;
   assign congen_lcl.r3 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R3])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R3]:
			  congen.r3;
   assign congen_lcl.r4 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R4])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R4]:
			  congen.r4;
   assign congen_lcl.r5 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R5])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R5]:
			  congen.r5;
   assign congen_lcl.r6 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R6])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R6]:
			  congen.r6;
   assign congen_lcl.r7 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R7])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R7]:
			  congen.r7;
   assign congen_lcl.r8 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R8])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R8]:
			  congen.r8;
   assign congen_lcl.r9 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R9])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R9]:
			  congen.r9;
   assign congen_lcl.r10 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R10])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R10]:
			  congen.r10;
   assign congen_lcl.r11 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R11])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R11]:
			  congen.r11;
   assign congen_lcl.r12 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R12])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R12]:
			  congen.r12;
   assign congen_lcl.r13 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R13])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R13]:
			  congen.r13;
   assign congen_lcl.r14 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R14])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R14]:
			  congen.r14;
   assign congen_lcl.r15 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_R15])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_R15]:
			  congen.r15;
   assign congen_lcl.b0 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_B0])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_B0]:
			  congen.b0;
   assign congen_lcl.b1 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_B1])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_B1]:
			  congen.b1;
   assign congen_lcl.b2 = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_B2])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_B2]:
			  congen.b2;
   assign congen_lcl.xor_sel = (!init_done && reg_wvalid_lcl[reg_bus_pkg::CONGEN_XOR_SEL])?
			  reg_wdata_lcl[reg_bus_pkg::CONGEN_XOR_SEL]:
			  congen.xor_sel;
   assign bus.ready = wready || rready;
   assign bus.error = werror || rerror;
   assign dram_t_rm.CCD_DRAM_CYCLES = CCD_DRAM_CYCLES;

      // read block
   always_comb
     begin
	rerror = 1'b0;
	case((bus_raddr_lcl >> 2))
	  reg_bus_pkg::WTR_RRD:begin
	     bus.rdata = {dram_t_rm.WTR_DRAM_CYCLES,dram_t_rm.RRD_DRAM_CYCLES};
	  end
	  reg_bus_pkg::CWL_CL:begin
	     bus.rdata = {dram_t_rm.CWL,dram_t_rm.CL};
	       end
	  reg_bus_pkg::RP_RTP:begin
	     bus.rdata = {dram_t_bm.RP_DRAM_CYCLES,dram_t_bm.RTP_DRAM_CYCLES};
	  end
	  reg_bus_pkg::WR:begin
	     bus.rdata = {'0,dram_t_bm.WR_DRAM_CYCLES};
	  end
	  reg_bus_pkg::BL_RCD:begin
	     bus.rdata = {dram_t_rm.BL,dram_t_bm.RCD_DRAM_CYCLES};
	  end
	  reg_bus_pkg::RAS:begin
	     bus.rdata = {'0,dram_t_bm.RAS_DRAM_CYCLES};
	  end
	  reg_bus_pkg::FAW:begin
	     bus.rdata = {'0,dram_t_rm.FAW_DRAM_CYCLES};
	  end
	  reg_bus_pkg::ZQS:begin
	     bus.rdata = {aref_zq.ZQS_DISABLE,aref_zq.ZQS_DRAM_CYCLES};
	  end
	  reg_bus_pkg::AREF:begin
	     bus.rdata = {aref_zq.AREFI_DRAM_CYCLES[7:0]};
	  end
	  reg_bus_pkg::AREF_1:begin
	     bus.rdata = {aref_zq.AREFI_DRAM_CYCLES[15:8]};
	  end
	  reg_bus_pkg::AREF_2:begin
	     bus.rdata = {'0,aref_zq.AREFI_DRAM_CYCLES[19:16]};
	  end
	  reg_bus_pkg::RFC:begin
	     bus.rdata = {aref_zq.RFC_DRAM_CYCLES[7:0]};
	  end
	  reg_bus_pkg::RFC_1:begin
	     bus.rdata = {'0,aref_zq.RFC_DRAM_CYCLES[8]};
	  end
	  reg_bus_pkg::TREG_END:begin
	     bus.rdata = '0;
	  end
	  reg_bus_pkg::DISABLE_REF:begin
	     bus.rdata = {aref_zq.DISABLE_REF};
	  end
	  reg_bus_pkg::DRV_IMP_RON_DATA:begin
	     bus.rdata = {'0,phy_cal.ron_data};
	       end
	  reg_bus_pkg::DRV_IMP_RON_ADDR:begin
	     bus.rdata = {'0,phy_cal.ron_adr_cmd};
	  end
	  reg_bus_pkg::DRV_IMP_RTT_DATA:begin
	     bus.rdata = {'0,phy_cal.rtt_data};
	  end
	  reg_bus_pkg::DRV_SLEW:begin
	     bus.rdata = {'0,phy_cal.td_ctrl_n_data,phy_cal.tdqs_trim_n_data,
			  phy_cal.td_ctrl_n_adr_cmd,phy_cal.tdqs_trim_n_adr_cmd};
	  end
	  reg_bus_pkg::DRV_DLL_CAL_DIS:begin
	     bus.rdata = {'0,disable_dll_cal};
	  end
	  reg_bus_pkg::DRV_END:begin
	     bus.rdata = '0;
	  end
	  reg_bus_pkg::DRV_OCD_CAL_PU:begin
	     bus.rdata = {'0,phy_cal.pu_en_ocd_cal};
	  end
	  reg_bus_pkg::DRV_OCD_CAL_PD:begin
	     bus.rdata = {'0,phy_cal.pd_en_ocd_cal};
	  end
	  reg_bus_pkg::DRV_OCD_CAL_DIS:begin
	     bus.rdata = {'0,phy_cal.disable_ocd_cal};
	  end
	  reg_bus_pkg::BYPASS_BUS_RDY:begin
	     bus.rdata = {'0,bypass_bus_rdy};
	  end
	  reg_bus_pkg::DQS_OFFSET:begin
	     bus.rdata = delay_dqs_offset[7:0];
	  end
	  reg_bus_pkg::DQS_OFFSET_1:begin
	     bus.rdata = {'0,delay_dqs_offset[8]};
	  end
	  reg_bus_pkg::CLK_OFFSET:begin
	     bus.rdata = delay_clk_offset[7:0];
	  end
	  reg_bus_pkg::CLK_OFFSET_1:begin
	     bus.rdata = {'0,delay_clk_offset[8]};
	  end
	  reg_bus_pkg::MR0:begin
	     bus.rdata = mode_reg.mr0[7:0];
	  end
	  reg_bus_pkg::MR0_1:begin
	     bus.rdata = mode_reg.mr0[15:8];
	  end
	  reg_bus_pkg::MR1:begin
	     bus.rdata = mode_reg.mr1[7:0];
	  end
	  reg_bus_pkg::MR1_1:begin
	     bus.rdata = mode_reg.mr1[15:8];
	  end
	  reg_bus_pkg::MR2:begin
	     bus.rdata = mode_reg.mr2[7:0];
	  end
	  reg_bus_pkg::MR2_1:begin
	     bus.rdata = mode_reg.mr2[15:8];
	  end
	  reg_bus_pkg::MR3:begin
	     bus.rdata = mode_reg.mr3[7:0];
	  end
	  reg_bus_pkg::MR3_1:begin
	     bus.rdata = mode_reg.mr3[15:8];
	  end
	  reg_bus_pkg::MODE_END:begin
	     bus.rdata = '0;
	  end
	  reg_bus_pkg::RG_REF_START_ADDR:begin
	     bus.rdata = rg_ref.start_addr[7:0];
	  end
	  reg_bus_pkg::RG_REF_START_ADDR_1:begin
	     bus.rdata = rg_ref.start_addr[15:8];
	  end
	  reg_bus_pkg::RG_REF_END_ADDR:begin
	     bus.rdata = rg_ref.end_addr[7:0];
	  end
	  reg_bus_pkg::RG_REF_END_ADDR_1:begin
	     bus.rdata = rg_ref.end_addr[15:8];
	  end
	  reg_bus_pkg::RG_REF_NUM_ROW_PER_REF:begin
	     bus.rdata = {'0,rg_ref.num_row_per_ref};
	  end
	  reg_bus_pkg::RG_REF_EN_RASMIN:begin
	     bus.rdata = {rg_ref.en,1'b0,rg_ref.ras_dram_clk_cycle};
	  end
	  reg_bus_pkg::RG_REF_RP_RRD:begin
	     bus.rdata = {rg_ref.rp_dram_clk_cycle,rg_ref.rrd_dram_clk_cycle};
	  end
	  reg_bus_pkg::RG_REF_END:begin
	     bus.rdata = '0;
	  end
	  reg_bus_pkg::CONGEN_C3:begin
	     bus.rdata = {'0,congen.c3};
	  end
	  reg_bus_pkg::CONGEN_C4:begin
	     bus.rdata = {'0,congen.c4};
	  end
	  reg_bus_pkg::CONGEN_C5:begin
	     bus.rdata = {'0,congen.c5};
	  end
	  reg_bus_pkg::CONGEN_C6:begin
	     bus.rdata = {'0,congen.c6};
	  end
	  reg_bus_pkg::CONGEN_C7:begin
	     bus.rdata = {'0,congen.c7};
	  end
	  reg_bus_pkg::CONGEN_C8:begin
	     bus.rdata = {'0,congen.c8};
	  end
	  reg_bus_pkg::CONGEN_C9:begin
	     bus.rdata = {'0,congen.c9};
	  end
	  reg_bus_pkg::CONGEN_C10:begin
	     bus.rdata = {'0,congen.c10};
	  end
	  reg_bus_pkg::CONGEN_R0:begin
	     bus.rdata = {'0,congen.r0};
	  end
	  reg_bus_pkg::CONGEN_R1:begin
	     bus.rdata = {'0,congen.r1};
	  end
	  reg_bus_pkg::CONGEN_R2:begin
	     bus.rdata = {'0,congen.r2};
	  end
	  reg_bus_pkg::CONGEN_R3:begin
	     bus.rdata = {'0,congen.r3};
	  end
	  reg_bus_pkg::CONGEN_R4:begin
	     bus.rdata = {'0,congen.r4};
	  end
	  reg_bus_pkg::CONGEN_R5:begin
	     bus.rdata = {'0,congen.r5};
	  end
	  reg_bus_pkg::CONGEN_R6:begin
	     bus.rdata = {'0,congen.r6};
	  end
	  reg_bus_pkg::CONGEN_R7:begin
	     bus.rdata = {'0,congen.r7};
	  end
	  reg_bus_pkg::CONGEN_R8:begin
	     bus.rdata = {'0,congen.r8};
	  end
	  reg_bus_pkg::CONGEN_R9:begin
	     bus.rdata = {'0,congen.r9};
	  end
	  reg_bus_pkg::CONGEN_R10:begin
	     bus.rdata = {'0,congen.r10};
	  end
	  reg_bus_pkg::CONGEN_R11:begin
	     bus.rdata = {'0,congen.r11};
	  end
	  reg_bus_pkg::CONGEN_R12:begin
	     bus.rdata = {'0,congen.r12};
	  end
	  reg_bus_pkg::CONGEN_R13:begin
	     bus.rdata = {'0,congen.r13};
	  end
	  reg_bus_pkg::CONGEN_R14:begin
	     bus.rdata = {'0,congen.r14};
	  end
	  reg_bus_pkg::CONGEN_R15:begin
	     bus.rdata = {'0,congen.r15};
	  end
	  reg_bus_pkg::CONGEN_B0:begin
	     bus.rdata = {'0,congen.b0};
	  end
	  reg_bus_pkg::CONGEN_B1:begin
	     bus.rdata = {'0,congen.b1};
	  end
	  reg_bus_pkg::CONGEN_B2:begin
	     bus.rdata = {'0,congen.b2};
	  end
	  reg_bus_pkg::CONGEN_XOR_SEL:begin
	     bus.rdata = {'0,congen.xor_sel};
	  end
	  reg_bus_pkg::CONGEN_END:begin
	     bus.rdata = '0;
	  end
	  reg_bus_pkg::RD_STATUS_MC:begin
	     bus.rdata = mc_status;
	  end
	  reg_bus_pkg::RD_STATUS_INIT_1:begin
	     bus.rdata = dram_init_status_1;
	  end
	  reg_bus_pkg::RD_STATUS_INIT_2:begin
	     bus.rdata = dram_init_status_2;
	  end
	  reg_bus_pkg::RD_STATUS_PHY_10:begin
	     bus.rdata = phy_status_reg_1[7:0];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_11:begin
	     bus.rdata = phy_status_reg_1[15:8];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_12:begin
	     bus.rdata = phy_status_reg_1[23:16];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_13:begin
	     bus.rdata = phy_status_reg_1[31:24];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_20:begin
	     bus.rdata = phy_status_reg_2[7:0];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_21:begin
	     bus.rdata = phy_status_reg_2[15:8];
	  end
	  reg_bus_pkg::RD_STATUS_PHY_22:begin
	     bus.rdata = phy_status_reg_2[23:16];
	       end
	  reg_bus_pkg::RD_STATUS_PHY_23:begin
	     bus.rdata = phy_status_reg_2[31:24];
	  end
	  default:begin
	     bus.rdata = '0;
	     rerror = bus.valid && !bus.write;
	  end
	endcase // case (addr)
	rready = bus.valid && !bus.write;
     end // always_comb
endmodule // regbus_slave_DRR3config_8bit
