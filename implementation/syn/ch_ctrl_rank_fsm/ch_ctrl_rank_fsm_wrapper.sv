module ch_ctrl_rank_fsm_wrapper
  #(
    parameter BANK_FIFO_DEPTH = 8,
    parameter ROW_ADDR_WIDTH = 15,
    parameter COL_ADDR_WIDTH = 10,
    parameter DRAM_ADDR_WIDTH = 15,
    parameter DRAM_CMD_WIDTH = 5,
    parameter DRAM_BANKS = 8,
    parameter DRAM_BUS_WIDTH = 8,
    parameter FE_ADDR_WIDTH = 28,
    parameter FE_CMD_WIDTH = 1,
    parameter FE_ID_WIDTH = 8,
    parameter FE_WRITE = 0,
    parameter CLK_RATIO = 4,
    parameter AREF_CNT_WIDTH = 16,
    parameter RFC_DRAM_CYCLES_LOG2 = 9,
    parameter RC_DRAM_CYCLES_LOG2 = 6,
    parameter RAS_DRAM_CYCLES_LOG2 = 6,
    parameter RP_DRAM_CYCLES_LOG2 = 4,
    parameter WR2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RD2PRE_DRAM_CYCLES_LOG2 = 8,
    parameter RCD_DRAM_CYCLES_LOG2 = 4,
    parameter RRD_DRAM_CYCLES_LOG2 = 4,
    parameter WR2RD_DRAM_CYCLES_LOG2 = 8,
    parameter RD2WR_DRAM_CYCLES_LOG2 = 8,
    parameter ZQS_DRAM_CYCLES_LOG2 = 7,
    parameter ZQSI_TREFI_CYCLES = 128 //1ms=128*tREFI. assumption:tREFI = 7.8
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
	// from wrapper
    input 					   read_stall,
    input 					   init_done,
    output logic 				   init_en,
    //****************** SIGNALS TO THE PHY ***********************
    output [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0]    rm_addr,
    output [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] rm_bank,
    output [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	   rm_cmd,
    output 					   rm_valid,
    output [FE_ID_WIDTH-1:0] 			   rm_cas_cmd_id,
    output 					   rm_cas_cmd_id_valid,//not req
    output 					   rm_write,
    output 					   rm_read,
    output [$clog2(CLK_RATIO)-1:0] 		   rm_cas_slot,
    //**************** CONFIG & TIMING INPUTS ***********************
    input 					   decoder_type,
    input 					   rg_en,
    input [3:0] 				   RP_DRAM_CYCLES,
    input [3:0] 				   RTP_DRAM_CYCLES,
    input [4:0] 				   WR_DRAM_CYCLES,
    input [3:0] 				   RCD_DRAM_CYCLES,
    input [5:0] 				   RAS_DRAM_CYCLES,

    input [2:0] 				   CCD_DRAM_CYCLES, // ccd always 4 for DDR3, Required for DDR4
    input [3:0] 				   WTR_DRAM_CYCLES, // wr max 7.5 ns for DDR3
    input [3:0] 				   RRD_DRAM_CYCLES, //same as WTR
    input [15:0] 				   AREF_DRAM_CYCLES,
    input [8:0] 				   RFC_DRAM_CYCLES,
    input [5:0] 				   FAW_DRAM_CYCLES,
    input [6:0] 				   ZQS_DRAM_CYCLES,
    input [3:0] 				   BL,
    input [3:0] 				   CWL,
    input [3:0] 				   CL
    );

   dram_global_timing_if dram_t_rm();
   dram_bank_timing_if dram_t_bm();

   assign dram_t_bm.RP_DRAM_CYCLES = RP_DRAM_CYCLES;
   assign dram_t_bm.RTP_DRAM_CYCLES = RTP_DRAM_CYCLES;
   assign dram_t_bm.WR_DRAM_CYCLES = WR_DRAM_CYCLES;
   assign dram_t_bm.RCD_DRAM_CYCLES = RCD_DRAM_CYCLES;
   assign dram_t_bm.RAS_DRAM_CYCLES = RAS_DRAM_CYCLES;
   assign dram_t_rm.CCD_DRAM_CYCLES = CCD_DRAM_CYCLES;
   assign dram_t_rm.WTR_DRAM_CYCLES = WTR_DRAM_CYCLES;
   assign dram_t_rm.RRD_DRAM_CYCLES = RRD_DRAM_CYCLES;
   assign dram_t_rm.AREF_DRAM_CYCLES = AREF_DRAM_CYCLES;
   assign dram_t_rm.RFC_DRAM_CYCLES = RFC_DRAM_CYCLES;
   assign dram_t_rm.FAW_DRAM_CYCLES = FAW_DRAM_CYCLES;
   assign dram_t_rm.ZQS_DRAM_CYCLES = ZQS_DRAM_CYCLES;
   assign dram_t_rm.BL = BL;
   assign dram_t_rm.CWL = CWL;
   assign dram_t_rm.CL = CL;

   ch_ctrl_rank_fsm
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
       .FE_ID_WIDTH(FE_ID_WIDTH),
       .FE_WRITE(FE_WRITE),
       .CLK_RATIO(CLK_RATIO),
       .AREF_CNT_WIDTH(AREF_CNT_WIDTH),
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
       .ZQS_DRAM_CYCLES_LOG2(ZQS_DRAM_CYCLES_LOG2),
       .ZQSI_TREFI_CYCLES(ZQSI_TREFI_CYCLES)// ZQ short interval
       /*.RRD_DRAM_CYCLES(RRD_DRAM_CYCLES),
       .WTR_DRAM_CYCLES(WTR_DRAM_CYCLES),
       .CCD_DRAM_CYCLES(CCD_DRAM_CYCLES),
       .RP_DRAM_CYCLES(RP_DRAM_CYCLES),
       .RTP_DRAM_CYCLES(RTP_DRAM_CYCLES),
       .WR_DRAM_CYCLES(WR_DRAM_CYCLES),
       .RCD_DRAM_CYCLES(RCD_DRAM_CYCLES),
       .RAS_DRAM_CYCLES(RAS_DRAM_CYCLES),
       .ZQS_DRAM_CYCLES(ZQS_DRAM_CYCLES),
       .AREF_DRAM_CYCLES(AREF_DRAM_CYCLES),
       .RFC_DRAM_CYCLES(RFC_DRAM_CYCLES),
       .CL(CL),
       .CWL(CWL),
       .TFAW_NS(TFAW_NS),
       .BL(BL)*/
       ) RM
       (
	.rst_n(rst_n),
	.clk(clk),
	.fe_req(fe_req),
	.fe_cmd(fe_cmd),
	.fe_addr(fe_addr),
	.fe_id(fe_id),
	.fe_stall(fe_stall),
	.read_stall(read_stall),
	.init_done(init_done),
	.init_en(init_en),
	.rm_addr(rm_addr),
	.rm_bank(rm_bank),
	.rm_cmd(rm_cmd),
	.rm_valid(rm_valid),
	.rm_cas_cmd_id(rm_cas_cmd_id),
	.rm_cas_cmd_id_valid(rm_cas_cmd_id_valid),
	.rm_write(rm_write),
	.rm_read(rm_read),
	.rm_cas_slot(rm_cas_slot),
	.decoder_type(decoder_type),
	.rg_en(rg_en),
	.dram_t_rm(dram_t_rm),
	.dram_t_bm(dram_t_bm)
	);
endmodule
