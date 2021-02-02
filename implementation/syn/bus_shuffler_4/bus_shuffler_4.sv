module bus_shuffler_4
  #(
    parameter BUS_SIZE = 16//Bus size of each slot in bits
    )
   (
    input [3:0][BUS_SIZE-1:0]  bus_i,
    input [3:0] 	       req_slot,
    input [3:0][1:0] 	       req_slot_nr,

    output [3:0][BUS_SIZE-1:0] bus_o,
    output [3:0] 	       bus_valid_o
    );

   // This module has four input bus of width BUS_SIZE each. Data on each bus is
   // channelized to the respective slot requested by req_slot signal.
   // This operation is performed by a 1:4 demux. There are as many demux as
   // bus, the output of all demux is later OR'ed to combine it into one single
   // bus with four slots.
   // This mudule assumes that there are no two input request from different bus
   // to a same slot.

   logic [3:0][BUS_SIZE-1:0]   demux_out [3:0];
   logic [3:0] 		       demux_valid [3:0];

   assign bus_o = demux_out[0] | demux_out[1] | demux_out[2] | demux_out[3];
   assign bus_valid_o = demux_valid[0] | demux_valid[1] | demux_valid[2] |
			demux_valid[3];
   //always_comb $display("v %b", demux_valid[1]);

   generate
      for(genvar i=0; i<=3; i++)
	begin
	   demux_1_4
		   #(
		     .WIDTH (BUS_SIZE)
		     )demux_inst_data
		   (
		    .in (bus_i[i] & {BUS_SIZE{req_slot[i]}}),
		    .sel (req_slot_nr[i]),
		    .out (demux_out[i])
		    );
	   demux_1_4
	     #(
	       .WIDTH (1)
	       )demux_inst_valid
	       (
		.in (req_slot[i]),
		.sel (req_slot_nr[i]),
		.out (demux_valid[i])
		);
	end // for (genvar i=0;i<=3;i++)
   endgenerate
endmodule // bus_shuffler_four

