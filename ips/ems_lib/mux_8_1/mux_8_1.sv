module mux_8_1
	#(
		parameter WIDTH = 16
		)
	 (
		input [7:0][WIDTH-1:0] in,
		input [2:0] 					 sel,
		output logic [WIDTH-1:0] 		 out
		);
		always_comb
			begin
				 out = 0;
				 case(sel)
					 0: begin
							out = in[0];
					 end
					 1: begin
							out = in[1];
					 end
					 2: begin
							out = in[2];
					 end
					 3: begin
							out = in[3];
					 end
					 4: begin
							out = in[4];
					 end
					 5: begin
							out = in[5];
					 end
					 6: begin
							out = in[6];
					 end
					 7: begin
							out = in[7];
					 end
					 default: begin
							out = in[0];
						 end
				 endcase // case (sel)
			end // always_comb
endmodule // mux_8_1
