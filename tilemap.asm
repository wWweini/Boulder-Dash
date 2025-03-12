
# ------------------------------------------------------------------------------------------------
# Software-rendered tilemap
#
# This implements a TILEMAP_TILE_W-by-TILEMAP_TILE_H tilemap of 5x5 tiles. A rectangle of this
# tilemap can be drawn to the screen. Up to TILEMAP_UPDATE_MAX tiles can be changed each frame
# as well.
#
# How to use:
# 1. At startup, call tilemap_set_textures().
# 2. To fill the tilemap efficiently:
#    - call tilemap_set_tile_no_update() repeatedly to fill the tilemap with tiles
#    - after that, call tilemap_update_all() (very slow function!) to update the tilemap bitmap
# 3. During the game:
#    - tilemap_get_tile() gets the tile at a position
#    - tilemap_set_scroll() moves the viewport around
#    - tilemap_set_tile() can be called up to TILEMAP_UPDATE_MAX times per frame to set tiles
#    - tilemap_draw() runs any pending tile updates and draws the tilemap to the screen
# ------------------------------------------------------------------------------------------------

# Width, height, and size of the tilemap in tiles. If these dimensions exceed 256x256,
# the update variables/code will have to be modified (as they use byte arrays).
.eqv TILEMAP_TILE_W 40
.eqv TILEMAP_TILE_H 30
.eqv TILEMAP_TILE_SIZE 1200 #= TILEMAP_TILE_W * TILEMAP_TILE_H

# Width, height, and size of the tilemap in pixels.
.eqv TILEMAP_PIXEL_W 200 #= TILEMAP_TILE_W * 5
.eqv TILEMAP_PIXEL_H 150 #= TILEMAP_TILE_H * 5
.eqv TILEMAP_PIXEL_SIZE 30000 #= TILEMAP_PIXEL_W * TILEMAP_PIXEL_H

# Screen position/size of the viewport into the tilemap that is actually drawn.
# Due to the way tilemap_draw is implemented, the X and W must be multiples of 4.
.eqv TILEMAP_VIEWPORT_X 0
.eqv TILEMAP_VIEWPORT_Y 8
.eqv TILEMAP_VIEWPORT_W 64
.eqv TILEMAP_VIEWPORT_H 56

# Min/max values for scroll.
.eqv TILEMAP_SCX_MIN 0
.eqv TILEMAP_SCX_MAX 136 #= TILEMAP_PIXEL_W - TILEMAP_VIEWPORT_W
.eqv TILEMAP_SCY_MIN 0
.eqv TILEMAP_SCY_MAX 94 #= TILEMAP_PIXEL_H - TILEMAP_VIEWPORT_H

# Maximum number of tile updates per frame. Exceeding this crashes the program.
.eqv TILEMAP_UPDATE_MAX 32

.data
	# Scroll amounts - positive values scroll the view right/down. think of these as the coords
	# of the top-left pixel of the drawn viewport. Valid ranges given by TILEMAP_SCx constants.
	tilemap_scx: .word 0
	tilemap_scy: .word 0

	# Not an array - a POINTER to an array of textures, to be set with tilemap_set_textures.
	tilemap_textures: .word 0

	# How many tiles there are to update this frame.
	tilemap_num_updates: .word 0

	# Arrays holding data for tile updates.
	tilemap_update_x:    .byte 0:TILEMAP_UPDATE_MAX
	tilemap_update_y:    .byte 0:TILEMAP_UPDATE_MAX
	tilemap_update_type: .byte 0:TILEMAP_UPDATE_MAX

	# The actual arrays for the tiles and pixels (the offscreen buffer).
	tilemap_tiles: .byte 0:TILEMAP_TILE_SIZE
	tilemap_pixels: .byte 0:TILEMAP_PIXEL_SIZE
.text

# ------------------------------------------------------------------------------------------------
# Macros

.macro TILEMAP_CHECK_COORDS %x, %y
	tlti %x, 0              # your x coordinate is negative!
	tgei %x, TILEMAP_TILE_W # your x coordinate is too large!
	tlti %y, 0              # your y coordinate is negative!
	tgei %y, TILEMAP_TILE_H # your y coordinate is too large!
.end_macro

# ------------------------------------------------------------------------------------------------

# tilemap_set_textures(texture_array)
# takes a pointer to an array of texture pointers. sheesh!
# if this is not called, drawing the tilemap will crash.
tilemap_set_textures:
enter
	sw a0, tilemap_textures
