`timescale 1ps/1ps
`ifndef SYNTHESIS
 `include "arch_package.sv"
`endif

module tb_ddr4_mem_ch_top();

   localparam ADDR_WIDTH                    = 17;
   localparam DQ_WIDTH                      = 64;
   localparam DQS_WIDTH                     = 8;
   localparam DM_WIDTH                      = 8;
   localparam DRAM_WIDTH                    = 8;
   localparam tCK                           = 1250 ; //DDR4 interface clock period in ps
   localparam real SYSCLK_PERIOD            = tCK; 
   localparam NUM_PHYSICAL_PARTS = (DQ_WIDTH/DRAM_WIDTH) ;
   localparam           CLAMSHELL_PARTS = (NUM_PHYSICAL_PARTS/2);
   localparam           ODD_PARTS = ((CLAMSHELL_PARTS*2) < NUM_PHYSICAL_PARTS) ? 1 : 0;
   parameter RANK_WIDTH                       = 1;
   parameter CS_WIDTH                       = 1;
   parameter ODT_WIDTH                      = 1;
   parameter CA_MIRROR                      = "OFF";


   localparam MRS                           = 3'b000;
   localparam REF                           = 3'b001;
   localparam PRE                           = 3'b010;
   localparam ACT                           = 3'b011;
   localparam WR                            = 3'b100;
   localparam RD                            = 3'b101;
   localparam ZQC                           = 3'b110;
   localparam NOP                           = 3'b111;


   
   
   localparam cBEGIN_ADDRESS         = 32'h00000000;
   localparam cEND_ADDRESS           = 32'h1fffffff;
   localparam cPRBS_EADDR_MASK_POS   = 32'hff000000;
   localparam cENFORCE_RD_WR         = 0;
   localparam cENFORCE_RD_WR_CMD     = 8'h11;
   localparam cENFORCE_RD_WR_PATTERN = 3'b000;
   localparam cC_EN_WRAP_TRANS       = 0;
   localparam cC_AXI_NBURST_TEST     = 0;

   localparam cC_S_AXI_ID_WIDTH               = 16;
   localparam cC_S_AXI_ADDR_WIDTH             = 32;
   localparam cC_S_AXI_DATA_WIDTH             = 512;
   localparam cC_S_AXI_SUPPORTS_NARROW_BURST  = 0;

   localparam cDBG_WR_STS_WIDTH      = 40;
   localparam cDBG_RD_STS_WIDTH 	= 40;

   localparam cAXI4_WDATA_WIDTH= 64;

   localparam cCMD_ACT  = 4'b0011;
   localparam cCMD_PRE  = 4'b0010;
   localparam cCMD_RD   = 4'b0101;
   localparam cCMD_WR   = 4'b0100;
   localparam cCMD_REF  = 4'b0001;
   localparam cCMD_NOP 	= 4'b0111;
   localparam cCMD_DES 	= 4'b1111;
   localparam RRD_DRAM_CYCLES = 5;
   localparam WTR_DRAM_CYCLES = 2;
   localparam CCD_DRAM_CYCLES = 4;
   localparam RRD_DRAM_CYCLES_L = 5;
   localparam WTR_DRAM_CYCLES_L = 6;
   localparam CCD_DRAM_CYCLES_L = 5;

   localparam CL = 11;
   localparam CWL = 11;
   localparam RP_DRAM_CYCLES = 11;
   localparam WR_DRAM_CYCLES = 12;
   localparam RCD_DRAM_CYCLES = 11;
   localparam RAS_DRAM_CYCLES = 30;
 
   localparam BL = 8;
   localparam RTP_DRAM_CYCLES = 6;
   localparam FAW_DRAM_CYCLES = 20;
   localparam ZQS_DRAM_CYCLES = 128;
   localparam RFC_DRAM_CYCLES = 280;
   localparam AREFI_DRAM_CYCLES = 2880;
   localparam CONFIG_BUS_ADDR_WIDTH = 9;
   localparam CONFIG_BUS_DATA_WIDTH = 8;
   localparam ZQSI_TREFI_CYCLES = 128;

   localparam RESET_LOW_TIME =  16'b1100_0011_0101_0000;  // 50.000 cyc
   localparam RESET_HIGH_TIME = 16'b1111_1101_1110_1000;   // 65.000 cyc
   localparam AREFI_CNT_WIDTH = 20;
   localparam RFC_DRAM_CYCLES_LOG2 = 9;
   localparam RC_DRAM_CYCLES_LOG2 = 6;
   localparam RAS_DRAM_CYCLES_LOG2 = 6;
   localparam RP_DRAM_CYCLES_LOG2 = 4;
   localparam WR2PRE_DRAM_CYCLES_LOG2 = 8;
   localparam RD2PRE_DRAM_CYCLES_LOG2 = 8;
   localparam RCD_DRAM_CYCLES_LOG2 = 4;
   localparam RRD_DRAM_CYCLES_LOG2 = 4;
   localparam WR2RD_DRAM_CYCLES_LOG2 = 8;
   localparam RD2WR_DRAM_CYCLES_LOG2 = 8;
   localparam RG_REF_NUM_ROW_PER_REF_LOG2 = 6;
   localparam CWL_LOG2 = 4;
   localparam BL_LOG2 = 4;
   localparam ZQS_DRAM_CYCLES_LOG2 = 7;
   localparam RG_REF_NUM_ROW_PER_REF = 4;
   localparam RG_REF_START_ADDR = 0;
   localparam RG_REF_END_ADDR = 2**(16+3)-1;
   localparam RON_DATA = 5'b10011; //cRON48
   localparam RTT_DATA = 5'b00000; //cRTT60
   localparam RON_ADR_CMD = 5'b10011;
   localparam PU_EN_OCD_CAL = 5'b01001;
   localparam PD_EN_OCD_CAL = 5'b01001;
   localparam DISABLE_OCD_CAL = 1'b0;
