//`include "params_ctrl.v" 
`include "params_tgen_axi.sv"
`timescale 1ns/1ps

// Calculate Stall Cycles (Statistics)
`define ___BARRIER_WRITE___   begin barrier_w_time=$time; @(pending_AWLIST_Empty); @(AWLIST_Empty); STALLS_barrier_w+= ($time - barrier_w_time)/`CLK_PERIOD_SYS; end;
`define ___BARRIER_READ___    begin barrier_r_time=$time; @(pending_ARLIST_Empty); @(ARLIST_Empty); STALLS_barrier_r+= ($time - barrier_r_time)/`CLK_PERIOD_SYS; end;

// Calculate number of calls to barriers (Only for debugging)
// `define ___BARRIER_WRITE___ begin @(AWLIST_Empty); STALLS_barrier_w+=1; end;
// `define ___BARRIER_READ___  begin @(ARLIST_Empty); STALLS_barrier_r+=1; end;

module TGEN
#( 
      parameter AXI4_ADDRESS_WIDTH = 32,
      parameter AXI4_RDATA_WIDTH   = 64,
      parameter AXI4_WDATA_WIDTH   = 64,
      parameter AXI4_ID_WIDTH      = 16,
      parameter AXI4_USER_WIDTH    = 10,
      parameter AXI_NUMBYTES       = AXI4_WDATA_WIDTH/8,
      parameter SRC_ID             = 0
)	
(
	input logic 					ACLK,
	input logic 					ARESETn,

	//AXI write address bus
	output  logic [AXI4_ID_WIDTH-1:0]		AWID,    
	output  logic [AXI4_ADDRESS_WIDTH-1:0]		AWADDR,  
	output  logic [ 7:0]  				AWLEN    ,   
	output  logic [ 2:0] 				AWSIZE   ,  
	output  logic [ 1:0] 				AWBURST  , 
	output  logic 					AWLOCK   ,  
	output  logic [ 3:0] 				AWCACHE  , 
	output  logic [ 2:0] 				AWPROT   ,  
	output  logic [ 3:0]				AWREGION ,
	output  logic [ AXI4_USER_WIDTH-1:0]		AWUSER   ,  
	output  logic [ 3:0]				AWQOS    ,   
	output  logic					AWVALID  , 
	input   logic					AWREADY  , 
	///*************************************************************
	//AXI write data bus
	output  logic [AXI4_WDATA_WIDTH-1:0]		WDATA  ,
	output  logic [AXI_NUMBYTES-1:0]			WSTRB  ,   
	output  logic					WLAST  ,   
	output  logic [AXI4_USER_WIDTH-1:0]		WUSER  ,   
	output  logic					WVALID ,  
	input   logic					WREADY ,  
	///*************************************************************
	//AXI write response bus
	input   logic   [AXI4_ID_WIDTH-1:0]		BID    ,
	input   logic   [ 1:0]				BRESP  ,
	input   logic					BVALID ,
	input   logic   [AXI4_USER_WIDTH-1:0]		BUSER  ,   
	output  logic					BREADY ,
	///*************************************************************
	//AXI read address bus
	output  logic [AXI4_ID_WIDTH-1:0]		ARID,
	output  logic [AXI4_ADDRESS_WIDTH-1:0]		ARADDR,
	output  logic [ 7:0]				ARLEN,	
	output  logic [ 2:0]				ARSIZE,  
	output  logic [ 1:0]				ARBURST, 
	output  logic  					ARLOCK,  
	output  logic [ 3:0]				ARCACHE, 
	output  logic [ 2:0]				ARPROT,
	output  logic [ 3:0]				ARREGION,
	output  logic [ AXI4_USER_WIDTH-1:0]		ARUSER,  
	output  logic [ 3:0]				ARQOS,   
	output  logic  					ARVALID, 
	input   logic  					ARREADY, 
	///*************************************************************
	//AXI read data bus
	input  logic [AXI4_ID_WIDTH-1:0]  		RID,
	input  logic [AXI4_RDATA_WIDTH-1:0] 		RDATA,
	input  logic [ 1:0]				RRESP,
	input  logic  					RLAST,	
	input  logic [AXI4_USER_WIDTH-1:0] 		RUSER,	
	input  logic  					RVALID,  
	output logic  					RREADY
	///*************************************************************
);
	localparam NUM_TRANSACTIONS = `NUM_TRANSACTIONS;
	localparam TRAFFIC_IAT_DELAY = `TRAFFIC_IAT_DELAY;
	localparam TRAFFIC_IAT_JITTER = `TRAFFIC_IAT_JITTER;
	localparam TRAFFIC_INITIAL_DELAY = `TRAFFIC_INITIAL_DELAY;
	localparam TRAFFIC_INITIAL_JITTER = `TRAFFIC_INITIAL_JITTER;
	localparam TRAFFIC_MASK = `TRAFFIC_MASK;
	localparam AXI_TRAFFIC_MODE = `AXI_TRAFFIC_MODE;
	localparam TRAFFIC_NUM_WORDS = `TRAFFIC_NUM_WORDS;
	localparam TRAFFIC_RANDOM_NUM_WORDS = `TRAFFIC_RANDOM_NUM_WORDS;
	localparam AXI_TRAFFIC_WORKING_SET_SIZE = `AXI_TRAFFIC_WORKING_SET_SIZE;
	localparam AXI_TRAFFIC_ADDR_MODE = `AXI_TRAFFIC_ADDR_MODE;
	localparam NUM_CONSECUTIVE_WRITES = `NUM_CONSECUTIVE_WRITES;
	localparam NUM_CONSECUTIVE_READS = `NUM_CONSECUTIVE_READS;
	localparam VAR_CONSECUTIVE_WRITES = `VAR_CONSECUTIVE_WRITES;
	localparam VAR_CONSECUTIVE_READS = `VAR_CONSECUTIVE_READS;
	localparam DELAY_AFTER_CONSECUTIVE_WRITES = `DELAY_AFTER_CONSECUTIVE_WRITES;
	localparam DELAY_AFTER_CONSECUTIVE_READS = `DELAY_AFTER_CONSECUTIVE_READS;
	logic [AXI4_USER_WIDTH-1:0] MY_USER_ID = SRC_ID;
	
	//*********************STATISTICS*********************
	longint unsigned TRANS = 0;		// Injected transactions
	longint unsigned PASSED = 0;		// Passed transactions
	longint unsigned FAILED = 0;		// Failed transactions
	longint unsigned RACES = 0;		// Number of Races
	longint unsigned UNINIT = 0;		// Number of Reads from uninitialized locations of memory
	logic SIM_STOP = '0;			// Stop the simulation
	longint unsigned STALLS_allocate = 0;	// Stalls during the allocation phase (MiT)
	longint unsigned STALLS_barrier_r = 0;	// Stalls due to barrier after read transactions
	longint unsigned STALLS_barrier_w = 0;	// Stalls due to barrier after write transactions
	longint unsigned NUM_WRITES = 0;		// Number of Writes
	longint unsigned NUM_READS = 0;		// Number of Reads
	longint unsigned NUM_WRITE_WORDS = 0;	// Number of Writes
	longint unsigned NUM_READ_WORDS = 0;	// Number of Reads
	longint unsigned NUM_WRITE_WORDS_SCHEDULED = 0;	// Number of Writes
	longint unsigned NUM_READ_WORDS_SCHEDULED = 0;	// Number of Reads
	real	TMAT_WRITE = 0;			// Total Memory Access Time (Write Transactions)
	real	TMAT_READ = 0;			// Total Memory Access Time (Read Transactions)
	real    TMAT2_WRITE = 0;			// Total Memory Access Time Squared (Write Transactions)
	real    TMAT2_READ = 0;			// Total Memory Access Time Squared (Read Transactions)
	longint unsigned MIN_MAT_WRITE = 2000000000;	// Min MAT (Write Transactions)
	longint unsigned MIN_MAT_READ = 2000000000;	// Min MAT (Read Transactions)
	longint unsigned MAX_MAT_WRITE = 0;		// Max MAT (Write Transactions)
	longint unsigned MAX_MAT_READ = 0;		// Max MAT (Read Transactions)
	real INJECTION_START_TIME, INJECTION_END_TIME;	// To measure requested banwidth
	real REQUESTED_BANDWIDTH_W, REQUESTED_BANDWIDTH_R;
	`ifdef REPORT_COVERED_ADDRESS_RANGE
	longint unsigned MAX_ADDRESS = 0;	// Minimum address which has been accessed (determines the covered address range)
	longint MIN_ADDRESS = -1;	// Maximum address which has been accessed (determines the covered address range)
	`endif
	
	//****************************************************

	event req_AW_granted;
	event req_AR_granted;
	event req_DW_granted;
	event WriteDone, ReadDone;
	event AWLIST_Empty, ARLIST_Empty;
	event pending_AWLIST_Empty, pending_ARLIST_Empty;
	`ifdef VERIFY_READ_WRITE
	logic [15:0]				RECEIVED_ID_max;
	logic [AXI4_ID_WIDTH-1:0]		RECEIVED_ID;
	logic [AXI4_USER_WIDTH-1:0] 		RECEIVED_USER;
	logic [AXI4_ADDRESS_WIDTH-1:0]		RECEIVED_ADDR,RECEIVED_ADDR2;
	`endif

	logic	error_flag=0;
	
	integer i,i2,i3,j,k,TR, consecutive;
	integer R_W_BATCH_CNT, SEED;
	integer last_command_sent = `NOP_CMD;	// `NOP_CMD, `WRITE_CMD, `READ_CMD	(Only used in RANDOM_W_RANDOM_R Mode)
	real latency; ///REMOVE ID
	logic [AXI4_ID_WIDTH-1:0] curr_wid = 0;
	logic [AXI4_ID_WIDTH-1:0] curr_rid = 0;
	string s;
	time	barrier_r_time = 0;
	time	barrier_w_time = 0;

	`include "verif_utils.sv"
	`include "TGEN_TASK_GENERIC.sv"
	
	COMMAND CC, CCT;
 	DATA	DD;

	/// Generate Traffic
	///*************************
	longint unsigned NUM_WORDS, ADDRESS;
	initial 
	begin
	   `ifdef READY_QUEUE_ENABLED initialize_ready_queue(); `endif
		Nop;
	   @(ARESETn == 1)
		DELAY(`DRAM_INIT_TIME_ns/`CLK_PERIOD_SYS); // Wait for DRAM to initialize
		DELAY(TRAFFIC_INITIAL_DELAY + RANDOM(TRAFFIC_INITIAL_JITTER)); // Wait for specified number of cycles before injecting transactions
		
		$display("TGEN[%d] START GENERATING TRANSACTIONS - AXI_TRAFFIC_MODE:%s @%t", SRC_ID, AXI_TRAFFIC_MODE, $time);
		INJECTION_START_TIME = $time;
		
			
		if ( TRAFFIC_MASK != 0 )
		begin
		/*
		   ///DEEPAK -- this part is temporarily disabled
			//***********************************************************
			//***********************************************************
			//***********************************************************
			if ( AXI_TRAFFIC_MODE == "FILL_W" )
			begin
				for (TR=0; TR<NUM_TRANSACTIONS; TR++)
				begin
					NUM_WORDS=TRAFFIC_NUM_WORDS;
					if ( AXI_TRAFFIC_ADDR_MODE == "FIXED_ZERO")
						ADDRESS = 0;
					else
						ADDRESS = TR * (2**`ADDRESS_OFFSET(NUM_WORDS,`AXI_DATA_W));
					ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
					schedule_ST_AW ( .address(ADDRESS), .num_words(NUM_WORDS) );
					schedule_ST_DW ( .address(ADDRESS), .wdata(128'h0000CAFE0000FACE0000ABCD00000000+TR), .be({16'hFFFF}), .num_words(NUM_WORDS) );
					DELAY(TRAFFIC_IAT_DELAY);
				end
				`___BARRIER_WRITE___
			end
			//***********************************************************
			//***********************************************************
			//***********************************************************
			else if ( AXI_TRAFFIC_MODE == "FILL_R" )
			begin
				for (TR=0; TR<NUM_TRANSACTIONS; TR++)
				begin
					NUM_WORDS=TRAFFIC_NUM_WORDS;
					if ( AXI_TRAFFIC_ADDR_MODE == "FIXED_ZERO")
						ADDRESS = 0;
					else
						ADDRESS = TR * (2**`ADDRESS_OFFSET(NUM_WORDS,`AXI_DATA_W));
					ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
					schedule_LD ( .address(ADDRESS), .num_words(NUM_WORDS) );
					DELAY(TRAFFIC_IAT_DELAY);
				end
				`___BARRIER_READ___
			end
			//***********************************************************
			//***********************************************************
			//***********************************************************
			*/
			if ( AXI_TRAFFIC_MODE == "FILL_W_FILL_R" )
			begin
				for (TR=0; TR<NUM_TRANSACTIONS; TR++)
				begin
					NUM_WORDS=TRAFFIC_NUM_WORDS;
					if ( AXI_TRAFFIC_ADDR_MODE == "FIXED_ZERO")
						ADDRESS = 0;
					else
						ADDRESS = TR * (2**`ADDRESS_OFFSET(NUM_WORDS,`AXI_DATA_W));
					ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
					schedule_ST_AW ( .address(ADDRESS), .num_words(NUM_WORDS) );
					
					schedule_ST_DW ( .address(ADDRESS), .wdata(128'h0000CAFE0000FACE0000ABCD00000000+TR), .be({16'hFFFF}), .num_words(NUM_WORDS) );
					DELAY(TRAFFIC_IAT_DELAY);
				end
				`___BARRIER_WRITE___
				for (TR=0; TR<NUM_TRANSACTIONS; TR++)
				begin
					NUM_WORDS=TRAFFIC_NUM_WORDS;
					if ( AXI_TRAFFIC_ADDR_MODE == "FIXED_ZERO")
						ADDRESS = 0;
					else
						ADDRESS = TR * (2**`ADDRESS_OFFSET(NUM_WORDS,`AXI_DATA_W));
					ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
					schedule_LD ( .address(ADDRESS), .num_words(NUM_WORDS) );
					DELAY(TRAFFIC_IAT_DELAY);
				end
				`___BARRIER_READ___
			end
		
			//***********************************************************
			//***********************************************************
			//***********************************************************
			else if ( AXI_TRAFFIC_MODE == "RANDOM_WR" )
			begin
				for (TR=0; TR<NUM_TRANSACTIONS; TR+=2)
				begin
					NUM_WORDS= TRAFFIC_NUM_WORDS;  //DEEPAK AXI BL is fixed to 1
					//NUM_WORDS= GENERATE_NUM_WORDS(TRAFFIC_RANDOM_NUM_WORDS, TRAFFIC_NUM_WORDS);
					ADDRESS= GENERATE_ADDRESS( AXI_TRAFFIC_ADDR_MODE, AXI_TRAFFIC_WORKING_SET_SIZE, NUM_WORDS, TR );
					ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
					schedule_ST_AW ( .address(ADDRESS), .num_words(NUM_WORDS) );
					schedule_ST_DW ( .address(ADDRESS), .wdata(64'h0000CAFE0000FACE+TR), .be({8'hFF}), .num_words(NUM_WORDS) );   //DEEPAK 'be' generates data strobe
					DELAY(TRAFFIC_IAT_DELAY + RANDOM(TRAFFIC_IAT_JITTER));
					`___BARRIER_WRITE___
					schedule_LD ( .address(ADDRESS), .num_words(NUM_WORDS) );
					DELAY(TRAFFIC_IAT_DELAY + RANDOM(TRAFFIC_IAT_JITTER));
					`___BARRIER_READ___
					//$display("ID:%d | TRANSACTION @%h | NUM_WORDS=%d", SRC_ID, ADDRESS, NUM_WORDS );
				end
			end
			//***********************************************************
			//***********************************************************
			//***********************************************************
			else if ( AXI_TRAFFIC_MODE == "RANDOM_W_RANDOM_R" )
			begin
				if ( NUM_CONSECUTIVE_WRITES != 0 || NUM_CONSECUTIVE_READS != 0 )
				begin
				
					TR = 0;
					last_command_sent = `NOP_CMD;
					R_W_BATCH_CNT = 0;
					SEED = 0;
					while (TR<NUM_TRANSACTIONS )
					begin
						consecutive = NUM_CONSECUTIVE_WRITES + RANDOM(VAR_CONSECUTIVE_WRITES);
					    `ifdef VERIFY_READ_WRITE
						if ( last_command_sent == `READ_CMD && consecutive > 0 ) // WRITE AFTER READ (WAR)
							`___BARRIER_READ___
						`endif
						//$display("----> consecutive writes = %d", consecutive);
						for (i2=0; i2<consecutive; i2++)
						begin
						    SEED = R_W_BATCH_CNT*consecutive + i2;
							last_command_sent = `WRITE_CMD;
							NUM_WORDS= TRAFFIC_NUM_WORDS;  //DEEPAK AXI BL is fixed to 1
							//NUM_WORDS= GENERATE_NUM_WORDS(TRAFFIC_RANDOM_NUM_WORDS, TRAFFIC_NUM_WORDS);
							ADDRESS= GENERATE_ADDRESS( AXI_TRAFFIC_ADDR_MODE, AXI_TRAFFIC_WORKING_SET_SIZE, NUM_WORDS, SEED );
							ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
							schedule_ST_AW ( .address(ADDRESS), .num_words(NUM_WORDS) );
							schedule_ST_DW ( .address(ADDRESS), .wdata(64'h0000CAFE0000FACE+TR), .be({8'hFF}), .num_words(NUM_WORDS) );
							//$display("ID:%d|TID:%h(h)|WRITE:@%h|NUM_WORDS:%d", SRC_ID, TR, ADDRESS, NUM_WORDS );
							DELAY(TRAFFIC_IAT_DELAY + RANDOM(TRAFFIC_IAT_JITTER));
							TR++;
						end
						DELAY(DELAY_AFTER_CONSECUTIVE_WRITES);
						
						consecutive = NUM_CONSECUTIVE_READS + RANDOM(VAR_CONSECUTIVE_READS);
						`ifdef VERIFY_READ_WRITE
						if ( last_command_sent == `WRITE_CMD && consecutive > 0 ) // READ AFTER WRITE (RAW)
							`___BARRIER_WRITE___
						`endif
						//$display("----> consecutive reads = %d", consecutive);
						for (i3=0; i3<consecutive; i3++)
						begin
						    SEED = R_W_BATCH_CNT*consecutive + i3;
							last_command_sent = `READ_CMD;
							NUM_WORDS= TRAFFIC_NUM_WORDS;  //DEEPAK AXI BL is fixed to 1
							//NUM_WORDS= GENERATE_NUM_WORDS(TRAFFIC_RANDOM_NUM_WORDS, TRAFFIC_NUM_WORDS);
							ADDRESS= GENERATE_ADDRESS( AXI_TRAFFIC_ADDR_MODE, AXI_TRAFFIC_WORKING_SET_SIZE, NUM_WORDS, SEED );
							ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
							schedule_LD ( .address(ADDRESS), .num_words(NUM_WORDS) );
							DELAY(TRAFFIC_IAT_DELAY + RANDOM(TRAFFIC_IAT_JITTER));
							//$display("ID:%d|TID:%h(h)|READ:@%h|NUM_WORDS:%d", SRC_ID, TR, ADDRESS, NUM_WORDS );
							TR++;
						end
						DELAY(DELAY_AFTER_CONSECUTIVE_READS);
						R_W_BATCH_CNT++;
					end
				end
			end
			//***********************************************************
			//***********************************************************
			//***********************************************************
		end
		INJECTION_END_TIME = $time;

			$write("TGEN[%0d] STOP GENERATING TRANSACTIONS - MASK:%0d @%t\n",  SRC_ID, TRAFFIC_MASK, $time);
		
		// Requested bandwidth can't be reported for external traffic --> You have to calculate that yourself
		if ( INJECTION_END_TIME - INJECTION_START_TIME > 0 )
		begin
			REQUESTED_BANDWIDTH_R = (NUM_READ_WORDS_SCHEDULED * `AXI_DATA_W)/ (INJECTION_END_TIME - INJECTION_START_TIME);
			REQUESTED_BANDWIDTH_W = (NUM_WRITE_WORDS_SCHEDULED * `AXI_DATA_W)/ (INJECTION_END_TIME - INJECTION_START_TIME);
		end
		
		`___BARRIER_WRITE___
		`___BARRIER_READ___
		if (RLIST.size() != 0 || ARLIST.size() != 0 || AWLIST.size() != 0 || pending_ARLIST.size() != 0 || pending_AWLIST.size() != 0 || pending_WLIST.size() != 0)
			$write(`COLOR_RED,"Error: One of the FIFOs is still non-empty", `COLOR_NONE, "\n");
		Nop;
		SIM_STOP = '1;
		print_report(0);
		$finish;
	end
	
	/// Read Transaction Completed
	///*************************
	COMMAND		DUMMY_CMD;
	integer		search_index;
	logic		dump_info;
    logic [AXI4_WDATA_WIDTH-1:0]         WDATA_tmp;
    // Messages to display
	logic MSG_NO_ERROR;
	logic MSG_UNINIT;
	logic MSG_READ_X;
	logic MSG_REJECT;
	logic MSG_RW_ERROR;

	always @(ReadDone)
	begin
		//$display("Read Done: %h", RDATA);
		DUMMY_CMD = search_command_list(ARLIST, RID, search_index);
		RLIST[search_index].rdata[ RLIST[search_index].length ] = RDATA;
		RLIST[search_index].length++;
		if ( RLIST[search_index].length > `AXI_BURST_LENGTH )
			$error("RLIST[search_index].length >= BURST_LENGTH");
		
		if ( RLAST )
		begin
			`ifdef READY_QUEUE_ENABLED READY_QUEUE.push_back(RID); `endif
			CC = pop_ARLIST(RID);
			DD = pop_RLIST(RID);

			// Measure MAT
			latency = $time - CC.issue_time;
			assert (latency > 0) else $error("$time - CC.issue_time <= 0 !");
			TMAT_READ += latency;
			TMAT2_READ += real'(latency) * real'(latency);
			MIN_MAT_READ = `EVAL_MIN(MIN_MAT_READ, latency);
			MAX_MAT_READ = `EVAL_MAX(MAX_MAT_READ, latency);
			
			`ifdef VERIFY_READ_WRITE
			if (CC.length != DD.length)
				$error("Length of CC:%d and DD:%d do not match!", CC.length, DD.length);
				
			// Initialize error flags to zero
			MSG_NO_ERROR = '0;
			MSG_UNINIT = '0;
			MSG_READ_X = '0;
            MSG_REJECT = '0;
			MSG_RW_ERROR = '0;

			// Check correctness of the result for all flits
			for (k=0;k<CC.length;k++)
			begin
				{RECEIVED_ADDR2,RECEIVED_ADDR} = DD.rdata[k];
				RECEIVED_ID = RECEIVED_ID_max;
				/*  //DEEPAK -- Disabled Now
				if ( DD.rdata[k][127:0] === `INITIALIZE_DRAM_PATTERN )
					MSG_UNINIT = '1;
				*/
				if ( RECEIVED_ADDR === 'X )
					MSG_READ_X = '1;
				else if (RECEIVED_ADDR == 32'hDEADBEEF || RECEIVED_ADDR === 32'bZ )
					MSG_REJECT = '1;
				else if ( (RECEIVED_ADDR !== CC.address+k*(AXI4_WDATA_WIDTH/8)) || (RECEIVED_ADDR2 !== CC.address+k*(AXI4_WDATA_WIDTH/8)) )
					MSG_RW_ERROR = '1;
			end
			{RECEIVED_ADDR2, RECEIVED_ADDR} = DD.rdata[0];
			MSG_NO_ERROR = ~( MSG_READ_X | MSG_REJECT | MSG_RW_ERROR );
			error_flag = (MSG_NO_ERROR=='1)?'0:'X; // To be displayed in the waves
			dump_info = '1;

    		/****************/
			if (MSG_NO_ERROR === 1'b1)
			begin
				if ( `REPORT_PASSED_TRANSACTIONS=="TRUE" )
					$write(`COLOR_GREEN,"GOOD: Transaction was successful", `COLOR_NONE, "\n");
				else
					dump_info = '0;
				PASSED++;
			end
			else
			begin
				/****************/
		/*		if (MSG_UNINIT)
				begin
					UNINIT++;
					if (`REPORT_UNINIT_TRANSACTIONS=="TRUE" && AXI_TRAFFIC_MODE != "RANDOM_W_RANDOM_R" )
						$write(`COLOR_VIOLET,"WARNING: Read uninitialized location", `COLOR_NONE, "\n");
					else
						dump_info = '0;
					if (AXI_TRAFFIC_MODE == "RANDOM_WR")
					begin
						FAILED++;
						dump_info = '1;
						$write(`COLOR_RED,"ERROR: An error occurred in the received data!", `COLOR_NONE, "\n");
					end
					else
						dump_info = '0;
				end */
				/****************/
				if ( MSG_READ_X )
				begin
					$write(`COLOR_RED,"ERROR: Read X from memory", `COLOR_NONE, "\n");
					FAILED++;
				end
				/****************/
				if ( MSG_REJECT )
				begin
					$write(`COLOR_RED,"Interconnect rejected the transaction", `COLOR_NONE, "\n");
					FAILED++;
				end
				/****************/
				if ( MSG_RW_ERROR )
				begin
					$write(`COLOR_RED,"ERROR: Read value different from written value", `COLOR_NONE, "\n");
					FAILED++;
				end
				/****************/
			end

			if ( dump_info )
			begin
				$write("  @%0t TRANS=%0d\n", $time, TRANS);
				//$write("  R.SID=       %h(h) W.SID=       %h(h)\n", MY_USER_ID, RECEIVED_USER);
				$write("  R.ADD=  %0h(h) W.ADD=  %0h(h)\n", CC.address, RECEIVED_ADDR );
				$write("  R.TID=  %0d    W.TID=  %0d\n", CC.id, RECEIVED_ID);
				//$write("  R.LEN=  %0d    W.LEN=  %0d\n", CC.length, DD.length );
				for (k=0;k<CC.length;k++)
				begin
                    /* Recreate the previously written value in WDATA_tmp */
                    RECEIVED_ID_max = CC.id;
                    RECEIVED_ADDR = CC.address+k*(AXI4_WDATA_WIDTH/8);
					RECEIVED_ADDR2 = CC.address+k*(AXI4_WDATA_WIDTH/8);
                  //  RECEIVED_USER = MY_USER_ID;
                    WDATA_tmp = {RECEIVED_ADDR2, RECEIVED_ADDR};
					$write("  RDATA[%0d]=%h   WDATA: %h\n", k, DD.rdata[k], WDATA_tmp);
				end
				$write("................................\n");
			end
			`endif
		end
	end

	/// Write Transaction Completed
	///*************************
	always @(WriteDone)
	begin
		CC = pop_AWLIST(BID);
		// Measure MAT
		latency = $time - CC.issue_time;
		assert ( latency > 0) else $error("$time - CC.issue_time <= 0 !");
		TMAT_WRITE += latency;
		TMAT2_WRITE += real'(latency) * real'(latency);
		MIN_MAT_WRITE = `EVAL_MIN(MIN_MAT_WRITE, latency);
		MAX_MAT_WRITE = `EVAL_MAX(MAX_MAT_WRITE, latency);
		`ifdef VERIFY_READ_WRITE
		PASSED++;
		`endif
		`ifdef READY_QUEUE_ENABLED READY_QUEUE.push_back(BID); `endif
	end
	
	/// Inject the pending transactions
	///*************************
	COMMAND	AWinj;
	COMMAND	ARinj;
	DATA	DWinj;
	logic   Winjected, Rinjected;
	/// WRITE TRANSACTIONS
	always
	begin
		Winjected = '0;
		if ( AXI_TRAFFIC_MODE != "EXTERNAL" )
		begin
			if ( pending_AWLIST.size() > 0 ) // Synthetic traffic
			begin
				DELAY(`THROTTLING_JITTER); /// THROTTLING
				AWinj = pending_AWLIST.pop_front();
				DWinj = pending_WLIST.pop_front();
				while ( allocate_new_transaction("W") == '0 )
				begin 
					STALLS_allocate++;
					@ ( posedge ACLK );
				end
				//AWinj.address = remap( AWinj.address ); //DEEPAK-- Currently Disabled Remapping
				AWinj.id = curr_wid;
				DWinj.id = curr_wid;
				fork
					inject_ST_AW(AWinj);
					inject_ST_DW(AWinj, DWinj);
				join
				Winjected = '1;
			end
			if ( Winjected == 1'b0 ) @(posedge ACLK); // If we have already injected a transaction, we don't need to wait anymore
		end

	end
	/// READ TRANSACTIONS
	always
	begin
		Rinjected = '0;
		if ( AXI_TRAFFIC_MODE != "EXTERNAL" )
		begin
			if ( pending_ARLIST.size() > 0 ) // Synthetic traffic
			begin
				DELAY(`THROTTLING_JITTER); /// THROTTLING
				ARinj = pending_ARLIST.pop_front();
				while ( allocate_new_transaction("R") == '0 )
				begin
					STALLS_allocate++;
					@ ( posedge ACLK );
				end
			//	ARinj.address = remap( ARinj.address );  //DEEPAK-- Currently Disabled Remapping
				ARinj.id = curr_rid;
				fork
					inject_LD(ARinj);
				join
				Rinjected = '1;
			end
			if ( Rinjected == 1'b0 ) @(posedge ACLK); // If we have already injected a transaction, we don't need to wait anymore
		end

	end
	
	/// Events
	///*************************
	logic delayed_ACLK;
	assign #(`SOD)delayed_ACLK = ACLK;
	always @(posedge delayed_ACLK)
	begin
		if((AWVALID == 1'b1) && (AWREADY == 1'b1))	-> req_AW_granted;
		if((ARVALID == 1'b1) && (ARREADY == 1'b1))	-> req_AR_granted;
		if((WVALID == 1'b1) && (WREADY == 1'b1))	-> req_DW_granted;
		if((BVALID == 1'b1) && (BREADY == 1'b1))	-> WriteDone;
		if((RVALID == 1'b1) && (RREADY == 1'b1))	-> ReadDone;
		if(AWLIST.size() == 0)				-> AWLIST_Empty; // Write Barrier
		if(ARLIST.size() == 0)				-> ARLIST_Empty; // Read Barrier
		if(pending_AWLIST.size() == 0)			-> pending_AWLIST_Empty; // Write Barrier
		if(pending_ARLIST.size() == 0)			-> pending_ARLIST_Empty; // Read Barrier
	end

	// TODO FOR TEST LATER PUT A LIMITED FIFO HERE
	assign BREADY = 1'b1;
	assign RREADY = 1'b1;
	
endmodule
