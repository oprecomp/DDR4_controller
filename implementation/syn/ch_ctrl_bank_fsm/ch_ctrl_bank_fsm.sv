module ch_ctrl_bank_fsm
  #(
    parameter BANK_FIFO_DEPTH = 8,
    parameter ROW_ADDR_WIDTH = 16,
    parameter COL_ADDR_WIDTH = 11,
    parameter DRAM_ADDR_WIDTH = 16,
    parameter DRAM_CMD_WIDTH = 5,
    parameter FE_CMD_WIDTH = 1,
    parameter FE_WRITE = 0,
    parameter FE_ID_WIDTH = 6,
    parameter CLK_RATIO = 4,
    parameter PRIORITY_WIDTH = 6,
    parameter BANK_ID = 0,
    parameter DRAM_BANKS = 8,

    //Register width considering worstcase timings
    parameter RAS_DRAM_CYCLES_LOG2 = 8,
    parameter RP_DRAM_CYCLES_LOG2 = 8,
    parameter WR2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RD2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RCD_DRAM_CYCLES_LOG2 = 8,
    /*parameter RRD_RG_REF_DRAM_CYCLES_LOG2 = 4,
    parameter RAS_RG_REF_DRAM_CYCLES_LOG2 = 6,
    parameter RP_RG_REF_DRAM_CYCLES_LOG2 = 4,*/
    parameter RG_REF_NUM_ROW_PER_REF_LOG2 = 5,
    parameter CWL_LOG2 = 4,
    parameter BL_LOG2 = 4,

    //DEFAULTS
    parameter RG_REF_NUM_ROW_PER_REF = 4
    /*parameter WTR_DRAM_CYCLES = 4,
     parameter CCD_DRAM_CYCLES = 4,
     parameter RP_DRAM_CYCLES = 6,
     parameter RTP_DRAM_CYCLES = 4,
     parameter WR_DRAM_CYCLES = 6,
     parameter RCD_DRAM_CYCLES = 6,
     parameter RAS_DRAM_CYCLES = 15,
     parameter CL = 6,
     parameter CWL = 5,
     parameter TFAW_NS = 40,
     parameter BL = 8*/
    )
   (
    input 				    clk,
    input 				    rst_n,

    // Address Decoder to BM
    input 				    ad_req,
    input [ROW_ADDR_WIDTH-1:0] 		    ad_row,
    input [COL_ADDR_WIDTH-1:0] 		    ad_col,
    input [$clog2(DRAM_BANKS)-1:0] 	    ad_bank,
    input [FE_CMD_WIDTH-1:0] 		    ad_cmd,
    input [PRIORITY_WIDTH-1:0] 		    ad_priority,
    input [FE_ID_WIDTH-1:0] 		    ad_id,

    //BM to Address Decoder
    output logic 			    bm_ack,

    // Rank machine to BM
    input 				    rm_pre_all,
    input [$clog2(CLK_RATIO)-1:0] 	    rm_pre_all_slot,
    input 				    rm_stall,
    input 				    bm_en,

    //row granular ref
    //dram_rg_ref_if.wp rg_ref,
    input 				    rg_req,
    output 				    rg_done,
    input [DRAM_ADDR_WIDTH-1:0] 	    rg_ref_start_addr,
    input [DRAM_ADDR_WIDTH-1:0] 	    rg_ref_end_addr,
    input [RG_REF_NUM_ROW_PER_REF_LOG2-1:0] rg_ref_num_row_per_ref,
    input [RAS_DRAM_CYCLES_LOG2-1:0] 	    rg_ref_ras_dram_clk_cycle,
    input [RP_DRAM_CYCLES_LOG2-1:0] 	    rg_ref_rp_dram_clk_cycle,

    //BM to RM
    output logic 			    bm_idle,
    output logic 			    bm_prechared,

    // BM to Cmd_mux
    output logic [DRAM_ADDR_WIDTH-1:0] 	    bm_addr,
    output logic [$clog2(CLK_RATIO)-1:0]    bm_slot,
    output logic [PRIORITY_WIDTH-1:0] 	    bm_priority,
    output logic [FE_ID_WIDTH-1:0] 	    bm_id,
    output logic 			    bm_act,
    output logic 			    bm_cas,
    output logic 			    bm_r_w, // 1 = read, 0 = write
    output logic 			    bm_pre,
    output [$clog2(DRAM_BANKS)-1:0] 	    bm_bank,
    //output [PRIORITY_WIDTH-1:0] 	 not_srvd_earliest_act,
    //output [PRIORITY_WIDTH-1:0] 	 not_srvd_earliest_pre,

    // cmd_mux to BM
    input 				    cmd_mux_act_ack,
    input [$clog2(DRAM_BANKS)-1:0] 	    cmd_mux_act_grant,
    input [$clog2(CLK_RATIO)-1:0] 	    cmd_mux_act_slot,
    input 				    cmd_mux_cas_ack,
    input [$clog2(DRAM_BANKS)-1:0] 	    cmd_mux_cas_grant,
    input [$clog2(CLK_RATIO)-1:0] 	    cmd_mux_cas_slot,
    input 				    cmd_mux_pre_ack,
    input [$clog2(DRAM_BANKS)-1:0] 	    cmd_mux_pre_grant,
    input [$clog2(CLK_RATIO)-1:0] 	    cmd_mux_pre_slot,

    //DRAM timing
    logic [CWL_LOG2-1:0] 		    CWL,
    logic [BL_LOG2-1:0] 		    BL,
					    dram_bank_timing_if.wp dram_t_bm
    );

   localparam NOP = 5'b10111;
   localparam ACT = 5'b10011;
   localparam PRE = 5'b10010;
   localparam WR = 5'b10100;
   localparam RD = 5'b10101;
   localparam BUFFER_WIDTH = FE_ID_WIDTH + PRIORITY_WIDTH+ ROW_ADDR_WIDTH +
			     COL_ADDR_WIDTH + FE_CMD_WIDTH + 1;

   /*******************************Row Miss logic******************************/
   logic [ROW_ADDR_WIDTH-1:0] 		 prev_req_row_addr;
   logic 				 prev_req_row_addr_v;
   wire 				 row_miss;
   wire 				 fifo_empty;
   logic 				 bank_fifo_full_n;
   logic 				 bm_dis_interrupted_cas_q;
   logic 				 bm_dis_interrupted_cas_lcl;

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0) begin
	   prev_req_row_addr <= 0;
	   prev_req_row_addr_v <= 1'b0;
	end
	else begin
	   if(ad_req && (ad_bank == BANK_ID) && bank_fifo_full_n)
	     begin
		prev_req_row_addr_v <= 1'b1;
		prev_req_row_addr <= ad_row;
	     end
	   else if(rm_pre_all && fifo_empty && bm_dis_interrupted_cas_q)
	     prev_req_row_addr_v <= 1'b0;
	end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)

   assign row_miss = ad_req && (ad_bank == BANK_ID) &&
		     (prev_req_row_addr != ad_row) &&
		     prev_req_row_addr_v;


   /*************************End of Row miss logic*****************************/

   /*******************************Bank Buffer*********************************/
   // This block checks whether the command is for this specific bank machine
   // and acknowledges the address decode fsm
   logic latch_data;
   logic ack_ns;
   logic fifo_empty_n;
   logic fifo_next_cmd;
   logic bank_fifo_apre_out;
   logic [BUFFER_WIDTH-1:0] bank_fifo_out;

   always_comb
     begin
	if( ad_req && (ad_bank == BANK_ID) && bank_fifo_full_n ) begin
	   latch_data   = 1'b1;
	   ack_ns       = 1'b1;
	end
	else
	  begin
	     latch_data = 1'b0;
	     ack_ns     = 1'b0;
	  end
     end

   assign bm_ack = bank_fifo_full_n;

   /*always_ff@(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  bm_ack  <= 1'b0;
	else
	  bm_ack  <= bank_fifo_full_n;
     end*/

   //  BANK FIFO --- Stores the requests to the bank (Row, Column & Command)
   // FIXME: Later versions need dual clk fifo
