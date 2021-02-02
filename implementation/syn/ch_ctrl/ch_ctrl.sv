module ch_ctrl
  #(
    parameter BANK_FIFO_DEPTH = 8,
    parameter ROW_ADDR_WIDTH = 16,
    parameter COL_ADDR_WIDTH = 10,
    parameter DRAM_ADDR_WIDTH = 16,
    parameter DRAM_CMD_WIDTH = 5,
    parameter DRAM_BANKS = 8,
    parameter DRAM_BUS_WIDTH = 8,
    parameter FE_ADDR_WIDTH = 28,
    parameter FE_CMD_WIDTH = 1,
    parameter FE_ID_WIDTH = 8,
    parameter FE_WRITE = 0,
    parameter RESET_LOW_TIME =  16'b1100_0011_0101_0000,  // 50.000 cyc
    parameter RESET_HIGH_TIME = 16'b1111_1101_1110_1000,   // 65.000 cyc
    parameter CLK_RATIO = 4,
    parameter CAS_EVEN_SLOT = 0, // accepted values are either 1 (for XI FPGA) or zero
    
    //Register width considering worstcase timings
    parameter AREFI_CNT_WIDTH = 20,
    parameter RFC_DRAM_CYCLES_LOG2 = 9,
    parameter RC_DRAM_CYCLES_LOG2 = 6,
    parameter RAS_DRAM_CYCLES_LOG2 = 6,
    parameter RP_DRAM_CYCLES_LOG2 = 4,
    parameter WR2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RD2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RCD_DRAM_CYCLES_LOG2 = 4,
    parameter RRD_DRAM_CYCLES_LOG2 = 4,
    parameter CAS2CAS_DRAM_CYCLES_LOG2 = 4,
    parameter WR2RD_DRAM_CYCLES_LOG2 = 8,
    parameter RD2WR_DRAM_CYCLES_LOG2 = 8,
    parameter ZQS_DRAM_CYCLES_LOG2 = 7,
    parameter RG_REF_NUM_ROW_PER_REF_LOG2 = 6,
    parameter CWL_LOG2 = 4,
    parameter BL_LOG2 = 4,

    ////Default Vaues: if all the REG are not configured via config bus
    parameter RG_REF_NUM_ROW_PER_REF = 4,
    parameter RG_REF_START_ADDR = 0,
    parameter RG_REF_END_ADDR =2**(ROW_ADDR_WIDTH+DRAM_BANKS)-1,
    parameter ZQSI_AREFI_CYCLES = 128, //1ms=128*tREFI. assumption:tREFI = 7.8
    parameter RRD_DRAM_CYCLES = 4,
    parameter WTR_DRAM_CYCLES = 4,
    parameter CCD_DRAM_CYCLES = 4,
`ifdef DDR4
    parameter RRD_DRAM_CYCLES_L = 6,
    parameter WTR_DRAM_CYCLES_L = 6,
    parameter CCD_DRAM_CYCLES_L = 5,
`endif
    parameter RP_DRAM_CYCLES = 6,
    parameter RTP_DRAM_CYCLES = 4,
    parameter WR_DRAM_CYCLES = 6,
    parameter RCD_DRAM_CYCLES = 6,
    parameter RAS_DRAM_CYCLES = 15,
    parameter FAW_DRAM_CYCLES = 16,
    parameter AREFI_DRAM_CYCLES = 2880,//7.8us
    parameter RFC_DRAM_CYCLES = 44,//1Gb 110ns
    parameter ZQS_DRAM_CYCLES = 64,
    parameter CL = 6,
    parameter CWL = 5,
    parameter BL = 8,
    parameter CONFIG_BUS_ADDR_WIDTH = 9,
    parameter CONFIG_BUS_DATA_WIDTH = 8,
    parameter RON_DATA = 5'b10011,//cRON_48,
    parameter RTT_DATA = 5'b10000,//cRTT_60,
    parameter RON_ADR_CMD = 5'b10011,//cRON_48,
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
`ifdef DDR4
    parameter CONGEN_CONFIG_R16 = 5'd27,
`endif
    parameter CONGEN_CONFIG_B0  = 5'd21,
    parameter CONGEN_CONFIG_B1  = 5'd22,
    parameter CONGEN_CONFIG_B2  = 5'd23,
