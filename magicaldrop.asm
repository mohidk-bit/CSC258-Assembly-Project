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

BUBBLE_COLOURS:
    .word 0x00ff0000, 0x0000ff00, 0x000000ff, 0x00ffff00
ROW_INTERVAL:   .word 188   # ticks between new row
ROW_TICKS_LEFT: .word 188   # current tick count

GAME_OVER_TEXT:
    .asciiz "XXX..X..X.X.XXX.....XXX.X.X.XXX.XX.\nX...X.X.XXX.X.......X.X.X.X.X...X.X\nX.X.XXX.XXX.XX......X.X.X.X.XX..XX.\nX.X.X.X.X.X.X.......X.X.X.X.X...X.X\nXXX.X.X.X.X.XXX.....XXX..X..XXX.X.X"

RETRY_TEXT:
    .asciiz "XX..........XX..XXX.XXX.XX..X.X\nX.X..X......X.X.X....X..X.X.X.X\nXX..........XX..XX...X..XX...X.\nX.X..X......X.X.X....X..X.X..X.\nX.X.........X.X.XXX..X..X.X..X."

QUIT_TEXT:
    .asciiz "XXX.........XXX.X.X.XXX.XXX\nX.X..X......X.X.X.X..X...X.\nX.X.........X.X.X.X..X...X.\nXXX..X......XXX.X.X..X...X.\n..X...........X.XXX.XXX..X."

##############################################################################
# Mutable Data
##############################################################################
PLAYER_COL:
    .word 3                # start in the middle column (keeps track of player positioning)

HELD_COLOUR:  .word 0      # 0 means no colour held
HELD_COUNT:   .word 0

KEY_COUNT: .word 0         # Keeps track of pressed keys

DIFFICULTY_PROMPT:
  .asciiz "Choose Difficulty: 1 - EASY, 2 - MEDIUM, 3 - HARD\n"

##############################################################################
# Code
##############################################################################
	.text
	.globl main
    

    # Run the game.
main:
li $v0, 4
la $a0, DIFFICULTY_PROMPT
syscall

j choose_difficulty


choose_difficulty: 
# Check if anything is entered 
lw $t0, ADDR_KBRD
lw $t1, 0($t0)
beq $t1, $zero, wait_for_choice

# If something is entered:
lw $a0, 4($t0)   # Read the key once

li $t1, 0x31     # ASCII for '1'
li $t2, 313      # Easy difficulty time
beq $a0, $t1, set_difficulty 

li $t1, 0x32     # ASCII for '1'
li $t2, 188      # Easy difficulty time
beq $a0, $t1, set_difficulty 

li $t1, 0x33     # ASCII for '1'
li $t2, 125      # Easy difficulty time
beq $a0, $t1, set_difficulty

wait_for_choice:
li $v0, 32
li $a0, 16
syscall
j choose_difficulty

set_difficulty:
la $t0, ROW_INTERVAL
sw $t2, 0($t0)      # interval for subsequent rows

la $t0, ROW_TICKS_LEFT  #countdown for first row

j start_game


start_game:
li $a0, 3          # x
li $a1, 10           # y
li $a2, 18          # width
li $a3, 32          # height
li $t5, 0x00808080  # grey
jal draw_rect


li $v0, 10          # exit after drawing


li $a0, 5          # x
li $a1, 12           # y
li $a2, 14          # width
li $a3, 28          # height
li $t5, 0x00000000  # grey
jal draw_rect

li $s2, 12   # y of the first row
li $s3, 6    # rows left to draw
draw_starting_rows:
beq $s3, $zero, starting_rows_done

li $a0, 5  #starting x
add $a1, $s2, $zero  #starting y
li $a2, 7   #number of bubbles starting 
jal draw_random_bubble_row

addi $s2, $s2, 2  #move to next row
addi $s3, $s3, -1 
j draw_starting_rows

starting_rows_done:
# Drawing Player Character Pixels
# Drawing White Pixel 
li $a0, 11          # x value
li $a1, 42          # y value
li $a2, 1           # width
li $a3, 1           # height
li $t5, 0x00ffffff
jal draw_rect

# Drawing Green Pixel
li $a0, 11          # x value
li $a1, 43          # y value
li $a2, 1           # width
li $a3, 2           # height
li $t5, 0x0000ff00
jal draw_rect



