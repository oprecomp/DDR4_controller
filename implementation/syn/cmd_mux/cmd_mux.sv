module cmd_mux
  #(
    parameter DRAM_ADDR_WIDTH = 15,
    parameter DRAM_BANKS = 8,
    parameter DRAM_CMD_WIDTH = 5,
    parameter CLK_RATIO = 4,
    parameter PRIORITY_WIDTH = 6,
    parameter FE_ID_WIDTH = 8,
    parameter CAS_EVEN_SLOT = 0, // accepted values are either 1 (for XI FPGA) or zero
    parameter RRD_DRAM_CYCLES_LOG2 = 4,
    parameter CAS2CAS_DRAM_CYCLES_LOG2 = 4,
    parameter WR2RD_DRAM_CYCLES_LOG2 = 8,
    parameter RD2WR_DRAM_CYCLES_LOG2 = 8
    /***************************DRAM timings in DRAM ck************************/
    // FIXME: for asic no parameter
    /*parameter RRD_DRAM_CYCLES = 4,
     parameter WTR_DRAM_CYCLES = 4,
     parameter CCD_DRAM_CYCLES = 4,
     parameter CL = 5,
     parameter CWL = 5,
     parameter TFAW_NS = 40,
     parameter BL = 8*/
    )
   (
    input 						 clk,
    input 						 rst_n,

	// Bank machine to cmd_mux
    input [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	 bm_addr,
    input [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0] 	 bm_slot,
    input [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 		 bm_priority,
    input [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 		 bm_id,
    input [DRAM_BANKS-1:0] 				 bm_act,
    input [DRAM_BANKS-1:0] 				 bm_cas,
    input [DRAM_BANKS-1:0] 				 bm_r_w, // 1=read, 0=write
    input [DRAM_BANKS-1:0] 				 bm_pre,
    input [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0] 	 bm_bank,
    input [PRIORITY_WIDTH-1:0] 				 not_srvd_earliest_act,
    input [PRIORITY_WIDTH-1:0] 				 not_srvd_earliest_pre,

	// order qu bank id for strict ordering
    input [$clog2(DRAM_BANKS)-1:0] 			 ord_qu_bank,
    output 						 next_id,

	// RM to cmd mux
    input 						 rm_stall,
    input 						 bm_en,

	// cmd_mux to bank machine
    output logic 					 cmd_mux_act_ack,
    output logic [$clog2(DRAM_BANKS)-1:0] 		 cmd_mux_act_grant,
    output logic [$clog2(CLK_RATIO)-1:0] 		 cmd_mux_act_slot,
    output logic 					 cmd_mux_cas_ack,
    output logic [$clog2(DRAM_BANKS)-1:0] 		 cmd_mux_cas_grant,
    output logic [$clog2(CLK_RATIO)-1:0] 		 cmd_mux_cas_slot,
    output logic 					 cmd_mux_pre_ack,
    output logic [$clog2(DRAM_BANKS)-1:0] 		 cmd_mux_pre_grant,
    output logic [$clog2(CLK_RATIO)-1:0] 		 cmd_mux_pre_slot,

	// cmd_mux to Rank machine module
    output logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 cmd_mux_addr,
    output logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] cmd_mux_bank,
`ifdef DDR4
    output logic [CLK_RATIO-1:0] 			 cmd_mux_act_n,
`endif
    output logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 cmd_mux_cmd,
    output logic [CLK_RATIO-1:0] 			 cmd_mux_valid,
    output logic [FE_ID_WIDTH-1:0] 			 cmd_mux_fe_id,
    output logic 					 cmd_mux_fe_id_valid,
	// cmd_mux to phy
    output logic 					 cmd_mux_write,
    output logic 					 cmd_mux_read,
    output logic [$clog2(CLK_RATIO)-1:0] 		 cmd_mux_cas_slot_stg3,
							 //DRAM timing
							 dram_global_timing_if.wp dram_t_rm
	);

    // Cmd order | cke | cs_n | ras_n | cas_n | we_n |
`ifdef DDR4
   localparam NOP = 5'b11111;
   // In DDR4 the NOP command is not allowed, except when exiting maximum power savings mode 
   // or when entering gear-down mode, and only a DES command should be Used
   // Basically DDR3 NOP is equvalent to DES in DDR4 during normal operation
   // Hence setting cs_n to H or 1
`else
   localparam NOP = 5'b10111;
`endif
   localparam ACT = 5'b10011;
   localparam PRE = 5'b10010;
   localparam WR = 5'b10100;
   localparam RD = 5'b10101;

   /***************************Timers and Checkers*****************************/

   // FIXME: Chirag: All timers have same logic. Create a module for one timer
   // logic and reuse it.

   //ACT to ACT check
   logic [(RRD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] act2act_check;
   logic 						  safe_act2act;
   logic 						  safe_act2act_q;
   logic [$clog2(CLK_RATIO)-1:0] 			  act2act_slot;
   logic [$clog2(CLK_RATIO)-1:0] 			  act_slot;
   logic [$clog2(CLK_RATIO):0] 			  nxt_act2act_slot;
   logic 						  nxt_act2act_slot_ovf;
   logic 						  isact;
   logic [(RRD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] ACT2ACT_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 			  ACT2ACT_CTRL_SLOT;

   assign ACT2ACT_CTRL_CYCLES = dram_t_rm.RRD_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign ACT2ACT_CTRL_SLOT = dram_t_rm.RRD_DRAM_CYCLES - (ACT2ACT_CTRL_CYCLES <<
							   $clog2(CLK_RATIO));

   assign nxt_act2act_slot = act_slot + ACT2ACT_CTRL_SLOT;
   assign nxt_act2act_slot_ovf = nxt_act2act_slot > (CLK_RATIO-1);

   // FIXME: split it into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:act2act
	if(rst_n == 1'b0)begin
	   act2act_check <= 0;
	   act2act_slot <= 0;
	end
	else
	  begin
	     if(isact == 1'b1) begin
		act2act_slot <= nxt_act2act_slot_ovf ?
				(nxt_act2act_slot - CLK_RATIO):nxt_act2act_slot;
		act2act_check <= ((ACT2ACT_CTRL_CYCLES > 1)?
				  ACT2ACT_CTRL_CYCLES-1:0)+
				 (nxt_act2act_slot_ovf?1:0);
	     end
	     else
	       if(act2act_check != 0)
		 act2act_check <= act2act_check - 1'b1;
	       else
		 act2act_slot <= 0;
	     // slot is applicable only for clk at which the signal act2act_check
	     // makes a  transition to zero. From later clks even if
	     // act2act_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: act2act

   assign safe_act2act = (act2act_check == 0) || (rm_stall && safe_act2act_q);
   // if stall, retain the value of safe_act2act
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_act2act_q <= '0;
	else
	  safe_act2act_q <= safe_act2act;
     end

`ifdef DDR4

    //ACT to ACT check same bank group (BG)
   logic [(RRD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] act2act_check_l;
   logic 						  safe_act2act_l;
   logic 						  safe_act2act_q_l;
   logic [$clog2(CLK_RATIO)-1:0] 			  act2act_slot_l;
   logic [$clog2(CLK_RATIO):0] 				  nxt_act2act_slot_l;
   logic 						  nxt_act2act_slot_ovf_l;
   logic [(RRD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] ACT2ACT_CTRL_CYCLES_L;
   logic [$clog2(CLK_RATIO)-1:0] 			  ACT2ACT_CTRL_SLOT_L;

   assign ACT2ACT_CTRL_CYCLES_L = dram_t_rm.RRD_DRAM_CYCLES_L >> $clog2(CLK_RATIO);
   assign ACT2ACT_CTRL_SLOT_L = dram_t_rm.RRD_DRAM_CYCLES_L - (ACT2ACT_CTRL_CYCLES_L <<
							   $clog2(CLK_RATIO));

   assign nxt_act2act_slot_l = act_slot + ACT2ACT_CTRL_SLOT_L;
   assign nxt_act2act_slot_ovf_l = nxt_act2act_slot_l > (CLK_RATIO-1);

   // FIXME: split it into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:act2act_l
	if(rst_n == 1'b0)begin
	   act2act_check_l <= 0;
	   act2act_slot_l <= 0;
	end
	else
	  begin
	     if(isact == 1'b1) begin
		act2act_slot_l <= nxt_act2act_slot_ovf_l ?
				(nxt_act2act_slot_l - CLK_RATIO):nxt_act2act_slot_l;
		act2act_check_l <= ((ACT2ACT_CTRL_CYCLES_L > 1)?
				  ACT2ACT_CTRL_CYCLES_L-1:0)+
				 (nxt_act2act_slot_ovf_l?1:0);
	     end
	     else
	       if(act2act_check_l != 0)
		 act2act_check_l <= act2act_check_l - 1'b1;
	       else
		 act2act_slot_l <= 0;
	     // slot is applicable only for clk at which the signal act2act_check
	     // makes a  transition to zero. From later clks even if
	     // act2act_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: act2act

   assign safe_act2act_l = (act2act_check_l == 0) || (rm_stall && safe_act2act_q_l);
   // if stall, retain the value of safe_act2act
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_act2act_q_l <= '0;
	else
	  safe_act2act_q_l <= safe_act2act_l;
     end

`endif
   


   //CAS to CAS Delay check
   logic        safe_ccd;
   logic [$clog2(CLK_RATIO)-1:0] cas2cas_slot,cas_slot;
   logic 			 iscas,iscas_n,iswrite,isread;
   assign safe_ccd = 1;

   always_ff @(posedge clk, negedge rst_n)
     begin:cas2cas
	if(rst_n == 1'b0)
	  cas2cas_slot <= 0;
	else
	  begin
	     if(iscas == 1'b1)
	       cas2cas_slot <= cas_slot;
	     else
	       cas2cas_slot <= 0;
	  end
     end // block: cas2cas
   // FIXME: Chirag: This is correct only if CLK_RATIO is 4 or BL/2.
   // Write for general case of CLK_RATIO

`ifdef DDR4

   //CAS to CAS check same BG
   logic [(CAS2CAS_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] cas2cas_check_l;
   logic 						      safe_cas2cas_l;
   logic 						      safe_cas2cas_q_l;
   logic [$clog2(CLK_RATIO)-1:0] 			      cas2cas_slot_l;
   logic [$clog2(CLK_RATIO):0] 				      nxt_cas2cas_slot_l;
   logic 						      nxt_cas2cas_slot_ovf_l;
   logic [(CAS2CAS_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] CAS2CAS_CTRL_CYCLES_L;
   logic [$clog2(CLK_RATIO)-1:0] 			      CAS2CAS_CTRL_SLOT_L;

   assign CAS2CAS_CTRL_CYCLES_L = dram_t_rm.CCD_DRAM_CYCLES_L >> $clog2(CLK_RATIO);
   assign CAS2CAS_CTRL_SLOT_L = dram_t_rm.CCD_DRAM_CYCLES_L - (CAS2CAS_CTRL_CYCLES_L <<
							   $clog2(CLK_RATIO));
   assign nxt_cas2cas_slot_l = cas_slot + CAS2CAS_CTRL_SLOT_L;
   assign nxt_cas2cas_slot_ovf_l = nxt_cas2cas_slot_l > (CLK_RATIO-1);

   // FIXME: split into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:cas2cas_l
	if(rst_n == 1'b0)begin
	   cas2cas_check_l <= 0;
	   cas2cas_slot_l <= 0;
	end
	else
	  begin
	     if(iscas == 1'b1) begin
		cas2cas_slot_l <= nxt_cas2cas_slot_ovf_l ? (nxt_cas2cas_slot_l - CLK_RATIO):
			      nxt_cas2cas_slot_l;
		cas2cas_check_l <= ((CAS2CAS_CTRL_CYCLES_L > 1)?CAS2CAS_CTRL_CYCLES_L-1:0)+
			       (nxt_cas2cas_slot_ovf_l?1:0);
	     end
	     else
	       if(cas2cas_check_l > 0)
		 cas2cas_check_l <= cas2cas_check_l - 1'b1;
	       else
		 cas2cas_slot_l <= 0;
	     // slot is applicable only for clk at which the signal wr2rd_check
	     // makes a  transition to zero. From later clks even if
	     // wr2rd_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: wr2rd

   assign safe_cas2cas_l = (cas2cas_check_l == 0) || (rm_stall && safe_cas2cas_q_l);
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_cas2cas_q_l <= '0;
	else
	  safe_cas2cas_q_l <= safe_cas2cas_l;
     end
  
`endif

   //WR to RD check
   logic [(WR2RD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] wr2rd_check;
   logic 						    safe_wr2rd;
   logic 						    safe_wr2rd_q;
   logic [$clog2(CLK_RATIO)-1:0] 			    wr2rd_slot,write_slot;
   logic [$clog2(CLK_RATIO):0] 				    nxt_wr2rd_slot;
   logic 							    nxt_wr2rd_slot_ovf;
   logic [WR2RD_DRAM_CYCLES_LOG2-1:0] 				    WR2RD_DRAM_CYCLES;
   logic [(WR2RD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	    WR2RD_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				    WR2RD_CTRL_SLOT;

   assign WR2RD_DRAM_CYCLES = dram_t_rm.WTR_DRAM_CYCLES + dram_t_rm.CWL +
			      (dram_t_rm.BL/2);
   assign WR2RD_CTRL_CYCLES = WR2RD_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign WR2RD_CTRL_SLOT = WR2RD_DRAM_CYCLES - (WR2RD_CTRL_CYCLES <<
						 $clog2(CLK_RATIO));

   assign nxt_wr2rd_slot = write_slot + WR2RD_CTRL_SLOT;
   assign nxt_wr2rd_slot_ovf = nxt_wr2rd_slot > (CLK_RATIO-1);

   // FIXME: split into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:wr2rd
	if(rst_n == 1'b0)begin
	   wr2rd_check <= 0;
	   wr2rd_slot <= 0;
	end
	else
	  begin
	     if(iswrite == 1'b1) begin
		wr2rd_slot <= nxt_wr2rd_slot_ovf ? (nxt_wr2rd_slot - CLK_RATIO):
			      nxt_wr2rd_slot;
		wr2rd_check <= ((WR2RD_CTRL_CYCLES > 1)?WR2RD_CTRL_CYCLES-1:0)+
			       (nxt_wr2rd_slot_ovf?1:0);
	     end
	     else
	       if(wr2rd_check > 0)
		 wr2rd_check <= wr2rd_check - 1'b1;
	       else
		 wr2rd_slot <= 0;
	     // slot is applicable only for clk at which the signal wr2rd_check
	     // makes a  transition to zero. From later clks even if
	     // wr2rd_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: wr2rd

   assign safe_wr2rd = (wr2rd_check == 0) || (rm_stall && safe_wr2rd_q);
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_wr2rd_q <= '0;
	else
	  safe_wr2rd_q <= safe_wr2rd;
     end

`ifdef DDR4

   //WR to RD check same BG
   logic [(WR2RD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] wr2rd_check_l;
   logic 						    safe_wr2rd_l;
   logic 						    safe_wr2rd_q_l;
   logic [$clog2(CLK_RATIO)-1:0] 			    wr2rd_slot_l;
   logic [$clog2(CLK_RATIO):0] 				    nxt_wr2rd_slot_l;
   logic 							    nxt_wr2rd_slot_ovf_l;
   logic [WR2RD_DRAM_CYCLES_LOG2-1:0] 				    WR2RD_DRAM_CYCLES_L;
   logic [(WR2RD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	    WR2RD_CTRL_CYCLES_L;
   logic [$clog2(CLK_RATIO)-1:0] 				    WR2RD_CTRL_SLOT_L;

   assign WR2RD_DRAM_CYCLES_L = dram_t_rm.WTR_DRAM_CYCLES_L + dram_t_rm.CWL +
			      (dram_t_rm.BL/2);
   assign WR2RD_CTRL_CYCLES_L = WR2RD_DRAM_CYCLES_L >> $clog2(CLK_RATIO);
   assign WR2RD_CTRL_SLOT_L = WR2RD_DRAM_CYCLES_L - (WR2RD_CTRL_CYCLES_L <<
						 $clog2(CLK_RATIO));

   assign nxt_wr2rd_slot_l = write_slot + WR2RD_CTRL_SLOT_L;
   assign nxt_wr2rd_slot_ovf_l = nxt_wr2rd_slot_l > (CLK_RATIO-1);

   // FIXME: split into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:wr2rd_l
	if(rst_n == 1'b0)begin
	   wr2rd_check_l <= 0;
	   wr2rd_slot_l <= 0;
	end
	else
	  begin
	     if(iswrite == 1'b1) begin
		wr2rd_slot_l <= nxt_wr2rd_slot_ovf_l ? (nxt_wr2rd_slot_l - CLK_RATIO):
			      nxt_wr2rd_slot_l;
		wr2rd_check_l <= ((WR2RD_CTRL_CYCLES_L > 1)?WR2RD_CTRL_CYCLES_L-1:0)+
			       (nxt_wr2rd_slot_ovf_l?1:0);
	     end
	     else
	       if(wr2rd_check_l > 0)
		 wr2rd_check_l <= wr2rd_check_l - 1'b1;
	       else
		 wr2rd_slot_l <= 0;
	     // slot is applicable only for clk at which the signal wr2rd_check
	     // makes a  transition to zero. From later clks even if
	     // wr2rd_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: wr2rd

   assign safe_wr2rd_l = (wr2rd_check_l == 0) || (rm_stall && safe_wr2rd_q_l);
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_wr2rd_q_l <= '0;
	else
	  safe_wr2rd_q_l <= safe_wr2rd_l;
     end
  
`endif     

   //RD to WR check
   logic [(RD2WR_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] rd2wr_check;
   logic 						    safe_rd2wr;
   logic 						    safe_rd2wr_q;
   logic [$clog2(CLK_RATIO)-1:0] 			    rd2wr_slot,read_slot;
   logic [$clog2(CLK_RATIO):0] 				    nxt_rd2wr_slot;
   logic 							    nxt_rd2wr_slot_ovf;
   logic [RD2WR_DRAM_CYCLES_LOG2-1:0] 				    RD2WR_DRAM_CYCLES;
   logic [(RD2WR_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	    RD2WR_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				    RD2WR_CTRL_SLOT;

   assign RD2WR_DRAM_CYCLES = dram_t_rm.CL + dram_t_rm.CCD_DRAM_CYCLES + 2 - dram_t_rm.CWL +1;
   //+1 is Phy specific to avoid simultaneous switching of read and write
   // termination. Thereby, avoiding glitches for the last burst of the read cmd
   assign RD2WR_CTRL_CYCLES = RD2WR_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign RD2WR_CTRL_SLOT = RD2WR_DRAM_CYCLES - (RD2WR_CTRL_CYCLES<<$clog2(CLK_RATIO));

   assign nxt_rd2wr_slot = read_slot + RD2WR_CTRL_SLOT;
   assign nxt_rd2wr_slot_ovf = nxt_rd2wr_slot > (CLK_RATIO-1);

   // FIXME: split into 2 FFs
   always_ff @(posedge clk, negedge rst_n)
     begin:rd2wr
	if(rst_n == 1'b0)begin
	   rd2wr_check <= 0;
	   rd2wr_slot <= 0;
	end
	else
	  begin
	     if(isread == 1'b1) begin
		rd2wr_slot <= nxt_rd2wr_slot_ovf?(nxt_rd2wr_slot - CLK_RATIO):
			      nxt_rd2wr_slot;
		rd2wr_check <= ((RD2WR_CTRL_CYCLES > 1)?RD2WR_CTRL_CYCLES-1:0)+
			       (nxt_rd2wr_slot_ovf?1:0);
	     end
	     else
	       if(rd2wr_check > 0)
		 rd2wr_check <= rd2wr_check - 1'b1;
	       else
		 rd2wr_slot <= 0;
	     // slot is applicable only for clk at which the signal rd2wr_check
	     // makes a  transition to zero. From later clks even if
	     // rd2wr_check is 0 slot is not applicable
	  end // else: !if(rst_n == 1'b0)
     end // block: rd2wr
   assign safe_rd2wr = (rd2wr_check == 0) || (rm_stall && safe_rd2wr_q);
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  safe_rd2wr_q <= '0;
	else
	  safe_rd2wr_q <= safe_rd2wr;
     end

   /************************END of Timers and Checkers*************************/

   /*****************************ACT REQ processing****************************/
   logic [$clog2(CLK_RATIO)-1:0] acptd_act_req_slot;
   logic [DRAM_ADDR_WIDTH-1:0] 	 act_addr;
   logic [$clog2(DRAM_BANKS)-1:0] 	 act_grant_lcl,act_bank;
   logic [DRAM_BANKS-1:0] 		 act_req_lcl;
   logic [DRAM_CMD_WIDTH-1:0] 		 act_cmd;
   logic 				 cmd_mux_isact_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] 	 cmd_mux_act_grant_stg1;
   logic [$clog2(CLK_RATIO)-1:0] 	 cmd_mux_act_slot_stg1;
   logic [DRAM_ADDR_WIDTH-1:0] 		 act_addr_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] 	 act_bank_stg1;
   logic [DRAM_CMD_WIDTH-1:0] 		 act_cmd_stg1;
   logic [DRAM_BANKS-1:0] 		 bm_prev_cycle_isact;
   

`ifdef DDR4
   localparam DRAM_BG = 4; // 4 BG for DDR4

   logic [DRAM_BG-1:0] 			 prev_act_bg;
   
   genvar 				 i;
   generate
      for(i=0;i<DRAM_BG;i++) begin // assuming 4 BG
	 assign act_req_lcl[(DRAM_BG*(i+1))-1:DRAM_BG*i] = ((prev_act_bg==i)?safe_act2act_l:
							    safe_act2act)?
	                                                    bm_act[(DRAM_BG*(i+1))-1:DRAM_BG*i]:0;
      end
   endgenerate
`else // !`ifdef DDR4
   assign act_req_lcl = safe_act2act?bm_act:0;
`endif // !`ifdef DDR4
      
   // don't start processing any act request unless act2act is satifies

   // Priority arbiter send the act req and slot nr from a line with highest
   // priority. It only considers bus with valid act req.
`ifndef FPGA
   priority_arbiter
     #(
       .PRIORITY_WIDTH(PRIORITY_WIDTH),
       .DATA_WIDTH($clog2(CLK_RATIO)),
       .NR_INPUTS(DRAM_BANKS)
       )act_req_arbiter
       (
	.priority_i(bm_priority),
	.data_i(bm_slot),
	.req(act_req_lcl & bm_prev_cycle_isact),
	.highest_priority(not_srvd_earliest_act),
	.data_o(acptd_act_req_slot),
	.valid(isact),
	.grant(act_grant_lcl)
	);
`else // !`ifndef FPGA
   priority_encoder_16 // for DDR3 thios has to be _8. Make it configurable 
     #(
       )fixed_priority_arbiter_act
       (
	.req(act_req_lcl & bm_prev_cycle_isact),
	.valid(isact),
	.out(act_grant_lcl)
	);

   mux_1
     #(
       .WIDTH($clog2(CLK_RATIO)),
       .NR_INPUTS(DRAM_BANKS)
       )act_slot_mux
       (
	.in(bm_slot),
	.sel(act_grant_lcl),
	.out(acptd_act_req_slot)
	);
`endif // !`ifndef FPGA

   //inhibit the act req from BM whose ACT req was previously (1 cycle prior) accepted/ack. This ensure that the same request is not processed twice. It is helpful when the BM request are sent to FF and then forworded to cmd_mux.
   genvar k;
   generate
      for(k=0;k<DRAM_BANKS;k++) begin
	 assign bm_prev_cycle_isact[k]=(cmd_mux_act_ack && !rm_stall)?
				       (cmd_mux_act_grant!=k):1'b1;
      end
   endgenerate
   
   mux_1
     #(
       .WIDTH($clog2(DRAM_BANKS)),
       .NR_INPUTS(DRAM_BANKS)
       )act_bank_mux
       (
	.in(bm_bank),
	.sel(act_grant_lcl),
	.out(act_bank)
	);
   
   //slect the later slot, so as to meet all timing req
   comp_sel_grt
     #(
       .DATA_WIDTH($clog2(CLK_RATIO))
       )act2act_slot_cmp_sel_grt
       (
	.in_a(acptd_act_req_slot),
	.in_b(rm_stall&&cmd_mux_act_ack?{$clog2(CLK_RATIO){1'b0}}:
	      ((act_bank[$clog2(DRAM_BANKS)-1:$clog2(DRAM_BANKS)-$clog2(DRAM_BG)]==prev_act_bg)?
	       act2act_slot_l:act2act_slot)),
	.out(act_slot)
	);

      
   //send grant signal to BM whose act req was processed
   mux_1
     #(
       .WIDTH(DRAM_ADDR_WIDTH),
       .NR_INPUTS(DRAM_BANKS)
       )act_addr_mux
       (
	.in(bm_addr),
	.sel(act_grant_lcl),
	.out(act_addr)
	);

   assign act_cmd = (isact)?ACT:NOP;


   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_act_ack <= '0;
	     cmd_mux_act_grant <= '0;
	     cmd_mux_act_slot <= '0;
	     cmd_mux_isact_stg1 <= '0;
	     cmd_mux_act_grant_stg1 <= '0;
	     cmd_mux_act_slot_stg1 <= '0;
`ifdef DDR4
	     prev_act_bg <= '0;
`endif
	  end
	else
	  begin
	     cmd_mux_act_ack <= isact;
	     cmd_mux_act_grant <= act_grant_lcl;
	     cmd_mux_act_slot <= act_slot;
`ifdef DDR4
	     prev_act_bg <= isact?act_bank[$clog2(DRAM_BANKS)-1:$clog2(DRAM_BANKS)-$clog2(DRAM_BG)]
			    :prev_act_bg;
`endif
	     if(!(rm_stall && bm_en)) begin
		act_addr_stg1 <= act_addr;
		act_bank_stg1 <= act_bank;
		act_cmd_stg1 <= act_cmd;
	       	cmd_mux_isact_stg1 <= isact;
		cmd_mux_act_grant_stg1 <= act_grant_lcl;
		cmd_mux_act_slot_stg1 <= act_slot;
	     end
	     
	  end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)

   /*************************End of ACT req processing*************************/

   /*****************************CAS REQ processing****************************/

   logic [DRAM_ADDR_WIDTH-1:0] 		 cas_addr;
   logic [$clog2(DRAM_BANKS)-1:0] 	 cas_bank;
   logic [FE_ID_WIDTH-1:0] 		 cas_id;
   logic [$clog2(CLK_RATIO)-1:0] 	 cas_slot_lcl;
   logic [$clog2(CLK_RATIO)-1:0] 	 acptd_cas_req_slot;
   logic [$clog2(CLK_RATIO)-1:0] 	 cas_slot_earliest;
   logic [$clog2(CLK_RATIO)-1:0] 	 cas_slot_earliest_lcl;
   logic 				 cas_req_halt;
   logic 				 cas_req_lcl;
   logic 				 cas_rw_lcl;
   logic 				 safe_rw;
   logic 				 prev_cas_r_w;
   logic 				 latched_prev_cas_r_w;
   logic [DRAM_CMD_WIDTH-1:0] 		 cas_cmd;
   logic [$clog2(DRAM_BANKS)-1:0] 	 ord_qu_bank_lcl;
   logic 				 cmd_mux_send_stall_cas_cmd;
   logic 				 cmd_mux_write_q;
   logic 				 cmd_mux_read_q;
   wire 				 cmd_mux_inhibit_next_id;
   
`ifdef DDR4
   logic [DRAM_BG-1:0] 			 prev_cas_bg;
   logic [$clog2(DRAM_BG)-1:0] 		 cas_bg;
`endif

   logic 				 cmd_mux_isact_stg2;
   logic [$clog2(DRAM_BANKS)-1:0] 	 cmd_mux_act_grant_stg2;
   logic [$clog2(CLK_RATIO)-1:0] 	 cmd_mux_act_slot_stg2;
   logic 				 cmd_mux_iscas_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] 	 cmd_mux_cas_grant_stg1;
   logic [$clog2(CLK_RATIO)-1:0] 	 cmd_mux_cas_slot_stg1;
   logic 				 cmd_mux_iswrite_stg1;
   logic 				 cmd_mux_isread_stg1;
   logic [DRAM_ADDR_WIDTH-1:0] 		 act_addr_stg2;
   logic [$clog2(DRAM_BANKS)-1:0] 	 act_bank_stg2;
   logic [DRAM_CMD_WIDTH-1:0] 		 act_cmd_stg2;
   logic [DRAM_ADDR_WIDTH-1:0] 		 cas_addr_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] 	 cas_bank_stg1;
   logic [DRAM_CMD_WIDTH-1:0] 		 cas_cmd_stg1;
   logic [DRAM_BANKS-1:0] 		 bm_prev_cycle_iscas;
   logic [FE_ID_WIDTH-1:0] 		 cmd_mux_cas_id_stg1; 				 


   // FIXME: Chirag: Combine all mux to one.
   assign cmd_mux_inhibit_next_id = ((rm_stall&&cmd_mux_cas_ack)||
				     (cmd_mux_send_stall_cas_cmd &&
				      !(!rm_stall&&cmd_mux_cas_ack)));
   assign ord_qu_bank_lcl = cmd_mux_inhibit_next_id ?cmd_mux_cas_grant:
			    ord_qu_bank;

   mux_1
     #(
       .WIDTH(DRAM_ADDR_WIDTH),
       .NR_INPUTS(DRAM_BANKS)
       )cas_addr_mux
       (
	.in(bm_addr),
	.sel(ord_qu_bank_lcl),
	.out(cas_addr)
	);

   mux_1
     #(
       .WIDTH($clog2(DRAM_BANKS)),
       .NR_INPUTS(DRAM_BANKS)
       )cas_bank_mux
       (
	.in(bm_bank),
	.sel(ord_qu_bank_lcl),
	.out(cas_bank)
	);

   mux_1
     #(
       .WIDTH($clog2(CLK_RATIO)),
       .NR_INPUTS(DRAM_BANKS)
       )cas_slot_mux
       (
	.in(bm_slot),
	.sel(ord_qu_bank_lcl),
	.out(acptd_cas_req_slot)
	);

   mux_1
     #(
       .WIDTH(FE_ID_WIDTH),
       .NR_INPUTS(DRAM_BANKS)
       )cas_id_mux
       (
	.in(bm_id),
	.sel(ord_qu_bank_lcl),
	.out(cas_id)
	);

   genvar 				 h;
   generate
      for(h=0;h<DRAM_BANKS;h++) begin
	 assign bm_prev_cycle_iscas[h]=(cmd_mux_cas_ack && !rm_stall)?
				       (cmd_mux_cas_grant!=h):1'b1;
      end
   endgenerate
   
   mux_1
     #(
       .WIDTH(1),
       .NR_INPUTS(DRAM_BANKS)
       )cas_req_mux
       (
	.in(bm_cas & bm_prev_cycle_iscas),
	.sel(ord_qu_bank_lcl),
	.out(cas_req_lcl)
	);

   mux_1
     #(
       .WIDTH(1),
       .NR_INPUTS(DRAM_BANKS)
       )cas_rw_mux
       (
	.in(bm_r_w),
	.sel(ord_qu_bank_lcl),
	.out(cas_rw_lcl)
	);

`ifdef DDR4
   assign cas_bg = cas_bank[($clog2(DRAM_BANKS)-1):($clog2(DRAM_BANKS)-$clog2(DRAM_BG))];
`endif
   

   //identify the timing check(in ctrl clk) that is applicable for this cas cmd
   always_comb
     begin
	case({prev_cas_r_w,cas_rw_lcl})
	  2'b00: begin
`ifdef DDR4
	     safe_rw = (prev_cas_bg==cas_bg)?safe_cas2cas_l:safe_ccd;
	     cas_slot_lcl = (prev_cas_bg==cas_bg)?cas2cas_slot_l:cas2cas_slot;
`else
	     safe_rw = safe_ccd;
	     cas_slot_lcl = cas2cas_slot;
`endif
	  end
	  2'b01: begin
`ifdef DDR4
	     safe_rw = (prev_cas_bg==cas_bg)?safe_wr2rd_l:safe_wr2rd;
	     cas_slot_lcl = (prev_cas_bg==cas_bg)?wr2rd_slot_l:wr2rd_slot;
`else
	     safe_rw = safe_wr2rd;
	     cas_slot_lcl = wr2rd_slot;
`endif
	  end
	  2'b10: begin
	     safe_rw = safe_rd2wr;
	     cas_slot_lcl = rd2wr_slot;
	  end
	  2'b11: begin
`ifdef DDR4
	     safe_rw = (prev_cas_bg==cas_bg)?safe_cas2cas_l:safe_ccd;
	     cas_slot_lcl = (prev_cas_bg==cas_bg)?cas2cas_slot_l:cas2cas_slot;
`else
	     safe_rw = safe_ccd;
	     cas_slot_lcl = cas2cas_slot;
`endif
	  end
	  default: begin
	     safe_rw = 0;
	     cas_slot_lcl = wr2rd_slot;
	  end
	endcase // case ({prev_cas_r_w,cas_rw_lcl})
     end // always_comb

   //slect the later slot, so as to meet all timing req
   comp_sel_grt
     #(
       .DATA_WIDTH($clog2(CLK_RATIO))
       )cas_slot_cmp_sel_grt
       (
	.in_a(acptd_cas_req_slot),
	.in_b(rm_stall&&cmd_mux_cas_ack?{$clog2(CLK_RATIO){1'b0}}:cas_slot_lcl),
	.out(cas_slot_earliest_lcl)
	);
   
   // Logic for making cas slot to be in even slot (i.e 0 or 2) always.
   // this feature is required for some PHY like xilinx phy. 
   // If the CAS_EVEN_SLOT is set to zero then this feature is disabled
   // add CAS_EVEN_SLOT (i.e. = 1) if cas slot is not even.
   assign {cas_req_halt,cas_slot_earliest} = cas_slot_earliest_lcl+
					     (cas_slot_earliest_lcl[0]?CAS_EVEN_SLOT:0);
   assign {iscas_n,cas_slot} = ((cas_slot_earliest == cmd_mux_act_slot_stg1)&& cmd_mux_isact_stg1)?
			       (cas_slot_earliest+1+CAS_EVEN_SLOT):
			       {!cas_req_lcl,cas_slot_earliest};
   //Xilinx ultra scale Phy requires the CAS slot to be in even slot only.
   /*sign {iscas_n,cas_slot} = (((cas_slot_earliest == act_slot)&& isact)?
			       (cas_slot_earliest+(cas_slot_earliest[0]?1:
						   1+CAS_EVEN_SLOT)):
			       cas_slot_earliest+(cas_slot_earliest[0]? 3'd1:0));*/
   assign iscas = !iscas_n & cas_req_lcl & safe_rw & !cas_req_halt;
   assign iswrite = iscas & !cas_rw_lcl;
   assign isread = iscas & cas_rw_lcl;
   assign write_slot = iswrite?cas_slot:0;
   assign read_slot = isread?cas_slot:0;
   assign cas_cmd = (iscas)?((iswrite)?WR:RD):NOP;

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_cas_ack <= 1'b0;
	     cmd_mux_cas_grant <= '0;
	     cmd_mux_cas_slot <= '0;
	     cmd_mux_iswrite_stg1 <= '0;
	     cmd_mux_isread_stg1 <= '0;
	     cmd_mux_isact_stg2 <= '0;
	     cmd_mux_act_grant_stg2 <= '0;
	     cmd_mux_act_slot_stg2 <= '0;
	     cmd_mux_iscas_stg1 <= '0;
	     cmd_mux_cas_grant_stg1 <= '0;
	     cmd_mux_cas_slot_stg1 <= '0;
	     act_addr_stg2 <= '0;
	     act_bank_stg2 <= '0;
	     act_cmd_stg2 <= '0;
	     cas_addr_stg1 <= '0;
	     cas_bank_stg1 <= '0;
	     cas_cmd_stg1 <= '0;
	     cmd_mux_cas_id_stg1 <= '0;
	  end
	else
	  begin
	     cmd_mux_cas_ack <= iscas;
	     cmd_mux_cas_grant <= ord_qu_bank_lcl;
	     cmd_mux_cas_slot <= cas_slot;
	     if(!(rm_stall && bm_en)) begin
		act_addr_stg2 <= act_addr_stg1;
		act_bank_stg2 <= act_bank_stg1;
		act_cmd_stg2 <= act_cmd_stg1;
		cas_addr_stg1 <= cas_addr;
		cas_bank_stg1 <= cas_bank;
		cas_cmd_stg1 <= cas_cmd;
		cmd_mux_isact_stg2 <= cmd_mux_isact_stg1;
		cmd_mux_act_grant_stg2 <= cmd_mux_act_grant_stg1;
		cmd_mux_act_slot_stg2 <= cmd_mux_act_slot_stg1;
		cmd_mux_iscas_stg1 <= iscas;
		cmd_mux_cas_grant_stg1 <= ord_qu_bank_lcl;
		cmd_mux_cas_slot_stg1 <= cas_slot;
		cmd_mux_iswrite_stg1 <= iswrite;
		cmd_mux_isread_stg1 <= isread;
		cmd_mux_cas_id_stg1 <= cas_id;
	     end
	  end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_send_stall_cas_cmd <= 1'b0;
	  end
	else
	  if(cmd_mux_cas_ack && rm_stall)
	    cmd_mux_send_stall_cas_cmd <= 1'b1;
	  else if(cmd_mux_cas_ack && !rm_stall)
	    cmd_mux_send_stall_cas_cmd <= 1'b0;
     end // always_ff @ (posedge clk, negedge rst_n)

   assign next_id = iscas && !cmd_mux_inhibit_next_id;//cmd_mux_cas_ack;

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     prev_cas_r_w <= 0;
	     latched_prev_cas_r_w <= 0;
`ifdef DDR4
	     prev_cas_bg <= '0;
`endif
	  end
	else
	  if(iscas)
	    begin
	       latched_prev_cas_r_w <= prev_cas_r_w;
	       prev_cas_r_w <= cas_rw_lcl;
`ifdef DDR4
	       prev_cas_bg <= cas_bank[$clog2(DRAM_BANKS)-1:
			      $clog2(DRAM_BANKS)-$clog2(DRAM_BG)];
`endif
	    end
     end

   /*************************End of CAS req processing*************************/

   /*****************************PRE REQ processing****************************/
   logic [$clog2(CLK_RATIO)-1:0] acptd_pre_req_slot,pre_slot;
   logic [DRAM_ADDR_WIDTH-1:0] 	 pre_addr;
   logic [$clog2(DRAM_BANKS)-1:0] pre_bank;
   logic [$clog2(DRAM_BANKS)-1:0] pre_grant_lcl;
   logic [DRAM_BANKS-1:0] 	  pre_req_lcl;
   logic 			  ispre_lcl;
   logic 			  ispre,ispre_n;
   logic 			  same_slot_pre_cas;
   logic 			  same_slot_pre_act;
   logic [$clog2(CLK_RATIO):0] 	  cas_slot_plus1, act_slot_plus1;
   logic [DRAM_CMD_WIDTH-1:0] 	  pre_cmd;
   logic [DRAM_BANKS-1:0] 	  bm_prev_cycle_ispre;
   logic [DRAM_ADDR_WIDTH-1:0] 	  act_addr_stg3;
   logic [$clog2(DRAM_BANKS)-1:0] act_bank_stg3;
   logic [DRAM_CMD_WIDTH-1:0] 	  act_cmd_stg3;
   logic [DRAM_ADDR_WIDTH-1:0] 	  cas_addr_stg2;
   logic [$clog2(DRAM_BANKS)-1:0] cas_bank_stg2;
   logic [DRAM_CMD_WIDTH-1:0] 	  cas_cmd_stg2;
   logic 			  cmd_mux_isact_stg3;
   logic [$clog2(DRAM_BANKS)-1:0] cmd_mux_act_grant_stg3;
   logic [$clog2(CLK_RATIO)-1:0]  cmd_mux_act_slot_stg3;
   logic 			  cmd_mux_iscas_stg2;
   logic [$clog2(DRAM_BANKS)-1:0] cmd_mux_cas_grant_stg2;
   logic [$clog2(CLK_RATIO)-1:0]  cmd_mux_cas_slot_stg2;
   logic 			  cmd_mux_iswrite_stg2;
   logic 			  cmd_mux_isread_stg2;
   logic [FE_ID_WIDTH-1:0] 	  cmd_mux_cas_id_stg2;
   logic [$clog2(CLK_RATIO)-1:0]  cmd_mux_pre_slot_stg1;
   logic [DRAM_ADDR_WIDTH-1:0] 	  pre_addr_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] pre_bank_stg1;
   logic [$clog2(DRAM_BANKS)-1:0] cmd_mux_pre_grant_stg1;
   logic 			  cmd_mux_ispre_stg1;
   logic [DRAM_CMD_WIDTH-1:0] 	  pre_cmd_stg1;
   


   assign pre_req_lcl = bm_pre;

    //inhibit the pre req from BM whose PRE req was previously (1 cycle prior) accepted/ack. This ensure that the same request is not processed twice. It is helpful when the BM request are sent to FF and then forworded to cmd_mux.
   genvar l;
   generate
      for(l=0;l<DRAM_BANKS;l++) begin
	 assign bm_prev_cycle_ispre[l]=(cmd_mux_pre_ack && !rm_stall)?
				       (cmd_mux_pre_grant!=l):1'b1;
      end
   endgenerate

   // Priority arbiter send the act req and slot nr from a line with highest
   // priority. It only considers bus with valid act req.

`ifndef FPGA
   priority_arbiter
     #(
       .PRIORITY_WIDTH(PRIORITY_WIDTH),
       .DATA_WIDTH($clog2(CLK_RATIO)),
       .NR_INPUTS(DRAM_BANKS)
       )pre_req_arbiter
       (
	.priority_i(bm_priority),
	.data_i(bm_slot),
	.req(pre_req_lcl & bm_prev_cycle_ispre),
	.highest_priority(not_srvd_earliest_pre),
	.data_o(acptd_pre_req_slot),
	.valid(ispre_lcl),
	.grant(pre_grant_lcl)
	);
`else // !`ifndef FPGA
   priority_encoder_16 // for DDR3 thios has to be _8. Make it configurable 
     #(
       )fixed_priority_arbiter_pre
       (
	.req(pre_req_lcl & bm_prev_cycle_ispre),
	.valid(ispre_lcl),
	.out(pre_grant_lcl)
	);

   mux_1
     #(
       .WIDTH($clog2(CLK_RATIO)),
       .NR_INPUTS(DRAM_BANKS)
       )pre_slot_mux
       (
	.in(bm_slot),
	.sel(pre_grant_lcl),
	.out(acptd_pre_req_slot)
	);
