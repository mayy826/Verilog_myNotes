`timescale  1ns / 1ps      

module tb_synch_fifo;      

    // synch_fifo Parameters   
    parameter PERIOD            = 10            ;
    parameter FIFO_PTR          = 3            ;
    parameter FIFO_WIDTH        = 16            ;
    parameter FIFO_DEPTH        = 8             ;

    // synch_fifo Inputs
    reg                         clk = 0         ;
    reg                         rst_n = 0       ;
    reg                         write_en = 0    ;
    reg [FIFO_WIDTH-1:0]        write_data = 0  ;
    reg                         read_en = 0     ;

    // synch_fifo Outputs
    wire [FIFO_WIDTH-1:0]       read_data       ;
    wire                        full            ;
    wire                        empty           ;
    wire [FIFO_PTR:0]           room_avail      ;
    wire [FIFO_PTR:0]           data_avail      ;


    initial
    begin
        forever #(PERIOD/2)  clk = ~clk;
    end

    initial
    begin
        $display("\nstatus: %t Testbench started\n\n", $time);
        #(PERIOD*10) rst_n  =  1;
        $display("status: %t done reset", $time);
        repeat(5) @(posedge clk);
        read_after_write(50);
        repeat(5) @(posedge clk);
        read_all_after_write_all();
        repeat(5) @(posedge clk);
        $finish;
    end

    synch_fifo 
    #(
        .FIFO_PTR               (FIFO_PTR       ),
        .FIFO_WIDTH             (FIFO_WIDTH     ),
        .FIFO_DEPTH             (FIFO_DEPTH     )
    )
    u_synch_fifo 
    (
        .clk                    (clk            ),
        .rst_n                  (rst_n          ),
        .write_en               (write_en       ),
        .write_data             (write_data     ),
        .read_en                (read_en        ),

        .read_data              (read_data      ),
        .full                   (full           ),
        .empty                  (empty          ),
        .room_avail             (room_avail     ),
        .data_avail             (data_avail     )
    );

    //--------------------------------------------------------------------------
    // read after write task
    //--------------------------------------------------------------------------
    task read_after_write;
	input [31:0] 	        num_write		; 
	reg [31:0] 		idx			; 
	reg [FIFO_WIDTH-1:0] 	valW			;
	integer                 error			;
    begin
        $display("status: %t total number of write data : %d", $time,num_write);
	error = 0;
	for (idx = 0; idx < num_write; idx = idx + 1) begin
	    valW = $random;
	    write_fifo(full, valW);
	    read_fifo(empty);
	    if (read_data != valW) begin
		error = error + 1;
		$display("status: %t ERROR at idx:0x%08x D:0x%02x, but D:0x%02x expected",$time,
			idx, read_data, valW);
	    end
	end
	if (error == 0) 
	    $display("status: %t read-after-write test pass", $time);
    end
    endtask

    //--------------------------------------------------------------------------
    // read all after write all task, write to fifo until it is full
    //--------------------------------------------------------------------------
    task read_all_after_write_all;
        reg [31:0]              index           ;
        reg [FIFO_WIDTH-1:0] 	valW		;
        reg [FIFO_WIDTH-1:0]    valC            ;
	integer 		error		;
    begin
        error = 0;
        for (index = 0; index < 2**FIFO_PTR; index = index + 1) begin
            valW = ~(index + 1);
            write_fifo(full,valW);
        end

        for (index = 0; index < 2**FIFO_PTR; index = index + 1) begin
            valC = ~(index + 1);
            read_fifo(empty);
            if (read_data != valC) begin
		error = error + 1;
                $display("status: %t ERROR at Index:0x%08x D:0x%02x, but D:0x%02x expected",$time,
			index, read_data, valC);
            end
        end

        if (error == 0) 
	    $display("status: %t read-all-after-write-all test pass", $time);
    end
    endtask

    //--------------------------------------------------------------------------
    // write fifo task
    //--------------------------------------------------------------------------
    task write_fifo;
        input                   fifo_full       ;
        input [FIFO_WIDTH-1:0]  value           ;
    begin
        write_en    <= ~fifo_full;
        write_data  <= value;
        @(posedge clk);
        write_en    <= 1'b0;
    end
    endtask

    //--------------------------------------------------------------------------
    // read fifo task
    //--------------------------------------------------------------------------
    task read_fifo;
        input                   fifo_empty      ;
    begin
        @(posedge clk);
        read_en     <= 1'b1;
        @(posedge clk);
        read_en     <= 1'b0;
        @(posedge clk);
    end
    endtask

endmodule
