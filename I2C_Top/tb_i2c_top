`timescale 1ns/1ns
module tb_i2c_top();
parameter   NUM_I2CSLV=3;
reg         clk = 1'b0;
reg         rstn = 1'b0;
reg         wr_enable = 1'b0;
reg         rd_enable = 1'b0;
reg  [6:0]  devaddr;
reg  [7:0]  regaddr;
reg  [7:0]  regdat;
wire        rddat_valid;
wire [7:0]  rd_pdat;
wire        sda_pos;
wire        scl_pos; //+++++
wire        scl_neg; //+++++
wire [3:0]  i2c_rddat0;
wire [3:0]  i2c_rddat1;
reg         sim_clk = 1'b0;
reg         sda_1d  =1'b0;
reg         scl_1d  =1'b0;//+++++
reg         scl_2d  =1'b0;//+++++
reg         scl_3d  =1'b0;//+++++
reg [6*8-1:0] I2C_OP_ASCII = "IDLE";


tri1        sda,scl;

always
    #10 clk = ~clk; //
    
always  
    #250000 sim_clk = ~sim_clk;
    
i2c_master i2c_master(
    .clk        (clk        ),
    .rstn       (rstn       ),
    .wr_enable  (wr_enable  ),
    .rd_enable  (rd_enable  ),
    .sda        (sda        ),
    .scl        (scl        ),
    .devaddr    (devaddr    ),
    .regaddr    (regaddr    ),
    .regdat     (regdat     ),
    .rddat_valid(rddat_valid),
    .rd_pdat    (rd_pdat    )   
);
// I2C Slave Device Address (default value: 'h57)
i2c_slave i2c_slave(
    .clk         (clk),
    .rstn        (rstn),
    .scl         (scl),
    .sda         (sda),
    .reg0dat     ()
);
// I2C Slave Device Address ('h1)
i2c_slave #(.DEVADDR(7'b0000001))u1_i2c_slave(
    .clk        (clk),
    .rstn       (rstn),
    .scl        (scl),
    .sda        (sda),
    .reg0dat    (i2c_rddat0)
);
// I2C Slave Device Address ('h2)
i2c_slave #(.DEVADDR(7'b0000010))u2_i2c_slave(
    .clk        (clk),
    .rstn       (rstn),
    .scl        (scl),
    .sda        (sda),
    .reg0dat    (i2c_rddat1)
);
// sda posedge proc
always@(posedge clk)
begin
    sda_1d <= sda;
end
assign sda_pos = sda&&(~sda_1d);

// edge detector for scl/++++++++++++++++23213
always@(posedge clk)
begin
     scl_3d <= scl_2d;   
     scl_2d <= scl_1d;
     scl_1d <= scl;
end

assign  scl_pos = scl_2d && (~scl_3d);
assign  scl_neg = ~scl_2d && scl_3d;

// edge detector for scl/++++++++++++++++23213




initial
begin
    clk = 1'b0;
    #100 rstn = 1'b1;
    i2c_wr(7'h57,8'h00,8'h8f);
    i2c_wr(7'h57,8'h01,8'h8e);
    i2c_wr(7'h57,8'h02,8'h8d);
    i2c_wr(7'h57,8'h03,8'h8a);  
    i2c_rd(7'h57,8'h00);
    i2c_rd(7'h57,8'h01);
    i2c_rd(7'h57,8'h02);
    i2c_rd(7'h57,8'h03);
    i2c_wr(7'h01,8'h00,8'haa);
    i2c_wr(7'h01,8'h01,8'hbb);
    i2c_wr(7'h01,8'h02,8'hcc);
    i2c_wr(7'h01,8'h03,8'hdd);
    i2c_rd(7'h01,8'h00);
    i2c_rd(7'h01,8'h01);
    i2c_rd(7'h01,8'h02);
    i2c_rd(7'h01,8'h03);    
    i2c_wr(7'h02,8'h00,8'ha1);
    i2c_wr(7'h02,8'h01,8'hb2);
    i2c_wr(7'h01,8'h02,8'hc3);
    i2c_wr(7'h01,8'h03,8'hd4);
    i2c_rd(7'h02,8'h00);
    i2c_rd(7'h02,8'h01);
    i2c_rd(7'h01,8'h02);
    i2c_rd(7'h01,8'h03);    
    $stop;
end
// Trigger "wr_enable" sginal ,I2C Master to execute Write operation
task i2c_wr;
input   [6:0] devaddr_i;    // slave device address
input   [7:0] regaddr_i;    // slave register address
input   [7:0] regdat_i;     // slave write data
begin
    I2C_OP_ASCII = "I2C_WR";
    devaddr = devaddr_i;
    regaddr = regaddr_i;
    regdat  = regdat_i; 
    @(posedge clk)
    wr_enable <= 1'b1;
    @(posedge clk)
    wr_enable <= 1'b0;
    wait(scl && sda_pos)
    I2C_OP_ASCII = "IDLE";
    @(posedge sim_clk);
    @(posedge sim_clk);
    $display("I2C Master Write slave addr=0x%x, reg addr = 0x%x, dat = 0x%x",devaddr_i,regaddr_i,regdat_i);
end
endtask

// Trigger "rd_enable" signal , I2C Master to execute Read operation
task i2c_rd;
input   [6:0] devaddr_i;    // slave device address
input   [7:0] regaddr_i;    // slave register address
begin
    I2C_OP_ASCII = "I2C_RD";
    devaddr = devaddr_i;
    regaddr = regaddr_i;
    @(posedge clk)
    rd_enable <= 1'b1;
    @(posedge clk)
    rd_enable <= 1'b0;
    @(posedge rddat_valid) begin
    $display("I2C Master Read  slave addr=0x%x, reg addr = 0x%x, dat = 0x%x",devaddr_i,regaddr_i,rd_pdat);
    end
    I2C_OP_ASCII = "IDLE";
    @(posedge sim_clk);
    @(posedge sim_clk);
end
endtask


endmodule