`endif // !`ifndef FPGA



   //send grant signal to BM whose pre req was processed
   mux_1
     #(
       .WIDTH($clog2(DRAM_BANKS)),
       .NR_INPUTS(DRAM_BANKS)
       )pre_bank_mux
       (
	.in(bm_bank),
	.sel(pre_grant_lcl),
	.out(pre_bank)
	);

   assign same_slot_pre_cas = (acptd_pre_req_slot == cmd_mux_cas_slot_stg1) && cmd_mux_iscas_stg1;
   assign same_slot_pre_act = (acptd_pre_req_slot == cmd_mux_act_slot_stg2) && cmd_mux_isact_stg2;
   assign cas_slot_plus1 = cmd_mux_cas_slot_stg1 + 1;
   assign act_slot_plus1 = cmd_mux_act_slot_stg2 + 1;

   always_comb
     begin
	case({same_slot_pre_act,same_slot_pre_cas})
	  2'b00:{ispre_n,pre_slot} = {!pre_req_lcl,acptd_pre_req_slot};
	  2'b01:{ispre_n,pre_slot} = (cas_slot_plus1 == cmd_mux_act_slot_stg2) && 
				     cmd_mux_isact_stg2?
				     act_slot_plus1:cas_slot_plus1;
	  2'b10:{ispre_n,pre_slot} = (act_slot_plus1 == cmd_mux_cas_slot_stg1) && 
				     cmd_mux_iscas_stg1?
				     cas_slot_plus1:act_slot_plus1;
	  2'b11:{ispre_n,pre_slot} = {1'b1,1'b0};
	  // 2'b11 case not valid, logic placed to avoid latch
	endcase // case {same_slot_pre_act,same_slot_pre_cas}
     end // always_comb

   assign ispre = !ispre_n && ispre_lcl;
   assign pre_cmd = (ispre)?PRE:NOP;
   assign pre_addr = 0;
   
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_pre_ack <= '0;
	     cmd_mux_pre_grant <= '0;
	     cmd_mux_pre_slot <= '0;
	     cmd_mux_iswrite_stg2 <= '0;
	     cmd_mux_isread_stg2 <= '0;
	     cmd_mux_isact_stg3 <= '0;
	     cmd_mux_act_grant_stg3 <= '0;
	     cmd_mux_act_slot_stg3 <= '0;
	     cmd_mux_iscas_stg2 <= '0;
	     cmd_mux_cas_grant_stg2 <= '0;
	     cmd_mux_cas_slot_stg2 <= '0;
	     act_addr_stg3 <= '0;
	     act_bank_stg3 <= '0;
	     act_cmd_stg3 <= '0;
	     cas_addr_stg2 <= '0;
	     cas_bank_stg2 <= '0;
	     cas_cmd_stg2 <= '0;
	     cmd_mux_cas_id_stg2 <= '0;
	     cmd_mux_ispre_stg1 <= '0;
	     cmd_mux_pre_grant_stg1 <= '0;
	     cmd_mux_pre_slot_stg1 <= '0;
	     pre_addr_stg1 <= '0;
	     pre_bank_stg1 <= '0;
	     pre_cmd_stg1 <= '0;

	  end
	else
	  begin
	     cmd_mux_pre_ack <= ispre;
	     cmd_mux_pre_grant <= pre_grant_lcl;
	     cmd_mux_pre_slot <= pre_slot;
	     if(!(rm_stall && bm_en)) begin
		act_addr_stg3 <= act_addr_stg2;
		act_bank_stg3 <= act_bank_stg2;
		act_cmd_stg3 <= act_cmd_stg2;
		cas_addr_stg2 <= cas_addr_stg1;
		cas_bank_stg2 <= cas_bank_stg1;
		cas_cmd_stg2 <= cas_cmd_stg1;
		cmd_mux_isact_stg3 <= cmd_mux_isact_stg2;
		cmd_mux_act_grant_stg3 <= cmd_mux_act_grant_stg2;
		cmd_mux_act_slot_stg3 <= cmd_mux_act_slot_stg2;
		cmd_mux_iscas_stg2 <= cmd_mux_iscas_stg1;
		cmd_mux_cas_grant_stg2 <= cmd_mux_cas_grant_stg1;
		cmd_mux_cas_slot_stg2 <= cmd_mux_cas_slot_stg1;
		cmd_mux_iswrite_stg2 <= cmd_mux_iswrite_stg1;
		cmd_mux_isread_stg2 <= cmd_mux_isread_stg1;
		cmd_mux_cas_id_stg2 <= cmd_mux_cas_id_stg1;
		pre_addr_stg1 <= pre_addr;
		pre_bank_stg1 <= pre_bank;
		pre_cmd_stg1 <= pre_cmd;
	       	cmd_mux_ispre_stg1 <= ispre;
		cmd_mux_pre_grant_stg1 <= pre_grant_lcl;
		cmd_mux_pre_slot_stg1 <= pre_slot;
	     end
	  end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)


   /*************************End of PRE req processing*************************/


   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 cmd_mux_addr_lcl;
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 cmd_mux_addr_bus_shuffler_o;
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	 cmd_mux_addr_q;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] cmd_mux_bank_lcl;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 cmd_mux_cmd_lcl;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 cmd_mux_cmd_q;
   logic [CLK_RATIO-1:0] 			 cmd_mux_valid_lcl;
   logic [FE_ID_WIDTH-1:0] 			 cmd_mux_fe_id_lcl;
   logic 					 cmd_mux_fe_id_valid_lcl;
   logic [$clog2(CLK_RATIO)-1:0] 		 cmd_mux_cas_slot_q;
				  
