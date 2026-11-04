class_name VisualAnchor
extends RefCounted
## Shared bottom-anchor helper.
##
## Sprites are positioned so their lowest opaque pixel sits on the logical
## ground anchor. This avoids per-asset Y guesses and keeps 1x1, 2x1 and
## rotated footprints on the same rule.

static var _bottom_pad_cache: Dictionary = {}


static func bottom_pad(texture: Texture2D, fallback: float = 0.0) -> float:
	if texture == null:
		return fallback
	var key := texture.resource_path
	if key.is_empty():
		key = "tex:%d" % texture.get_instance_id()
	if _bottom_pad_cache.has(key):
		return float(_bottom_pad_cache[key])
	var image := texture.get_image()
	if image == null or image.is_empty():
		_bottom_pad_cache[key] = fallback
		return fallback
	var width := image.get_width()
	var height := image.get_height()
	for y in range(height - 1, -1, -1):
		for x in range(width):
			if image.get_pixel(x, y).a > 0.08:
				var pad := float(height - 1 - y)
				_bottom_pad_cache[key] = pad
				return pad
	_bottom_pad_cache[key] = fallback
	return fallback


static func clear_cache() -> void:
	_bottom_pad_cache.clear()
