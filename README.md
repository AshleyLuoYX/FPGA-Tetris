# FPGA-Tetris
pp fan club


## Functionalities:
1. RGB
2. Generating blocks
3. Terminating
4. Score
5. Address (movement check -- main file)
6. VGA
7. Gravity (down by 1)

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
   
