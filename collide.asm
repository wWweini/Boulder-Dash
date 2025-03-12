
# ------------------------------------------------------------------------------------------------

# (a0, a1) = (x, y) in tile coords.
# returns a boolean (1/0) of whether the tile at those coordinates is solid (like a wall).
# also returns v1 = the tile type that was hit.
is_solid_tile:
enter
	jal tilemap_get_tile
	move v1, v0

	li  v0, 1
	beq v1, TILE_BRICK,  _solid
	beq v1, TILE_DIRT,   _solid
		li v0, 0
	_solid:
leave

# ------------------------------------------------------------------------------------------------

# (a0, a1) = (x, y) in pixel coords.
# asks if there is a tile or object at the given coordinates.
# returns v0 = COLLISION_NONE if there is nothing there (empty tile and no object).
# returns v0 = COLLISION_TILE if there is a solid tile there. in that case v1 = the tile type.
# returns v0 = COLLISION_OBJ if there is an object there. in that case v1 = the object index.
collision_check:
enter s0, s1
	move s0, a0
	move s1, a1

	# pixel coords to tile coords
	sra a0, s0, 8
	div a0, a0, 5
	sra a1, s1, 8
	div a1, a1, 5
	jal is_solid_tile
	beq v0, 0, _endif
		# a tile was found, return COLLISION_TILE
		li v0, COLLISION_TILE
		j _return
	_endif:

	# test for object
	move a0, s0
	move a1, s1
	jal obj_find_at_position

	beq v0, -1, _nothing
		# object found; put index in v1 and return 1
		move v1, v0
		li v0, COLLISION_OBJ
		j _return
	_nothing:

	# nothing here
	li v0, COLLISION_NONE
_return:
leave s0, s1