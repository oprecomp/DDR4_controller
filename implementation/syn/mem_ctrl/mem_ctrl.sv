// MEMORY CHANNEL TOP FILE (AXI -> MEMORY CONTROLLER -> x8 PHY)
// AUTHOR: Chirag Sudarshan, Jan Lappas, Deepak M. Mathew Christian Weis
// DATE: 21.03.2018

`include "light_phy.svh"

module mem_ctrl
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

    parameter CAS_EVEN_SLOT = 0, // accepted values are either 1 (for XI FPGA) or zero
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
    parameter DECODER_TYPE = 1'b0
    )
   (
    input 						 clk,
    input 						 rst_n,

   // **************************************************************************
   // ----- AXI write address bus ----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 				 AWID,
    input [AXI4_ADDRESS_WIDTH-1:0] 			 AWADDR,
    input [7:0] 					 AWLEN,
    input [2:0] 					 AWSIZE,
    input [1:0] 					 AWBURST,
    input 						 AWLOCK,
    input [3:0] 					 AWCACHE,
    input [2:0] 					 AWPROT,
    input [3:0] 					 AWREGION,
    input [AXI4_USER_WIDTH-1:0] 			 AWUSER,
    input [3:0] 					 AWQOS,
    input 						 AWVALID,
    output logic 					 AWREADY,

   // **************************************************************************
   // ----- AXI write data bus -------------------------------------------------
   // **************************************************************************
    input [AXI_NUMBYTES-1:0][7:0] 			 WDATA, 
    input [AXI_NUMBYTES-1:0] 				 WSTRB,
    input 						 WLAST,
    input [AXI4_USER_WIDTH-1:0] 			 WUSER,
    input 						 WVALID,
    output logic 					 WREADY,

   // **************************************************************************
   // ----- AXI write response bus ---------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 			 BID,
    output logic [1:0] 					 BRESP,
    output logic 					 BVALID,
    output logic [AXI4_USER_WIDTH-1:0] 			 BUSER,
    input 						 BREADY,

   // **************************************************************************
   // ----- AXI read address bus -----------------------------------------------
   // **************************************************************************
    input [AXI4_ID_WIDTH-1:0] 				 ARID,
    input [AXI4_ADDRESS_WIDTH-1:0] 			 ARADDR,
    input [7:0] 					 ARLEN,
    input [2:0] 					 ARSIZE,
    input [1:0] 					 ARBURST,
    input 						 ARLOCK,
    input [3:0] 					 ARCACHE,
    input [2:0] 					 ARPROT,
    input [3:0] 					 ARREGION,
    input [AXI4_USER_WIDTH-1:0] 			 ARUSER,
    input [ 3:0] 					 ARQOS,
    input 						 ARVALID,
    output logic 					 ARREADY,

   // **************************************************************************
   // ----- AXI read data bus --------------------------------------------------
   // **************************************************************************
    output logic [AXI4_ID_WIDTH-1:0] 			 RID,
    output logic [AXI4_RDATA_WIDTH-1:0] 		 RDATA,
    output logic [ 1:0] 				 RRESP,
    output logic 					 RLAST,
    output logic [AXI4_USER_WIDTH-1:0] 			 RUSER,
    output logic 					 RVALID,
    input 						 RREADY,
    // **************************************************************************
    // ----- Config bus ---------------------------------------------------------
    // **************************************************************************
    //reg_bus_if.slave mc_config_bus,
`ifndef FPGA
    input [CONFIG_BUS_ADDR_WIDTH-1:0] 			 mc_config_bus_addr,
    output 						 mc_config_bus_ready,
    input 						 mc_config_bus_write,//0 = read , 1= write
    input 						 mc_config_bus_valid,
    input [CONFIG_BUS_DATA_WIDTH-1:0] 			 mc_config_bus_wdata,
    input [CONFIG_BUS_DATA_WIDTH/8-1:0] 		 mc_config_bus_wstrb, // byte-wise strobe
    output [CONFIG_BUS_DATA_WIDTH-1:0] 			 mc_config_bus_rdata,
    output 						 mc_config_bus_error, // 0=ok, 1= transaction error


   // **************************************************************************
   // ----- Phy Interface ------------------------------------------------------
   // **************************************************************************
   // RESET FOR DATA_BUS AND ADR_CMD_BUS
    output logic 					 reset_n_phy,
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

    output logic 					 reset_m_n,
    output logic 					 clk_oe,
    output logic 					 ocd_oe,
    output logic 					 slot_cnt_en,
    //input logic 					 mem_data_bus_rdy,
    //output logic 					 mem_addr_cmd_write_valid,
    //output logic 					 mem_addr_cmd_read_valid,
    output logic 					 start_dll,
    output logic 					 start_ocd_cal,
    output logic 					 iddq_n, // DATA RECEIVER BIAS EN
