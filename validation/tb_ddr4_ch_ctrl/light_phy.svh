// AUTHOR: Jan Lappas
// Date : 09.03.2018
`ifndef LIGHT_PHY_SVH
`define LIGHT_PHY_SVH

interface if_io_config;
   // Slew Rate Control
   logic [1:0] td_ctrl_n;
   logic       tdqs_trim_n;
   // Impedance Calibration Off Chip Driver
   logic [4:0] pd_en_a;
   logic [4:0] pd_en_n_a;
   logic [4:0] pu_en_a;
   logic [4:0] pu_en_n_a;
   //----------------------------
   logic [4:0] pd_en_b;
   logic [4:0] pd_en_n_b;
   logic [4:0] pu_en_b;
   logic [4:0] pu_en_n_b;

   // PHY Side
   //***************************************
   modport phy
	 (
	  output td_ctrl_n, output tdqs_trim_n,
	  output pd_en_a, output pd_en_n_a, output pu_en_a, output pu_en_n_a,
	  output pd_en_b, output pd_en_n_b, output pu_en_b, output pu_en_n_b
	  );

   // Off Chip Driver Side
   //***************************************
   modport ocd
	 (
	  input td_ctrl_n, input tdqs_trim_n,
	  input pd_en_a, input pd_en_n_a, input pu_en_a, input pu_en_n_a,
	  input pd_en_b, input pd_en_n_b, input pu_en_b, input pu_en_n_b
	  );

endinterface // if_config_io

interface if_impedance_cntrl;
   // Impedance Control Off Chip Driver
   logic [4:0] pdat_en_a;
   logic [4:0] ndat_nen_a;
   //---------------------------
   logic [4:0] pdat_en_b;
   logic [4:0] ndat_nen_b;

   // PHY Side
   //***************************************
   modport phy
	 (
	  output pdat_en_a, output ndat_nen_a,
	  output pdat_en_b, output ndat_nen_b
	  );

   // Off Chip Driver Side
   //***************************************
   modport ocd
	 (
	  input pdat_en_a, input ndat_nen_a,
	  input pdat_en_b, input ndat_nen_b
	  );
endinterface // if_impedance_cntrl

interface if_ocd;
   logic 	   pdat_ev_a;
   logic 	   ndat_ev_a;
   logic 	   pdat_od_a;
   logic 	   ndat_od_a;
   //----------------------------
   // Driver Signals Channel B
   logic 	   pdat_ev_b;
   logic 	   ndat_ev_b;
   logic 	   pdat_od_b;
   logic 	   ndat_od_b;

   // PHY Side
   //***************************************
   modport phy
	 (
	  output pdat_ev_a, output ndat_ev_a,
	  output pdat_od_a, output ndat_od_a,
	  output pdat_ev_b, output ndat_ev_b,
	  output pdat_od_b, output ndat_od_b
	  );

   // Off Chip Driver Side
   //***************************************
   modport ocd
	 (
	  input pdat_ev_a, input ndat_ev_a,
	  input pdat_od_a, input ndat_od_a,
	  input pdat_ev_b, input ndat_ev_b,
	  input pdat_od_b, input ndat_od_b
	  );
endinterface // if_ocd

interface if_rcv_dq;
   // Receiver Channel A
   //logic dq_a_in;
   logic 	en_rcv2_a;
   logic 	en_rcv1_bias_a;
   logic 	en_rcv2_bias_a;
   logic 	parkh_n_a;
   // Receiver Channel B
   //logic 	dq_b_in;
   logic 	en_rcv2_b;
   logic 	en_rcv1_bias_b;
   logic 	en_rcv2_bias_b;
   logic 	parkh_n_b;
   //----------------------------
   logic 	rdy_n;
   logic 	iddq_n;

   // PHY Side
   //***************************************
   modport phy
	 (
	  output en_rcv2_a, output en_rcv1_bias_a, output en_rcv2_bias_a,
	  output parkh_n_a,
	  output en_rcv2_b, output en_rcv1_bias_b, output en_rcv2_bias_b,
	  output parkh_n_b,
	  input  rdy_n , output iddq_n
	  );

   // Data Receiver Side
   //***************************************
   modport rcv_dq
	 (
	  input  en_rcv2_a, input en_rcv1_bias_a, input en_rcv2_bias_a,
	  input  parkh_n_a,
	  input  en_rcv2_b, input en_rcv1_bias_b, input en_rcv2_bias_b,
	  input  parkh_n_b,
	  output rdy_n , input iddq_n
	  );
endinterface // if_rcv

