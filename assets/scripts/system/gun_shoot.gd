@tool
extends XRToolsPickable

@export var bullet_scene : PackedScene = preload("res://scenes/system/bullet.tscn")
@export var muzzle_path : NodePath
@export_range(0.1, 60.0) var fire_rate : float = 5.0 # shots per second
@export_range(0.0, 1000.0) var bullet_speed : float = 50.0

var _cooldown : float = 0.0

func _ready() -> void:
	# Connect to the pickable action signal (emitted when the user presses action while holding)
	if has_signal("action_pressed"):
		connect("action_pressed", Callable(self, "_on_action_pressed"))
	set_process(true)

func _process(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown = max(0.0, _cooldown - delta)

func _on_action_pressed(_pickable) -> void:
	# Only fire while held
	if not is_picked_up():
		return
	# enforce cooldown
	if _cooldown > 0.0:
		return

	# find muzzle
	var muzzle : Node = null
	if muzzle_path != null and muzzle_path != NodePath(""):
		muzzle = get_node_or_null(muzzle_path)
	if muzzle == null:
		muzzle = self

	# instantiate bullet
	var b := bullet_scene.instantiate()
	var root := get_tree().get_current_scene()
	if not root:
		root = get_tree().get_root()
	root.add_child(b)
	# place at muzzle
	if b and b is Node:
		b.global_transform = muzzle.global_transform
		# set bullet speed if available
		if b.has_variable("speed"):
			b.speed = bullet_speed
