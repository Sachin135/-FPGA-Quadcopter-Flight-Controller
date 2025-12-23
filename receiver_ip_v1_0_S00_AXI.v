`timescale 1 ns / 1 ps

module receiver_ip_v1_0_S00_AXI #
(
    // axi data width
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // axi address width
    parameter integer C_S_AXI_ADDR_WIDTH = 4
)
(
   
    input  wire [5:0]                    rx_in,

    input  wire                          S_AXI_ACLK,
    input  wire                          S_AXI_ARESETN,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_AWADDR,
    input  wire [2:0]                    S_AXI_AWPROT,
    input  wire                          S_AXI_AWVALID,
    output wire                          S_AXI_AWREADY,
    input  wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_WDATA,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] S_AXI_WSTRB,
    input  wire                          S_AXI_WVALID,
    output wire                          S_AXI_WREADY,
    output wire [1:0]                    S_AXI_BRESP,
    output wire                          S_AXI_BVALID,
    input  wire                          S_AXI_BREADY,
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] S_AXI_ARADDR,
    input  wire [2:0]                    S_AXI_ARPROT,
    input  wire                          S_AXI_ARVALID,
    output wire                          S_AXI_ARREADY,
    output wire [C_S_AXI_DATA_WIDTH-1:0] S_AXI_RDATA,
    output wire [1:0]                    S_AXI_RRESP,
    output wire                          S_AXI_RVALID,
    input  wire                          S_AXI_RREADY
);

    // AXI4LITE signals
    reg  [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                           axi_awready;
    reg                           axi_wready;
    reg  [1:0]                    axi_bresp;
    reg                           axi_bvalid;
    reg  [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                           axi_arready;
    reg  [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg  [1:0]                    axi_rresp;
    reg                           axi_rvalid;

    // local parameters for addressing
    localparam integer ADDR_LSB          = (C_S_AXI_DATA_WIDTH/32) + 1;
    // 2 bits of address index
    localparam integer OPT_MEM_ADDR_BITS = 1;

 
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;

    wire                          slv_reg_rden;
    wire                          slv_reg_wren;
    reg  [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer                       byte_index;
    reg                           aw_en;

// io connections  
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;

    // implement axi_awready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en       <= 1'b1;
        end else begin    
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awready <= 1'b1;
                aw_en       <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en       <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end 
    end       

    // implement axi_awaddr latching
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin    
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                axi_awaddr <= S_AXI_AWADDR;
            end
        end 
    end       

    // implement axi_wready generation
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin    
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end 
    end       

    // slave register write enable
    assign slv_reg_wren = axi_wready && S_AXI_WVALID &&
                          axi_awready && S_AXI_AWVALID;

    // write logic for example registers (not used by RX logic)
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= {C_S_AXI_DATA_WIDTH{1'b0}};
            slv_reg1 <= {C_S_AXI_DATA_WIDTH{1'b0}};
            slv_reg2 <= {C_S_AXI_DATA_WIDTH{1'b0}};
            slv_reg3 <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB])  // [3:2]
                    2'h0: for (byte_index = 0;
                               byte_index <= (C_S_AXI_DATA_WIDTH/8)-1;
                               byte_index = byte_index+1)
                              if (S_AXI_WSTRB[byte_index] == 1)
                                  slv_reg0[(byte_index*8) +: 8] <=
                                      S_AXI_WDATA[(byte_index*8) +: 8];
                    2'h1: for (byte_index = 0;
                               byte_index <= (C_S_AXI_DATA_WIDTH/8)-1;
                               byte_index = byte_index+1)
                              if (S_AXI_WSTRB[byte_index] == 1)
                                  slv_reg1[(byte_index*8) +: 8] <=
                                      S_AXI_WDATA[(byte_index*8) +: 8];
                    2'h2: for (byte_index = 0;
                               byte_index <= (C_S_AXI_DATA_WIDTH/8)-1;
                               byte_index = byte_index+1)
                              if (S_AXI_WSTRB[byte_index] == 1)
                                  slv_reg2[(byte_index*8) +: 8] <=
                                      S_AXI_WDATA[(byte_index*8) +: 8];
                    2'h3: for (byte_index = 0;
                               byte_index <= (C_S_AXI_DATA_WIDTH/8)-1;
                               byte_index = byte_index+1)
                              if (S_AXI_WSTRB[byte_index] == 1)
                                  slv_reg3[(byte_index*8) +: 8] <=
                                      S_AXI_WDATA[(byte_index*8) +: 8];
                    default: begin
                        slv_reg0 <= slv_reg0;
                        slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end    

   
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 1'b0;
            axi_bresp  <= 2'b00;
        end else begin    
            if (axi_awready && S_AXI_AWVALID &&
                ~axi_bvalid && axi_wready && S_AXI_WVALID) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // OKAY
            end else begin
                if (S_AXI_BREADY && axi_bvalid) begin
                    axi_bvalid <= 1'b0;
                end  
            end
        end
    end   

   
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin    
            if (~axi_arready && S_AXI_ARVALID) begin
                axi_arready <= 1'b1;
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end 
    end       

  
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 1'b0;
            axi_rresp  <= 2'b00;
        end else begin    
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // OKAY
            end else if (axi_rvalid && S_AXI_RREADY) begin
                axi_rvalid <= 1'b0;
            end                
        end
    end    

    
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;

   
    // pwm outputs// we assume 6 channels for now but only really use 4
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch1;
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch2;
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch3;
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch4;
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch5;
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_width_ch6;

    // exposing the period for the throttle
    wire [C_S_AXI_DATA_WIDTH-1:0] pulse_period_ch3;

    // status signals for debugging
    wire new_data_ch1, new_data_ch2, new_data_ch3;
    wire new_data_ch4, new_data_ch5, new_data_ch6;
    wire overflow_ch1, overflow_ch2, overflow_ch3;
    wire overflow_ch4, overflow_ch5, overflow_ch6;

    // channel 1
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch1 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[0]),
        .pulse_width (pulse_width_ch1),
        .pulse_period(),         
        .new_data    (new_data_ch1),
        .overflow    (overflow_ch1)
    );

    // channel 2
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch2 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[1]),
        .pulse_width (pulse_width_ch2),
        .pulse_period(),         
        .new_data    (new_data_ch2),
        .overflow    (overflow_ch2)
    );

    // channel 3
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch3 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[2]),
        .pulse_width (pulse_width_ch3),
        .pulse_period(pulse_period_ch3), 
        .new_data    (new_data_ch3),
        .overflow    (overflow_ch3)
    );

    // channel 4
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch4 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[3]),
        .pulse_width (pulse_width_ch4),
        .pulse_period(),         
        .new_data    (new_data_ch4),
        .overflow    (overflow_ch4)
    );

    // channel 5
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch5 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[4]),
        .pulse_width (pulse_width_ch5),
        .pulse_period(),          // not exported
        .new_data    (new_data_ch5),
        .overflow    (overflow_ch5)
    );

    // channel 6
    rx_capture_core #(
        .COUNTER_WIDTH(C_S_AXI_DATA_WIDTH)
    ) rx_capture_ch6 (
        .clk         (S_AXI_ACLK),
        .rst_n       (S_AXI_ARESETN),
        .rx_in       (rx_in[5]),
        .pulse_width (pulse_width_ch6),
        .pulse_period(),          // not exported
        .new_data    (new_data_ch6),
        .overflow    (overflow_ch6)
    );

    // now we map the registers to channels to genuinely expose them
    // 0x00 - 0x0C correspond to CH1 to Ch4 widths 
    always @(*) begin
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS : ADDR_LSB])  // [3:2]
            2'h0: reg_data_out <= pulse_width_ch1;
            2'h1: reg_data_out <= pulse_width_ch2;
            2'h2: reg_data_out <= pulse_width_ch3;    // THROTTLE width
            2'h3: reg_data_out <= pulse_width_ch4;
            default: reg_data_out <= 32'd0;
        endcase
    end

    
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= {C_S_AXI_DATA_WIDTH{1'b0}};
        end else begin    
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;
            end   
        end
    end    

endmodule