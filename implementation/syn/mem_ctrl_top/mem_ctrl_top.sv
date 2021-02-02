module mem_ctrl_top
  #(
    parameter AXI4_ADDRESS_WIDTH = 32,
    parameter AXI4_RDATA_WIDTH   = 64,
    parameter AXI4_WDATA_WIDTH   = 64,
    parameter AXI4_ID_WIDTH      = 16,
    parameter AXI4_USER_WIDTH    = 10,
    parameter AXI_BURST_LENGTH   = 1,
    parameter BUFF_DEPTH_SLAVE   = 2,
    parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,

    parameter BANK_FIFO_DEPTH = 8,
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
`ifdef DDR4
    parameter CONGEN_CONFIG_R16 = 5'd27,
`endif
    parameter CONGEN_CONFIG_B0  = 5'd21,
    parameter CONGEN_CONFIG_B1  = 5'd22,
    parameter CONGEN_CONFIG_B2  = 5'd23,
`ifdef DDR4
    parameter CONGEN_CONFIG_B3  = 5'd28,
`endif
    parameter CONGEN_XOR_SEL = 3'b0,
    parameter DECODER_TYPE = 1'b1
    )
   (
`ifdef FPGA
    input 						 clk,
`else
    input 						 clk_t,
    output 						 clk_t_adr,
    output 						 clk_c_adr,
    output 						 clk_t_dat,
    output 						 clk_c_dat,
    output 						 clk_axi_out,
`endif
    input 						 rst_n,
   // **************************************************************************
   // ----- AXI write address bus ----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 				 AWID,
    input [AXI4_ADDRESS_WIDTH-3:0] 			 AWADDR, // 31-30 nu - MSB  not used
    input [7:0] 					 AWLEN, 
 //   input [2:0] 			AWSIZE,  
 //   input [1:0] 			AWBURST,
 //   input 				AWLOCK,   // nu
 //   input [3:0] 			AWCACHE,  // nu
 //   input [2:0] 			AWPROT,   // nu
 //   input [3:0] 			AWREGION, // nu
 //   input [AXI4_USER_WIDTH-1:0] 	AWUSER,   // nu
 //   input [3:0] 			AWQOS,    // nu
    input 						 AWVALID,
    output logic 					 AWREADY,

   // **************************************************************************
   // ----- AXI write data bus -------------------------------------------------
   // **************************************************************************
    input [AXI_NUMBYTES-1:0][7:0] 			 WDATA, 
 //   input [AXI_NUMBYTES-1:0] 		WSTRB,
    input 						 WLAST, 
 //   input [AXI4_USER_WIDTH-1:0] 	WUSER,   // nu
    input 						 WVALID,
    output logic 					 WREADY,

   // **************************************************************************
   // ----- AXI write response bus ---------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 			 BID, 
    output logic [1:0] 					 BRESP, 
    output logic 					 BVALID,
 //   output logic [AXI4_USER_WIDTH-1:0] 	BUSER,   // nu
    input 						 BREADY,

   // **************************************************************************
   // ----- AXI read address bus -----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 				 ARID,
    input [AXI4_ADDRESS_WIDTH-3:0] 			 ARADDR, // 31 nu - MSB not used
 //   input [7:0] 			ARLEN,   // nu - fixed to zero intern
 //   input [2:0] 			ARSIZE,
 //   input [1:0] 			ARBURST,
 //   input 				ARLOCK,   // nu
 //   input [3:0] 			ARCACHE,  // nu
 //   input [2:0] 			ARPROT,   // nu
 //   input [3:0] 			ARREGION, // nu
 //   input [AXI4_USER_WIDTH-1:0] 	ARUSER,   // nu
 //   input [ 3:0] 			ARQOS,    // nu
    input 						 ARVALID,
    output logic 					 ARREADY,

   // **************************************************************************
   // ----- AXI read data bus --------------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 			 RID,
    output logic [AXI4_RDATA_WIDTH-1:0] 		 RDATA,
    output logic [ 1:0] 				 RRESP,
    output logic 					 RLAST,
 //   output logic [AXI4_USER_WIDTH-1:0] 	RUSER,  // nu
    output logic 					 RVALID,
    input 						 RREADY,

    // **************************************************************************
    // ----- Config bus ---------------------------------------------------------
    // **************************************************************************
    //reg_bus_if.slave mc_config_bus,
`ifndef FPGA
    input [CONFIG_BUS_ADDR_WIDTH-1:2] 			 mc_config_bus_addr, // lower 2 bits not used, CW
    output 						 mc_config_bus_ready,
    input 						 mc_config_bus_write,//0 = read , 1= write
    input 						 mc_config_bus_valid,
    input [CONFIG_BUS_DATA_WIDTH-1:0] 			 mc_config_bus_wdata,
  //  input [CONFIG_BUS_DATA_WIDTH/8-1:0] mc_config_bus_wstrb, // byte-wise strobe
    output [CONFIG_BUS_DATA_WIDTH-1:0] 			 mc_config_bus_rdata,
    output 						 mc_config_bus_error, // 0=ok, 1= transaction error

   // **************************************************************************
   // ----- Phy Interface ------------------------------------------------------
   // **************************************************************************
   // RESET FOR DATA_BUS AND ADR_CMD_BUS
    output logic 					 reset_n_dat,
    output logic 					 reset_n_adr,
   // Inteface to DATA_BUS
    output logic [3:0] 					 cwl,
    output logic [3:0] 					 cl,
    //phy_config_if.mem_cntrl phy_config,
       // IMPEDANCE SELECTION
    output [4:0] 					 ctrl_phy_config_ron_data,
    output [4:0] 					 ctrl_phy_config_rtt_data,
    output [4:0] 					 ctrl_phy_config_ron_adr_cmd,
   // IMPEDANCE CALIBRATION OVERRIGHT DEBUG
    output [4:0] 					 ctrl_phy_config_pu_en_ocd_cal,
    output [4:0] 					 ctrl_phy_config_pd_en_ocd_cal,
    output 						 ctrl_phy_config_disable_ocd_cal,
   // SLEW RATE CONFIG
    output [1:0] 					 ctrl_phy_config_td_ctrl_n_data,
    output 						 ctrl_phy_config_tdqs_trim_n_data,
    output [1:0] 					 ctrl_phy_config_td_ctrl_n_adr_cmd,
    output 						 ctrl_phy_config_tdqs_trim_n_adr_cmd,

    output logic [8:0] 					 delay_dqs_offset,
    output logic [8:0] 					 delay_clk_offset,

    // *************************************************************************
    // to phy
    // *************************************************************************
    output logic 					 reset_m_n,
    output logic 					 clk_oe,
    output logic 					 ocd_oe,
    output logic 					 slot_cnt_en,
    output logic 					 data_slot_cnt_en,
    //input logic 					 mem_data_bus_rdy,
    //output logic 					 mem_addr_cmd_write_valid,
    //output logic 					 mem_addr_cmd_read_valid,
    output logic 					 start_dll,
    output logic 					 start_ocd_cal,
    output logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 ctrl_data_cmd,
    output logic 					 iddq_n, // DATA RECEIVER BIAS EN
`endif //  `ifndef FPGA

    output logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 ctrl_addr,
    output logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] ctrl_bank,
    output logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 ctrl_cmd,
