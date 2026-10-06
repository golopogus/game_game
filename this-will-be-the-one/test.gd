extends Node2D


var panning = false
var stored_mous_pos = Vector2()


#var inventory
#var check_radius = 2

const grid_size_options = [[20,20],[4,4],[8,8]]
var chosen_grid_size = grid_size_options[0]

var num_of_chunks = Vector2(10,10)
var chunk_split
var initial_pos = Vector2(0,0)
var chunk_size = Vector2()
var x_length
var y_length
#var start = false
var chunk_dict = {}
#var gamestart = false
var revealed_tiles = []
var initial_chunk_pos 
var number_of_mines_per_chunk = 65
var moveable = false
var local_mous_pos
var current_neighbors = []
var stored_pos = Vector2()
var current_chunk = Vector2()
#var visible_area
#var safe_tiles = []
#var tiles_in_current_chunk = []
#var in_game_menu = false
var tile_dict = {} 
var tile_load = preload("res://tile.tscn")
var chunk_load = preload("res://chunk.tscn")
var squidge_load = preload("res://squidge.tscn")
var mouse_in = true
#var mine_thread
var texture_dict
#var selected_mark = []
#var round_points = 0
#var score_multiplier = 1
#var active_mines = []
#var checked_clicked = []

		
func _ready() -> void:

	x_length = 16
	y_length = 16

	chunk_size = Vector2(chosen_grid_size[0],chosen_grid_size[1]) * Vector2(x_length,y_length)
	chunk_split = -floor(num_of_chunks/2)
	
	initial_chunk_pos = get_nearest(Vector2(chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0,chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0),'chunk')
	current_chunk = initial_chunk_pos
	
	initialize_textures()
	place_chunk_loc()
	place_tile_loc()
	create_starting_loc()
	
	
	
	$Camera2D.position.x = chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0 - x_length/2.0
	$Camera2D.position.y = chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0 - y_length/2.0
	
	var squidge = squidge_load.instantiate()
	add_child(squidge)
	squidge.position = $Camera2D.position


func _process(_delta: float) -> void:
	
	if moveable and mouse_in:
	
		var difference = local_mous_pos - get_global_mouse_position()
		$Camera2D.position += difference
	
	var nearest_chunk_pos = Vector2()
	
	var chunk_follow_pos = $Camera2D.position

	nearest_chunk_pos = get_nearest(chunk_follow_pos,'chunk')
	
	if nearest_chunk_pos != current_chunk:

		current_chunk = nearest_chunk_pos
		update_chunk_pos(current_chunk)

	
func _unhandled_input(_event: InputEvent) -> void:
	
	var mouse_pos = get_global_mouse_position()
	var nearest_tile_pos = get_nearest(mouse_pos, 'tile')
	var nearest_chunk_pos = get_nearest(nearest_tile_pos,'chunk')
	
	if Input.is_action_just_pressed("left_click"):
		stored_mous_pos = get_global_mouse_position()
		stored_pos = nearest_tile_pos
		
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
			
		
	if Input.is_action_just_released("left_click"):

			revealed_tiles = []
		
			if nearest_tile_pos == stored_pos:
				
				if tile_dict.has(nearest_tile_pos):
					current_chunk = get_nearest(nearest_tile_pos,'chunk')
					
					clicked(nearest_tile_pos,false)
		

	if Input.is_action_pressed("pan"):
		
		
		if moveable == false:
			local_mous_pos = get_global_mouse_position()
			
		moveable = true
		
	if Input.is_action_just_released("pan"):
		moveable = false

		
		
					
#############################################################################
#█ █▄░█ █ ▀█▀ █ ▄▀█ ▀█▀ █ █▄░█ █▀▀   █▀▀ █▀█ █ █▀▄
#█ █░▀█ █ ░█░ █ █▀█ ░█░ █ █░▀█ █▄█   █▄█ █▀▄ █ █▄▀
#############################################################################	

func get_node_from_pos(pos):
	var nearest_chunk_pos = get_nearest(pos, 'chunk')
	var node_path = 'chunks/' +  chunk_dict[nearest_chunk_pos]['name'] + '/' + tile_dict[pos]['name']
	return get_node(node_path)
	
	
