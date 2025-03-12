
# To add a new kind of object:
# - in game_constants.asm: add a new OBJ_KIND constant
# - in proj1.asm: add obj_KIND_update and obj_KIND_draw methods for it
# - in this file:
#   - add references to those methods in obj_update_methods and obj_draw_methods
#   - add an obj_new_KIND function in this file to allocate it and set it up any way you like
#	  - you don't have to crash if allocation fails; if it's an unimportant object (like a little
#       decoration or special effect or something) you can just fail silently
# - in map.asm: update char_to_obj and load_map to handle that object type
#   - then place the object by putting that character in the level data!
# - in textures.asm: make any texture(s) needed for that object to be used in obj_KIND_draw

.data
# A pair of arrays, indexed by direction, to turn a direction into x/y deltas.
# e.g. direction_delta_x[DIR_E] is 1, because moving east increments X by 1.
#                         N  E  S  W
direction_delta_x: .byte  0  1  0 -1
direction_delta_y: .byte -1  0  1  0
.text

# -------------------------------------------------------------------------------------------------

# a0 = object type
# tries to allocate an object.
# if successful, zeros out the other variables and returns the object's array index.
# if unsuccessful, returns -1.
obj_alloc:
enter
	# start at object 1 so we skip the player object slot.
	li v0, 4
	_loop:
		lw  t0, object_type(v0)
		beq t0, OBJ_EMPTY, _found
	add v0, v0, 4
	blt v0, NUM_OBJECTS_X4, _loop

	# fail!
	li v0, -1
	j _return

_found:
	# initialize the variables associated with it
	sw a0,   object_type(v0)
	sw zero, object_x(v0)
	sw zero, object_y(v0)
	sw zero, object_vx(v0)
	sw zero, object_vy(v0)
	sw zero, object_moving(v0)
	sw zero, object_dir(v0)
_return:
leave

# -------------------------------------------------------------------------------------------------

# a0 = object index
# frees an object.
obj_free:
enter
	tlti a0, 4 # you passed a negative object index (or the index of the player object).
	tgei a0, NUM_OBJECTS_X4 # you passed an invalid object index.
	sw zero, object_type(a0) # if this crashes, your index is not a multiple of 4.
leave

# -------------------------------------------------------------------------------------------------

# obj_new_boulder(x, y)
# Tries to create a boulder object and crashes if unsuccessful.
obj_new_boulder:
enter s0, s1
	move s0, a0
	move s1, a1

	li  a0, OBJ_BOULDER
	jal obj_alloc
	blt v0, 0, _else
		sw s0, object_x(v0)
		sw s1, object_y(v0)
	j _endif
	_else:
		println_str "Could not spawn boulder!"
		syscall_exit
	_endif:
leave s0, s1

# -------------------------------------------------------------------------------------------------

# obj_new_diamond(x, y)
# Tries to create a diamond object and crashes if unsuccessful.
obj_new_diamond:
enter s0, s1
	move s0, a0
	move s1, a1

	li  a0, OBJ_DIAMOND
	jal obj_alloc
	blt v0, 0, _else
		sw s0, object_x(v0)
		sw s1, object_y(v0)
	j _endif
	_else:
		println_str "Could not spawn diamond!"
		syscall_exit
	_endif:
leave s0, s1

# -------------------------------------------------------------------------------------------------

# obj_new_bug(x, y)
# Tries to create a bug object and crashes if unsuccessful.
obj_new_bug:
enter s0, s1
	move s0, a0
	move s1, a1

	li  a0, OBJ_BUG
	jal obj_alloc
	blt v0, 0, _else
		sw s0, object_x(v0)
		sw s1, object_y(v0)
	j _endif
	_else:
		println_str "Could not spawn diamond!"
		syscall_exit
	_endif:
leave s0, s1

# -------------------------------------------------------------------------------------------------

# a0 = object index
# returns a boolean (1/0) of whether the object is solid (acts like a solid tile).
# this includes boulders... and that's it for now
# also returns v1 = the type of this object.
obj_is_solid:
enter
	lw v1, object_type(a0)

	li  v0, 1
	beq v1, OBJ_BOULDER, _solid
		li v0, 0
	_solid:
