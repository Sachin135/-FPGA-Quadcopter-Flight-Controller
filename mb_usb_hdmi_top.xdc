########################################
# SYSTEM CLOCK (100 MHz on N15)
########################################

# Board clock: 100 MHz on pin N15
set_property PACKAGE_PIN N15 [get_ports clk_100MHz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100MHz]

# Tell Vivado this is a 100 MHz clock (10 ns period)
create_clock -period 10.000 -name sys_clk -waveform {0 5} \
  [get_ports clk_100MHz]


########################################
# RESET BUTTON (BTN0) - UNUSED FOR NOW
########################################

# If you later re-add reset_rtl_0 as a top-level port and wire it,
# you can uncomment these. For now, leave them commented since there
# is no reset_rtl_0 port in design_1_wrapper.
#
# set_property PACKAGE_PIN J2 [get_ports reset_rtl_0]
# set_property IOSTANDARD LVCMOS25 [get_ports reset_rtl_0]


########################################
# UART (USB-UART BRIDGE, FTDI)
########################################

# UART RX (FPGA receives from USB-UART, FTDI TX -> FPGA input)
set_property PACKAGE_PIN B16 [get_ports usb_rx]
set_property IOSTANDARD LVCMOS33 [get_ports usb_rx]

# UART TX (FPGA sends to USB-UART, FPGA output -> FTDI RX)
set_property PACKAGE_PIN A16 [get_ports usb_tx]
set_property IOSTANDARD LVCMOS33 [get_ports usb_tx]

#CH1 - Roll / Aileron  (In0_0[0])
set_property PACKAGE_PIN J15 [get_ports {In0_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In0_0[0]}]

#CH2 - Pitch / Elevator  (In1_0[0])
set_property PACKAGE_PIN J16 [get_ports {In1_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In1_0[0]}]

#CH3 - Throttle  (In2_0[0])
set_property PACKAGE_PIN K14 [get_ports {In2_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In2_0[0]}]

#CH4 - Yaw / Rudder  (In3_0[0])
set_property PACKAGE_PIN K16 [get_ports {In3_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In3_0[0]}]

#CH5 - Aux1  (In4_0[0])
set_property PACKAGE_PIN G18 [get_ports {In4_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In4_0[0]}]

#CH6 - Aux2  (In5_0[0])
set_property PACKAGE_PIN H17 [get_ports {In5_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {In5_0[0]}]

########################################
# LEDS (Bval[0..3] = LED0..LED3)
########################################

# LED0  (Bval[0]) -> C13
set_property PACKAGE_PIN C13 [get_ports {gpio_io_o_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_io_o_0[0]}]

# LED1  (Bval[1]) -> C14
set_property PACKAGE_PIN C14 [get_ports {gpio_io_o_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_io_o_0[1]}]

# LED2  (Bval[2]) -> D14
set_property PACKAGE_PIN D14 [get_ports {gpio_io_o_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_io_o_0[2]}]

# LED3  (Bval[3]) -> D15
set_property PACKAGE_PIN D15 [get_ports {gpio_io_o_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {gpio_io_o_0[3]}]


########################################
# PWM OUTPUTS (mapped to LEDs 4..7 for now)
########################################

#pwm_out_0[0] -> Bval[4] (LED4) D16
set_property PACKAGE_PIN H14 [get_ports {pwm_out_0[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_0[0]}]

#pwm_out_0[1] -> Bval[5] (LED5) F18
set_property PACKAGE_PIN F15 [get_ports {pwm_out_0[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_0[1]}]

#pwm_out_0[2] -> Bval[6] (LED6) E17
set_property PACKAGE_PIN F14 [get_ports {pwm_out_0[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_0[2]}]

#pwm_out_0[3] -> Bval[7] (LED7) D17
set_property PACKAGE_PIN J13 [get_ports {pwm_out_0[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {pwm_out_0[3]}]

# scl
set_property PACKAGE_PIN H13 [get_ports {iic_rtl_0_scl_io}]
set_property IOSTANDARD LVCMOS33   [get_ports {iic_rtl_0_scl_io}]

# sda
set_property PACKAGE_PIN E14 [get_ports {iic_rtl_0_sda_io}]
set_property IOSTANDARD LVCMOS33   [get_ports {iic_rtl_0_sda_io}]