`ifdef DDR4
    output logic [CLK_RATIO-1:0] 			 ctrl_act_n,
`endif
`ifdef FPGA
    output logic 					 ctrl_valid,  // Not used in  TUKL phy - CW
    output logic [$clog2(CLK_RATIO)-1:0] 		 ctrl_cas_slot,  // NA for TUKL phy - CW
`endif
    output logic [AXI4_ID_WIDTH-1:0] 			 ctrl_cas_cmd_id,
    //output logic 					 ctrl_cas_cmd_id_valid, // NA  - CW
    output logic 					 ctrl_write,
    output logic 					 ctrl_read,
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
    //output logic 					 ctrl_w_valid, // Not used CW
`ifdef FPGA
    input logic 					 ctrl_w_grant,
`endif
    // *************************************************************************
    //read buffer
    // *************************************************************************
    input logic [DRAM_BUS_WIDTH*BL-1:0] 		 ctrl_r_data,
    input logic [AXI4_ID_WIDTH-1:0] 			 ctrl_r_id,
    input logic 					 ctrl_r_valid
    //output logic 					 ctrl_r_grant,  // Not used CW
  );
 
 // Not used signals // mem_ctrl
   wire ctrl_r_grant;
   wire ctrl_w_valid;
   wire ctrl_cas_cmd_id_valid;
   

   logic  reset_n_ctrl;
   
