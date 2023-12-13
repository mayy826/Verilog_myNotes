module i2c_slave(
    input             clk,
    input             rstn,
    inout             scl,
    inout             sda,
    output     [3:0]  reg0dat
);
wire        devaddr_ack;
wire        scl_oe;
reg         sda_oe;
reg [7:0]   cs;
reg [7:0]   ns;
wire        sda_in;
wire        scl_in;
wire        dev_addr_stage;
wire        reg_addr_stage;
wire        reg_wrdat_stage/*synthesis keep*/;
reg [6:0]   devaddr_val/*synthesis noprune*/;
wire        scl_pos;
wire        scl_neg;
wire        sda_neg;
wire        sda_pos;
wire        csr_wr;
reg  [7:0]  regwrdat_val;
reg  [7:0]  regaddr_val;
wire [7:0]  rd_dat;

parameter DEVADDR = 7'b1010111;

assign  scl = scl_oe ? 1'bz : 1'b0;
assign  sda = sda_oe ? 1'bz : 1'b0;
assign  sda_in = sda;
assign  scl_in = scl;

// FSM state definition
parameter 
    idle_st     = 'd0,
    start_st    = 'd1,
    devaddr_st  = 'd2,
    devreg_st   = 'd3,
    chk_st_p1   = 'd4,
    chk_st_p2   = 'd5,
    rddat_st    = 'd6,
    wrdat_st    = 'd7,
    chk_rd_ack  = 'd8,
    chk_wr_ack  = 'd9,
    chk_dev_ack = 'd10,
    chk_reg_ack = 'd11,
    stop_st     = 'd12;
    
// edge detector for scl
reg scl_1d,scl_2d,scl_3d;
reg sda_1d,sda_2d;
reg [7:0] i2c_bit_cnt;
reg         rd_oper;
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        {scl_1d,scl_2d,scl_3d} <= 3'b000;
    else begin
        scl_3d <= scl_2d;   
        scl_2d <= scl_1d;
        scl_1d <= scl_in;
    end
end

assign  scl_pos = scl_2d && (~scl_3d);
assign  scl_neg = ~scl_2d && scl_3d;

// edge detector for sda
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        {sda_1d,sda_2d} <= 2'b00;
    else begin
        sda_2d <= sda_1d;
        sda_1d <= sda_in;
    end
end
assign  sda_neg = ~sda_1d && sda_2d;	// neg edge detect
assign   sda_pos = sda_1d && ~sda_2d;   // pos edge detect

