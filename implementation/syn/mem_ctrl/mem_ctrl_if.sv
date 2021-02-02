// bank independent timing DDR3 specific
interface dram_global_timing_if;
   logic [2:0] CCD_DRAM_CYCLES; // ccd always 4 for DDR3, Required for DDR4
   logic [3:0] WTR_DRAM_CYCLES; // wr max 7.5 ns for DDR3
   logic [3:0] RRD_DRAM_CYCLES; //same as WTR
`ifdef DDR4
   logic [2:0] CCD_DRAM_CYCLES_L; 
   logic [3:0] WTR_DRAM_CYCLES_L; 
   logic [3:0] RRD_DRAM_CYCLES_L; 
`endif
   //logic [15:0] AREF_DRAM_CYCLES;
   //logic [8:0] 	RFC_DRAM_CYCLES;
   logic [5:0] 		FAW_DRAM_CYCLES;
   //logic [6:0] 			ZQS_DRAM_CYCLES;
   logic [3:0] 				BL;
   logic [3:0] 					CWL;
   logic [3:0] 						CL;

   modport wp (input CCD_DRAM_CYCLES,WTR_DRAM_CYCLES,
	       RRD_DRAM_CYCLES,
`ifdef DDR4
	       input CCD_DRAM_CYCLES_L,WTR_DRAM_CYCLES_L,
	       RRD_DRAM_CYCLES_L,
`endif
	       /*AREF_DRAM_CYCLES,
		RFC_DRAM_CYCLES,*/input FAW_DRAM_CYCLES,/*ZQS_DRAM_CYCLES,*/
	       BL,CWL,CL);
   modport rp (output CCD_DRAM_CYCLES,WTR_DRAM_CYCLES,
	       RRD_DRAM_CYCLES,
`ifdef DDR4
	       output CCD_DRAM_CYCLES_L,WTR_DRAM_CYCLES_L,
	       RRD_DRAM_CYCLES_L,
`endif
	       /*RFC_DRAM_CYCLES,AREF_DRAM_CYCLES,*/
	       output FAW_DRAM_CYCLES,/*ZQS_DRAM_CYCLES,*/BL,CWL,CL);
   //modport mc_port (input CCD_DRAM_CYCLES,WTR_DRAM_CYCLES,RRD_DRAM_CYCLES,
   //		    AREF_DRAM_CYCLES,RFC_DRAM_CYCLES,FAW_DRAM_CYCLES,BL,CWL,CL);
endinterface // dram_timing_global

// bank specific timing
interface dram_bank_timing_if;
   logic [3:0] 			RP_DRAM_CYCLES;
   logic [3:0] 				RTP_DRAM_CYCLES;
   logic [4:0] 					WR_DRAM_CYCLES;
   logic [3:0] 						RCD_DRAM_CYCLES;
   logic [5:0] 							RAS_DRAM_CYCLES;

   modport wp (input RP_DRAM_CYCLES,RTP_DRAM_CYCLES,
	       WR_DRAM_CYCLES,RCD_DRAM_CYCLES,RAS_DRAM_CYCLES);
   modport rp (output RP_DRAM_CYCLES,RTP_DRAM_CYCLES,
	       WR_DRAM_CYCLES,RCD_DRAM_CYCLES,RAS_DRAM_CYCLES);
   //modport mc_port (input RP_DRAM_CYCLES,RTP_DRAM_CYCLES,WR_DRAM_CYCLES,
//		    RCD_DRAM_CYCLES,RAS_DRAM_CYCLES);
endinterface // dram_timing_bank

interface dram_aref_zq_timing_if;
   logic [19:0] AREFI_DRAM_CYCLES;
   logic [8:0] 	RFC_DRAM_CYCLES;
   logic [6:0] 		ZQS_DRAM_CYCLES;
   logic 			ZQS_DISABLE;
   logic 			DISABLE_REF;

   modport wp (input AREFI_DRAM_CYCLES,RFC_DRAM_CYCLES,ZQS_DRAM_CYCLES,ZQS_DISABLE,DISABLE_REF);
   modport rp (output AREFI_DRAM_CYCLES,RFC_DRAM_CYCLES,ZQS_DRAM_CYCLES,ZQS_DISABLE,DISABLE_REF);

endinterface // dram_ref_zq_timing_if

