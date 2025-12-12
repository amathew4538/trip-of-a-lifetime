extends Control

@export var sprint_provider_path : NodePath
@export_range(0.0, 1000.0) var stamina_max : float = 100.0
@export_range(0.1, 500.0) var drain_rate : float = 20.0 # units per second while sprinting
@export_range(0.1, 500.0) var recover_rate : float = 10.0 # units per second recovering
@export_range(0.0, 10.0) var recover_delay : float = 1.0 # seconds to wait before recovering

var stamina : float = 100.0
var _is_sprinting : bool = false
var _recover_timer : float = 0.0
var _sprint_provider: Node = null

func _ready() -> void:
	stamina = stamina_max
	$Stamina.value = stamina
	set_process(true)

	var node: Node = null
	# Prefer explicit NodePath from inspector
	if sprint_provider_path != null and sprint_provider_path != NodePath(""):
		node = get_node_or_null(sprint_provider_path)

	# If no valid NodePath, try to auto-find a MovementSprint provider in the current scene
	if node == null:
		var current_scene := get_tree().get_current_scene()
		if current_scene:
			node = _find_movement_sprint_in_node(current_scene)
		if node == null:
			node = _find_movement_sprint_in_node(get_tree().get_root())

	if node:
		_sprint_provider = node
		if node.has_signal("sprinting_started"):
			node.connect("sprinting_started", Callable(self, "_on_sprinting_started"))
		if node.has_signal("sprinting_finished"):
			node.connect("sprinting_finished", Callable(self, "_on_sprinting_finished"))
	else:
		push_warning("UI_Test: No sprint provider found; stamina will not respond to sprinting")

# Recursively find MovementSprint provider in a node subtree
func _find_movement_sprint_in_node(root: Node) -> Node:
	if root is XRToolsMovementSprint:
		return root
	for child in root.get_children():
		var result := _find_movement_sprint_in_node(child)
		if result:
			return result
	return null


func _process(delta: float) -> void:
	# Drain while sprinting
	if _is_sprinting and stamina > 0.0:
		_recover_timer = 0.0
		stamina -= drain_rate * delta
		if stamina < 0.0:
			stamina = 0.0
	else:
		# Count the delay then slowly recover
		_recover_timer += delta
		if _recover_timer >= recover_delay and stamina < stamina_max:
			stamina += recover_rate * delta
			if stamina > stamina_max:
				stamina = stamina_max

	$Stamina.value = stamina

	# Prevent sprinting while stamina is zero
	if _sprint_provider:
		# If we're out of stamina, force provider off and disable it
		if stamina <= 0.0:
			if _sprint_provider.has_method("set_sprinting"):
				_sprint_provider.set_sprinting(false)
			# Use set_enabled if provided, otherwise directly set property
			if _sprint_provider.has_method("set_enabled"):
				_sprint_provider.set_enabled(false)
			else:
				_sprint_provider.set("enabled", false)
		# If we've recovered above zero and provider is disabled, re-enable it
		else:
			var enabled_val = _sprint_provider.get("enabled")
			if enabled_val == null:
				enabled_val = true
			if not enabled_val:
				if _sprint_provider.has_method("set_enabled"):
					_sprint_provider.set_enabled(true)
				else:
					_sprint_provider.set("enabled", true)

func _on_sprinting_started() -> void:
	_is_sprinting = true

func _on_sprinting_finished() -> void:
	_is_sprinting = false
	_recover_timer = 0.0