`ifdef DLL_OFF
   localparam DISABLE_DLL_CAL = 1'b1; // internal controller dll off =1
   localparam DELAY_DQS_OFFSET = 9'b0_1110_1111; // dll off
   localparam DELAY_CLK_OFFSET = 9'b0_1110_1111; // dll off
`else
   localparam DISABLE_DLL_CAL = 1'b0; // internal controller dll on  =0
   localparam DELAY_DQS_OFFSET = 0;
   localparam DELAY_CLK_OFFSET = 0;
`endif
   localparam TD_CTRL_N_DATA = 0;
   localparam TD_CTRL_N_ADR_CMD = 0;
   localparam TDQS_TRIM_N_DATA = 0;
   localparam TDQS_TRIM_N_ADR_CMD = 0;
`ifdef CORNER_WC
   localparam MRS_INIT_REG0 = 16'b0000_0101_0010_0000; // cl 6
   localparam MRS_INIT_REG1 = 16'b0000_0000_0000_0000; // dll on 
   localparam MRS_INIT_REG2 = 16'b0000_0000_0000_0000; // cwl 5
   localparam MRS_INIT_REG3 = 16'b0000_0000_0000_0000;
`else
 `ifdef DLL_OFF
   // DLL off settings:
   localparam MRS_INIT_REG0 = 16'b0000_0100_0010_0000; //no dll reset, CL 6
   localparam MRS_INIT_REG1 = 16'b0000_0000_0000_0001; //dll off
   localparam MRS_INIT_REG2 = 16'b0000_0000_0000_1000; //cwl 6
   localparam MRS_INIT_REG3 = 16'b0000_0000_0000_0000;
 `else
   localparam MRS_INIT_REG0 = 16'b0000_0101_0011_0000; // cl 7
   localparam MRS_INIT_REG1 = 16'b0000_0000_0000_0000; // dll on 
   localparam MRS_INIT_REG2 = 16'b0000_0000_0000_1000; // cwl 6
   localparam MRS_INIT_REG3 = 16'b0000_0000_0000_0000;
 `endif
