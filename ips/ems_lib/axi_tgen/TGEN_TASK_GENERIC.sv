
task Nop;
begin
	#(`SOD);
	/*AWID        = '0;	*/AWADDR      = '0;	AWLEN       = '0;	AWSIZE      = '0;
	AWBURST     = '0;	AWLOCK      = '0;	AWCACHE     = '0;	AWPROT      = '0;
	AWREGION    = '0;	AWUSER      = '0;	AWQOS       = '0;	AWVALID     = '0;
	WDATA       = '0;	WSTRB       = '0;	WLAST       = '0;	WUSER       = '0;
	WVALID      = '0;	/*ARID        = '0;*/	ARADDR      = '0;	ARLEN       = '0;
	ARSIZE      = '0;	ARBURST     = '0;	ARLOCK      = '0;	ARCACHE     = '0;
	ARPROT      = '0;	ARREGION    = '0;	ARUSER      = '0;	ARQOS       = '0;
	ARVALID     = '0;
	@(posedge ACLK);
end
endtask

// Nop
//******************************
task DELAY;
	input integer Cycles;
	integer i;
begin
	for (i=0; i<Cycles; i++)
		@(posedge ACLK);
end
endtask

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Store (Address Write)
//******************************
task schedule_ST_AW;
input   [AXI4_ADDRESS_WIDTH-1:0]	       		address;  
input   integer					num_words;
logic  [AXI4_ADDRESS_WIDTH-1:0]	       		remapped_addr;
begin
	pending_AWLIST.push_back(new_command('X, address, num_words)); // ID is still unknown: 'X
end
endtask

// Store (Data Write)
//******************************
task schedule_ST_DW;
input  [AXI4_ADDRESS_WIDTH-1:0]	       			address;		// For verification only
input  [`AXI_BURST_LENGTH-1:0][AXI4_WDATA_WIDTH-1:0]	wdata;
input  [`AXI_BURST_LENGTH-1:0][AXI_NUMBYTES-1:0]		be;   
input  integer						num_words;
begin
	pending_WLIST.push_back(new_data('X, wdata, num_words, be));			// ID is still unknown: 'X
	NUM_WRITE_WORDS_SCHEDULED+=num_words;
	DELAY(num_words); // Store has multiple flits
end
endtask

// Load (Address Write)
//******************************
task schedule_LD;
input  [AXI4_ADDRESS_WIDTH-1:0]	       		address;
input  integer					num_words;
logic  [AXI4_ADDRESS_WIDTH-1:0]	       		remapped_addr;
begin
	pending_ARLIST.push_back(new_command('X, address, num_words));	// ID is still unknown: 'X
	NUM_READ_WORDS_SCHEDULED+=num_words;
	DELAY(1); // Load has only 1 flit
end
endtask
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Store (Address Write)
//******************************
task inject_ST_AW;
	input   COMMAND CCC;
begin
	AWLIST.push_back(CCC);
	if (CCC.length > `AXI_BURST_LENGTH )begin $error("Number of words more than AXI bus can transfer!"); $finish(); end
	#(`SOD);
	AWID        <=  CCC.id;
	AWADDR      <=  CCC.address;
	AWLEN       <=  CCC.length-1;
	AWSIZE      <=  3'b011;
	AWBURST     <=  2'b01;
	AWLOCK      <= '0;
	AWCACHE     <= '0;
	AWPROT      <= '0;
	AWREGION    <= '0;
	AWUSER      <=  MY_USER_ID;
	AWQOS       <= '0;
	AWVALID     <=  1'b1;
	@(req_AW_granted);
	
	//AWID        <= '0;
	AWADDR      <= '0;
	AWLEN       <= '0;
	AWSIZE      <= '0;
	AWBURST     <= '0;
	AWLOCK      <= '0;
	AWCACHE     <= '0;
	AWPROT      <= '0;
	AWREGION    <= '0;
	AWUSER      <= '0;
	AWQOS       <= '0;
	AWVALID     <= '0;
	TRANS+=1;			// Number of transactions
	NUM_WRITES+=1;			// Number of write transactions
	NUM_WRITE_WORDS+= CCC.length;	// Number of words written
end
endtask

// Store (Data Write)
//******************************
task inject_ST_DW;
	input   COMMAND CCC;
	input   DATA DDD;
	logic  [15:0] id_max;
	integer i;
begin
	for ( i=0; i<CCC.length; i++)
	begin
		#(`SOD);
		`ifdef VERIFY_READ_WRITE
			id_max = CCC.id;
			WDATA  <= {CCC.address+i*(AXI4_WDATA_WIDTH/8),CCC.address+i*(AXI4_WDATA_WIDTH/8)}; //DEEPAK 
			WSTRB  <= '1;
		`else
			WDATA  <= DDD.rdata[i]; // Write Data
			WSTRB  <= DDD.be[i];   
		`endif
		WLAST  <= (i<CCC.length-1)?1'b0:1'b1;
		WUSER  <= MY_USER_ID;   
		WVALID <= 1'b1;  
		@(req_DW_granted);
	end
	WDATA      <= '0;
	WSTRB      <= '0;
	WLAST      <= '0;
	WUSER      <= '0;
	WVALID     <= '0;
end
endtask

// Load (Address Write)
//******************************
task inject_LD;
	input   COMMAND CCC;
begin
	ARLIST.push_back(CCC);
	RLIST.push_back(new_data(CCC.id, `DONT_CARE, 0, 'X));
	if (CCC.length > `AXI_BURST_LENGTH )begin $error("Number of words more than AXI bus can transfer!"); $finish(); end
	#(`SOD);
	ARID        <=  CCC.id;
	ARADDR      <=  CCC.address;
	ARLEN       <=  CCC.length-1;
	ARSIZE      <=  3'b011;
	ARBURST     <=  2'b01;
	ARLOCK      <= '0;
	ARCACHE     <= '0;
	ARPROT      <= '0;
	ARREGION    <= '0;
	ARUSER      <=  MY_USER_ID;
	ARQOS       <= '0;
	ARVALID     <=  1'b1;
	@(req_AR_granted);
// 	ARID        <= '0;
	ARADDR      <= '0;
	ARLEN       <= '0;
	ARSIZE      <= '0;
	ARBURST     <= '0;
	ARLOCK      <= '0;
	ARCACHE     <= '0;
	ARPROT      <= '0;
	ARREGION    <= '0;
	ARUSER      <= '0;
	ARQOS       <= '0;
	ARVALID     <= '0;
	TRANS+=1;			// Number of transactions
	NUM_READS+=1;			// Number of read transactions
	NUM_READ_WORDS+= CCC.length;	// Number of words read
end
endtask

// Truncate address based on system properties
//******************************
function longint unsigned TRUNCATE_ADDRESS;
	input longint unsigned addr;
	input integer NUM_WORDS;
	input integer DATA_WIDTH;
	longint unsigned total_mem_size;
	integer unsigned offset_bits;
begin
	//total_mem_size = `N_INIT_PORT * `DRAM_CHANNEL_SIZE_B;
	total_mem_size = `TOTAL_MEM_SIZE; 
	offset_bits = NUM_WORDS * DATA_WIDTH / 8;
	addr = addr % total_mem_size;
	addr = addr / offset_bits;
	addr = addr * offset_bits;
	//$display("total_mem_size=%h, offset_bits=%h, addr=%h", total_mem_size, offset_bits, addr);
	return addr;
end
endfunction;

// Generate number of words
//******************************
/* //DEEPAK-- disabled due to fixed AXI BL = 1
function longint unsigned GENERATE_NUM_WORDS;
	input string IS_RANDOM;
	input integer MAX_NUM_WORDS;
	integer NUM_WORDS;
begin
	if (IS_RANDOM == "TRUE")
		NUM_WORDS=2**RANDOM(`EVAL_LOG2(MAX_NUM_WORDS*2));
	else
		NUM_WORDS=MAX_NUM_WORDS;
	return NUM_WORDS;
end
endfunction; */

// Generate address
//******************************
function longint unsigned GENERATE_ADDRESS;
	input string ADDR_MODE;
	input integer WSS; // Working set size
	input integer NUM_WORDS;
	input longint unsigned TR; // Sequence Number
	longint unsigned ADDRESS;
    longint unsigned total_mem_size;
	logic[`ROW_ADDR_WDTH-1:0] ROW; 
    logic[`BA_ADDR_WDTH-1:0] BANK;
    logic[`COL_ADDR_WIDTH-1:0] COL;	
begin
        total_mem_size = `TOTAL_MEM_SIZE;	
        ADDRESS = 0;
	case (ADDR_MODE)
		"FIXED_ZERO": ADDRESS = 0;
		"UNIFORM_ALL":
		begin
          process::self().srandom(TR);
		  //ADDRESS = {$urandom_range(1,total_mem_size)};
		  ROW = {$urandom_range(0,(2**`ROW_ADDR_WDTH)-1)};
		  //ROW = {$urandom_range(0,7)};
		  BANK = {$urandom_range(0,(2**`BA_ADDR_WDTH)-1)};
		  //BANK = {$urandom_range(6,7)};
	      COL = {$urandom_range(0,(2**`COL_ADDR_WIDTH)-1)};
          `ifdef BRC
		    ADDRESS = {2'b00,BANK,ROW,COL};
          `endif
          `ifdef RBC
		    ADDRESS = {2'b00,ROW,BANK,COL};
          `endif		   		  
		end  
		"STREAM":
		begin
			ADDRESS = TR * (2**`ADDRESS_OFFSET(NUM_WORDS,`AXI_DATA_W));
			ADDRESS = ADDRESS % WSS;
			ADDRESS += SRC_ID*total_mem_size/`N_TARG_PORT + total_mem_size/(`N_TARG_PORT*2);
		end
		"UNIFORM_LOCAL":
		begin
			ADDRESS  = RANDOM(WSS);
			ADDRESS += SRC_ID*total_mem_size/`N_TARG_PORT + total_mem_size/(`N_TARG_PORT*2);
		end
		default:
		begin
			$error("Illegal address mode: %s!", ADDR_MODE);
			$finish();
		end
	endcase
	ADDRESS = TRUNCATE_ADDRESS(ADDRESS, NUM_WORDS, `AXI_DATA_W);
	return ADDRESS;
end
endfunction;

longint unsigned READY_QUEUE[$];

// Allocate a free Transaction_ID and return it either in curr_rid or in curr_wid
// Returns successful or not
//******************************
function logic allocate_new_transaction;
	input string 			  ttype;
	static logic   [AXI4_ID_WIDTH-1:0] id = 0;
begin
	if (`TID_ALLOCATION_MODE == "LINEAR")
	begin
		id = id + 1;
	end
	else
	if (`TID_ALLOCATION_MODE == "ZERO")
	begin
		id = 0;
	end
	else
	if (`TID_ALLOCATION_MODE == "READY_QUEUE")
	begin
		if ( READY_QUEUE.size() == 0 )
			return '0; // Failed
		id = READY_QUEUE.pop_front();
	end
	else
	begin
		$error("Illegal value for TID_ALLOCATION_MODE!");
		$finish();
	end
	if ( ttype == "W" )
		curr_wid = id;
	else
		curr_rid = id;
		
	return '1; // Successful
end
endfunction;

// Initialize ready queue to all ready locations: 0, 1, 2, ...
//******************************
task initialize_ready_queue;
	integer i;
begin
	for ( i=0; i< `MAX_INFLIGHT_TRANS; i++ )
		READY_QUEUE.push_back(i);
	$display("Ready queue initialized successfully! [MiT=%d]", `MAX_INFLIGHT_TRANS);
end
endtask; 

// Print reports whenever called
//******************************
task print_report;
	input integer ID;
begin
	// Remaining stats: Pend.W Pend.R NW NR
	`ifdef VERIFY_READ_WRITE
	$display("TGEN[%0d] %0d TR\t%0d PASS\t%0d UNIN\t%0d RACE\t%0d FAIL",ID , TRANS, PASSED, UNINIT, RACES, FAILED );
	`else
	$display("TGEN[%0d] %0d TR",ID , TRANS);
	`endif
//	$display("TGEN[%d] %d TR\t%d PASS\t%d UNIN\t%d RACE\t%d FAIL\t%d P.AW\t%d P.AR",ID , TRANS, PASSED, UNINIT, RACES, FAILED, pending_AWLIST.size(), pending_ARLIST.size()); //// NUM_WRITES, NUM_READS , 
end
endtask

// Address mapping
//******************************
/* //DEEPAK-- Currently Disabled
task report_address_mapping;
begin
	$display("DEFAULT ADDRESS MAPPING:  [CH-LB-RC-OF] CH=%d, LB=%d, RC=%d, OF=%d", `nbits_ch, `nbits_lb, `nbits_rc, `nbits_of);
	$display("ADDRESS REMAPPED TO:      [%s]", `ADDRESS_MAPPING);
end
endtask
*/
// Remap address based on the address mapping scheme
//******************************
/* //DEEPAK-- Currently Disabled
function [AXI4_ADDRESS_WIDTH-1:0] remap;
input  [AXI4_ADDRESS_WIDTH-1:0]		address;
logic  [AXI4_ADDRESS_WIDTH-1:0]		remapped_addr;
logic  [`nbits_ch-1:0 ] bits_ch, zeros_ch;
logic  [`nbits_lb-1:0 ] bits_lb, zeros_lb;
logic  [`nbits_rc-1:0 ] bits_rc, zeros_rc;
logic  [`nbits_of-1:0 ] bits_of, zeros_of;
logic  [`AXI_ADDRESS_W-`nbits_ch-`nbits_lb-`nbits_rc-`nbits_of-1:0] bits_uu;
begin
	{zeros_ch, zeros_lb, zeros_rc,  zeros_of} = '0;
	`include "_address_map.v"
	`ifdef REPORT_ADDRESS_REMAP
	$display("ADDR= %b, {bits_uu=%b, bits_ch=%b, bits_lb=%b, bits_rc=%b, bits_of=%b}", address, bits_uu, bits_ch, bits_lb, bits_rc, bits_of );
	$display("REMAP=%b", remapped_addr);
	`endif
	return remapped_addr;
end
endfunction */
