class_name VisualSampleRabbit
extends RabbitPlayer
## 小白兔的 Sprite 版视觉层。移动、碰撞、镜头继续使用 RabbitPlayer。

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _frames: SpriteFrames
var _direction := "down"


func setup_assets(catalog: Dictionary) -> void:
	var rabbit: Dictionary = catalog.get("rabbit", {})
	var animations: Dictionary = rabbit.get("animations", {})
	_frames = SpriteFrames.new()
	for anim_name in animations.keys():
		var name := str(anim_name)
		_frames.add_animation(name)
		_frames.set_animation_speed(name, 8.0 if name.begins_with("walk") else 2.6)
		_frames.set_animation_loop(name, true)
		for path in animations[anim_name]:
			var texture := load(str(path)) as Texture2D
			if texture:
				_frames.add_frame(name, texture)
	sprite.sprite_frames = _frames
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var frame_size: Array = rabbit.get("frame_size", [160, 220])
	var base_pad := float(rabbit.get("base_pad", 12))
	var display_scale := float(rabbit.get("display_scale", 1.0))
	sprite.scale = Vector2(display_scale, display_scale)
	sprite.position = Vector2(-float(frame_size[0]) * display_scale * 0.5,
		-float(frame_size[1]) * display_scale + base_pad * display_scale)
	sprite.play("idle_down")


func _process(delta: float) -> void:
	super._process(delta)
	_update_animation()


func _update_animation() -> void:
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input.length() > 0.08:
		if absf(input.y) > absf(input.x):
			_direction = "up" if input.y < 0.0 else "down"
		else:
			_direction = "side"
	var anim := ("walk_" if _moving else "idle_") + _direction
	if sprite.animation != anim:
		sprite.play(anim)
	sprite.flip_h = _direction == "side" and _facing < 0.0


func _draw() -> void:
	Painter.shadow(self, Vector2(0, 2), 19, 7, Color(0.15, 0.20, 0.14, 0.18))
