module ddr4_mem_ch_top
  #(
    parameter AXI4_ADDRESS_WIDTH = 32,
    parameter AXI4_RDATA_WIDTH   = 64,
    parameter AXI4_WDATA_WIDTH   = 64,
    parameter AXI4_ID_WIDTH      = 16,
    parameter AXI4_USER_WIDTH    = 10,
    parameter AXI_BURST_LENGTH   = 1,
    parameter BUFF_DEPTH_SLAVE   = 2,
    parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,

    parameter BANK_FIFO_DEPTH = 4,
    parameter ROW_ADDR_WIDTH = 16,
    parameter COL_ADDR_WIDTH = 11,
    parameter DRAM_ADDR_WIDTH = 16,
    parameter DRAM_CMD_WIDTH = 5,
    parameter DRAM_BANKS = 8,
    parameter DRAM_BUS_WIDTH = 8,
    
    parameter CAS_EVEN_SLOT = 1, // accepted values are either 1 (for XI FPGA) or zero
    parameter CLK_RATIO = 4,

    parameter RESET_LOW_TIME =  16'b1100_0011_0101_0000,  // 50.000 cyc
    parameter RESET_HIGH_TIME = 16'b1111_1101_1110_1000,   // 65.000 cyc
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
    parameter RG_REF_NUM_ROW_PER_REF_LOG2 = 6,
    parameter CWL_LOG2 = 4,
    parameter BL_LOG2 = 4,
    parameter ZQS_DRAM_CYCLES_LOG2 = 7,
    parameter ZQSI_AREFI_CYCLES = 128, // ZQ short interval
    // ZQCSI is defined interms of tREFI(1ms=128*tREFI). Assumption:tREFI = 7.8
    //Default Vaues: if all the REG are not configured via config bus
    parameter RRD_DRAM_CYCLES = 4,
    parameter WTR_DRAM_CYCLES = 4,
    parameter CCD_DRAM_CYCLES = 4,

    parameter RRD_DRAM_CYCLES_L = 6,
    parameter WTR_DRAM_CYCLES_L = 6,
    parameter CCD_DRAM_CYCLES_L = 5,

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
    parameter RG_REF_NUM_ROW_PER_REF = 4,
    parameter RG_REF_START_ADDR = 0,
    parameter RG_REF_END_ADDR = 2**(ROW_ADDR_WIDTH+DRAM_BANKS)-1,
    parameter RON_DATA = 5'b10011, //cRON48
    parameter RTT_DATA = 5'b10000, //cRTT60
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

    parameter CONGEN_CONFIG_R16 = 5'd27,

    parameter CONGEN_CONFIG_B0  = 5'd21,
    parameter CONGEN_CONFIG_B1  = 5'd22,
    parameter CONGEN_CONFIG_B2  = 5'd23,

    parameter CONGEN_CONFIG_B3  = 5'd28,

    parameter CONGEN_XOR_SEL = 3'b0,
    parameter DECODER_TYPE = 1'b1
    )
   (
    input 				sys_rst_n,
    input 				c0_sys_clk_p,
    input 				c0_sys_clk_n,
    
    output 				ui_clk_out,
    output 				ui_rst_n_out,

   // **************************************************************************
   // ----- AXI write address bus ----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 		AWID,
    input [AXI4_ADDRESS_WIDTH-3:0] 	AWADDR, // MSB bit not internally conneted only [29:0] is used
    input [7:0] 			AWLEN,
    //input [2:0] 			AWSIZE,
    //input [1:0] 			AWBURST,
    //input 				AWLOCK,
    //input [3:0] 			AWCACHE,
    //input [2:0] 			AWPROT,
    //input [3:0] 			AWREGION,
    //input [AXI4_USER_WIDTH-1:0] 	AWUSER,
    //input [3:0] 			AWQOS,
    input 				AWVALID,
    output logic 			AWREADY,

   // **************************************************************************
   // ----- AXI write data bus -------------------------------------------------
   // **************************************************************************
    input [AXI_NUMBYTES-1:0][7:0] 	WDATA,
    //input [AXI_NUMBYTES-1:0] 		WSTRB,
    input 				WLAST,
    //input [AXI4_USER_WIDTH-1:0] 	WUSER,
    input 				WVALID,
    output logic 			WREADY,

   // **************************************************************************
   // ----- AXI write response bus ---------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 	BID,
    output logic [1:0] 			BRESP,
    output logic 			BVALID,
    //output logic [AXI4_USER_WIDTH-1:0] 	BUSER,
    input 				BREADY,

   // **************************************************************************
   // ----- AXI read address bus -----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 		ARID,
    input [AXI4_ADDRESS_WIDTH-3:0] 	ARADDR,
    //input [7:0] 			ARLEN,
    //input [2:0] 			ARSIZE,
    //input [1:0] 			ARBURST,
    //input 				ARLOCK,
    //input [3:0] 			ARCACHE,
    //input [2:0] 			ARPROT,
    //input [3:0] 			ARREGION,
    //input [AXI4_USER_WIDTH-1:0] 	ARUSER,
    //input [ 3:0] 			ARQOS,
    input 				ARVALID,
    output logic 			ARREADY,

   // **************************************************************************
   // ----- AXI read data bus --------------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 	RID,
    output logic [AXI4_RDATA_WIDTH-1:0] RDATA,
    output logic [ 1:0] 		RRESP,
    output logic 			RLAST,
    //output logic [AXI4_USER_WIDTH-1:0] 	RUSER,
    output logic 			RVALID,
    input 				RREADY,

    // **************************************************************************
    // ----- Config bus ---------------------------------------------------------
    // **************************************************************************
    //reg_bus_if.slave mc_config_bus,
`ifndef FPGA
    input [CONFIG_BUS_ADDR_WIDTH-1:2] 	mc_config_bus_addr,
    output 				mc_config_bus_ready,
    input 				mc_config_bus_write,//0 = read , 1= write
    input 				mc_config_bus_valid,
    input [CONFIG_BUS_DATA_WIDTH-1:0] 	mc_config_bus_wdata,
    //input [CONFIG_BUS_DATA_WIDTH/8-1:0] mc_config_bus_wstrb, // byte-wise strobe
    output [CONFIG_BUS_DATA_WIDTH-1:0] 	mc_config_bus_rdata,
    output 				mc_config_bus_error, // 0=ok, 1= transaction error
`endif //  `ifndef FPGA

    // **************************************************************************
    // ----- DRAM Interface-------------------------------------------------------
    // **************************************************************************
    output 				c0_ddr4_act_n,
    output [16:0] 			c0_ddr4_adr,
    output [1:0] 			c0_ddr4_ba,
    output [1:0] 			c0_ddr4_bg,
    output [0:0] 			c0_ddr4_cke,
    output [0:0] 			c0_ddr4_odt,
    output [0:0] 			c0_ddr4_cs_n,
    output [0:0] 			c0_ddr4_ck_t,
    output [0:0] 			c0_ddr4_ck_c,
    output 				c0_ddr4_reset_n,
    inout [7:0] 			c0_ddr4_dm_dbi_n,
    inout [63:0] 			c0_ddr4_dq,
    inout [7:0] 			c0_ddr4_dqs_c,
    inout [7:0] 			c0_ddr4_dqs_t,

    output 				c0_init_calib_complete,
    output 				c0_data_compare_error
    );