leave

# ------------------------------------------------------------------------------------------------

# tilemap_set_scroll(x, y)
# sets the tilemap scrolling to the given coords, clamped to the valid range.
tilemap_set_scroll:
enter
	maxi a0, a0, TILEMAP_SCX_MIN
	mini a0, a0, TILEMAP_SCX_MAX
	maxi a1, a1, TILEMAP_SCY_MIN
	mini a1, a1, TILEMAP_SCY_MAX
	sw a0, tilemap_scx
	sw a1, tilemap_scy
leave

# ------------------------------------------------------------------------------------------------

# int tilemap_get_tile(x, y)
# returns the tile number at the given coords. traps on invalid coords.
tilemap_get_tile:
enter
	TILEMAP_CHECK_COORDS a0, a1

	# return tilemap_tiles[y * TILEMAP_TILE_W + x]
	mul t0, a1, TILEMAP_TILE_W
	add t0, t0, a0
	lbu v0, tilemap_tiles(t0)
leave

# ------------------------------------------------------------------------------------------------

# tilemap_set_tile_no_update(x, y, tile)
# sets the tile in tilemap_tiles, but does not update the offscreen buffer. it's up to you to
# call tilemap_update_all after filling in the tilemap data.
# traps on invalid coords.
tilemap_set_tile_no_update:
enter
	TILEMAP_CHECK_COORDS a0, a1

	# tilemap_tiles[y * TILEMAP_TILE_W + x] = tile
	mul t0, a1, TILEMAP_TILE_W
	add t0, t0, a0
	sb  a2, tilemap_tiles(t0)
leave

# ------------------------------------------------------------------------------------------------

# tilemap_set_tile(x, y, tile)
# queues an update for the given tile which will be drawn the next time the tilemap is drawn.
# only TILEMAP_UPDATE_MAX updates can be queued each frame. If you exceed this limit, an error
# is printed and the program crashes!
# this immediately updates the internal tile number, though, so logic that depends on
# tilemap_get_tile will see the change right after this call.
# traps on invalid coords.
tilemap_set_tile:
enter
	TILEMAP_CHECK_COORDS a0, a1

	lw t0, tilemap_num_updates
	blt t0, TILEMAP_UPDATE_MAX, _okay
		println_str "Error: exceeded maximum number of tile updates in one frame!"
		syscall_exit
	_okay:

	sb a0, tilemap_update_x(t0)
	sb a1, tilemap_update_y(t0)
	sb a2, tilemap_update_type(t0)
	inc t0
	sw t0, tilemap_num_updates

	# tilemap_tiles[y * TILEMAP_TILE_W + x] = tile
	mul t0, a1, TILEMAP_TILE_W
	add t0, t0, a0
	sb  a2, tilemap_tiles(t0)
leave

# ------------------------------------------------------------------------------------------------

