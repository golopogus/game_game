extends Node2D


var stored_mous_pos = Vector2()
var num_of_chunks = Vector2(10,10)
var chunk_size = Vector2()
var gamestart = false
var revealed_tiles = []
var moveable = false
var local_mous_pos
var stored_pos = Vector2()
var current_chunk = Vector2()
var tile_dict = {} # pos = [tile.name, 'unknown' (type), value, true (hidden),marked]
var mouse_in = true
#var texture_dict
var map_created = false


func _ready() -> void:
	MapGen.texture_dict = initialize_textures()
	MapGen.on_ready()
	$Camera2D.position.x = chunk_size.x * num_of_chunks.x/2.0 + chunk_size.x/2.0
	$Camera2D.position.y = chunk_size.y * num_of_chunks.y/2.0 + chunk_size.y/2.0
	$squidge.position = $Camera2D.position
func _process(_delta: float) -> void:
	if map_created:
		if moveable and mouse_in:
		
			var difference = local_mous_pos - get_global_mouse_position()
			$Camera2D.position += difference
		
		var nearest_chunk_pos = Vector2()
		
		var chunk_follow_pos = $Camera2D.position

		nearest_chunk_pos = MapGen.get_nearest(chunk_follow_pos,'chunk')
		
		if nearest_chunk_pos != current_chunk:

			current_chunk = nearest_chunk_pos
			call_deferred('update_chunk_pos',current_chunk)
func _unhandled_input(_event: InputEvent) -> void:
	
	if map_created:
		var mouse_pos = get_global_mouse_position()
		var nearest_tile_pos = MapGen.get_nearest(mouse_pos, 'tile')
		var nearest_chunk_pos = MapGen.get_nearest(nearest_tile_pos,'chunk')
		
		if Input.is_action_just_pressed("left_click"):
			stored_mous_pos = get_global_mouse_position()
			stored_pos = nearest_tile_pos
			
		if Input.is_action_just_pressed("esc"):
			get_tree().quit()
				
		if Input.is_action_just_pressed("check"):
			$scouts.global_position = nearest_tile_pos
			
		if Input.is_action_just_released("left_click"):

				revealed_tiles = []
			
				if nearest_tile_pos == stored_pos:
						if tile_dict.has(nearest_tile_pos):
							if gamestart == false:
								current_chunk = MapGen.get_nearest(nearest_tile_pos,'chunk')
								MapGen.start_game(nearest_tile_pos)
							
							else:
								
								if tile_dict[nearest_tile_pos]['marked'] == false:	
									MapGen.clicked(nearest_tile_pos)
													
		if Input.is_action_just_pressed("right_click"):
			stored_mous_pos = get_global_mouse_position()
			stored_pos = nearest_tile_pos
		
		if Input.is_action_just_released("right_click"):
			if tile_dict.has(nearest_tile_pos):
				MapGen.mark(nearest_tile_pos, nearest_chunk_pos)

		if Input.is_action_pressed("pan"):
			
			
			if moveable == false:
				local_mous_pos = get_global_mouse_position()
				
			moveable = true
			
		if Input.is_action_just_released("pan"):
			moveable = false

func initialize_textures():
		var texture_dict = {
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
	
		return texture_dict
	
	#if _event is InputEventMouseButton:
		#if _event.button_index == MOUSE_BUTTON_WHEEL_UP and _event.pressed:
			#if $Camera2D.zoom.x < 1 and $Camera2D.zoom.y < 1:
				#$Camera2D.zoom += Vector2(1,1)
		#
	#if _event is InputEventMouseButton:
		#if _event.button_index == MOUSE_BUTTON_WHEEL_DOWN and _event.pressed:
			#if $Camera2D.zoom.x >= 6 and $Camera2D.zoom.y >= 6:
				#$Camera2D.zoom -= Vector2(1,1)
				#print($Camera2D.zoom)
