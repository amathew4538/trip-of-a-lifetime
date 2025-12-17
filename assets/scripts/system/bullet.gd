extends CharacterBody3D

@export var speed : float = 50.0
@export var life_time : float = 5.0
@export var damage : int = 10

var _life_timer : float = 0.0
var _prev_pos : Vector3

func _ready() -> void:
	_prev_pos = global_transform.origin

func _process(delta: float) -> void:
	# Compute movement
	var move_vec := transform.basis * Vector3(0, 0, -speed) * delta
	var from := _prev_pos
	var to := from + move_vec

	# Raycast to detect hits between previous and new position
	var space := get_world_3d().direct_space_state
	var params := PhysicsRayQueryParameters3D.new()
	params.from = from
	params.to = to
	params.exclude = [self]
	var result := space.intersect_ray(params)
	if result and result.size() > 0:
		var collider_obj = result.get("collider")
		# If we hit the player, apply damage
		if collider_obj and collider_obj.is_in_group("player"):
			# Decrease the global player health and clamp
			PlayerGlobalVariables.player_health = max(0.0, PlayerGlobalVariables.player_health - float(damage))
			# Optionally notify or play effects here
			queue_free()
			return
		else:
			# Hit something else (wall) — destroy bullet
			queue_free()
			return

	# Move forward if no hit
	global_translate(move_vec)
	_prev_pos = global_transform.origin

	# Auto-free after life_time
	_life_timer += delta
	if _life_timer >= life_time:
		queue_free()