`ifdef DDR4
   logic [CLK_RATIO-1:0] 			 cmd_mux_act_n_lcl;
   logic [CLK_RATIO-1:0] 			 cmd_mux_act_n_q;

   demux_1_4
     #(
       .WIDTH (1),
       .INVERTED_OUTPUT(1)
       )demux_inst_act_n
       (
	.in (cmd_mux_isact_stg3),
	.sel (cmd_mux_act_slot_stg3),
	.out (cmd_mux_act_n_lcl)
	);
`endif //  `ifdef DDR4
       
   bus_shuffler_4
     #(
       .BUS_SIZE(DRAM_ADDR_WIDTH+$clog2(DRAM_BANKS)+DRAM_CMD_WIDTH)
       )bus_shuffler
       (
	//inputs
	.bus_i({{{DRAM_ADDR_WIDTH{1'b0}},{$clog2(DRAM_BANKS){1'b0}},NOP},
		{pre_addr_stg1,pre_bank_stg1,pre_cmd_stg1},
		{cas_addr_stg2,cas_bank_stg2,cas_cmd_stg2},
		{act_addr_stg3,act_bank_stg3,act_cmd_stg3}}),
	.req_slot({1'b0,cmd_mux_ispre_stg1,cmd_mux_iscas_stg2,cmd_mux_isact_stg3}),
	.req_slot_nr({2'b0,cmd_mux_pre_slot_stg1,cmd_mux_cas_slot_stg2,cmd_mux_act_slot_stg3}),
	//ouputs
	.bus_o({{cmd_mux_addr_bus_shuffler_o[3],cmd_mux_bank_lcl[3],cmd_mux_cmd_lcl[3]},
		{cmd_mux_addr_bus_shuffler_o[2],cmd_mux_bank_lcl[2],cmd_mux_cmd_lcl[2]},
		{cmd_mux_addr_bus_shuffler_o[1],cmd_mux_bank_lcl[1],cmd_mux_cmd_lcl[1]},
		{cmd_mux_addr_bus_shuffler_o[0],cmd_mux_bank_lcl[0],cmd_mux_cmd_lcl[0]}}),
	.bus_valid_o(cmd_mux_valid)
	);

   always_comb
     begin
	cmd_mux_addr_lcl = cmd_mux_addr_bus_shuffler_o;
`ifdef DDR4
	if(!(cmd_mux_valid[0]&&(cmd_mux_cmd_lcl[0]==ACT)))
	  cmd_mux_addr_lcl[0][16:14] = cmd_mux_valid[0]?cmd_mux_cmd_lcl[0]:NOP;
	if(!(cmd_mux_valid[1]&&(cmd_mux_cmd_lcl[1]==ACT)))
	  cmd_mux_addr_lcl[1][16:14] = cmd_mux_valid[1]?cmd_mux_cmd_lcl[1]:NOP;
	if(!(cmd_mux_valid[2]&&(cmd_mux_cmd_lcl[2]==ACT)))
	  cmd_mux_addr_lcl[2][16:14] = cmd_mux_valid[2]?cmd_mux_cmd_lcl[2]:NOP;
	if(!(cmd_mux_valid[3]&&(cmd_mux_cmd_lcl[3]==ACT)))
	  cmd_mux_addr_lcl[3][16:14] = cmd_mux_valid[3]?cmd_mux_cmd_lcl[3]:NOP;
`endif
     end // always_comb

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_addr_q <= '0;
	     cmd_mux_bank <= '0;
	     cmd_mux_fe_id <= '0;
	     cmd_mux_cmd_q <= {NOP,NOP,NOP,NOP};
	     cmd_mux_write_q <= '0;
	     cmd_mux_read_q <= '0;
	     cmd_mux_cas_slot_q <= '0;
	  end
	else
	  begin
	     cmd_mux_fe_id <= cmd_mux_cas_id_stg2;
	     cmd_mux_addr_q <= cmd_mux_addr_lcl;
	     cmd_mux_bank <= cmd_mux_bank_lcl;
	     cmd_mux_cmd_q[0] <= cmd_mux_valid[0]?cmd_mux_cmd_lcl[0]:NOP;
	     cmd_mux_cmd_q[1] <= cmd_mux_valid[1]?cmd_mux_cmd_lcl[1]:NOP;
	     cmd_mux_cmd_q[2] <= cmd_mux_valid[2]?cmd_mux_cmd_lcl[2]:NOP;
	     cmd_mux_cmd_q[3] <= cmd_mux_valid[3]?cmd_mux_cmd_lcl[3]:NOP;
	     cmd_mux_write_q <= cmd_mux_iswrite_stg2;
	     cmd_mux_read_q <= cmd_mux_isread_stg2;
	     cmd_mux_cas_slot_q <= cmd_mux_cas_slot_stg2;
	  end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)

   assign cmd_mux_cmd[0] = !rm_stall?cmd_mux_cmd_q[0]:NOP;
   assign cmd_mux_cmd[1] = !rm_stall?cmd_mux_cmd_q[1]:NOP;
   assign cmd_mux_cmd[2] = !rm_stall?cmd_mux_cmd_q[2]:NOP;
   assign cmd_mux_cmd[3] = !rm_stall?cmd_mux_cmd_q[3]:NOP;
   assign cmd_mux_write = !rm_stall?cmd_mux_write_q:0;
   assign cmd_mux_read = !rm_stall?cmd_mux_read_q:0;
   assign cmd_mux_cas_slot_stg3 = !rm_stall?cmd_mux_cas_slot_q:0;
   assign cmd_mux_fe_id_valid = '0;

   integer j;
   always_comb
     begin
	cmd_mux_addr = cmd_mux_addr_q;
`ifdef DDR4
	for(j=0;j<CLK_RATIO;j=j+1) begin
	   cmd_mux_addr[j][16:14] = !rm_stall?cmd_mux_addr_q[j][16:14]:3'b111; //else NOP
	end
`endif
     end
  
`ifdef DDR4
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     cmd_mux_act_n_q <= '0;
	  end
	else
	  begin
	     cmd_mux_act_n_q <= cmd_mux_act_n_lcl;
	  end
     end // always_ff @ (posedge clk, negedge rst_n)

   assign cmd_mux_act_n = !rm_stall?cmd_mux_act_n_q:'1;
   
`endif //  `ifdef DDR4

endmodule // cmd_mux


