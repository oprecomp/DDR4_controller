`ifdef CORNER_WC
`define CLK_PERIOD_SYS 8.0 // WC corner 6-5-5 CWL 5 
`else
  `ifdef DLL_OFF
  `define CLK_PERIOD_SYS 24.0  // dll off default 6-4-4 CWL 6 setting
   `else
  `define CLK_PERIOD_SYS 12.0  // default 7-6-6 CWL 6 setting
  `endif
`endif
//`define CLK_PERIOD_SYS 32  // DLL off
//
`define DRAM_INIT_TIME_ns 1000 //50 ns //DEEPAK --Check this
`define NUM_TRANSACTIONS 5000
//`define STOP_SIM_MASK 1
`define AXI_TRAFFIC_MODE  "RANDOM_W_RANDOM_R"//"RANDOM_WR" //"FILL_R" "FILL_W_FILL_R" "RANDOM_WR" "RANDOM_W_RANDOM_R" "PIM_DOUBLE_BUFFER" "MANUAL" "EXTERNAL"
`define TRAFFIC_NUM_WORDS 1  // AXI Burst length
`define TRAFFIC_RANDOM_NUM_WORDS 10
`define AXI_TRAFFIC_WORKING_SET_SIZE 10  //DEEPAK //Used only for AXI_TRAFFIC_ADDR_MODE = UNIFORM_LOCAL
`define AXI_TRAFFIC_ADDR_MODE "UNIFORM_ALL" // "FIXED_ZERO"  "UNIFORM_LOCAL"  //Check GENERATE_ADDRESS function for details
`define NUM_CONSECUTIVE_WRITES 1
`define NUM_CONSECUTIVE_READS 1
`define VAR_CONSECUTIVE_WRITES 0  
`define VAR_CONSECUTIVE_READS 0
`define DELAY_AFTER_CONSECUTIVE_WRITES 0 //DEEPAK-- for generating random delay between consecutive writes
`define DELAY_AFTER_CONSECUTIVE_READS 0 
`define TRAFFIC_INITIAL_DELAY 0
`define TRAFFIC_INITIAL_JITTER 0
`define TRAFFIC_IAT_DELAY 0
`define TRAFFIC_IAT_JITTER 0
`define THROTTLING_JITTER 0 
`define TRAFFIC_MASK 1
`define NOP_CMD 0
`define WRITE_CMD 1
`define READ_CMD 2
`ifdef GATE_LEVEL
 `define SOD 2
`elsif GATE_LEVEL2
 `define SOD 2
`else
 `define SOD 0