interface dram_rg_ref_if
  #(
     parameter DRAM_ADDR_WIDTH = 15
    )
   ();
   logic [DRAM_ADDR_WIDTH-1:0] 	start_addr;
   logic [DRAM_ADDR_WIDTH-1:0] 	end_addr;
   logic [5:0] 			num_row_per_ref; // per bank
   logic [3:0] 			rrd_dram_clk_cycle;
   logic [5:0] 			ras_dram_clk_cycle;
   logic [3:0] 			rp_dram_clk_cycle;
   logic 				en;

   modport wp (input start_addr,end_addr,num_row_per_ref,
	       rrd_dram_clk_cycle,ras_dram_clk_cycle,
	       rp_dram_clk_cycle,en);
   modport rp (output start_addr,end_addr,num_row_per_ref,
	       rrd_dram_clk_cycle,ras_dram_clk_cycle,
	       rp_dram_clk_cycle,en);

endinterface // dram_rg_ref_if



interface mode_reg_config_if; // mode reg
   logic [15:0] 					mr0;
   logic [15:0] 					mr1;
   logic [15:0] 					mr2;
   logic [15:0] 					mr3;


   modport wp (input mr0,mr1,mr2,mr3);
   modport rp (output mr0,mr1,mr2,mr3);
endinterface

interface phy_config_if;
   // IMPEDANCE SELECTION
   logic [4:0] 	  ron_data;
   logic [4:0] 	  rtt_data;
   logic [4:0] 	  ron_adr_cmd;
   // IMPEDANCE CALIBRATION OVERRIGHT DEBUG
   logic [4:0] 	  pu_en_ocd_cal;
   logic [4:0] 	  pd_en_ocd_cal;
   logic 		  disable_ocd_cal;
   // SLEW RATE CONFIG
   logic [1:0] 	  td_ctrl_n_data;
   logic 		  tdqs_trim_n_data;
   logic [1:0] 	  td_ctrl_n_adr_cmd;
   logic 		  tdqs_trim_n_adr_cmd;

   // PHY Side
   //***************************************
   modport phy
	 (
	  input ron_data, input rtt_data, input ron_adr_cmd,
	  input pu_en_ocd_cal, input pd_en_ocd_cal, input disable_ocd_cal,
	  input td_ctrl_n_data, input tdqs_trim_n_data, input td_ctrl_n_adr_cmd,
	  input tdqs_trim_n_adr_cmd);
   // DRAM INIT UNIT Side
   //***************************************
   modport mem_cntrl
	 (
	  output ron_data, output rtt_data, output ron_adr_cmd,
	  output pu_en_ocd_cal, output pd_en_ocd_cal, output disable_ocd_cal,
	  output td_ctrl_n_data, output tdqs_trim_n_data, output td_ctrl_n_adr_cmd,
	  output tdqs_trim_n_adr_cmd);
endinterface // if_dram_init

interface congen_if;
   logic [4:0] c3;
   logic [4:0] c4;
   logic [4:0] c5;
   logic [4:0] c6;
   logic [4:0] c7;
   logic [4:0] c8;
   logic [4:0] c9;
   logic [4:0] c10;
   logic [4:0] r0;
   logic [4:0] r1;
   logic [4:0] r2;
   logic [4:0] r3;
   logic [4:0] r4;
   logic [4:0] r5;
   logic [4:0] r6;
   logic [4:0] r7;
   logic [4:0] r8;
   logic [4:0] r9;
   logic [4:0] r10;
   logic [4:0] r11;
   logic [4:0] r12;
   logic [4:0] r13;
   logic [4:0] r14;
   logic [4:0] r15;
   logic [4:0] b0;
   logic [4:0] b1;
   logic [4:0] b2;
`ifdef DDR4
   logic [4:0] b3;
   logic [4:0] r16;
`endif
   logic [2:0] xor_sel;

   modport wp (input c3,c4,c5,c6,c7,c8,c9,c10,
	       r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,
	       b0,b1,b2,
`ifdef DDR4 
	       input b3, r16,
`endif 
	       input xor_sel
	       );
   modport rp (output c3,c4,c5,c6,c7,c8,c9,c10,
	       r0,r1,r2,r3,r4,r5,r6,r7,r8,r9,r10,r11,r12,r13,r14,r15,
	       b0,b1,b2,
`ifdef DDR4 
	       output b3, r16,
`endif 
	       input xor_sel);
endinterface // congen_if