# tilemap_draw()
# if any updates are pending, updates the offscreen buffer; then draws the tilemap to the display.
tilemap_draw:
enter s0, s1
	# update offscreen buffer if needed
	lw t0, tilemap_num_updates
	beq t0, 0, _no_updates
		jal tilemap_run_updates_DO_NOT_CALL
	_no_updates:

	# blit the window to the display. Essentially, copy a rectangle from tilemap_pixels starting
	# at (tilemap_scx, tilemap_scx) to (TILEMAP_VIEWPORT_X, TILEMAP_VIEWPORT_Y), with dimensions
	# (TILEMAP_VIEWPORT_W, TILEMAP_VIEWPORT_H).

	# t6 is src (tilemap_pixels + tilemap_scx + tilemap_scy * TILEMAP_PIXEL_W)
	la  t6, tilemap_pixels
	lw  t0, tilemap_scx
	add t6, t6, t0
	lw  t0, tilemap_scy
	mul t0, t0, TILEMAP_PIXEL_W
	add t6, t6, t0

	# t7 is dst (DISPLAY_BASE + TILEMAP_VIEWPORT_X + TILEMAP_VIEWPORT_Y * DISPLAY_W)
	li  t7, DISPLAY_BASE
	add t7, t7, TILEMAP_VIEWPORT_X
	li  t0, TILEMAP_VIEWPORT_Y
	mul t0, t0, DISPLAY_W
	add t7, t7, t0

	and  t0, t7, 3
	tnei t0, 0 # if this trap happens, TILEMAP_VIEWPORT_X is not a multiple of 4!
	li   t0, TILEMAP_VIEWPORT_W
	and  t0, t0, 3
	tnei t0, 0 # if this trap happens, TILEMAP_VIEWPORT_W is not a multiple of 4!

	# t8 is tilemap inter-row stride (TILEMAP_PIXEL_W - TILEMAP_VIEWPORT_W)
	li  t8, TILEMAP_PIXEL_W
	sub t8, t8, TILEMAP_VIEWPORT_W

	# t9 is display inter-row stride (DISPLAY_W - TILEMAP_VIEWPORT_W)
	li  t9, DISPLAY_W
	sub t9, t9, TILEMAP_VIEWPORT_W

	# src ptr alignment will changed based on x scroll. since we want to use lw/sw instead
	# of lb/sb (huge performance improvement), we have to be clever and move bits around
	# when the x scroll is not a multiple of 4.
	and t0, t6, 3
	beq t0, 0, _zero
	beq t0, 1, _one
	beq t0, 2, _two
	j _three

	_zero:
		# s0 = col, s1 = row
		li s1, 0
		_rowLoop0:
			li s0, 0
			_colLoop0:
				lw t0, (t6)
				sw t0, (t7)
				add t6, t6, 4
				add t7, t7, 4
			add s0, s0, 4
			blt s0, TILEMAP_VIEWPORT_W, _colLoop0

			# src += tilemap stride
			add t6, t6, t8

			# dst += display stride
			add t7, t7, t9
		inc s1
		blt s1, TILEMAP_VIEWPORT_H, _rowLoop0
	j _return

	_one:
		# s0 = col, s1 = row
		li s1, 0
		_rowLoop1:
			li s0, 0

			# queue up first three bytes to draw
			lw t0, -1(t6)
			srl t0, t0, 8
			add t6, t6, 3

			_colLoop1:
				# get next 4 bytes, extract lowest and put into high bits of t0
				lw  t1, (t6)
				sll t2, t1, 24
				or  t0, t0, t2
				sw  t0, (t7)

				# then move things along
				srl t0, t1, 8

				add t6, t6, 4
				add t7, t7, 4
			add s0, s0, 4
			blt s0, TILEMAP_VIEWPORT_W, _colLoop1

			# src += tilemap stride - 3
			add t6, t6, t8
			sub t6, t6, 3

			# dst += display stride
			add t7, t7, t9
		inc s1
		blt s1, TILEMAP_VIEWPORT_H, _rowLoop1
	j _return

	_two:
	# s0 = col, s1 = row
		li s1, 0
		_rowLoop2:
			li s0, 0

			# queue up first two bytes to draw
			lw t0, -2(t6)
			srl t0, t0, 16
			add t6, t6, 2

			_colLoop2:
				# get next 4 bytes, extract lowest two and put into high bits of t0
				lw  t1, (t6)
				sll t2, t1, 16
				or  t0, t0, t2
				sw  t0, (t7)

				# then move things along
				srl t0, t1, 16

				add t6, t6, 4
				add t7, t7, 4
			add s0, s0, 4
			blt s0, TILEMAP_VIEWPORT_W, _colLoop2

			# src += tilemap stride - 2
			add t6, t6, t8
			sub t6, t6, 2

			# dst += display stride
			add t7, t7, t9
		inc s1
		blt s1, TILEMAP_VIEWPORT_H, _rowLoop2
	j _return

	_three:
		# s0 = col, s1 = row
		li s1, 0
		_rowLoop3:
			li s0, 0

			# queue up first byte to draw
			lw t0, -3(t6)
			srl t0, t0, 24
			add t6, t6, 1

			_colLoop3:
				# get next 4 bytes, extract lowest and put into high bits of t0
				lw  t1, (t6)
				sll t2, t1, 8
				or  t0, t0, t2
				sw  t0, (t7)

				# then move things along
				srl t0, t1, 24

				add t6, t6, 4
				add t7, t7, 4
			add s0, s0, 4
			blt s0, TILEMAP_VIEWPORT_W, _colLoop3

			# src += tilemap stride - 1
			add t6, t6, t8
			sub t6, t6, 1

			# dst += display stride
			add t7, t7, t9
		inc s1
		blt s1, TILEMAP_VIEWPORT_H, _rowLoop3
