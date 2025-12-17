extends RichTextLabel



func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	text = str(PlayerGlobalVariables.ammo) + "/" + str(PlayerGlobalVariables.ammo_total)
