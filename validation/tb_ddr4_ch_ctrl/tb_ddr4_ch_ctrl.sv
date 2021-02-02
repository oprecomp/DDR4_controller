// This is synthesisable test bench for DDR4 channel ctrl.
// This tb is for testing the ctrl on an FPGA board.
// Currently integrated with Xi Mig only.
`timescale 1ps/1ps
`ifndef SYNTHESIS
 `include "arch_package.sv"
`endif

module tb_ddr4_ch_ctrl
  (
`ifdef FPGA
 `ifdef SYNTHESIS
   input  c0_sys_clk_p,
   input  c0_sys_clk_n,
   input  sys_rst_n,
   
   output logic           c0_ddr4_act_n,
   output [16:0]          c0_ddr4_adr,
   output [1:0]           c0_ddr4_ba,
   output [1:0]           c0_ddr4_bg,
   output [0:0]           c0_ddr4_cke,
   output [0:0]           c0_ddr4_odt,
   output [0:0]           c0_ddr4_cs_n,
   output [0:0]           c0_ddr4_ck_t,
   output [0:0]           c0_ddr4_ck_c,
   output                 c0_ddr4_reset_n,
   inout [7:0]            c0_ddr4_dm_dbi_n,
   inout [63:0]           c0_ddr4_dq,
   inout [7:0]            c0_ddr4_dqs_c,
   inout [7:0]            c0_ddr4_dqs_t,
 `endif //  `ifdef SYNTHESIS
   output logic c0_data_compare_error,
   output logic c0_init_calib_complete
`endif
   );

`ifndef SYNTHESIS
   import arch_package::*;
   parameter UTYPE_density CONFIGURED_DENSITY = _8G;
`endif
   
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
   
   localparam AXI4_ADDRESS_WIDTH = 32;
   localparam AXI4_ID_WIDTH = 16;
   localparam BANK_FIFO_DEPTH = 4;
   localparam ROW_ADDR_WIDTH = ADDR_WIDTH;
   localparam COL_ADDR_WIDTH = 11;
   localparam DRAM_ADDR_WIDTH = ADDR_WIDTH;
   localparam DRAM_CMD_WIDTH = 5;
   localparam DRAM_BANKS = 16;
   localparam DRAM_BUS_WIDTH = DQ_WIDTH;
   localparam FE_CMD_WIDTH = 1;
   localparam FE_WRITE = 0;
   localparam FE_ADDR_WIDTH = AXI4_ADDRESS_WIDTH;// $clog2(DRAM_BANKS) + ROW_ADDR_WIDTH +
			      //COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH) - 3;
   localparam FE_ID_WIDTH = AXI4_ID_WIDTH;
   
   localparam CAS_EVEN_SLOT = 1; // accepted values are either 1 (for XI FPGA) or zero
   localparam CLK_RATIO = 4;
      
   localparam RRD_DRAM_CYCLES = 6;
   localparam WTR_DRAM_CYCLES = 2;
   localparam CCD_DRAM_CYCLES = 4;
   localparam RRD_DRAM_CYCLES_L = 6;
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
   localparam CAS2CAS_DRAM_CYCLES_LOG2 = 4;
   localparam WR2RD_DRAM_CYCLES_LOG2 = 8;
   localparam RD2WR_DRAM_CYCLES_LOG2 = 8;
   localparam RG_REF_NUM_ROW_PER_REF_LOG2 = 6;
   localparam CWL_LOG2 = 4;
   localparam BL_LOG2 = 4;
   localparam ZQS_DRAM_CYCLES_LOG2 = 8;
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


   logic 				fe_req;
   logic [FE_CMD_WIDTH-1:0] 		fe_cmd;
   logic [FE_ADDR_WIDTH-6-1:0] 		fe_addr;
   logic [FE_ID_WIDTH-1:0] 		fe_id;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_data;
   logic 				fe_stall;
   logic [FE_ID_WIDTH-1:0] 		fe_read_id;
   logic 				fe_read_valid;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_read_data;
   
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
   

   // Input clock is assumed to be equal to the memory clock frequency
   // User should change the parameter as necessary if a different input
   // clock frequency is used
   localparam real 			  CLKIN_PERIOD_NS = 5000 / 1000.0;

   //initial begin
   //   $shm_open("waves.shm");
   //   $shm_probe("ACMTF");
   //end


   reg 					  ui_clk;
   reg 					  ui_rst_n;
   
     
   
 `ifndef SYNTHESIS

   reg 					  sys_clk_i;
   reg 					  sys_rst_n;

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

   wire 				  c0_ddr4_ck_t;
   wire 				  c0_ddr4_ck_c;

   wire 				  c0_ddr4_reset_n;
   
   wire [7:0] 				  c0_ddr4_dm_dbi_n;
   wire [63:0] 				  c0_ddr4_dq;
   wire [7:0] 				  c0_ddr4_dqs_c;
   wire [7:0] 				  c0_ddr4_dqs_t;

   wire [0:0] 				  c0_ddr4_ck_t_int;
   wire [0:0] 				  c0_ddr4_ck_c_int;

   reg [31:0] 				  cmdName;
   bit 					  en_model;
   tri 					  model_enable = en_model;

 `endif
   //wire 				  c0_init_calib_complete;
   //wire 				  c0_data_compare_error;

   
   
 `ifndef SYNTHESIS
   //**************************************************************************//
   // Reset Generation
   //**************************************************************************//
   initial begin
      sys_rst_n = 1'b1;
      #200
	sys_rst_n = 1'b0;
      en_model = 1'b0; 
      #5 en_model = 1'b1;
      #200000;
      sys_rst_n = 1'b1;
   end


//************************************************************************//
// Clock Generation
//************************************************************************//
   
   initial
     sys_clk_i = 1'b0;
   always
     //sys_clk_i = #(3334/2.0) ~sys_clk_i;
     sys_clk_i = #(5000/2.0) ~sys_clk_i;
   

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
   end // always @ ( * )

   assign c0_sys_clk_p = sys_clk_i;
   assign c0_sys_clk_n = ~sys_clk_i;
   
 `endif //  `ifndef SYNTHESIS

   assign ui_clk = c0_ddr4_clk;
   assign ui_rst_n = ~c0_ddr4_rst;
   assign cal_done = c0_init_calib_complete;
`endif //  `ifdef FPGA

   /*********** test*******************/

`ifdef NEW_TGEN   
   
  mem_tgen_checker
  #(
    .DRAM_BUS_WIDTH(DRAM_BUS_WIDTH),
    .FE_CMD_WIDTH(FE_CMD_WIDTH),
    .FE_WRITE(FE_WRITE),
    .FE_ADDR_WIDTH(FE_ADDR_WIDTH),
    .FE_ID_WIDTH(FE_ID_WIDTH),
    .BL(BL)
    )tgen_checker
   (

    .ui_clk(ui_clk),
    .ui_rst_n(ui_rst_n),
    .fe_stall(fe_stall),
    .fe_req(fe_req),
    .fe_cmd(fe_cmd),
    .fe_addr(fe_addr),
    .fe_id(fe_id),
    .fe_data(fe_data),
    .fe_read_data(fe_read_data),
    .fe_read_id(fe_read_id),
    .fe_read_valid(fe_read_valid),
    .data_cmp_err(c0_data_compare_error)
    );




`else

 /*************TGEN_SIM_ONLY*********/   
   localparam RDN_ADDR_STORED = 128;
   localparam cTMP_ADDR = 27;
   localparam cFE_CMD_WIDTH = FE_CMD_WIDTH;
   localparam cFE_ADDR_WIDTH = FE_ADDR_WIDTH;
   localparam cFE_WR = FE_WRITE;
   localparam cFE_RD = 1 - FE_WRITE;
   localparam cFE_ID_WIDTH = FE_ID_WIDTH;

   logic [63:0] fe_data_wr;
   
      
   typedef struct {
      logic [RDN_ADDR_STORED-1:0] rd_en_array;
      logic [RDN_ADDR_STORED-1:0][cTMP_ADDR-1:0] tmp_addr_array;
      logic 					 fe_req;
      logic [cFE_CMD_WIDTH-1:0] 		 fe_cmd;
      logic [cTMP_ADDR-1:0] 			 fe_addr_tmp;
      logic [cFE_ID_WIDTH-1:0] 			 fe_id;
      logic [2:0] 				 grant_cnt;
      logic 					 grant_cnt_en;

   } tREG_FE;
   tREG_FE q_fe , d_fe;
    typedef struct {
       logic 	   clk;  
      logic 	  reset_n;
      logic 	  iddq_n;
      logic 	  odt;
      // *********************************************************************
      // ----- RANK MACHINE --------------------------------------------------
      // *********************************************************************
      // stall from wrapper
      logic 					  read_stall;
      logic [$clog2(RDN_ADDR_STORED)-1:0] 	  rd_adr;
      logic [cTMP_ADDR-1:0] 			      random_addr;
      logic [cFE_CMD_WIDTH-1:0] 		      fe_cmd;
      logic 					      fe_req;
      logic [cFE_ADDR_WIDTH-1:0] 		      fe_addr;
   } tTB;

   tTB tb;
   assign tb.clk = ui_clk;
   assign tb.reset_n = ui_rst_n;
   		   
   logic [$clog2(2*RDN_ADDR_STORED)-1:0] q_cnt, d_cnt;

   logic [2*RDN_ADDR_STORED-1:0][cTMP_ADDR-1:0] fe_addr_write;
   logic [2*RDN_ADDR_STORED-1:0][cTMP_ADDR-1:0] fe_addr_read;
   logic [$clog2(2*RDN_ADDR_STORED)-1:0] cntx;
   logic [2*RDN_ADDR_STORED-1:0][511:0]   data_i_mem_wr_array;
   logic fe_stall_del;
   logic token_grant;


   localparam data_bits = 64;
   localparam fe_addr_bits = 27;
   localparam fe_addr_red= 24;

   logic mem_data_bus_rdy;

   reg [511:0] Array[((1<<(fe_addr_red))-1):0];
   logic [26:0] j;
   
   // AXI SLAVE INTERFACE (FRONT END)
   always_ff @(posedge tb.clk, negedge tb.reset_n)
     begin
	if(tb.reset_n == 1'b0)
	  begin
	     q_fe.fe_req <= '0;
	     q_fe.fe_cmd <= '0;
	     q_fe.fe_addr_tmp <= '0;
	     q_fe.fe_id <= '0;
	     q_cnt <= '0;
	     fe_stall_del <= '0;
	  end
	else
	  begin
	     q_fe <= d_fe;
	     q_cnt <= d_cnt;
	     fe_stall_del <= fe_stall;
	     tb.fe_req <= $random();
	     tb.fe_cmd <= $random();
	     fe_data_wr[31:0] <= $urandom_range((2**32)-1,0);
	     fe_data_wr[63:32] <= $urandom_range((2**32)-1,0);
	     tb.random_addr <= $urandom_range((2**cTMP_ADDR)-1, 0);
	     tb.rd_adr 	<= $urandom_range(RDN_ADDR_STORED-1-2, 0);
	  end // else: !if(tb.reset_n == 1'b0)
     end // always_ff @ (posedge clk, negedge reset_n)

   //assign fe_stall = tb.fe_stall ;//| fe_stall_del;

   always_comb begin
      d_fe  = q_fe;
      d_cnt = q_cnt;
      tb.read_stall = 0;

      if (cal_done && ~fe_stall && tb.fe_req) begin
	 if (tb.fe_cmd==cFE_WR) begin         // WR part
	    d_fe.fe_id       = q_fe.fe_id + 1;
	    if (q_cnt<RDN_ADDR_STORED) begin
	       d_fe.tmp_addr_array[q_cnt]      = tb.random_addr;
	       d_fe.rd_en_array[q_cnt] 	     = 1;
	       d_cnt = q_cnt + 1;
	    end else if(q_cnt==RDN_ADDR_STORED) begin  // TODO does not work: enable this for more random addressing
			//d_fe.tmp_addr_array[tb.rd_adr]  = tb.random_addr;
			//d_fe.rd_en_array[tb.rd_adr] 	 = 1;
            end
			d_fe.fe_addr_tmp 			     = tb.random_addr;
			d_fe.fe_cmd 				     = tb.fe_cmd;
			d_fe.fe_req = 1;
		  // else: !if(tb.rd_en_array[tb.fe_addr_tmp] && tb.fe_cmd_tmp==cFE_RD)
		 end else if (q_cnt==RDN_ADDR_STORED && q_fe.rd_en_array[tb.rd_adr] && tb.fe_cmd==cFE_RD) begin // RD part
			d_fe.fe_addr_tmp = fe_addr_write[tb.rd_adr];//q_fe.tmp_addr_array[tb.rd_adr];
			d_fe.fe_id       = q_fe.fe_id + 1;
			d_fe.fe_cmd      = tb.fe_cmd;
			d_fe.fe_req      = 1;
		 end else if (q_cnt>32 && q_cnt<RDN_ADDR_STORED && q_fe.rd_en_array[q_cnt-16] && tb.fe_cmd==cFE_RD) begin
			d_fe.fe_addr_tmp = fe_addr_write[q_cnt-16];//q_fe.tmp_addr_array[q_cnt-16];
			d_fe.fe_id       = q_fe.fe_id + 1;
			d_fe.fe_cmd      = tb.fe_cmd;
			d_fe.fe_req      = 1;
		 end // else: !if(tb.rd_en_array[tb.fe_addr_tmp] && tb.fe_cmd_tmp==cFE_RD)
	  end else begin // if (!tb.data_bus_rdy)
	     //if(~tb.fe_stall)
	       d_fe.fe_req = fe_stall?q_fe.fe_req:0;
	  end // else: !if(tb.data_bus_rdy)
   end

  // Read & Write Address FIFO for data checker
  //
   logic [$clog2(2*RDN_ADDR_STORED)-1:0]  cnt_write_i, cnt_read_i;
   logic 				  error_flag, set_flag, set_flag2;
   
   always_ff @(posedge tb.clk, negedge tb.reset_n)
     begin
	if(tb.reset_n == 1'b0)
	  begin
	     fe_addr_write <= '0;
	     fe_addr_read <= '0;
	     cnt_write_i <= '0;
	     cnt_read_i <= '0;
	  end
	else
	  begin
	     if(~fe_stall /*&& tb.data_bus_rdy*/) begin
		if(q_fe.fe_cmd == 1'b0 && q_fe.fe_req == 1'b1) begin
		   fe_addr_write[cnt_write_i] <= q_fe.fe_addr_tmp;
		   cnt_write_i <= cnt_write_i + 1;
		end
		else
		  if(q_fe.fe_cmd == 1'b1 && q_fe.fe_req == 1'b1) begin
		     fe_addr_read[cnt_read_i] <= q_fe.fe_addr_tmp;
		     $display("RD triggered for address %d: using index no.(%d)", q_fe.fe_addr_tmp, cnt_read_i);
		     cnt_read_i <= cnt_read_i + 1;
		  end
	     end // else: !if(tb.reset_n == 1'b0
	  end
     end // a

   logic [31:0] error_count;
   logic [$clog2(2*RDN_ADDR_STORED)-1:0]  cnt_write_o, cnt_read_o;

   // Write block --> Array
   always_ff @(posedge tb.clk, negedge tb.reset_n)
     begin
	if(tb.reset_n == 1'b0)
	  begin
	     cnt_write_o <= '0;
	     set_flag <= '0;
	  end
	else
	  begin
	     if(wrDataEn_q/*mem_data.grant_wr_data*/ == 1'b1 /*&& tb.valid_o_mem_fifo_wr*/) begin
		data_i_mem_wr_array[cnt_write_o] <= wrData;
		$display("WR Data written for address %d: written data no.(%d) = %h", fe_addr_write[cnt_write_o], cnt_write_o, wrData);
		cnt_write_o <= cnt_write_o + 1;
		set_flag <= 1;
	     end
	     else if(wrDataEn_q/*mem_data.grant_wr_data*/ == 1'b0 && set_flag == 1) begin
		if(cnt_write_o != 0) begin
		   $display("Tmp Data stored for address %d: stored data no.(%d) = %h", fe_addr_write[cnt_write_o-1], cnt_write_o-1, data_i_mem_wr_array[cnt_write_o-1]);
		end
		set_flag <= 0;
             end 
	  end // else: !if(tb.reset_n == 1'b0)
     end // a


   logic [1:0] cnt_tmp;
   logic       cnt_tmp_en;
   logic       grant_wr_data_del;

   always_ff @(posedge tb.clk, negedge tb.reset_n) begin
      if(tb.reset_n == 1'b0) begin
	 cntx <= 0; set_flag2 <= 0;
         grant_wr_data_del <= 0;
      end else begin
         if(grant_wr_data_del == 1) begin
            Array[fe_addr_write[cntx][26:3]] <= data_i_mem_wr_array[cntx];
	    $display("Data stored in DRAM for fe addr %d: stored data no.(%d) = %h", fe_addr_write[cntx],cntx, data_i_mem_wr_array[cntx]);
	    cntx++;
	    set_flag2 <= 1;
	 end else if(set_flag2 && cntx != 0) begin 
	    $display("Data stored in DRAM for fe addr %d: stored data no.(%d) = %h", fe_addr_write[cntx-1],cntx-1, Array[fe_addr_write[cntx-1][26:3]]);
	    set_flag2 <= 0;
	 end
         grant_wr_data_del <= wrDataEn_q;//mem_data.grant_wr_data; //& tb.valid_o_mem_fifo_wr;
		
        end
   end

/*   always_ff @(posedge tb.clk_t, negedge tb.reset_n) begin
      if(tb.reset_n == 1'b0) begin
		cnt_tmp <= 0;
		cnt_tmp_en <= 0;
      end else begin
	if() begin
		    cnt_tmp_en <= 1;
	end else if (cnt_tmp == 3) begin
			cnt_tmp_en <= 0;
			cnt_tmp <= 0;
	end else if( cnt_tmp_en == 1) begin
		    cnt_tmp++;
	end
      end
   end */

   // Read block --> Array
   always_ff @(posedge tb.clk, negedge tb.reset_n)
     begin
	if(tb.reset_n == 1'b0)
	  begin
	     cnt_read_o <= '0;
	     error_flag <= '0;
             error_count <= '0;
	  end
	else begin
	   //		  if(mem_data.data_rd_valid == 1'b1) begin
	   if ((Array[fe_addr_read[cnt_read_o][26:3]] != rdData)&& rdDataEn) begin
	      error_flag <= '1;
	      $display("RD Wrong data comparison for address %d: Stored data no.(%d) = %h  vs. Read data = %h", fe_addr_read[cnt_read_o], cnt_read_o, Array[fe_addr_read[cnt_read_o][26:3]], rdData);
	      $finish();
	      ReadCheck: assert (Array[fe_addr_read[cnt_read_o][26:3]] === rdData)
                else begin error_count++;$error("memory read error"); 
                end
	   end else begin
	      if(rdDataEn)
		$display("RD data comparison for address %d: Stored data no.(%d) = %h  vs. Read data = %h", fe_addr_read[cnt_read_o], cnt_read_o, Array[fe_addr_read[cnt_read_o][26:3]], rdData);
	      SampleCheck: assert (~(1'bX === ^rdData))
                else begin error_count++;$error("memory sample read error for address",fe_addr_read[cnt_read_o]); error_flag <= '1; end
	   end // else: !if((Array[fe_addr_read[cnt_read_o][26:3]] != rdData)&& rdDataEn)
	   if(rdDataEn)
	     cnt_read_o <= cnt_read_o + 1;
	   //		  end 
	end // else: !if(tb.reset_n == 1'b0)
     end // al

   assign tb.fe_addr= {'0,q_fe.fe_addr_tmp[26:3],3'b000};

`endif // !`ifdef NEW_TGEN
   
   
   /*********** DUT *******************/
   
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
       .ZQSI_AREFI_CYCLES(ZQSI_TREFI_CYCLES), // ZQ short interval
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
       .CONGEN_XOR_SEL(CONGEN_CONFIG_XOR_SEL)
       ) ch_ctrl
       (
	.rst_n(ui_rst_n),
	.clk(ui_clk),
`ifdef NEW_TGEN
	.fe_req(fe_req),
	.fe_cmd(fe_cmd),
	.fe_addr({1'b0,2'b0,fe_addr,3'b000}),
	.fe_id(fe_id),
	.fe_data(fe_data),
`else
	.fe_req              (q_fe.fe_req),
	.fe_cmd              (q_fe.fe_cmd),
	.fe_addr             ({tb.fe_addr}),//({'0,tb.fe_addr}),
	.fe_id               (q_fe.fe_id),
	.fe_data({8{fe_data_wr}}),
`endif // !`ifdef NEW_TGEN
	.fe_stall(fe_stall),
	.fe_read_data(fe_read_data),
	.fe_read_id(fe_read_id),
	.fe_read_valid(fe_read_valid),
	.fe_read_grant(fe_read_valid),
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
	.ctrl_w_data(wrData),
	.ctrl_w_valid(ctrl_w_valid),
	.ctrl_w_grant(wrDataEn_q),//mem_data.grant_wr_data),//Phy accepts data along with cmd
	.ctrl_r_data(rdData),
	.ctrl_r_id(ctrl_r_id),
	.ctrl_r_valid(rdDataEn),
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
	
	.dBufAdr(dBufAdr),
	.rdDataEn(rdDataEn),
	
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

   /*********** MIG PHY *******************/
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


   //===========================================================================
   //                         Memory Model instantiation
   //===========================================================================

`ifndef SYNTHESIS
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
     
`endif //  `ifndef SYNTHESIS
   
endmodule // tb_ddr4_ch_ctrl
