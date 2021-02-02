module comp_sel_grt
	#(
		parameter DATA_WIDTH = 16
		)
	 (
		input [DATA_WIDTH-1:0] in_a,
		input [DATA_WIDTH-1:0] in_b,
		output [DATA_WIDTH -1:0] out
		);

		// This module ouputs the greater value signal among 2 input signals.

		assign out=(in_a > in_b)?in_a:in_b;
endmodule // comp_sel_grt
