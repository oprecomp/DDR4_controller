module demux_1_4
  #(
    parameter WIDTH = 16,
    parameter INVERTED_OUTPUT = 0
    )
   (
    input [WIDTH-1:0] 		  in,
    input [1:0] 		  sel,
    output logic [3:0][WIDTH-1:0] out
    );

   logic [WIDTH-1:0] 		  in_lcl;

   assign in_lcl = (INVERTED_OUTPUT==0)?in:~in;
   
   always_comb
     begin
	out = 0;
	if(INVERTED_OUTPUT!=0)
	  out = '1;
	case(sel)
	  0: begin
	     out[0] = in_lcl;
	  end
	  1: begin
	     out[1] = in_lcl;
	  end
	  2: begin
	     out[2] = in_lcl;
	  end
	  3: begin
	     out[3] = in_lcl;
	  end
	  default: begin
	     out[0] = in_lcl;
	  end
	endcase // case (sel)
     end // always_comb
endmodule // demux_1_4