`ifdef DDR4
    parameter CONGEN_CONFIG_B3  = 5'd28,
`endif
    parameter CONGEN_XOR_SEL = 3'b0
    )
   (
    input logic 					 rst_n, //  Reset
    input logic 					 clk,//  System Clock

    // *************************************************************************
    // from frontend eg(AXI)
    // *************************************************************************
    input logic 					 fe_req,
    input logic [FE_CMD_WIDTH-1:0] 			 fe_cmd,
    input logic [FE_ADDR_WIDTH-1:0] 			 fe_addr,
    input logic [FE_ID_WIDTH-1:0] 			 fe_id,
    input logic [DRAM_BUS_WIDTH*BL-1:0] 		 fe_data,
    output logic 					 fe_stall,

    // *************************************************************************
    // from read  buffer to fe
    // *************************************************************************
    output logic [DRAM_BUS_WIDTH*BL-1:0] 		 fe_read_data,
    output logic [FE_ID_WIDTH-1:0] 			 fe_read_id,
    output logic 					 fe_read_valid,
    input logic 					 fe_read_grant,

    // *************************************************************************
    // to phy
    // *************************************************************************
    output logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 ctrl_addr,
    output logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] ctrl_bank,
    output logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 ctrl_cmd,
`ifdef DDR4
    output logic [CLK_RATIO-1:0] 			 ctrl_act_n,
`endif
    output logic 					 ctrl_valid,
    output logic [FE_ID_WIDTH-1:0] 			 ctrl_cas_cmd_id,
    output logic 					 ctrl_cas_cmd_id_valid,//NA
    output logic 					 ctrl_write,
    output logic 					 ctrl_read,
    output logic [$clog2(CLK_RATIO)-1:0] 		 ctrl_cas_slot,
    // *************************************************************************
	// from phy
    // *************************************************************************
	// bus_rdy tells mem_controller if data bus is rdy
`ifdef FPGA
    input 						 cal_done,
`else
    input logic 					 bus_rdy,
    input [31:0] 					 phy_status_reg_1,
    input [31:0] 					 phy_status_reg_2,
`endif

   // **************************************************************************
   //write buffer
   // **************************************************************************
    output logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_w_data,
    output logic 					 ctrl_w_valid,
    input logic 					 ctrl_w_grant,

    // *************************************************************************
    //read buffer
    // *************************************************************************
    input logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_r_data,
    input logic [FE_ID_WIDTH-1:0] 			 ctrl_r_id,
    input logic 					 ctrl_r_valid,
    output logic 					 ctrl_r_grant,

    // *************************************************************************
    // from init block to phy
    // *************************************************************************
`ifndef FPGA
    output logic 					 reset_m_n,
    output logic 					 clk_oe,
    output logic 					 ocd_oe,
    output logic 					 slot_cnt_en,
    output logic 					 start_ocdcal,
    output logic 					 start_dll,
       // TIMING WRITE cwl= 0-4 not in use cwl = 5 - 16 allowed
    output logic [3:0] 					 cwl,
    output logic [3:0] 					 cl,
    // io calibration
    phy_config_if.mem_cntrl phy_config,
       // offset TIMING
    output logic [8:0] 					 delay_dqs_offset,
    output logic [8:0] 					 delay_clk_offset,
`endif //  `ifndef FPGA

    // *************************************************************************
    // ctrl config inputs
    // *************************************************************************
`ifndef FPGA
    reg_bus_if.slave mc_config_bus,
`endif
    input logic 					 decoder_type
    );


   //************************* Config bus slave ********************************
   dram_global_timing_if dram_t_rm();
   dram_bank_timing_if dram_t_bm();
   dram_aref_zq_timing_if aref_zq();
   dram_rg_ref_if #(.DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH)) rg_ref();
   congen_if congen();
   //if_dram_init phy_cal();
   
   logic 						 bus_rdy_lcl;
   logic 						 init_done;