`endif //  `ifndef FPGA
    
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
    output logic [AXI4_ID_WIDTH-1:0] 			 ctrl_cas_cmd_id,
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
    input logic [AXI4_ID_WIDTH-1:0] 			 ctrl_r_id,
    input logic 					 ctrl_r_valid,
    output logic 					 ctrl_r_grant

   );

   assign iddq_n = rst_n;       // PHY RECEIVER BIAS ALWAYS ON
   assign reset_n_phy = rst_n; // RESET PHY WITH MEM_CNTRL

   localparam FE_CMD_WIDTH = 1;
   localparam FE_WRITE = 0;
   localparam FE_ADDR_WIDTH = AXI4_ADDRESS_WIDTH;// $clog2(DRAM_BANKS) + ROW_ADDR_WIDTH +
			      //COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH) - 3;
   localparam FE_ID_WIDTH = AXI4_ID_WIDTH;

   //***************************** UI - AXI *****************************************

   logic 				fe_req;
   logic [FE_CMD_WIDTH-1:0] 		fe_cmd;
   logic [FE_ADDR_WIDTH-1:0] 		fe_addr;
   logic [FE_ID_WIDTH-1:0] 		fe_id;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_data;
   logic [DRAM_BUS_WIDTH/8*BL-1:0] 	fe_mask;
   logic 				fe_stall;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_read_data;
   logic [FE_ID_WIDTH-1:0] 		fe_read_id;
   logic 				fe_read_valid;
   logic 				fe_read_grant;
   logic 				data_r_stall;
`ifndef FPGA
   logic 						 mc_config_bus_clk;
   assign mc_config_bus_clk = clk;
`endif
   assign fe_read_grant = !data_r_stall;
   
   axi_dram_if
     #(
       .AXI4_ADDRESS_WIDTH(AXI4_ADDRESS_WIDTH),
       .AXI4_RDATA_WIDTH(AXI4_RDATA_WIDTH),
       .AXI4_WDATA_WIDTH(AXI4_WDATA_WIDTH),
       .AXI4_ID_WIDTH(AXI4_ID_WIDTH),
       .AXI4_USER_WIDTH(AXI4_USER_WIDTH),
       .AXI_BURST_LENGTH(AXI_BURST_LENGTH),
       .MEM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
       .FE_CMD_WIDTH(FE_CMD_WIDTH),
       .WRITE_CMD(FE_WRITE),
       .READ_CMD(1-FE_WRITE),
       .BUFF_DEPTH_SLAVE(BUFF_DEPTH_SLAVE),
       .DRAM_BUS_WIDTH(DRAM_BUS_WIDTH),
       .BL(BL),
       .MEM_ADDR_RANGE(FE_ADDR_WIDTH)
       ) axi_dram_if
       (
	.ACLK(clk),
	.ARESETn(rst_n),
	.AWID_i(AWID),
	.AWADDR_i(AWADDR),
	.AWLEN_i(AWLEN),
	.AWSIZE_i(AWSIZE),
	.AWBURST_i(AWBURST),
	.AWLOCK_i(AWLOCK),
	.AWCACHE_i(AWCACHE),
	.AWPROT_i(AWPROT),
	.AWREGION_i(AWREGION),
	.AWUSER_i(AWUSER),
	.AWQOS_i(AWQOS),
	.AWVALID_i(AWVALID),
	.AWREADY_o(AWREADY),
	.WDATA_i(WDATA),
	.WSTRB_i(WSTRB),
	.WLAST_i(WLAST),
	.WUSER_i(WUSER),
	.WVALID_i(WVALID),
	.WREADY_o(WREADY),
	.BID_o(BID),
	.BRESP_o(BRESP),
	.BVALID_o(BVALID),
	.BUSER_o(BUSER),
	.BREADY_i(BREADY),
	.ARID_i(ARID),
	.ARADDR_i(ARADDR),
	.ARLEN_i(ARLEN),
	.ARSIZE_i(ARSIZE),
	.ARBURST_i(ARBURST),
	.ARLOCK_i(ARLOCK),
	.ARCACHE_i(ARCACHE),
	.ARPROT_i(ARPROT),
	.ARREGION_i(ARREGION),
	.ARUSER_i(ARUSER),
	.ARQOS_i(ARQOS),
	.ARVALID_i(ARVALID),
	.ARREADY_o(ARREADY),
	.RID_o(RID),
	.RDATA_o(RDATA),
	.RRESP_o(RRESP),
	.RLAST_o(RLAST),
	.RUSER_o(RUSER),
	.RVALID_o(RVALID),
	.RREADY_i(RREADY),
	.data_addr_o(fe_addr),
	.data_cmd_o(fe_cmd),
	.data_req_o(fe_req),
	.data_wdata_o(fe_data),
	.data_mask_o(fe_mask),
	.data_ID_o(fe_id),
	.data_stall_i(fe_stall),
	.data_r_rdata_i(fe_read_data),
	.data_r_ID_i(fe_read_id),
	.data_r_valid_i(fe_read_valid),
	.data_r_stall_o(data_r_stall)
	);

   //*************************** channel controller ********************************************

   logic 				decoder_type;
   logic 				ctrl_valid_NA;
   //logic [3:0][4:0] 			ctrl_cmd;
   logic 				ctrl_r_grant_NA;
   logic 				ctrl_cas_cmd_id_valid_NA;

