//Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
//Date        : Tue Dec  9 21:17:28 2025
//Host        : SK_Laptop99 running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (In0_0,
    In1_0,
    In2_0,
    In3_0,
    In4_0,
    In5_0,
    clk_100MHz,
    gpio_io_o_0,
    iic_rtl_0_scl_io,
    iic_rtl_0_sda_io,
    pwm_out_0,
    usb_rx,
    usb_tx);
  input [0:0]In0_0;
  input [0:0]In1_0;
  input [0:0]In2_0;
  input [0:0]In3_0;
  input [0:0]In4_0;
  input [0:0]In5_0;
  input clk_100MHz;
  output [3:0]gpio_io_o_0;
  inout iic_rtl_0_scl_io;
  inout iic_rtl_0_sda_io;
  output [3:0]pwm_out_0;
  input usb_rx;
  output usb_tx;

  wire [0:0]In0_0;
  wire [0:0]In1_0;
  wire [0:0]In2_0;
  wire [0:0]In3_0;
  wire [0:0]In4_0;
  wire [0:0]In5_0;
  wire clk_100MHz;
  wire [3:0]gpio_io_o_0;
  wire iic_rtl_0_scl_i;
  wire iic_rtl_0_scl_io;
  wire iic_rtl_0_scl_o;
  wire iic_rtl_0_scl_t;
  wire iic_rtl_0_sda_i;
  wire iic_rtl_0_sda_io;
  wire iic_rtl_0_sda_o;
  wire iic_rtl_0_sda_t;
  wire [3:0]pwm_out_0;
  wire usb_rx;
  wire usb_tx;

  design_1 design_1_i
       (.In0_0(In0_0),
        .In1_0(In1_0),
        .In2_0(In2_0),
        .In3_0(In3_0),
        .In4_0(In4_0),
        .In5_0(In5_0),
        .clk_100MHz(clk_100MHz),
        .gpio_io_o_0(gpio_io_o_0),
        .iic_rtl_0_scl_i(iic_rtl_0_scl_i),
        .iic_rtl_0_scl_o(iic_rtl_0_scl_o),
        .iic_rtl_0_scl_t(iic_rtl_0_scl_t),
        .iic_rtl_0_sda_i(iic_rtl_0_sda_i),
        .iic_rtl_0_sda_o(iic_rtl_0_sda_o),
        .iic_rtl_0_sda_t(iic_rtl_0_sda_t),
        .pwm_out_0(pwm_out_0),
        .usb_rx(usb_rx),
        .usb_tx(usb_tx));
  IOBUF iic_rtl_0_scl_iobuf
       (.I(iic_rtl_0_scl_o),
        .IO(iic_rtl_0_scl_io),
        .O(iic_rtl_0_scl_i),
        .T(iic_rtl_0_scl_t));
  IOBUF iic_rtl_0_sda_iobuf
       (.I(iic_rtl_0_sda_o),
        .IO(iic_rtl_0_sda_io),
        .O(iic_rtl_0_sda_i),
        .T(iic_rtl_0_sda_t));
endmodule
