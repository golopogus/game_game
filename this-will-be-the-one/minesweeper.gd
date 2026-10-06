extends Node2D
var panning = false
var stored_mous_pos = Vector2()
var total_clicked = 0
var castle_pos
var inventory
var check_radius = 2
# final game grid = [40,25] x (25x50)
const grid_size_options = [[20,20],[4,4],[8,8]]
var chosen_grid_size = grid_size_options[0]
#var num_of_chunks = Vector2(25,50)
var num_of_chunks = Vector2(10,10)
var chunk_split
var initial_pos = Vector2(0,0)
var chunk_size = Vector2()
var x_length
var y_length
var start = false
var chunk_dict = {}
var gamestart = false
var revealed_tiles = []
var initial_chunk_pos 
var number_of_mines_per_chunk = 65
var moveable = false
var local_mous_pos
var current_neighbors = []
var stored_pos = Vector2()
var current_chunk = Vector2()
var visible_area
var safe_tiles = []
var tiles_in_current_chunk = []
var in_game_menu = false
var tile_dict = {} # pos = [tile.name, 'unknown' (type), value, true (hidden),marked]
var tile_load = preload("res://tile.tscn")
var chunk_load = preload("res://chunk.tscn")
#var castle_load = preload("res://castle.tscn")
#var enemy_base_load = preload("res://enemy_base.tscn")
#var path_load = preload("res://sp.tscn")
#var scout_load = preload("res://scout.tscn")
var mouse_in = true
var mine_thread
var texture_dict
var selected_mark = []
var round_points = 0
var score_multiplier = 1
var active_mines = []
var checked_clicked = []
func start_game(click_pos):
	
	
	gamestart = true
	
	var safe_neighbors = create_neighbors(click_pos,x_length,y_length, 'ALL')
	
	safe_neighbors.append(click_pos)
	
	for i in safe_neighbors:
		tile_dict[i]['type'] = 'safe'
		safe_tiles.append(i)
	 
	var chunk_pos = get_nearest(click_pos,'chunk')
	var chunk_neighbors = create_neighbors(chunk_pos,chunk_size.x,chunk_size.y, 'ALL')
	
	chunk_neighbors.append(chunk_pos)
	
	for i in chunk_neighbors:
		check_chunk_boundary(i)
		randomize_mine_placement(i)	
	
	clicked(click_pos)
			
#############################################################################	
#############################################################################	
#############################################################################						
func clicked(pos):
	
	revealed_tiles.append(pos)
	var nearest_chunk_pos = get_nearest(pos, 'chunk')
	var tile = tile_dict[pos]
	var node_path = 'chunks/' +  chunk_dict[nearest_chunk_pos]['name'] + '/' + tile['name']
	
	if chunk_dict[nearest_chunk_pos]['drawn'] == true:
		if tile['clicked'] == false:
			total_clicked += 1
			tile['clicked'] = true
			if tile['type'] == 'unknown':
				tile['type'] = 'safe'

			change_texture(get_node(node_path))

			if tile['type'] == 'mine':
				
				var mine_radius = 0
				if mine_radius > 0:
					update_neighbors(pos,'mine')
			
			if tile['type'] != 'mine':
				#var score_mulitplier = Globals.get_upgrade_data('click_multi') + 1
				round_points += 1 * score_multiplier
				#update_points()
				

		
		
		# reveal if tile complete
		elif tile['clicked'] == true:
			
			if tile['type'] == 'warning':
				
				var neighbors = create_neighbors(pos,x_length,y_length,'ALL')
				var count = 0
				for i in neighbors:
					if tile_dict[i]['type'] == 'mine':
						if tile_dict[i]['clicked'] == true or tile_dict[i]['marked'] == true:
							count += 1
				if count == tile['value']:
					for i in neighbors:
						if tile_dict[i]['type'] != 'mine' and tile_dict[i]['clicked'] == false:
							clicked(i)
							
			
						
			
				
	elif chunk_dict[nearest_chunk_pos]['drawn'] == false:
		tile_dict[pos]['clicked'] = true
		total_clicked += 1
		if chunk_dict[nearest_chunk_pos]['mines'] == false:
			safe_tiles = []
			safe_tiles.append(pos)
			check_chunk_boundary(nearest_chunk_pos)
			randomize_mine_placement(nearest_chunk_pos)
		if tile_dict[pos]['type'] == 'unknown':
				tile_dict[pos]['type'] = 'safe'
		
		if tile_dict[pos]['type'] != 'mine':
			#var score_multiplier = Globals.all_upgrade_data['click_multi']['current'] + 1
			round_points += 1 * score_multiplier
			#update_points()

		if tile_dict[pos]['type'] == 'mine':
			var mine_radius = 0
			if mine_radius > 0:
				update_neighbors(pos,'mine')
				
	if tile_dict[pos]['type'] == 'safe':
		
		update_neighbors(pos,'safe')					
	
#############################################################################	
#############################################################################	
#############################################################################

