extends Area2D

var hover = false
var selected = false
func _on_mouse_entered() -> void:
	hover = true


func _on_mouse_exited() -> void:
	hover = false
	

func _unhandled_input(event: InputEvent) -> void:
	
	if Input.is_action_just_pressed("left_click"):
		if hover:
			selected = true
			print('yes')

func _process(delta: float) -> void:
	pass
	
