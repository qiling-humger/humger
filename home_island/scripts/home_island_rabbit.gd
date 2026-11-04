class_name HomeIslandRabbit
extends VisualSampleRabbit
## Keep the accepted rabbit sprite/animation set, but stop looping the
## closed-eye idle frame. Eyes stay open and blink briefly every few seconds.

var _blink_left := 0.0
var _blink_wait := 4.0


func _process(delta: float) -> void:
	super._process(delta)
	_blink_wait -= delta
	if _blink_wait <= 0.0:
		_blink_left = 0.12
		_blink_wait = 3.2 + randf() * 2.0
	elif _blink_left > 0.0:
		_blink_left = maxf(0.0, _blink_left - delta)


func _update_animation() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.08:
		if absf(input.y) > absf(input.x):
			_direction = "up" if input.y < 0.0 else "down"
		else:
			_direction = "side"

	var anim := ("walk_" if _moving else "idle_") + _direction
	if _moving:
		if sprite.animation != anim:
			sprite.play(anim)
		sprite.speed_scale = 1.0
	else:
		if sprite.animation != anim:
			sprite.play(anim)
		sprite.pause()
		var frame_count := sprite.sprite_frames.get_frame_count(anim)
		sprite.frame = 1 if _blink_left > 0.0 and frame_count > 1 else 0
	sprite.flip_h = _direction == "side" and _facing < 0.0
