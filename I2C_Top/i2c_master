`timescale 1ns/1ns
module i2c_master(
    input            clk,
    input            rstn,
    input            wr_enable,
    input            rd_enable,
    inout            sda,
    inout            scl,
    input      [6:0] devaddr,
    input      [7:0] regaddr,
    input      [7:0] regdat,
    output           rddat_valid,
    output reg [7:0] rd_pdat
);

reg  [3:0] cs,ns;
wire [1:0] op_phase;
reg  [9:0] div_cnt;
reg  [8:0] devaddr_pdat;
reg  [8:0] regaddr_pdat;
reg  [8:0] wdat_pdat;
reg  [3:0] i2c_bit_cnt;
reg  [2:0] bitop_cnt;
reg        rd_operation;
reg        i2c_rw;
wire       bitop_done;
reg [3:0]  shift_index;
reg        sda_oe;
reg        scl_oe;
wire       scl_in;
wire       sda_in;
wire       scl_neg;
reg        scl_1d;

// FSM state definition
parameter idle_st    = 'h0,
          start_st   = 'h1,
          devaddr_st = 'h2,
          devreg_st  = 'h3,
          wrdat_st   = 'h4,
          stop_st    = 'h5,
          restart_st = 'h6,
          rddat_st   = 'h7
          ;
          
// I2C interface          
assign sda = sda_oe ? 1'bz : 1'b0;
assign scl = scl_oe ? 1'bz : 1'b0;
assign scl_in = scl;
assign sda_in = sda;

// SCL 100KHz : 'd499, SCL 400KHz : 'd249
parameter CNT_END = 'd249; // 400KHz
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        div_cnt <= 'h0;
    else if(div_cnt == CNT_END)
        div_cnt <= 'h0;
    else    
        div_cnt <= div_cnt + 1'b1;
end

assign trig_clk_t = (div_cnt == CNT_END) ? 1'b1 : 1'b0;

// i2c RW bit operation
always@(posedge clk or negedge rstn)
begin   
    if(~rstn)
        i2c_rw <= 1'b0;
    else if(cs == idle_st)
        i2c_rw <= 1'b0;
    else if((cs == restart_st) && (trig_clk_t))
        i2c_rw <= 1'b1;
    else
        i2c_rw <= i2c_rw;
end

always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        cs <= 'h0;
    else if(bitop_done ||  wr_enable || rd_enable)
        cs <= ns;
    else
        cs <= cs;
end
// i2c read operation flag
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        rd_operation <= 1'b0;
    else if(cs == stop_st)
        rd_operation <= 1'b0;
    else if (rd_enable)
        rd_operation <= 1'b1;
    else
        rd_operation <= rd_operation;
end

always@*
begin
    case(cs)
    idle_st:
        if(wr_enable || rd_enable)
            ns = start_st;
        else
            ns = idle_st;
    start_st: ns = devaddr_st;

    devaddr_st:
        if ((i2c_bit_cnt == 'd9) && i2c_rw)
            ns = rddat_st;
        else if (i2c_bit_cnt == 'd9)
            ns = devreg_st;
        else
            ns = devaddr_st;
    devreg_st:
        if ((i2c_bit_cnt == 'd9) && rd_operation)
            ns = restart_st;
        else if(i2c_bit_cnt == 'd9)
            ns = wrdat_st;
        else
            ns = devreg_st;
    wrdat_st:
        if (i2c_bit_cnt == 'd9)
            ns = stop_st;
        else 
            ns = wrdat_st;
    restart_st:
            ns = devaddr_st;
    rddat_st:
        if (i2c_bit_cnt == 'd9)
            ns = stop_st;
        else 
            ns = rddat_st;          
    stop_st:
            ns = idle_st;
            
    default: ns = idle_st;
    endcase
end


// sda_oe scl_oe proc
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        sda_oe <= 1'b1;
    else begin
       case(cs)
       idle_st    :                   
          sda_oe <= 1'b1;
       start_st   : 
          if(bitop_cnt == 'd1) 
             sda_oe <= 1'b0; 
          else 
             sda_oe <= sda_oe;
       devaddr_st : 
          if(bitop_cnt == 'd0) 
             sda_oe <= devaddr_pdat[8-shift_index];
          else 
             sda_oe <= sda_oe;
       devreg_st  : 
          if(bitop_cnt == 'd0) 
             sda_oe <= regaddr_pdat[8-shift_index];
          else 
             sda_oe <= sda_oe;
       wrdat_st   : 
          if(bitop_cnt == 'd0) 
             sda_oe <= wdat_pdat[8-shift_index];
          else 
             sda_oe <= sda_oe;
       restart_st : 
          if(bitop_cnt <= 'd1) 
             sda_oe <= 1'b1;
          else if(bitop_cnt >= 'd2) 
          sda_oe <= 1'b0;
          else 
          sda_oe <= sda_oe;
       rddat_st   : 
             sda_oe <= 1'b1;    // single read , and send nack to termianl read operation                 
       stop_st    : 
           if(bitop_cnt >= 'd2) 
          sda_oe <= 1'b1; 
           else 
             sda_oe <= 1'b0;
       default:
          sda_oe <= 1'b1;
       endcase
    end
end

// scl_oe operation
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        scl_oe <= 1'b1;
    else begin
       case(cs)
       idle_st:      
          scl_oe <= 1'b1;
       start_st   : 
          if(bitop_cnt >= 'd3)                    
              scl_oe <= 1'b0; 
          else 
              scl_oe <= 1'b1;
       devaddr_st : 
          if(bitop_cnt >= 'd2 && bitop_cnt <='d3) 
              scl_oe <= 1'b1; 
          else 
              scl_oe <= 1'b0;
       devreg_st  : 
          if(bitop_cnt >= 'd2 && bitop_cnt <='d3) 
              scl_oe <= 1'b1; 
          else 
              scl_oe <= 1'b0;   
       wrdat_st   : 
          if(bitop_cnt >= 'd2 && bitop_cnt <='d3) 
		      scl_oe <= 1'b1; 
		  else 
		      scl_oe <= 1'b0;  
       stop_st    : 
	      if(bitop_cnt >= 'd1)                    
		      scl_oe <= 1'b1; 
	      else 
		      scl_oe <= 1'b0;
       restart_st : 
	      if(bitop_cnt >= 'd3)                    
		      scl_oe <= 1'b0; 
		  else 
		      scl_oe <= 1'b1;
       rddat_st   : 
	      if(bitop_cnt >= 'd2 && bitop_cnt <='d3) 
		      scl_oe <= 1'b1; 
		  else 
		      scl_oe <= 1'b0;
	   default:
              scl_oe <= 1'b1;
       endcase
    end
end

// shift operation
always@(posedge clk or negedge rstn)
begin
    if(~rstn)  begin
       devaddr_pdat <= 'h0;
       regaddr_pdat <= 'h0;
       wdat_pdat    <= 'h0;
       end
    else if(((cs == start_st) || (cs == restart_st)) && bitop_done) begin   // load data
       devaddr_pdat <= {devaddr,i2c_rw,1'b1};
       regaddr_pdat <= {regaddr,1'b1};
       wdat_pdat    <= {regdat,1'b1};
       end
    else begin
       devaddr_pdat <= devaddr_pdat;
       regaddr_pdat <= regaddr_pdat;
       wdat_pdat    <= wdat_pdat;
    end
end

// bit operation
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        bitop_cnt <= 'h0;
    else if ((cs !== idle_st) && (bitop_cnt == 'd4) && (trig_clk_t))
        bitop_cnt <= 'h0;
    else if ((cs !== idle_st) && (trig_clk_t))
        bitop_cnt <= bitop_cnt + 1'b1;
    else
        bitop_cnt <= bitop_cnt;
end
assign bitop_done = ((cs !== idle_st) && (bitop_cnt == 'd4) && (trig_clk_t));

// I2C BIT count
always@(posedge clk or negedge rstn)
begin   
    if(~rstn)
        i2c_bit_cnt <= 'h0; 
    else if((bitop_done) && (cs == stop_st))
           i2c_bit_cnt <= 'h0;          
    else if(     (bitop_done)  &&
               ((cs == start_st) || (cs == restart_st))
           )
           i2c_bit_cnt <= 'h1;  
    else if((bitop_done) &&  (i2c_bit_cnt == 'd9))
          i2c_bit_cnt <= 'h1;             
    else if(bitop_done) 
          i2c_bit_cnt <= i2c_bit_cnt + 1'b1;
    else
        i2c_bit_cnt <= i2c_bit_cnt;
end

//shift bit index 
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        shift_index <= 'h0;
    else if(((cs == devaddr_st) || (cs == devreg_st) || (cs == wrdat_st))
            && (bitop_done)) begin
        if(shift_index == 'd8)
            shift_index <= 'h0;
        else
            shift_index <= shift_index + 1'b1;
    end
    else 
        shift_index <= shift_index;
end

// i2c master read data proc
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        scl_1d <= 1'b0;
    else
        scl_1d <= scl;
end
assign scl_neg = ~scl && scl_1d;

always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        rd_pdat <= 'h0;
    else if((cs == rddat_st) && scl_neg && (i2c_bit_cnt !== 'd9))
        rd_pdat <= {rd_pdat,sda};
    else
        rd_pdat <= rd_pdat;
end

assign rddat_valid = ((cs == rddat_st) && (i2c_bit_cnt == 'd9) && bitop_done) ? 1'b1 : 1'b0;
////////////////////////////////////
//// show cs value in ascii code format on modelsim
//reg [10*8-1:0] cs_ascii;
//always@*
//begin
//    case(cs)
//          idle_st   : cs_ascii = "idle_st";
//          start_st  : cs_ascii = "start_st";
//          devaddr_st: cs_ascii = "devaddr_st";
//          devreg_st : cs_ascii = "devreg_st";
//          wrdat_st  : cs_ascii = "wrdat_st";
//          stop_st   : cs_ascii = "stop_st";
//          restart_st: cs_ascii = "restart_st";
//          rddat_st  : cs_ascii = "rddat_st";
//    endcase       
//end

endmodule
