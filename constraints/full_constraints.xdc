## 12 MHz Clock Signal
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { clk }]; #IO_L12P_T1_MRCC_14 Sch=gclk
create_clock -add -name sys_clk_pin -period 83.33 -waveform {0 41.66} [get_ports {clk}];

## Reset Signal
#set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { reset }]; # Reset signal (assign correct pin)

## Pmod Header JA
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { red[0] }]; #IO_L5N_T0_D07_14 Sch=ja[1]
set_property -dict { PACKAGE_PIN H17   IOSTANDARD LVCMOS33 } [get_ports { red[1] }]; #IO_L5P_T0_D06_14 Sch=ja[7]
set_property -dict { PACKAGE_PIN G19   IOSTANDARD LVCMOS33 } [get_ports { green[0] }]; #IO_L4N_T0_D05_14 Sch=ja[2]
set_property -dict { PACKAGE_PIN H19   IOSTANDARD LVCMOS33 } [get_ports { green[1] }]; #IO_L4P_T0_D04_14 Sch=ja[8]
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { blue[0] }]; #IO_L9P_T1_DQS_14 Sch=ja[3]
set_property -dict { PACKAGE_PIN J19   IOSTANDARD LVCMOS33 } [get_ports { blue[1] }]; #IO_L6N_T0_D08_VREF_14 Sch=ja[9]
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { hsync }]; #IO_L8N_T1_D12_14 Sch=ja[10]
set_property -dict { PACKAGE_PIN L18   IOSTANDARD LVCMOS33 } [get_ports { vsync }]; #IO_L8P_T1_D11_14 Sch=ja[4]

## Button Inputs
set_property -dict { PACKAGE_PIN M3    IOSTANDARD LVCMOS33 } [get_ports { raw_drop }]; # Red button
set_property -dict { PACKAGE_PIN L3    IOSTANDARD LVCMOS33 } [get_ports { raw_left }]; # Blue button
set_property -dict { PACKAGE_PIN A16   IOSTANDARD LVCMOS33 } [get_ports { raw_right }]; # Yellow button
set_property -dict { PACKAGE_PIN K3    IOSTANDARD LVCMOS33 } [get_ports { raw_rotate }]; # Green button
set_property -dict { PACKAGE_PIN A18   IOSTANDARD LVCMOS33 } [get_ports { restart_game }]; #IO_L19N_T3_VREF_16 Sch=btn[0]

### LEDs
set_property -dict { PACKAGE_PIN A17   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]; # LED 0
set_property -dict { PACKAGE_PIN C16   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]; # LED 1


## UART
#set_property -dict { PACKAGE_PIN J18   IOSTANDARD LVCMOS33 } [get_ports { tx }]; #IO_L7N_T1_D10_14 Sch=uart_rxd_out