game_loop:
lw $t0, ADDR_KBRD
lw $t8, 0($t0)           # 0 means key is not ready
beq $t8, $zero, wait_for_next_frame


lw $a0, 4($t0)           # read it 
li $t1, 0x71             # loads a q
beq $a0, $t1, quit_game  # check if input was "q"


li $t1, 0x61             # loads "a"
beq $a0, $t1, move_left  # check if the input was "a"

li $t1, 0x64             # loads "d"
beq $a0, $t1, move_right # check if the input was "d"

li $t1, 0x73             # loads "s"
beq $a0, $t1, grab_bubbles # check if the input was "s"

li $t1, 0x77             # loads "w"
beq $a0, $t1, throw_bubbles # checks if the input was "w"


wait_for_next_frame:
li $v0, 32               # sleep for 16 milliseconds
li $a0, 16
syscall

la $t0, ROW_TICKS_LEFT
lw $t1, 0($t0)
addi $t1, $t1, -1  # one tick done
sw $t1, 0($t0)

beq $t1, $zero, advance_rows
j game_loop


quit_game:
li $v0, 10
syscall

move_left: 
lw $t2, PLAYER_COL   #load player's current column 
beq $t2, $zero, wait_for_next_frame  #already at left edge

sll $a0, $t2, 1   # x = column * 2 
addi $a0, $a0, 5  # x = 5 + column * 2
li $a1, 42        # y of the white tip
li $a2, 1         # width
li $a3, 3         # height to cover 3 pixels
li $t5, 0x00000000 # color it black
jal draw_rect

# Reload Column since draw_rect changes t2
la $t0, PLAYER_COL
lw $t2, 0($t0)
addi $t2, $t2, -1  #shift it to the left so column - 1
sw $t2, 0($t0)     #update the PLAYER_COL

# Draw White Tip 
sll $a0, $t2, 1
addi $a0, $a0, 5
li $a1, 42
li $a2, 1
li $a3, 1
li $t5, 0x00ffffff
jal draw_rect

# Draw Green Tip
li $a1, 43
li $a2, 1
li $a3, 2
li $t5, 0x0000ff00
jal draw_rect

j key_processed


move_right:
lw $t2, PLAYER_COL   #load player's current column 
li $t1, 6
beq $t2, $t1, wait_for_next_frame  #already at right edge

sll $a0, $t2, 1   # x = column * 2 
addi $a0, $a0, 5  # x = 5 + column * 2
li $a1, 42        # y of the white tip
li $a2, 1         # width
li $a3, 3         # height to cover 3 pixels
li $t5, 0x00000000 # color it black
jal draw_rect

# Reload Column since draw_rect changes t2
la $t0, PLAYER_COL
lw $t2, 0($t0)
addi $t2, $t2, 1  #shift it to the left so column + 1
sw $t2, 0($t0)     #update the PLAYER_COL

# Draw White Tip 
sll $a0, $t2, 1
addi $a0, $a0, 5
li $a1, 42
li $a2, 1
li $a3, 1
li $t5, 0x00ffffff
jal draw_rect

# Draw Green Tip
li $a1, 43
li $a2, 1
li $a3, 2
li $t5, 0x0000ff00
jal draw_rect

j key_processed

grab_bubbles:
lw $t0, ADDR_DSPL
lw $t1, PLAYER_COL
sll $t1, $t1, 3          # 8 bytes per bubble column
addi $t0, $t0, 9748      # offset of pixel (5, 38)
add $t0, $t0, $t1        # move to desired column
li $t2, 13               # current board row

find_lowest_bubble:
lw $t4, 0($t0)           # read the current cell color
beq $t4, $zero, skip_empty_row
j check_held_colour

skip_empty_row:
beq $t2, $zero, key_processed
addi $t2, $t2, -1        # move up one 
addi $t0, $t0, -512      # two bitmap rows, 256 bytes each
j find_lowest_bubble


check_held_colour:
la $t6, HELD_COLOUR
lw $t5, 0($t6)
beq $t5, $zero, start_grab # Grab it if not already holding anything
beq $t5, $t4, start_grab   # Grab if color already holding is same 
j key_processed      # Holding a different colour


throw_bubbles:
la $t6, HELD_COUNT
lw $t3, 0($t6)
beq $t3, $zero, key_processed  # not holding anything, so count towards key pressed

la $t7, HELD_COLOUR
lw $t4, 0($t7)

