module mem_tgen_checker
  #(
    parameter DRAM_BUS_WIDTH = 8,
    parameter FE_CMD_WIDTH = 1,
    parameter FE_WRITE = 0,
    parameter FE_ADDR_WIDTH = 32,
    parameter FE_ID_WIDTH = 16,
    parameter NUM_TRANSACTIONS = 10000000,
    parameter BL = 8
    )
   (

    input 				 ui_clk,
    input 				 ui_rst_n,
        
    input logic 			 fe_stall,
    
    output logic 			 fe_req,
    output logic [FE_CMD_WIDTH-1:0] 	 fe_cmd,
    output logic [FE_ADDR_WIDTH-6-1:0] 	 fe_addr,
    output logic [FE_ID_WIDTH-1:0] 	 fe_id,
    output logic [DRAM_BUS_WIDTH*BL-1:0] fe_data,

    input logic [DRAM_BUS_WIDTH*BL-1:0]  fe_read_data,
    input logic [FE_ID_WIDTH-1:0] 	 fe_read_id,
    input logic 			 fe_read_valid,

    output logic 			 data_cmp_err
    );

   
   logic 				fe_req_wr;
   logic 				fe_wr_stall;
   logic [FE_CMD_WIDTH-1:0] 		fe_cmd_wr; 
   logic [FE_ADDR_WIDTH-6-1:0] 		fe_addr_wr;// -6 = -3-1-2. -3 for lower three bits to be set to zero, -1 because c10 doesnt exsists in DDR4 so it has to be set to zero, -2 because the DDR4 model is for 4gb i.e. one Row0 to Row14, Row15,16 has to be set to zero. 
   logic 				fe_req_rd;
   logic [FE_CMD_WIDTH-1:0] 		fe_cmd_rd;
   logic 				fe_cmd_sel;
   logic [FE_ADDR_WIDTH-6-1:0] 		fe_addr_rd;
   logic 				fe_stall_q;
   logic 				fe_req_regen;
   logic [FE_CMD_WIDTH-1:0] 		fe_cmd_regen;
   logic [FE_ADDR_WIDTH-6-1:0] 		fe_addr_regen;
   logic [FE_ID_WIDTH-1:0] 		fe_id_regen;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_data_regen;
   logic [DRAM_BUS_WIDTH*BL-1:0] 	fe_read_data_q;
   logic [FE_ID_WIDTH-1:0] 		fe_read_id_q;
   logic 				fe_read_valid_q;
   logic [63:0] 			fe_write_cnt;
   logic [$clog2(NUM_TRANSACTIONS)-1:0] write_cnt;
   logic 				stop_lfsr;
   
   
 
   lfsr_gen
     #(
       .lfsr_width(FE_ADDR_WIDTH-6+1+1) // -3 for lower three bit set to zero, -1 because c10 doesnt exsists in DDR4 so it has to be set to zero, -2 because the DDR4 model is for 4gb i.e. one Row0 to Row14, Row15,16 has to be set to zero
       )lfsr_generate_addr_wr
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n || stop_lfsr), // works as a reset 
	.seed(66'h2734c673a47f2345a), // will be reseted to this seed 
	.readyMig((~fe_stall) && !(fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))), // check if Mig is ready for write
	.regen(1'b0), // check if gen or regen
	.rd_valid(1'b0), // check if valid data to read

	.gen_pattern({fe_addr_wr,fe_cmd_wr,fe_req_wr})
    );

   lfsr_gen
     #(
       .lfsr_width(FE_ADDR_WIDTH-6+1+1)
       )lfsr_generate_addr_rd
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n || stop_lfsr), // works as a reset 
	.seed(66'h2734c673a47f2345a), // will be reseted to this seed 
	.readyMig((~fe_stall) && (fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))), // check if Mig is ready for write
	.regen(1'b0), // check if gen or regen
	.rd_valid(1'b0), // check if valid data to read

	.gen_pattern({fe_addr_rd,fe_cmd_rd,fe_req_rd})
    );
   
   lfsr_gen
     #(
       .lfsr_width(DRAM_BUS_WIDTH*BL)
       )lfsr_generate_data
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n || stop_lfsr), // works as a reset 
	.seed(512'h7cb7467189af4346_fcabbfa445676870_4125234647787889_afc444334bb34245_85768a424fc4256_453667ab678f6909_018783ab3645ac39_343cffb342c5645f), // will be reseted to this seed 
	//.readyMig((~fe_stall_q) && (fe_req_wr) && !fe_cmd),
	.readyMig((~fe_stall)&& (fe_req_wr) && !(fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))),
	.regen(1'b0), // check if gen or regen
	.rd_valid(1'b0), // check if valid data to read

	.gen_pattern(fe_data)
    );

   lfsr_gen
     #(
       .lfsr_width(16)
       )lfsr_generate_cmd_sel
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n || stop_lfsr), // works as a reset 
	.seed(16'h8dc3), // will be reseted to this seed 
	.readyMig(1'b1), // check if Mig is ready for write
	.regen(1'b0), // check if gen or regen
	.rd_valid(1'b0), // check if valid data to read

	.gen_pattern(fe_cmd_sel)
    );


   assign fe_addr = (fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))?fe_addr_rd:fe_addr_wr;
   assign fe_cmd = (fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))?1'b1:1'b0;
   assign fe_req = ((fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0)))?fe_req_rd:fe_req_wr) && !fe_stall;

   //sync FF
   //assumption fe_cmd_rd is initially zero, this happens if the seed is zero
   always_ff@(posedge ui_clk, negedge ui_rst_n)
     begin
	if(ui_rst_n == 1'b0)
	  begin
	     //fe_addr <= '0;
	     //fe_cmd <= '0;
	     //fe_req <= '0;
	     fe_stall_q <= '1;
	     fe_write_cnt <= '0;
	     fe_wr_stall <= '0;
	     write_cnt <= NUM_TRANSACTIONS-1;
	     stop_lfsr <= 1'b0;
	  end
	else
	  begin
	     fe_stall_q <= fe_stall;
	     if((fe_cmd == FE_WRITE) && fe_req)
	       write_cnt <= write_cnt - 1;
	     
	     if(write_cnt == '0)
	       stop_lfsr <= 1'b1;
	     
	     if(!fe_stall) begin
		if((fe_wr_stall||(fe_cmd_sel && (fe_write_cnt>0))))
		  fe_write_cnt <= fe_write_cnt - 1;
		else
		  fe_write_cnt <= fe_write_cnt + 1;

		if(fe_write_cnt>15)
		  fe_wr_stall <= 1;
		else
		  if(fe_wr_stall && (fe_write_cnt<8))
		    fe_wr_stall <= 0;
	     end
	  end // else: !if(ui_rst_n == 1'b0)
     end // always_ff@ (posedge ui_clk, negedge ui_rst_n)
   
   
   lfsr_gen
     #(
       .lfsr_width(DRAM_BUS_WIDTH*BL)
       )lfsr_regenerate_data
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n), // works as a reset 
	.seed(512'h7cb7467189af4346_fcabbfa445676870_4125234647787889_afc444334bb34245_85768a424fc4256_453667ab678f6909_018783ab3645ac39_343cffb342c5645f), // will be reseted to this seed 
	.readyMig('0), // check if Mig is ready for write
	.regen(1'b1), // check if gen or regen
	.rd_valid(fe_read_valid), // check if valid data to read

	.gen_pattern(fe_data_regen)
    );


   /*lfsr_gen
     #(
       .lfsr_width(FE_ADDR_WIDTH-6+1+1)
       )lfsr_regenerate_addr
       (
	.clk(ui_clk),
	.new_seed(~ui_rst_n), // works as a reset 
	.seed(66'h2734c673a47f2345a), // will be reseted to this seed 
	.readyMig(), // check if Mig is ready for write
	.regen(1'b1), // check if gen or regen
	.rd_valid((fe_req_regen)?fe_read_valid:1'b1), // if previous cmd was write then skip, if read then wait for read valid

	.gen_pattern({fe_addr_regen,fe_cmd_regen,fe_req_regen})
    );*/

   always_ff@(posedge ui_clk, negedge ui_rst_n)
     begin
	if(ui_rst_n == 1'b0)
	  begin
	     fe_read_valid_q <= '0;
	     fe_read_data_q <= '0;
	     fe_read_id_q <= '0;
	  end
	else
	  begin
	     fe_read_valid_q <= fe_read_valid;
	     fe_read_data_q <= fe_read_data;
	     fe_read_id_q <= fe_read_id;
	  end
     end // always_ff@ (posedge ui_clk, negedge ui_rst_n)
   
   always_ff@(posedge ui_clk, negedge ui_rst_n)
     begin
	if(ui_rst_n == 1'b0)
	  begin
	     data_cmp_err <= 1'b0;
	  end
	else
	  begin
	     if(fe_read_valid)
	       begin
		  if(fe_read_data != fe_data_regen)
		    begin
		       data_cmp_err <= 1'b1;
`ifndef SYNTHESIS
		       $display("ERROR");
		       $display("Written Data = %h",fe_data_regen);
		       $display("Read Data    = %h",fe_read_data);
		       //$display("Addr         = %h",fe_addr_regen);
		       //$display("Read CMD ID = %h, Read Data ID = %h",fe_id_regen,fe_read_id_q);
		       $stop;
`endif
		    end
		  else
		    begin
`ifndef SYNTHESIS
		       $display("GOOD");
		       $display("Written Data = %h",fe_data_regen);
		       $display("Read Data    = %h",fe_read_data);
		       //$display("Addr         = %h",fe_addr_regen);
		       // $display("Read CMD ID = %h, Read Data ID = %h",fe_id_regen,fe_read_id_q);
`endif
		       data_cmp_err <= data_cmp_err;
		    end
	       end
	  end // else: !if(ui_rst_n == 1'b0)
     end // always_ff@ (posedge ui_clk, negedge ui_rst_n)
   
   
    always_ff @(posedge ui_clk, negedge ui_rst_n)
     begin
	if(ui_rst_n == 1'b0)
	  begin
	     fe_id <= '0;
	     fe_id_regen <= '0;
	  end
	else
	  begin
	     if((~fe_stall_q)&&((fe_cmd_sel && (fe_write_cnt>0))?fe_req_rd:fe_req_wr))
	       fe_id <= fe_id + 1;
	     if(((fe_cmd_regen==FE_WRITE) && fe_req_regen)?1'b1:fe_read_valid)
	       fe_id_regen <= fe_id_regen + 1;
	  end
     end // always_ff @ (posedge ui_clk, negedge ui_rst_n)
   
endmodule 
