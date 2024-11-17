Each shape consists of a collection of coordinates defined by values relative to the
bottom left reference, (x,y), of each shape. 

The coordinates of each shape are used to achieve 3 main functionalities:
1. Displaying visual position of the block
2. Movement collision checking
3. Terminal collision checking

*In both types of collision checking, every coordinate a given shape will be checked
 with the coordinates of every 'set' block at the base of the screen.

Example:
Shape O with coordinates [(x,y), (x,y+1), (x+1,y+1), (x+1,y)] is falling
The screen has set blocks at coordinates [(1,1), (1,2), (2,1)]

A for loop will iterate from (x,y) = (6,20) down to (x,y) = (6,0), representing
the block's path from the top of the screen down to the bottom

For each iteration, the coordinates of the shape will be compared to the coordinates
of the set blocks in "Terminal Collision" check. If there is user input and Terminal
Check is false (it hasn't reached the bottom or hit a set block), then the potential 
new position of the shape is calculated and checked against the existing set blocks. 
If there is no overlap, the actual position (defined by the for loop values) is updated. 
But the relative (x+1,y) values remain the same.