`ifndef FPGA   
   reg_bus_if
     #(.ADDR_WIDTH(CONFIG_BUS_ADDR_WIDTH),
       .DATA_WIDTH(CONFIG_BUS_DATA_WIDTH)
       ) mc_config_bus
       (
	.clk(mc_config_bus_clk)
	);
   phy_config_if ctrl_phy_config();
`endif
   
   assign decoder_type =  DECODER_TYPE;
   //assign mem_adr_cmd.cmd = ctrl_cmd;
   //assign cmd = ctrl_cmd;
   
`ifndef FPGA
   
   assign ctrl_phy_config_ron_data = ctrl_phy_config.ron_data;
   assign ctrl_phy_config_rtt_data = ctrl_phy_config.rtt_data;
   assign ctrl_phy_config_ron_adr_cmd = ctrl_phy_config.ron_adr_cmd;
   assign ctrl_phy_config_pu_en_ocd_cal = ctrl_phy_config.pu_en_ocd_cal;
   assign ctrl_phy_config_pd_en_ocd_cal = ctrl_phy_config.pd_en_ocd_cal;
   assign ctrl_phy_config_disable_ocd_cal = ctrl_phy_config.disable_ocd_cal;
   assign ctrl_phy_config_td_ctrl_n_data = ctrl_phy_config.td_ctrl_n_data;
   assign ctrl_phy_config_tdqs_trim_n_data = ctrl_phy_config.tdqs_trim_n_data;
   assign ctrl_phy_config_td_ctrl_n_adr_cmd = ctrl_phy_config.td_ctrl_n_adr_cmd;
   assign ctrl_phy_config_tdqs_trim_n_adr_cmd = ctrl_phy_config.tdqs_trim_n_adr_cmd;
   assign mc_config_bus.addr = mc_config_bus_addr;
   assign mc_config_bus.write = mc_config_bus_write;
   assign mc_config_bus_error = mc_config_bus.error;
   assign mc_config_bus.valid = mc_config_bus_valid;
   assign mc_config_bus_ready = mc_config_bus.ready;
   assign mc_config_bus.wdata = mc_config_bus_wdata;
   assign mc_config_bus.wstrb = mc_config_bus_wstrb;
   assign mc_config_bus_rdata = mc_config_bus.rdata;
`endif //  `ifndef FPGA

   ch_ctrl
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
       .FE_ID_WIDTH(AXI4_ID_WIDTH),
       .FE_WRITE(FE_WRITE),
       .RESET_LOW_TIME(RESET_LOW_TIME),
       .RESET_HIGH_TIME(RESET_HIGH_TIME),
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
       .CONGEN_XOR_SEL(CONGEN_XOR_SEL)
       ) ch_ctrl
       (
	.rst_n(rst_n),
	.clk(clk),
	.fe_req(fe_req),
	.fe_cmd(fe_cmd),
	.fe_addr(fe_addr),
	.fe_id(fe_id),
	.fe_data(fe_data),
	.fe_stall(fe_stall),
	.fe_read_data(fe_read_data),
	.fe_read_id(fe_read_id),
	.fe_read_valid(fe_read_valid),
	.fe_read_grant(fe_read_grant),
	.ctrl_addr(ctrl_addr),
	.ctrl_bank(ctrl_bank),
	.ctrl_cmd(ctrl_cmd),
`ifdef DDR4
	.ctrl_act_n(ctrl_act_n),
`endif
	.ctrl_valid(ctrl_valid),
	.ctrl_cas_cmd_id(ctrl_cas_cmd_id),
	.ctrl_cas_cmd_id_valid(ctrl_cas_cmd_id_valid),//NA
	.ctrl_write(ctrl_write),
	.ctrl_read(ctrl_read),
	.ctrl_cas_slot(ctrl_cas_slot),
	.ctrl_w_data(ctrl_w_data),
	.ctrl_w_valid(ctrl_w_valid),
	.ctrl_w_grant(ctrl_w_grant),//mem_data.grant_wr_data),//Phy accepts data along with cmd
	.ctrl_r_data(ctrl_r_data),
	.ctrl_r_id(ctrl_r_id),
	.ctrl_r_valid(ctrl_r_valid),
	.ctrl_r_grant(ctrl_r_grant),
`ifdef FPGA
	.cal_done(cal_done),
`else
	.reset_m_n(reset_m_n),
	.clk_oe(clk_oe),
	.ocd_oe(ocd_oe),
	.slot_cnt_en(slot_cnt_en),
	.start_ocdcal(start_ocd_cal),
	.start_dll(start_dll),
	.cwl(cwl),
	.cl(cl),
	.phy_config(ctrl_phy_config),
	.delay_dqs_offset(delay_dqs_offset),
	.delay_clk_offset(delay_clk_offset),
	.bus_rdy(bus_rdy),
	.phy_status_reg_1(phy_status_reg_1),
	.phy_status_reg_2(phy_status_reg_2),
	.mc_config_bus(mc_config_bus),
`endif
	.decoder_type(decoder_type)
	);


endmodule