lw $t0, ADDR_DSPL
lw $t1, PLAYER_COL
sll $t1, $t1, 3       # 8 bytes per bubble column
addi $t0, $t0, 9748   # row 13, col 0
add $t0, $t0, $t1     # row 13 in player col 
addi $t9, $t0, -6656  # row 0 in the same col: 13*512 up 

li $t2, 0
li $t8, 14            # total cells in the col

find_throw_space:
beq $t2, $t8, check_throw_space
lw $t5, 0($t0)
beq $t5, $zero, scan_throw_up
j check_throw_space

scan_throw_up:
addi $t2, $t2, 1
addi $t0, $t0, -512
j find_throw_space

check_throw_space:
slt $t5, $t2, $t3              # 1 if empty cells 
beq $t5, $zero, start_throw
j key_processed                 # keep the bubbles in hand if they won't fit

start_throw:
addi $t0, $t0, 512             # first empty cell below the stack
add $t1, $t0, $zero            # save the first thrown address
add $t8, $t3, $zero            # start the match count with the held count

throw_one_bubble:
sw $t4,   0($t0)               # paint the four pixels of the bubble
sw $t4,   4($t0)
sw $t4, 256($t0)
sw $t4, 260($t0)

addi $t2, $t2, -1              # one fewer empty cell
addi $t3, $t3, -1              # one fewer bubble to place
beq $t3, $zero, finish_throw
addi $t0, $t0, 512             # next bubble goes one row lower
j throw_one_bubble

finish_throw:
sw $zero, 0($t6)               # clear HELD_COUNT
sw $zero, 0($t7)               # clear HELD_COLOUR

count_match_above:
beq $t1, $t9, check_match_count # stop at top of col
addi $t5, $t1, -512            # bubbles above address
lw $t3, 0($t5)
beq $t3, $t4, extend_match
j check_match_count

extend_match:
add $t1, $t5, $zero            # new top of the matching run
addi $t8, $t8, 1
j count_match_above

check_match_count:
slti $t5, $t8, 3               # 1 if the run is shorter than 3
beq $t5, $zero, clear_vertical_match
beq $t2, $zero, game_over      # a bubble remains in row 13
j key_processed

clear_vertical_match:
sw $zero,   0($t1)
sw $zero,   4($t1)
sw $zero, 256($t1)
sw $zero, 260($t1)

addi $t8, $t8, -1
beq $t8, $zero, key_processed
addi $t1, $t1, 512             # clear the next bubble down
j clear_vertical_match

start_grab:
sw $t4, 0($t6)
la $t7, HELD_COUNT
lw $t3, 0($t7)

grab_one_bubble:
sw $zero,   0($t0)       # clear all four pixels
sw $zero,   4($t0)
sw $zero, 256($t0)
sw $zero, 260($t0)
addi $t3, $t3, 1         # one more bubble held

beq $t2, $zero, finish_grab
addi $t2, $t2, -1
addi $t0, $t0, -512
lw $t5, 0($t0)
beq $t5, $t4, grab_one_bubble  # Keep looping until different color

finish_grab:
sw $t3, 0($t7)
j key_processed

key_processed:
# la $t0, KEY_COUNT
# lw $t1, 0($t0)
# addi $t1, $t1, 1
# sw $t1, 0($t0)

# li $t2, 10
# beq $t1, $t2, advance_rows
j wait_for_next_frame

advance_rows:
# sw $zero, 0($t0)          # reset count back to 0
lw $t1, ROW_INTERVAL
la $t0, ROW_TICKS_LEFT
sw $t1, 0($t0)

lw $t0, ADDR_DSPL
addi $t0, $t0, 9492       # address of pixel (5, 37): 37 * 256 + 5 * 4
li $t1, 26                # copy source pixel rows 37 through 12

shift_pixel_row:
beq $t1, $zero, draw_new_top_row
add $t2, $t0, $zero       # start at x = 5 for this row
li $t3, 14                # pixels across the playfield

shift_pixel:
beq $t3, $zero, shift_next_row
lw $t4, 0($t2)            # read the original pixel
sw $t4, 512($t2)          # write two pixel rows below
addi $t2, $t2, 4          # move right one pixel
addi $t3, $t3, -1
j shift_pixel

shift_next_row:
addi $t0, $t0, -256       # move the source up one pixel row
addi $t1, $t1, -1
j shift_pixel_row

