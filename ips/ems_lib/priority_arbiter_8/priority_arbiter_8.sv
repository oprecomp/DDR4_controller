module priority_arbiter_8
  #(
	parameter PRIORITY_WIDTH = 8,
	parameter DATA_WIDTH = 2
	)
   (
	input [7:0][PRIORITY_WIDTH-1:0] priority_i,
	input [7:0][DATA_WIDTH-1:0] 	data_i,
	input [7:0] 			req,
	input [PRIORITY_WIDTH-1:0] 	highest_priority,
	output [DATA_WIDTH-1:0] 	data_o,
	output 			valid,
	output [2:0] 			grant
	);

   // This module accepts 8 input reqs, each req is associated with priority.
   // The data request with highest priority is passed to output.
   //  Priority order: highest priority i/p value to highest priority-1(lowest).
   // It is in wrap around fashion.

   logic [2:0] 			select_lcl;
   logic [7:0][PRIORITY_WIDTH-1:0] 	priority_lcl;


//	  for(genvar i = 0; i<=7; i++)
//		assign priority_lcl[i] = priority_i[i] - highest_priority;
//   endgenerate

  assign priority_lcl[0] = priority_i[0] - highest_priority;
  assign priority_lcl[1] = priority_i[1] - highest_priority;
  assign priority_lcl[2] = priority_i[2] - highest_priority;
  assign priority_lcl[3] = priority_i[3] - highest_priority;
  assign priority_lcl[4] = priority_i[4] - highest_priority;
  assign priority_lcl[5] = priority_i[5] - highest_priority;
  assign priority_lcl[6] = priority_i[6] - highest_priority;
  assign priority_lcl[7] = priority_i[7] - highest_priority;

   lowest_nr_identifier_8
	 #(
	   .NR_WIDTH(PRIORITY_WIDTH)
	   )highest_priority_selector
	   (
		.nr(priority_lcl),
		.req(req),
		.lowest_nr(),
		.lowest_line(select_lcl),
		.lowest_valid(valid)
		);
   assign grant = select_lcl;

   mux_8_1
	 #(
	   .WIDTH (DATA_WIDTH)
	   )mux
	   (
		.in(data_i),
		.sel(select_lcl),
		.out(data_o)
		);
endmodule // priority_arbiter_8
