// This module translates the custom memctrl signals to signals as specified in Xilinx PG150 Phy Only Interface (October 30, 2019) page 160.
// Xilinx ultrascale phy requires the bits to be packed in a certain pattern.
// for more details refer the following link
// https://www.xilinx.com/support/documentation/ip_documentation/ultrascale_memory_ip/v1_4/pg150-ultrascale-memory-ip.pdf#page=160

module xiphy_ultrascale_if
  #(
    parameter DRAM_ADDR_WIDTH = 8,
    parameter CLK_RATIO = 4,
    parameter DRAM_BANKS = 8,
    parameter AXI4_ID_WIDTH = 16,
    parameter DRAM_CMD_WIDTH = 5
    )
   (
    input 					  clk,
    input 					  rst_n,
    
    input [CLK_RATIO-1:0][DRAM_ADDR_WIDTH-1:0] 	  ctrl_addr,
    input [CLK_RATIO-1:0][$clog2(DRAM_BANKS)-1:0] ctrl_bank,
    input [CLK_RATIO-1:0][DRAM_CMD_WIDTH-1:0] 	  ctrl_cmd,
    input [CLK_RATIO-1:0] 			  ctrl_act_n,
    //output [CLK_RATIO-1:0] 			  ctrl_cs_n
    //output [CLK_RATIO-1:0] 			  ctrl_cke
    input 					  ctrl_valid,
    input [AXI4_ID_WIDTH-1:0] 			  ctrl_cas_cmd_id,
    //input 					  ctrl_cas_cmd_id_valid,//NA
    input 					  ctrl_write,
    input 					  ctrl_read,
    input [$clog2(CLK_RATIO)-1:0] 		  ctrl_cas_slot,
    input 					  rdDataEn,
    
    output [4:0] 				  dBufAdr,

    output [7:0] 				  mc_ACT_n,
    output [135:0] 				  mc_ADR,
    output [15:0] 				  mc_BA,
    output [15:0] 				  mc_BG,
    output [7:0] 				  mc_CKE,
    output [7:0] 				  mc_CS_n,
    output [7:0] 				  mc_ODT,
    output [1:0] 				  mcCasSlot,
    output [0:0] 				  mcCasSlot2,
    output [0:0] 				  mcRdCAS,
    output [0:0] 				  mcWrCAS,
    output [0:0] 				  winInjTxn,
    output [0:0] 				  winRmw,
    output logic 				  gt_data_ready,
    output [4:0] 				  winBuf,
    output [1:0] 				  winRank
    );


   // cas control signals
   assign mcRdCAS = ctrl_read;
   assign mcWrCAS = ctrl_write;
   assign mcCasSlot = ctrl_cas_slot;
   assign mcCasSlot2 = ctrl_cas_slot[1];

   // VT tracking signals that has to be considered later
   assign winInjTxn = 0;
   
   // Read modified write -- works for with ECC only
   assign winRmw = 0;

   // to be considered later for multi rank
   assign winRank = 0;

    assign winBuf = 0;
   
   // dBufAdr is a reserved signal in Xilinx ultrascale phy, should be tied low
   assign dBufAdr = 0;

   logic [CLK_RATIO-1:0] 			  ctrl_write_lcl,ctrl_write_q;
   logic [CLK_RATIO-1:0] 			  mc_ODT_lcl;
   
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0)
	  ctrl_write_q <='0;
	else
	  ctrl_write_q <=ctrl_write_lcl;
     end

   // gt_data_read signal has to sent every 1us. gt_data_ready has to be asserted after readDataEN
   logic[9:0] counter;
   
   always_ff @(posedge clk, negedge rst_n)
     begin
	if(rst_n == 1'b0) begin
	   gt_data_ready <= '0;
	   counter <= 100;
	end
	else begin
	   if (counter == '0) begin
	      if(rdDataEn) begin
		 counter <= 100;
		 gt_data_ready <= 1'b1;
	      end
	      else begin
		 gt_data_ready <= 1'b0;
		 counter <= 0;
	      end
	   end
	   else begin
	      counter <= counter - 1;
	      gt_data_ready <= 1'b0;
	   end // else: !if(counter == '0)
	end // else: !if(rst_n == 1'b0)
     end // always_ff @ (posedge clk, negedge rst_n)
   

   always_comb
     begin
	mc_ODT_lcl = {CLK_RATIO{(ctrl_write && ctrl_valid)}} | ctrl_write_q;
	case(ctrl_cas_slot)
	  2'b00:begin
	     ctrl_write_lcl={'0 ,{(ctrl_write && ctrl_valid)}}; 
	  end
	  2'b01:begin
	     ctrl_write_lcl={'0 ,{2{(ctrl_write && ctrl_valid)}}};
	  end
	  2'b10:begin
	     ctrl_write_lcl={'0,{3{(ctrl_write && ctrl_valid)}}};
	  end
	  2'b11:begin
	     ctrl_write_lcl={4{(ctrl_write && ctrl_valid)}};
	  end
	endcase // case (ctrl_cas_slot)
     end // always_comb

   bit_packing_xiphy_ultrascale
      #(
	.DATA_WIDTH(1'b1),
	.CLK_RATIO(CLK_RATIO),
	.DUPLICATES(2)
	) addr_bit_packing_odt
	(
	 .data_i(mc_ODT_lcl),
	 .data_o(mc_ODT)
	 );

   bit_packing_xiphy_ultrascale
     #(
       .DATA_WIDTH($clog2(DRAM_BANKS)),
       .CLK_RATIO(CLK_RATIO),
       .DUPLICATES(2)
       ) bg_ba_bit_packing_bank
       (
	.data_i(ctrl_bank),
	.data_o({mc_BG,mc_BA})
	);
   

    bit_packing_xiphy_ultrascale
      #(
	.DATA_WIDTH(DRAM_ADDR_WIDTH),
	.CLK_RATIO(CLK_RATIO),
	.DUPLICATES(2)
	) addr_bit_packing_addr
	(
	 .data_i(ctrl_addr),
	 .data_o(mc_ADR)
	 );

    bit_packing_xiphy_ultrascale
      #(
	.DATA_WIDTH(1'b1),
	.CLK_RATIO(CLK_RATIO),
	.DUPLICATES(2)
	) addr_bit_packing_act
	(
	 .data_i(ctrl_act_n),
	 .data_o(mc_ACT_n)
	 );

       // Cmd order | cke | cs_n | ras_n | cas_n | we_n |
   bit_packing_xiphy_ultrascale
      #(
	.DATA_WIDTH(1'b1),
	.CLK_RATIO(CLK_RATIO),
	.DUPLICATES(2)
	) addr_bit_packing_cs
	(
	 .data_i({ctrl_cmd[3][3],ctrl_cmd[2][3],ctrl_cmd[1][3],ctrl_cmd[0][3]}),
	 .data_o(mc_CS_n)
	 );

   bit_packing_xiphy_ultrascale
      #(
	.DATA_WIDTH(1'b1),
	.CLK_RATIO(CLK_RATIO),
	.DUPLICATES(2)
	) addr_bit_packing_cke
	(
	 .data_i({ctrl_cmd[3][4],ctrl_cmd[2][4],ctrl_cmd[1][4],ctrl_cmd[0][4]}),
	 .data_o(mc_CKE)
	 );
    
endmodule // xiphy_ultrascale_if

