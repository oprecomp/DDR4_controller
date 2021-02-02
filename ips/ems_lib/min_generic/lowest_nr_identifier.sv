module lowest_nr_identifier
  #(
    parameter NR_WIDTH = 8,
    parameter NR_INPUTS = 8
    )
   (
    input [NR_INPUTS-1:0][NR_WIDTH-1:0]  nr,
    input [NR_INPUTS-1:0] 		 req,

    output [NR_WIDTH-1:0] 		 lowest_nr,
    output logic [$clog2(NR_INPUTS)-1:0] lowest_line,
    output logic 			 lowest_valid
    );
   
   // This module will select and output the lowest number among the eight
   // input numbers. It also will indicate on which input line the lowest number
   // was signaled.
   // This for same nr req, lowest line is the id of highest
   
   //To find lowest number among all reqs, we need 7 compare unit in 3 stages for 8 input device
   logic [$clog2(NR_INPUTS):0][NR_INPUTS-1:0][NR_WIDTH-1:0] comp_lowest;
   logic [$clog2(NR_INPUTS):0][NR_INPUTS-1:0] 		    comp_res_v;
   logic [$clog2(NR_INPUTS):1][(NR_INPUTS/2)-1:0] 	    comp_low_line;
   logic [$clog2(NR_INPUTS):0][NR_INPUTS-1:0][$clog2(NR_INPUTS)-1:0] lowest_line_tmp;
   logic [$clog2(NR_INPUTS)-1:0][(NR_INPUTS/2)-1:0] 		     sign;
   logic [$clog2(NR_INPUTS)-1:0][(NR_INPUTS/2)-1:0][NR_WIDTH+1:0]    sub;
   
   assign comp_lowest[0] = nr;
   assign comp_res_v[0] = req;
   
   generate
      for(genvar j=0; j<NR_INPUTS; j++) begin
	 assign lowest_line_tmp[0][j] = j;
      end
      
      for(genvar j=0; j<$clog2(NR_INPUTS); j++) begin
	 for(genvar i=0; i<(NR_INPUTS/(2**(j+1))); i++) begin
	    assign {sign[j][i],sub[j][i]} = ({1'b0,!comp_res_v[j][i*2],comp_lowest[j][i*2]}-{1'b0,!comp_res_v[j][i*2+1],comp_lowest[j][(i*2)+1]});
	    assign comp_low_line[j+1][i]=sign[j][i];
	    //assign comp_low_line[j+1][i]=({1'b0,!comp_res_v[j][i*2],comp_lowest[j][i*2]}<{1'b0,!comp_res_v[j][i*2+1],comp_lowest[j][(i*2)+1]});
	    assign comp_lowest[j+1][i]=(comp_low_line[j+1][i])?comp_lowest[j][i*2]:comp_lowest[j][i*2+1];
	    assign lowest_line_tmp[j+1][i]= (comp_low_line[j+1][i])?lowest_line_tmp[j][i*2]:lowest_line_tmp[j][i*2+1];
	    assign comp_res_v[j+1][i] = comp_res_v[j][i*2] | comp_res_v[j][i*2+1];
	 end
      end
   endgenerate
      
   assign lowest_nr = comp_lowest[$clog2(NR_INPUTS)][0];
   assign lowest_valid = comp_res_v[$clog2(NR_INPUTS)][0];
   //assign lowest_line_tmp[$clog2(NR_INPUTS)] = 0;
   assign lowest_line = lowest_line_tmp[$clog2(NR_INPUTS)][0];

   /*always_comb
     begin
	//lowest_line_tmp = 0;
       	for(int k = $clog2(NR_INPUTS); k > 0; k--) begin
	   for(integer i = 0; i < NR_INPUTS/(2**(k)); i++) begin
	      if((lowest_line_tmp >> (k-1)) == i)
		lowest_line_tmp[k-1] = !comp_low_line[k][i];
	   end
	end
     end*/
endmodule
