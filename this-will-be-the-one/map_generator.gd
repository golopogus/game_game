extends Node2D

# used for generating the map initially and any updates throughout

const grid_size_options = [[20,20],[4,4],[8,8]]
var chosen_grid_size = grid_size_options[0]
var num_of_chunks = Vector2(10,10)
var chunk_split
var initial_pos = Vector2(0,0)
var chunk_size = Vector2()
var chunk_dict = {}
var initial_chunk_pos 
var current_neighbors = []
var stored_pos = Vector2()
var current_chunk = Vector2()
var tile_dict = {} 
var tile_load = preload("res://tile.tscn")
var chunk_load = preload("res://chunk.tscn")
var x_length = 16
var y_length = 16

	
func _ready() -> void:

	chunk_size = Vector2(chosen_grid_size[0],chosen_grid_size[1]) * Vector2(x_length,y_length)
	MapController.chunk_size = chunk_size
	chunk_split = -floor(num_of_chunks/2)
	
	initial_chunk_pos = MapController.get_nearest(Vector2(chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0,chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0),'chunk')
	current_chunk = initial_chunk_pos
	
	initialize_textures()
	place_chunk_loc()
	place_tile_loc()
	
	create_starting_loc()

	#MapController.start_level()
	
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
	MapController.tile_dict = tile_dict
	MapController.chunk_dict = chunk_dict
	draw_initial_chunks(initial_chunk_pos)

func draw_initial_chunks(pos):
	
	current_neighbors = MapController.create_neighbors(pos,chunk_size.x,chunk_size.y, 'ALL')
	current_neighbors.append(pos)
	for i in current_neighbors:
		
		var chunk = chunk_load.instantiate()

		$chunks.add_child(chunk)
		MapController.chunk_dict[i]['name'] = chunk.name
		MapController.chunk_dict[i]['drawn'] = true
		chunk.position = i
		
		
		for x in chosen_grid_size[0]:
			for y in chosen_grid_size[1]:
			
				var tile = tile_load.instantiate()
				var global_pos = Vector2(x,y) * Vector2(x_length, y_length) + initial_pos + i
				
				chunk.add_child(tile)
				tile.global_position = global_pos
				MapController.tile_dict[tile.global_position]['name'] = tile.name	
				
				
				tile.texture = MapController.texture_dict['hidden']['hidden']
									

	
func create_starting_loc():
	
	var starting_pos = Vector2(chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0,chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0)
	#var square_size = 3
	var grid = []
	var x = -2
	while x < 1:
		var y = -2
		while y < 1:
			grid.append(Vector2(x,y))
			y += 1
		x += 1
	
	var all_loc = MapController.convert_grid_to_pos(grid,starting_pos)
	
	for pos in all_loc:

		MapController.clicked(pos,true)
		var node = convert_to_node(pos)
		change_texture(node)
	
#############################################################################	
#█▀▄▀█ █ █▀ █▀▀
#█░▀░█ █ ▄█ █▄▄	
#############################################################################

func initialize_textures():
		MapController.texture_dict = {
		'mark' = {
			'mark1' = $sprites/marked/mark.texture,
		},
		'hidden' = {
			'hidden' = $sprites/hidden/hidden.texture,
			'clickable' = $sprites/hidden/clickable.texture

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

func convert_to_node(pos):
		var nearest_chunk_pos = MapController.get_nearest(pos, 'chunk')
		var tile = MapController.tile_dict[pos]
		var node_path = 'chunks/' +  MapController.chunk_dict[nearest_chunk_pos]['name'] + '/' + tile['name']
		var node = get_node(node_path)
		return node
	
	
func change_texture(tile):
	
	var pos = tile.global_position

	var tile_pos = tile_dict[pos]

	tile_dict[pos]['name'] = tile.name
	if tile_pos['clicked'] == false:
		if tile_pos['clickable']:
			tile.texture = MapController.texture_dict['hidden']['clickable']
		else:

			tile.texture = MapController.texture_dict['hidden']['hidden']
	else:		
		tile.texture = MapController.texture_dict['safe']
		
	
func update_chunk_pos(pos):
	
	var pos_to_move = []
	
	current_neighbors = MapController.create_neighbors(pos,chunk_size.x,chunk_size.y, 'ALL')
	current_neighbors.append(pos)
	
	var chunks_to_move = move_chunks(current_neighbors)
	
	for i in current_neighbors:
		if MapController.chunk_dict.has(i):
			if MapController.chunk_dict[i]['drawn'] == false:
				pos_to_move.append(i)
	
	for i in len(pos_to_move):

		if len(pos_to_move) == len(chunks_to_move):
			
			chunks_to_move[i].position = pos_to_move[i]
			MapController.chunk_dict[chunks_to_move[i].position]['drawn'] = true
			MapController.chunk_dict[chunks_to_move[i].position]['name'] = chunks_to_move[i].name
	
			
	for chunk in chunks_to_move:
		var chunk_children = chunk.get_children()
		for child in chunk_children:
			change_texture(child)
			
func move_chunks(dont_erase):
	
	var delete = true
	var chunks_to_move = []
			
	for chunk in $chunks.get_children():		
		for pos in dont_erase:
			if chunk.position == pos:
				MapController.chunk_dict[chunk.position]['drawn'] = true
				delete = false
		if delete == true:
			MapController.chunk_dict[chunk.position]['drawn'] = false
			chunks_to_move.append(chunk)
		delete = true

	return chunks_to_move
