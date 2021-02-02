// Uses load pattern as reset to reset the pseudo random number generator
// Input pattern is used as seed
// need another reset to restart for the comparison
//Author: Deepak M. Mathew, EMS, TUKL


module lfsr_gen
  #(
    parameter lfsr_width = 64
    )
   (
    input logic 		  clk,
    input logic 		  new_seed, // works as a reset 
    input logic [lfsr_width-1:0]  seed, // will be reseted to this seed 
    input logic 		  readyMig, // check if Mig is ready for write
    input logic 		  regen, // check if gen or regen
    input logic 		  rd_valid, // check if valid data to read

    output logic [lfsr_width-1:0] gen_pattern
    );
   
   logic [lfsr_width-1:0] 	  pattern_aux;  // feedback reg
      
   always_ff@(posedge clk) 
     begin   
        integer i;
        if(new_seed)  begin        
           for (i = 0; i < lfsr_width; i = i + 1) begin
              if ((i !=lfsr_width-1)) begin
                 pattern_aux[i] <= seed[i+1];
              end         
           end
           pattern_aux[lfsr_width-1]  <= (seed[0]~^seed[1]~^seed[3]~^seed[4]); //maximum length lfsr tap for n=64
                         
        end               
        else begin
           if (!regen) begin  // If write check readyMig
              if (readyMig) begin 
                 for (i = 0; i < lfsr_width; i = i + 1) begin
                    if ((i != lfsr_width-1)) begin
                       pattern_aux[i] <= pattern_aux[i+1];
                    end         
                 end
                 pattern_aux[lfsr_width-1]  <= (pattern_aux[0]~^pattern_aux[1]~^pattern_aux[3]~^pattern_aux[4]);  
              end
              else begin
                 pattern_aux <= pattern_aux; 
              end
           end
           else begin     // If Read, check rd_valid
              if (rd_valid) begin
                 for (i = 0; i < lfsr_width; i = i + 1) begin
                    if ((i != lfsr_width-1)) begin
                       pattern_aux[i] <= pattern_aux[i+1];
                    end         
                 end
                 pattern_aux[lfsr_width-1]  <= (pattern_aux[0]~^pattern_aux[1]~^pattern_aux[3]~^pattern_aux[4]);
              end
              else begin
                 pattern_aux <= pattern_aux; 
              end
           end
        end
     end
    
   always_comb
     begin
        if(new_seed)  begin
           gen_pattern = seed; 
        end
        else begin
           gen_pattern = pattern_aux; 
        end
     end
   
endmodule 
 
 
 
 
       
       
 