`ifndef FPGA
   
   // **************************************************************************
   // ----- Phy Interface ------------------------------------------------------
   // **************************************************************************
   // RESET FOR DATA_BUS AND ADR_CMD_BUS
   logic 				reset_n_dat;
   logic 				reset_n_adr;
   logic 				clk_t_adr;
   logic 				clk_c_adr;
   logic 				clk_t_dat;
   logic 				clk_c_dat;
   
   // Inteface to DATA_BUS
   logic [3:0] 				cwl;
   logic [3:0] 				cl;
   
   // IMPEDANCE SELECTION
   logic [4:0] 				ctrl_phy_config_ron_data;
   logic [4:0] 				ctrl_phy_config_rtt_data;
   logic [4:0] 				ctrl_phy_config_ron_adr_cmd;
   
   // IMPEDANCE CALIBRATION OVERRIGHT DEBUG
   logic [4:0] 				ctrl_phy_config_pu_en_ocd_cal;
   logic [4:0] 				ctrl_phy_config_pd_en_ocd_cal;
   logic 				ctrl_phy_config_disable_ocd_cal;

   // SLEW RATE CONFIG
   logic [1:0] 				ctrl_phy_config_td_ctrl_n_data;
   logic 				ctrl_phy_config_tdqs_trim_n_data;
   logic [1:0] 				ctrl_phy_config_td_ctrl_n_adr_cmd;
   logic 				ctrl_phy_config_tdqs_trim_n_adr_cmd;

   logic [8:0] 				delay_dqs_offset;
   logic [8:0] 				delay_clk_offset;

   logic 				reset_m_n;
   logic 				clk_oe;
   logic 				ocd_oe;
   logic 				slot_cnt_en;
   logic 				data_slot_cnt_en;
   logic 				start_dll;
   logic 				start_ocd_cal;
   logic 				iddq_n;// DATA RECEIVER BIAS EN
`endif //  `ifndef FPGA

   // *************************************************************************
    // to phy
    // *************************************************************************
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] ctrl_addr;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] ctrl_bank;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 ctrl_cmd;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 ctrl_data_cmd;
   logic [AXI4_ID_WIDTH-1:0] 			 ctrl_cas_cmd_id;
   logic [CLK_RATIO-1:0] 			 ctrl_act_n;
   logic 					 ctrl_valid;
   logic [$clog2(CLK_RATIO)-1:0] 		 ctrl_cas_slot;
   logic 					 ctrl_write;
   logic 					 ctrl_read;

   // *************************************************************************
   // from phy
   // *************************************************************************
   // bus_rdy tells mem_controller if data bus is rdy