draw_new_top_row:
li $a0, 5                 # playfield left edge
li $a1, 12                # playfield top edge
li $a2, 7                 # seven new bubbles
jal draw_random_bubble_row
j check_bottom_row

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
jr $ra                     # return to the calling program

check_bottom_row:
lw $t0, ADDR_DSPL
addi $t0, $t0, 9748       # top-left pixel of row 13, column 0: (5, 38)
li $t1, 7                 # cells to check


# Try Finding a bubble in the bottom most row
check_bottom_cell:
beq $t1, $zero, wait_for_next_frame
lw $t2, 0($t0)
beq $t2, $zero, next_bottom_cell
j game_over             

# Move right 
next_bottom_cell:
addi $t0, $t0, 8         
addi $t1, $t1, -1
j check_bottom_cell



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



draw_random_bubble_row: 
add $t9, $ra, $zero       # save initial position
add $t4, $a0, $zero       # current x
add $t6, $a1, $zero       # current y
add $t7, $a2, $zero       # bubbles left to draw 

random_bubble_loop: 
beq $t7, $zero, random_bubble_row_done

li $v0, 42
li $a0, 0   # random generator ID
li $a1, 4   # pick index between 0 to 3
syscall

sll $t0, $a0, 2   # color index * 4 bytes
la $t1, BUBBLE_COLOURS
add $t1, $t1, $t0
lw $t5, 0($t1)   # store the color in the t5 register for pixel

add $a0, $t4, $zero  # bubble x
add $a1, $t6, $zero  # bubble y
li $a2, 2            # width
li $a3, 2            # height
jal draw_rect


# move right by 1 bubble: 
addi $t4, $t4, 2  
addi $t7, $t7, -1  

j random_bubble_loop

random_bubble_row_done: 
jr $t9


game_over: 
jal clear_bitmap

li $a0, 14  # x position
li $a1, 23  # y position
la $a2, GAME_OVER_TEXT
jal draw_bitmap_text

li $a0, 16  # x position
li $a1, 34  # y position
la $a2, RETRY_TEXT
jal draw_bitmap_text

li $a0, 18  # x position
li $a1, 42  # y position
la $a2, QUIT_TEXT
jal draw_bitmap_text

game_over_wait:
lw $t0, ADDR_KBRD
lw $t1, 0($t0)  # Check if anything is input
beq $t1, $zero, game_over_idle

lw $t1, 4($t0)   # read key
li $t2, 0x72     # checks for "r"
beq $t1, $t2, retry_game
li $t2, 0x71     # checks for "q"
beq $t1, $t2, quit_game

game_over_idle:
li $v0, 32
li $a0, 16
syscall #waits 16 ms before checking again

j game_over_wait

retry_game:
li $t0, 3
sw $t0, PLAYER_COL
sw $zero, HELD_COUNT
sw $zero, HELD_COLOUR

lw $t0, ROW_INTERVAL
sw $t0, ROW_TICKS_LEFT   # Start with full countdown

jal clear_bitmap
j start_game


clear_bitmap:
li $a0, 0          # x
li $a1, 0          # y
li $a2, 64         # width
li $a3, 64         # height
li $t5, 0          # black
j draw_rect

draw_bitmap_text:
lw $t1, ADDR_DSPL
sll $t2, $a0, 2             # x * 4 bytes
add $t1, $t1, $t2
sll $t2, $a1, 8             # y * 256 bytes
add $t1, $t1, $t2           # $t1 = start of current bitmap row

add $t2, $t1, $zero         # $t2 = current pixel address
add $t0, $a2, $zero         # $t0 = current character address
li $t4, 10                  # Newline character
li $t5, 0x00ffffff          # White color
li $t6, 0x2e                # Period character

bitmap_text_loop:
lbu $t3, 0($t0)
beq $t3, $zero, bitmap_text_done
addi $t0, $t0, 1           # Advance to the next character

beq $t3, $t4, bitmap_text_next_row
beq $t3, $t6, bitmap_text_next_pixel
sw $t5, 0($t2)             # Paint the X white

bitmap_text_next_pixel:
addi $t2, $t2, 4
j bitmap_text_loop

bitmap_text_next_row:
addi $t1, $t1, 256
add $t2, $t1, $zero         # Return to the starting x
j bitmap_text_loop

bitmap_text_done:
jr $ra