`ifdef FPGA
   logic 						 congen_update_q;

   assign congen_update_q = cal_done;

   always_comb
     begin
	init_done = cal_done;
	bus_rdy_lcl = '1;
	dram_t_rm.CCD_DRAM_CYCLES = CCD_DRAM_CYCLES;
	dram_t_rm.WTR_DRAM_CYCLES = WTR_DRAM_CYCLES;
	dram_t_rm.RRD_DRAM_CYCLES = RRD_DRAM_CYCLES;
 `ifdef DDR4
	dram_t_rm.CCD_DRAM_CYCLES_L = CCD_DRAM_CYCLES_L;
	dram_t_rm.WTR_DRAM_CYCLES_L = WTR_DRAM_CYCLES_L;
	dram_t_rm.RRD_DRAM_CYCLES_L = RRD_DRAM_CYCLES_L;
 `endif
	aref_zq.AREFI_DRAM_CYCLES = AREFI_DRAM_CYCLES;
	aref_zq.RFC_DRAM_CYCLES = RFC_DRAM_CYCLES;
	dram_t_rm.FAW_DRAM_CYCLES = FAW_DRAM_CYCLES;
	aref_zq.ZQS_DRAM_CYCLES = ZQS_DRAM_CYCLES;
	aref_zq.ZQS_DISABLE = 1'b0;
	aref_zq.DISABLE_REF = 1'b0;
	dram_t_rm.BL = BL;
	dram_t_rm.CWL = CWL;
	dram_t_rm.CL = CL;
	dram_t_bm.RP_DRAM_CYCLES = RP_DRAM_CYCLES;
	dram_t_bm.RTP_DRAM_CYCLES = RTP_DRAM_CYCLES;
	dram_t_bm.WR_DRAM_CYCLES = WR_DRAM_CYCLES;
	dram_t_bm.RCD_DRAM_CYCLES = RCD_DRAM_CYCLES;
	dram_t_bm.RAS_DRAM_CYCLES = RAS_DRAM_CYCLES;
	rg_ref.start_addr = RG_REF_START_ADDR;
	rg_ref.end_addr = RG_REF_END_ADDR;
	rg_ref.num_row_per_ref = RG_REF_NUM_ROW_PER_REF;
	rg_ref.rrd_dram_clk_cycle = RRD_DRAM_CYCLES;
	rg_ref.ras_dram_clk_cycle = RAS_DRAM_CYCLES;
	rg_ref.rp_dram_clk_cycle = RP_DRAM_CYCLES;
	rg_ref.en = 1'b0;
	congen.c3 = CONGEN_CONFIG_C3;
	congen.c4 = CONGEN_CONFIG_C4;
	congen.c5 = CONGEN_CONFIG_C5;
	congen.c6 = CONGEN_CONFIG_C6;
	congen.c7 = CONGEN_CONFIG_C7;
	congen.c8 = CONGEN_CONFIG_C8;
	congen.c9 = CONGEN_CONFIG_C9;
	congen.c10 = CONGEN_CONFIG_C10;
	congen.r0 = CONGEN_CONFIG_R0;
	congen.r1 = CONGEN_CONFIG_R1;
	congen.r2 = CONGEN_CONFIG_R2;
	congen.r3 = CONGEN_CONFIG_R3;
	congen.r4 = CONGEN_CONFIG_R4;
	congen.r5 = CONGEN_CONFIG_R5;
	congen.r6 = CONGEN_CONFIG_R6;
	congen.r7 = CONGEN_CONFIG_R7;
	congen.r8 = CONGEN_CONFIG_R8;
	congen.r9 = CONGEN_CONFIG_R9;
	congen.r10 = CONGEN_CONFIG_R10;
	congen.r11 = CONGEN_CONFIG_R11;
	congen.r12 = CONGEN_CONFIG_R12;
	congen.r13 = CONGEN_CONFIG_R13;
	congen.r14 = CONGEN_CONFIG_R14;
	congen.r15 = CONGEN_CONFIG_R15;
 `ifdef DDR4
	congen.r16 = CONGEN_CONFIG_R16;
 `endif
	congen.b0 = CONGEN_CONFIG_B0;
	congen.b1 = CONGEN_CONFIG_B1;
	congen.b2 = CONGEN_CONFIG_B2;
 `ifdef DDR4
	congen.b3 = CONGEN_CONFIG_B3;
 `endif	
	congen.xor_sel = CONGEN_XOR_SEL;
     end

`else // !`ifdef FPGA

   // TODO update for DDR4
   mode_reg_config_if mode_reg();
   
   logic 						 time_check_done;
   logic 						 time_check_start;
   logic 						 phy_cal_config_done;
   logic 						 mode_reg_config_done;
   logic 						 phy_cal_reg_update;
   logic 						 mode_reg_update;
   logic 						 rg_ref_update,rg_ref_update_q;
   logic 						 congen_update,congen_update_q;
   logic [7:0]						 dram_init_status_1;
   logic [7:0]						 dram_init_status_2;
   logic [7:0]						 rm_fsm_state;
   logic 						 disable_dll_cal;
   logic 						 bypass_bus_rdy;

   assign cwl = dram_t_rm.CWL;
   assign cl = {mode_reg.mr0[2],mode_reg.mr0[6:4]};
   assign bus_rdy_lcl = bus_rdy || bypass_bus_rdy;

   regbus_slave_DDR3config_8bit
     #(
       //.atype(reg_bus_pkg::REG_BUS_FRAMES),
       .ADDR_WIDTH(CONFIG_BUS_ADDR_WIDTH),
       .DATA_WIDTH(CONFIG_BUS_DATA_WIDTH),
       .RRD_DRAM_CYCLES(RRD_DRAM_CYCLES),
       .WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
       .CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
       .RP_DRAM_CYCLES(RP_DRAM_CYCLES),
       .RTP_DRAM_CYCLES(RTP_DRAM_CYCLES),
       .WR_DRAM_CYCLES(WR_DRAM_CYCLES),
       .RCD_DRAM_CYCLES(RCD_DRAM_CYCLES),
       .RAS_DRAM_CYCLES(RAS_DRAM_CYCLES),
       .FAW_DRAM_CYCLES(FAW_DRAM_CYCLES),
       .ZQS_DRAM_CYCLES(ZQS_DRAM_CYCLES),
       .AREFI_DRAM_CYCLES(AREFI_DRAM_CYCLES),
       .RFC_DRAM_CYCLES(RFC_DRAM_CYCLES),
       .CL(CL),
       .CWL(CWL),
       .BL(BL),
       .RG_REF_NUM_ROW_PER_REF(RG_REF_NUM_ROW_PER_REF),
       .RG_REF_START_ADDR(RG_REF_START_ADDR),
       .RG_REF_END_ADDR(RG_REF_END_ADDR),
       .RON_DATA(RON_DATA),
       .RTT_DATA(RTT_DATA),
       .RON_ADR_CMD(RON_ADR_CMD),
       .PU_EN_OCD_CAL(PU_EN_OCD_CAL),
       .PD_EN_OCD_CAL(PD_EN_OCD_CAL),
       .DISABLE_OCD_CAL(DISABLE_OCD_CAL),
       .DISABLE_DLL_CAL(DISABLE_DLL_CAL),
       .TD_CTRL_N_DATA(TD_CTRL_N_DATA),
       .TD_CTRL_N_ADR_CMD(TD_CTRL_N_ADR_CMD),
       .TDQS_TRIM_N_DATA(TDQS_TRIM_N_DATA),
       .TDQS_TRIM_N_ADR_CMD(TDQS_TRIM_N_ADR_CMD),
       .DELAY_DQS_OFFSET(DELAY_DQS_OFFSET),
       .DELAY_CLK_OFFSET(DELAY_CLK_OFFSET),
       .MRS_INIT_REG0(MRS_INIT_REG0),
       .MRS_INIT_REG1(MRS_INIT_REG1),
       .MRS_INIT_REG2(MRS_INIT_REG2),
       .MRS_INIT_REG3(MRS_INIT_REG3),
       .CONGEN_CONFIG_C3(CONGEN_CONFIG_C3),
       .CONGEN_CONFIG_C4(CONGEN_CONFIG_C4),
       .CONGEN_CONFIG_C5(CONGEN_CONFIG_C5),
       .CONGEN_CONFIG_C6(CONGEN_CONFIG_C6),
       .CONGEN_CONFIG_C7(CONGEN_CONFIG_C7),
       .CONGEN_CONFIG_C8(CONGEN_CONFIG_C8),
       .CONGEN_CONFIG_C9(CONGEN_CONFIG_C9),
       .CONGEN_CONFIG_C10(CONGEN_CONFIG_C10),
       .CONGEN_CONFIG_R0(CONGEN_CONFIG_R0),
       .CONGEN_CONFIG_R1(CONGEN_CONFIG_R1),
       .CONGEN_CONFIG_R2(CONGEN_CONFIG_R2),
       .CONGEN_CONFIG_R3(CONGEN_CONFIG_R3),
       .CONGEN_CONFIG_R4(CONGEN_CONFIG_R4),
       .CONGEN_CONFIG_R5(CONGEN_CONFIG_R5),
       .CONGEN_CONFIG_R6(CONGEN_CONFIG_R6),
       .CONGEN_CONFIG_R7(CONGEN_CONFIG_R7),
       .CONGEN_CONFIG_R8(CONGEN_CONFIG_R8),
       .CONGEN_CONFIG_R9(CONGEN_CONFIG_R9),
       .CONGEN_CONFIG_R10(CONGEN_CONFIG_R10),
       .CONGEN_CONFIG_R11(CONGEN_CONFIG_R11),
       .CONGEN_CONFIG_R12(CONGEN_CONFIG_R12),
       .CONGEN_CONFIG_R13(CONGEN_CONFIG_R13),
       .CONGEN_CONFIG_R14(CONGEN_CONFIG_R14),
       .CONGEN_CONFIG_R15(CONGEN_CONFIG_R15),
       .CONGEN_CONFIG_B0(CONGEN_CONFIG_B0),
       .CONGEN_CONFIG_B1(CONGEN_CONFIG_B1),
       .CONGEN_CONFIG_B2(CONGEN_CONFIG_B2),
       .CONGEN_XOR_SEL(CONGEN_XOR_SEL)
       )mc_config_bus_slave
       (
	.rst_n(rst_n),
	.bus(mc_config_bus),
	.dram_t_rm(dram_t_rm),
	.dram_t_bm(dram_t_bm),
	.aref_zq(aref_zq),
	.rg_ref(rg_ref),
	.phy_cal(phy_config),
	.congen(congen),
	.disable_dll_cal(disable_dll_cal),
	.bypass_bus_rdy(bypass_bus_rdy),
	.delay_dqs_offset(delay_dqs_offset),
	.delay_clk_offset(delay_clk_offset),
	.mode_reg(mode_reg),
	.mc_status(rm_fsm_state),
	.dram_init_status_1(dram_init_status_1),
	.dram_init_status_2(dram_init_status_2),
	.phy_status_reg_1(phy_status_reg_1),
	.phy_status_reg_2(phy_status_reg_2),
	.time_check_done(time_check_done),
	.time_check_passed(time_check_done), // to be updated after timing check is implemented
	.init_done(init_done),
	.phy_cal_config_done(phy_cal_config_done),
	.mode_reg_config_done(mode_reg_config_done),
	.time_check_start(time_check_start),
	.phy_cal_reg_update(phy_cal_reg_update),
	.mode_reg_update(mode_reg_update),
	.rg_ref_update(rg_ref_update),
	.congen_update(congen_update)
	);
   //FIXME: replace FF with timing check
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(!rst_n) begin
	   time_check_done <= 1'b0;
	   rg_ref_update_q <= 1'b0;
	   congen_update_q <= 1'b0;
	end
	else begin
	  // should be high until new start
	   time_check_done <= time_check_start?1'b1:time_check_done;
	   rg_ref_update_q <= rg_ref_update?1'b1:rg_ref_update_q;
	   congen_update_q <= congen_update?1'b1:congen_update_q;
	end
     end

