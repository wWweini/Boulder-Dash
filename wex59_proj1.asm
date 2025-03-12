# YOUR FULL NAME HERE
# YOUR PITT USERNAME HERE

# This is used in a few places to make grading your project easier.
.eqv GRADER_MODE 0

# This .include has to be up here so we can use the constants in the variables below.
.include "game_constants.asm"

# ------------------------------------------------------------------------------------------------
.data
# Boolean (0/1): 1 when the game is over, either successfully or not.
game_over: .word 0

# 0 = player can move, nonzero = they can't
player_move_timer: .word 0

# How many diamonds the player has collected.
player_diamonds: .word 0

# How many dirt blocks the player has picked up.
player_dirt: .word 0

# How many bugs the player has saved.
bugs_saved: .word 0

# How many bugs need to be saved.
bugs_to_save: .word 0

# Object arrays. These are parallel arrays. The player object is in slot 0,
# so the "player_x" and "player_y" labels are pointing to the same place as
# slot 0 of those arrays. Same thing for the other arrays.
object_type:   .word OBJ_EMPTY:NUM_OBJECTS
player_x:
object_x:      .word 0:NUM_OBJECTS # fixed 24.8 - X position
player_y:
object_y:      .word 0:NUM_OBJECTS # fixed 24.8 - Y position
player_vx:
object_vx:     .word 0:NUM_OBJECTS # fixed 24.8 - X velocity
player_vy:
object_vy:     .word 0:NUM_OBJECTS # fixed 24.8 - Y velocity
player_moving:
object_moving: .word 0:NUM_OBJECTS # 0 = still, nonzero = moving for this many frames
player_dir:
object_dir:    .word 0:NUM_OBJECTS # direction object is facing

.text

# ------------------------------------------------------------------------------------------------

# these .includes are here to make these big arrays come *after* the interesting
# variables in memory. it makes things easier to debug.
.include "display_2227_0611.asm"
.include "tilemap.asm"
.include "textures.asm"
.include "map.asm"
.include "levels.asm"
.include "obj.asm"
.include "collide.asm"

# ------------------------------------------------------------------------------------------------

.globl main
main:
	# load the map and objects
	la  a0, level_1
	#la  a0, test_level_dirt
	#la  a0, test_level_diamonds
	#la  a0, test_level_vines
	#la  a0, test_level_boulders
	#la  a0, test_level_goal
	#la  a0, test_level_bug_movement
	#la  a0, test_level_bug_vines
	#la  a0, test_level_bug_goal
	#la  a0, test_level_blank
	jal load_map

	# main game loop
	_loop:
		jal update_all
		jal draw_all
		jal display_update_and_clear
		jal wait_for_next_frame
	jal check_game_over
	beq v0, 0, _loop

	# when the game is over, show a message
	jal show_game_over_message
syscall_exit

# ------------------------------------------------------------------------------------------------
# Misc game logic
# ------------------------------------------------------------------------------------------------

# returns a boolean (1/0) of whether the game is over. 1 means it is.
check_game_over:
enter
	# might seem silly to have the whole function be one line,
	# but abstracting it into a function like this means that we
	# can expand the "game over" condition in the future.
	lw v0, game_over
leave

# ------------------------------------------------------------------------------------------------

# does what it says.
show_game_over_message:
enter
	# first clear the display
	jal display_update_and_clear

	# they finished successfully!
	li   a0, 7
	li   a1, 15
	lstr a2, "yay! you"
	li   a3, COLOR_GREEN
	jal  display_draw_colored_text

	li   a0, 12
	li   a1, 21
	lstr a2, "did it!"
	li   a3, COLOR_GREEN
	jal  display_draw_colored_text

	li   a0, 25
	li   a1, 37
	la   a2, tex_diamond
	jal  display_blit_5x5_trans

	li   a0, 32
	li   a1, 37
	lw   a2, player_diamonds
	jal  display_draw_int

	jal display_update_and_clear
leave

# ------------------------------------------------------------------------------------------------

# updates all the parts of the game.
update_all:
enter
	jal obj_update_all
	jal update_timers
	jal update_camera
leave

# ------------------------------------------------------------------------------------------------