`endif // !`ifdef CORNER_WC
   //RBC
   localparam CONGEN_CONFIG_C3  = 5'd0; // consider '-3'
   localparam CONGEN_CONFIG_C4  = 5'd1;
   localparam CONGEN_CONFIG_C5  = 5'd2;
   localparam CONGEN_CONFIG_C6  = 5'd3;
   localparam CONGEN_CONFIG_C7  = 5'd4;
   localparam CONGEN_CONFIG_C8  = 5'd5;
   localparam CONGEN_CONFIG_C9  = 5'd6;
   localparam CONGEN_CONFIG_C10 = 5'd28;
   //c10 used only for 8 Gb, in such case c10 = d7 and all others are +1
   localparam CONGEN_CONFIG_B0  = 5'd7;
   localparam CONGEN_CONFIG_B1  = 5'd8;
   localparam CONGEN_CONFIG_B2  = 5'd9;
   localparam CONGEN_CONFIG_B3  = 5'd10;
   localparam CONGEN_CONFIG_R0  = 5'd11;
   localparam CONGEN_CONFIG_R1  = 5'd12;
   localparam CONGEN_CONFIG_R2  = 5'd13;
   localparam CONGEN_CONFIG_R3  = 5'd14;
   localparam CONGEN_CONFIG_R4  = 5'd15;
   localparam CONGEN_CONFIG_R5  = 5'd16;
   localparam CONGEN_CONFIG_R6  = 5'd17;
   localparam CONGEN_CONFIG_R7  = 5'd18;
   localparam CONGEN_CONFIG_R8  = 5'd19;
   localparam CONGEN_CONFIG_R9  = 5'd20;
   localparam CONGEN_CONFIG_R10 = 5'd21;
   localparam CONGEN_CONFIG_R11 = 5'd22;
   localparam CONGEN_CONFIG_R12 = 5'd23;
   localparam CONGEN_CONFIG_R13 = 5'd24;
   localparam CONGEN_CONFIG_R14 = 5'd25;
   localparam CONGEN_CONFIG_R15 = 5'd26;
   localparam CONGEN_CONFIG_R16 = 5'd27;
   localparam CONGEN_CONFIG_XOR_SEL  = 3'd0;

   typedef struct {
      // Slave Interface Write Address Ports
      logic [cC_S_AXI_ID_WIDTH-1:0] awid;
      logic [cC_S_AXI_ADDR_WIDTH-1:0] awaddr;
      logic [7:0] 		      awlen;
      logic [2:0] 		      awsize;
      logic [1:0] 		      awburst;
      logic 			      awlock;
      logic [3:0] 		      awcache;
      logic [2:0] 		      awprot;
      logic 			      awvalid;
      logic 			      awready;
      // Slave Interface Write Data Ports
      logic [cC_S_AXI_DATA_WIDTH-1:0] wdata;
      logic [(cC_S_AXI_DATA_WIDTH/8)-1:0] wstrb;
      logic                               wlast;
      logic                               wvalid;
      logic                               wready;
      // Slave Interface Write Response Ports
      logic 				  bready;
      logic [cC_S_AXI_ID_WIDTH-1:0] 	  bid;
      logic [1:0] 			  bresp;
      logic 				  bvalid;
      // Slave Interface Read Address Ports
      logic [cC_S_AXI_ID_WIDTH-1:0] 	  arid;
      logic [cC_S_AXI_ADDR_WIDTH-1:0] 	  araddr;
      logic [7:0] 			  arlen;
      logic [2:0] 			  arsize;
      logic [1:0] 			  arburst;
      logic 				  arlock;
      logic [3:0] 			  arcache;
      logic [2:0] 			  arprot;
      logic 				  arvalid;
      logic 				  arready;
      // Slave Interface Read Data Ports
      logic 				  rready;
      logic [cC_S_AXI_ID_WIDTH-1:0] 	  rid;
      logic [cC_S_AXI_DATA_WIDTH-1:0] 	  rdata;
      logic [1:0] 			  rresp;
      logic 				  rlast;
      logic 				  rvalid;
   } tAXI_BUS;

   tAXI_BUS s_axi;

   import arch_package::*;
   parameter UTYPE_density CONFIGURED_DENSITY = _8G;

   // Input clock is assumed to be equal to the memory clock frequency
   // User should change the parameter as necessary if a different input
   // clock frequency is used
   localparam real 			  CLKIN_PERIOD_NS = 5000 / 1000.0;

   //initial begin
   //   $shm_open("waves.shm");
   //   $shm_probe("ACMTF");
   //end

   reg 					  sys_clk_i;
   reg 					  sys_rst_n;

   reg 					  ui_clk;
   reg 					  ui_rst_n;
   
   wire 				  c0_sys_clk_p;
   wire 				  c0_sys_clk_n;
   
   reg [16:0] 				  c0_ddr4_adr_sdram[1:0];
   reg [1:0] 				  c0_ddr4_ba_sdram[1:0];
   reg [1:0] 				  c0_ddr4_bg_sdram[1:0];
   

   wire 				  c0_ddr4_act_n;
   wire [16:0] 				  c0_ddr4_adr;
   wire [1:0] 				  c0_ddr4_ba;
   wire [1:0] 				  c0_ddr4_bg;
   wire [0:0] 				  c0_ddr4_cke;
   wire [0:0] 				  c0_ddr4_odt;
   wire [0:0] 				  c0_ddr4_cs_n;

   wire [0:0] 				  c0_ddr4_ck_t_int;
   wire [0:0] 				  c0_ddr4_ck_c_int;

   wire 				  c0_ddr4_ck_t;
   wire 				  c0_ddr4_ck_c;

   wire 				  c0_ddr4_reset_n;
   
   wire [7:0] 				  c0_ddr4_dm_dbi_n;
   wire [63:0] 				  c0_ddr4_dq;
   wire [7:0] 				  c0_ddr4_dqs_c;
   wire [7:0] 				  c0_ddr4_dqs_t;
   wire 				  c0_init_calib_complete;
   wire 				  c0_data_compare_error;


   reg [31:0] 				  cmdName;
   bit 					  en_model;
   tri 					  model_enable = en_model;



   //**************************************************************************//
   // Reset Generation
   //**************************************************************************//
   initial begin
      sys_rst_n = 1'b1;
      #200
	sys_rst_n = 1'b0;
      en_model = 1'b0; 
      #5 en_model = 1'b1;
      #20000;
      sys_rst_n = 1'b1;
   end

   //**************************************************************************//
   // Clock Generation
   //**************************************************************************//
   
   initial
     sys_clk_i = 1'b0;
   always
     //sys_clk_i = #(3334/2.0) ~sys_clk_i;
     sys_clk_i = #(5000/2.0) ~sys_clk_i;

   assign c0_sys_clk_p = sys_clk_i;
   assign c0_sys_clk_n = ~sys_clk_i;


   always @( * ) begin
      c0_ddr4_adr_sdram[0]   <=  c0_ddr4_adr;
      c0_ddr4_adr_sdram[1]   <=  (CA_MIRROR == "ON") ?
                                       {c0_ddr4_adr[ADDR_WIDTH-1:14],
                                        c0_ddr4_adr[11], c0_ddr4_adr[12],
                                        c0_ddr4_adr[13], c0_ddr4_adr[10:9],
                                        c0_ddr4_adr[7], c0_ddr4_adr[8],
                                        c0_ddr4_adr[5], c0_ddr4_adr[6],
                                        c0_ddr4_adr[3], c0_ddr4_adr[4],
                                        c0_ddr4_adr[2:0]} :
                                        c0_ddr4_adr;
      c0_ddr4_ba_sdram[0]    <=  c0_ddr4_ba;
      c0_ddr4_ba_sdram[1]    <=  (CA_MIRROR == "ON") ?
                                        {c0_ddr4_ba[0],
                                         c0_ddr4_ba[1]} :
                                 c0_ddr4_ba;
      c0_ddr4_bg_sdram[0]    <=  c0_ddr4_bg;
      c0_ddr4_bg_sdram[1]    <=  (CA_MIRROR == "ON" && DRAM_WIDTH != 16) ?
                                 {c0_ddr4_bg[0],
                                  c0_ddr4_bg[1]} :
                                 c0_ddr4_bg;
   end



   //===========================================================================
   //                         FPGA Memory Controller instantiation
  //===========================================================================   
   ddr4_mem_ch_top
 `ifndef GATE_LEVEL
     #(
       .AXI4_ADDRESS_WIDTH(32),
       .AXI4_RDATA_WIDTH(512),
       .AXI4_WDATA_WIDTH(512),
       .AXI4_ID_WIDTH(16),
       .AXI4_USER_WIDTH(10),
       .AXI_BURST_LENGTH(1),
       .BUFF_DEPTH_SLAVE(2),
       .AXI_NUMBYTES(64),
       // ----------------------------------------------------------------------
       .BANK_FIFO_DEPTH(4),
       .ROW_ADDR_WIDTH(ADDR_WIDTH),
       .COL_ADDR_WIDTH(11),
       .DRAM_ADDR_WIDTH(ADDR_WIDTH),
       .DRAM_CMD_WIDTH(5),
       .DRAM_BANKS(16),
       .DRAM_BUS_WIDTH(64),
       // ----------------------------------------------------------------------
       .CLK_RATIO(4),
       // ----------------------------------------------------------------------
       .RESET_LOW_TIME(16'b1100_0011_0101_0000),  // 50.000 cyc
       .RESET_HIGH_TIME(16'b1111_1101_1110_1000),   // 65.000 cyc
       .AREFI_CNT_WIDTH(20),
       .RFC_DRAM_CYCLES_LOG2(RFC_DRAM_CYCLES_LOG2),
       .RC_DRAM_CYCLES_LOG2(RC_DRAM_CYCLES_LOG2),
       .RAS_DRAM_CYCLES_LOG2(RAS_DRAM_CYCLES_LOG2),
       .RP_DRAM_CYCLES_LOG2(RP_DRAM_CYCLES_LOG2),
       .WR2PRE_DRAM_CYCLES_LOG2(WR2PRE_DRAM_CYCLES_LOG2),
       .RD2PRE_DRAM_CYCLES_LOG2(RD2PRE_DRAM_CYCLES_LOG2),
       .RCD_DRAM_CYCLES_LOG2(RCD_DRAM_CYCLES_LOG2),
       .RRD_DRAM_CYCLES_LOG2(RRD_DRAM_CYCLES_LOG2),
       .WR2RD_DRAM_CYCLES_LOG2(WR2RD_DRAM_CYCLES_LOG2),
       .RD2WR_DRAM_CYCLES_LOG2(RD2WR_DRAM_CYCLES_LOG2),
       .RG_REF_NUM_ROW_PER_REF_LOG2(RG_REF_NUM_ROW_PER_REF_LOG2),
       .CWL_LOG2(CWL_LOG2),
       .BL_LOG2(BL_LOG2),
       .ZQSI_AREFI_CYCLES(ZQSI_TREFI_CYCLES),
       .RRD_DRAM_CYCLES(RRD_DRAM_CYCLES),
       .WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
       .CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
  
       .RRD_DRAM_CYCLES_L(RRD_DRAM_CYCLES_L),
       .WTR_DRAM_CYCLES_L(WTR_DRAM_CYCLES_L),
       .CCD_DRAM_CYCLES_L(CCD_DRAM_CYCLES_L),
  
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
       .RG_REF_END_ADDR(RG_REF_END_ADDR),
       .RON_DATA(RON_DATA),
       .RTT_DATA(RTT_DATA),
       .RON_ADR_CMD(RON_ADR_CMD),
       .PU_EN_OCD_CAL(PU_EN_OCD_CAL),
       .PD_EN_OCD_CAL(PD_EN_OCD_CAL),
       .DISABLE_OCD_CAL(DISABLE_OCD_CAL),
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

       .CONGEN_CONFIG_R16(CONGEN_CONFIG_R16),

       .CONGEN_CONFIG_B0(CONGEN_CONFIG_B0),
       .CONGEN_CONFIG_B1(CONGEN_CONFIG_B1),
       .CONGEN_CONFIG_B2(CONGEN_CONFIG_B2),

       .CONGEN_CONFIG_B3(CONGEN_CONFIG_B3),
  
       .CONGEN_XOR_SEL(3'd0),
       .DECODER_TYPE(1)
       )
   `endif
   dut
     (
      .c0_sys_clk_p(c0_sys_clk_p),
      .c0_sys_clk_n(c0_sys_clk_n),
      .sys_rst_n(sys_rst_n),

      .ui_clk_out(ui_clk),
      .ui_rst_n_out(ui_rst_n),
      
      // **************************************************************************
      // ----- AXI write address bus ----------------------------------------------
      // **************************************************************************
      .AWID(s_axi.awid),
      .AWADDR(s_axi.awaddr[cC_S_AXI_ADDR_WIDTH-3:0]),
      .AWLEN(s_axi.awlen),
      //.AWSIZE(s_axi.awsize),
      //.AWBURST(s_axi.awburst),
      //.AWLOCK(s_axi.awlock[0]),
      //.AWCACHE(s_axi.awcache),
      //.AWPROT(s_axi.awprot),
      //.AWREGION(),
      //.AWUSER(),
      //.AWQOS(),
      .AWVALID(s_axi.awvalid),
      .AWREADY(s_axi.awready),
      // **************************************************************************
      // ----- AXI write data bus -------------------------------------------------
      // **************************************************************************
      .WDATA(s_axi.wdata),
      //.WSTRB(s_axi.wstrb),
      .WLAST(s_axi.wlast),
      //.WUSER(),
      .WVALID(s_axi.wvalid),
      .WREADY(s_axi.wready),
      // **************************************************************************
      // ----- AXI write response bus ---------------------------------------------
      // **************************************************************************
      .BID(s_axi.bid),
      .BRESP(s_axi.bresp),
      .BVALID(s_axi.bvalid),
      //.BUSER(),
      .BREADY(s_axi.bready),
      // **************************************************************************
      // ----- AXI read address bus -----------------------------------------------
      // **************************************************************************
      .ARID(s_axi.arid),
      .ARADDR(s_axi.araddr[cC_S_AXI_ADDR_WIDTH-3:0]),
      //.ARLEN(s_axi.arlen),
      //.ARSIZE(s_axi.arsize),
      //.ARBURST(s_axi.arburst),
      //.ARLOCK(s_axi.arlock[0]),
      //.ARCACHE(s_axi.arcache),
      //.ARPROT(s_axi.arprot),
      //.ARREGION(),
      //.ARUSER(),
      //.ARQOS(),
      .ARVALID(s_axi.arvalid),
      .ARREADY(s_axi.arready),
      // **************************************************************************
      // ----- AXI read data bus --------------------------------------------------
      // **************************************************************************
      .RID(s_axi.rid),
      .RDATA(s_axi.rdata),
      .RRESP(s_axi.rresp),
      .RLAST(s_axi.rlast),
      //.RUSER(),
      .RVALID(s_axi.rvalid),
      .RREADY(s_axi.rready),
      // **************************************************************************
      // ----- Config bus ---------------------------------------------------------
      // **************************************************************************
   `ifndef FPGA
      //.mc_config_bus(config_bus),
      //.mc_config_bus_clk(tb.clk),
      //.mc_config_bus_rst_n(tb.reset_n),
      .mc_config_bus_addr(config_bus.addr[CONFIG_BUS_ADDR_WIDTH-1:2]),
      .mc_config_bus_write(config_bus.write),
      .mc_config_bus_error(config_bus.error),
      .mc_config_bus_valid(config_bus.valid),
      .mc_config_bus_ready(config_bus.ready),
      .mc_config_bus_wdata(config_bus.wdata),
      //.mc_config_bus_wstrb(config_bus.wstrb),
      .mc_config_bus_rdata(config_bus.rdata),
   `endif
      // ------ DRAM INTERFACE ------------------
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
      .c0_ddr4_dqs_t        (c0_ddr4_dqs_t)
      );

   // **************************************************************************
   // TUK AXI_TGEN
   // **************************************************************************
   TGEN
     #(
      .AXI4_ADDRESS_WIDTH(32),
      .AXI4_RDATA_WIDTH(512),
      .AXI4_WDATA_WIDTH(512),
      .AXI4_ID_WIDTH(16),
      .AXI4_USER_WIDTH(10),
      .AXI_NUMBYTES(64)
       )axi4_tg
     (
      .ACLK (ui_clk),
      .ARESETn (ui_rst_n),
      .AWID (s_axi.awid),
      .AWADDR (s_axi.awaddr),
      .AWLEN (s_axi.awlen),
      .AWSIZE (s_axi.awsize),
      .AWBURST (s_axi.awburst),
      .AWLOCK (s_axi.awlock),
      .AWCACHE(s_axi.awcache),
      .AWPROT(s_axi.awprot),
      .AWREGION(),
      .AWUSER(),
      .AWQOS(),
      .AWVALID(s_axi.awvalid),
      .AWREADY (s_axi.awready),
      .WDATA(s_axi.wdata),
      .WSTRB(s_axi.wstrb),
      .WLAST(s_axi.wlast),
      .WUSER(),
      .WVALID(s_axi.wvalid),
      .WREADY(s_axi.wready),
      .BID(s_axi.bid),
      .BRESP(s_axi.bresp),
      .BVALID(s_axi.bvalid),
      .BUSER(),
      .BREADY(s_axi.bready),
      .ARID(s_axi.arid),
      .ARADDR(s_axi.araddr),
      .ARLEN(s_axi.arlen),
      .ARSIZE(s_axi.arsize),
      .ARBURST(s_axi.arburst),
      .ARLOCK(s_axi.arlock),
      .ARCACHE(s_axi.arcache),
      .ARPROT(s_axi.arprot),
      .ARREGION(),
      .ARUSER(),
      .ARQOS(),
      .ARVALID(s_axi.arvalid),
      .ARREADY(s_axi.arready),
      .RID(s_axi.rid),
      .RDATA(s_axi.rdata),
      .RRESP(s_axi.rresp),
      .RLAST(s_axi.rlast),
      .RUSER(),
      .RVALID(s_axi.rvalid),
      .RREADY(s_axi.rready)
      );

   //===========================================================================
   //                         Memory Model instantiation
   //===========================================================================

    reg [ADDR_WIDTH-1:0] DDR4_ADRMOD[RANK_WIDTH-1:0];
   always @(*)
     if (c0_ddr4_cs_n == 4'b1111)
       cmdName = "DSEL";
     else
       if (c0_ddr4_act_n)
	 casez (DDR4_ADRMOD[0][16:14])
	   MRS:     cmdName = "MRS";
	   REF:     cmdName = "REF";
	   PRE:     cmdName = "PRE";
	   WR:      cmdName = "WR";
	   RD:      cmdName = "RD";
	   ZQC:     cmdName = "ZQC";
	   NOP:     cmdName = "NOP";
	   default:  cmdName = "***";
	 endcase
       else
	 cmdName = "ACT";

   reg 			 wr_en ;
   always@(posedge c0_ddr4_ck_t)begin
      if(!c0_ddr4_reset_n)begin
	 wr_en <= #100 1'b0 ;
      end else begin
	 if(cmdName == "WR")begin
            wr_en <= #100 1'b1 ;
	 end else if (cmdName == "RD")begin
            wr_en <= #100 1'b0 ;
	 end
      end
   end

   genvar rnk;
   generate
      for (rnk = 0; rnk < CS_WIDTH; rnk++) begin:rankup
	 always @(*)
	   if (c0_ddr4_act_n)
	     casez (c0_ddr4_adr_sdram[0][16:14])
	       WR, RD: begin
		  DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk] & 18'h1C7FF;
	       end
	       default: begin
		  DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk];
	       end
	     endcase
	   else begin
	      DDR4_ADRMOD[rnk] = c0_ddr4_adr_sdram[rnk];
	   end
      end
   endgenerate
   
   genvar i;
  genvar r;
  genvar s;

  generate
    if (DRAM_WIDTH == 4) begin: mem_model_x4

      DDR4_if #(.CONFIGURED_DQ_BITS (4)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();
      for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel
        ddr4_model  #
          (
           .CONFIGURED_DQ_BITS (4),
           .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
           ) ddr4_model(
            .model_enable (model_enable),
            .iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
        );
        end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ1
          for (s = 0; s < 4; s++) begin:tranDQp
            `ifdef XILINX_SIMULATOR
             short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*4]);
             `else
              tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*4]);
             `endif
       end
    end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS1
        `ifdef XILINX_SIMULATOR
        short bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
        short bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
        `else
          tran bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          tran bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
        `endif
      end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:ADDR_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:ADDR_R

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

     for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
      end
      end
    end
    else if (DRAM_WIDTH == 8) begin: mem_model_x8

      DDR4_if #(.CONFIGURED_DQ_BITS(8)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();

      for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri1
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel1
            ddr4_model #(
              .CONFIGURED_DQ_BITS(8),
              .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
                ) ddr4_model(
              .model_enable (model_enable)
             ,.iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
           );
         end
       end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ2
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ12
          for (s = 0; s < 8; s++) begin:tranDQ2
           `ifdef XILINX_SIMULATOR
           short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*8]);
           `else
            tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*8]);
           `endif
          end
        end
      end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS2
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS12
        `ifdef XILINX_SIMULATOR
          short bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          short bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
          short bidiDM(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n, c0_ddr4_dm_dbi_n[i]);
        `else
          tran bidiDQS(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t, c0_ddr4_dqs_t[i]);
          tran bidiDQS_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c, c0_ddr4_dqs_c[i]);
          tran bidiDM(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n, c0_ddr4_dm_dbi_n[i]);
        `endif
        end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:ADDR_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:ADDR_R

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

      for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS1
        for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL1
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];

          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
            assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
         end
      end

    end else begin: mem_model_x16

      if (DQ_WIDTH/16) begin: mem

      DDR4_if #(.CONFIGURED_DQ_BITS (16)) iDDR4[0:(RANK_WIDTH*NUM_PHYSICAL_PARTS)-1]();

        for (r = 0; r < RANK_WIDTH; r++) begin:memModels_Ri2
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:memModel2
            ddr4_model  #
            (
             .CONFIGURED_DQ_BITS (16),
             .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
             )  ddr4_model(
                .model_enable (model_enable),
                .iDDR4        (iDDR4[(r*NUM_PHYSICAL_PARTS)+i])
            );
          end
        end

        for (r = 0; r < RANK_WIDTH; r++) begin:tranDQ3
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQ13
            for (s = 0; s < 16; s++) begin:tranDQ2
              `ifdef XILINX_SIMULATOR
              short bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*16]);
              `else
              tran bidiDQ(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQ[s], c0_ddr4_dq[s+i*16]);
              `endif
            end
          end
        end

        for (r = 0; r < RANK_WIDTH; r++) begin:tranDQS3
          for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranDQS13
          `ifdef XILINX_SIMULATOR
            short bidiDQS0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[0], c0_ddr4_dqs_t[(2*i)]);
            short bidiDQS0_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[0], c0_ddr4_dqs_c[(2*i)]);
            short bidiDM0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[0], c0_ddr4_dm_dbi_n[(2*i)]);
            short bidiDQS1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[1], c0_ddr4_dqs_t[((2*i)+1)]);
            short bidiDQS1_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[1], c0_ddr4_dqs_c[((2*i)+1)]);
            short bidiDM1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[1], c0_ddr4_dm_dbi_n[((2*i)+1)]);

          `else
            tran bidiDQS0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[0], c0_ddr4_dqs_t[(2*i)]);
            tran bidiDQS0_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[0], c0_ddr4_dqs_c[(2*i)]);
            tran bidiDM0(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[0], c0_ddr4_dm_dbi_n[(2*i)]);
            tran bidiDQS1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_t[1], c0_ddr4_dqs_t[((2*i)+1)]);
            tran bidiDQS1_(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DQS_c[1], c0_ddr4_dqs_c[((2*i)+1)]);
            tran bidiDM1(iDDR4[(r*NUM_PHYSICAL_PARTS)+i].DM_n[1], c0_ddr4_dm_dbi_n[((2*i)+1)]);
          `endif
        end
      end

       for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS
         for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL

           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BG        = c0_ddr4_bg_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].BA        = c0_ddr4_ba_sdram[r];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[r][ADDR_WIDTH-1] : 1'b0;
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ADDR      = DDR4_ADRMOD[r][13:0];
           assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CS_n = c0_ddr4_cs_n[r];

         end
       end

    for (r = 0; r < RANK_WIDTH; r++) begin:tranADCTL_RANKS1
      for (i = 0; i < NUM_PHYSICAL_PARTS; i++) begin:tranADCTL1
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ACT_n     = c0_ddr4_act_n;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RAS_n_A16 = DDR4_ADRMOD[r][16];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CAS_n_A15 = DDR4_ADRMOD[r][15];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].WE_n_A14  = DDR4_ADRMOD[r][14];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].CKE       = c0_ddr4_cke[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ODT       = c0_ddr4_odt[r];
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PARITY  = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].TEN     = 1'b0;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].ZQ      = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].PWR     = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_CA = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].VREF_DQ = 1'b1;
          assign iDDR4[(r*NUM_PHYSICAL_PARTS)+ i].RESET_n = c0_ddr4_reset_n;
          end
        end
      end

      if (DQ_WIDTH%16) begin: mem_extra_bits
       // DDR4 X16 dual rank is not supported
        DDR4_if #(.CONFIGURED_DQ_BITS (16)) iDDR4[(DQ_WIDTH/DRAM_WIDTH):(DQ_WIDTH/DRAM_WIDTH)]();

        ddr4_model  #
          (
           .CONFIGURED_DQ_BITS (16),
           .CONFIGURED_DENSITY (CONFIGURED_DENSITY)
           )  ddr4_model(
            .model_enable (model_enable),
            .iDDR4        (iDDR4[(DQ_WIDTH/DRAM_WIDTH)])
        );

        for (i = (DQ_WIDTH/DRAM_WIDTH)*16; i < DQ_WIDTH; i=i+1) begin:tranDQ
          `ifdef XILINX_SIMULATOR
          short bidiDQ(iDDR4[i/16].DQ[i%16], c0_ddr4_dq[i]);
          short bidiDQ_msb(iDDR4[i/16].DQ[(i%16)+8], c0_ddr4_dq[i]);
          `else
          tran bidiDQ(iDDR4[i/16].DQ[i%16], c0_ddr4_dq[i]);
          tran bidiDQ_msb(iDDR4[i/16].DQ[(i%16)+8], c0_ddr4_dq[i]);
          `endif
        end

        `ifdef XILINX_SIMULATOR
        short bidiDQS0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[0], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        short bidiDQS0_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[0], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        short bidiDM0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[0], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        short bidiDQS1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[1], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        short bidiDQS1_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[1], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        short bidiDM1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[1], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        `else
        tran bidiDQS0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[0], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        tran bidiDQS0_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[0], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        tran bidiDM0(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[0], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        tran bidiDQS1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_t[1], c0_ddr4_dqs_t[DQS_WIDTH-1]);
        tran bidiDQS1_(iDDR4[DQ_WIDTH/DRAM_WIDTH].DQS_c[1], c0_ddr4_dqs_c[DQS_WIDTH-1]);
        tran bidiDM1(iDDR4[DQ_WIDTH/DRAM_WIDTH].DM_n[1], c0_ddr4_dm_dbi_n[DM_WIDTH-1]);
        `endif

        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CK = {c0_ddr4_ck_t, c0_ddr4_ck_c};
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ACT_n = c0_ddr4_act_n;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].RAS_n_A16 = DDR4_ADRMOD[0][16];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CAS_n_A15 = DDR4_ADRMOD[0][15];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].WE_n_A14 = DDR4_ADRMOD[0][14];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CKE = c0_ddr4_cke[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ODT = c0_ddr4_odt[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].BG = c0_ddr4_bg_sdram[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].BA = c0_ddr4_ba_sdram[0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ADDR_17 = (ADDR_WIDTH == 18) ? DDR4_ADRMOD[0][ADDR_WIDTH-1] : 1'b0;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ADDR = DDR4_ADRMOD[0][13:0];
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].RESET_n = c0_ddr4_reset_n;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].TEN     = 1'b0;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].ZQ      = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].PWR     = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].VREF_CA = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].VREF_DQ = 1'b1;
        assign iDDR4[DQ_WIDTH/DRAM_WIDTH].CS_n = c0_ddr4_cs_n[0];
      end
    end
  endgenerate
endmodule // tb_ddr4_mem_ch_top

