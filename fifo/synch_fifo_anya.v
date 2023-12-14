`timescale 1ns / 1ps

module synch_fifo( clk, reset, rd_en, wr_en, write_data, read_data, full, empty, room_avail, data_avail);
input		   clk, reset ;
input	 	   rd_en, wr_en;
input	[15:0] write_data ; 
output	[15:0] read_data ;
output		   full, empty ; 
output	[2:0]  room_avail, data_avail;

parameter FIFO_width = 16,
		  FIFO_depth = 8,
		  FIFO_ptr   = 3;
		  
		  
reg 	[15:0] memory[FIFO_depth-1:0];



//write-pointer control logic	依序寫register
reg	[2:0]wr_count_num;
reg [2:0]wr_count_num_nxt;
	  
always@(*)
begin	
	wr_count_num_nxt = wr_count_num;
	
	if(wr_en == 1'b1)
		if(wr_count_num_nxt == FIFO_depth-1)
			wr_count_num = 1'b0;
		else
			wr_count_num = wr_count_num+1'b1;		
end


//read-pointer control logic 依序讀register	
reg		[2:0]rd_count_num;
reg 	[2:0]rd_count_num_nxt;
	  
always@(*)
begin	
	rd_count_num_nxt = rd_count_num;
	
	if(rd_en == 1'b1)
		if(rd_count_num_nxt == FIFO_depth-1)
			rd_count_num = 1'b0;
		else
			rd_count_num = rd_count_num+1'b1;		
end

// calculate number of occupied entries in the FIFO
reg		[FIFO_ptr:0] num_entries;
reg		[FIFO_ptr:0] num_entries_nxt;

always@(*)
begin
	num_entries_nxt = num_entries;
	if( wr_en == 1'b1 && rd_en==1'b1 )
		num_entries = num_entries;
	else if (wr_en == 1'b1)
			num_entries = num_entries + 1'b1;
		else if (rd_en == 1'b1)
			num_entries = num_entries - 1'b1;	
			
end

reg 	full, empty;
wire	full_nxt, empty_nxt;
wire	[2:0] data_avail,room_avail_nxt;

assign  full_nxt  		= (num_entries_nxt == FIFO_depth) ? 1:0; 
assign	empty_nxt 		= (num_entries_nxt == 4'b0      ) ? 1:0;
assign	data_avail  	= num_entries_nxt;
assign  room_avail_nxt  = FIFO_depth - data_avail;

reg	[2:0] room_avail;

always@(posedge clk or negedge reset)
begin
	if(!reset)begin
	  full  	 <= 'b0;
	  empty 	 <= 'b0;
	  room_avail <= 'b000;
	  end
	else begin
	  full  	 <= full_nxt;
	  empty 	 <= empty_nxt;
	  room_avail <= room_avail_nxt;
	  end
end



sram aaa( .wrclk(clk), 
				    .wrptr(wr_count_num), 
					.wrdata(write_data), 
					.wr_en(wr_en), 
					.rdclk(clk), 
					.rdptr(rd_count_num), 
					.rddata(read_data), 
					.rd_en(rd_en));  
endmodule			
			
module sram(wrclk, wrptr, wrdata, wr_en, rdclk, rdptr, rddata, rd_en);
 // IO Declarations
	input		   wrclk, wr_en, rdclk, rd_en;
	input	[15:0] wrdata; 
	input	[2:0]  wrptr ;
	output  [15:0] rddata; 
	output  [2:0]  rdptr ;

    parameter PTR 		 = 3,
			  FIFO_WIDTH = 16,
			  A_MAX 	 = 2**(PTR);

    // Variable Declarations
	reg 	[FIFO_WIDTH-1:0] 	memory[A_MAX-1:0]; // ==8個[15:0]memory
	//reg 	[15:0] 				wrdata;
	
	//wrdata寫進Sram
	always@(posedge wrclk)
	begin
		if (wr_en)
			memory[wrptr] <= wrdata ;
		else
			memory[wrptr] <= memory[wrptr];		
	end

	reg		[15:0] rddata;
	//Sram output rddata
	always@(posedge rdclk)
	begin
		if (rd_en)
			rddata <= memory[wrptr] ;
		else
			rddata <= rddata;		
	end
	
endmodule

endmodule