`ifdef FPGA
   logic 					 cal_done;
`else
   logic 					 bus_rdy;
   logic [31:0] 				 phy_status_reg_1;
   logic [31:0] 				 phy_status_reg_2;
`endif
   // **************************************************************************
   //write buffer
   // **************************************************************************
   logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_w_data;
   logic 					 ctrl_w_grant;

   // *************************************************************************
   //read buffer
   // *************************************************************************
   logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_r_data;
   logic [AXI4_ID_WIDTH-1:0] 			 ctrl_r_id;
   logic 					 ctrl_r_valid;

`ifdef FPGA
   // UI Clk from Mig Phy
   logic 					 c0_ddr4_clk;
   logic 					 c0_ddr4_rst;


   // Generelize the width
   wire [4:0] 				dBufAdr;
   wire [511:0] 			wrData;
   logic [63:0] 			wrDataMask;
   wire [511:0] 			rdData;
   wire [4:0] 				rdDataAddr;
   wire [0:0] 				rdDataEn;
   wire [0:0] 				rdDataEnd;
   wire [0:0] 				per_rd_done;
   wire [0:0] 				rmw_rd_done;
   wire [4:0] 				wrDataAddr;
   wire [0:0] 				wrDataEn;
   wire [7:0] 				mc_ACT_n;
   wire [135:0] 			mc_ADR;
   wire [15:0] 				mc_BA;
   wire [15:0] 				mc_BG;
   wire [7:0] 				mc_CKE;
   wire [7:0] 				mc_CS_n;
   wire [7:0] 				mc_ODT;
   wire [1:0] 				mcCasSlot;
   wire [0:0] 				mcCasSlot2;
   wire [0:0] 				mcRdCAS;
   wire [0:0] 				mcWrCAS;
   wire [0:0] 				winInjTxn;
   wire [0:0] 				winRmw;
   wire [4:0] 				winBuf;
   wire [1:0] 				winRank;
   wire [5:0] 				tCWL;
   wire 				dbg_clk;
   logic 				wrDataEn_q;
   

   assign ui_clk_out = c0_ddr4_clk;
   assign ui_rst_n_out = ~c0_ddr4_rst;
   assign cal_done = c0_init_calib_complete;
