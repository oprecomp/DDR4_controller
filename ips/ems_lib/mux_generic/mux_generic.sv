module mux_1
  #(
    parameter WIDTH = 16,
    parameter NR_INPUTS = 8
    )
   (
    input [NR_INPUTS-1:0][WIDTH-1:0] in,
    input [$clog2(NR_INPUTS)-1:0]    sel,
    output logic [WIDTH-1:0] 	     out
    );

   integer 			     i;
 
   always_comb 
     begin
	out = '0;
	for(i = 0; i < NR_INPUTS; i++) 
	  begin
	     if(sel == i)
	       out = in[i];
	  end
     end
endmodule
  