`ifndef FPGA
   logic ctrl_w_grant;
   wire ctrl_valid;
   wire [$clog2(CLK_RATIO)-1:0] 	 ctrl_cas_slot;
   
   assign ctrl_w_grant = ctrl_write;

 // Clock and reset generation and alignment
   logic  clk;
   logic  rst_n_del;
   logic  temp1, temp2, temp3;

   assign clk_t_adr =  clk_t;
   assign clk_c_adr = ~clk_t;
   assign clk_t_dat =  clk_t;
   assign clk_c_dat = ~clk_t;

   logic [1:0] 		clk_cnt;
   always_ff @(posedge clk_t , negedge rst_n) begin
      if( ~rst_n) begin
		 clk_cnt 		  <= 2'b11;
      end else begin
	 clk_cnt 		  <= clk_cnt + 2'd1;
      end
   end // always_ff @ (posedge clk_t , negedge rst_n) */

   assign clk = clk_cnt[1];
   assign clk_axi_out = clk;

   // Reset for Controller

   always_ff @(posedge clk_t , negedge rst_n) begin
      if( ~rst_n) begin
	 rst_n_del 		      <= 1'b0;
	 temp1                <= 1'b0;
	 temp2                <= 1'b0;
	 temp3                <= 1'b0;
      end else begin
	  temp1 		  <= rst_n;
	  temp2 		  <= temp1;
	  temp3 		  <= temp2;
	  rst_n_del 	  <= temp3;
      end
   end 
   assign reset_n_ctrl = rst_n_del & rst_n;

 // Assignments
  assign ctrl_data_cmd = ctrl_cmd;
  assign data_slot_cnt_en = slot_cnt_en;
 

  logic  reset_n_phy;
  assign reset_n_dat = reset_n_phy;
  assign reset_n_adr = reset_n_phy;

`else // !`ifndef FPGA
   
   assign reset_n_ctrl =  rst_n;