interface if_rcv_dqs;
   // DQS Receiver
  // logic 	   dqs_in;
  // logic 	   dqs_n_in;
   //--------DQS_IN----------------------
   logic 	   en_rcv2_bias_a;
   logic 	   en_rcv2_a;
   logic 	   parkh_n_a;
  //---------DQS_N_IN--------------------
   logic 	   en_rcv2_bias_b;
   logic 	   en_rcv2_b;
   logic 	   parkh_n_b;
   //---------------------------------
   logic 	   rdy_n;
   logic 	   en_rcv1_bias;
   logic 	   iddq_n;

   // PHY Side
   //***************************************
   modport phy
	 (
	  input rdy_n,
	  output en_rcv2_bias_a, output en_rcv2_a, output parkh_n_a,
	  output en_rcv2_bias_b, output en_rcv2_b, output parkh_n_b,
	  output en_rcv1_bias, output iddq_n
	  );

   // Data Strobe Receiver Side
   //***************************************
   modport rcv_dqs
	 (
	  output rdy_n,
	  input en_rcv2_bias_a, input en_rcv2_a, input parkh_n_a,
	  input en_rcv2_bias_b, input en_rcv2_b, input parkh_n_b,
	  input en_rcv1_bias, input iddq_n
	  );
endinterface // if_rcv

interface if_mem_data #(pAXI_ID_WIDTH = 16);
   // INPUT MEM_CNTRL FIFO READ
   logic  data_rd_valid;
   // INPUT MEM_CNTRL FIFO READ - DATA
   logic [63:0] data_rd;
   // INPUT MEM_CNTRL FIFO READ - DATA ID
   logic [pAXI_ID_WIDTH-1:0] data_rd_id;
   // INPUT FOR PHY - DATA ID FROM MEM_CNTRL
   logic [pAXI_ID_WIDTH-1:0] data_id;
   // OUTPUT FROM MEM_CNTRL FIFO
   logic [63:0] data_wr;
   // MEM_CNTRL PUSH DATA INTO WR-DATA BUFFER IN THE LIGHT_PHY
   logic  grant_wr_data;

   // DATA BUS READY - tell MEM_CNTRL if data bus is ready (calibration etc.)
   //logic  bus_rdy;

   // PHY Side
   //***************************************
   modport phy
	 (
	  output data_rd_valid, output data_rd, output data_rd_id,
	  output grant_wr_data,
	  input  data_id, input data_wr
	  );

   // DATA SLICE Side
   //***************************************
   modport data_slice
	 (
	  output data_rd_valid, output data_rd, output data_rd_id,
	  output grant_wr_data,
	  input data_id, input data_wr
	  );

   // Memory Controller Side
   //***************************************
   modport mem_cntrl
	 (
	  input data_rd_valid, input data_rd, input data_rd_id,
	  input grant_wr_data,
	  output data_id, output data_wr
	  );

endinterface // if_mem_data

interface if_mem_adr_cmd;
   // Input Off Chip Driver
   logic [3:0] [2:0]  ba;
   logic [3:0] [15:0] adr;
   logic [3:0] [4:0]  cmd; // CKE,nCS, nRAS,nCAS,nWE [4:0]
   logic              reset_m_n;
   // --------------------------------------------
   logic              clk_oe;
   logic              ocd_oe;
   // PHY Side
   //***************************************
   modport phy
	 (
	  input ba, input adr, input cmd, input reset_m_n, input clk_oe,
	  input ocd_oe
	  );

   // Memory Controller Side
   //***************************************
   modport mem_cntrl
	 (
	  output ba, output adr, output cmd, output reset_m_n, output clk_oe,
	  output ocd_oe
	  );
endinterface // if_mem_adr_cmd

interface if_phy_io_cal_config;
   // IMPEDANCE SELECTION
   logic [4:0] 	  ron_data;
   logic [4:0] 	  rtt_data;
   //logic [4:0] 	  ron_adr_cmd;
   // IMPEDANCE CALIBRATION OVERRIGHT DEBUG
   logic [4:0] 	  pu_en_ocd_cal;
   logic [4:0] 	  pd_en_ocd_cal;
   logic 		  disable_ocd_cal;
   // SLEW RATE CONFIG
   logic [1:0] 	  td_ctrl_n_data;
   logic 		  tdqs_trim_n_data;
   //logic [1:0] 	  td_ctrl_n_adr_cmd;
   //logic 		  tdqs_trim_n_adr_cmd;

   // PHY Side
   //***************************************
   modport phy
	 (
	  input ron_data, input rtt_data,
	  input pu_en_ocd_cal, input pd_en_ocd_cal, input disable_ocd_cal,
	  input td_ctrl_n_data, input tdqs_trim_n_data);
   // DRAM INIT UNIT Side
   //***************************************
   modport mem_cntrl
	 (
	  output ron_data, output rtt_data,
	  output pu_en_ocd_cal, output pd_en_ocd_cal, output disable_ocd_cal,
	  output td_ctrl_n_data, output tdqs_trim_n_data);
endinterface // if_dram_init


localparam cRON_60 = 5'b01011;
localparam cRON_48 = 5'b10011;
localparam cRON_40 = 5'b10111;
localparam cRON_34 = 5'b11111;

localparam cRTT_120 = 5'b01000;
localparam cRTT_60  = 5'b10000;
localparam cRTT_40  = 5'b11000;
localparam cRTT_30  = 5'b10110;
localparam cRTT_20  = 5'b10101;

`endif