`endif
   
   mem_ctrl_top
    `ifndef GATE_LEVEL2
     #(
       .AXI4_ADDRESS_WIDTH(AXI4_ADDRESS_WIDTH),
       .AXI4_RDATA_WIDTH(AXI4_RDATA_WIDTH),
       .AXI4_WDATA_WIDTH(AXI4_WDATA_WIDTH),
       .AXI4_ID_WIDTH(AXI4_ID_WIDTH),
       .AXI4_USER_WIDTH(AXI4_USER_WIDTH),
       .AXI_BURST_LENGTH(AXI_BURST_LENGTH),
       .AXI_NUMBYTES(AXI4_WDATA_WIDTH/8),
       // ----------------------------------------------------------------------
       .BANK_FIFO_DEPTH(BANK_FIFO_DEPTH),
       .ROW_ADDR_WIDTH(ROW_ADDR_WIDTH),
       .COL_ADDR_WIDTH(COL_ADDR_WIDTH),
       .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
       .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH),
       .DRAM_BANKS(DRAM_BANKS),
       .DRAM_BUS_WIDTH(DRAM_BUS_WIDTH),
       // ----------------------------------------------------------------------
       .CAS_EVEN_SLOT(CAS_EVEN_SLOT),
       .CLK_RATIO(CLK_RATIO),
       // ----------------------------------------------------------------------
       .RESET_LOW_TIME(RESET_LOW_TIME),
       .RESET_HIGH_TIME(RESET_HIGH_TIME),
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
       .RG_REF_NUM_ROW_PER_REF_LOG2(RG_REF_NUM_ROW_PER_REF_LOG2),
       .CWL_LOG2(CWL_LOG2),
       .BL_LOG2(BL_LOG2),
       .ZQS_DRAM_CYCLES_LOG2(ZQS_DRAM_CYCLES_LOG2),
       .ZQSI_AREFI_CYCLES(ZQSI_AREFI_CYCLES), // ZQ short interval
       .RRD_DRAM_CYCLES(RRD_DRAM_CYCLES),
       .WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
       .CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
     `ifdef DDR4
       .RRD_DRAM_CYCLES_L(RRD_DRAM_CYCLES_L),
       .WTR_DRAM_CYCLES_L(WTR_DRAM_CYCLES_L),
       .CCD_DRAM_CYCLES_L(CCD_DRAM_CYCLES_L),
     `endif
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
       .CONFIG_BUS_ADDR_WIDTH(CONFIG_BUS_ADDR_WIDTH),
       .CONFIG_BUS_DATA_WIDTH(CONFIG_BUS_DATA_WIDTH),
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
     `ifdef DDR4
       .CONGEN_CONFIG_R16(CONGEN_CONFIG_R16),
     `endif
       .CONGEN_CONFIG_B0(CONGEN_CONFIG_B0),
       .CONGEN_CONFIG_B1(CONGEN_CONFIG_B1),
       .CONGEN_CONFIG_B2(CONGEN_CONFIG_B2),
     `ifdef DDR4
       .CONGEN_CONFIG_B3(CONGEN_CONFIG_B3),
     `endif
       .CONGEN_XOR_SEL(CONGEN_XOR_SEL),
       .DECODER_TYPE(DECODER_TYPE)
       )
   `endif
   mem_ctrl_top
     (
   `ifdef FPGA
      .clk(c0_ddr4_clk),
   `else
      .clk_t_adr(clk_t_adr),
      .clk_c_adr(clk_c_adr),
      .clk_t_dat(clk_t_dat),
      .clk_c_dat(clk_c_dat),
      .clk_axi_out(clk_axi_out),
   `endif
      .rst_n(~c0_ddr4_rst),
      // **************************************************************************
      // ----- AXI write address bus ----------------------------------------------
      // **************************************************************************
      .AWID(AWID),
      .AWADDR(AWADDR),
      .AWLEN(AWLEN),
      //  .AWSIZE(AWSIZE),
      //  .AWBURST(AWBURST),
      //  .AWLOCK(AWLOCK),
      //  .AWCACHE(AWCACHE),
      //  .AWPROT(AWPROT),
      //  .AWREGION(AWREGION),
      //  .AWUSER(AWUSER),
      //  .AWQOS(AWQOS),
      .AWVALID(AWVALID),
      .AWREADY(AWREADY),
      // **************************************************************************
      // ----- AXI write data bus -------------------------------------------------
      // **************************************************************************
      .WDATA(WDATA),
      //   .WSTRB(WSTRB),
      .WLAST(WLAST),
      //   .WUSER(WUSER),
      .WVALID(WVALID),
      .WREADY(WREADY),
      // **************************************************************************
      // ----- AXI write response bus ---------------------------------------------
      // **************************************************************************
      .BID(BID),
      .BRESP(BRESP),
      .BVALID(BVALID),
      //  .BUSER(BUSER),
      .BREADY(BREADY),
      // **************************************************************************
      // ----- AXI read address bus -----------------------------------------------
      // **************************************************************************
      .ARID(ARID),
      .ARADDR(ARADDR),
      //  .ARLEN(ARLEN),
      //  .ARSIZE(ARSIZE),
      //  .ARBURST(ARBURST),
      //  .ARLOCK(ARLOCK),
      //  .ARCACHE(ARCACHE),
      //  .ARPROT(ARPROT),
      //  .ARREGION(ARREGION),
      //  .ARUSER(ARUSER),
      //  .ARQOS(ARQOS),
      .ARVALID(ARVALID),
      .ARREADY(ARREADY),
      // **************************************************************************
      // ----- AXI read data bus --------------------------------------------------
      // **************************************************************************
      .RID(RID),
      .RDATA(RDATA),
      .RRESP(RRESP),
      .RLAST(RLAST),
      //  .RUSER(RUSER),
      .RVALID(RVALID),
      .RREADY(RREADY),
      // **************************************************************************
      // ----- Config bus ---------------------------------------------------------
      // **************************************************************************
   `ifndef FPGA
      .mc_config_bus_addr(mc_config_bus_addr),
      .mc_config_bus_write(mc_config_bus_write),
      .mc_config_bus_error(mc_config_bus_error),
      .mc_config_bus_valid(mc_config_bus_valid),
      .mc_config_bus_ready(mc_config_bus_ready),
      .mc_config_bus_wdata(mc_config_bus_wdata),
      //.mc_config_bus_wstrb(mc_config_bus_wstrb),
      .mc_config_bus_rdata(mc_config_bus_rdata),
      
      // **************************************************************************
      // ----- Phy Interface ------------------------------------------------------
      // **************************************************************************
      // RESET FOR DATA_BUS AND ADR_CMD_BUS
      .reset_n_dat(reset_n_dat),
      .reset_n_adr(reset_n_adr),

      // interface from dram init block to phy
      .reset_m_n(reset_m_n),
      .clk_oe(clk_oe),
      .ocd_oe(ocd_oe),
      .slot_cnt_en(slot_cnt_en),
      .data_slot_cnt_en(data_slot_cnt_en),
      .start_dll(start_dll),
      .start_ocd_cal(start_ocd_cal),
      .iddq_n(iddq_n),

      // Inteface to/from Phy DATA_BUS
      .cwl(cwl),
      .cl(cl),

      //phy config
      .ctrl_phy_config_ron_data(ctrl_phy_config_ron_data),
      .ctrl_phy_config_rtt_data(ctrl_phy_config_rtt_data),
      .ctrl_phy_config_ron_adr_cmd(ctrl_phy_config_ron_adr_cmd),
      .ctrl_phy_config_pu_en_ocd_cal(ctrl_phy_config_pu_en_ocd_cal),
      .ctrl_phy_config_pd_en_ocd_cal(ctrl_phy_config_pd_en_ocd_cal),
      .ctrl_phy_config_disable_ocd_cal(ctrl_phy_config_disable_ocd_cal),
      .ctrl_phy_config_td_ctrl_n_data(ctrl_phy_config_td_ctrl_n_data),
      .ctrl_phy_config_tdqs_trim_n_data(ctrl_phy_config_tdqs_trim_n_data),
      .ctrl_phy_config_td_ctrl_n_adr_cmd(ctrl_phy_config_td_ctrl_n_adr_cmd),
      .ctrl_phy_config_tdqs_trim_n_adr_cmd(ctrl_phy_config_tdqs_trim_n_adr_cmd),
      .delay_dqs_offset(delay_dqs_offset),
      .delay_clk_offset(delay_clk_offset),
      
      .bus_rdy(bus_rdy),
      .phy_status_reg_1(phy_status_reg_1),
      .phy_status_reg_2(phy_status_reg_2),
   `endif //  `ifndef FPGA

   `ifdef FPGA
      .cal_done(cal_done),
   `endif
      //ctrl addr and cmd interface
      .ctrl_addr(ctrl_addr),
      .ctrl_bank(ctrl_bank),
      .ctrl_cmd(ctrl_cmd),
      .ctrl_act_n(ctrl_act_n),
    `ifndef FPGA
      .ctrl_data_cmd(ctrl_data_cmd),  //New in mem_ctrl_top
    `endif
      .ctrl_cas_cmd_id(ctrl_cas_cmd_id),
      .ctrl_write(ctrl_write),
      .ctrl_read(ctrl_read),
      .ctrl_w_data(wrData),
    `ifdef FPGA
      .ctrl_w_grant(wrDataEn_q),
      .ctrl_valid(ctrl_valid),
      .ctrl_cas_slot(ctrl_cas_slot),
    `endif
      .ctrl_r_data(rdData),
      .ctrl_r_id(ctrl_r_id),
      .ctrl_r_valid(rdDataEn)
      );

    `ifdef FPGA
   
   
   // FIFO FOR AXI READ ID
   // Xilinx phy has winBuf signal for this purpose use that it in future
   generic_fifo 
     #(
       .DATA_WIDTH(AXI4_ID_WIDTH),
       .DATA_DEPTH(16)
       ) axi_read_id_buffer
       (
	.clk(c0_ddr4_clk),
	.rst_n(~c0_ddr4_rst),
	// PUSH SIDE
	.data_i(ctrl_cas_cmd_id),           // INPUT FROM MEM_CNTRL
	.valid_i(ctrl_read),                // INTERNAL FLIP FLOP TO PUSH READ_ID
	.grant_o(),                         // GRANT STATUS
	// POP SIDE
	.data_o(ctrl_r_id),                 // OUTPUT TO MEM_CNTRL
	.valid_o(),                         // VALID STATUS
	.grant_i(rdDataEn),                 // INTERNAL FLIP FLOP TO POPE READ_ID 
	.test_mode_i(1'b0)
	);

   //assign wrDataMask = wrDataEn?'1:'0;

   always_ff @(posedge c0_ddr4_clk, posedge c0_ddr4_rst)
     begin
	if(c0_ddr4_rst == 1'b1)
	  begin
	     wrDataMask <= '1;
	     wrDataEn_q <= '0;
	  end
	else
	  begin
	     if(wrDataEn) begin
		wrDataMask <= '0;
		wrDataEn_q <= 1'b1;
	     end
	     else begin
		wrDataMask <= '1;
		wrDataEn_q <= 1'b0;
	     end
	  end // else: !if(c0_ddr4_rst == 1'b1)
     end // always_ff @ (posedge c0_ddr4_clk, posedge c0_ddr4_rst)
   
   
	
      
   xiphy_ultrascale_if
  #(
    .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
    .CLK_RATIO(CLK_RATIO),
    .DRAM_BANKS(DRAM_BANKS),
    .AXI4_ID_WIDTH(AXI4_ID_WIDTH),
    .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH)
    ) xiphy_ultrascale_if
    (
     .clk(c0_ddr4_clk),
     .rst_n(~c0_ddr4_rst),
     .ctrl_addr(ctrl_addr),
     .ctrl_bank(ctrl_bank),
     .ctrl_cmd(ctrl_cmd),
     .ctrl_act_n(ctrl_act_n),
     .ctrl_valid(ctrl_valid),
     .ctrl_cas_cmd_id(ctrl_cas_cmd_id),
     .ctrl_write(ctrl_write),
     .ctrl_read(ctrl_read),
     .ctrl_cas_slot(ctrl_cas_slot),
     .rdDataEn(rdDataEn),
    
     .dBufAdr(dBufAdr),
       
     .mc_ACT_n(mc_ACT_n),
     .mc_ADR(mc_ADR),
     .mc_BA(mc_BA),
     .mc_BG(mc_BG),
     .mc_CKE(mc_CKE),
     .mc_CS_n(mc_CS_n),
     .mc_ODT(mc_ODT),
     .mcCasSlot(mcCasSlot),
     .mcCasSlot2(mcCasSlot2),
     .mcRdCAS(mcRdCAS),
     .mcWrCAS(mcWrCAS),
     .winInjTxn(winInjTxn),
     .winRmw(winRmw),
     .gt_data_ready(gt_data_ready),
     .winBuf(winBuf),
     .winRank(winRank)
     );

   ddr4_0 ddr4_phy
     (
      .sys_rst              (~sys_rst_n),
      .c0_sys_clk_p         (c0_sys_clk_p),
      .c0_sys_clk_n         (c0_sys_clk_n),
      
      .c0_ddr4_ui_clk       (c0_ddr4_clk),
      .c0_ddr4_ui_clk_sync_rst (c0_ddr4_rst),
      .c0_init_calib_complete (c0_init_calib_complete),
      .dbg_clk              (dbg_clk),
      .c0_ddr4_act_n        (c0_ddr4_act_n),
      .c0_ddr4_adr          (c0_ddr4_adr),
      .c0_ddr4_ba           (c0_ddr4_ba),
      .c0_ddr4_bg           (c0_ddr4_bg),
      .c0_ddr4_cke          (c0_ddr4_cke),
      .c0_ddr4_odt          (c0_ddr4_odt),
      .c0_ddr4_cs_n         (c0_ddr4_cs_n),
      .c0_ddr4_ck_t         (c0_ddr4_ck_t),
      .c0_ddr4_ck_c         (c0_ddr4_ck_c),
      .c0_ddr4_reset_n      (c0_ddr4_reset_n),
      .c0_ddr4_dm_dbi_n     (c0_ddr4_dm_dbi_n),
      .c0_ddr4_dq           (c0_ddr4_dq),
      .c0_ddr4_dqs_c        (c0_ddr4_dqs_c),
      .c0_ddr4_dqs_t        (c0_ddr4_dqs_t),

      .dBufAdr              (dBufAdr),
      .wrData               (wrData),
      .wrDataMask           (wrDataMask),

      .rdData               (rdData),
      .rdDataAddr           (),
      .rdDataEn             (rdDataEn),
      .rdDataEnd            (),
      .per_rd_done          (),
      .rmw_rd_done          (),
      .wrDataAddr           (),
      .wrDataEn             (wrDataEn),

      .mc_ACT_n             (mc_ACT_n),
      .mc_ADR               (mc_ADR),
      .mc_BA                (mc_BA),
      .mc_BG                (mc_BG),
      .mc_CKE               (mc_CKE),
      .mc_CS_n              (mc_CS_n),
      .mc_ODT               (mc_ODT),
      .mcCasSlot            (mcCasSlot),
      .mcCasSlot2           (mcCasSlot2),
      .mcRdCAS              (mcRdCAS),
      .mcWrCAS              (mcWrCAS),
      .winInjTxn            (winInjTxn),
      .winRmw               (winRmw),
      .gt_data_ready        (gt_data_ready),
      .winBuf               (winBuf),
      .winRank              (winRank),
      .tCWL                 (tCWL),
      .dbg_bus              ()                                             
     
     );
    `endif //  `ifdef FPGA
   
endmodule // ddr4_mem_ch_top