func update_neighbors(pos,type):	
	var nearest_chunk_pos = get_nearest(pos, 'chunk')
	
	if chunk_dict[nearest_chunk_pos]['mines'] == false:
		await randomize_mine_placement(nearest_chunk_pos)
	
	var neighbors
	var mine_neighbors
	
	if type == 'safe':
		neighbors = create_neighbors(pos, x_length, y_length, 'ALL')
		for i in neighbors:
			if tile_dict[i]['clicked'] == false:
				if tile_dict[i]['type'] != 'mine':
					clicked(i) 
	elif type == 'mine':
		mine_neighbors = create_explosion(pos)
		await get_tree().create_timer(.1).timeout
		for i in mine_neighbors:
			if tile_dict[i]['clicked'] == false:
				clicked(i)
	
	
#############################################################################	
#############################################################################	
#############################################################################

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

	
func check_chunk_boundary(pos):
	
	var x_bounds = [0,chosen_grid_size[0] - 1] 
	
	var y_bounds = [0,chosen_grid_size[1] -1]
	
	var global_bounds = [Vector2(x_bounds[0],y_bounds[0]) * Vector2(x_length, y_length) + initial_pos + pos - Vector2(x_length, y_length),
						 Vector2(x_bounds[1],y_bounds[1]) * Vector2(x_length, y_length) + initial_pos + pos + Vector2(x_length, y_length)]
	var jump = 3
	var sim_size = Vector2()
	
	var border_up = []
	var border_down = []
	var border_left = []
	var border_right = []	
	if x_bounds[1] % 3 == 0 or x_bounds[1] % 3 == 1:
		sim_size.x = x_bounds[1]
	else:
		sim_size.x = x_bounds[1] + 1
		
	if y_bounds[1] % 3 == 0 or y_bounds[1] % 3 == 1:
		sim_size.y = y_bounds[1]
	else:
		sim_size.y = y_bounds[1] + 1
	
	
	for x in int(sim_size.x):
		
		if x % jump == 0:
		
			var top_row_pos = Vector2(x,y_bounds[0])
			var top_row_pos_global = (top_row_pos * Vector2(x_length, y_length)) + initial_pos + pos
			var tiles_above_pos = create_neighbors(top_row_pos_global,x_length,y_length,'TOP')
			
			for i in tiles_above_pos:
				if i.x >= global_bounds[0].x and i.x <= global_bounds[1].x:
					border_up.append(i)
			
			var bottom_row_pos = Vector2(x,y_bounds[1])
			var bottom_row_pos_global = (bottom_row_pos * Vector2(x_length, y_length)) + initial_pos + pos
			var tiles_below_pos = create_neighbors(bottom_row_pos_global,x_length,y_length,'BOTTOM')
			
			for i in tiles_below_pos:
				if i.x >= global_bounds[0].x and i.x <= global_bounds[1].x:
					border_down.append(i)
		
	for y in int(sim_size.y):
		
		if y % jump == 0:
			
			var left_col_pos = Vector2(x_bounds[0],y)
			var left_col_pos_global = (left_col_pos * Vector2(x_length, y_length)) + initial_pos + pos
			var tiles_left_of_pos = create_neighbors(left_col_pos_global,x_length,y_length,'LEFT')
			
			for i in tiles_left_of_pos:
				if i.y >= global_bounds[0].y and i.y <= global_bounds[1].y:
					border_left.append(i)
			
			var right_row_pos = Vector2(x_bounds[1],y)
			var right_row_pos_global = (right_row_pos * Vector2(x_length, y_length)) + initial_pos + pos
			var tiles_right_of_pos = create_neighbors(right_row_pos_global,x_length,y_length,'RIGHT')
			
			for i in tiles_right_of_pos:
				if i.y >= global_bounds[0].y and i.y <= global_bounds[1].y:
					border_right.append(i)
	
	var border = {
		'up' = border_up,
		'down' = border_down,
		'left' = border_left,
		'right' = border_right,
	}
	
	find_clicked_on_border(border)

func find_clicked_on_border(border):
	
	for i in border['up']:
		if tile_dict[i]['clicked'] == true and tile_dict[i]['type'] != 'mine':
			var down_neighbors = create_neighbors(i,x_length,y_length,'BOTTOM')
			for neighbor in down_neighbors:
				if neighbor not in safe_tiles:
					safe_tiles.append(neighbor)
	
	for i in border['down']:
		if tile_dict[i]['clicked'] == true and tile_dict[i]['type'] != 'mine':
			var up_neighbors = create_neighbors(i,x_length,y_length,'TOP')
			for neighbor in up_neighbors:
				if neighbor not in safe_tiles:
					safe_tiles.append(neighbor)
		
	for i in border['left']:
		if tile_dict[i]['clicked'] == true and tile_dict[i]['type'] != 'mine':
			var right_neighbors = create_neighbors(i,x_length,y_length,'RIGHT')
			for neighbor in right_neighbors:
				if neighbor not in safe_tiles:
					safe_tiles.append(neighbor)
		
	for i in border['right']:
		if tile_dict[i]['clicked'] == true and tile_dict[i]['type'] != 'mine':
			var left_neighbors = create_neighbors(i,x_length,y_length,'LEFT')
			for neighbor in left_neighbors:
				if neighbor not in safe_tiles:
					safe_tiles.append(neighbor)