leave

# -------------------------------------------------------------------------------------------------

# a0 = object index
# returns a boolean (1/0) of whether the object is visible (within the tilemap viewport).
# empty objects are also considered invisible.
obj_is_visible:
enter
	li v0, 0

	# empty?
	lw  t0, object_type(a0)
	beq t0, OBJ_EMPTY, _return

	# t0 = (int)object_x
	# t1 = (int)object_y
	lw  t0, object_x(a0)
	sra t0, t0, 8
	lw  t1, object_y(a0)
	sra t1, t1, 8

	# t2 = tilemap_scx
	# t3 = tilemap_scy
	lw  t2, tilemap_scx
	lw  t3, tilemap_scy

	sub t4, t2, 5
	blt t0, t4, _return # object x < tilemap x - 5?
	sub t4, t3, 5
	blt t1, t4, _return # object y < tilemap y - 5?

	add t2, t2, TILEMAP_VIEWPORT_W
	add t2, t2, 5
	add t3, t3, TILEMAP_VIEWPORT_H
	add t3, t3, 5

	bge t0, t2, _return # object x >= tilemap x + screen w + 5?
	bge t1, t3, _return # object y >= tilemap y + screen h + 5?

	# ok, it's visible!
	li v0, 1

_return:
leave

# -------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = other object index
# returns boolean (1/0) of whether these two objects are overlapping.
# if a0 == a1, returns 0.
obj_collides_with_obj:
enter
	li v0, 0

	# don't check object against itself.
	beq a0, a1, _return

	# if abs(object_x[a0] - object_x[a1]) >= OBJ_SIZE, return
	lw t0, object_x(a0)
	lw t1, object_x(a1)
	sub t0, t0, t1
	abs t0, t0
	bge t0, OBJ_SIZE, _return

	# if abs(object_y[a0] - object_y[a1]) >= OBJ_SIZE, return
	lw t0, object_y(a0)
	lw t1, object_y(a1)
	sub t0, t0, t1
	abs t0, t0
	bge t0, OBJ_SIZE, _return

	# passed both checks, colliding
	li v0, 1
_return:
leave

# -------------------------------------------------------------------------------------------------

# a0 = object index
# returns boolean (1/0) of whether this object is overlapping with the player object.
# if a0 == 0, returns 0.
obj_collides_with_player:
enter
	li a1, 0
	jal obj_collides_with_obj
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = direction to check
# checks if there is an obstruction (solid tile or object) one tile away from the given object
# in the given direction.
# returns COLLISION_NONE if there are no obstructions.
# returns COLLISION_TILE if there is a solid tile, in which case v1 = the tile type.
# returns COLLISION_OBJ if there is a solid object, in which case v1 = the object index.
obj_collision_check:
enter s0
	move a2, a1
	li   a1, TILE_SIZE
	jal  obj_get_pixel_coords_in_dir
	move a0, v0
	move a1, v1
	jal  collision_check

	# if it's none or a solid tile, we're done
	bne v0, COLLISION_OBJ, _return

	# have to check if object is solid
	move s0, v1
	move a0, v1
	jal  obj_is_solid
	beq  v0, 0, _return_none

	# it is solid, so set up the return values and return
	li   v0, COLLISION_OBJ
	move v1, s0
	j    _return

_return_none:
	li v0, COLLISION_NONE
_return:
leave s0

# -------------------------------------------------------------------------------------------------

# a0 = object index
# returns tile coordinates of object's center in (v0, v1).
obj_get_tile_coords:
enter
	lw  v0, object_x(a0)
	sra v0, v0, 8
	div v0, v0, 5

	lw  v1, object_y(a0)
	sra v1, v1, 8
	div v1, v1, 5
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = cardinal direction you want to test
# returns tile coordinates of the tile one tile away from the object in the given direction.
# (v0, v1) = (x, y)
obj_get_tile_coords_in_dir:
enter s0
	move s0, a1

	jal obj_get_tile_coords

	lb  t0, direction_delta_x(s0)
	add v0, v0, t0

	lb  t0, direction_delta_y(s0)
	add v1, v1, t0