`ifndef FPGA
   
   generic_fifo #(
		  .DATA_WIDTH(BUFFER_WIDTH),
		  .DATA_DEPTH(BANK_FIFO_DEPTH)
		  )
   bank_fifo (
	      .clk(clk),
	      .rst_n(rst_n),
	      .data_i({ad_id,ad_priority,ad_row,ad_col,ad_cmd,row_miss}),
	      .valid_i(latch_data),
	      .grant_o(bank_fifo_full_n),
	      .data_o(bank_fifo_out),
	      .valid_o(fifo_empty_n),
	      .grant_i(fifo_next_cmd),
	      .test_mode_i(1'b0)
	      );
`else // !`ifndef FPG
   
   bram_fifo_52x4 #(
		    // do not override the parameters
		    )
   bank_fifo (
	      .clk(clk),
	      .rst_n(rst_n),
	      .data_i({ad_id,ad_priority,ad_row,ad_col,ad_cmd,row_miss}),
	      .valid_i(latch_data),
	      .grant_o(bank_fifo_full_n),
	      .data_o(bank_fifo_out),
	      .valid_o(fifo_empty_n),
	      .grant_i(fifo_next_cmd),
	      .test_mode_i(1'b0)
	      );
`endif

   assign fifo_empty = ~fifo_empty_n;

   // FIXME: Add apre fifo for auto-precharging in case of row miss
   assign bank_fifo_apre_out = 0;

   /****************************End of Bank Buffer*****************************/

   /***************************Timers and Checkers*****************************/

   //ACT to PRE check
   // Could combine act2pre, wr2pre, rd2pre.
   logic [(RAS_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] act2pre_check;
   logic 						  safe_act2pre;
   logic [$clog2(CLK_RATIO)-1:0] 			  act2pre_slot;
   logic [$clog2(CLK_RATIO):0] 				  nxt_act2pre_slot;
   logic 							  nxt_act2pre_slot_ovf;
   wire 							  ack_act_lcl;
   logic [(RAS_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	  RAS_CTRL_CYCLES;
   logic [RAS_DRAM_CYCLES_LOG2-1:0] 				  RAS_DRAM_CYCLES_lcl;
   logic [$clog2(CLK_RATIO)-1:0] 				  RAS_CTRL_SLOT;

   assign RAS_DRAM_CYCLES_lcl = rg_req?rg_ref_ras_dram_clk_cycle:
				dram_t_bm.RAS_DRAM_CYCLES;
   assign RAS_CTRL_CYCLES = RAS_DRAM_CYCLES_lcl >> $clog2(CLK_RATIO);
   assign RAS_CTRL_SLOT = RAS_DRAM_CYCLES_lcl - (RAS_CTRL_CYCLES <<
						 $clog2(CLK_RATIO));

   //considering cmd_mux_act_slot instead of act_slot, if in case cmd_mux shifts
   // requested slot. since ack is received only next clk, so -2
   assign nxt_act2pre_slot = cmd_mux_act_slot + RAS_CTRL_SLOT;
   assign nxt_act2pre_slot_ovf = nxt_act2pre_slot > (CLK_RATIO-1);

   always_ff @(posedge clk, negedge rst_n)
     begin:act2pre
	if(rst_n == 1'b0)
	  begin
	     act2pre_check <= 0;
	     act2pre_slot <= 0;
	  end
	else
	  begin
	     if(ack_act_lcl)
	       begin
		  act2pre_check <= ((RAS_CTRL_CYCLES>2)?(RAS_CTRL_CYCLES-2):0)+
				   (nxt_act2pre_slot_ovf?1:0);//-2
		  act2pre_slot <= nxt_act2pre_slot_ovf ?
				  (nxt_act2pre_slot - CLK_RATIO):nxt_act2pre_slot;
	       end
	     else
	       begin
		  if(act2pre_check != 0)
		    act2pre_check <= act2pre_check - 1'b1;
		  else
		    act2pre_slot <= 1'b0;
		  // slot is applicable only for the clk at which check signal
		  // makes a transition to 0. From later clks slot could be == 0
	       end // else: !if(isact == 1'b1)
	  end // else: !if(rst_n == 1'b0)
     end // block: act2pre

   assign safe_act2pre = (act2pre_check == 0) && !ack_act_lcl;
   // safe_act2pre goes low 1 clk later without ack_act_lcl.
   // It has to be pulled down along with ack_act_lcl

   //PRE to ACT check
   logic [(RP_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] pre2act_check;
   logic 						 safe_pre2act;
   logic [$clog2(CLK_RATIO)-1:0] 			 pre2act_slot;
   logic [$clog2(CLK_RATIO)-1:0] 			 pre_slot;
   logic [$clog2(CLK_RATIO):0] 				 nxt_pre2act_slot;
   logic 							 nxt_pre2act_slot_ovf;
   logic 							 ispre;
   logic [(RP_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	 RP_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				 RP_CTRL_SLOT;

   assign RP_CTRL_CYCLES = dram_t_bm.RP_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign RP_CTRL_SLOT = dram_t_bm.RP_DRAM_CYCLES - (RP_CTRL_CYCLES <<
						     $clog2(CLK_RATIO));

   assign nxt_pre2act_slot = pre_slot + RP_CTRL_SLOT;
   assign nxt_pre2act_slot_ovf = nxt_pre2act_slot > (CLK_RATIO-1);

   always_ff @(posedge clk, negedge rst_n)
     begin:pre2act
	if(rst_n == 1'b0)
	  begin
	     pre2act_check <= 0;
	     pre2act_slot <= 0;
	  end
	else
	  begin
	     if(ispre == 1'b1)
	       begin
		  pre2act_check <= ((RP_CTRL_CYCLES>1)?(RP_CTRL_CYCLES-1):0)+
				   (nxt_pre2act_slot_ovf?1:0);
		  pre2act_slot <= nxt_pre2act_slot_ovf ?
				  (nxt_pre2act_slot - CLK_RATIO):nxt_pre2act_slot;
	       end
	     else
	       begin
		  if(pre2act_check != 0)
		    pre2act_check <= pre2act_check - 1'b1;
		  else
		    pre2act_slot <= 1'b0;
		  // slot is applicable only for the clk at which check signal
		  // makes a transition to 0. From later clks slot could be == 0
	       end // else: !if(isact == 1'b1)
	  end // else: !if(rst_n == 1'b0)
     end // block: pre2act

   assign safe_pre2act = (pre2act_check == 0);

   //WR to PRE check
   logic [(WR2PRE_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] wr2pre_check;
   logic 						     safe_wr2pre;
   logic [$clog2(CLK_RATIO)-1:0] 			     wr2pre_slot;
   logic [$clog2(CLK_RATIO)-1:0] 			     write_slot;
   logic [$clog2(CLK_RATIO):0] 				     nxt_wr2pre_slot;
   logic 							     nxt_wr2pre_slot_ovf;
   logic 							     iswrite;
   logic [WR2PRE_DRAM_CYCLES_LOG2 - 1:0] 			     WR2PRE_DRAM_CYCLES;
   logic [(WR2PRE_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	     WR2PRE_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				     WR2PRE_CTRL_SLOT;

   assign WR2PRE_DRAM_CYCLES = dram_t_bm.WR_DRAM_CYCLES + CWL + (BL/2);
   assign WR2PRE_CTRL_CYCLES = WR2PRE_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign WR2PRE_CTRL_SLOT = WR2PRE_DRAM_CYCLES - (WR2PRE_CTRL_CYCLES <<
						   $clog2(CLK_RATIO));

   assign nxt_wr2pre_slot = write_slot + WR2PRE_CTRL_SLOT;
   assign nxt_wr2pre_slot_ovf = nxt_wr2pre_slot > (CLK_RATIO-1);

   always_ff @(posedge clk, negedge rst_n)
     begin:wr2pre
	if(rst_n == 1'b0)
	  begin
	     wr2pre_check <= 0;
	     wr2pre_slot <= 0;
	  end
	else
	  begin
	     if(iswrite == 1'b1)
	       begin
		  wr2pre_check <= ((WR2PRE_CTRL_CYCLES>1)?(WR2PRE_CTRL_CYCLES-1)
				   :0)+(nxt_wr2pre_slot_ovf?1:0);
		  wr2pre_slot <= nxt_wr2pre_slot_ovf ?
				 (nxt_wr2pre_slot - CLK_RATIO):nxt_wr2pre_slot;
	       end
	     else
	       begin
		  if(wr2pre_check != 0)
		    wr2pre_check <= wr2pre_check - 1'b1;
		  else
		    wr2pre_slot <= 1'b0;
		  // slot is applicable only for the clk at which check signal
		  // makes a transition to 0. From later clks slot could be == 0
	       end // else: !if(isact == 1'b1)
	  end // else: !if(rst_n == 1'b0)
     end // block: wr2pre

   assign safe_wr2pre = (wr2pre_check == 0);

   //RD to PRE check
   logic [(RD2PRE_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] rd2pre_check;
   logic 						     safe_rd2pre;
   logic [$clog2(CLK_RATIO)-1:0] 			     rd2pre_slot;
   logic [$clog2(CLK_RATIO)-1:0] 			     read_slot;
   logic [$clog2(CLK_RATIO):0] 				     nxt_rd2pre_slot;
   logic 							     nxt_rd2pre_slot_ovf;
   logic 							     isread;
   logic [(RD2PRE_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	     RD2PRE_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				     RD2PRE_CTRL_SLOT;

   assign RD2PRE_CTRL_CYCLES = dram_t_bm.RTP_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign RD2PRE_CTRL_SLOT = dram_t_bm.RTP_DRAM_CYCLES - (RD2PRE_CTRL_CYCLES <<
							  $clog2(CLK_RATIO));

   assign nxt_rd2pre_slot = read_slot + RD2PRE_CTRL_SLOT;
   assign nxt_rd2pre_slot_ovf = nxt_rd2pre_slot > (CLK_RATIO-1);

   always_ff @(posedge clk, negedge rst_n)
     begin:rd2pre
	if(rst_n == 1'b0)
	  begin
	     rd2pre_check <= 0;
	     rd2pre_slot <= 0;
	  end
	else
	  begin
	     if(isread == 1'b1)
	       begin
		  rd2pre_check <= ((RD2PRE_CTRL_CYCLES>1)?(RD2PRE_CTRL_CYCLES-1)
				   :0)+(nxt_rd2pre_slot_ovf?1:0);
		  rd2pre_slot <= nxt_rd2pre_slot_ovf ?
				 (nxt_rd2pre_slot - CLK_RATIO):nxt_rd2pre_slot;
	       end
	     else
	       begin
		  if(rd2pre_check != 0)
		    rd2pre_check <= rd2pre_check - 1'b1;
		  else
		    rd2pre_slot <= 1'b0;
		  // slot is applicable only for the clk at which check signal
		  // makes a transition to 0. From later clks slot could be == 0
	       end // else: !if(isact == 1'b1)
	  end // else: !if(rst_n == 1'b0)
     end // block: wr2pre

   assign safe_rd2pre = (rd2pre_check == 0);

   //ACT to CAS check
   logic [(RCD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] act2cas_check;
   logic 						  safe_act2cas;
   logic [$clog2(CLK_RATIO)-1:0] 			  act2cas_slot;
   logic [$clog2(CLK_RATIO)-1:0] 			  act_slot;
   logic [$clog2(CLK_RATIO):0] 				  nxt_act2cas_slot;
   logic 							  nxt_act2cas_slot_ovf;
   logic 							  isact;
   logic [(RCD_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] 	   RCD_CTRL_CYCLES;
   logic [$clog2(CLK_RATIO)-1:0] 				   RCD_CTRL_SLOT;

   assign RCD_CTRL_CYCLES = dram_t_bm.RCD_DRAM_CYCLES >> $clog2(CLK_RATIO);
   assign RCD_CTRL_SLOT = dram_t_bm.RCD_DRAM_CYCLES - (RCD_CTRL_CYCLES <<
						       $clog2(CLK_RATIO));

   assign nxt_act2cas_slot = act_slot + RCD_CTRL_SLOT;
   assign nxt_act2cas_slot_ovf = nxt_act2cas_slot > (CLK_RATIO-1);

   always_ff @(posedge clk, negedge rst_n)
     begin:act2cas
	if(rst_n == 1'b0)
	  begin
	     act2cas_check <= 0;
	     act2cas_slot <= 0;
	  end
	else
	  begin
	     if(isact == 1'b1)
	       begin
		  act2cas_check <= ((RCD_CTRL_CYCLES>1)?(RCD_CTRL_CYCLES-1):0)+
				   (nxt_act2cas_slot_ovf?1:0);
		  act2cas_slot <= nxt_act2cas_slot_ovf ?
				  (nxt_act2cas_slot - CLK_RATIO):nxt_act2cas_slot;
	       end
	     else
	       begin
		  if(act2cas_check != 0)
		    act2cas_check <= act2cas_check - 1'b1;
		  else
		    act2cas_slot <= 1'b0;
		  // slot is applicable only for the clk at which check signal
		  // makes a transition to 0. From later clks slot could be == 0
	       end // else: !if(isact == 1'b1)
	  end // else: !if(rst_n == 1'b0)
     end // block: act2cas

   assign safe_act2cas = (act2cas_check == 0);

   /************************END of Timers and Checkers*************************/

   /*********************Row Granular Refresh counters*************************/
   // counters to keep track of number of ACTs and PREs per REF
   logic [RG_REF_NUM_ROW_PER_REF_LOG2-1:0] rg_act_cnts_CS,rg_act_cnts_NS;
   logic [RG_REF_NUM_ROW_PER_REF_LOG2-1:0] rg_pre_cnts_CS,rg_pre_cnts_NS;
   logic [DRAM_ADDR_WIDTH-1:0] rg_ref_row_cntr_CS,rg_ref_row_cntr_NS;
   logic 		       rg_ref_act_ack, rg_ref_pre_ack;
   logic 		       first_rg_ref_q_n;
   logic 		       rg_done_n;
   wire 		       ack_cas_lcl;
   wire 		       ack_pre_lcl;

   assign rg_ref_act_ack = ack_act_lcl && rg_req;
   assign rg_ref_pre_ack = ack_pre_lcl && rg_req;
   assign rg_act_cnts_NS = rg_act_cnts_CS - rg_ref_act_ack;
   assign rg_pre_cnts_NS = rg_pre_cnts_CS - rg_ref_pre_ack;
   assign rg_done_n = ((rg_pre_cnts_NS!=0)&&rg_req);
   assign rg_done = !rg_done_n;
   assign rg_ref_row_cntr_NS = first_rg_ref_q_n?rg_ref_start_addr:
			       (rg_ref_row_cntr_CS!=(rg_ref_end_addr-1))?
			       (rg_ref_row_cntr_CS + rg_ref_act_ack):
			       rg_ref_act_ack?rg_ref_start_addr:rg_ref_row_cntr_CS;

   always_ff @(posedge clk, negedge rst_n) begin
      if(rst_n == 1'b0) begin
	 rg_act_cnts_CS <= RG_REF_NUM_ROW_PER_REF;
	 rg_pre_cnts_CS <= RG_REF_NUM_ROW_PER_REF;
	 rg_ref_row_cntr_CS <= '0;
	 first_rg_ref_q_n <= 1;
      end
      else begin
	rg_ref_row_cntr_CS <= rg_ref_row_cntr_NS;
	if(rg_req == 1'b1) begin
	   rg_act_cnts_CS <= rg_act_cnts_NS;
	   rg_pre_cnts_CS <= rg_pre_cnts_NS;
	   first_rg_ref_q_n <= 0;
	end
	else begin // don't update during ref
	   rg_act_cnts_CS <= rg_ref_num_row_per_ref;
	   rg_pre_cnts_CS <= rg_ref_num_row_per_ref;
	end
      end
   end // always_ff @ (posedge clk, negedge rst_n)


   /*******************END Row Granular Refresh counters***********************/

   /**************************** FSM ******************************************/

   typedef enum logic [0:0] {
			     BANK_ST_IDLE_PRE,
			     BANK_ST_ROW_ACTIVE
			     } BM_FSM;
   BM_FSM CS,NS;
   logic [PRIORITY_WIDTH-1:0] priority_lcl;
   logic [ROW_ADDR_WIDTH-1:0] row_lcl;
   logic [COL_ADDR_WIDTH-1:0] col_lcl;
   logic [FE_CMD_WIDTH-1:0]   cmd_lcl;
   logic [PRIORITY_WIDTH-1:0] latch_priority_lcl;
   logic [ROW_ADDR_WIDTH-1:0] latch_row_lcl;
   logic [COL_ADDR_WIDTH-1:0] latch_col_lcl;
   logic [FE_CMD_WIDTH-1:0]   latch_cmd_lcl;
   logic [PRIORITY_WIDTH-1:0] latch_priority_q;
   logic [ROW_ADDR_WIDTH-1:0] latch_row_q;
   logic [COL_ADDR_WIDTH-1:0] latch_col_q;
   logic [FE_CMD_WIDTH-1:0]   latch_cmd_q;
   logic 		      row_miss_lcl;
   logic [DRAM_CMD_WIDTH-1:0] bm_cmd; // FIXME: remove not required
   logic 		      bank_active_q;
   logic 		      bank_active_lcl;
   logic 		      bm_sent_pre_n_q;
   logic 		      bm_sent_pre_n_lcl;
   logic 		      bm_sent_apre_q;
   logic 		      bm_sent_apre_lcl;
   logic 		      bm_sent_cas_q;
   logic 		      bm_sent_cas_lcl;
   logic 		      bm_atmpt_pre_q;
   logic 		      bm_atmpt_pre_lcl;
   logic [$clog2(CLK_RATIO)-1:0] bm_slot_q;
   logic [$clog2(CLK_RATIO)-1:0] req_grant_slot_diff_lcl;
   logic [$clog2(CLK_RATIO)-1:0] req_grant_slot_diff_q;
   logic 			 bm_prechared_q;
   logic [FE_ID_WIDTH-1:0] 	 id_lcl;
   logic [FE_ID_WIDTH-1:0] 	 latched_id_q;
   logic [FE_ID_WIDTH-1:0] 	 latched_id_lcl;
   wire 			 bm_first_cas_aftr_act;
   wire [$clog2(CLK_RATIO)-1:0]  wr2pre_rd2pre_max_slot;
   wire [$clog2(CLK_RATIO)-1:0]  pre_max_slot;

   // Assign Bank FIFO output
   assign id_lcl = bm_dis_interrupted_cas_q?latched_id_q:
		   bank_fifo_out[FE_ID_WIDTH + PRIORITY_WIDTH + ROW_ADDR_WIDTH +
				 COL_ADDR_WIDTH + FE_CMD_WIDTH:
				 PRIORITY_WIDTH + ROW_ADDR_WIDTH +
				 COL_ADDR_WIDTH + FE_CMD_WIDTH+1];
   assign priority_lcl = rg_req?BANK_ID:bm_dis_interrupted_cas_q?latch_priority_q:
			 bank_fifo_out[PRIORITY_WIDTH + ROW_ADDR_WIDTH +
				       COL_ADDR_WIDTH + FE_CMD_WIDTH:
				       ROW_ADDR_WIDTH + COL_ADDR_WIDTH +
				       FE_CMD_WIDTH+1];
   assign row_lcl = rg_req?rg_ref_row_cntr_CS:bm_dis_interrupted_cas_q?latch_row_q:
		    bank_fifo_out[ROW_ADDR_WIDTH+COL_ADDR_WIDTH+FE_CMD_WIDTH:
				  COL_ADDR_WIDTH+FE_CMD_WIDTH+1];
   assign col_lcl = bm_dis_interrupted_cas_q?latch_col_q:
		    bank_fifo_out[COL_ADDR_WIDTH+FE_CMD_WIDTH:FE_CMD_WIDTH+1];
   assign cmd_lcl = bm_dis_interrupted_cas_q?latch_cmd_q:
		    bank_fifo_out[FE_CMD_WIDTH:1];
   assign row_miss_lcl = bank_fifo_out[0]; // FIXME: valid

   assign ack_cas_lcl = cmd_mux_cas_ack && (cmd_mux_cas_grant == BANK_ID);
   assign ack_act_lcl = cmd_mux_act_ack && (cmd_mux_act_grant == BANK_ID);
   assign ack_pre_lcl = cmd_mux_pre_ack && (cmd_mux_pre_grant == BANK_ID);
   assign wr2pre_rd2pre_max_slot = (wr2pre_slot > rd2pre_slot)? wr2pre_slot :
				   rd2pre_slot;
   assign pre_max_slot = (wr2pre_rd2pre_max_slot > act2pre_slot) ?
			 wr2pre_rd2pre_max_slot : act2pre_slot;
   assign bm_first_cas_aftr_act = !(bm_sent_cas_q || ack_cas_lcl) || rg_done_n;
   // ack_cas_lcl is not needed. During row granilar ref, bm_first_cas has to be
   // high to enter the loop and send pre

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     //check if all need init value
	     CS <= BANK_ST_IDLE_PRE;
	     bank_active_q <= 1'b0;
	     bm_sent_pre_n_q <= 1'b1;
	     bm_sent_apre_q <= '0; // :D :D i wonder y i use '0 instead of 0
	     bm_sent_cas_q <= '0;
	     bm_slot_q <= '0;
	     req_grant_slot_diff_q <= '0;
	     latch_row_q <= '0;
	     latch_col_q <= '0;
	     latch_cmd_q <= '0;
	     latch_priority_q <= '0;
	     bm_dis_interrupted_cas_q <= '0;
	     bm_atmpt_pre_q <= '0;
	     latched_id_q <= '0;
	     bm_prechared_q <= '0;
	  end
	else
	  begin
	     CS<= NS;
	     bank_active_q <= bank_active_lcl;
	     bm_sent_pre_n_q <= bm_sent_pre_n_lcl;
	     bm_sent_apre_q <= bm_sent_apre_lcl;
	     bm_sent_cas_q <= bm_sent_cas_lcl;
	     bm_slot_q <= bm_slot;
	     req_grant_slot_diff_q <= req_grant_slot_diff_lcl;
	     latch_row_q <= latch_row_lcl;
	     latch_col_q <= latch_col_lcl;
	     latch_cmd_q <= latch_cmd_lcl;
	     latch_priority_q <= latch_priority_lcl;
	     bm_dis_interrupted_cas_q <= bm_dis_interrupted_cas_lcl;
	     bm_atmpt_pre_q <= bm_atmpt_pre_lcl;
	     latched_id_q <= latched_id_lcl;
	     bm_prechared_q <= bm_prechared;
	  end
     end // always_ff @ (posedge clk, negedge rst_n)

   // This is the first version of BM optimized for 4 slot window and
   // slower controller clock.
   // A typical BM FSM can't be used since the controller clk is slow.
   // TODO: logic could be optimized further. compleate all noted optimization.

   assign bm_bank = BANK_ID;

   always_comb
     begin
	bm_addr = '0;
	bm_slot = bm_slot_q;
	bm_priority = priority_lcl;
	bm_atmpt_pre_lcl = bm_atmpt_pre_q;
	bm_id = '0;
	bm_act = '0;
	bm_cas = '0;
	bm_r_w = '0;
	bm_pre = '0;
	isact = '0;
	ispre = '0;
	iswrite = '0;
	isread = '0;
	act_slot = '0;
	pre_slot = '0;
	write_slot = '0;
	read_slot = '0;
	bm_idle = '0;
	bm_prechared = bm_prechared_q;
	fifo_next_cmd = '0;
	NS = CS;
	bm_cmd = NOP;
	bank_active_lcl = bank_active_q;
	bm_sent_pre_n_lcl = bm_sent_pre_n_q;
	bm_sent_apre_lcl = bm_sent_apre_q;
	bm_sent_cas_lcl = bm_sent_cas_q;
	req_grant_slot_diff_lcl = req_grant_slot_diff_q;
	latch_row_lcl = latch_row_q;
	latch_col_lcl = latch_col_q;
	latch_cmd_lcl = latch_cmd_q;
	latch_priority_lcl = latch_priority_q;
	latched_id_lcl = latched_id_q;
	bm_dis_interrupted_cas_lcl = bm_dis_interrupted_cas_q;
	case(CS)
	  BANK_ST_IDLE_PRE: begin
	     bank_active_lcl = '0;
	     if(bm_en || rg_done_n)
	       begin
		  if(((cmd_mux_pre_ack && (cmd_mux_pre_grant == BANK_ID) &&
		       (!rm_stall||rg_done_n)) || bm_sent_pre_n_q))
		    begin
		       bm_sent_pre_n_lcl = 1'b1;
		       bm_sent_apre_lcl = 1'b0;
		       if(cmd_mux_pre_ack && (cmd_mux_pre_grant == BANK_ID))
			 req_grant_slot_diff_lcl = cmd_mux_pre_slot - bm_slot_q;
		       bm_idle = fifo_empty && !bm_dis_interrupted_cas_q;
		       //send new act
		       if(safe_pre2act)
			 begin
			    if((pre2act_slot +
				(ack_pre_lcl?cmd_mux_pre_slot-bm_slot_q:
				 req_grant_slot_diff_q)) < CLK_RATIO)
			      begin
				 bm_prechared = !rm_stall;
				 if(((!fifo_empty || bm_dis_interrupted_cas_q) &&
				    !rm_stall)||rg_done_n) begin
				    NS = BANK_ST_ROW_ACTIVE;
				    bm_cmd = ACT;
				    /*if(bm_dis_interrupted_cas_q && rg_done)
				      begin
					 bm_addr = latch_row_lcl;
					 bm_id = latched_id_q;
					 bm_priority = latch_priority_q;
				      end
				    else
				      begin*/
					 bm_addr = row_lcl;
					 bm_id = id_lcl;
					 bm_priority = priority_lcl;
				      //end
				    bm_slot = pre2act_slot +
					      (ack_pre_lcl?cmd_mux_pre_slot -
					       bm_slot_q : req_grant_slot_diff_q);
				    bm_act = 1'b1;
				    isact = 1'b1;
				    act_slot = bm_slot;
				    //bm_idle = '0;
				    bm_prechared = '0;
				    req_grant_slot_diff_lcl = 0;
				 end // if (!(fifo_empty || rm_stall))
				 else
				   req_grant_slot_diff_lcl = '0;
			      end // if (((pre2act_slot + req_grant_slot_lcl)...
			    else
			      req_grant_slot_diff_lcl = pre2act_slot +
							(ack_pre_lcl?cmd_mux_pre_slot-bm_slot_q:
							 req_grant_slot_diff_q) - CLK_RATIO;
			 end // if (safe_pre2act )
		    end // if ((cmd_mux_pre_ack && (cmd_mux_pre_grant...
		  else
		    begin
		       //send previous pre
		       NS = BANK_ST_IDLE_PRE;
		       bm_cmd = PRE;
		       bm_addr = '0;
		       bm_id = id_lcl;
		       bm_slot = '0;
		       bm_priority = priority_lcl;
		       bm_pre = 1'b1;
		       ispre = 1'b1;
		       pre_slot = bm_slot;
		       bm_sent_pre_n_lcl = 1'b0;
		    end // else: !if(((cmd_mux_pre_ack && (cmd_mux_pre_gran...
	       end // if (bm_en)
	     else
	       begin
		  if(rm_pre_all)
		    begin
		       NS = BANK_ST_IDLE_PRE;
		       ispre = 1'b1;
		       pre_slot = rm_pre_all_slot;
		       req_grant_slot_diff_lcl = '0;
		    end
		  bm_sent_pre_n_lcl = 1'b1;
		  bm_idle = fifo_empty && !bm_dis_interrupted_cas_q;
		  //if( bm_sent_pre_n_q && safe_pre2act)
		  bm_prechared = bm_prechared_q;//1'b1;
	       end // else: !if(bm_en)
	  end // case: BANK_ST_IDLE_PRE
	  BANK_ST_ROW_ACTIVE: begin
	     if(bm_en || rg_done_n)
	       begin
		  if(!(bank_active_q || ((!rm_stall||rg_done_n) && ack_act_lcl)))
		    begin
		       //continue to send ACT cmd. Sslot is applicable
		       // only for 1st clk when ACT was sent.
		       NS = BANK_ST_ROW_ACTIVE;
		       bm_cmd = ACT;
		       /*if(bm_dis_interrupted_cas_q && !rg_req)
			 begin
			    bm_addr = latch_row_lcl;
			    bm_id = latched_id_q;
			    bm_priority = latch_priority_q;
			 end
		       else
			 begin*/
			    bm_addr = row_lcl;
			    bm_id = id_lcl;
			    bm_priority = priority_lcl;
			// end
		       bm_slot = '0;
		       bm_act = 1'b1;
		       isact = 1'b1;
		       act_slot = bm_slot;
		    end // if (!(bank_active_q || !rm_stall) ||...
		  else
		    begin
		       bank_active_lcl = 1'b1;
		       if(ack_act_lcl)
			 req_grant_slot_diff_lcl = cmd_mux_act_slot - bm_slot_q;
		       else if(ack_cas_lcl)
			 req_grant_slot_diff_lcl = cmd_mux_cas_slot - bm_slot_q;
		       // entering after act cmd or after ack of previous
		       // cas cmd && !rm_stall. Entering after act cmd and
		       // checking for rm_stall is an invalid condition.
		       if(((bm_sent_cas_q && ((ack_cas_lcl && !rm_stall) ||
					      bm_atmpt_pre_q))||
			   bm_first_cas_aftr_act)
			  /*&& (!bm_dis_interrupted_cas_q||rg_done_n)*/)begin
			  // || ack_cas_lcl could be commented (redundent)
			  // apre_sent in prev clk and !row_miss in preset clk
			  // is an unreachable state
			  if((!row_miss_lcl || bm_first_cas_aftr_act) && rg_done
			     && (!fifo_empty || bm_dis_interrupted_cas_q) &&
			     !bm_sent_apre_q)begin
			     // !bm_sent_apre_q is redundent(row_miss is enough)
			     if(safe_act2cas) begin
				if((act2cas_slot +
				    (ack_act_lcl?cmd_mux_act_slot - bm_slot_q:
				     ack_cas_lcl?cmd_mux_cas_slot - bm_slot_q:
				     req_grant_slot_diff_q)) < CLK_RATIO)
				  begin
				     if(!rm_stall) begin
					// send cmds from fifo top
					NS = BANK_ST_ROW_ACTIVE;
					bm_cmd = (cmd_lcl == FE_WRITE)?WR:RD;
					bm_addr = {'0,col_lcl[10],1'b0,col_lcl[9:0]};//col_lcl;
					bm_id = id_lcl;
					// slot is applicable only for the 1st cas
					// cmd after act. later on all cas2cas
					// timing is taken care in cmd_mux
					bm_slot = act2cas_slot +
						  (ack_act_lcl?cmd_mux_act_slot-bm_slot_q:
						   req_grant_slot_diff_q);
					bm_priority = priority_lcl;
					bm_cas = 1'b1;
					bm_r_w = (cmd_lcl != FE_WRITE);
					iswrite = (cmd_lcl == FE_WRITE);
					isread = (cmd_lcl != FE_WRITE);
					write_slot = bm_slot;
					read_slot = bm_slot;
					bm_sent_cas_lcl = 1'b1;
					bm_sent_apre_lcl = bank_fifo_apre_out;
					bm_addr[10] = bank_fifo_apre_out;
					fifo_next_cmd = !bm_dis_interrupted_cas_q;
					bm_atmpt_pre_lcl = 1'b0;
					bm_dis_interrupted_cas_lcl = 1'b0;
					// latch fifo top. if there is an ack
					// in the next clk FIFO should be
					// incremented, waiting for ack will
					// add latency. Thus, this logic
					// assumes ack and will increment
					// fifo. If there is no ack it will
					// continue to send same cmd from the
					// latch.
					latch_row_lcl = row_lcl;
					latch_col_lcl = col_lcl;
					latch_cmd_lcl = cmd_lcl;
					latch_priority_lcl = priority_lcl;
					latched_id_lcl = id_lcl;
				     end // if (!rm_stall)
				     else
				       req_grant_slot_diff_lcl = '0;
				  end // if ((pre2act_slot +...
				else
				  // considering only act related slot because
				  // this branch is entered only before sending
				  // first cas after act cmd. Later on this
				  // branch is not at all entered
				  req_grant_slot_diff_lcl = act2cas_slot +
							    (ack_act_lcl?cmd_mux_act_slot-bm_slot_q:
							     req_grant_slot_diff_q) - CLK_RATIO;
			     end // if (safe_act2cas && !fifo_empty)
			  end // if (!row_miss_lcl || bm_sent_cas_q)
			  else
			    begin
			       bm_atmpt_pre_lcl = 1'b1;
			       if(!fifo_empty || bm_sent_apre_q || rg_done_n) begin
				  // manage precherge
				  if(safe_wr2pre && safe_rd2pre && safe_act2pre)
				     //&& !fifo_empty)
				    begin
				       if((pre_max_slot + (ack_cas_lcl?
							   cmd_mux_cas_slot - bm_slot_q:
							   req_grant_slot_diff_q)) < CLK_RATIO)
					 begin
					    if(!rm_stall || rg_done_n) begin
					       //send pre
					       NS = BANK_ST_IDLE_PRE;
					       bm_cmd = PRE;
					       bm_addr = '0;
					       bm_id = id_lcl;
					       bm_slot = pre_max_slot +
							 (ack_cas_lcl?cmd_mux_cas_slot -
							  bm_slot_q:req_grant_slot_diff_q);
					       bm_pre = !bm_sent_apre_q;
					       ispre = 1'b1;
					       pre_slot = bm_slot;
					       bank_active_lcl = '0;
					       bm_priority = priority_lcl;
					       bm_sent_pre_n_lcl = bm_sent_apre_q;
					       bm_sent_cas_lcl = 1'b0;
					       bm_atmpt_pre_lcl = 1'b0;
					       //req_grant_slot_diff_lcl = '0;
					    end // if (!rm_stall)
					    else
					      req_grant_slot_diff_lcl = '0;
					 end
				       else begin
					  req_grant_slot_diff_lcl = pre_max_slot +
								    (ack_cas_lcl?cmd_mux_cas_slot-bm_slot_q:
								     req_grant_slot_diff_q) - CLK_RATIO;
				       end
				    end // if (safe_wr2pre && safe_rd2pre && safe_act2pre...
			       end // if (!fifo_empty || bm_sent_apre_q)
			       else begin
				  // fifo_empty and auto pre not sent wait here
				  // TODO: bm_idle
				  bm_idle = 1'b1;
				  NS = CS;
			       end // else: !if(!fifo_empty || bm_sent_apre_q)
			    end // else: !if((!row_miss_lcl && !fifo_empty)||bm_sent_apre_n_q)
		       end // if ((bm_sent_cas_q && ack_cas_lcl && !rm_stall) ||...
		       else
			 begin
			    //send lached cmd
			    NS = BANK_ST_ROW_ACTIVE;
			    bm_cmd = (latch_cmd_q == FE_WRITE)?WR:RD;
			    bm_addr = {'0,latch_col_q[10],1'b0,latch_col_q[9:0]};
			    bm_id = latched_id_q;
			    bm_slot = /*bm_dis_interrupted_cas_q?act2cas_slot:*/1'b0;
			    bm_priority = latch_priority_q;
			    bm_cas = 1'b1;
			    bm_r_w = (latch_cmd_q != FE_WRITE);
			    iswrite = (latch_cmd_q == FE_WRITE);
			    isread = (latch_cmd_q != FE_WRITE);
			    write_slot = bm_slot;
			    read_slot = bm_slot;
			    bm_sent_cas_lcl = 1'b1;
			    fifo_next_cmd = 1'b0;
			    bm_sent_apre_lcl = bank_fifo_apre_out;
			    bm_addr[10] = bm_sent_apre_q;
			    bm_dis_interrupted_cas_lcl = 1'b0;
			    // latch fifo top. if there is an ack
			    // in the next clk FIFO should be
			    // incremented, waiting for ack will
			    // add latency. Thus, this logic
			    // assumes ack and will increment
			    // fifo. If there is no ack it will
			    // continue to send same cmd from the
			    // latch.
			    latch_row_lcl = latch_row_q;
			    latch_col_lcl = latch_col_q;
			    latch_cmd_lcl = latch_cmd_q;
			    latch_priority_lcl = latch_priority_q;
			 end // else: !if((bm_sent_cas_q && ack_cas_lcl && !rm_stall) ||...
		    end // else: !if(!(bank_active_q || (!rm_stall && ack_act_lcl)))
			   end // if (bm_en)
	     else
	       begin
		  if(rm_pre_all)
		    begin
		       NS = BANK_ST_IDLE_PRE;
		       ispre = 1'b1;
		       pre_slot = rm_pre_all_slot;
		       bm_sent_pre_n_lcl = 1'b1;
		       req_grant_slot_diff_lcl = '0;
		       bm_dis_interrupted_cas_lcl = bm_sent_cas_q && !bm_atmpt_pre_q;
		       bm_sent_cas_lcl = /*bm_sent_cas_q && !bm_atmpt_pre_q*/1'b0;
		       bm_atmpt_pre_lcl = 1'b0;
		    end // if (rm_pre_all)
		  bm_idle = fifo_empty && !(bm_sent_cas_q && !bm_atmpt_pre_q);
	       end
	  end // case: BANK_ST_ROW_ACTIVE
	endcase // case (CS)
     end // always_comb

endmodule
