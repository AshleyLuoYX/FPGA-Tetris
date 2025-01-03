# FPGA-Tetris
Tetris game implemented in VHDL on Cmod A7-35T FPGA board. 


## Functionalities:
1. RGB
2. Generating blocks
3. Terminating
4. Score
5. Address (movement check -- main file)
6. VGA
7. Gravity (down by 1)

## File Organization (tentative)
```
/FPGA-Tetris/
  ├── /src/                       # Source code for VHDL modules
  │     ├── top_level.vhd         # Main file integrating all components 
  │     ├── clock_divider.vhd     # Generates slower clocks  --> Sunny
  │     ├── vga_controller.vhd    # Handles VGA timing and sync signals 
  │     ├── rendering_engine.vhd  # Converts game state to pixel data  --> Ashley
  │     ├── game_logic.vhd        # Implements core Tetris game rules
  │     ├── input_handler.vhd     # Handles player inputs (debouncing)  --> Emma
  │     ├── rom_tetrominos.vhd    # ROM for precomputed tetromino shapes  --> Ashley
  │     ├── tetris_utils.vhd      # Package file for reusable functions/types
  │     ├── debouncer.vhd         # Reusable button debouncer --> Emma
  │     ├── counter.vhd           # Reusable counter module  --> Sunny
  │
  ├── /tb/                        # Testbenches for verification
  │     ├── tb_top_level.vhd      # Testbench for top_level.vhd
  │     ├── tb_game_logic.vhd     # Testbench for game_logic.vhd
  │     ├── tb_vga_controller.vhd # Testbench for vga_controller.vhd
  │     ├── tb_rendering.vhd      # Testbench for rendering_engine.vhd
  │     ├── tb_utils.vhd          # Testbench for tetris_utils.vhd functions
  │
  ├── /docs/                      # Documentation and diagrams
  │     ├── block_diagram.pdf     # System block diagram
  │     ├── timing_constraints.txt# FPGA timing constraints  --> Sunny
  │     ├── module_interfaces.txt # Description of module interfaces  
  │
  ├── /constraints/               # FPGA-specific constraint files
  │     ├── tetris_pin_map.xdc    # Pin mappings for buttons, VGA, etc.  --> Emma
  │
  └── README.md                   # Overview of the project

```

## notes:
1. on terminating logic
```
   **if terminating check == TRUE
       terminate --> update grid --> update score
   elseif user has input
     if movement check == valid
       do movement.vhd (move --> update address)
     else
       down by 1
   else
     down by 1**
   ```

## Basic info
   
### height of grid: 20
   
### width of grid: 12

### encode seven blocks:
   ![image](https://github.com/user-attachments/assets/6b8032a0-da16-42fc-9e3d-d66bcd1c9183)

   The seven Tetrominos are encoded using 4*4 binary matrices. We define a Tetromino type which contains 7 different shapes. For example, the I Tetromino with 0 degree of rotation can be encoded as b"0000111100000000" or a 4-bit hex value. The I tetromino with 4 types of rotation is represented as an array: ("0000111100000000", "0010001000100010", "0000111100000000", "0010001000100010"). Other shapes are also hard-coded similarly. 

   To track the Tetromino's position, we track it by the coordinate of the 4*4 matrix (represented by the coordinate of the lower-left cell of the matrix). To calculate the coordinates of the Tetromino, we do the following: 
   ```
   for every cell in the matrix that is '1':
      block_x = piece_pos_x + matrix_column
      block_y = piece_pos_y + matrix_row
   ```

![5a92b5056e8066344c49ee614c4cdb5](https://github.com/user-attachments/assets/d4328eef-e87e-468e-a14e-ee5d7bcabd87)

   
