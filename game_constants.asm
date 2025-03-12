
# Cardinal directions.
.eqv DIR_N 0
.eqv DIR_E 1
.eqv DIR_S 2
.eqv DIR_W 3

# Camera position is player position plus these offsets.
.eqv CAMERA_OFFSET_X -30
.eqv CAMERA_OFFSET_Y -25

# Tile types.
.eqv TILE_EMPTY   0
.eqv TILE_DIRT    1
.eqv TILE_BRICK   2
.eqv TILE_GOAL    3
.eqv TILE_VINES   4

# Maximum number of objects in the game world.
.eqv NUM_OBJECTS 100

# Used in array bounds checks
.eqv NUM_OBJECTS_X4 200 #= NUM_OBJECTS * 4

# The width/height of objects. It's fixed at 5 pixels.
.eqv OBJ_SIZE 0x500

# The size of one tile in pixels (in 24.8 format).
.eqv TILE_SIZE 0x500

# Half the width/height of objects, used in collision and drawing.
.eqv OBJ_HALF_SIZE 0x280 #= OBJ_SIZE / 2

# Object types.
.eqv OBJ_EMPTY     0
.eqv OBJ_PLAYER    1
.eqv OBJ_BOULDER   2
.eqv OBJ_DIAMOND   3
.eqv OBJ_BUG       4

# Player constants.
.eqv PLAYER_MOVE_DELAY    8     # frames
.eqv PLAYER_MOVE_VELOCITY 0x100 # pixels per frame
.eqv PLAYER_MOVE_DURATION 5     # frames
.eqv PLAYER_MAX_DIRT      99    # blocks

# Object constants.
.eqv OBJECT_MOVE_VELOCITY 0x080 # pixels per frame
.eqv OBJECT_MOVE_DURATION 10    # frames

# Bug constants.
.eqv BUG_MOVE_VELOCITY 0x040 # pixels per frame
.eqv BUG_MOVE_DURATION 20    # frames

# Collision constants.
.eqv COLLISION_NONE -1
.eqv COLLISION_TILE  0
.eqv COLLISION_OBJ   1