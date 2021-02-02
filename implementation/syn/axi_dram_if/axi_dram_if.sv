// Version2: Written by Erfan Azarkhish
// Apended by Chirag Sudarshan

module axi_dram_if
  #(
	parameter AXI4_ADDRESS_WIDTH = 32,
	parameter AXI4_RDATA_WIDTH   = 64,
	parameter AXI4_WDATA_WIDTH   = 64,
	parameter AXI4_ID_WIDTH      = 16,
	parameter AXI4_USER_WIDTH    = 10,
	parameter AXI_BURST_LENGTH   = 1,
	parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,
	parameter MEM_ADDR_WIDTH     = 13,
	parameter FE_CMD_WIDTH       = 1,
	parameter WRITE_CMD          = 0,
	parameter READ_CMD           = 1,
	parameter BUFF_DEPTH_SLAVE   = 4,
	parameter DRAM_BUS_WIDTH = 8,
	parameter DRAM_MASK_WIDTH = DRAM_BUS_WIDTH/8,
	parameter BL = 8, // Burst Length
	parameter MEM_ADDR_RANGE    = 28
	)
  (
   input 									  ACLK,
   input 									  ARESETn,

	//AXI write address bus *******************************************
   input [AXI4_ID_WIDTH-1:0] 				  AWID_i ,
   input [AXI4_ADDRESS_WIDTH-1:0] 			  AWADDR_i ,
   input [7:0] 								  AWLEN_i ,
   input [2:0] 								  AWSIZE_i ,
   input [1:0] 								  AWBURST_i ,
   input 									  AWLOCK_i ,
   input [3:0] 								  AWCACHE_i ,
   input [2:0] 								  AWPROT_i ,
   input [3:0] 								  AWREGION_i,
   input [AXI4_USER_WIDTH-1:0] 				  AWUSER_i ,
   input [3:0] 								  AWQOS_i ,
   input 									  AWVALID_i ,
   output logic 							  AWREADY_o ,
	//AXI write data bus **********************************************
   input [AXI_NUMBYTES-1:0][7:0] 			  WDATA_i ,
   input [AXI_NUMBYTES-1:0] 				  WSTRB_i ,
   input 									  WLAST_i ,
   input [AXI4_USER_WIDTH-1:0] 				  WUSER_i ,
   input 									  WVALID_i ,
   output logic 							  WREADY_o ,
	//AXI write response bus ******************************************
   output logic [AXI4_ID_WIDTH-1:0] 		  BID_o ,
   output logic [1:0] 						  BRESP_o ,
   output logic 							  BVALID_o ,
   output logic [AXI4_USER_WIDTH-1:0] 		  BUSER_o ,
   input 									  BREADY_i ,
	//AXI read address bus ********************************************
   input [AXI4_ID_WIDTH-1:0] 				  ARID_i,
   input [AXI4_ADDRESS_WIDTH-1:0] 			  ARADDR_i,
   input [7:0] 								  ARLEN_i,
   input [2:0] 								  ARSIZE_i,
   input [1:0] 								  ARBURST_i,
   input 									  ARLOCK_i,
   input [3:0] 								  ARCACHE_i,
   input [2:0] 								  ARPROT_i,
   input [3:0] 								  ARREGION_i,
   input [AXI4_USER_WIDTH-1:0] 				  ARUSER_i,
   input [3:0] 								  ARQOS_i,
   input 									  ARVALID_i,
   output logic 							  ARREADY_o,
	//AXI read data bus ***********************************************
   output logic [AXI4_ID_WIDTH-1:0] 		  RID_o,
   output logic [AXI4_RDATA_WIDTH-1:0] 		  RDATA_o,
   output logic [1:0] 						  RRESP_o,
   output logic 							  RLAST_o,
   output logic [AXI4_USER_WIDTH-1:0] 		  RUSER_o,
   output logic 							  RVALID_o,
   input 									  RREADY_i,

	// To DRAM Controller *********************************************
   output logic [MEM_ADDR_RANGE-1:0] 		  data_addr_o,
   output logic [FE_CMD_WIDTH-1:0] 			  data_cmd_o,
   output logic 							  data_req_o,
   output logic [BL-1:0][DRAM_BUS_WIDTH-1:0]  data_wdata_o,
   output logic [BL-1:0][DRAM_MASK_WIDTH-1:0] data_mask_o,
   output logic [AXI4_ID_WIDTH-1:0] 		  data_ID_o,
   //output logic [`CH_TRANS_TYPE-1:0] 			data_trans_type_o,
   //output logic [`CH_BURST_LENGTH_LOG2-1:0] 	data_burst_o,
   input 									  data_stall_i,

	// From DRAM Controller *******************************************
   input [BL-1:0][DRAM_BUS_WIDTH-1:0] 		  data_r_rdata_i,
   input [AXI4_ID_WIDTH-1:0] 				  data_r_ID_i,
   //input logic [$clog2(BL)-1:0] 				data_r_burst_i,
   //input logic [`CH_TRANS_TYPE-1:0] 			data_r_trans_type_i,
   input 									  data_r_valid_i,
   //input logic [`CH_BURST_LENGTH_LOG2-1:0] 	data_r_start_chunk_i,
   output logic 							  data_r_stall_o
	);

   localparam OKAY = 2'b00;
   localparam EXOKAY = 2'b01;
   localparam SLVERR = 2'b10;
   localparam DECERR = 2'b11;
   localparam DATA_WIDTH_RATIO = (DRAM_BUS_WIDTH*BL)/AXI4_RDATA_WIDTH;

   typedef enum logic [2:0] {
							 REQ_IDLE,
							 WAIT_FOR_W,
							 WAIT_FOR_B,
							 WAIT_FOR_DRAM,
							 ERROR } req_state_type;
   typedef enum logic [2:0] {
							  RSP_IDLE,
							  SERIALIZE } rsp_state_type;
   typedef enum  logic [1:0] {
							  AXI_W,
							  AXI_R,
							  NONE } channel_type;

   req_state_type req_state_c, req_state_n;
   rsp_state_type rsp_state_c, rsp_state_n;
   channel_type RR_Flag_c, RR_Flag_n, selected; // Roind-robin selector

   //AXI write address bus
   logic [AXI4_ID_WIDTH-1:0] AWID, AWID_Q;
   logic [AXI4_ADDRESS_WIDTH-1:0] AWADDR, AWADDR_Q;
   logic [7:0] 				  AWLEN, AWLEN_Q;
   logic [2:0] 				  AWSIZE;
   logic [1:0] 				  AWBURST;
   logic 						  AWLOCK;
   logic [3:0] 				  AWCACHE;
   logic [2:0] 				  AWPROT;
   logic [3:0] 				  AWREGION;
   logic [AXI4_USER_WIDTH-1:0]   AWUSER;
   logic [3:0] 				  AWQOS;
   logic 						  AWVALID;
   logic 						  AWREADY;
   //AXI write data bus
   logic [AXI_NUMBYTES-1:0][7:0]  WDATA;
   logic [AXI_NUMBYTES-1:0] 	  WSTRB;
   logic 						  WLAST;
   logic [AXI4_USER_WIDTH-1:0] 	  WUSER;
   logic 							  WVALID;
   logic 							  WREADY ;
   //AXI write response bus
   logic [AXI4_ID_WIDTH-1:0] 		  BID;
   logic [1:0] 						  BRESP;
   logic 								  BVALID;
   logic [AXI4_USER_WIDTH-1:0] 			  BUSER;
   logic 									  BREADY;
   //AXI read address bus
   logic [AXI4_ID_WIDTH-1:0] 				  ARID;
   logic [AXI4_ADDRESS_WIDTH-1:0] 			  ARADDR;
   logic [7:0] 							  ARLEN;
   logic [2:0] 							  ARSIZE;
   logic [1:0] 							  ARBURST;
   logic 									  ARLOCK;
   logic [3:0] 							  ARCACHE;
   logic [2:0] 							  ARPROT;
   logic [3:0] 							  ARREGION;
   logic [AXI4_USER_WIDTH-1:0] 			  ARUSER;
   logic [3:0] 							  ARQOS;
   logic 									  ARVALID;
   logic 									  ARREADY;
   //AXI read data bus
   logic [AXI4_ID_WIDTH-1:0] 				  RID;
   logic [AXI4_RDATA_WIDTH-1:0] 			  RDATA;
   logic [1:0] 							  RRESP;
   logic 									  RLAST;
   logic [AXI4_USER_WIDTH-1:0] 				  RUSER;
   logic 										  RVALID;
   logic 										  RREADY;
   // Buffered signals to DRAM (Compander)
   logic [DATA_WIDTH_RATIO-1:0][AXI4_RDATA_WIDTH-1:0] data_wdata, data_wdata_Q;
   logic [DATA_WIDTH_RATIO-1:0][AXI_NUMBYTES-1:0] data_mask, data_mask_Q;
   logic [DATA_WIDTH_RATIO-1:0][AXI4_RDATA_WIDTH-1:0] data_r_rdata_Q;
   logic [AXI4_ID_WIDTH-1:0] 						  data_r_ID_Q;
   //logic [`CH_BURST_LENGTH_LOG2-1:0] 				  data_r_burst_Q;

   // Internal signals
   logic 											  sample_AW, sample_W;
   logic 											  sample_AR, sample_R;
   logic [7:0] 									  AWINDEX, AWINDEX_Q;
   logic [7:0] 									  RCOUNT, RCOUNT_Q;
   logic [7:0] 										  RINDEX, RINDEX_Q;

	// FSM for the Resposne Channel (R)
   always_ff @(posedge ACLK, negedge ARESETn)
	 begin : RSP_FSM
		if(ARESETn == 1'b0)
		  begin
			 // Reset signals
			 RINDEX_Q <= '0;
			 RCOUNT_Q <= '0;
			 data_r_rdata_Q <= '0;
			 //data_r_burst_Q <= '0;
			 data_r_ID_Q <= '0;
			 rsp_state_c <= RSP_IDLE;
		  end
		else
		  begin
			 rsp_state_c <= rsp_state_n;
			 RINDEX_Q <= RINDEX;
			 RCOUNT_Q <= RCOUNT;
			 if (sample_R)
			   begin
				  RINDEX_Q <= '0;
				  RCOUNT_Q <= '0;
				  //data_r_burst_Q <= data_r_burst_i;
				  data_r_rdata_Q <= data_r_rdata_i;
				  data_r_ID_Q <= data_r_ID_i;
			end
		end
	end


   always_comb
	 begin : RSP_COMB
	   rsp_state_n = RSP_IDLE;
	   sample_R = '0;
	   data_r_stall_o = '0;
	   RINDEX = RINDEX_Q;
	   RCOUNT = RCOUNT_Q;
	   RVALID = '0;
	   RRESP = '0;
	   RUSER = '0;
	   RID   = '0;
	   RDATA = '0;
	   RLAST = '0;
		case (rsp_state_c)
		  RSP_IDLE:
			begin
			   RINDEX = 0;
			   RCOUNT = 0;
			   if ( data_r_valid_i )
				 begin
					sample_R = '1;
					rsp_state_n = SERIALIZE;
				end
			end
		  SERIALIZE:
			begin
			   rsp_state_n = SERIALIZE;
			   data_r_stall_o = '1;
			   if ( RREADY )
				 begin
					RINDEX = RINDEX_Q + 1;
					RCOUNT = RCOUNT_Q + 1;
					/// R Channel
					RRESP = OKAY;
					RVALID = '1;
					RUSER = '0;
					RID = data_r_ID_Q;
					RDATA = data_r_rdata_Q[RINDEX_Q];
					RLAST = '0;
					///**********
					if ( RCOUNT_Q == DATA_WIDTH_RATIO-1 )
					  ///`CONV_TO_AXI_LEN(data_r_burst_Q)  )
					  begin
						 RLAST = '1;
						 rsp_state_n = RSP_IDLE;
					  end
				 end
			end
		  default:
			rsp_state_n = RSP_IDLE;
		endcase
	 end

// FSM for Request Channels (AR. AW, W)
   always_ff @(posedge ACLK, negedge ARESETn)
	 begin : REQ_FSM
		if(ARESETn == 1'b0)
		  begin
			 // Reset signals
			 AWADDR_Q <= '0;
			 AWID_Q <= '0;
			 AWLEN_Q  <= '0;
			 RR_Flag_c <= AXI_W;
			 req_state_c  <= REQ_IDLE;
			 AWINDEX_Q <= '0;
			 data_mask_Q <= '0;
			 data_wdata_Q <= '0;
		  end
		else
		  begin
			 req_state_c <= req_state_n;
			 RR_Flag_c <= RR_Flag_n;
			 data_mask_Q <= data_mask;
			 data_wdata_Q <= data_wdata;
			 AWINDEX_Q <= AWINDEX;
			 if (sample_AW)
			   begin
				  AWADDR_Q <= AWADDR;
				  AWID_Q <= AWID;
				  AWLEN_Q  <= AWLEN;
			   end
		  end
	 end

   always_comb
	 begin : REQ_COMB
		req_state_n = REQ_IDLE;
		RR_Flag_n = RR_Flag_c;
		selected = NONE;
		sample_AW = '0;
		sample_AR = '0;
 		sample_W = '0;
		data_wdata_o = '0;
		data_mask_o = '0;
		data_addr_o = '0;
		data_ID_o = '0;
		data_cmd_o = '0;
		//data_trans_type_o = `DRAM_TRANSACTION_TYPE;
		//data_burst_o = `CONV_TO_DRAM_BURST(0);
		data_req_o = '0;
		BID = '0;
		BRESP = '0;
		BUSER = '0;
		BVALID = '0;
		case (req_state_c)
		  REQ_IDLE:
			begin
			   if ( AWVALID && ARVALID )
				 selected = RR_Flag_c; // Round-robin
			   else if ( AWVALID )
				 selected = AXI_W;
			   else if ( ARVALID )
				 selected = AXI_R;
			   if ( selected == AXI_W )
				 begin // Write command ********
					sample_AW = '1;
					req_state_n = WAIT_FOR_W;
					if ( WVALID && !data_stall_i ) //DEEPAK
					  begin
						 sample_W = '1;
						 if ( AWLEN == '0 )
						   begin
							  if ( WLAST )
								begin // Burst
								   if ( ! data_stall_i )
									 begin
										data_req_o = '1;
										data_cmd_o = WRITE_CMD;
										data_ID_o = AWID;
										data_addr_o = AWADDR[MEM_ADDR_RANGE-1:0];
										//data_trans_type_o = `DRAM_TRANSACTION_TYPE;
										//data_burst_o = `CONV_TO_DRAM_BURST(AWLEN);
										///`CONV_TO_BURST_CMD(AWLEN);
										data_wdata_o = data_wdata;// TODO NOTICE
										data_mask_o = data_mask;// TODO NOTICE
										if ( BREADY ) // Backward (B) Write
										  begin
											 ///********** ACK BACKWARD CHANNEL
											 req_state_n = REQ_IDLE;
											 BID = AWID;
											 BRESP = OKAY;
											 BUSER = '0;
											 BVALID = '1;
											 RR_Flag_n = (RR_Flag_c == AXI_W ?
														  AXI_R : AXI_W); // Rotate
										  end
										else
									  req_state_n = WAIT_FOR_B;
									 end
								   else
									 req_state_n = WAIT_FOR_DRAM;
								end
							  else
								req_state_n = ERROR;
						   end
					  end
				 end
			   else if ( selected == AXI_R )
				 begin // Read Command
					if ( ! data_stall_i )
					  begin
						 sample_AR = '1;
						 data_req_o = '1;
						 data_cmd_o = READ_CMD;
						 data_addr_o = ARADDR[MEM_ADDR_RANGE-1:0];
						 data_wdata_o = '0;
						 data_mask_o = '0;
						 data_ID_o = ARID;
						 //data_burst_o = `CONV_TO_DRAM_BURST(ARLEN);
						 ///`CONV_TO_BURST_CMD(ARLEN);
						 //data_trans_type_o = `DRAM_TRANSACTION_TYPE;
						 RR_Flag_n = (RR_Flag_c == AXI_W ? AXI_R : AXI_W);
						 // Rotate
					  end
				 end
			end
		  WAIT_FOR_W:
			begin // Write Data
			   req_state_n = WAIT_FOR_W;
 			   if ( WVALID && !data_stall_i)  //DEEPAK
				 begin
					sample_W = '1;
					if ( AWINDEX_Q == AWLEN_Q )
					  begin
						 if ( WLAST )
						   begin // Burst
							  if ( ! data_stall_i )
								begin
								   data_req_o = '1;
								   data_cmd_o = WRITE_CMD;
								   data_ID_o = AWID_Q;
								   data_addr_o = AWADDR_Q[MEM_ADDR_RANGE-1:0];
								   //data_trans_type_o = `DRAM_TRANSACTION_TYPE;
								   //data_burst_o = `CONV_TO_DRAM_BURST(AWLEN_Q);
								   ///`CONV_TO_BURST_CMD(AWLEN_Q);
								   data_wdata_o = data_wdata;
								   data_mask_o = data_mask;
								   if ( BREADY ) // Backward (B) Write
									 begin
										req_state_n = REQ_IDLE;
										BID = AWID_Q;
										BRESP = OKAY;
										BUSER = '0;
										BVALID = '1;
										RR_Flag_n = (RR_Flag_c == AXI_W ?
													 AXI_R : AXI_W); // Rotate
									 end
								   else
									 req_state_n = WAIT_FOR_B;
								end
							  else
								req_state_n = WAIT_FOR_DRAM;
						   end
						 else
						   req_state_n = ERROR;
					  end
					else
					  req_state_n = WAIT_FOR_W;
				 end
			end
		  WAIT_FOR_DRAM:
			begin
			   if ( ! data_stall_i )
				 begin
					data_req_o = '1;
					data_cmd_o = WRITE_CMD;
					data_ID_o = AWID_Q;
					data_addr_o = AWADDR_Q[MEM_ADDR_RANGE-1:0];
					//data_trans_type_o = `DRAM_TRANSACTION_TYPE;
					//data_burst_o = `CONV_TO_DRAM_BURST(AWLEN_Q);
					///`CONV_TO_BURST_CMD(AWLEN_Q);
					data_wdata_o = data_wdata_Q;
					data_mask_o = data_mask_Q;
					if ( BREADY ) // Backward (B) Write
					  begin
						 req_state_n = REQ_IDLE;
						 BID = AWID_Q;
						 BRESP = OKAY;
						 BUSER = '0;
						 BVALID = '1;
						 RR_Flag_n = (RR_Flag_c == AXI_W ? AXI_R : AXI_W);
					  end
					else
					  req_state_n = WAIT_FOR_B;
				 end
			   else
				 req_state_n = WAIT_FOR_DRAM;
			end
		  WAIT_FOR_B:
			begin
			   if ( BREADY )
				 begin
					BID = AWID_Q;
					BRESP = OKAY;
					BUSER = '0;
					BVALID = '1;
					req_state_n = REQ_IDLE;
					RR_Flag_n = (RR_Flag_c == AXI_W ? AXI_R : AXI_W); // Rotate
				 end
			   else
				 req_state_n = WAIT_FOR_B;
			end
		  ERROR:
			begin
			   req_state_n = ERROR;
               `ifndef SYNTHESIS
			      $error("req_state_c = ERROR!");
				  $stop();
			   `endif
			end
		  default:
			req_state_n = REQ_IDLE;
		endcase
	 end

   // Data Buffer
   always_comb
	 begin : DATA_BUFFER
		AWINDEX = 0;
		data_mask = data_mask_Q;
		data_wdata = data_wdata_Q;
		if (WVALID /*&& (req_state_c == WAIT_FOR_W)*/ )
		  begin
			 if ( !WLAST )
			   AWINDEX = AWINDEX_Q + 1;
			 if ( AWINDEX_Q == 0 )
			   data_mask = '1; // Reset mask to inactive value
			 data_wdata[AWINDEX_Q] = WDATA;
			 data_mask[AWINDEX_Q] = ~WSTRB;
		end
	 end // block: DATA_BUFFER

	// Wirings
 	assign AWREADY = sample_AW;
 	assign WREADY  = sample_W;
 	assign ARREADY = sample_AR;

   // FIFOs
   axi_aw_buffer
	 #(
	   .ID_WIDTH     ( AXI4_ID_WIDTH      ),
       .ADDR_WIDTH   ( AXI4_ADDRESS_WIDTH ),
       .USER_WIDTH   ( AXI4_USER_WIDTH    ),
	   .BUFFER_DEPTH ( BUFF_DEPTH_SLAVE  )
	   )
   Slave_aw_buffer
	 (
	  .clk_i           ( ACLK        ),
	  .rst_ni          ( ARESETn     ),
	  .test_en_i       ( 1'b0        ),
	  .slave_valid_i   ( AWVALID_i   ),
	  .slave_addr_i    ( AWADDR_i    ),
	  .slave_prot_i    ( AWPROT_i    ),
	  .slave_region_i  ( AWREGION_i  ),
	  .slave_len_i     ( AWLEN_i     ),
	  .slave_size_i    ( AWSIZE_i    ),
	  .slave_burst_i   ( AWBURST_i   ),
	  .slave_lock_i    ( AWLOCK_i    ),
	  .slave_cache_i   ( AWCACHE_i   ),
	  .slave_qos_i     ( AWQOS_i     ),
	  .slave_id_i      ( AWID_i      ),
	  .slave_user_i    ( AWUSER_i    ),
	  .slave_ready_o   ( AWREADY_o   ),
	  .master_valid_o  ( AWVALID     ),
	  .master_addr_o   ( AWADDR      ),
	  .master_prot_o   ( AWPROT      ),
	  .master_region_o ( AWREGION    ),
	  .master_len_o    ( AWLEN       ),
	  .master_size_o   ( AWSIZE      ),
	  .master_burst_o  ( AWBURST     ),
	  .master_lock_o   ( AWLOCK      ),
	  .master_cache_o  ( AWCACHE     ),
	  .master_qos_o    ( AWQOS       ),
	  .master_id_o     ( AWID        ),
	  .master_user_o   ( AWUSER      ),
	  .master_ready_i  ( AWREADY     )
	);

   axi_ar_buffer
	 #(
	   .ID_WIDTH     ( AXI4_ID_WIDTH      ),
	   .ADDR_WIDTH   ( AXI4_ADDRESS_WIDTH ),
	   .USER_WIDTH   ( AXI4_USER_WIDTH    ),
	   .BUFFER_DEPTH ( BUFF_DEPTH_SLAVE   )
	   )
   Slave_ar_buffer
	 (
	  .clk_i           ( ACLK       ),
	  .rst_ni          ( ARESETn    ),
	  .test_en_i       ( 1'b0       ),
	  .slave_valid_i   ( ARVALID_i  ),
	  .slave_addr_i    ( ARADDR_i   ),
	  .slave_prot_i    ( ARPROT_i   ),
	  .slave_region_i  ( ARREGION_i ),
	  .slave_len_i     ( ARLEN_i    ),
	  .slave_size_i    ( ARSIZE_i   ),
	  .slave_burst_i   ( ARBURST_i  ),
	  .slave_lock_i    ( ARLOCK_i   ),
	  .slave_cache_i   ( ARCACHE_i  ),
	  .slave_qos_i     ( ARQOS_i    ),
	  .slave_id_i      ( ARID_i     ),
	  .slave_user_i    ( ARUSER_i   ),
	  .slave_ready_o   ( ARREADY_o  ),
	  .master_valid_o  ( ARVALID    ),
	  .master_addr_o   ( ARADDR     ),
	  .master_prot_o   ( ARPROT     ),
	  .master_region_o ( ARREGION   ),
	  .master_len_o    ( ARLEN      ),
	  .master_size_o   ( ARSIZE     ),
	  .master_burst_o  ( ARBURST    ),
	  .master_lock_o   ( ARLOCK     ),
	  .master_cache_o  ( ARCACHE    ),
	  .master_qos_o    ( ARQOS      ),
	  .master_id_o     ( ARID       ),
	  .master_user_o   ( ARUSER     ),
	  .master_ready_i  ( ARREADY    )
	  );

	axi_w_buffer
	#(
	  .DATA_WIDTH(AXI4_RDATA_WIDTH),
	  .USER_WIDTH(AXI4_USER_WIDTH),
	  .BUFFER_DEPTH(BUFF_DEPTH_SLAVE)
	)
   Slave_w_buffer
	 (
	  .clk_i          ( ACLK     ),
	  .rst_ni         ( ARESETn  ),
	  .test_en_i      ( 1'b0     ),
	  .slave_valid_i  ( WVALID_i ),
	  .slave_data_i   ( WDATA_i  ),
	  .slave_strb_i   ( WSTRB_i  ),
	  .slave_user_i   ( WUSER_i  ),
	  .slave_last_i   ( WLAST_i  ),
	  .slave_ready_o  ( WREADY_o ),
	  .master_valid_o ( WVALID   ),
	  .master_data_o  ( WDATA    ),
	  .master_strb_o  ( WSTRB    ),
	  .master_user_o  ( WUSER    ),
	  .master_last_o  ( WLAST    ),
	  .master_ready_i ( WREADY   )
	);

	////////////////////////////
   /// assign RREADY = '0;
	axi_r_buffer
	#(
	  .ID_WIDTH(AXI4_ID_WIDTH),
	  .DATA_WIDTH(AXI4_RDATA_WIDTH),
	  .USER_WIDTH(AXI4_USER_WIDTH),
	  .BUFFER_DEPTH(BUFF_DEPTH_SLAVE)
	)
	Slave_r_buffer
	(

	 .clk_i          ( ACLK       ),
	 .rst_ni         ( ARESETn    ),
	 .test_en_i      ( 1'b0       ),
	 .slave_valid_i  ( RVALID     ),
	 .slave_data_i   ( RDATA      ),
	 .slave_resp_i   ( RRESP      ),
	 .slave_user_i   ( RUSER      ),
	 .slave_id_i     ( RID        ),
	 .slave_last_i   ( RLAST      ),
	 .slave_ready_o  ( RREADY     ),
	 .master_valid_o ( RVALID_o   ),
	 .master_data_o  ( RDATA_o    ),
	 .master_resp_o  ( RRESP_o    ),
	 .master_user_o  ( RUSER_o    ),
	 .master_id_o    ( RID_o      ),
	 .master_last_o  ( RLAST_o    ),
	 .master_ready_i ( RREADY_i   )
	);


/// 	assign BREADY = '0;
   axi_b_buffer
	 #(
	   .ID_WIDTH(AXI4_ID_WIDTH),
	   .USER_WIDTH(AXI4_USER_WIDTH),
	   .BUFFER_DEPTH(BUFF_DEPTH_SLAVE)
	   )
   Slave_b_buffer
	 (
	  .clk_i          ( ACLK       ),
	  .rst_ni         ( ARESETn    ),
	  .test_en_i      ( 1'b0       ),
	  .slave_valid_i  ( BVALID    ),
	  .slave_resp_i   ( BRESP     ),
	  .slave_id_i     ( BID       ),
	  .slave_user_i   ( BUSER     ),
	  .slave_ready_o  ( BREADY    ),
	  .master_valid_o ( BVALID_o  ),
	  .master_resp_o  ( BRESP_o   ),
	  .master_id_o    ( BID_o     ),
	  .master_user_o  ( BUSER_o   ),
	  .master_ready_i ( BREADY_i  )
	);

  endmodule
