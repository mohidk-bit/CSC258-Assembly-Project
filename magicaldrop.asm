################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Magical Drop.
#
# Student 1: Muhammad Mohid Khan, 1012557207
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       1
# - Unit height in pixels:      1
# - Display width in pixels:    64
# - Display height in pixels:   64
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

##############################################################################
# Code
##############################################################################
	.text
	.globl main
    
li $a0, 15          # x
li $a1, 3           # y
li $a2, 33          # width
li $a3, 54          # height
li $t5, 0x00808080  # grey
jal draw_rect


li $v0, 10          # exit after drawing


li $a0, 21          # x
li $a1, 9           # y
li $a2, 21          # width
li $a3, 42          # height
li $t5, 0x00000000  # grey
jal draw_rect


li $v0, 10          # exit after drawing
syscall



    # Run the game.
main:
    # Initialize the game

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop

draw_rect:
lw $t0, ADDR_DSPL          # $t0 = base address for display
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
sll $t2, $t2, 8            # multiply $t2 by 128 to get the vertical offset in bytes
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
