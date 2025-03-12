
.data

# Array that maps characters to tile types. Index 0 is ASCII 32 (space).
# The 0 entries are TILE_EMPTY but I wrote them as 0 to make it easy to visually tell
# which characters map to non-empty tiles.
char_to_tile: .byte
	TILE_EMPTY   # ' '
	0            # '!'
	0            # '"'
	TILE_BRICK   # '#'
	0            # '$'
	TILE_GOAL    # '%'
	0            # '&'
	0            # '''
	0            # '('
	0            # ')'
	0            # '*'
	0            # '+'
	0            # ','
	0            # '-'
	TILE_DIRT    # '.'
	0            # '/'
	0            # '0'
	0            # '1'
	0            # '2'
	0            # '3'
	0            # '4'
	0            # '5'
	0            # '6'
	0            # '7'
	0            # '8'
	0            # '9'
	0            # ':'
	0            # ';'
	0            # '<'
	0            # '='
	0            # '>'
	0            # '?'
	0            # '@'
	0            # 'A'
	0            # 'B'
	0            # 'C'
	0            # 'D'
	0            # 'E'
	0            # 'F'
	0            # 'G'
	0            # 'H'
	0            # 'I'
	0            # 'J'
	0            # 'K'
	0            # 'L'
	0            # 'M'
	0            # 'N'
	0            # 'O'
	0            # 'P'
	0            # 'Q'
	0            # 'R'
	0            # 'S'
	0            # 'T'
	0            # 'U'
	0            # 'V'
	0            # 'W'
	0            # 'X'
	0            # 'Y'
	0            # 'Z'
	0            # '['
	0            # '\'
	0            # ']'
	0            # '^' (places a diamond object)
	0            # '_'
	0            # '`'
	0            # 'a'
	0            # 'b' (places a bug object)
	0            # 'c'
	0            # 'd'
	0            # 'e'
	0            # 'f'
	0            # 'g'
	0            # 'h'
	0            # 'i'
	0            # 'j'
	0            # 'k'
	0            # 'l'
	0            # 'm'
	0            # 'n'
	0            # 'o' (places a boulder object)
	0            # 'p'
	0            # 'q'
	0            # 'r'
	0            # 's'
	0            # 't'
	0            # 'u'
	0            # 'v'
	0            # 'w'
	0            # 'x'
	0            # 'y'
	0            # 'z'
	0            # '{'
	0            # '|'
	0            # '}'
	TILE_VINES   # '~'

# Array that maps characters to object types. Index 0 is ASCII 32 (space).
# The 0 entries are OBJ_EMPTY but I wrote them as 0 to make it easy to visually tell
# which characters map to non-empty objects.
# One character can map to both a tile and an object (e.g. 'k', which makes a key object
# on top of a grass tile).
char_to_obj: .byte
	0              # ' '
	0              # '!'
	0              # '"'
	0              # '#'
	OBJ_PLAYER     # '$'
	0              # '%'
	0              # '&'
	0              # '''
	0              # '('
	0              # ')'
	0              # '*'
	0              # '+'
	0              # ','
	0              # '-'
	0              # '.'
	0              # '/'
	0              # '0'
	0              # '1'
	0              # '2'
	0              # '3'
	0              # '4'
	0              # '5'
	0              # '6'
	0              # '7'
	0              # '8'
	0              # '9'
	0              # ':'
	0              # ';'
	0              # '<'
	0              # '='
	0              # '>'
	0              # '?'
	0              # '@'
	0              # 'A'
	0              # 'B'
	0              # 'C'
	0              # 'D'
	0              # 'E'
	0              # 'F'
	0              # 'G'
	0              # 'H'
	0              # 'I'
	0              # 'J'
	0              # 'K'
	0              # 'L'
	0              # 'M'
	0              # 'N'
	0              # 'O'
	0              # 'P'
	0              # 'Q'
	0              # 'R'
	0              # 'S'
	0              # 'T'
	0              # 'U'
	0              # 'V'
	0              # 'W'
	0              # 'X'
	0              # 'Y'
	0              # 'Z'
	0              # '['
	0              # '\'
	0              # ']'
	OBJ_DIAMOND    # '^' (on an empty tile)
	0              # '_'
	0              # '`'
	0              # 'a'
	OBJ_BUG        # 'b'
	0              # 'c'
	0              # 'd'
	0              # 'e'
	0              # 'f'
	0              # 'g'
	0              # 'h'
	0              # 'i'
	0              # 'j'
	0              # 'k'
	0              # 'l'
	0              # 'm'
	0              # 'n'
	OBJ_BOULDER    # 'o' (on an empty tile)
	0              # 'p'
	0              # 'q'
	0              # 'r'
	0              # 's'
	0              # 't'
	0              # 'u'
	0              # 'v'
	0              # 'w'
	0              # 'x'
	0              # 'y'
	0              # 'z'
	0              # '{'
	0              # '|'
	0              # '}'
	0              # '~'
.text

# ------------------------------------------------------------------------------------------------

# a0 = pointer to level data
# fills in tilemap by translating the characters in the level data to tile types.
# also allocates objects for characters that correspond to those.
load_map:
enter s0, s1, s2, s3
	move s2, a0 # s2 = level data

	# set the textures array
	la  a0, tile_textures
	jal tilemap_set_textures

	# force object 0 to be the player object, facing down
	li t0, OBJ_PLAYER
	sw t0, object_type
	li t0, DIR_S
	sw t0, player_dir

	li s1, 0 # s1 = row
	_row_loop:
		li s0, 0 # s0 = column
		_col_loop:
			# t2 = index = row * TILEMAP_TILE_W + col
			mul t2, s1, TILEMAP_TILE_W
			add t2, t2, s0

			# s3 = level_data[t2] - ' '
			add s3, s2, t2
			lb  s3, (s3)    # s3 = character from level_data
			sub s3, s3, ' ' # s3 = the index into char_to_tile

			# tilemap_set_tile_no_update(s0, s1, char_to_tile[s3])
			move a0, s0
			move a1, s1
			lb   a2, char_to_tile(s3)
			jal  tilemap_set_tile_no_update

			# now see if we need to spawn an object
			lb  t0, char_to_obj(s3)
			beq t0, 0, _break

				# compute spawn pixel coordinates as arguments
				mul a0, s0, 5
				sll a0, a0, 8
				add a0, a0, OBJ_HALF_SIZE

				mul a1, s1, 5
				sll a1, a1, 8
				add a1, a1, OBJ_HALF_SIZE

				# which object it?
				beq t0, OBJ_PLAYER, _player
				beq t0, OBJ_BOULDER, _boulder
				beq t0, OBJ_DIAMOND, _diamond
				beq t0, OBJ_BUG, _bug
				j _default

				_player:
					# don't have to call a function to create player object
					sw a0, player_x
					sw a1, player_y
					j _break

				_boulder:
					# computed coordinates are passed as arguments
					jal obj_new_boulder
					j _break

				_diamond:
					# computed coordinates are passed as arguments
					jal obj_new_diamond
					j _break

				_bug:
					# computed coordinates are passed as arguments
					jal obj_new_bug

					# increment bugs_to_save
					lw  t0, bugs_to_save
					inc t0
					sw  t0, bugs_to_save
					j _break

				_default:
					print_str "error loading map: object character "
					add a0, s3, ' '
					syscall_print_char
					println_str " unimplmented."
					syscall_exit
			_break:
		inc s0
		blt s0, TILEMAP_TILE_W, _col_loop
	inc s1
	blt s1, TILEMAP_TILE_H, _row_loop

	# commit the changes.
	jal tilemap_update_all
leave s0, s1, s2, s3