func place_chunk_loc():
	
	var start_pos = Vector2()
	var chunk_position = Vector2()
	
	for x in num_of_chunks.x:
		for y in num_of_chunks.y:
			chunk_position = start_pos + Vector2(x,y)*chunk_size
			chunk_dict[chunk_position] = {
				'name':'not_named',
				'drawn': false,
				}
	
func place_tile_loc():
	
	var start_pos = Vector2()  
	var x_tiles = chosen_grid_size[0] * num_of_chunks.x
	var y_tiles = chosen_grid_size[1] * num_of_chunks.y
	var tile_pos = Vector2()

	for x in x_tiles:
		for y in y_tiles:
			tile_pos = start_pos + Vector2(x_length,y_length) * Vector2(x,y)
			if tile_dict.has(tile_pos) == false:
				
				tile_dict[tile_pos] = {
					'name': 'none',
					'clicked': false,
					'clickable': false

				}
					
	draw_initial_chunks(initial_chunk_pos)

						
#############################################################################	
#█▀▀ █░█ █░█ █▄░█ █▄▀ █ █▄░█ █▀▀
#█▄▄ █▀█ █▄█ █░▀█ █░█ █ █░▀█ █▄█	
#############################################################################

func update_chunk_pos(pos):
	
	var pos_to_move = []
	
	current_neighbors = create_neighbors(pos,chunk_size.x,chunk_size.y, 'ALL')
	current_neighbors.append(pos)
	
	var chunks_to_move = move_chunks(current_neighbors)

	
	for i in current_neighbors:
		if chunk_dict.has(i):
			if chunk_dict[i]['drawn'] == false:
				pos_to_move.append(i)
	

	for i in len(pos_to_move):

		if len(pos_to_move) == len(chunks_to_move):
			
			chunks_to_move[i].position = pos_to_move[i]
			chunk_dict[chunks_to_move[i].position]['drawn'] = true
			chunk_dict[chunks_to_move[i].position]['name'] = chunks_to_move[i].name
				
		
	for chunk in chunks_to_move:
		var chunk_children = chunk.get_children()
		for child in chunk_children:
			#change_texture(child)
			call_deferred('change_texture',child)
	
func change_texture(tile):
	
	var pos = tile.global_position
	var sprite
	var tile_pos = tile_dict[pos]

	tile_dict[pos]['name'] = tile.name
	if tile_pos['clicked'] == false:

			tile.texture = texture_dict['hidden']['hidden1']
	else:		
		tile.texture = texture_dict['safe']

func draw_initial_chunks(pos):
	
	current_neighbors = create_neighbors(pos,chunk_size.x,chunk_size.y, 'ALL')
	current_neighbors.append(pos)
	
	for i in current_neighbors:
		
		var chunk = chunk_load.instantiate()

		$chunks.add_child(chunk)
		chunk_dict[i]['name'] = chunk.name
		chunk_dict[i]['drawn'] = true
		chunk.position = i
		
		
		for x in chosen_grid_size[0]:
			for y in chosen_grid_size[1]:
			
				var tile = tile_load.instantiate()
				var global_pos = Vector2(x,y) * Vector2(x_length, y_length) + initial_pos + i
				
				chunk.add_child(tile)
				tile.global_position = global_pos
				tile_dict[tile.global_position]['name'] = tile.name	
				
				
				tile.texture = texture_dict['hidden']['hidden1']
									
func clicked(pos,at_start):
	revealed_tiles.append(pos)
	var nearest_chunk_pos = get_nearest(pos, 'chunk')
	var tile = tile_dict[pos]
	var node_path = 'chunks/' +  chunk_dict[nearest_chunk_pos]['name'] + '/' + tile['name']
	#print(tile_dict[pos])
		
	if tile['clickable'] == true or at_start:
		if tile['clicked'] == false:
			tile['clicked'] = true
			#tile['type'] = 'safe'
			check_clickable(pos)
			
			change_texture(get_node(node_path))
			var neighbors = create_neighbors(pos,x_length,y_length,'CARDINAL')
			for t in neighbors:
				check_clickable(t)
	