# updates all timer variables (well... there's just one)
update_timers:
enter
	lw t0, player_move_timer
	beq t0, 0, _endif
	sub t0, t0, 1
	sw t0, player_move_timer
	_endif:
leave

# ------------------------------------------------------------------------------------------------

# positions camera based on player position.
update_camera:
enter
	li a0, 0
	jal obj_get_topleft_pixel_coords
	li t0, CAMERA_OFFSET_X 
	li t1, CAMERA_OFFSET_Y
	add a0, v0, t0
	add a1, v1, t1
	jal tilemap_set_scroll
leave

# ------------------------------------------------------------------------------------------------
# Player object
# ------------------------------------------------------------------------------------------------

# a0 = object index (but you can just access the player_ variables directly)
obj_update_player:
enter
	lw t0, player_moving
	bne t0, 0, _endif1
	jal player_check_goal
	jal player_check_vines
	bne v0, 0, _endif2
		jal player_check_place_input
		jal player_check_move_input
		j _endif2
	_endif1:
	li a0, 0
	jal obj_move
	_endif2:
	jal player_check_dig_input
leave

player_check_vines:
enter
	li a0, 0
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	jal tilemap_get_tile
	#check vine
	li t0, TILE_VINES
    	bne v0, t0, _endif
	    	#move backward
	    	li a0, 0
	    	li a1, PLAYER_MOVE_VELOCITY  
	    	li a2, PLAYER_MOVE_DURATION 
	    	jal obj_start_moving_backward
	    	li v0, 1
	_endif:
	li v0, 0
leave

player_check_move_input:
enter s0
	jal input_get_keys_held
	move s0, v0
	and t0, s0, KEY_U
	beq t0, 0, _endif1
	li a0, DIR_N
	jal player_try_move
	_endif1:
	
	and t0, s0, KEY_D
	beq t0, 0, _endif2
	li a0, DIR_S
	jal player_try_move			
	_endif2:
	
	and t0, s0, KEY_L
	beq t0, 0, _endif3
	li a0, DIR_W
	jal player_try_move
	_endif3:

	and t0, s0, KEY_R
	beq t0, 0, _endif4
	li a0, DIR_E
	jal player_try_move
	_endif4:
	
leave s0

player_try_move:
enter s0
	lw t0, player_dir
	beq t0, a0, _endif
		sw a0, player_dir
		li t1, PLAYER_MOVE_DELAY
    		sw t1, player_move_timer
	_endif:
	
	lw t0, player_move_timer
	bne t0, 0, _endif2
		li t1, PLAYER_MOVE_DELAY
    		sw t1, player_move_timer
    		#check for collision
		li a0, 0
		lw a1, player_dir
		jal obj_collision_check
		#switch cases 
		beq v0, COLLISION_TILE, _case1
    		beq v0, COLLISION_OBJ, _case2
		j _default
		_case1:
			j _endif2
		
        	_case2:
        		move a0, v1
        		jal player_try_push_object
        		beq v0, 0, _endif2
            		j _endif2
        	_default:
        		li a0, 0
    			li a1, PLAYER_MOVE_VELOCITY
    			li a2, PLAYER_MOVE_DURATION
    			jal obj_start_moving_forward		
	_endif2:	
leave s0

player_try_push_object:
enter s0
	move s0, a0
	#check type
	lw t0, object_type(s0)
	li t2, OBJ_BOULDER
	bne t0, t2, _return_no
	#check direction
	lw t2, player_dir 
	beq t2, DIR_N, _return_no
	beq t2, DIR_S, _return_no
	#check if it's moving
	lw t3, object_moving(s0)
	bne t3, 0, _return_no
	#check for collision
	move a0, s0
	lw a1, player_dir
	jal obj_collision_check
	beq v0, COLLISION_NONE, _push
	beq v0, COLLISION_TILE, _return_yes
	lw t0, object_type(s0)
	li t2, OBJ_BOULDER
	beq t0, t2, _return_no
	
	_push:
		move a0, s0
		lw a1, player_dir
		jal obj_push
		
	_return_yes:
		li v0, 1  
		j _return
	_return_no:
		li v0, 0 
