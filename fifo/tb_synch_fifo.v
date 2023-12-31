`timescale  1ns / 1ps      

module fifo_anya_tb();

	// fifo Inputs
	reg         clk		= 1'b0 ;
	reg         reset	= 1'b0 ;
	reg         rd_en0	= 1'b0 ;
	reg         wr_en0 	= 1'b0 ;
	reg  [15:0] write_data	   ;
	
	
	// fifo Outputs
	wire [15:0] read_data	   		  ;
	wire 		full, empty    		  ;
	wire		full_nxt, empty_nxt	  ;
	wire [3:0]  room_avail, data_avail;
	wire [15:0]  memory_wire		  ;
	
	// clk  
	always  
		begin
		#10 clk = ~clk;
		end	
	
	synch_fifo test_instance(
			.clk		(clk)  			, 
			.reset		(reset)			, 
			.rd_en0		(rd_en0)		, 
			.wr_en0		(wr_en0)		, 
			.write_data (write_data)	, 
			.read_data  (read_data) 	, 
			.full		(full) 			, 
			.empty		(empty)			,
			.full_nxt   (full_nxt) 		,
			.empty_nxt	(empty_nxt) 	,	
			.room_avail	(room_avail)	, 
			.data_avail (data_avail)	,
			.memory_wire( memory_wire)
	);
	

    initial
    begin
      $dumpfile("dump.vcd");
      $dumpvars(1,fifo_anya_tb);
        $display("\nstatus: %t Testbench started\n\n", $time);
        #(100) reset  =  1;
        $display("status: %t done reset", $time);
        repeat(5) @(posedge clk);
        read_after_write(50);
        repeat(5) @(posedge clk);
        read_all_after_write_all();
	    repeat(5) @(posedge clk);
        reset <= 1'b0;
        repeat(2) @(posedge clk);
      	reset <= 1'b1;
      	read_after_write(50);
        $finish;
		$display("status: %t done reset", $time);
    end



//	write fifo task
//-----------------------------------
    task write_fifo;
		input        full 		;
        input [15:0]  value		;
	begin
     	/*if(full == 1'b1)
		wr_en0 	  <= 1'b0;
		else begin*/		
		@(posedge clk);
        wr_en0     <= 1'b1		;
        write_data  <= value    ;
        @(posedge clk);
        wr_en0     <= 1'b0;	
		@(posedge clk);	
		//end           
    end
	endtask

//  read fifo task
//-----------------------------------
	task read_fifo;
		input        empty; 
	begin
		/*if(empty == 1'b1)
		rd_en0 	  <= 1'b0;
		else begin*/		
		@(posedge clk);
        rd_en0     <= 1'b1;
        @(posedge clk);
        rd_en0     <= 1'b0;	
		@(posedge clk);
        //end
    end
	endtask


// read after write task
//------------------------------------
    task read_after_write;
		input [31:0] 	num_write   ; //write 幾次
		reg [7:0] 		idx			; //第幾次trigger
		reg [15:0] 	valW			;


	for (idx = 0; idx < 8 ; idx = idx + 1) begin
	    valW = $random;
	    write_fifo(full, valW);
	    read_fifo(empty);
	   
	end
	endtask	
	
// read all after write all task, write to fifo until it is full
    //--------------------------------------------------------------------------
    task read_all_after_write_all;
        reg [15:0]  index       ;
        reg [15:0] 	valW		;
        reg [15:0]   valC        ;

    begin
        for (index = 0; index < 9; index = index + 1) begin
            valW = ~(index + 1);
            write_fifo(full,valW);
        end

      for (index = 0; index < 10; index = index + 1) begin
            valC = ~(index + 1);
            read_fifo(empty);          
        end

    end
    endtask	
	
		
endmodule	
	
