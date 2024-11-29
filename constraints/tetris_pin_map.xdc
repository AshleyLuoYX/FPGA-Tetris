# Clock signal (external clock)
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

# Reset button
set_property PACKAGE_PIN C2 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

# Game control buttons
set_property PACKAGE_PIN D3 [get_ports move_left]
set_property IOSTANDARD LVCMOS33 [get_ports move_left]

set_property PACKAGE_PIN D4 [get_ports move_right]
set_property IOSTANDARD LVCMOS33 [get_ports move_right]

set_property PACKAGE_PIN C3 [get_ports rotate]
set_property IOSTANDARD LVCMOS33 [get_ports rotate]

# VGA interface
set_property PACKAGE_PIN A1 [get_ports vga_hsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_hsync]

set_property PACKAGE_PIN A2 [get_ports vga_vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vga_vsync]

set_property PACKAGE_PIN B1 [get_ports vga_r]
set_property IOSTANDARD LVCMOS33 [get_ports vga_r]

set_property PACKAGE_PIN B2 [get_ports vga_g]
set_property IOSTANDARD LVCMOS33 [get_ports vga_g]

set_property PACKAGE_PIN C1 [get_ports vga_b]
set_property IOSTANDARD LVCMOS33 [get_ports vga_b]

# Debug LEDs (optional)
set_property PACKAGE_PIN F4 [get_ports debug_led]
set_property IOSTANDARD LVCMOS33 [get_ports debug_led]
