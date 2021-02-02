module lowest_nr_identifier_8
	#(
		parameter NR_WIDTH = 8
		)
	 (
		input [7:0][NR_WIDTH-1:0] nr,
		input [7:0] 							req,

		output [NR_WIDTH-1:0] 		lowest_nr,
		output logic [2:0] 				lowest_line,
		output logic 							lowest_valid
		);

	 // This module will select and output the lowest number among the eight
	 // input numbers. It also will indicate on which input line the lowest number
	 // was signaled.
	 // This for same nr req, lowest line is the id of highest

	 //To find lowest number among all reqs, we need 7 compare unit in 3 stages
	 logic [3:0][NR_WIDTH-1:0] 				 comp1_lowest;
	 logic [1:0][NR_WIDTH-1:0] 					 comp2_lowest;
	 logic [3:0][0:0] 										 comp1_res_v, comp1_low_line;
	 logic [1:0] 											 comp2_res_v, comp2_low_line;
	 logic 															 comp3_low_line;

	 generate
			for(genvar i=0; i<=3; i++) begin
					 assign comp1_low_line[i]=({!req[i*2],nr[i*2]}<{!req[i*2+1],nr[(i*2)+1]});
					 assign comp1_lowest[i]=(comp1_low_line[i])?nr[i*2]:nr[i*2+1];
					 assign comp1_res_v[i] = req[i*2] | req[i*2+1];
			end

			for(genvar j=0; j<=1; j++)
				begin
					 assign comp2_low_line[j]=({!comp1_res_v[j*2],comp1_lowest[j*2]}<
																		 {!comp1_res_v[j*2+1],comp1_lowest[j*2+1]});
					 assign comp2_lowest[j]=(comp2_low_line[j])?comp1_lowest[j*2]:
																	comp1_lowest[j*2+1];
					 assign comp2_res_v[j] = comp1_res_v[j*2] | comp1_res_v[j*2+1];
				end
			endgenerate

	 assign comp3_low_line = ({!comp2_res_v[0],comp2_lowest[0]}<
														{!comp2_res_v[1],comp2_lowest[1]});
	 assign lowest_nr = (comp3_low_line)? comp2_lowest[0]: comp2_lowest[1];
	 assign lowest_valid = comp2_res_v[0] | comp2_res_v[1];

	 always_comb
		 begin
				lowest_line[2] = !comp3_low_line;
				lowest_line[1] = comp3_low_line? !comp2_low_line[0]:!comp2_low_line[1];
				case({lowest_line[2],lowest_line[1]})
						2'b00: lowest_line[0] = !comp1_low_line[0];
						2'b01: lowest_line[0] = !comp1_low_line[1];
						2'b10: lowest_line[0] = !comp1_low_line[2];
						2'b11: lowest_line[0] = !comp1_low_line[3];
					endcase // case ({comp3_low_line,comp2_low_line})
		 end // always_comb
endmodule // lowest_nr_identifier_8
