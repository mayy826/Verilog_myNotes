`timescale 1ns / 1ps

module synch_fifo( clk, reset, rd_en, wr_en, write_data, read_data, full, empty, full_nxt, empty_nxt, room_avail, data_avail,memory_wire);

	parameter FIFO_width = 16,
		  FIFO_depth = 8 ,
		  FIFO_ptr   = 3 ;
	
	input		   				clk, reset         ;
	input	 	   				rd_en, wr_en	   ;
	input	[FIFO_width-1:0] 	write_data 			   ; 
	output	[FIFO_width-1:0] 	read_data 			   ;
	output		   				full, empty 	   ; 
	output		   				full_nxt, empty_nxt;
	output	[FIFO_ptr:0]  		room_avail, data_avail 	 	   ;
	output  [FIFO_width-1:0] 	memory_wire			   ;

			
	
	
	//write-pointer control logic	依序寫register
	reg	[FIFO_ptr-1:0]wr_reg_ptr;
	reg 	[FIFO_ptr-1:0]wr_reg_ptr_nxt;
		
	always@(*)
	begin	
		wr_reg_ptr_nxt = wr_reg_ptr ;
		
		if(wr_en == 1'b1)
			if(wr_reg_ptr == FIFO_depth-1)
				wr_reg_ptr_nxt <= 'd0;
			else
				wr_reg_ptr_nxt <= wr_reg_ptr + 1'b1;		
	end
	
	
	//read-pointer control logic 依序讀register	
	reg	[FIFO_ptr-1:0]rd_reg_ptr;
	reg 	[FIFO_ptr-1:0]rd_reg_ptr_nxt;
		
	always@(*)
	begin		
		rd_reg_ptr_nxt = rd_reg_ptr ;//把上一個clk前的ptr存進nxt
		if(rd_en == 1'b1)
		   if (rd_reg_ptr == FIFO_depth-1)
			rd_reg_ptr_nxt = 'd0;
		   else
			rd_reg_ptr_nxt = rd_reg_ptr + 1'b1;		
	end
	
	// calculate number of  entries in the FIFO
	reg		[FIFO_ptr:0] num_entries;
	reg		[FIFO_ptr:0] num_entries_nxt;
		
	always@(*)
	begin
		num_entries_nxt = num_entries;
		
		if( wr_en == 1'b1 && rd_en==1'b1 )
			num_entries_nxt = num_entries;
		else if (wr_en == 1'b1)
			num_entries_nxt = num_entries + 1'b1;
		else if (rd_en == 1'b1)
			num_entries_nxt = num_entries - 1'b1;	
				
	end

	
	reg 	full, empty;
	reg		[FIFO_ptr:0] room_avail;
	wire	full_nxt, empty_nxt;
	wire	[FIFO_ptr:0] data_avail,room_avail_nxt;
	
	assign  full_nxt  		= (num_entries_nxt >= FIFO_depth) ? 1'b1 : 1'b0;
	assign	empty_nxt 		= (num_entries_nxt <= 'd0       ) ? 1'b1 : 1'b0;
	assign	data_avail  	= num_entries; //clk poedge num_entries <= num_entries_nxt 
	assign  room_avail_nxt  = (FIFO_depth - num_entries_nxt); 
		
	always@(posedge clk or negedge reset)
	begin
		if(!reset)begin
		wr_reg_ptr  <= 'd0				;
		rd_reg_ptr  <= 'd0				;
		full  	    <= 1'b0				;
		empty 	    <= 1'b1				;
		num_entries <= 'd0				; 
		room_avail  <= FIFO_depth			;
		end
		else begin
		wr_reg_ptr  <= wr_reg_ptr_nxt	;
		rd_reg_ptr  <= rd_reg_ptr_nxt	;
		full  	    <= full_nxt		;
		empty 	    <= empty_nxt	;
		num_entries <= num_entries_nxt  ;
		room_avail  <= room_avail_nxt   ;
		end
	end

	// fifo writedata to memory or rddata from memory.	  
	reg 	[FIFO_width-1:0] memory[FIFO_depth-1:0];
	wire	[FIFO_width-1:0] memory_wire;
	
	assign  memory_wire = memory[0]; //memory[0] test pin
	
	always@(posedge clk or negedge reset)
	begin
		if(!reset) 
			memory[wr_reg_ptr] <= 'h0000;
		else if(wr_en == 1'b1)
			memory[wr_reg_ptr] <= write_data ;				
	end

	reg [FIFO_width-1:0] rddata;
	
	assign 	read_data = rddata;
	
	always@(posedge clk or negedge reset)
	begin
		if(!reset) 
			rddata <=  'h0000 ;
		else if (rd_en == 1'b1)
			rddata <= memory[rd_reg_ptr] ;		
	end

	
endmodule