`endif // !`ifdef FPGA

   //***************************** init block **********************************

   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0]    dram_init_addr;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] dram_init_bank;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 dram_init_cmd;
   
`ifdef FPGA
   logic [CLK_RATIO-1:0] 			 dram_init_act_n;

   assign dram_init_cmd = '1;
   assign dram_init_addr = '1;
   assign dram_init_bank = '1;
 `ifdef DDR4
   assign dram_init_act_n = '1;
 `endif
   
`else // !`ifdef FPGA
       
   logic cs_n;
   logic ras_n;
   logic cas_n;
   logic we_n;
   logic cke;
   logic [$clog2(DRAM_BANKS)-1:0]  bank;
   logic [DRAM_ADDR_WIDTH-1:0] 	   addr;
   logic 			   mux_ctrl_init_mrs;
   logic 			   time_check_passed;
   logic [2:0] 			   dram_init_fsm_state;
   logic 			   start_dll_dram_init;
   logic 			   init_done_lcl;
   logic 			   init_done_q;

   assign time_check_passed = time_check_done && rg_ref_update_q && congen_update_q;
   assign dram_init_status_1 = {clk_oe,ocd_oe,slot_cnt_en,start_ocdcal,
				start_dll,dram_init_fsm_state};
   assign dram_init_status_2 = {4'b0000,init_done,phy_cal_config_done,
				mode_reg_config_done,time_check_passed};
   assign start_dll = start_dll_dram_init && !disable_dll_cal;
   assign init_done = (init_done_lcl && bus_rdy_lcl) || init_done_q;

   // combination of init_done and bus_rdy/disable_dll for correct start_up

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(!rst_n) begin
           init_done_q <= 1'b0;
	end
	else
          init_done_q <= init_done;
     end

   dram_init
     #(
       .RESET_LOW_TIME(RESET_LOW_TIME),
       .RESET_HIGH_TIME(RESET_HIGH_TIME)
       ) dram_init
       (
	.clk(clk),
	.rst_n(rst_n),
	//.ba_in(3'b111),//default
	.mrs_in(mode_reg),
	.mrs_ext_in(mode_reg_update),
	.time_check_passed(time_check_passed),
	.phy_cal_reg_update(phy_cal_reg_update),
	.cs_n(cs_n),
	.ras_n(ras_n),
	.cas_n(cas_n),
	.we_n(we_n),
	.cke(cke),
	.reset_m_n(reset_m_n),
	.ba(bank),
	.addr(addr),
	.mux_ctrl_init_mrs(mux_ctrl_init_mrs),
	.clk_oe(clk_oe),
	.ocd_oe(ocd_oe),
	.slot_cnt_en(slot_cnt_en),
	.start_ocdcal(start_ocdcal),
	.start_dll(start_dll_dram_init),
	.phy_cal_config_done(phy_cal_config_done),
	.mode_reg_config_done(mode_reg_config_done),
	.init_done(init_done_lcl),
	.fsm_state(dram_init_fsm_state)
	);

   assign dram_init_cmd = {{cke,4'b1111},{cke,4'b1111},{cke,4'b1111},
			   {cke,cs_n,ras_n,cas_n,we_n}};
   assign dram_init_addr = {addr,{(DRAM_ADDR_WIDTH*(CLK_RATIO-2)){1'b0}},addr};
   assign dram_init_bank = {{($clog2(DRAM_BANKS)*(CLK_RATIO-1)){1'b0}},bank};

`endif // !`ifdef FPGA

   //***************************** rank machine *******************************
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 rm_addr;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] rm_bank;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 rm_cmd;
   logic 					 rm_valid;
   logic [FE_ID_WIDTH-1:0] 			 rm_cas_cmd_id;
   logic 					 rm_cas_cmd_id_valid;
   logic 					 rm_fe_stall;
   logic [DRAM_BUS_WIDTH*BL-1:0] 		 r_data;
   logic [FE_ID_WIDTH-1:0] 			 r_id;
   logic 					 r_valid;
   logic 					 r_grant;
   logic 					 init_en;
`ifdef DDR4
   logic [CLK_RATIO-1:0] 			 rm_act_n;
`endif
   

   ch_ctrl_rank_fsm
     #(
       .BANK_FIFO_DEPTH(BANK_FIFO_DEPTH),
       .ROW_ADDR_WIDTH(ROW_ADDR_WIDTH),
       .COL_ADDR_WIDTH(COL_ADDR_WIDTH),
       .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
       .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH),
       .DRAM_BANKS(DRAM_BANKS),
       .DRAM_BUS_WIDTH(DRAM_BUS_WIDTH),
       .FE_ADDR_WIDTH(FE_ADDR_WIDTH),
       .FE_CMD_WIDTH(FE_CMD_WIDTH),
       .FE_ID_WIDTH(FE_ID_WIDTH),
       .FE_WRITE(FE_WRITE),
       .CLK_RATIO(CLK_RATIO),
       .CAS_EVEN_SLOT(CAS_EVEN_SLOT),
       .AREFI_CNT_WIDTH(AREFI_CNT_WIDTH),
       .RFC_DRAM_CYCLES_LOG2(RFC_DRAM_CYCLES_LOG2),
       .RC_DRAM_CYCLES_LOG2(RC_DRAM_CYCLES_LOG2),
       .RAS_DRAM_CYCLES_LOG2(RAS_DRAM_CYCLES_LOG2),
       .RP_DRAM_CYCLES_LOG2(RP_DRAM_CYCLES_LOG2),
       .WR2PRE_DRAM_CYCLES_LOG2(WR2PRE_DRAM_CYCLES_LOG2),
       .RD2PRE_DRAM_CYCLES_LOG2(RD2PRE_DRAM_CYCLES_LOG2),
       .RCD_DRAM_CYCLES_LOG2(RCD_DRAM_CYCLES_LOG2),
       .RRD_DRAM_CYCLES_LOG2(RRD_DRAM_CYCLES_LOG2),
       .CAS2CAS_DRAM_CYCLES_LOG2(CAS2CAS_DRAM_CYCLES_LOG2),
       .WR2RD_DRAM_CYCLES_LOG2(WR2RD_DRAM_CYCLES_LOG2),
       .RD2WR_DRAM_CYCLES_LOG2(RD2WR_DRAM_CYCLES_LOG2),
       .ZQS_DRAM_CYCLES_LOG2(ZQS_DRAM_CYCLES_LOG2),
       .RG_REF_NUM_ROW_PER_REF_LOG2(RG_REF_NUM_ROW_PER_REF_LOG2),
       .CWL_LOG2(CWL_LOG2),
       .BL_LOG2(BL_LOG2),
       .RG_REF_NUM_ROW_PER_REF(RG_REF_NUM_ROW_PER_REF),
       .ZQSI_AREFI_CYCLES(ZQSI_AREFI_CYCLES)// ZQ short interval in AREF cycles
       /*.RRD_DRAM_CYCLES(RRD_DRAM_CYCLES),
       .WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
       .CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
       .RP_DRAM_CYCLES(RP_DRAM_CYCLES),
       .RTP_DRAM_CYCLES(RTP_DRAM_CYCLES),
       .WR_DRAM_CYCLES(WR_DRAM_CYCLES),
       .RCD_DRAM_CYCLES(RCD_DRAM_CYCLES),
       .RAS_DRAM_CYCLES(RAS_DRAM_CYCLES),
       .ZQS_DRAM_CYCLES(ZQS_DRAM_CYCLES),
       .AREF_DRAM_CYCLES(AREF_DRAM_CYCLES),
       .RFC_DRAM_CYCLES(RFC_DRAM_CYCLES),
       .CL(CL),
       .CWL(CWL),
       .TFAW_NS(TFAW_NS),
       .BL(BL)*/
       ) RM
       (
	.rst_n(rst_n),
	.clk(clk),
	.fe_req(fe_req && !fe_stall),
	.fe_cmd(fe_cmd),
	.fe_addr(fe_addr),
	.fe_id(fe_id),
	.fe_stall(rm_fe_stall),
	.read_stall(!r_grant),
	.init_done(init_done),
	.init_en(init_en),
	.rm_addr(rm_addr),
	.rm_bank(rm_bank),
	.rm_cmd(rm_cmd),
`ifdef DDR4
	.rm_act_n(rm_act_n),
`endif
	.rm_valid(rm_valid),
	.rm_cas_cmd_id(rm_cas_cmd_id),
	.rm_cas_cmd_id_valid(rm_cas_cmd_id_valid),
	.rm_write(ctrl_write),
	.rm_read(ctrl_read),
	.rm_cas_slot(ctrl_cas_slot),
`ifndef DDR4
	.rm_fsm_state(rm_fsm_state),
`endif
	.bus_rdy(bus_rdy_lcl),
	.decoder_type(decoder_type),
	.dram_t_rm(dram_t_rm),
	.dram_t_bm(dram_t_bm),
	.aref_zq(aref_zq),
	.rg_ref(rg_ref),
	.congen(congen)
	);

   assign ctrl_addr = init_done?rm_addr:dram_init_addr;
   assign ctrl_bank = init_done?rm_bank:dram_init_bank;
   assign ctrl_cmd = init_done?rm_cmd:dram_init_cmd;
`ifdef DDR4
   assign ctrl_act_n = init_done?rm_act_n:dram_init_act_n;
`endif
   assign ctrl_valid = !init_done || rm_valid;
   assign ctrl_cas_cmd_id = rm_cas_cmd_id;
   assign ctrl_cas_cmd_id_valid = rm_cas_cmd_id_valid;

   //******************************* buffers **********************************
   logic 					 ctrl_w_grant_sync;
//   logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_r_data_sync;
//   logic [FE_ID_WIDTH-1:0] 			 ctrl_r_id_sync;
//   logic 					 ctrl_r_valid_sync;
   logic 					 wr_buffer_stall;

   /*assign ctrl_w_grant_sync = ctrl_w_grant;
   assign ctrl_r_data_sync = ctrl_r_data;
   assign ctrl_r_id_sync = ctrl_r_id;
   assign ctrl_r_valid_sync = ctrl_r_valid;*/

   assign fe_stall = rm_fe_stall || !wr_buffer_stall || !congen_update_q;

   //Sync FF
   always_ff @(negedge clk, negedge rst_n)
     begin
	if(!rst_n) begin
	   ctrl_w_grant_sync <= '0;
	  // ctrl_r_data_sync <= '0;
	  // ctrl_r_id_sync <= '0;
	  // ctrl_r_valid_sync <= '0;
	end
	else begin
	   ctrl_w_grant_sync <= ctrl_w_grant;
	 //  ctrl_r_data_sync <= ctrl_r_data;
	 //  ctrl_r_id_sync <= ctrl_r_id;
	 //  ctrl_r_valid_sync <= ctrl_r_valid;
	end // else: !if(!rst_n)
     end

`ifndef FPGA
  
   generic_fifo #(
		  .DATA_WIDTH(DRAM_BUS_WIDTH*BL),//TODO: Extend it for data mask
	       .DATA_DEPTH(BANK_FIFO_DEPTH*DRAM_BANKS)
	       // +1: address decoder could latch 1 extra cmd after
	       )
   write_buffer (
		 .clk(clk),
		 .rst_n(rst_n),
		 .data_i(fe_data),
		 .valid_i(fe_req && !fe_stall && (fe_cmd == FE_WRITE)),
		 .grant_o(wr_buffer_stall),
		 .data_o(ctrl_w_data),
		 .valid_o(ctrl_w_valid),
		 .grant_i(ctrl_w_grant_sync),
		 .test_mode_i(1'b0)
		 );
`else // !`ifndef FPGA
   
   bram_fifo_512x64 #(
		       // do not override the parameters
		      )
   write_buffer (
		 .clk(clk),
		 .rst_n(rst_n),
		 .data_i(fe_data),
		 .valid_i(fe_req && !fe_stall && (fe_cmd == FE_WRITE)),
		 .grant_o(wr_buffer_stall),
		 .data_o(ctrl_w_data),
		 .valid_o(ctrl_w_valid),
		 .grant_i(ctrl_w_grant_sync),
		 .test_mode_i(1'b0)
		 );
`endif // !`ifndef FPGA
   
`ifndef FPGA
   dual_clock_fifo #(
		  .DATA_WIDTH((DRAM_BUS_WIDTH*BL)+FE_ID_WIDTH),
		  .DATA_DEPTH(8)
		  )
   overflow_buffer (
		.clk(clk),
		.rst_n(rst_n),
		.data_i({ctrl_r_id,ctrl_r_data}),
		.clk_valid_i(ctrl_r_valid),
		.grant_o(ctrl_r_grant),
		.data_o({r_id,r_data}),
		.valid_o(r_valid),
		.grant_i(r_grant)
		);
`else // !`ifndef FPGA
   //generic_fifo #(
    bram_fifo_528x8 #(
   		      // do not override the parameters
		      )
   overflow_buffer (
		    .clk(clk),
		    .rst_n(rst_n),
		    .data_i({ctrl_r_id,ctrl_r_data}),
		    .valid_i(ctrl_r_valid),
		    .grant_o(ctrl_r_grant),
		    .data_o({r_id,r_data}),
		    .valid_o(r_valid),
		    .grant_i(r_grant),
		    .test_mode_i(1'b0)
		    );
`endif

`ifndef FPGA

   generic_fifo #(
		  .DATA_WIDTH((DRAM_BUS_WIDTH*BL)+FE_ID_WIDTH),
		  .DATA_DEPTH(BANK_FIFO_DEPTH*DRAM_BANKS)
	       )
   read_buffer (
		.clk(clk),
		.rst_n(rst_n),
		.data_i({r_id,r_data}),
		.valid_i(r_valid),
		.grant_o(r_grant),
		.data_o({fe_read_id,fe_read_data}),
		.valid_o(fe_read_valid),
		.grant_i(fe_read_grant),
		.test_mode_i(1'b0)
		);
`else // !`ifndef FPGA
   
   bram_fifo_528x64 #(
		       // do not override the parameters
		      )
   read_buffer (
		.clk(clk),
		.rst_n(rst_n),
		.data_i({r_id,r_data}),
		.valid_i(r_valid),
		.grant_o(r_grant),
		.data_o({fe_read_id,fe_read_data}),
		.valid_o(fe_read_valid),
		.grant_i(fe_read_grant),
		.test_mode_i(1'b0)
		);
`endif

/*
   generic_fifo #(
		  .DATA_WIDTH((DRAM_BUS_WIDTH*BL)+FE_ID_WIDTH),
		  .DATA_DEPTH(8)//CL max is 16 = 4 reads cmds
		  // depth of 5 required, but fifo supports only 4 or 8
		  )
   overflow_buffer (
		    .clk(clk),
		    .rst_n(rst_n),
		    .data_i({ctrl_r_id_sync,ctrl_r_data_sync}),
		    .valid_i(ctrl_r_valid_sync),
		    .grant_o(ctrl_r_grant),
		    .data_o({r_id,r_data}),
		    .valid_o(r_valid),
		    .grant_i(r_grant),
		    .test_mode_i(1'b0)
		    );
*/
endmodule