func randomize_mine_placement(pos):
	
	var unused_tile_grid = get_chunk_grid()
	var unused_tile_pos = convert_grid_to_pos(unused_tile_grid,pos)

	for i in safe_tiles:
		unused_tile_pos.erase(i)
	if chunk_dict[pos]['mines'] == false:
		for mine in number_of_mines_per_chunk:
			
			var rand_tile_pos = Vector2()
			
			rand_tile_pos = unused_tile_pos[randi_range(0, len(unused_tile_pos)-1)]					
			unused_tile_pos.erase(rand_tile_pos)		
			tile_dict[rand_tile_pos]['type'] = 'mine'
			
			var neighbors = create_neighbors(rand_tile_pos,x_length,y_length, 'ALL')
			
			for i in neighbors:
				if tile_dict[i]['type'] != 'mine':
					tile_dict[i]['type'] = 'warning'
					tile_dict[i]['value'] += 1
						
		chunk_dict[pos]['mines'] = true
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

#############################################################################	
#############################################################################	
#############################################################################

func get_chunk_grid():
	
	var chunk_grid = []
	
	for x in chosen_grid_size[0]:
		for y in chosen_grid_size[1]:
			chunk_grid.append(Vector2(x,y))
	
	return chunk_grid
	
#############################################################################	
#############################################################################	
#############################################################################
			
func mark(pos,chunk_pos):	
	
	var node_path = 'chunks/' +  chunk_dict[chunk_pos]['name'] + '/' + tile_dict[pos]['name']
	var tile = tile_dict[pos]
	if tile['clicked'] == false:

		if tile['marked'] == false:
			tile['marked'] = true
			
		elif tile['marked'] == true:
			tile['marked'] = false	
			var tile_node = get_node(node_path)
			if tile_node.material != null:
				tile_node.material.set("shader", '')	
	
	change_texture(get_node(node_path))
		
#############################################################################	
#############################################################################	
#############################################################################
	
func get_nearest(pos, val):
	
	var nearest = Vector2()
	
	match val:
		'chunk':
			nearest = floor(pos / chunk_size) * chunk_size + initial_pos
		'tile':
			nearest = floor(pos / Vector2(x_length,y_length)) * Vector2(x_length,y_length) + initial_pos
	return nearest
	
#############################################################################	
#############################################################################	
#############################################################################

func convert_grid_to_pos(grid,pos):
	
	var new_grid = []
	for i in grid:
		var new_pos = (i * Vector2(x_length, y_length)) + initial_pos + pos
		new_grid.append(new_pos)
	return new_grid

#############################################################################	
#############################################################################	
#############################################################################

func create_explosion(pos):
	
	var n = pos + Vector2(0,-1) * Vector2(x_length,y_length)
	var s = pos + Vector2(0,1) * Vector2(x_length,y_length)
	var w = pos + Vector2(-1,0) * Vector2(x_length,y_length)
	var e = pos + Vector2(1,0) * Vector2(x_length,y_length)
	
	var pre_neighbors = [n,e,s,w]
	
	var mine_radius = 0
	for i in range(mine_radius + 1):
		
		n = [pos + Vector2(0,-i) * Vector2(x_length,y_length)]
		pre_neighbors += n
		s = [pos + Vector2(0,i) * Vector2(x_length,y_length)]
		pre_neighbors += s
		w = [pos + Vector2(-i,0) * Vector2(x_length,y_length)]
		pre_neighbors += w
		e = [pos + Vector2(i,0) * Vector2(x_length,y_length)]
		pre_neighbors += e
	
	var neighbors = []

	for i in pre_neighbors:
		var nearest_chunk_pos = get_nearest(i,'chunk')
		
		if chunk_dict.has(nearest_chunk_pos):
			neighbors.append(i)
				
	return neighbors
	
#############################################################################	
#############################################################################	
#############################################################################
	
func send_init(path):
	
	get_node(path).set_init(Vector2(x_length,y_length),initial_pos)

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
	
func check_border():
	var center = castle_pos
	var x = check_radius * -1
	
	while x < check_radius + 1:
		var y =  check_radius * -1
		while y < check_radius + 1:
		
			if x == 0 and y == 0:
				pass
			else:
				var pos = Vector2(x * x_length,y * y_length) + center
				
				if pos not in active_mines and pos not in checked_clicked:
					if tile_dict[pos]['clicked'] == false:
						if tile_dict[pos]['type'] == 'mine':
							active_mines.append(pos)
						else:
							checked_clicked.append(pos)
					else:
						checked_clicked.append(pos)
			y += 1
		x += 1
