module priority_arbiter
  #(
    parameter PRIORITY_WIDTH = 8,
    parameter DATA_WIDTH = 2,
    parameter NR_INPUTS = 8
    )
   (
    input [NR_INPUTS-1:0][PRIORITY_WIDTH-1:0] priority_i,
    input [NR_INPUTS-1:0][DATA_WIDTH-1:0]     data_i,
    input [NR_INPUTS-1:0] 		      req,
    input [PRIORITY_WIDTH-1:0] 		      highest_priority,
    output [DATA_WIDTH-1:0] 		      data_o,
    output 				      valid,
    output [$clog2(NR_INPUTS)-1:0] 	      grant
    );

   // This module accepts 8 input reqs, each req is associated with priority.
   // The data request with highest priority is passed to output.
   //  Priority order: highest priority i/p value to highest priority-1(lowest).
   // It is in wrap around fashion.

   logic [$clog2(NR_INPUTS)-1:0] 	      select_lcl;
   logic [NR_INPUTS-1:0][PRIORITY_WIDTH-1:0]  priority_lcl;

   generate
      for(genvar i = 0; i<NR_INPUTS; i++)
	assign priority_lcl[i] = priority_i[i] - highest_priority;
   endgenerate

   assign grant = select_lcl;
   
   /*lowest_nr_identifier
     #(
       .NR_WIDTH(PRIORITY_WIDTH),
       .NR_INPUTS(NR_INPUTS)
       )highest_priority_selector
       (
	.nr(priority_lcl),
	.req(req),
	.lowest_nr(),
	.lowest_line(select_lcl),
	.lowest_valid(valid)
	);

   mux_1
     #(
       .WIDTH(DATA_WIDTH),
       .NR_INPUTS(NR_INPUTS)
       )mux_data
       (
	.in(data_i),
	.sel(select_lcl),
	.out(data_o)
	);*/

    priority_mux
     #(
       .NR_WIDTH(PRIORITY_WIDTH),
       .NR_INPUTS(NR_INPUTS),
       .DATA_WIDTH(DATA_WIDTH)
       )highest_priority_selector_mux
       (
	.priority_nr_in(priority_lcl),
	.req(req),
	.data_in(data_i),
	.data_out(data_o),
	.lowest_nr(),
	.lowest_line(select_lcl),
	.lowest_valid(valid)
	);
endmodule // priority_arbiter