leave s0

# ------------------------------------------------------------------------------------------------

# a0 = object index
# same as obj_get_tile_coords_in_dir, but uses the object's direction property as the direction.
# (v0, v1) = (x, y)
obj_get_tile_coords_in_front:
	lw a1, object_dir(a0)
	j  obj_get_tile_coords_in_dir

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = distance to project point, measured from center of object, in 24.8 format
# a2 = cardinal direction you want to test
# returns coordinates projected from object in given direction
# (v0, v1) = (x, y)
obj_get_pixel_coords_in_dir:
enter
	lw  v0, object_x(a0)
	lb  t0, direction_delta_x(a2)
	mul t0, t0, a1
	add v0, v0, t0

	lw  v1, object_y(a0)
	lb  t0, direction_delta_y(a2)
	mul t0, t0, a1
	add v1, v1, t0
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = distance to project point, measured from center of object, in 24.8 format
# same as obj_get_pixel_coords_in_dir, but uses the object's direction property as the direction.
# (v0, v1) = (x, y)
obj_get_pixel_coords_in_front:
	lw a2, object_dir(a0)
	j  obj_get_pixel_coords_in_dir

# -------------------------------------------------------------------------------------------------

# a0 = object index
# returns pixel coordinates of object's top-left corner in (v0, v1).
obj_get_topleft_pixel_coords:
enter
	lw  v0, object_x(a0)
	sub v0, v0, OBJ_HALF_SIZE
	sra v0, v0, 8

	lw  v1, object_y(a0)
	sub v1, v1, OBJ_HALF_SIZE
	sra v1, v1, 8
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = x velocity
# a2 = y velocity
# a3 = movement duration
# sets velocity and duration, and then calls obj_move to start it moving on this frame.
obj_start_moving:
enter
	sw a1, object_vx(a0)
	sw a2, object_vy(a0)
	sw a3, object_moving(a0)

	jal obj_move
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = velocity
# a2 = movement duration
# same as obj_start_moving, but moves in whatever direction the object is currently facing.
obj_start_moving_forward:
	move a3, a2
	lw   t0, object_dir(a0)
	lb   t1, direction_delta_y(t0)
	mul  a2, a1, t1
	lb   t1, direction_delta_x(t0)
	mul  a1, a1, t1
	j obj_start_moving

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = velocity
# a2 = movement duration
# same as obj_start_moving, but moves backwards from the direction the object is currently facing.
obj_start_moving_backward:
	move a3, a2
	lw   t0, object_dir(a0)
	lb   t1, direction_delta_y(t0)
	neg  t1, t1
	mul  a2, a1, t1
	lb   t1, direction_delta_x(t0)
	neg  t1, t1
	mul  a1, a1, t1
	j obj_start_moving

# ------------------------------------------------------------------------------------------------

# a0 = object index
# integrates object's velocity into its position.
obj_move:
enter
	lw  t0, object_x(a0)
	lw  t1, object_vx(a0)
	add t0, t0, t1
	sw  t0, object_x(a0)

	lw  t0, object_y(a0)
	lw  t1, object_vy(a0)
	add t0, t0, t1
	sw  t0, object_y(a0)
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# a1 = direction to be pushed
# starts object moving in the given direction, but using the player's movement velocity/duration.
# objects can only be pushed east/west, so this function will do wrong things if you mistakenly
# give it north/south as the direction.
obj_push:
enter
	lb  a1, direction_delta_x(a1)
	mul a1, a1, PLAYER_MOVE_VELOCITY
	li  a2, 0
	li  a3, PLAYER_MOVE_DURATION
	sub a3, a3, 1 # ??? not sure why this is needed but whatever lol
	jal obj_start_moving
leave

# ------------------------------------------------------------------------------------------------