func move_chunks(dont_erase):
	
	var delete = true
	var chunks_to_move = []
			
	for chunk in $chunks.get_children():		
		for pos in dont_erase:
			if chunk.position == pos:
				chunk_dict[chunk.position]['drawn'] = true
				delete = false
		if delete == true:
			chunk_dict[chunk.position]['drawn'] = false
			chunks_to_move.append(chunk)
		delete = true

	return chunks_to_move

func check_clickable(tile_pos):

	if tile_dict[tile_pos]['clicked'] == false:
		tile_dict[tile_pos]['clickable'] = true
	else:
		tile_dict[tile_pos]['clickable'] = false
	
func create_starting_loc():
	var starting_pos = Vector2(chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0,chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0)
	var square_size = 3
	var grid = []
	var x = -2
	while x < 1:
		var y = -2
		while y < 1:
			grid.append(Vector2(x,y))
			y += 1
		x += 1
	
	var all_loc = convert_grid_to_pos(grid,starting_pos)
	
	for pos in all_loc:
		clicked(pos,true)
	
#############################################################################	
#█▀▄▀█ █ █▀ █▀▀
#█░▀░█ █ ▄█ █▄▄	
#############################################################################

var neighbor_dict
func create_neighbors(pos,x,y,dir):
	
	
	
	var pre_neighbors
	var n = pos + Vector2(0,-1) * Vector2(x,y)
	var ne = pos + Vector2(1,-1) * Vector2(x,y)
	var nw = pos + Vector2(-1,-1) * Vector2(x,y)
	var s = pos + Vector2(0,1) * Vector2(x,y)
	var se = pos + Vector2(1,1) * Vector2(x,y)
	var sw = pos + Vector2(-1,1) * Vector2(x,y)
	var w = pos + Vector2(-1,0) * Vector2(x,y)
	var e = pos + Vector2(1,0) * Vector2(x,y)
	
	match dir:
	
		'TOP':
			pre_neighbors = [n,ne,nw]
		'BOTTOM':
			pre_neighbors = [sw,s,se]
		'RIGHT':
			pre_neighbors = [ne,e,se]
		'LEFT':
			pre_neighbors = [nw,w,sw]
		'ALL':
			pre_neighbors = [n,ne,e,se,s,sw,w,nw]
		'CARDINAL':
			pre_neighbors = [n,e,s,w]
	
	var neighbors = []

	for i in pre_neighbors:
		var nearest_chunk_pos = get_nearest(i,'chunk')

		if chunk_dict.has(nearest_chunk_pos):
			neighbors.append(i)

				
	return neighbors

func get_chunk_grid():
	
	var chunk_grid = []
	
	for x in chosen_grid_size[0]:
		for y in chosen_grid_size[1]:
			chunk_grid.append(Vector2(x,y))
	
	return chunk_grid
	
func get_nearest(pos, val):
	
	var nearest = Vector2()
	
	match val:
		'chunk':
			nearest = floor(pos / chunk_size) * chunk_size + initial_pos
		'tile':
			nearest = floor(pos / Vector2(x_length,y_length)) * Vector2(x_length,y_length) + initial_pos
	return nearest

func convert_grid_to_pos(grid,pos):
	
	var new_grid = []
	for i in grid:
		var new_pos = (i * Vector2(x_length, y_length)) + initial_pos + pos
		new_grid.append(new_pos)
	return new_grid

func initialize_textures():
		texture_dict = {
		'mark' = {
			'mark1' = $sprites/marked/mark.texture,
		},
		'hidden' = {
			'hidden1' = $sprites/hidden/hidden.texture,

		},
		'1' = $"sprites/revealed/1".texture,
		'2' = $"sprites/revealed/2".texture,
		'3' = $"sprites/revealed/3".texture,
		'4' = $"sprites/revealed/4".texture,
		'5' = $"sprites/revealed/5".texture,
		'6' = $"sprites/revealed/6".texture,
		'7' = $"sprites/revealed/7".texture,
		'8' = $"sprites/revealed/8".texture,
		'safe' = $sprites/revealed/safe.texture,
		'mine' = $sprites/revealed/mine.texture
	}


	


	
	

			
				
			
	
