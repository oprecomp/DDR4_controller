interface reg_bus_if
  #(
    //parameter type atype = logic,
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
    )
   (
    input logic clk
    );
   logic [ADDR_WIDTH-1:0] addr;
   logic 	write;//0 = read , 1= write
   logic 	error; // 0=ok, 1= transaction error
   logic 	valid;
   logic 	ready;
   logic [DATA_WIDTH-1:0] wdata;
   logic [DATA_WIDTH/8-1:0] wstrb; // byte-wise strobe
   logic [DATA_WIDTH-1:0]   rdata;

   modport slave  (input  clk, addr, write, wdata, wstrb, valid,
		    output error, ready, rdata);
   modport master (output addr, wdata, write, wstrb, valid,
		   input clk, error, ready, rdata);
endinterface // REG_BUS