`endif
`define TOTAL_MEM_SIZE 2**(29)
`define ROW_ADDR_WDTH 14
`define BA_ADDR_WDTH 4
`define COL_ADDR_WIDTH 10
`define RBC//RBC  //Address Mapping BRC (Bank-Row-Col) or RBC (Row-Bank-Col)
/*************************************************************/
/////////////////////// _params.axi ///////////////////////////
/*************************************************************/
`define N_INIT_PORT	1
`define N_TARG_PORT	1
`define AXI_DATA_W	512
//`define AXI_ID_IN	(`EVAL_LOG2(44))
//`define N_REGION 	1
`define AXI_BURST_LENGTH 1
`define MAX_INFLIGHT_TRANS 128  //DEEPAK -- Number of transactions in the controller
`define TID_ALLOCATION_MODE "READY_QUEUE"
//*****************************
`define REPORT_PASSED_TRANSACTIONS "TRUE"
`define REPORT_RACED_TRANSACTIONS "TRUE"
`define REPORT_UNINIT_TRANSACTIONS "TRUE"
//`define PERIODIC_REPORT_PERIOD 50000
`define VERIFY_READ_WRITE
//`define MEASURE_LINK_STATISTICS
`define READY_QUEUE_ENABLED
//`define COARSE_BURST_MULTIPLEXING
/**********************************************************************/
//////////////params_global///////////////////////////////////////////
/**********************************************************************/
//`ifndef PARAMS_GLOBAL_HEADER
//`define PARAMS_GLOBAL_HEADER

//`define  SOD 0.01

// DEFINITIONS ONLY (NOT THE PARAMETERS)

// Notice: This function is Ceil{Log2{X}}, so EVAL_LOG2(3) = 2
`define EVAL_LOG2(VALUE) ((VALUE) <= ( 1 ) ? 0 : (VALUE) <= ( 2 ) ? 1 : (VALUE) <= ( 4 ) ? 2 : (VALUE) <= (8) ? 3 :(VALUE) <= ( 16 )  ? 4 : (VALUE) <= ( 32 )  ? 5 : (VALUE) <= ( 64 )  ? 6 : (VALUE) <= ( 128 ) ? 7 : (VALUE) <= ( 256 ) ? 8 : (VALUE) <= ( 512 ) ? 9 : (VALUE) <= ( 1024 ) ? 10 : (VALUE) <= ( 2048 ) ? 11 : (VALUE) <= ( 4096 ) ? 12 : (VALUE) <= ( 8192 ) ? 13 : (VALUE) <= ( 16384 ) ? 14 : (VALUE) <= ( 32768 ) ? 15 : 15)

// Notice: This function has been manipulated to avoid zero-sized arrays. So it returns 1 instead of 0 when its input argument is equal to 1
`define EVAL_LOG2_MANIPULATED(VALUE) ((VALUE) <= ( 2 ) ? 1 : (VALUE) <= ( 4 ) ? 2 : (VALUE) <= (8) ? 3 :(VALUE) <= ( 16 )  ? 4 : (VALUE) <= ( 32 )  ? 5 : (VALUE) <= ( 64 )  ? 6 : (VALUE) <= ( 128 ) ? 7 : (VALUE) <= ( 256 ) ? 8 : (VALUE) <= ( 512 ) ? 9 : (VALUE) <= ( 1024 ) ? 10 : (VALUE) <= ( 2048 ) ? 11 : (VALUE) <= ( 4096 ) ? 12 : (VALUE) <= ( 8192 ) ? 13 : (VALUE) <= ( 16384 ) ? 14 : (VALUE) <= ( 32768 ) ? 15 : 15)

// Ceil Function
`define INT_DIV(A,B) (unsigned'((A- (int' (A/B))* B > 0) ? int' (A/B) +1  : int' (A/B)))

// Min Function
`define EVAL_MIN(A,B) ((A>B)? B : A)

// Max Function
`define EVAL_MAX(A,B) ((A>B)? A : B)

// Address Offset based on the width of the data bus (W:bits), and the number of words to fetch (N)
`define ADDRESS_OFFSET(N,W) (`EVAL_LOG2(N)+`EVAL_LOG2(W/8))

////////////////////////////////////////////////////////////////////////////

// This is the system fast clock, and can be different from DRAM Clock (CLK_PERIOD_DRAM)
//`define CLK_PERIOD_SYS	1.0

// Colors (Only usable in linux shell)
`define COLOR_NONE	"\033[0m"
`define COLOR_RED	"\033[1;31m"
`define COLOR_GREEN	"\033[1;32m"
`define COLOR_YELLOW	"\033[1;33m"
`define COLOR_BLUE	"\033[1;34m"
`define COLOR_VIOLET	"\033[1;35m"

// Errors defined in the Generic TGEN

`define NAN 2000000000

`ifndef SYNTHESIS
// Generate a random number up to the limit
//******************************
function longint RANDOM;
	input longint LIMIT;
begin
	if ( LIMIT == 0 || LIMIT == 1 )
		return 0;
	return {$random} % LIMIT;
end
endfunction;

// Cleanup a string to convert it to a file name
//******************************
function string cleanup_string;
	input string s;
	integer k;
begin
	for ( k=0; k < s.len(); k++ )
	begin
		if ( 
		s.getc(k) == "[" || 
		s.getc(k) == "]" ||
		s.getc(k) == "/" ||
		s.getc(k) == "\\"
		) s.putc(k,"_");
	end
	return s;
end
endfunction;
`endif

`ifdef SYNTHESIS
`define DONT_CARE '0
`else
`define DONT_CARE 'X
`endif


`define nbits_ch (byte'(`EVAL_LOG2(`N_INIT_PORT)))				// Channel bits
`define nbits_lb (byte'(`EVAL_LOG2(`BANKS_PER_VAULT)))				// Layer + Bank bits
`define nbits_of (byte'(`EVAL_LOG2(`CH_BURST_LENGTH * `DRAM_BUS_WIDTH / 8)))	// Offset bits
`define nbits_rc (byte'(`row_size+`column_size-`EVAL_LOG2(`CH_BURST_LENGTH)))	// Row+Col bits

/******************************************************/
///////params_axi////////////////
/******************************************************/
`ifndef PARAMS_AXI_HEADER
`define PARAMS_AXI_HEADER

`define OKAY    2'b00
`define EXOKAY  2'b01
`define SLVERR  2'b10
`define DECERR  2'b11

// `define N_INIT_PORT	8
// `define N_TARG_PORT	5
// `define N_REGION	4
// `define AXI_ID_IN	8						// ID Before the AXI Interconnect
// `define AXI_DATA_W	32
// `define AXI_BURST_LENGTH 	8
`define AXI_USER_W	10
`define AXI_ADDRESS_W	32

`define AXI_NUMBYTES		`AXI_DATA_W/8
//`define AXI_ID_OUT		`AXI_ID_IN + `EVAL_LOG2(`N_TARG_PORT)		// ID After the AXI Interconnect
`define AXI_OFFSET_BITS		(`EVAL_LOG2(`AXI_DATA_W) - 3)			// Lowest bits of address which should be ignored
`define AXI_BURST_LENGTH_LOG2	(`EVAL_LOG2(`AXI_BURST_LENGTH))
`define CONV_TO_AXI_BURST(BURST)	((BURST+1)/`DATA_WIDTH_RATIO-1)

`endif