always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        i2c_bit_cnt <= 'h0;
    else if((cs == start_st )&& scl_neg)
        i2c_bit_cnt <= 'h1;
    else if((cs == chk_st_p2) && sda_neg)
            i2c_bit_cnt <= 'h0;
    else if((i2c_bit_cnt == 'd9) && (scl_neg)) 
        i2c_bit_cnt <= 1'b1;        
    else if((cs !== idle_st) && (scl_neg))
        i2c_bit_cnt <= i2c_bit_cnt + 1'b1;
    else
        i2c_bit_cnt <= i2c_bit_cnt;
end

// FSM Sequential part
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        cs <= 'h0;
    else 
        cs <= ns;
end

// FSM Combinational part
always@(*)
begin
    case(cs)
        idle_st: if((scl == 1'b1) && sda_neg)
            ns = start_st;
        else
            ns = idle_st;
        start_st:
            if(scl_neg)
                ns =devaddr_st;
            else
                ns = start_st;
        devaddr_st:
            if((i2c_bit_cnt == 'd8) && scl_neg && devaddr_ack)
                ns = chk_dev_ack;
            else if ((i2c_bit_cnt == 'd8) && scl_neg && ~devaddr_ack)
                ns = idle_st;
            else
                ns = devaddr_st;
        chk_dev_ack:
            if(scl_neg && ~rd_oper)
                ns = devreg_st;
            else if(scl_neg && rd_oper)
                ns = rddat_st;
            else
                ns = chk_dev_ack;
        devreg_st:
            if((i2c_bit_cnt == 'd8) && scl_neg)
                ns = chk_reg_ack;
            else
                ns = devreg_st;
        chk_reg_ack:
            if(scl_neg)
                ns = chk_st_p1;
            else
                ns = chk_reg_ack;
        chk_st_p1:
            if(scl_pos)
                ns = chk_st_p2;
            else
                ns = chk_st_p1;
        chk_st_p2:
            if(sda_neg)
                ns = devaddr_st;
            else if(scl_neg)
                ns = wrdat_st;
            else
                ns = chk_st_p2;
        wrdat_st:
            if((i2c_bit_cnt == 'd8) && scl_neg)
                ns = chk_wr_ack;
            else    
                ns = wrdat_st;
        rddat_st:
            if((i2c_bit_cnt == 'd8) && scl_neg)
                ns = chk_rd_ack;
            else
                ns = rddat_st;
        chk_wr_ack:
            if(scl_neg)
                ns = stop_st;
            else
                ns = chk_wr_ack;
        chk_rd_ack:
            if(~sda && scl_pos)
                ns = rddat_st;
            else if(sda && scl_pos)
                ns = stop_st;
            else
                ns = chk_rd_ack;
        stop_st:
            if(scl && sda_pos)
                ns = idle_st;
            else
                ns = stop_st;
        default: ns = idle_st;
    endcase
end

// detect I2C Read operation proc
always@(posedge clk or negedge rstn)
begin   
    if(~rstn)
        rd_oper <= 1'b0;
    else if((cs == chk_st_p2) && sda_neg)
        rd_oper <= 1'b1;
    else if(cs == idle_st)
        rd_oper <= 1'b0;
    else    
        rd_oper <= rd_oper;
end

// scl_oe operation
assign  scl_oe = 1'b1;	

// sda_oe operation
always@*
begin
    case(cs)
    idle_st:     sda_oe = 1'b1;
    start_st:    sda_oe = 1'b1;
    devaddr_st:  sda_oe = 1'b1;
    chk_dev_ack: sda_oe = 1'b0;
    devreg_st : 
        if(i2c_bit_cnt == 'd9)
                 sda_oe = 1'b0;
        else
                 sda_oe = 1'b1;
    chk_st_p1 :  sda_oe = 1'b1;
    chk_st_p2 :  sda_oe = 1'b1;
    chk_reg_ack: sda_oe = 1'b0;
    wrdat_st  :  sda_oe = 1'b1;
    stop_st   :  sda_oe = 1'b1;
    chk_rd_ack:  sda_oe = 1'b1;
    chk_wr_ack:  sda_oe = 1'b0;
    rddat_st  :
        if(i2c_bit_cnt == 'd1)
                 sda_oe = rd_dat[7];
        else if(i2c_bit_cnt == 'd2)
                 sda_oe = rd_dat[6];
        else if(i2c_bit_cnt == 'd3)
                 sda_oe = rd_dat[5];
        else if(i2c_bit_cnt == 'd4)
                 sda_oe = rd_dat[4];
        else if(i2c_bit_cnt == 'd5)
                 sda_oe = rd_dat[3];
        else if(i2c_bit_cnt == 'd6)
                 sda_oe = rd_dat[2];
        else if(i2c_bit_cnt == 'd7)
                 sda_oe = rd_dat[1]; 
        else if(i2c_bit_cnt == 'd8)
                 sda_oe = rd_dat[0]; 
        else 
                 sda_oe = 1'b1;
    default: sda_oe = 1'b1;
    endcase
end

//////////////////////////////////////
// I2C Register Interface Proc
//////////////////////////////////////
assign dev_addr_stage = (cs == devaddr_st)  ? 1'b1 : 1'b0;
assign reg_addr_stage = (cs == devreg_st) ? 1'b1 : 1'b0;
assign reg_wrdat_stage = ((cs == wrdat_st) || (cs == chk_st_p2)) ? 1'b1 : 1'b0;

// device address check
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        devaddr_val <= 'h0;
    else if((dev_addr_stage) && (scl_neg))
        devaddr_val <= {devaddr_val[5:0],sda_in};
    else
        devaddr_val <= devaddr_val;
end

assign  devaddr_ack = (devaddr_val == DEVADDR) ? 1'b1 : 1'b0;

// reg addreess operaton
always@(posedge clk or negedge rstn)
begin
    if(~rstn)
        regaddr_val <= 'h0;
    else if((reg_addr_stage) && (scl_neg))
        regaddr_val <=  {regaddr_val[6:0],sda_in};
    else
        regaddr_val <= regaddr_val;
end

// reg wr data operation
always@(posedge clk  or negedge rstn)
begin
    if(~rstn)
        regwrdat_val <= 'h0;
    else if((reg_wrdat_stage) && (scl_neg))
        regwrdat_val <= {regwrdat_val[6:0],sda_in};
    else
        regwrdat_val <= regwrdat_val;
end
assign  csr_wr = ((cs == chk_wr_ack) && scl_neg ) ? 1'b1 : 1'b0; //when scl negedge trigger,read write ack check,csr_wr ==1'b1


// I2C Slave Register 
i2c_slave_reg u_i2c_slave_reg (
    .clk         (clk        ),
    .rstn        (rstn       ),
    .csr_wr      (csr_wr     ),
    .regwrdat_val(regwrdat_val),
    .regaddr_val (regaddr_val ),
    .rd_dat      (rd_dat      ),
    .reg0dat     (reg0dat)
);

////////////////////////////////////
//// show cs value in ASCII code format in modelsim

//reg [11*8-1:0] slv_cs_asci;
//always@*
//begin
//    case(cs)
//  idle_st     : slv_cs_asci = "idle_st    ";
//  start_st    : slv_cs_asci = "start_st   ";
//  devaddr_st  : slv_cs_asci = "devaddr_st ";
//  devreg_st   : slv_cs_asci = "devreg_st  ";
//  chk_st_p1   : slv_cs_asci = "chk_st_p1  ";
//  chk_st_p2   : slv_cs_asci = "chk_st_p2  ";
//  rddat_st    : slv_cs_asci = "rddat_st   ";
//  wrdat_st    : slv_cs_asci = "wrdat_st   ";
//  chk_rd_ack  : slv_cs_asci = "chk_rd_ack ";
//  chk_dev_ack : slv_cs_asci = "chk_dev_ack";
//  stop_st     : slv_cs_asci = "stop_st    "; 
//  chk_wr_ack  : slv_cs_asci = "chk_wr_ack ";
//    endcase       
//end
endmodule


//這是I2C_slave存放data的register!!!!!!!!!!

module i2c_slave_reg (
    input        clk,
    input        rstn,
    input        csr_wr, //Read/write之後的ack
    input  [7:0]  regwrdat_val, //存放data value的register
    input  [7:0]  regaddr_val,  //存放address value的register
    output [7:0]  rd_dat,
    output [3:0]  reg0dat
);
reg [7:0] csr_reg[3:0]; //宣告四個[7:0] register,分別為csr_reg[0]/csr_reg[1]/csr_reg[2]/csr_reg[3]

always@(posedge clk or negedge rstn)
begin   
    if(~rstn) begin
        csr_reg[0] <= 8'h0;
        csr_reg[1] <= 8'h0;
        csr_reg[2] <= 8'h0;
        csr_reg[3] <= 8'h0;     
        end
    else  if(csr_wr) begin//當輪到Read/write之後的ack
        case(regaddr_val) //存放address value的register變化時
        8'h0: csr_reg[0] = regwrdat_val; 
        8'h1: csr_reg[1] = regwrdat_val; 
        8'h2: csr_reg[2] = regwrdat_val; 
        8'h3: csr_reg[3] = regwrdat_val; 
        endcase
       end
    else begin
       csr_reg[0] = csr_reg[0];
       csr_reg[1] = csr_reg[1]; 
       csr_reg[2] = csr_reg[2];
       csr_reg[3] = csr_reg[3];
     end
end

assign rd_dat = (regaddr_val == 'h0) ? csr_reg[0] :
                (regaddr_val == 'h1) ? csr_reg[1] :
                (regaddr_val == 'h2) ? csr_reg[2] :
                (regaddr_val == 'h3) ? csr_reg[3] :
                'h00;
assign reg0dat[3:0] = csr_reg[0][3:0];
endmodule
