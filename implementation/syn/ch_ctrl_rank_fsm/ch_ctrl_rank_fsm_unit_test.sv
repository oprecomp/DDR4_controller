`timescale 1ns/1ps
`include "svunit_defines.svh"
`include "ch_ctrl_rank_fsm.sv"
`include "util/clk_and_reset.svh"
`include "ch_ctrl_bank_fsm.sv"
`include "cmd_mux.sv"
`include "lowest_nr_identifier.sv"
`include "mux_8_1.sv"
`include "slot_combin.sv"
`include "demux_1_4.sv"
`include "priority_arbiter.sv"
`include "comp_sel.sv"
`include "generic_fifo.sv"
`include "pulp_clock_gating.sv"


module ch_ctrl_rank_fsm_unit_test;
  import svunit_pkg::svunit_testcase;

  string name = "ch_ctrl_rank_fsm_ut";
  svunit_testcase svunit_ut;


  //===================================
  // This is the UUT that we're
  // running the Unit Tests on
  //===================================

   localparam FE_ADDR_WIDTH = 28;
   localparam FE_CMD_WIDTH = 1;
   localparam FE_ID_WIDTH = 8;
   localparam DRAM_ADDR_WIDTH = 15;
   localparam DRAM_CMD_WIDTH = 5;
   localparam DRAM_BANKS = 8;
   localparam CLK_RATIO = 4;
   localparam RRD_DRAM_CYCLES = 4;
   localparam WTR_DRAM_CYCLES = 4;
   localparam CCD_DRAM_CYCLES = 4;
   localparam CL = 6;
   localparam CWL = 5;
   localparam BL = 8;
   parameter RP_DRAM_CYCLES = 6;
   parameter RTP_DRAM_CYCLES = 4;
   parameter WR_DRAM_CYCLES = 6;
   parameter RCD_DRAM_CYCLES = 6;
   parameter RAS_DRAM_CYCLES = 15;
   localparam WR2RD_DRAM_CYCLES = WTR_DRAM_CYCLES + CWL + (BL/2);
   localparam RD2WR_DRAM_CYCLES = CL + CCD_DRAM_CYCLES + 2 - CWL;
   localparam WR2PRE_DRAM_CYCLES = WR_DRAM_CYCLES + CWL + (BL/2);
   localparam RD2PRE_DRAM_CYCLES = RTP_DRAM_CYCLES;
   localparam ACT2PRE_DRAM_CYCLES = RAS_DRAM_CYCLES;
   localparam PRE2ACT_DRAM_CYCLES = RP_DRAM_CYCLES;
   localparam ACT2CAS_DRAM_CYCLES = RRD_DRAM_CYCLES;
   localparam NOP = 5'b10111;
   localparam ACT = 5'b10011;
   localparam PRE = 5'b10010;
   localparam WR = 5'b10100;
   localparam RD = 5'b10101;

   //logic rst_n;
   logic fe_req;
   logic [FE_CMD_WIDTH-1:0] fe_cmd;
   logic [FE_ADDR_WIDTH-1:0] fe_addr;
   logic [FE_ID_WIDTH-1:0] 	 fe_id;
   logic 						 fe_stall;
   // stall from wrapper
   logic 						 read_stall;
   logic 						 init_done;
   logic 						 init_en;
   // to phy
   logic [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] rm_addr;
   logic [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] rm_bank;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	  rm_cmd;
   logic 										  rm_valid;
   logic [FE_ID_WIDTH-1:0] 					  rm_cas_cmd_id;
   logic 										  rm_cas_cmd_id_valid;
   logic 										  rm_write;
   logic [$clog2(CLK_RATIO)-1:0] 				  rm_write_slot;
   logic 										  decoder_type;

   `CLK_RESET_FIXTURE(5, 20);

   ch_ctrl_rank_fsm my_ch_ctrl_rank_fsm(.*);


  //===================================
  // Build
  //===================================
  function void build();
    svunit_ut = new(name);
  endfunction


  //===================================
  // Setup for running the Unit Tests
  //===================================
  task setup();
    svunit_ut.setup();
    /* Place Setup Code Here */

  endtask


  //===================================
  // Here we deconstruct anything we
  // need after running the Unit Tests
  //===================================
  task teardown();
    svunit_ut.teardown();
    /* Place Teardown Code Here */

  endtask

   initial begin
			#0 rst_n = 0;
			#20;
			forever begin
			   rst_n = 1;
			   step();
			end
   end

   assign decoder_type = 0;
   logic random;
   logic [31:0] j;
   always_ff @(posedge clk, negedge rst_n)
	 begin
		if(rst_n == 1'b0)
		  begin
			 fe_cmd <= '0;
			 fe_addr <= '0;
			 fe_id <= '0;
			 fe_req <= '0;
			 read_stall <= 1'b0;
			 random <= 1'b0;
			 j<= '0;
		  end
		else
		  begin
			 j<= (j=='1)?j:j+1;
			 fe_cmd <= fe_stall?fe_cmd:$random();
			 fe_addr[FE_ADDR_WIDTH-3-1:0] <= fe_stall?fe_addr[FE_ADDR_WIDTH-3-1:0]:$random();
			 random <= ((j>200)&&(j<800))?0:$random();
			 fe_addr[FE_ADDR_WIDTH-1:FE_ADDR_WIDTH-3] <= fe_stall||(!random)?
														 fe_addr[FE_ADDR_WIDTH-1:
																 FE_ADDR_WIDTH-3]:
														 fe_addr[FE_ADDR_WIDTH-1:
																 FE_ADDR_WIDTH-3]+1;
			 fe_id <= fe_stall||(!random)?fe_id:fe_id+1;
			 fe_req <= random;
			 read_stall <= 0;//$random();
		  end // else: !if(rst_n == 1'b0)
	 end // always_ff @ (posedge clk, negedge rst_n)

   //to reuse the timing checker of cmd mux UT
   logic [CLK_RATIO-1:0] write4, read4, act4, pre4, wr_or_rd;
   logic [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0]  cmd_mux_cmd;
   logic 									  cmd_mux_act_ack;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_act_slot;
   logic 									  cmd_mux_cas_ack;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_cas_slot;
   logic 									  cmd_mux_pre_ack;
   logic [$clog2(CLK_RATIO)-1:0] 			  cmd_mux_pre_slot;
   logic [6:0] 							  prev_cas2cas_cnt;
   logic [6:0] 							  prev_act2act_cnt;
   logic [6:0] 							  prev_wr2rd_cnt;
   logic [6:0] 							  prev_rd2wr_cnt;
   logic [7:0][6:0] 						  prev_wr2pre_cnt;
   logic [7:0][6:0] 						  prev_rd2pre_cnt;
   logic [7:0][6:0] 						  prev_act2pre_cnt;
   logic [7:0][6:0] 						  prev_pre2act_cnt;
   logic [7:0][6:0] 						  prev_act2cas_cnt;

   assign cmd_mux_cmd = rm_cmd;
   assign act4 = {(cmd_mux_cmd[3] == ACT),(cmd_mux_cmd[2] == ACT),
				 (cmd_mux_cmd[1] == ACT),(cmd_mux_cmd[0] == ACT)};
   assign pre4 = {(cmd_mux_cmd[3] == PRE),(cmd_mux_cmd[2] == PRE),
				 (cmd_mux_cmd[1] == PRE),(cmd_mux_cmd[0] == PRE)};
   assign write4 = {(cmd_mux_cmd[3] == WR),(cmd_mux_cmd[2] == WR),
				   (cmd_mux_cmd[1] == WR),(cmd_mux_cmd[0] == WR)};
   assign read4 = {(cmd_mux_cmd[3] == RD),(cmd_mux_cmd[2] == RD),
				   (cmd_mux_cmd[1] == RD),(cmd_mux_cmd[0] == RD)};
   assign wr_or_rd = write4 | read4;

   assign cmd_mux_act_ack = init_en?0:((cmd_mux_cmd[0] == ACT)||
								  (cmd_mux_cmd[1] == ACT)||
								  (cmd_mux_cmd[2] == ACT)||
									   (cmd_mux_cmd[3] == ACT));
   assign cmd_mux_pre_ack = init_en?0:((cmd_mux_cmd[0] == PRE)||
								  (cmd_mux_cmd[1] == PRE)||
								  (cmd_mux_cmd[2] == PRE)||
									   (cmd_mux_cmd[3] == PRE));
   assign cmd_mux_cas_ack = init_en?0:((|read4) || (|write4));
   assign cmd_mux_act_slot = $clog2(act4);
   assign cmd_mux_pre_slot = $clog2(pre4);
   assign cmd_mux_cas_slot = $clog2(wr_or_rd);

    initial begin
	  #0 init_done = 0;
	  #1600 init_done = 1;
	  #1000000 $finish;
   end

   //***********Timing checker************************
   always_ff @(posedge clk, negedge rst_n)
	 begin
		if(rst_n == 1'b0) begin
		   prev_cas2cas_cnt <= -5;
		end
		else begin
		   if(cmd_mux_cas_ack) begin
			  if((prev_cas2cas_cnt + cmd_mux_cas_slot) < CCD_DRAM_CYCLES)
				$stop;
			  prev_cas2cas_cnt <= CLK_RATIO - cmd_mux_cas_slot;
		   end
		   else begin
			  if(prev_cas2cas_cnt < CCD_DRAM_CYCLES)
				prev_cas2cas_cnt <= prev_cas2cas_cnt + 4;
		   end // else: !if((bm_cas & 64) == 64)
		end // else: !if(rst_n == 1'b0)
	 end // always_ff @ (posedge clk, negedge rst_n)


	 //ACT2ACT
   always_ff @(posedge clk, negedge rst_n)
	 begin
		if(rst_n == 1'b0) begin
		   prev_act2act_cnt <= -5;
		end
		else begin
		   if(cmd_mux_act_ack) begin
			  if((prev_act2act_cnt + cmd_mux_act_slot) < RRD_DRAM_CYCLES)
				$stop;
			  prev_act2act_cnt <= CLK_RATIO - cmd_mux_act_slot;
		   end
		   else begin
			  if(prev_act2act_cnt < RRD_DRAM_CYCLES)
				prev_act2act_cnt <= prev_act2act_cnt + 4;
		   end // else: !if((bm_cas & 64) == 64)
		end // else: !if(rst_n == 1'b0)
	 end // always_ff @ (posedge clk, negedge rst_n)

   //WR2RD
   always_ff @(posedge clk, negedge rst_n)
	 begin
		if(rst_n == 1'b0) begin
		   prev_wr2rd_cnt <= -5;
		end
		else begin
		   if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 20)||
								  (cmd_mux_cmd[1] == 20)||
								  (cmd_mux_cmd[2] == 20)||
								  (cmd_mux_cmd[3] == 20))) begin
			  prev_wr2rd_cnt <= CLK_RATIO - cmd_mux_cas_slot;
		   end
		   else begin
			  if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 21)||
									 (cmd_mux_cmd[1] == 21)||
									 (cmd_mux_cmd[2] == 21)||
									 (cmd_mux_cmd[3] == 21)))
				if((prev_wr2rd_cnt + cmd_mux_cas_slot) < WR2RD_DRAM_CYCLES)
				  $stop;
			  if(prev_wr2rd_cnt < WR2RD_DRAM_CYCLES)
				prev_wr2rd_cnt <= prev_wr2rd_cnt + 4;
		   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
		end // else: !if(rst_n == 1'b0)
	 end // always_ff @ (posedge clk, negedge rst_n)

   //RD2WR
   always_ff @(posedge clk, negedge rst_n)
	 begin
		if(rst_n == 1'b0) begin
		   prev_rd2wr_cnt <= -5;
		end
		else begin
		   if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 21)||
								  (cmd_mux_cmd[1] == 21)||
								  (cmd_mux_cmd[2] == 21)||
								  (cmd_mux_cmd[3] == 21))) begin
			  prev_rd2wr_cnt <= CLK_RATIO - cmd_mux_cas_slot;
		   end
		   else begin
			  if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 20)||
									 (cmd_mux_cmd[1] == 20)||
									 (cmd_mux_cmd[2] == 20)||
									 (cmd_mux_cmd[3] == 20)))
				if((prev_rd2wr_cnt + cmd_mux_cas_slot) < RD2WR_DRAM_CYCLES)
				  $stop;
			  if(prev_rd2wr_cnt < RD2WR_DRAM_CYCLES)
				prev_rd2wr_cnt <= prev_rd2wr_cnt + 4;
		   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
		end // else: !if(rst_n == 1'b0)
	 end // always_ff @ (posedge clk, negedge rst_n)

   //wr2pre
   genvar i;
   generate
	  for (i=0;i<DRAM_BANKS; i++)
		begin
		   always_ff @(posedge clk, negedge rst_n)
			 begin
				if(rst_n == 1'b0) begin
				   prev_wr2pre_cnt[i] <= -5;
				end
				else begin
				   if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 20)||
										  (cmd_mux_cmd[1] == 20)||
										  (cmd_mux_cmd[2] == 20)||
										  (cmd_mux_cmd[3] == 20)) &&
					  (rm_bank[cmd_mux_cas_slot] == i)) begin
					  prev_wr2pre_cnt[i] <= CLK_RATIO - cmd_mux_cas_slot;
				   end
				   else begin
					  if(cmd_mux_pre_ack && (rm_bank[cmd_mux_pre_slot] == i))
						if((prev_wr2pre_cnt[i] + cmd_mux_pre_slot) < WR2PRE_DRAM_CYCLES)
						  $stop;
					  if(prev_wr2pre_cnt[i] < WR2PRE_DRAM_CYCLES)
						prev_wr2pre_cnt[i] <= prev_wr2pre_cnt[i] + 4;
				   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
				end // else: !if(rst_n == 1'b0)
			 end // always_ff @ (posedge clk, negedge rst_n)
		   always_ff @(posedge clk, negedge rst_n)
			 begin
				if(rst_n == 1'b0) begin
				   prev_rd2pre_cnt[i] <= -5;
				end
				else begin
				   if(cmd_mux_cas_ack && ((cmd_mux_cmd[0] == 21)||
										  (cmd_mux_cmd[1] == 21)||
										  (cmd_mux_cmd[2] == 21)||
										  (cmd_mux_cmd[3] == 21)) &&
					  (rm_bank[cmd_mux_cas_slot] == i)) begin
					  prev_rd2pre_cnt[i] <= CLK_RATIO - cmd_mux_cas_slot;
				   end
				   else begin
					  if(cmd_mux_pre_ack && (rm_bank[cmd_mux_pre_slot] == i))
						if((prev_rd2pre_cnt[i] + cmd_mux_pre_slot) < RD2PRE_DRAM_CYCLES)
						  $stop;
					  if(prev_rd2pre_cnt[i] < RD2PRE_DRAM_CYCLES)
						prev_rd2pre_cnt[i] <= prev_rd2pre_cnt[i] + 4;
				   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
				end // else: !if(rst_n == 1'b0)
			 end // always_ff @ (posedge clk, negedge rst_n)
		   always_ff @(posedge clk, negedge rst_n)
			 begin
				if(rst_n == 1'b0) begin
				   prev_act2pre_cnt[i] <= -5;
				end
				else begin
				   if(cmd_mux_act_ack && (rm_bank[cmd_mux_act_slot] == i)) begin
					  prev_act2pre_cnt[i] <= CLK_RATIO - cmd_mux_act_slot;
				   end
				   else begin
					  if(cmd_mux_pre_ack && (rm_bank[cmd_mux_pre_slot] == i))
						if((prev_act2pre_cnt[i] + cmd_mux_pre_slot) < ACT2PRE_DRAM_CYCLES)
						  $stop;
					  if(prev_act2pre_cnt[i] < ACT2PRE_DRAM_CYCLES)
						prev_act2pre_cnt[i] <= prev_act2pre_cnt[i] + 4;
				   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
				end // else: !if(rst_n == 1'b0)
			 end // always_ff @ (posedge clk, negedge rst_n)
		   always_ff @(posedge clk, negedge rst_n)
			 begin
				if(rst_n == 1'b0) begin
				   prev_act2cas_cnt[i] <= -5;
				end
				else begin
				   if(cmd_mux_act_ack && (rm_bank[cmd_mux_act_slot] == i)) begin
					  prev_act2cas_cnt[i] <= CLK_RATIO - cmd_mux_act_slot;
				   end
				   else begin
					  if(cmd_mux_cas_ack && (rm_bank[cmd_mux_cas_slot] == i))
						if((prev_act2cas_cnt[i] + cmd_mux_cas_slot) < ACT2CAS_DRAM_CYCLES)
						  $stop;
					  if(prev_act2cas_cnt[i] < ACT2CAS_DRAM_CYCLES)
						prev_act2cas_cnt[i] <= prev_act2cas_cnt[i] + 4;
				   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
				end // else: !if(rst_n == 1'b0)
			 end // always_ff @ (posedge clk, negedge rst_n)
		   always_ff @(posedge clk, negedge rst_n)
			 begin
				if(rst_n == 1'b0) begin
				   prev_pre2act_cnt[i] <= -5;
				end
				else begin
				   if(cmd_mux_pre_ack && (rm_bank[cmd_mux_pre_slot] == i)) begin
					  prev_pre2act_cnt[i] <= CLK_RATIO - cmd_mux_pre_slot;
				   end
				   else begin
					  if(cmd_mux_act_ack && (rm_bank[cmd_mux_act_slot] == i))
						if((prev_pre2act_cnt[i] + cmd_mux_act_slot) < PRE2ACT_DRAM_CYCLES)
						  $stop;
					  if(prev_pre2act_cnt[i] < PRE2ACT_DRAM_CYCLES)
						prev_pre2act_cnt[i] <= prev_pre2act_cnt[i] + 4;
				   end // else: !if(cmd_mux_act_ack && ((cmd_mux_cmd[0] == 20)||...
				end // else: !if(rst_n == 1'b0)
			 end // always_ff @ (posedge clk, negedge rst_n)
		end // for (i=0;i<DRAM_BANKS; i++)
	  endgenerate

  //===================================
  // All tests are defined between the
  // SVUNIT_TESTS_BEGIN/END macros
  //
  // Each individual test must be
  // defined between `SVTEST(_NAME_)
  // `SVTEST_END
  //
  // i.e.
  //   `SVTEST(mytest)
  //     <test code>
  //   `SVTEST_END
  //===================================
  `SVUNIT_TESTS_BEGIN
	  //#0 init_done = 0;
	  //#1600 init_done = 1;
	  //#5000 $finish;
	`SVTEST(no_same_cmd_in_slot)
       #1;
       forever begin
		  //$display("%d\t %h\n",act4,rm_cmd);
		  `FAIL_IF((act4 !== 0)&&(act4 !== 4'b0001)&&(act4 !== 4'b0010)&&
				   (act4 !== 4'b0100)&&(act4 !== 4'b1000));
		  //$display("%d\t %h\n",act4,rm_cmd);
		  `FAIL_IF((pre4 !== 0)&&(pre4 !== 4'b0001)&&(pre4 !== 4'b0010)&&
				   (pre4 !== 4'b0100)&&(pre4 !== 4'b1000));
		  `FAIL_IF((wr_or_rd !== 0)&&(wr_or_rd !== 4'b0001)&&
				   (wr_or_rd !== 4'b0010)&&(wr_or_rd !== 4'b0100)&&
				   (wr_or_rd !== 4'b1000));
		  step();
	   end // forever begin
   `SVTEST_END


  `SVUNIT_TESTS_END

endmodule