_return:
leave s0

player_check_goal:
enter
	li a0, 0 
	jal obj_get_tile_coords 
	move a0, v0
   	move a1, v1
   	jal tilemap_get_tile
	li t0, TILE_GOAL 
	bne v0, t0, _endif 	
		lw t1, bugs_saved 		
		lw t2, bugs_to_save 		
		bne t1, t2, _endif 		
		li t3, 1 		
		sw t3, game_over 	
	_endif:	
leave

player_check_place_input:
enter 
	jal input_get_keys_pressed
	and t0, v0, KEY_Z
	beq t0, 0, _return
		li t1, GRADER_MODE
		lw t2, player_dirt
		beq t1, 0, _check_dirt
		_check_dirt:
	    		beq t2, 0, _return
	    	#check if no object in front
	 	li a0, 0
	    	li a1, TILE_SIZE
	    	jal obj_get_pixel_coords_in_front
	    	move a0, v0
	    	move a1, v1
	    	jal obj_find_at_position
		bne v0, -1, _return 
		#check if the tile in front is empty
	    	li a0, 0
		jal obj_get_tile_coords_in_front
		move a0, v0
		move a1, v1
		jal tilemap_get_tile
		li t3, TILE_EMPTY
		bne v0, t3, _return
		#set the tile to dirt and decrement player dirt 
		li t2, TILE_DIRT
	    	move a2, t2
		jal tilemap_set_tile
	    	lw t2, player_dirt
	    	sub t2, t2, 1
	    	sw t2, player_dirt
	_return:
leave 

player_check_dig_input:
enter 
	jal input_get_keys_pressed
	and t0, v0, KEY_X
	beq t0, 0 , _endif1
		#get the coordinates in fornt of the player
		li a0, 0
		jal obj_get_tile_coords_in_front
		#get the coortinates of tile
		move a0, v0
   		move a1, v1
   		jal tilemap_get_tile
    		#check if it's dirt
    		li t1, TILE_DIRT
    		bne v0, t1, _endif1
    		#set the tile empty
    		li t2, TILE_EMPTY
    		move a2, t2
    		jal tilemap_set_tile
    		lw t3, player_dirt
    		li t4, PLAYER_MAX_DIRT
    		bge t3, t4, _endif2
    			add t3, t3, 1         
    			sw t3, player_dirt
    		_endif2:
	_endif1:
leave
# ------------------------------------------------------------------------------------------------
# Diamond object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_diamond:
enter s0
	move s0, a0
	jal obj_move_or_check_for_falling
    	move a0, s0
    	jal obj_collides_with_player
    	beq v0, 0, _endif
    		lw t0, player_diamonds
    		add t0, t0, 1
    		sw t0, player_diamonds
    		move a0, s0
    		jal obj_free
    	_endif:
leave s0

# ------------------------------------------------------------------------------------------------
# Boulder object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_boulder:
enter
	jal obj_move_or_check_for_falling
leave

# ------------------------------------------------------------------------------------------------
# Bug object
# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_update_bug:
enter s0

	move s0, a0
	#check for goal
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	jal tilemap_get_tile
	li t1, TILE_GOAL
	bne v0, t1, _not_goal
		#is a goal
		move a0, s0
		jal obj_free
		lw t2, bugs_saved
		add t2, t2, 1
		sw t2, bugs_saved
	_not_goal:
	#check if the tile in front is vine
	move a0, s0
	jal obj_get_tile_coords
	move a0, v0
	move a1, v1
	jal tilemap_get_tile
	li t1, TILE_VINES
	bne v0, t1, _not_vines
		#set the tile to empty
		li a2, TILE_EMPTY
		jal tilemap_set_tile
	_not_vines:
	#movement
	move a0, s0
	lw t0, object_moving(s0)
	beq t0, 0, _else
	jal obj_move
	j _endif
	_else:
	  	#check front
		move a0, s0
		lw a1, object_dir(s0)
		jal obj_collision_check
		move t1, v0
    		#test left
    		move a0, s0
    		lw t0, object_dir(s0)
		sub t2, t0, 1
		and t2, t2, 3
		move a1, t2
		jal obj_collision_check
		move t3, v0
    		beq t3, COLLISION_NONE, _left
    		beq t1, COLLISION_NONE, _forward
    		j _right
    		
    		_left:
    			lw t2, object_dir(s0)
    			sub t2, t2, 1
			and t4, t2, 3
			sw t4, object_dir(s0)
		_forward:
			move a0, s0
		    	li a1, BUG_MOVE_VELOCITY
		    	li a2, BUG_MOVE_DURATION
		    	jal obj_start_moving_forward
		    	j _endif
		_right:
			lw t2, object_dir(s0)
			add t2, t2, 1
			and t4, t2, 3
			sw t4, object_dir(s0)
	_endif:
