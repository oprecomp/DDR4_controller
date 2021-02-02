// Authors: Matthias Jung (2017) and Chirag Sudarshan

module mux (input [31:0] in, input [4:0] addr, output logic out);

always @(in)
   case (addr)
       5'd0  : out = in[ 0];
       5'd1  : out = in[ 1];
       5'd2  : out = in[ 2];
       5'd3  : out = in[ 3];
       5'd4  : out = in[ 4];
       5'd5  : out = in[ 5];
       5'd6  : out = in[ 6];
       5'd7  : out = in[ 7];
       5'd8  : out = in[ 8];
       5'd9  : out = in[ 9];
       5'd10 : out = in[10];
       5'd11 : out = in[11];
       5'd12 : out = in[12];
       5'd13 : out = in[13];
       5'd14 : out = in[14];
       5'd15 : out = in[15];
       5'd16 : out = in[16];
       5'd17 : out = in[17];
       5'd18 : out = in[18];
       5'd19 : out = in[19];
       5'd20 : out = in[20];
       5'd21 : out = in[21];
       5'd22 : out = in[22];
       5'd23 : out = in[23];
       5'd24 : out = in[24];
       5'd25 : out = in[25];
       5'd26 : out = in[26];
       5'd27 : out = in[27];
       5'd28 : out = in[28];
       5'd29 : out = in[29];
       5'd30 : out = in[30];
       5'd31 : out = in[31];
    endcase
endmodule

/*module congen 
  (
   input [32-1:0]      in,
   input [5*ADDR_WIDTH-1:0]    conf,
   output reg [32-1:0] out
    );

   assign out[0] = in[0]; // C0
   assign out[1] = in[1]; // C1
   assign out[2] = in[2]; // C2

   genvar 			i;
   
   generate
      for (i=3;i<32;i++)
	begin
	   mux mux  (in, conf[(i-3)*5 +: 5], out[i]);
	end
   endgenerate
*/   
module congen (input [31:0] in, input [144:0] conf, output reg [31:0] out);

   assign out[0] = in[0]; // C0
   assign out[1] = in[1]; // C1
   assign out[2] = in[2];  // C2
   mux mux0  ({3'd0,in[31:3]}, conf[    4:0], out[ 3]);
   mux mux1  ({3'd0,in[31:3]}, conf[    9:5], out[ 4]);
   mux mux2  ({3'd0,in[31:3]}, conf[  14:10], out[ 5]);
   mux mux3  ({3'd0,in[31:3]}, conf[  19:15], out[ 6]);
   mux mux4  ({3'd0,in[31:3]}, conf[  24:20], out[ 7]);
   mux mux5  ({3'd0,in[31:3]}, conf[  29:25], out[ 8]);
   mux mux6  ({3'd0,in[31:3]}, conf[  34:30], out[ 9]);
   mux mux7  ({3'd0,in[31:3]}, conf[  39:35], out[10]);
   mux mux8  ({3'd0,in[31:3]}, conf[  44:40], out[11]);
   mux mux9  ({3'd0,in[31:3]}, conf[  49:45], out[12]);
   mux mux10 ({3'd0,in[31:3]}, conf[  54:50], out[13]);
   mux mux11 ({3'd0,in[31:3]}, conf[  59:55], out[14]);
   mux mux12 ({3'd0,in[31:3]}, conf[  64:60], out[15]);
   mux mux13 ({3'd0,in[31:3]}, conf[  69:65], out[16]);
   mux mux14 ({3'd0,in[31:3]}, conf[  74:70], out[17]);
   mux mux15 ({3'd0,in[31:3]}, conf[  79:75], out[18]);
   mux mux16 ({3'd0,in[31:3]}, conf[  84:80], out[19]);
   mux mux17 ({3'd0,in[31:3]}, conf[  89:85], out[20]);
   mux mux18 ({3'd0,in[31:3]}, conf[  94:90], out[21]);
   mux mux19 ({3'd0,in[31:3]}, conf[  99:95], out[22]);
   mux mux20 ({3'd0,in[31:3]}, conf[104:100], out[23]);
   mux mux21 ({3'd0,in[31:3]}, conf[109:105], out[24]);
   mux mux22 ({3'd0,in[31:3]}, conf[114:110], out[25]);
   mux mux23 ({3'd0,in[31:3]}, conf[119:115], out[26]);
   mux mux24 ({3'd0,in[31:3]}, conf[124:120], out[27]);
   mux mux25 ({3'd0,in[31:3]}, conf[129:125], out[28]);
   mux mux26 ({3'd0,in[31:3]}, conf[134:130], out[29]);
   mux mux27 ({3'd0,in[31:3]}, conf[139:135], out[30]);
   mux mux28 ({3'd0,in[31:3]}, conf[144:140], out[31]);

endmodule