`endif

   mem_ctrl
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
       .CLK_RATIO(CLK_RATIO),
       .CAS_EVEN_SLOT(CAS_EVEN_SLOT),
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
   mem_ctrl
     (
      .clk(clk),
      .rst_n(reset_n_ctrl),
      // **************************************************************************
      // ----- AXI write address bus ----------------------------------------------
      // **************************************************************************
      .AWID(AWID),
      .AWADDR({2'b00,AWADDR}),
      .AWLEN(AWLEN),
      .AWSIZE(3'd0),
      .AWBURST(2'd0),
      .AWLOCK(1'b0),
      .AWCACHE(4'd0),
      .AWPROT(3'd0),
      .AWREGION(4'd0),
      .AWUSER(10'd0),
      .AWQOS(4'd0),
      .AWVALID(AWVALID),
      .AWREADY(AWREADY),
      // **************************************************************************
      // ----- AXI write data bus -------------------------------------------------
      // **************************************************************************
      .WDATA(WDATA), 
      .WSTRB('0),
      .WLAST(WLAST),
      .WUSER(10'd0),
      .WVALID(WVALID),
      .WREADY(WREADY),
      // **************************************************************************
      // ----- AXI write response bus ---------------------------------------------
      // **************************************************************************
      .BID(BID),
      .BRESP(BRESP),
      .BVALID(BVALID),
      .BUSER(),
      .BREADY(BREADY),
      // **************************************************************************
      // ----- AXI read address bus -----------------------------------------------
      // **************************************************************************
      .ARID(ARID),
      .ARADDR({2'b00,ARADDR}),
      .ARLEN(8'd0),
      .ARSIZE(3'd0),
      .ARBURST(2'd0),
      .ARLOCK(1'b0),
      .ARCACHE(4'd0),
      .ARPROT(3'd0),
      .ARREGION(4'd0),
      .ARUSER(10'd0),
      .ARQOS(4'd0),
      .ARVALID(ARVALID),
      .ARREADY(ARREADY),
      // **************************************************************************
      // ----- AXI read data bus --------------------------------------------------
      // **************************************************************************
      .RID(RID),
      .RDATA(RDATA),
      .RRESP(RRESP),
      .RLAST(RLAST),
      .RUSER(),
      .RVALID(RVALID),
      .RREADY(RREADY),
   
   `ifdef FPGA
      .cal_done(cal_done),
   `else
   
      // **************************************************************************
      // ----- Config bus ---------------------------------------------------------
      // **************************************************************************
      .mc_config_bus_addr({mc_config_bus_addr,2'b00}),
      .mc_config_bus_write(mc_config_bus_write),
      .mc_config_bus_error(mc_config_bus_error),
      .mc_config_bus_valid(mc_config_bus_valid),
      .mc_config_bus_ready(mc_config_bus_ready),
      .mc_config_bus_wdata(mc_config_bus_wdata),
      .mc_config_bus_wstrb(1'b0),
      .mc_config_bus_rdata(mc_config_bus_rdata),
      // **************************************************************************
      // ----- Phy Interface ------------------------------------------------------
      // **************************************************************************
      // RESET FOR DATA_BUS AND ADR_CMD_BUS
      .reset_n_phy(reset_n_phy),
      .reset_m_n(reset_m_n),

      // interface from dram init block to phy
      .clk_oe(clk_oe),
      .ocd_oe(ocd_oe),
      .slot_cnt_en(slot_cnt_en),
      .start_dll(start_dll),
      .start_ocd_cal(start_ocd_cal),
      .iddq_n(iddq_n),

      // Inteface to/from Phy DATA_BUS
      .cwl(cwl),
      .cl(cl),
      .bus_rdy(bus_rdy),

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

      //phy status
      .phy_status_reg_1(phy_status_reg_1),
      .phy_status_reg_2(phy_status_reg_2),
   `endif // !`ifdef FPGA
      
      //ctrl addr and cmd interface
      .ctrl_addr(ctrl_addr),
      .ctrl_bank(ctrl_bank),
      .ctrl_cmd(ctrl_cmd),
   `ifdef DDR4
      .ctrl_act_n(ctrl_act_n),
   `endif
      .ctrl_valid(ctrl_valid),
      .ctrl_cas_cmd_id(ctrl_cas_cmd_id),
      .ctrl_cas_cmd_id_valid(ctrl_cas_cmd_id_valid),
      .ctrl_write(ctrl_write),
      .ctrl_read(ctrl_read),
      .ctrl_cas_slot(ctrl_cas_slot),

      // write data interface from write buffer
      .ctrl_w_data(ctrl_w_data),
      .ctrl_w_valid(ctrl_w_valid),
      .ctrl_w_grant(ctrl_w_grant),//Phy accepts data along with cmd

      // read data interface from read buffer
      .ctrl_r_data(ctrl_r_data),
      .ctrl_r_id(ctrl_r_id),
      .ctrl_r_valid(ctrl_r_valid),
      .ctrl_r_grant(ctrl_r_grant) // phy assumes read fifo + overflow fifo is never full
      );
 

endmodule