leave s0

# ------------------------------------------------------------------------------------------------
# Drawing functions
# ------------------------------------------------------------------------------------------------

# draws everything.
draw_all:
enter
	jal tilemap_draw
	jal obj_draw_all
	jal hud_draw
leave

# ------------------------------------------------------------------------------------------------

# draws the HUD ("heads-up display", the icons and numbers at the top of the screen)
hud_draw:
enter
	# draw a big black rectangle - this covers up any objects that move off
	# the top of the tilemap area
	li  a0, 0
	li  a1, 0
	li  a2, 64
	li  a3, TILEMAP_VIEWPORT_Y
	li  v1, COLOR_BLACK
	jal display_fill_rect_fast

	# draw how many diamonds the player has
	li  a0, 1
	li  a1, 1
	la  a2, tex_diamond
	jal display_blit_5x5_trans

	li  a0, 7
	li  a1, 1
	lw  a2, player_diamonds
	jal display_draw_int

	# draw how many dirt blocks the player has
	li  a0, 20
	li  a1, 1
	la  a2, tex_dirt
	jal display_blit_5x5_trans

	li  a0, 26
	li  a1, 1
	lw  a2, player_dirt
	jal display_draw_int

	# draw how many bugs have been saved and need to be saved
	li  a0, 39
	li  a1, 1
	la  a2, tex_bug_N
	jal display_blit_5x5_trans

	li  a0, 45
	li  a1, 1
	lw  a2, bugs_saved
	jal display_draw_int

	li  a0, 51
	li  a1, 1
	li  a2, '/'
	jal display_draw_char

	li  a0, 57
	li  a1, 1
	lw  a2, bugs_to_save
	jal display_draw_int
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index (but you can just access the player_ variables directly)
obj_draw_player:
enter 
	jal obj_get_topleft_pixel_coords
	#move to the first two arguments
	move a0, v0
	move a1, v1
	lw t0, player_dir
	#.word array multiply  by 4
	mul t0, t0, 4
	lw a2, player_textures(t0)
	jal blit_5x5_sprite_trans
leave 

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_diamond:
enter
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	la a2, tex_diamond
	jal blit_5x5_sprite_trans
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_boulder:
enter
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	la a2, tex_boulder
	jal blit_5x5_sprite_trans
	
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
obj_draw_bug:
enter s0
	move s0, a0
	jal obj_get_topleft_pixel_coords
	move a0, v0
	move a1, v1
	#load bug_textures[object_dir[s0]]
	lw t0, object_dir(s0)
	#.word array multiply  by 4
	mul t0, t0, 4
	lw a2, bug_textures(t0)
	jal blit_5x5_sprite_trans
leave s0

# ------------------------------------------------------------------------------------------------

# a0 = world x
# a1 = world y
# a2 = pointer to texture
# draws a 5x5 image, but coordinates are relative to the "world" (i.e. the tilemap).
# figures out the screen coordinates and draws it there.
blit_5x5_sprite_trans:
enter
	# draw the dang thing
	# x = x - tilemap_scx + TILEMAP_VIEWPORT_X
	lw  t0, tilemap_scx
	sub a0, a0, t0
	add a0, a0, TILEMAP_VIEWPORT_X

	# y = y - tilemap_scy + TILEMAP_VIEWPORT_Y
	lw  t0, tilemap_scy
	sub a1, a1, t0
	add a1, a1, TILEMAP_VIEWPORT_Y

	jal display_blit_5x5_trans
leave
