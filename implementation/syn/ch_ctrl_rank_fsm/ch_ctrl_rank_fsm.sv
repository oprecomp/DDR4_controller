module ch_ctrl_rank_fsm
  #(
    parameter BANK_FIFO_DEPTH = 8,
    parameter ROW_ADDR_WIDTH = 16,
    parameter COL_ADDR_WIDTH = 11,
    parameter DRAM_ADDR_WIDTH = 16,
    parameter DRAM_CMD_WIDTH = 5,
    parameter DRAM_BANKS = 8,
    parameter DRAM_BUS_WIDTH = 8,
    parameter FE_ADDR_WIDTH = 32,
    parameter FE_CMD_WIDTH = 1,
    parameter FE_ID_WIDTH = 8,
    parameter FE_WRITE = 0,
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

    //DEFAULTS
    parameter RG_REF_NUM_ROW_PER_REF = 4,
    parameter ZQSI_AREFI_CYCLES = 128 //1ms=128*tREFI. assumption:tREFI = 7.8
    /*parameter RRD_DRAM_CYCLES = 4,
    parameter WTR_DRAM_CYCLES = 4,
    parameter CCD_DRAM_CYCLES = 4,
    parameter RP_DRAM_CYCLES = 6,
    parameter RTP_DRAM_CYCLES = 4,
    parameter WR_DRAM_CYCLES = 6,
    parameter RCD_DRAM_CYCLES = 6,
    parameter RAS_DRAM_CYCLES = 15,
    parameter AREF_DRAM_CYCLES = 3120,//7.8us
    parameter RFC_DRAM_CYCLES = 44,//1Gb 110ns
    parameter ZQS_DRAM_CYCLES = 64, // max(64nCK, 80ns)
    parameter CL = 6,
    parameter CWL = 5,
    parameter TFAW_NS = 40,
    parameter BL = 8*/
    )
   (
    //********* SIGNALS FROM THE FRONT END ***********************
    input 					   rst_n, //  Reset
    input 					   clk,//  System Clock
    input 					   fe_req,
    input [FE_CMD_WIDTH-1:0] 			   fe_cmd,
    input [FE_ADDR_WIDTH-1:0] 			   fe_addr,
    input [FE_ID_WIDTH-1:0] 			   fe_id,
    output 					   fe_stall,
    input 					   read_stall,
    input 					   init_done,
    output logic 				   init_en,
    //****************** SIGNALS TO THE PHY ***********************
    output [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0]    rm_addr,
    output [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] rm_bank,
`ifdef DDR4
    output [CLK_RATIO-1:0] 			   rm_act_n,
`endif
    output [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	   rm_cmd,
    output 					   rm_valid,
    output [FE_ID_WIDTH-1:0] 			   rm_cas_cmd_id,
    output 					   rm_cas_cmd_id_valid,//not req
    output 					   rm_write,
    output 					   rm_read,
    output [$clog2(CLK_RATIO)-1:0] 		   rm_cas_slot,
    //****************** SIGNALS TO Side Ch ***********************
    output logic [7:0] 				   rm_fsm_state,
    //****************** SIGNALS TO THE PHY ***********************
    input 					   bus_rdy,
    //**************** CONFIG & TIMING INPUTS ***********************
    input 					   decoder_type,
    dram_global_timing_if.wp dram_t_rm,
    dram_bank_timing_if.wp dram_t_bm,
    dram_aref_zq_timing_if.wp aref_zq,
    dram_rg_ref_if.wp rg_ref,
    congen_if.wp congen
    );

`ifdef DDR4
   localparam NOP = 5'b11111;
   // In DDR4 the NOP command is not allowed, except when exiting maximum power savings mode 
   // or when entering gear-down mode, and only a DES command should be Used
   // Basically DDR3 NOP is equvalent to DES in DDR4 during normal operation
   // Hence setting cs_n to H or 1
`else
   localparam NOP = 5'b10111;
`endif
   localparam PRE = 5'b10010;
   localparam REF = 5'b10001;
   localparam ZQCS = 5'b10110;

   /***************************** AREF Counter ********************************/

   //FIXME: opt is possible
   //taken from old ctrl.

   logic [AREFI_CNT_WIDTH-1:0] 			   arefi_cntr,arefi_cntr_lcl;
   logic [AREFI_CNT_WIDTH-1:0] 			   AREFI_CTRL_CYCLES;
   logic 						   aref_done;
   logic 						   aref_req;
   logic [2:0] 					   aref_stack_cnt;
   logic [2:0] 					   aref_stack_cnt_lcl; // max 8
   logic 						   aref_incr_stack;
   logic 						   aref_incr_stack_lcl;
   logic 						   near_to_aref;
   logic 						   stop_aref_cntr;
   logic 						   aref_req_lmr;// req from mode reg

   assign stop_aref_cntr = !(init_done && !aref_zq.DISABLE_REF);
   assign AREFI_CTRL_CYCLES = (aref_zq.AREFI_DRAM_CYCLES >> $clog2(CLK_RATIO)) + 1;

   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n ==  1'b0)
	  begin
	     arefi_cntr <= 780; // 7.8 us for 100 Mhz ctrl clk
	     aref_stack_cnt <= '0;
	     aref_incr_stack <= 1'b0;
	  end
	else
	  begin
	     arefi_cntr <= arefi_cntr_lcl;
	     aref_stack_cnt <= aref_stack_cnt_lcl;
	     aref_incr_stack <= aref_incr_stack_lcl;
	  end // else: !if(rst_n ==  1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)

   always_comb
     begin
	case({aref_incr_stack,aref_done})
	  2'b00: begin
	     aref_stack_cnt_lcl = aref_stack_cnt;
	  end
	  2'b01: begin
	     if(aref_stack_cnt != 0)
	       aref_stack_cnt_lcl = aref_stack_cnt - 1'b1;
	     else
	       aref_stack_cnt_lcl = aref_stack_cnt;
	  end
	  2'b10: begin
	     aref_stack_cnt_lcl = aref_stack_cnt + 1'b1;
	  end
	  2'b11: begin
	     aref_stack_cnt_lcl = aref_stack_cnt;
	  end
	endcase // case ({AREF_Incr_StackReq,aref_done||aref_rq_lmr})
     end // always_comb

   always_comb
     begin
	if((arefi_cntr > 0) && (~stop_aref_cntr)) begin
	   arefi_cntr_lcl = arefi_cntr - 1'b1;
	   aref_incr_stack_lcl = 1'b0;
	end
	else begin
	   arefi_cntr_lcl = AREFI_CTRL_CYCLES;
	   aref_incr_stack_lcl = ~stop_aref_cntr;
	end
     end // always_comb

   //assign aref_incr_stack = (arefi_cntr == 0);
   assign aref_req = (aref_stack_cnt > 0);
   assign near_to_aref = (arefi_cntr < 5);

   /***************************** END AREF Counter ****************************/

   /******************************* PRE_AREF_FSM ******************************/
   logic [RC_DRAM_CYCLES_LOG2-1:0] RC_DRAM_CYCLES;
   logic [(RC_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] RC_CTRL_CYCLES;
   logic [(RP_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] RP_CTRL_CYCLES;
   logic [(RFC_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] RFC_CTRL_CYCLES;
   logic [(ZQS_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] ZQS_CTRL_CYCLES;

   assign RC_DRAM_CYCLES = dram_t_bm.RAS_DRAM_CYCLES + dram_t_bm.RP_DRAM_CYCLES;
   assign RC_CTRL_CYCLES = (RC_DRAM_CYCLES >> $clog2(CLK_RATIO)) + 1;
   assign RP_CTRL_CYCLES = (dram_t_bm.RP_DRAM_CYCLES >> $clog2(CLK_RATIO)) + 1;
   assign RFC_CTRL_CYCLES = (aref_zq.RFC_DRAM_CYCLES >> $clog2(CLK_RATIO)) + 1;
   assign ZQS_CTRL_CYCLES = (aref_zq.ZQS_DRAM_CYCLES >> $clog2(CLK_RATIO));

   typedef enum logic [2:0] {
			     IDLE = 0,
			     INIT,
			     PRE_ALL,
			     AREF,
			     ZQS
			     } CMD_PRE_AREF_FSM;
   CMD_PRE_AREF_FSM  PRE_AREF_CS;
   CMD_PRE_AREF_FSM  PRE_AREF_NS;

   logic [(RFC_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] counter_pre_aref_CS;
   logic [(RFC_DRAM_CYCLES_LOG2 - $clog2(CLK_RATIO))-1:0] counter_pre_aref_NS;
   logic 						  pre_aref_done;
   logic 						  rm_pre_all;
   logic 						  rm_pre_all_pd;
   logic 						  start_pre_aref;
   logic 						  start_aref;
   logic [DRAM_ADDR_WIDTH-1:0] 				  pre_aref_addr;
   logic [DRAM_CMD_WIDTH-1:0] 					  pre_aref_cmd;
   logic [$clog2(ZQSI_AREFI_CYCLES)-1:0] 			  zq_cntr_q;
   logic [$clog2(ZQSI_AREFI_CYCLES)-1:0] 			  zq_cntr_lcl;
   logic 							  rg_req;
   logic 							  rg_req_q;
   logic [DRAM_BANKS-1:0] 					  rg_done;
   logic 							  bus_rdy_q;


   always_ff @(posedge clk, negedge rst_n)  begin
      if(rst_n == 1'b0)  begin
	 PRE_AREF_CS <= IDLE;
	 counter_pre_aref_CS <= '0;
	 zq_cntr_q <= ZQSI_AREFI_CYCLES-1;
	 rg_req_q <= '0;
	 bus_rdy_q <= '0;
      end
      else  begin
	 PRE_AREF_CS <= PRE_AREF_NS;
	 counter_pre_aref_CS <= counter_pre_aref_NS;
	 // ZQ short cntr - cntr value is in increments every REF
	 zq_cntr_q <= zq_cntr_lcl;
	 rg_req_q <= rg_req;
	 bus_rdy_q <= bus_rdy;
      end
   end

   always_comb  begin
      counter_pre_aref_NS = counter_pre_aref_CS;
      aref_done = 1'b0;
      pre_aref_addr = '0;
      pre_aref_cmd = NOP;
      pre_aref_done = 1'b0;
      rm_pre_all = 1'b0;
      rm_pre_all_pd = 1'b0;
      zq_cntr_lcl = zq_cntr_q;
      PRE_AREF_NS = PRE_AREF_CS;
      rg_req = rg_req_q;
      case(PRE_AREF_CS)
	IDLE: begin
	   if(start_pre_aref == 1'b1)
	     begin
		PRE_AREF_NS = INIT;
		counter_pre_aref_NS = RC_CTRL_CYCLES - 1 + 3;
	     end
	   else if (start_aref == 1'b1)
	     begin
		PRE_AREF_NS = PRE_ALL;
		counter_pre_aref_NS = RP_CTRL_CYCLES - 1'b1;
		// if in case a precharge cmd is sent a clock cycle before
		// rm_stall is high and it was the only active bank
	     end
	   else
	     PRE_AREF_NS = IDLE;
	end // case: IDLE
	INIT: begin  //could be optimized here, instead of considering fxd time
	   if(counter_pre_aref_CS != 0)
	     begin
		PRE_AREF_NS = INIT;
		counter_pre_aref_NS = counter_pre_aref_CS - 1'b1;
	     end
	   else
	     begin
		PRE_AREF_NS = PRE_ALL;
		counter_pre_aref_NS = RP_CTRL_CYCLES - 1'b1;
		//send Pre-All
		pre_aref_addr[10] = 1'b1;
`ifdef DDR4
		pre_aref_addr[16:14] = 3'b010;
`endif
		pre_aref_cmd = PRE;
		rm_pre_all = 1'b1;
	     end
	end // case: INIT
	PRE_ALL:
	  begin
	     // Apply PRE ALL and wait tRP
	     if(counter_pre_aref_CS != 0)
	       begin
		  PRE_AREF_NS = PRE_ALL;
		  counter_pre_aref_NS = counter_pre_aref_CS - 1'b1;
	       end
	     else
	       begin
		  //SEND AREF
		  rg_req = rg_ref.en;
		  pre_aref_cmd = REF;
`ifdef DDR4
		  pre_aref_addr[16:14] = 3'b001;
`endif
		  counter_pre_aref_NS = RFC_CTRL_CYCLES - 1'b1;
		  aref_done = 1'b1;
		  PRE_AREF_NS = AREF;
	       end // else: !if(counter_pre_aref_CS != 0)
	  end // case: PRE_ALL
	AREF:
	  begin
	     // Apply FIRST AREF wait tRFC
	     if(counter_pre_aref_CS != 1'b0)
	       begin
		  PRE_AREF_NS = AREF;
		  if(rg_req_q)
		    if(&rg_done)
		      counter_pre_aref_NS = 0;
		    else
		      counter_pre_aref_NS = counter_pre_aref_CS;
		  else
		    counter_pre_aref_NS = counter_pre_aref_CS - 1'b1;
	       end
	     else
	       begin
		  zq_cntr_lcl = zq_cntr_q - 1;
		  if((zq_cntr_q == 0) && (!aref_zq.ZQS_DISABLE))
		    begin
		       zq_cntr_lcl = ZQSI_AREFI_CYCLES-1;
		       // ZQS interval = ZQS_AREFI_CYCLES * tREFI
		       pre_aref_cmd = ZQCS;
`ifdef DDR4
		       pre_aref_addr[16:14] = 3'b110;
`endif
		       PRE_AREF_NS = ZQS;
		       counter_pre_aref_NS = ZQS_CTRL_CYCLES - 1'b1;
		    end
		  else
		    begin
		       if(!read_stall)
			 begin
			    rg_req = 0;
			    PRE_AREF_NS = IDLE;
			    pre_aref_done = 1'b1;
			 end
		    end // else: !if(zq_cntr_q != 0)
	       end // else: !if(counter_pre_aref_CS != 1'b0)
	  end // case: AREF
	ZQS:
	  begin
	     if(counter_pre_aref_CS != 1'b0)
	       begin
		  PRE_AREF_NS = ZQS;
		  counter_pre_aref_NS = counter_pre_aref_CS - 1'b1;
	       end
	     else
	       begin
		  if(!read_stall&&bus_rdy_q)
		    begin
		       rg_req = 0;
		       PRE_AREF_NS = IDLE;
		       pre_aref_done = 1'b1;
		    end
	       end // else: !if(counter_pre_aref_CS != 1'b0)
	  end // case: AREF
      endcase // case (PRE_AREF_CS)
   end // always_comb

   /************************* END of AREF PREALL FSM **************************/

   /******************************* Addr Decoder FSM****************************/

   // This fsm decodes the incoming address to bank, row and column and send
   // it to all bank machines. Then waits for the response from bank machines.
   // In case of no ack, input requestes are stalled.

   /*typedef enum logic[1:0] {DEC_IDLE = 0, DEC_ACTIVE, DEC_BUSY} bank_dec_state;
   bank_dec_state  bank_dec_CS, bank_dec_NS;*/

   logic 	ad_req;
   logic [ROW_ADDR_WIDTH-1:0] ad_row, ad_row_q;
   logic [ROW_ADDR_WIDTH-1:0] latched_row_lcl, latched_row_q;
   logic [COL_ADDR_WIDTH-1:0] ad_col, ad_col_q;
   logic [COL_ADDR_WIDTH-1:0] latched_col_lcl, latched_col_q;
   logic [$clog2(DRAM_BANKS)-1:0] ad_bank, ad_bank_q;
   logic [$clog2(DRAM_BANKS)-1:0] latched_bank_lcl, latched_bank_q;
   logic [FE_CMD_WIDTH-1:0] 	  ad_cmd, ad_cmd_q;
   logic [FE_CMD_WIDTH-1:0] 	  latched_cmd_lcl, latched_cmd_q;
   logic 			  ord_fifo_en;
   logic [$clog2(DRAM_BANKS)-1:0] ord_fifo_in;
   logic [FE_ID_WIDTH-1:0] 	  ad_id,ad_id_q;
   logic [FE_ID_WIDTH-1:0] 	  latched_id_lcl, latched_id_q;
   logic [$clog2(BANK_FIFO_DEPTH*DRAM_BANKS)-1:0] ad_priority, ad_priority_q;
   logic [DRAM_BANKS-1:0] 			  bm_ack;
   logic 					  ad_stall_q;
   logic 					  ad_stall;
   logic [31:0] 				  congen_out;
   logic 					  bm_ack_comp;

   // only for FE_ADDR_WIDTH = 32
   // make it generic
   congen congen_decoder
     (
      .in(fe_addr),
`ifdef DDR4
      .conf({congen.b3,congen.b2,congen.b1,congen.b0,congen.r16,congen.r15,
	     congen.r14,congen.r13,congen.r12,congen.r11,congen.r10,congen.r9,
	     congen.r8,congen.r7,congen.r6,congen.r5,congen.r4,congen.r3,
	     congen.r2,congen.r1,congen.r0,congen.c10,congen.c9,congen.c8,
	     congen.c7,congen.c6,congen.c5,congen.c4,congen.c3}),
`else
      .conf({5'b0,congen.b2,congen.b1,congen.b0,congen.r15,congen.r14,congen.r13,
	     congen.r12,congen.r11,congen.r10,congen.r9,congen.r8,congen.r7,
	     congen.r6,congen.r5,congen.r4,congen.r3,congen.r2,congen.r1,
	     congen.r0,congen.c10,congen.c9,congen.c8,congen.c7,congen.c6,
	     congen.c5,congen.c4,congen.c3}),
`endif
      .out(congen_out)
      );

   assign ad_cmd = fe_cmd;
   assign ad_col = congen_out[COL_ADDR_WIDTH-1:0];
   assign ad_row = congen_out[COL_ADDR_WIDTH +: ROW_ADDR_WIDTH];
   assign ad_bank = congen_out[(COL_ADDR_WIDTH+ROW_ADDR_WIDTH)+:$clog2(DRAM_BANKS)] ^ 
		    (congen.xor_sel & ad_row[2:0]);
   assign bm_ack_comp = (bm_ack == '1);
   assign ord_fifo_en = fe_req && bm_ack_comp;
   assign ad_stall = !bm_ack_comp;
   assign ad_req = fe_req && bm_ack_comp;
   assign ad_priority = ord_fifo_en?ad_priority_q + 1'b1:ad_priority_q;
   assign {ord_fifo_in,ad_id} = {ad_bank,fe_id};

   always_ff@(posedge clk, negedge rst_n)
     begin
	if(!rst_n)  begin
	   ad_priority_q <= '1;
	end
	else
	  ad_priority_q <= ad_priority;
     end

   // optimization possible, this part of the code istaken from previous
   // controller
   /*always_ff@(posedge clk, negedge rst_n)
     begin
	if(!rst_n)  begin
	   bank_dec_CS <= DEC_IDLE;
	   ad_bank_q <= '0;
	   ad_row_q <= '0;
	   ad_col_q <= '0;
	   ad_cmd_q <= '0;
	   ad_id_q <= '0;
	   ad_priority_q <= '1;
	   ad_stall_q <= '0;
	   latched_bank_q <= '0;
	   latched_row_q <= '0;
	   latched_col_q <=  '0;
	   latched_cmd_q <= '0;
	   latched_id_q <= '0;
	end // if (!rst_n)
	else  begin
	   bank_dec_CS <= bank_dec_NS;
	   ad_bank_q <= ad_bank;
	   ad_row_q <= ad_row;
	   ad_col_q <= ad_col;
	   ad_cmd_q <= ad_cmd;
	   ad_id_q <= ad_id;
	   ad_priority_q <= ad_priority;
	   ad_stall_q <= (bank_dec_NS == DEC_BUSY);
	   latched_bank_q <= latched_bank_lcl;
	   latched_row_q <= latched_row_lcl;
	   latched_col_q <=  latched_col_lcl;
	   latched_cmd_q <= latched_cmd_lcl;
	   latched_id_q <= latched_id_lcl;
	end // else: !if(!rst_n)
  end // always_ff@ (posedge clk, negedge rst_n)

   always_comb
     begin
	ad_row = ad_row_q; // FIXME:Chirag: FF !required, remove in nxt ver
	ad_col = ad_col_q;
	ad_bank = ad_bank_q;
	ad_req = '0;
	ad_cmd = ad_cmd_q;
	ad_id = ad_id_q;
	ad_priority = ad_priority_q;
	latched_bank_lcl = latched_bank_q;
	latched_row_lcl = latched_row_q;
	latched_col_lcl = latched_col_q;
	latched_cmd_lcl = latched_cmd_q;
	latched_id_lcl = latched_id_q;
	bank_dec_NS = bank_dec_CS;
	//ad_stall = 1'b0;
	ord_fifo_en = 1'b0;
	ord_fifo_in = '0;
	case(bank_dec_CS)
	  DEC_IDLE: begin
	     if(fe_req)
	       begin
		  bank_dec_NS = DEC_ACTIVE;
		  ad_cmd = fe_cmd;
		  ad_req = 1'b1;
		  ad_priority = ad_priority_q + 1'b1;
		  case(decoder_type)
		    1'b0: begin //BRC
		       ad_bank = fe_addr[$clog2(DRAM_BANKS) + ROW_ADDR_WIDTH +
					 COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					 - 4: ROW_ADDR_WIDTH + COL_ADDR_WIDTH +
					 $clog2(DRAM_BUS_WIDTH) - 3];
		       ad_row = fe_addr[ROW_ADDR_WIDTH + COL_ADDR_WIDTH +
					$clog2(DRAM_BUS_WIDTH) - 4:
					COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					- 3];
		       ad_col = fe_addr[COL_ADDR_WIDTH +$clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b0
		    1'b1: begin // RBC
		       ad_row = fe_addr[ROW_ADDR_WIDTH + $clog2(DRAM_BANKS) +
					COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BANKS)+ COL_ADDR_WIDTH+
					$clog2(DRAM_BUS_WIDTH) - 3];
		       ad_bank = fe_addr[$clog2(DRAM_BANKS) + COL_ADDR_WIDTH +
					 $clog2(DRAM_BUS_WIDTH) - 4:
					 COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					 - 3];
		       ad_col = fe_addr[COL_ADDR_WIDTH +$clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b1
		  endcase // case (decoder_type)
		  ord_fifo_en = 1'b1;
		  {ord_fifo_in,ad_id} = {ad_bank,fe_id};
	       end // if (fe_req)
          end // case: DEC_IDLE
	  DEC_ACTIVE: begin
	     case ({fe_req,(bm_ack == '1)})
	       2'b00: begin
		  bank_dec_NS =  DEC_ACTIVE;
		  ad_req = 1'b0;
		  ad_row =  ad_row_q;
		  ad_col = ad_col_q;
		  ad_bank = ad_bank_q;
		  ad_cmd = ad_cmd_q;
		  ad_id = ad_id_q;
	       end
	       2'b01: begin
		  bank_dec_NS =  DEC_IDLE;
		  ad_req = 1'b0;
		  ad_row =  ad_row_q;
		  ad_col = ad_col_q;
		  ad_bank = ad_bank_q;
		  ad_cmd = ad_cmd_q;
		  ad_id = ad_id_q;
	       end
	       2'b10:  begin
		  // Latch the new request(Row, Bank ,Column & Cmd) and
		  // stall the front end
		  bank_dec_NS = DEC_BUSY;
		  ad_req = 1'b0;
		  latched_cmd_lcl = fe_cmd;
		  latched_id_lcl = fe_id;
		  case(decoder_type)
		    1'b0: begin //BRC
		       latched_bank_lcl = fe_addr[$clog2(DRAM_BANKS)+ROW_ADDR_WIDTH+
						  COL_ADDR_WIDTH +
						  $clog2(DRAM_BUS_WIDTH)- 4:
						  ROW_ADDR_WIDTH+ COL_ADDR_WIDTH
						  + $clog2(DRAM_BUS_WIDTH) - 3];
		       latched_row_lcl = fe_addr[ROW_ADDR_WIDTH + COL_ADDR_WIDTH
						 + $clog2(DRAM_BUS_WIDTH) - 4:
						 COL_ADDR_WIDTH +
						 $clog2(DRAM_BUS_WIDTH) - 3];
		       latched_col_lcl = fe_addr[COL_ADDR_WIDTH +
						 $clog2(DRAM_BUS_WIDTH) - 4:
						 $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b0
		    1'b1: begin // RBC
		       latched_row_lcl = fe_addr[ROW_ADDR_WIDTH + $clog2(DRAM_BANKS)
						 + COL_ADDR_WIDTH +
						 $clog2(DRAM_BUS_WIDTH) - 4:
						 $clog2(DRAM_BANKS) + COL_ADDR_WIDTH +
						 $clog2(DRAM_BUS_WIDTH) - 3];
		       latched_bank_lcl = fe_addr[$clog2(DRAM_BANKS)+COL_ADDR_WIDTH+
						  $clog2(DRAM_BUS_WIDTH) - 4:
						  COL_ADDR_WIDTH +
						  $clog2(DRAM_BUS_WIDTH) - 3];
		       latched_col_lcl = fe_addr[COL_ADDR_WIDTH +
						 $clog2(DRAM_BUS_WIDTH) - 4:
						 $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b1
       	  endcase // case (decoder_type)
		  ad_row =  latched_row_lcl;
		  ad_col = latched_col_lcl;
		  ad_bank = latched_bank_lcl;
		  ad_cmd = latched_cmd_lcl;
		  ad_id = latched_id_lcl;
		  //id_fifo_en = 1'b1;
		  //id_fifo_in = {latched_bank_lcl,fe_id};
	       end // case: 2'b10
	       2'b11:  begin
		  bank_dec_NS =  DEC_ACTIVE;
		  ad_req = 1'b1;
		  ad_priority = ad_priority_q + 1'b1;
		  ad_cmd = fe_cmd;
		  case(decoder_type)
		    1'b0: begin //BRC
		       ad_bank = fe_addr[$clog2(DRAM_BANKS) + ROW_ADDR_WIDTH +
					 COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					 - 4: ROW_ADDR_WIDTH + COL_ADDR_WIDTH +
					 $clog2(DRAM_BUS_WIDTH) - 3];
		       ad_row = fe_addr[ROW_ADDR_WIDTH + COL_ADDR_WIDTH +
					$clog2(DRAM_BUS_WIDTH) - 4:
					COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					- 3];
		       ad_col = fe_addr[COL_ADDR_WIDTH +$clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b0
		    1'b1: begin // RBC
		       ad_row = fe_addr[ROW_ADDR_WIDTH + $clog2(DRAM_BANKS) +
					COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BANKS) + COL_ADDR_WIDTH +
					$clog2(DRAM_BUS_WIDTH) - 3];
		       ad_bank = fe_addr[$clog2(DRAM_BANKS) + COL_ADDR_WIDTH +
					 $clog2(DRAM_BUS_WIDTH) - 4:
					 COL_ADDR_WIDTH + $clog2(DRAM_BUS_WIDTH)
					 - 3];
		       ad_col = fe_addr[COL_ADDR_WIDTH +$clog2(DRAM_BUS_WIDTH)
					- 4: $clog2(DRAM_BUS_WIDTH) - 3];
		    end // case: 1'b1
		  endcase // case (decoder_type)
		  ord_fifo_en = 1'b1;
		  {ord_fifo_in,ad_id} = {ad_bank,fe_id};
	       end // case: 2'b11
	     endcase // case ({fe_req,|bm_ack})
	  end // case: DEC_ACTIVE
	  DEC_BUSY: begin
	     //ad_stall= 1'b1;
	     if(bm_ack == '1)
	       begin
		  ad_req = 1'b1;
		  ad_priority = ad_priority_q + 1'b1;
		  bank_dec_NS =  DEC_ACTIVE;
		  ord_fifo_en = 1'b1;
	       end
	     ad_row = latched_row_q;
	     ad_col = latched_col_q;
	     ad_bank = latched_bank_q;
	     ad_cmd = latched_cmd_q;
	     {ord_fifo_in,ad_id} = {latched_bank_q,latched_id_q};
	  end // case: DEC_BUSY
	endcase // case (bank_dec_CS)
     end */// always_comb

   /************************ END Addr Decoder FSM *****************************/

   /************************** Rank Machine FSM *******************************/

   typedef enum logic [2:0] {
			     RM_START_INIT = 0,
			     RM_ACTIVE,
			     RM_ACTIVE_PWR_DOWN,
			     RM_START_AREF,
			     RM_PRE_PWR_DOWN,
			     RM_SELF_REFRESH,
			     RM_IDLE
			     } CMD_MASTER_FSM;
   CMD_MASTER_FSM  CS, NS;

   logic 	cmd_bypass;
   logic 	bm_en;
   logic [DRAM_BANKS-1:0] bm_idle;
   logic [DRAM_BANKS-1:0] bm_prechared;
   logic 		  rm_fsm_stall;


  always_ff @(posedge clk, negedge rst_n)
    begin
       if(rst_n == 1'b0)
	 begin
	    CS <= RM_START_INIT;
	 end
       else
	 begin
	    CS <= NS;
	 end
    end

   always_comb
     begin
	init_en = 1'b0;
	NS= CS;
	bm_en = 1'b0;
	rm_fsm_stall = 1'b0;
	cmd_bypass = 1'b0;
	start_aref = 1'b0;
	start_pre_aref = 1'b0;
	case(CS)
	  RM_START_INIT: begin
	     init_en = 1'b1;
	     rm_fsm_stall = 1'b1;
	     if(init_done)
	       NS = RM_ACTIVE;
	  end
	  RM_ACTIVE: begin
	     if(aref_req == 1'b1)
	       begin
		  //Deselect the bank machines and wait for them to be idle
		  bm_en = 1'b0;
		  rm_fsm_stall = 1'b1;
		  cmd_bypass = 1'b1;
		  if(&bm_prechared == 1'b1)
		    begin
		       NS = RM_START_AREF;
		       start_aref = 1'b1;
		    end
		  else
		    begin
		       NS =  RM_START_AREF;
		       start_pre_aref = 1'b1;
		    end
	       end // if (aref_req == 1'b1)
	     else
	       begin
		  bm_en = 1'b1;
		  NS = RM_ACTIVE;
			   end // else: !if(aref_req == 1'b1)
	  end // case: RM_ACTIVE
	  RM_START_AREF: begin
   	     if((pre_aref_done == 1'b1) /*&& (aref_req != 1'b1)*/)
	       begin
		  NS = RM_ACTIVE;
		  rm_fsm_stall = 1'b1;
	       end
	     else
	       begin
		  NS  = RM_START_AREF;
		  cmd_bypass = !(rg_ref.en || rg_req_q) || rm_pre_all; //1'b1;
		  // if rg_ref.en go low middle of row granular ref.
		  // rg_req_q will continue to be high until the row granular
		  // ref is finished.
		  rm_fsm_stall = 1'b1;
	       end
	  end // case: CMD_START_AREF
	  ////FIXME//  POWER DOWN STATES WILL BE ADDED LATER
	endcase // case (CS)
     end // always_comb

   /************************* END Rank Machine FSM ****************************/

   localparam PRIORITY_WIDTH = $clog2(BANK_FIFO_DEPTH*DRAM_BANKS);

   logic [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	  bm_addr;
   logic [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0] 	  bm_slot;
   logic [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 		  bm_priority;
   logic [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 		  bm_id;
   logic [DRAM_BANKS-1:0] 				  bm_act;
   logic [DRAM_BANKS-1:0] 				  bm_cas;
   logic [DRAM_BANKS-1:0] 				  bm_r_w;
   logic [DRAM_BANKS-1:0] 				  bm_pre;
   logic [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0] 	  bm_bank;
   logic 						  cmd_mux_act_ack;
   logic [$clog2(DRAM_BANKS)-1:0] 			  cmd_mux_act_grant;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_act_slot;
   logic 						  cmd_mux_cas_ack;
   logic [$clog2(DRAM_BANKS)-1:0] 			  cmd_mux_cas_grant;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_cas_slot;
   logic 						  cmd_mux_pre_ack;
   logic [$clog2(DRAM_BANKS)-1:0] 			  cmd_mux_pre_grant;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_pre_slot;
   logic 						  rm_stall_lcl,rm_stall;
   logic 						  rm_stall_1,rm_stall_2,rm_stall_3;
   logic 						  bm_en_q;
   logic 						  cmd_bypass_1,cmd_bypass_2, cmd_bypass_q;
   

   assign rm_stall_lcl = (read_stall || rm_fsm_stall || aref_incr_stack) && !rg_req;
   //typedef bit [$bits(dram_t_rm.CWL)-1:0] 		  CWL_TYPE;

   always_ff @(posedge clk, negedge rst_n)
    begin
       if(!rst_n)
	 begin
	    rm_stall_1 <= '0;
	    rm_stall_2 <= '0;
	    rm_stall <= '0;
	    bm_en_q <= '0;
	    cmd_bypass_1 <= '0;
	    cmd_bypass_q <= '0;
	 end
       else
	 begin
	    rm_stall_1 <= rm_stall_lcl;
	    rm_stall_2 <= rm_stall_1;
	    rm_stall_3 <= rm_stall_2;
	    rm_stall <= rm_stall_3;
	    bm_en_q <= bm_en;
	    cmd_bypass_1 <= cmd_bypass;
	    cmd_bypass_2 <= cmd_bypass_1;
	    cmd_bypass_q <= cmd_bypass_2;
	 end
    end

   genvar 						  i;
   generate
      for (i=0;i<DRAM_BANKS; i++)
	begin
	   ch_ctrl_bank_fsm
	     #(
	       .BANK_FIFO_DEPTH(BANK_FIFO_DEPTH),
	       .ROW_ADDR_WIDTH(ROW_ADDR_WIDTH),
	       .COL_ADDR_WIDTH(COL_ADDR_WIDTH),
	       .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
	       .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH),
	       .FE_CMD_WIDTH(FE_CMD_WIDTH),
	       .FE_WRITE(FE_WRITE),
	       .FE_ID_WIDTH(FE_ID_WIDTH),
	       .CLK_RATIO(CLK_RATIO),
	       .PRIORITY_WIDTH(PRIORITY_WIDTH),
	       .BANK_ID(i),
	       .DRAM_BANKS(DRAM_BANKS),
	       .RAS_DRAM_CYCLES_LOG2(RAS_DRAM_CYCLES_LOG2),
	       .RP_DRAM_CYCLES_LOG2(RP_DRAM_CYCLES_LOG2),
	       .WR2PRE_DRAM_CYCLES_LOG2(WR2PRE_DRAM_CYCLES_LOG2),
	       .RD2PRE_DRAM_CYCLES_LOG2(RD2PRE_DRAM_CYCLES_LOG2),
	       .RCD_DRAM_CYCLES_LOG2(RCD_DRAM_CYCLES_LOG2),
	       .RG_REF_NUM_ROW_PER_REF_LOG2(RG_REF_NUM_ROW_PER_REF_LOG2),
	       .CWL_LOG2(CWL_LOG2),
	       .BL_LOG2(BL_LOG2),
	       .RG_REF_NUM_ROW_PER_REF(RG_REF_NUM_ROW_PER_REF) // Reset value
	       )ctrl_bank_fsm
	     (
	      .rst_n(rst_n),
	      .clk(clk),
	      .ad_req(ad_req),
	      .ad_row(ad_row),
	      .ad_col(ad_col),
	      .ad_bank(ad_bank),
	      .ad_cmd(ad_cmd),
	      .ad_priority(ad_priority),
	      .ad_id(ad_id),
	      .bm_ack(bm_ack[i]),
	      .rm_pre_all(rm_pre_all),
	      .rm_pre_all_slot({$clog2(CLK_RATIO){1'b0}}),
	      .rm_stall(rm_stall_3 || rm_stall),
	      .bm_en(bm_en_q),
	      .rg_ref_start_addr(rg_ref.start_addr),
	      .rg_ref_end_addr(rg_ref.end_addr),
	      .rg_ref_num_row_per_ref(rg_ref.num_row_per_ref),
	      .rg_ref_ras_dram_clk_cycle(rg_ref.ras_dram_clk_cycle),
	      .rg_ref_rp_dram_clk_cycle(rg_ref.rp_dram_clk_cycle),
	      .rg_req(rg_req_q),//rg_req),
	      .rg_done(rg_done[i]),
	      .bm_idle(bm_idle[i]),
	      .bm_prechared(bm_prechared[i]),
	      .bm_addr(bm_addr[i]),
	      .bm_slot(bm_slot[i]),
	      .bm_priority(bm_priority[i]),
	      .bm_id(bm_id[i]),
	      .bm_act(bm_act[i]),
	      .bm_cas(bm_cas[i]),
	      .bm_r_w(bm_r_w[i]),
	      .bm_pre(bm_pre[i]),
	      .bm_bank(bm_bank[i]),
	      .cmd_mux_act_ack(cmd_mux_act_ack),
	      .cmd_mux_act_grant(cmd_mux_act_grant),
	      .cmd_mux_act_slot(cmd_mux_act_slot),
	      .cmd_mux_cas_ack(cmd_mux_cas_ack),
	      .cmd_mux_cas_grant(cmd_mux_cas_grant),
	      .cmd_mux_cas_slot(cmd_mux_cas_slot),
	      .cmd_mux_pre_ack(cmd_mux_pre_ack),
	      .cmd_mux_pre_grant(cmd_mux_pre_grant),
	      .cmd_mux_pre_slot(cmd_mux_pre_slot),
	      //.mc_config_bus(mc_config_bus),
	      .CWL(dram_t_rm.CWL),
	      .BL(dram_t_rm.BL),
	      //.dram_t_rm(dram_t_rm),
	      .dram_t_bm(dram_t_bm)
	      //.rg_ref(rg_ref),
	      );
	end
   endgenerate


   // The BANK, and ID of each incoming transaction is stored in this FIFO,
   // to ensure the order in strict CAS order
   logic next_id;
   logic ord_fifo_full_n;
   logic [$clog2(DRAM_BANKS)-1:0] ord_qu_bank;
   //logic [FE_ID_WIDTH-1:0] 		  ord_qu_id;
   logic [$clog2(DRAM_BANKS)-1:0] ord_fifo_out;

   generic_fifo #(
		  .DATA_WIDTH($clog2(DRAM_BANKS)/* + FE_ID_WIDTH*/),
		  .DATA_DEPTH(BANK_FIFO_DEPTH*DRAM_BANKS)
		  )
   ord_fifo (
	     .clk(clk),
	     .rst_n(rst_n),
	     .data_i(ord_fifo_in),
	     .valid_i(ord_fifo_en),// could use ad_req also.
	     .grant_o(ord_fifo_full_n),
	     .data_o(ord_fifo_out),
	     .valid_o(),
	     .grant_i(next_id && !aref_req /*&& !aref_incr_stack*/),
	     .test_mode_i(1'b0)
	     );

   assign ord_qu_bank = ord_fifo_out;
   //assign ord_qu_id    =  id_fifo_out[FE_ID_WIDTH-1:0];


   logic [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] priority_lcl;
   logic [PRIORITY_WIDTH-1:0] 		      not_srvd_earliest_req_lcl;
   logic [PRIORITY_WIDTH-1:0] 		      not_srvd_earliest_req_q;
   logic [PRIORITY_WIDTH-1:0] 		      not_srvd_earliest_act;
   logic [PRIORITY_WIDTH-1:0] 		      not_srvd_earliest_pre;
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] cmd_mux_addr;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] cmd_mux_bank;
`ifdef DDR4
   logic [CLK_RATIO-1:0] 			 cmd_mux_act_n;
`endif
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 cmd_mux_cmd;
   logic [CLK_RATIO-1:0] 			 cmd_mux_valid;
   logic [FE_ID_WIDTH-1:0] 			 cmd_mux_fe_id;
   logic 					 cmd_mux_fe_id_valid;
   logic 					 cmd_mux_write;
   logic 					 cmd_mux_read;

   logic [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	  bm_addr_lcl;
   logic [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0]  bm_slot_lcl;
   logic [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 	  bm_priority_lcl;
   logic [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 	  bm_id_lcl;
   logic [DRAM_BANKS-1:0] 			  bm_act_lcl;
   logic [DRAM_BANKS-1:0] 			  bm_cas_lcl;
   logic [DRAM_BANKS-1:0] 			  bm_r_w_lcl; // 1=read, 0=write
   logic [DRAM_BANKS-1:0] 			  bm_pre_lcl;
   logic [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0] bm_bank_lcl;
   logic [$clog2(CLK_RATIO)-1:0] 		  cmd_mux_cas_slot_stg3;


   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  begin
	     not_srvd_earliest_req_q <= '0;
	  end
	else
	  begin
	     if(!aref_incr_stack && bm_en && (|bm_act_lcl || |bm_cas_lcl || |bm_pre_lcl))
	       not_srvd_earliest_req_q <= not_srvd_earliest_req_lcl;
	  end
     end
   // FIXME: require priority arbiter
   priority_arbiter
     #(
       .PRIORITY_WIDTH(PRIORITY_WIDTH),
       .DATA_WIDTH(PRIORITY_WIDTH),
       .NR_INPUTS(DRAM_BANKS)
       )pre_req_arbiter
       (
	.priority_i(bm_priority_lcl),
	.data_i(bm_priority_lcl),
	.req(~bm_idle & {DRAM_BANKS{bm_en && !aref_incr_stack}}),
	.highest_priority(not_srvd_earliest_req_q),
	.data_o(not_srvd_earliest_req_lcl),
	.valid(),
	.grant()
	);
   assign not_srvd_earliest_act = not_srvd_earliest_req_q;
   assign not_srvd_earliest_pre = not_srvd_earliest_req_q;
   /*
   generate
    for(genvar i = 0; i<=7; i++)
    assign priority_lcl[i] = bm_priority[i] - not_srvd_earliest_req_q;
   endgenerate
   assign not_srvd_earliest_act = not_srvd_earliest_req_q;
   assign not_srvd_earliest_pre = not_srvd_earliest_req_q;

   lowest_nr_identifier_8
    #(
    .NR_WIDTH(PRIORITY_WIDTH)
    )highest_priority_selector
    (
    .nr(priority_lcl),
    .req('1),
    .lowest_nr(not_srvd_earliest_req_lcl),
    .lowest_line(),
    .lowest_valid()
    );*/


   			
    bankfsm_cmdmux_if
     #(
       .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
       .DRAM_BANKS(DRAM_BANKS),
       .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH),
       .CLK_RATIO(CLK_RATIO),
       .PRIORITY_WIDTH(PRIORITY_WIDTH),
       .FE_ID_WIDTH(FE_ID_WIDTH)
       ) bankfsm_cmdmux_if
       (
	.rst_n(rst_n),
	.clk(clk),
	.bm_addr(bm_addr),
	.bm_slot(bm_slot),
	.bm_priority(bm_priority),
	.bm_id(bm_id),
	.bm_act(bm_act),
	.bm_cas(bm_cas),
	.bm_r_w(bm_r_w),
	.bm_pre(bm_pre),
	.bm_bank(bm_bank),
	.bm_addr_o(bm_addr_lcl),
	.bm_slot_o(bm_slot_lcl),
	.bm_priority_o(bm_priority_lcl),
	.bm_id_o(bm_id_lcl),
	.bm_act_o(bm_act_lcl),
	.bm_cas_o(bm_cas_lcl),
	.bm_r_w_o(bm_r_w_lcl),
	.bm_pre_o(bm_pre_lcl),
	.bm_bank_o(bm_bank_lcl),
	.rm_stall(rm_stall_1 || rm_stall)
	);
      
   
   cmd_mux
     #(
       .DRAM_ADDR_WIDTH(DRAM_ADDR_WIDTH),
       .DRAM_BANKS(DRAM_BANKS),
       .DRAM_CMD_WIDTH(DRAM_CMD_WIDTH),
       .CLK_RATIO(CLK_RATIO),
       .PRIORITY_WIDTH(PRIORITY_WIDTH),
       .FE_ID_WIDTH(FE_ID_WIDTH),
       .CAS_EVEN_SLOT(CAS_EVEN_SLOT),
       .RRD_DRAM_CYCLES_LOG2(RRD_DRAM_CYCLES_LOG2),
       .CAS2CAS_DRAM_CYCLES_LOG2(CAS2CAS_DRAM_CYCLES_LOG2),
       .WR2RD_DRAM_CYCLES_LOG2(WR2RD_DRAM_CYCLES_LOG2),
       .RD2WR_DRAM_CYCLES_LOG2(RD2WR_DRAM_CYCLES_LOG2)
       /*******************DRAM timings in DRAM ck************************/
       /*RD_DRAM_CYCLES(RRD_DRAM_CYCLES),
	.WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
	.CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
	.CL(CL),
	.CWL(CWL),
	.TFAW_NS(TFAW_NS),
	.BL(BL)*/
       ) cmd_mux
       (
	.rst_n(rst_n),
	.clk(clk),
	.bm_addr(bm_addr_lcl),
	.bm_slot(bm_slot_lcl),
	.bm_priority(bm_priority_lcl),
	.bm_id(bm_id_lcl),
	.bm_act(bm_act_lcl),
	.bm_cas(bm_cas_lcl),
	.bm_r_w(bm_r_w_lcl),
	.bm_pre(bm_pre_lcl),
	.bm_bank(bm_bank_lcl),
	.not_srvd_earliest_act(rg_req_q ? 6'd0:not_srvd_earliest_act),
	.not_srvd_earliest_pre(rg_req_q ? 6'd0:not_srvd_earliest_pre),
	.ord_qu_bank(ord_qu_bank),
	.next_id(next_id),
	.rm_stall(rm_stall),
	.bm_en(bm_en),
	.cmd_mux_act_ack(cmd_mux_act_ack),
	.cmd_mux_act_grant(cmd_mux_act_grant),
	.cmd_mux_act_slot(cmd_mux_act_slot),
	.cmd_mux_cas_ack(cmd_mux_cas_ack),
	.cmd_mux_cas_grant(cmd_mux_cas_grant),
	.cmd_mux_cas_slot(cmd_mux_cas_slot),
	.cmd_mux_pre_ack(cmd_mux_pre_ack),
	.cmd_mux_pre_grant(cmd_mux_pre_grant),
	.cmd_mux_pre_slot(cmd_mux_pre_slot),
	.cmd_mux_addr(cmd_mux_addr),
	.cmd_mux_bank(cmd_mux_bank),
`ifdef DDR4
	.cmd_mux_act_n(cmd_mux_act_n),
`endif
	.cmd_mux_cmd(cmd_mux_cmd),
	.cmd_mux_valid(cmd_mux_valid),
	.cmd_mux_fe_id(cmd_mux_fe_id),
	.cmd_mux_fe_id_valid(cmd_mux_fe_id_valid),
	.cmd_mux_write(cmd_mux_write),
	.cmd_mux_read(cmd_mux_read),
	.cmd_mux_cas_slot_stg3(cmd_mux_cas_slot_stg3),
	.dram_t_rm(dram_t_rm)
	);

   /***************************** output assignment**********************/
   /*logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0]    rm_addr_lcl;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] rm_bank_lcl;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	 rm_cmd_lcl;
   logic 					 rm_valid_lcl;
   logic [FE_ID_WIDTH-1:0] 			 rm_cas_cmd_id_lcl;
   logic 					 rm_cas_cmd_id_valid_lcl;//not req
   logic 					 rm_write_lcl;
   logic 					 rm_read_lcl;
   logic [$clog2(CLK_RATIO)-1:0] 		 rm_cas_slot_lcl;

   // added to fix timing issues from phy interface. if cmd_bypass was reg then
   // the below code is not required. Check this in next version.
   always_ff @(posedge clk, negedge rst_n) begin
      if(rst_n == 1'b0) begin
	 rm_addr <= '0;
	 rm_bank <= '0;
	 rm_cmd <= '0;
	 rm_valid <= '0;
	 rm_cas_cmd_id <= '0;
	 rm_cas_cmd_id_valid <= '0;
	 rm_write <= '0;
	 rm_read <= '0;
	 rm_cas_slot <= '0;
      end // if (rst_n == 1'b0)
      else begin
	 rm_addr <= rm_addr_lcl;
	 rm_bank <= rm_bank_lcl;
	 rm_cmd <= rm_cmd_lcl;
	 rm_valid <= rm_valid_lcl;
	 rm_cas_cmd_id <= rm_cas_cmd_id_lcl;
	 rm_cas_cmd_id_valid <= rm_cas_cmd_id_valid_lcl;
	 rm_write <= rm_write_lcl;
	 rm_read <= rm_read_lcl;
	 rm_cas_slot <= rm_cas_slot_lcl;
      end // else: !if(rst_n == 1'b0)
   end // always_ff @ (posedge clk, negedge rst_n)*/

      // if above ff is used add _lcl to all rm variables in below assign
   assign fe_stall = ad_stall || (!ord_fifo_full_n);
   assign rm_addr = cmd_bypass_q?{{DRAM_ADDR_WIDTH{1'b0}},
				{DRAM_ADDR_WIDTH{1'b0}},
				{DRAM_ADDR_WIDTH{1'b0}},
				pre_aref_addr}:cmd_mux_addr;
   assign rm_bank = cmd_bypass_q?0:cmd_mux_bank;
   assign rm_cmd = cmd_bypass_q?{NOP,NOP,NOP,pre_aref_cmd}:cmd_mux_cmd;
`ifdef DDR4
   assign rm_act_n = cmd_bypass_q?'1:cmd_mux_act_n;   
`endif
   assign rm_valid = !init_en;
   assign rm_cas_cmd_id = cmd_mux_fe_id;
   assign rm_cas_cmd_id_valid = rm_valid && cmd_mux_fe_id_valid;
   assign rm_write = cmd_mux_write;
   assign rm_read = cmd_mux_read;
   assign rm_cas_slot = cmd_mux_cas_slot_stg3;
   assign rm_fsm_state = {'0/*bank_dec_CS*/,PRE_AREF_CS,CS};// bank decoder doesn't exsist

endmodule

