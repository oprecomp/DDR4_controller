module bram_fifo_512x64
#(
  //Don't change
   parameter                       DATA_WIDTH = 512,
   parameter                       DATA_DEPTH = 64
)
(
   input  logic                                    clk,
   input  logic                                    rst_n,
   //PUSH SIDE
   input  logic [DATA_WIDTH-1:0]                   data_i,
   input  logic                                    valid_i,
   output logic                                    grant_o,
   //POP SIDE
   output logic [DATA_WIDTH-1:0]                   data_o,
   output logic                                    valid_o,
   input  logic                                    grant_i,

   input  logic                                    test_mode_i
);


   // Local Parameter
   localparam ADDR_DEPTH = $clog2(DATA_DEPTH);
   enum logic [1:0] { EMPTY, FULL, MIDDLE } CS, NS;
   // Internal Signals

   logic       gate_clock;
   logic       clk_gated;

   logic [ADDR_DEPTH-1:0]          Pop_Pointer_CS,  Pop_Pointer_NS;
   logic [ADDR_DEPTH-1:0]          Push_Pointer_CS, Push_Pointer_NS;
   logic [ADDR_DEPTH-1:0] 	   Pop_Pointer_BRAM;
   logic [DATA_WIDTH-1:0]          FIFO_REGISTERS[DATA_DEPTH-1:0];
   integer                         i;
   logic [DATA_WIDTH-1:0] 	   data_i_q, data_o_BRAM;
   logic 			   BRAM_overlap_d,BRAM_overlap_q;

   assign data_o =  BRAM_overlap_q?data_i_q:data_o_BRAM;



   // Parameter Check
   // synopsys translate_off
   initial
   begin : parameter_check
      integer param_err_flg;
      param_err_flg = 0;

      if (DATA_WIDTH < 1)
      begin
         param_err_flg = 1;
         $display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_WIDTH \
                  (legal range: greater than 1)", DATA_WIDTH );
      end

      if (DATA_DEPTH < 1)
      begin
         param_err_flg = 1;
         $display("ERROR: %m :\n  Invalid value (%d) for parameter DATA_DEPTH \
                  (legal range: greater than 1)", DATA_DEPTH );
      end
   end
   // synopsys translate_on


   assign clk_gated = clk;

   // UPDATE THE STATE
   always_ff @(posedge clk, negedge rst_n)
   begin
       if(rst_n == 1'b0)
       begin
               CS              <= EMPTY;
	       BRAM_overlap_q  <= '0;
               Pop_Pointer_CS  <= {ADDR_DEPTH {1'b0}};
               Push_Pointer_CS <= {ADDR_DEPTH {1'b0}};
	       data_i_q        <= '0;
	       Pop_Pointer_BRAM <= '1;
       end
       else
       begin
               CS              <= NS;
               Pop_Pointer_CS  <= Pop_Pointer_NS;
               Push_Pointer_CS <= Push_Pointer_NS;
	       data_i_q        <= data_i;
	       BRAM_overlap_q  <= BRAM_overlap_d;   
	       if(NS != EMPTY)
		 Pop_Pointer_BRAM <= Pop_Pointer_NS;
       end
   end

   assign BRAM_overlap_d = (CS==EMPTY)||(valid_i &&
			   ((Pop_Pointer_NS == Push_Pointer_NS -1)||
			   ((Pop_Pointer_NS == DATA_DEPTH-1) &&
			    (Push_Pointer_NS == 0))));

   // Compute Next State
   always_comb
   begin
      gate_clock      = 1'b0;

      case(CS)

      EMPTY:
      begin
          grant_o = 1'b1;
          valid_o = 1'b0;

          case(valid_i)
          1'b0 :
          begin
                  NS                      = EMPTY;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;
                  gate_clock      = 1'b1;
          end

          1'b1:
          begin
                  NS                      = MIDDLE;
                  Push_Pointer_NS = Push_Pointer_CS + 1'b1;
                  Pop_Pointer_NS  = Pop_Pointer_CS;
          end

          endcase
      end//~EMPTY

      MIDDLE:
      begin
          grant_o = 1'b1;
          valid_o = 1'b1;

          case({valid_i,grant_i})

          2'b01:
          begin
                  gate_clock      = 1'b1;

                  if((Pop_Pointer_CS == Push_Pointer_CS -1 ) ||
                     ((Pop_Pointer_CS == DATA_DEPTH-1) && (Push_Pointer_CS == 0)))
                          NS              = EMPTY;
                  else
                          NS              = MIDDLE;

                  Push_Pointer_NS = Push_Pointer_CS;

                  if(Pop_Pointer_CS == DATA_DEPTH-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS + 1'b1;
          end

          2'b00 :
          begin
                  gate_clock      = 1'b1;
                  NS              = MIDDLE;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;
          end

          2'b11:
          begin
                  NS              = MIDDLE;

                  if(Push_Pointer_CS == DATA_DEPTH-1)
                          Push_Pointer_NS = 0;
                  else
                          Push_Pointer_NS = Push_Pointer_CS + 1'b1;

                  if(Pop_Pointer_CS == DATA_DEPTH-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS  + 1'b1;
          end

          2'b10:
          begin
                  if(( Push_Pointer_CS == Pop_Pointer_CS - 1) ||
                     ((Push_Pointer_CS == DATA_DEPTH-1) && (Pop_Pointer_CS == 0)))
                          NS = FULL;
                  else
                          NS = MIDDLE;

                  if(Push_Pointer_CS == DATA_DEPTH - 1)
                          Push_Pointer_NS = 0;
                  else
                          Push_Pointer_NS = Push_Pointer_CS + 1'b1;

                  Pop_Pointer_NS = Pop_Pointer_CS;
          end

          endcase
      end

      FULL:
      begin
          grant_o = 1'b0;
          valid_o = 1'b1;
          gate_clock = 1'b1;

          case(grant_i)
          1'b1:
          begin
                  NS = MIDDLE;

                  Push_Pointer_NS = Push_Pointer_CS;

                  if(Pop_Pointer_CS == DATA_DEPTH-1)
                          Pop_Pointer_NS  = 0;
                  else
                          Pop_Pointer_NS  = Pop_Pointer_CS  + 1'b1;
          end

          1'b0:
          begin
                  NS              = FULL;
                  Push_Pointer_NS = Push_Pointer_CS;
                  Pop_Pointer_NS  = Pop_Pointer_CS;
          end
          endcase

      end // end of FULL

      default :
      begin
          gate_clock      = 1'b1;
          grant_o         = 1'b0;
          valid_o         = 1'b0;
          NS              = EMPTY;
          Pop_Pointer_NS  = 0;
          Push_Pointer_NS = 0;
      end

      endcase
   end

   /*always_ff @(posedge clk_gated, negedge rst_n)
   begin
      if(rst_n == 1'b0)
      begin
      for (i=0; i< DATA_DEPTH; i++)
         FIFO_REGISTERS[i] <= {DATA_WIDTH {1'b0}};
      end
      else
      begin
         if((grant_o == 1'b1) && (valid_i == 1'b1))
            FIFO_REGISTERS[Push_Pointer_CS] <= data_i;
      end
   end // always_ff @ (posedge clk_gated, negedge rst_n)*/
   
   blk_mem_gen_0 bram_512x64 (
			      .clka(clk_gated),    // input wire clka
			      .wea((grant_o == 1'b1) && (valid_i == 1'b1)),      // input wire [0 : 0] wea
			      .addra(Push_Pointer_CS),  // input wire [5 : 0] addra
			      .dina(data_i),    // input wire [511 : 0] dina
			      .clkb(clk),    // input wire clkb
			      .addrb(BRAM_overlap_d?Pop_Pointer_BRAM:
				     Pop_Pointer_NS),  // input wire [5 : 0] addrb
			      .doutb(data_o_BRAM)  // output wire [511 : 0] doutb
		       );
   
   //assign data_o = FIFO_REGISTERS[Pop_Pointer_CS];

endmodule // generic_fifo
