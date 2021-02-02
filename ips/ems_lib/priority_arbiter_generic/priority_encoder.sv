module priority_encoder_16
  #(
    )
   (
    input [16-1:0] req,

    output logic [4-1:0] out,
    output logic   valid
    );


   logic [16-1:0][16-1:0]   req_split;
   logic [16-1:0] 	    req_lcl;
   
   
   generate
      for (genvar i=0; i<16; i++)
	assign req_split[i] = (req[i])?(16'b1111_1111_1111_1111 << (i+1)):
			      (16'b1111_1111_1111_1111);
   endgenerate

   assign req_lcl = req_split[0] & req_split[1] & req_split[2] & req_split[3] 
		    & req_split[4] & req_split[5] & req_split[6] &
		    req_split[7] & req_split[8] & req_split[9] &
		    req_split[10] & req_split[11] & req_split[12] & 
		    req_split[13] & req_split[14] & req_split[15];
   

   always_comb begin
      out = '0;
      valid = '0;

      case(req_lcl)
	16'b1111_1111_1111_1111: begin
	   out = '0;
	   valid = '0;
	end
	16'b1111_1111_1111_1110: begin
	   out = 4'b0;
	   valid = 1'b1;
	end
	16'b1111_1111_1111_1100: begin
	   out = 4'd1;
	   valid = 1'b1;
	end
	16'b1111_1111_1111_1000: begin
	   out = 4'd2;
	   valid =  1'b1;
	end
	16'b1111_1111_1111_0000: begin
	   out = 4'd3;
	   valid =  1'b1;
	end
	16'b1111_1111_1110_0000: begin
	   out = 4'd4;
	   valid =  1'b1;
	end
	16'b1111_1111_1100_0000: begin
	   out = 4'd5;
	   valid = 1'b1;
	end
	16'b1111_1111_1000_0000: begin
	   out = 4'd6;
	   valid = 1'b1;
	end
	16'b1111_1111_0000_0000: begin
	   out = 4'd7;
	   valid = 1'b1;
	end
	16'b1111_1110_0000_0000: begin
	   out = 4'd8;
	   valid = 1'b1;
	end
	16'b1111_1100_0000_0000: begin
	   out = 4'd9;
	   valid = 1'b1;
	end
	16'b1111_1000_0000_0000: begin
	   out = 4'd10;
	   valid = 1'b1;
	end
	16'b1111_0000_0000_0000: begin
	   out = 4'd11;
	   valid = 1'b1;
	end
	16'b1110_0000_0000_0000: begin
	   out = 4'd12;
	   valid = 1'b1;
	end
	16'b1100_0000_0000_0000: begin
	   out = 4'd13;
	   valid = 1'b1;
	end
	16'b1000_0000_0000_0000: begin
	   out = 4'd14;
	   valid = 1'b1;
	end
	16'b0000_0000_0000_0000: begin
	   out = 4'd15;
	   valid = 1'b1;
	end
      endcase
   end // always_comb

endmodule // priority_encoder_16
