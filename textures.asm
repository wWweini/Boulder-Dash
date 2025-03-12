
.data

# Array of pointers to the textures for each tile, ordered by tile type.
tile_textures: .word
	tex_empty   # TILE_EMPTY
	tex_dirt    # TILE_DIRT
	tex_brick   # TILE_BRICK
	tex_goal    # TILE_GOAL
	tex_vines   # TILE_VINES

tex_empty: .byte
     0  0  0  0  0
     0  0  0  0  0
     0  0  0  0  0
     0  0  0  0  0
     0  0  0  0  0

tex_dirt: .byte
	11 11 11 11 11
	11  9 11 11 11
	11 11 11  9 11
	11 11 11 11 11
	11 11 11 11 11

tex_brick: .byte
	 2 10  2  2  2
	10 10 10 10 10
	 2  2  2 10  2
	 2  2  2 10  2
	10 10 10 10 10

tex_goal: .byte
	 0  7  0  7  0
	 7  0  7  0  7
	 0  7  0  7  0
	 7  0  7  0  7
	 0  7  0  7  0

tex_vines: .byte
     0  0 11  4  0
     0  0 11  0  0
     4 11  0  0  0
     0  0 11  4  0
     0  0 11  0  0

# -------------------------------------------------------------------------------------------------

# Array of pointers to player textures, ordered by direction (NESW).
player_textures: .word
	tex_player_N
	tex_player_E
	tex_player_S
	tex_player_W

tex_player_N: .byte
	-1 13 13 13 -1
	13 13 13 13 13
	 3 13 13 13  3
	 3  3 13  3  3
	-1  3  3  3 -1

tex_player_E: .byte
	-1 13 13 13 -1
	13 13 13  3  3
	13 13  3  8  3
	 3  3  3  3  3
	-1  3  3  3 -1

tex_player_S: .byte
	-1 13 13 13 -1
	 3  3  3  3  3
	 3  8  3  8  3
	 3  3  3  3  3
	-1  3  3  3 -1

tex_player_W: .byte
	-1 13 13 13 -1
	 3  3 13 13 13
	 3  8  3 13 13
	 3  3  3  3  3
	-1  3  3  3 -1

# -------------------------------------------------------------------------------------------------

# Boulder texture
tex_boulder: .byte
	-1 10 10 10 -1
	10 11 10 10  9
	10 10 10 10  9
	10 10 10  9  9
	-1  9  9  9 -1

# -------------------------------------------------------------------------------------------------

# Diamond texture
tex_diamond: .byte
	-1 -1  7 -1 -1
	-1  7  5  5 -1
	 7  5  5  5 13
	-1  5  5 13 -1
	-1 -1 13 -1 -1

# -------------------------------------------------------------------------------------------------

# Array of pointers to bug textures, ordered by direction (NESW).
bug_textures: .word
	tex_bug_N
	tex_bug_E
	tex_bug_S
	tex_bug_W

tex_bug_N: .byte
	-1  7 10  7 -1
	-1  1  1  1 -1
	 1  0  1  1  1
	 1  1  1  0  1
	-1  1  1  1 -1

tex_bug_E: .byte
	-1  1  1 -1 -1
	 1  0  1  1  7
	 1  1  1  1 10
	 1  1  0  1  7
	-1  1  1 -1 -1

tex_bug_S: .byte
	-1  1  1  1 -1
	 1  1  1  0  1
	 1  0  1  1  1
	-1  1  1  1 -1
	-1  7 10  7 -1

tex_bug_W: .byte
	-1 -1  1  1 -1
	 7  1  1  0  1
	10  1  1  1  1
	 7  1  0  1  1
	-1 -1  1  1 -1