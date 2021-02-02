module bankfsm_cmdmux_if
  #(
    parameter DRAM_ADDR_WIDTH = 15,
    parameter DRAM_BANKS = 8,
    parameter DRAM_CMD_WIDTH = 5,
    parameter CLK_RATIO = 4,
    parameter PRIORITY_WIDTH = 6,
    parameter FE_ID_WIDTH = 8
    )
   (
    input 						  clk,
    input 						  rst_n,
    input [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	  bm_addr,
    input [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0] 	  bm_slot,
    input [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 		  bm_priority,
    input [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 		  bm_id,
    input [DRAM_BANKS-1:0] 				  bm_act,
    input [DRAM_BANKS-1:0] 				  bm_cas,
    input [DRAM_BANKS-1:0] 				  bm_r_w, // 1=read, 0=write
    input [DRAM_BANKS-1:0] 				  bm_pre,
    input [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0] 	  bm_bank,
    input 						  rm_stall, 
    /*input 					    cmd_mux_act_ack,
    input [$clog2(DRAM_BANKS)-1:0] 		    cmd_mux_act_grant,
    input [$clog2(CLK_RATIO)-1:0] 		    cmd_mux_act_slot,
    input 					    cmd_mux_cas_ack,
    input [$clog2(DRAM_BANKS)-1:0] 		    cmd_mux_cas_grant,
    input [$clog2(CLK_RATIO)-1:0] 		    cmd_mux_cas_slot,
    input 					    cmd_mux_pre_ack,
    input [$clog2(DRAM_BANKS)-1:0] 		    cmd_mux_pre_grant,
    input [$clog2(CLK_RATIO)-1:0] 		    cmd_mux_pre_slot,*/
    output logic [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	  bm_addr_o,
    output logic [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0]  bm_slot_o,
    output logic [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 	  bm_priority_o,
    output logic [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 	  bm_id_o,
    output logic [DRAM_BANKS-1:0] 			  bm_act_o,
    output logic [DRAM_BANKS-1:0] 			  bm_cas_o,
    output logic [DRAM_BANKS-1:0] 			  bm_r_w_o, // 1=read, 0=write
    output logic [DRAM_BANKS-1:0] 			  bm_pre_o,
    output logic [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0] bm_bank_o
    );

   /*logic [DRAM_BANKS-1:0][DRAM_ADDR_WIDTH-1:0] 	    bm_addr_q;
   logic [DRAM_BANKS-1:0][$clog2(CLK_RATIO)-1:0]    bm_slot_q;
   logic [DRAM_BANKS-1:0][PRIORITY_WIDTH-1:0] 	    bm_priority_q;
   logic [DRAM_BANKS-1:0][FE_ID_WIDTH-1:0] 	    bm_id_q;
   logic [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0]   bm_bank_q;
   logic [DRAM_BANKS-1:0] 			    bm_cas_q;
   logic [DRAM_BANKS-1:0] 			    bm_r_w_q; // 1=read, 0=write
   logic [DRAM_BANKS-1:0] 			    bm_pre_q;
   logic [DRAM_BANKS-1:0][$clog2(DRAM_BANKS)-1:0]   bm_bank_q;*/
   

    always_ff @(posedge clk, negedge rst_n)
      begin
	 if(rst_n == 1'b0)
	   begin
	      bm_addr_o <='0;
	      bm_slot_o <='0;
     	      bm_priority_o <='0;
     	      bm_id_o <='0;
     	      bm_act_o <='0;
    	      bm_cas_o <='0;
    	      bm_r_w_o <='0; // 1=read, 0=write
    	      bm_pre_o <='0;
	      bm_bank_o <='0;
	   end // if (rst_n == 1'b0)
	 else
	   begin
	      bm_addr_o <=bm_addr;
	      bm_slot_o <=bm_slot;
     	      bm_priority_o <=bm_priority;
     	      bm_id_o <=bm_id;
     	      bm_act_o <=bm_act & {DRAM_BANKS{!rm_stall}};
    	      bm_cas_o <=bm_cas & {DRAM_BANKS{!rm_stall}};
    	      bm_r_w_o <=bm_r_w; // 1=read, 0=write
    	      bm_pre_o <=bm_pre & {DRAM_BANKS{!rm_stall}};
	      bm_bank_o <= bm_bank;
	   end // else: !if(rst_n == 1'b0)
      end // always_ff @ (posedge clk, negedge rst_n)
   
endmodule // bankfsm_cmdmux_if



   
