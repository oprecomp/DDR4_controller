
	// AXI Command
	//*******************************
	typedef struct {
		logic [AXI4_ID_WIDTH-1:0]		id;    
		logic [AXI4_ADDRESS_WIDTH-1:0]		address;  
		logic [ AXI4_USER_WIDTH-1:0]		user;
		integer					length;
		time					issue_time;
		`ifdef GEM5_CLOSEDLOOP_MODELSIM
		logic					RWB; // R=1, W=0
		longint unsigned				original_address;
		`endif
	} COMMAND;
	
	// AXI Data
	//*******************************
	typedef struct {
		logic [AXI4_ID_WIDTH-1:0]		id;    
		logic [`AXI_BURST_LENGTH-1:0][AXI4_RDATA_WIDTH-1:0] rdata;
		logic [`AXI_BURST_LENGTH-1:0][AXI_NUMBYTES-1:0]		be;   
		integer					length;
	} DATA;
	
	// Pending transactions which have not been injected yet
	//  This way we can decouple generation of transactions from their
	//  injection, and MAT will become more natural
	COMMAND		pending_AWLIST[$];
 	DATA		pending_WLIST[$];
	COMMAND		pending_ARLIST[$];

	// Keep track of the transaction which are already injected
	COMMAND		AWLIST[$];
	COMMAND		ARLIST[$];
 	DATA		RLIST[$];

 	// New command
	//*******************************
	function COMMAND new_command;
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		input logic [AXI4_ADDRESS_WIDTH-1:0]	address;  
		input integer				length;
		COMMAND cmd;
	begin
		cmd.id = id;
		cmd.address = address;
		cmd.length = length;
		cmd.issue_time = $time;
		return cmd;
	end
	endfunction
	
 	// New data
	//*******************************
	function DATA new_data;
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		input logic [AXI4_WDATA_WIDTH-1:0]	rdata;
		input integer				length;
		input  [`AXI_BURST_LENGTH-1:0][AXI_NUMBYTES-1:0] be;   
		DATA dta;
	begin
		dta.id = id;
		dta.rdata = rdata;
		dta.length = length;
		dta.be = be;
		return dta;
	end
	endfunction
	
	// Print command
	//*******************************
	task print_command;
		input COMMAND				CMD;
		input string				NAME;
		begin
			$write(, "... COMMAND:%s|ID:%d|A:%h|L:%d|@%d(ns)\n", NAME, CMD.id, CMD.address, CMD.length, $time);
		end
	endtask
	
	// Print data
	//*******************************
	task print_data;
		input DATA				DTA;
		input string				NAME;
		begin
			$write(, "... DATA:%s|ID:%d|D:%h|L:%d|@%d(ns)\n", NAME, DTA.id, DTA.rdata, DTA.length, $time);
		end
	endtask
	
	// Print command list
	//*******************************
	task print_command_list;
		input COMMAND				LIST[$];
		input string				NAME;
		begin
			$write("........................................\n");
			$write("COMMAND_LIST:%s @%d(ns)\n", NAME, $time);
			for (i=0; i < LIST.size();i++)
			begin
				$write("  %d)ID:%d|A:%h|L:%d\n", i, LIST[i].id, LIST[i].address, LIST[i].length);
			end
			$write("........................................\n");
		end
	endtask

	// Print data list
	//*******************************
	task print_data_list;
		input DATA				LIST[$];
		input string				NAME;
		begin
			$write("........................................\n");
			$write("DATA_LIST:%s @%d(ns)\n", NAME, $time);
			for (i=0; i < LIST.size();i++)
			begin
				$write("  %d)ID:%d|D:%h|L:%h\n", i, LIST[i].id, LIST[i].rdata, LIST[i].length);
			end
			$write("........................................\n");
		end
	endtask
	
 	// Search command list (Associative)
	//*******************************
	function COMMAND search_command_list;
		input COMMAND				LIST[$];
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		output integer				search_index;
		COMMAND obj;
		logic found;
	begin
		found = '0;
		for (i=0; i < LIST.size();i++)
			if ( LIST[i].id == id )
			begin
				if ( !found )
				begin
					obj = LIST[i];
					found = '1;
					search_index = i;
				end
				else
					$error("Two command with the same ID were found in the list! (ID=%h(h))", id);
			end
		if ( !found )
			$error("Command not found in the list! (ID=%h(h))", id );
			
		return obj;
	end
	endfunction
	
 	// Search data list (Associative)
	//*******************************
	function DATA search_data_list;
		input DATA				LIST[$];
		input logic [AXI4_ID_WIDTH-1:0]		id;
		output integer				search_index;
		DATA obj;
		logic found;
	begin
		found = '0;
		for (i=0; i < LIST.size();i++)
			if ( LIST[i].id == id )
			begin
				if ( !found )
				begin
					obj = LIST[i];
					found = '1;
					search_index = i;
				end
				else
					$error("Two data with the same ID were found in the list! (ID=%d)", id);
			end
		if ( !found )
			$error("Data not found in the list! (ID=%d)", id);
			
		return obj;
	end
	endfunction
	
 	// Pop AWLIST
	//*******************************
	function COMMAND pop_AWLIST;
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		COMMAND obj;
		integer search_index;
	begin
		obj = search_command_list(AWLIST, id, search_index); // Just to check for errors
		AWLIST.delete(search_index);
		return obj;
	end
	endfunction
	
 	// Pop ARLIST
	//*******************************
	function COMMAND pop_ARLIST;
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		COMMAND obj;
		integer search_index;
	begin
		obj = search_command_list(ARLIST, id, search_index); // Just to check for errors
		ARLIST.delete(search_index);
		return obj;
	end
	endfunction
	
 	// Pop RLIST
	//*******************************
	function DATA pop_RLIST;
		input logic [AXI4_ID_WIDTH-1:0]		id;    
		DATA obj;
		integer search_index;
	begin
		obj = search_data_list(RLIST, id, search_index); // Just to check for errors
		RLIST.delete(search_index);
		return obj;
	end
	endfunction
