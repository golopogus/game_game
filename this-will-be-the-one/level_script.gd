
extends Node2D

# handles inputs and process function

var panning = false
var stored_mous_pos = Vector2()
var num_of_chunks
var initial_pos = Vector2(0,0)
var chunk_size
var x_length
var y_length
var revealed_tiles = []
var moveable = false
var local_mous_pos
var stored_pos = Vector2()
var current_chunk = Vector2()

var tile_load = preload("res://tile.tscn")
var chunk_load = preload("res://chunk.tscn")
var squidge_load = preload("res://squidge.tscn")
var mouse_in = true
var can_start = false

func _ready() -> void:
	
	num_of_chunks = MapController.num_of_chunks
	chunk_size = MapController.chunk_size
	x_length = MapController.x_length
	y_length = MapController.y_length
	
	$Camera2D.position.x = chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0 - x_length/2.0
	$Camera2D.position.y = chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0 - y_length/2.0
	
	var squidge = squidge_load.instantiate()
	add_child(squidge)
	squidge.position = $Camera2D.position
	#MapController.game_start.connect(level_start)




func _process(_delta: float) -> void:
	
	
	if moveable and mouse_in:
	
		var difference = local_mous_pos - get_global_mouse_position()
		$Camera2D.position += difference
	
	var nearest_chunk_pos = Vector2()
	
	var chunk_follow_pos = $Camera2D.position

	nearest_chunk_pos = MapController.get_nearest(chunk_follow_pos,'chunk')
	
	if nearest_chunk_pos != current_chunk:
		
		current_chunk = nearest_chunk_pos
		$map.update_chunk_pos(current_chunk)

func _unhandled_input(_event: InputEvent) -> void:
	
	var mouse_pos = get_global_mouse_position()
	var nearest_tile_pos = MapController.get_nearest(mouse_pos, 'tile')
	
	if Input.is_action_just_pressed("left_click"):
		stored_mous_pos = get_global_mouse_position()
		stored_pos = nearest_tile_pos
		
	if Input.is_action_just_pressed("esc"):
		get_tree().quit()
			
		
	if Input.is_action_just_released("left_click"):

			revealed_tiles = []
			if nearest_tile_pos == stored_pos:
				
				if MapController.tile_dict.has(nearest_tile_pos):
					current_chunk = MapController.get_nearest(nearest_tile_pos,'chunk')
					MapController.clicked(nearest_tile_pos,false)
					var node = $map.convert_to_node(nearest_tile_pos)
					$map.change_texture(node)
					
					
		

	if Input.is_action_pressed("pan"):
		
		
		if moveable == false:
			local_mous_pos = get_global_mouse_position()
			
		moveable = true
		
	if Input.is_action_just_released("pan"):
		moveable = false
