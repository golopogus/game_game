extends Node2D

# used for doing calculations and keeping track of the dictionaries


var panning = false
var stored_mous_pos = Vector2()
const grid_size_options = [[20,20],[4,4],[8,8]]
var chosen_grid_size = grid_size_options[0]
var num_of_chunks = Vector2(10,10)
var initial_pos = Vector2(0,0)
var chunk_size = Vector2()
var x_length = 16
var y_length = 16
var chunk_dict = {}
var initial_chunk_pos 
var moveable = false
var local_mous_pos
var current_neighbors = []
var stored_pos = Vector2()
var current_chunk = Vector2()
var tile_dict = {} 
var mouse_in = true
var texture_dict

	

									
func clicked(pos,at_start):
	
	var tile = tile_dict[pos]
	
	if tile['clickable'] == true or at_start:
		if tile['clicked'] == false:
			tile['clicked'] = true
			check_clickable(pos)
			#change_texture(get_node(node_path))
			var neighbors = create_neighbors(pos,x_length,y_length,'CARDINAL')
			for t in neighbors:
				check_clickable(t)

func check_clickable(tile_pos):

	if tile_dict[tile_pos]['clicked'] == false:
		tile_dict[tile_pos]['clickable'] = true
	else:
		tile_dict[tile_pos]['clickable'] = false
	
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




	


	
	

			
				
			
	