# a0 = object index
# checks if the object should fall (if there is nothing below it),
# or moves the object if it is currently falling.
obj_move_or_check_for_falling:
enter s0
	move s0, a0

	lw t0, object_moving(s0)
	beq t0, 0, _else
		# object is moving, move it
		move a0, s0
		jal obj_move
	j _endif
	_else:
		# check if the location below object is empty
		move a0, s0
		li   a1, TILE_SIZE
		li   a2, DIR_S
		jal  obj_get_pixel_coords_in_dir
		move a0, v0
		move a1, v1
		jal  collision_check

		bne v0, COLLISION_NONE, _endif
			move a0, s0
			li   a1, 0
			li   a2, OBJECT_MOVE_VELOCITY
			li   a3, OBJECT_MOVE_DURATION
			jal  obj_start_moving
	_endif:
leave s0

# -------------------------------------------------------------------------------------------------

# (a0, a1) = (x, y) in pixel coords
# find the first active object in the array of objects which contains the given point (treating
# the object as a 5x5 rectangle surrounding the point), excluding slot 0 (the player object).
# returns the object index if found. returns -1 if none found.
obj_find_at_position:
enter
	li v0, 4 # skip player object
	_loop:
		lw  t0, object_type(v0)
		beq t0, OBJ_EMPTY, _skip

			# if abs(object_x[v0] - a0) >= OBJ_HALF_SIZE, outside
			lw t0, object_x(v0)
			sub t0, t0, a0
			abs t0, t0
			bge t0, OBJ_HALF_SIZE, _skip

			# if abs(object_y[v0] - a1) >= OBJ_HALF_SIZE, outside
			lw t0, object_y(v0)
			sub t0, t0, a1
			abs t0, t0
			bge t0, OBJ_HALF_SIZE, _skip

			# found it!
			j _return
		_skip:
	add v0, v0, 4
	blt v0, NUM_OBJECTS_X4, _loop

	# none found
	li v0, -1

_return:
leave

# -------------------------------------------------------------------------------------------------

.data
# array of pointers to object update methods, indexed by type.
obj_update_methods: .word
	0                    # OBJ_EMPTY
	obj_update_player    # OBJ_PLAYER
	obj_update_boulder   # OBJ_BOULDER
	obj_update_diamond   # OBJ_DIAMOND
	obj_update_bug       # OBJ_BUG
.text

# update all visible objects by calling their update method, and then updating their
# moving timer.
obj_update_all:
enter s0
	# updating in reverse order to avoid double-updates when player interacts with object
	li s0, NUM_OBJECTS_X4
	sub s0, s0, 4
	_loop:
		move a0, s0
		jal  obj_is_visible
		beq  v0, 0, _invisible
			lw   t0, object_type(s0)
			mul  t0, t0, 4
			lw   t0, obj_update_methods(t0)
			teqi t0, 0 # update method is null! aaaahh!
			move a0, s0
			jalr t0

			# also update the object_moving timer, to keep it in sync with update method
			lw   t0, object_moving(s0)
			dec  t0
			maxi t0, t0, 0
			sw   t0, object_moving(s0)
		_invisible:
	sub s0, s0, 4
	bge s0, 0, _loop
leave s0

# -------------------------------------------------------------------------------------------------

.data
# array of pointers to object drawing methods, indexed by type.
obj_draw_methods: .word
	0                  # OBJ_EMPTY
	obj_draw_player    # OBJ_PLAYER
	obj_draw_boulder   # OBJ_BOULDER
	obj_draw_diamond   # OBJ_DIAMOND
	obj_draw_bug       # OBJ_BUG
.text

# draw all visible objects.
obj_draw_all:
enter s0
	# draw in reverse order so player ends up on top of everything else
	li s0, NUM_OBJECTS_X4
	sub s0, s0, 4
	_loop:
		move a0, s0
		jal  obj_is_visible
		beq  v0, 0, _invisible
			lw   t0, object_type(s0)
			mul  t0, t0, 4
			lw   t0, obj_draw_methods(t0)
			teqi t0, 0 # drawing method is null! aaaahh!
			move a0, s0
			jalr t0
		_invisible:
	sub s0, s0, 4
	bge s0, 0, _loop
leave s0
