.data
displayaddress:     .word   0x10008000
# ...
.text
# ...
# Some of the starter code from the handout, augmented to draw more pixel colours
li $t1, 0xff0000            # $t1 = red
li $t2, 0x00ff00            # $t2 = green
li $t3, 0x0000ff            # $t3 = blue
lw $t0, displayaddress      # $t0 = base address for display
# use ALU operations to make all the colours
add $t4, $t1, $t3           # $t4 = magenta
add $t5, $t2, $t3           # $t5 = cyan
add $t6, $t1, $t2           # $t6 = yellow
add $t7, $t6, $t3           # $t7 = white

# write these pixel colours into memory
sw $t1, 0($t0)              # paint the first unit (i.e., top-left) red
sw $t2, 4($t0)              # paint the second unit on the first row green
sw $t4, 8($t0)              # paint the third unit on the first row magenta
sw $t5, 12($t0)              # paint the fourth unit on the first row cyan
sw $t6, 16($t0)              # paint the fifth unit on the first row yellow
sw $t3, 128($t0)            # paint the first unit on the second row blue

#################################################################
# Code created in-class to draw lines on the screen
#################################################################
# set the X coordinate to 5
addi $t1, $zero, 5
# set the Y coordinate to 16
addi $t2, $zero, 16
# set the length of the line to 7
addi $t3, $zero, 7
# set the colour of the line to cyan
li $t5, 0x00ffff            # set $t5 to cyan

jal draw_line

# set the X coordinate to 9
addi $t1, $zero, 30
# set the Y coordinate to 12
addi $t2, $zero, 
# set the length of the line to 5
addi $t3, $zero, 5
# set the colour of the line to cyan
li $t5, 0xffff00            # set $t5 to yellow

jal draw_line

# Let's draw a rectangle!
# set the X coordinate to 9
addi $a0, $zero, 7
# set the Y coordinate to 12
addi $a1, $zero, 10
# set the length of the line to 5
addi $a2, $zero, 4
# set the colour of the line to cyan
addi $a3, $zero, 6
# set the colour of the line to cyan

jal draw_rect

li $v0, 10                  # terminate the program gracefully, otherwise it'll go into draw_line again
syscall

#
# The rectangle drawing function
#
# - $t0 = The location in memory of the top-left corner of the bitmap
# - $a0 = The X coordinate of the top-left corner of the rectangle
# - $a1 = The Y coordinate of the top-left corner of the rectangle
# - $a2 = The width of the rectangle
# - $a3 = The height of the rectangle
draw_rect:
lw $t0, displayaddress          # $t0 = base address for display
# start the row-drawing loop
row_drawing_loop_start:
add $t1, $a0, $zero             # store the X coordinate input into $t1
add $t2, $a1, $zero             # store the Y coordinate input into $t2
add $t3, $a2, $zero             # store the length of the line into $t3
beq $a3, $zero, row_drawing_loop_end    # if the height parameter is zero, then exit the loop

addi $sp, $sp, -4               # move the stack pointer to the next empty location in memory
sw $ra, 0($sp)                  # push the return address register onto the stack
jal draw_line                   # draw a line at the current X and Y coordinates
lw $ra, 0($sp)                  # pop the return address register from the stack
addi $sp, $sp, 4                # move the stack pointer to the top element of the stack

addi $a3, $a3, -1               # reduce the height parameter by 1
addi $a1, $a1, 1                # increase the Y coordinate by 1
j row_drawing_loop_start        # jump to the start of the loop
# end the row-drawing loop
row_drawing_loop_end:
#
jr $ra                     # return to the calling program


#
# The line drawing function
#
draw_line:
# - $t0 = The location in memory of the top-left corner of the bitmap
# - $t1 = The X coordinate of the start of the line
# - $t2 = The Y coordinate of the start of the line
# - $t3 = The length of the line
# - $t5 = The colour of the line
# - $t8 = The location in memory for the current pixel being drawn

# calculate the horizontal offset from the leftmost column
sll $t1, $t1, 2             # multiply $t1 by 4 to get the horizontal offset in bytes
# calculate the vertical offset from the first row
sll $t2, $t2,  7            # multiply $t2 by 128 to get the vertical offset in bytes
add $t8, $t0, $t1           # add the horizontal offset to $t0, store in $t8
add $t8, $t8, $t2           # add the vertical offset to $t8

line_loop_start:
beq $t3, $zero, line_loop_end       # check to see if we've reached the end of the line
addi $t3, $t3, -1                   # decrement the loop variable (the length of the line)
sw $t5, 0($t8)                      # store a pixel in the current location in memory.
addi $t8, $t8, 4                    # move to the next pixel in the line.
j line_loop_start                   # jump to the start of the line-drawing loop
line_loop_end:
jr $ra                      # return to the calling program


# ...
