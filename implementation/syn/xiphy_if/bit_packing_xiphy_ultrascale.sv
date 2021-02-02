// This module packs the bits as specified in Xilinx PG150 (October 30, 2019) page 167.
// Xilinx ultrascale phy requires the bits to be packed in a certain pattern.
// for more details refer the following link
// https://www.xilinx.com/support/documentation/ip_documentation/ultrascale_memory_ip/v1_4/pg150-ultrascale-memory-ip.pdf#page=167

module bit_packing_xiphy_ultrascale
  #(
    parameter DATA_WIDTH = 8,
    parameter CLK_RATIO = 4,
    parameter DUPLICATES = 2
    )
   (
    input [CLK_RATIO-1:0][DATA_WIDTH-1:0] data_i,
    output [DATA_WIDTH-1:0][CLK_RATIO-1:0][DUPLICATES-1:0] data_o
    );

   genvar 							   i,j;

   generate
      for(i=0; i<DATA_WIDTH; i=i+1) begin
	 for (j=0; j<CLK_RATIO; j=j+1) begin
	    assign data_o[i][j] = {DUPLICATES{data_i[j][i]}};
	 end
      end
   endgenerate
   
endmodule // bit_packing_xiphy_ultrascale
   
		
    
