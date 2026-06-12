class_name HeartIcon
extends TextureRect


func set_full() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(0, 0, 16, 16)


func set_half() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(16, 0, 16, 16)


func set_empty() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(32, 0, 16, 16)