_return:
leave s0, s1

# ------------------------------------------------------------------------------------------------

# draws the entire tilemap to the offscreen buffer. this is used after calling
# tilemap_set_tile_no_update many times to fill it with initial data. this is an incredibly
# slow function! do not call it frequently!
tilemap_update_all:
enter s0, s1, s2
	lw s2, tilemap_textures
	teqi s2, 0 # you didn't set the texture pointer!

	# draw it...
	li s1, 0
	_rowLoop:
		li s0, 0
		_colLoop:
			# t0 = tilemap_tiles[row * TILEMAP_TILE_W + col]
			mul t0, s1, TILEMAP_TILE_W
			add t0, t0, s0
			lbu t0, tilemap_tiles(t0)

			# a2 = tilemap_textures[t0 * 4]
			mul t0, t0, 4
			add t0, t0, s2
			lw  a2, (t0)

			# a0 = col * 5
			mul a0, s0, 5

			# a1 = row * 5
			mul a1, s1, 5

			# and blit!
			jal tilemap_blit_tile_DO_NOT_CALL
		inc s0
		blt s0, TILEMAP_TILE_W, _colLoop
	inc s1
	blt s1, TILEMAP_TILE_H, _rowLoop
leave s0, s1, s2

# ------------------------------------------------------------------------------------------------

# tilemap_run_updates_DO_NOT_CALL()
# runs and clears pending tile updates.
# this is an internal function. do not call this yourself!
tilemap_run_updates_DO_NOT_CALL:
enter s0, s1, s2
	lw s2, tilemap_textures
	teqi s2, 0 # you didn't set the texture pointer!

	# for each update...
	lw s1, tilemap_num_updates
	li s0, 0
	_loop:
		# run it
		lbu a0, tilemap_update_x(s0)
		mul a0, a0, 5
		lbu a1, tilemap_update_y(s0)
		mul a1, a1, 5

		# a2 = tilemap_textures[tilemap_update_type[s0] * 4]
		lbu t0, tilemap_update_type(s0)
		mul t0, t0, 4
		add t0, t0, s2
		lw  a2, (t0)

		# and blit!
		jal tilemap_blit_tile_DO_NOT_CALL
	inc s0
	blt s0, s1, _loop

	# and clear them out
	sw zero, tilemap_num_updates
leave s0, s1, s2

# ------------------------------------------------------------------------------------------------

# tilemap_blit_tile_DO_NOT_CALL(x, y, texture)
# blits the 5x5 texture in a2 into the offscreen tilemap pixel buffer at coords (a0, a1).
# this is an internal function. do not call this yourself!
tilemap_blit_tile_DO_NOT_CALL:
enter
	# a1 = destination pointer = tilemap_pixels + y * TILEMAP_PIXEL_W + x
	mul a1, a1, TILEMAP_PIXEL_W
	la  t0, tilemap_pixels
	add a1, a1, t0
	add a1, a1, a0

.macro BLIT_PIXEL %off1, %off2
	lb t0, %off1(a2)
	sb t0, %off2(a1)
.end_macro

	BLIT_PIXEL 0, 0
	BLIT_PIXEL 1, 1
	BLIT_PIXEL 2, 2
	BLIT_PIXEL 3, 3
	BLIT_PIXEL 4, 4
	add a1, a1, TILEMAP_PIXEL_W
	BLIT_PIXEL 5, 0
	BLIT_PIXEL 6, 1
	BLIT_PIXEL 7, 2
	BLIT_PIXEL 8, 3
	BLIT_PIXEL 9, 4
	add a1, a1, TILEMAP_PIXEL_W
	BLIT_PIXEL 10, 0
	BLIT_PIXEL 11, 1
	BLIT_PIXEL 12, 2
	BLIT_PIXEL 13, 3
	BLIT_PIXEL 14, 4
	add a1, a1, TILEMAP_PIXEL_W
	BLIT_PIXEL 15, 0
	BLIT_PIXEL 16, 1
	BLIT_PIXEL 17, 2
	BLIT_PIXEL 18, 3
	BLIT_PIXEL 19, 4
	add a1, a1, TILEMAP_PIXEL_W
	BLIT_PIXEL 20, 0
	BLIT_PIXEL 21, 1
	BLIT_PIXEL 22, 2
	BLIT_PIXEL 23, 3
	BLIT_PIXEL 24, 4
leave
