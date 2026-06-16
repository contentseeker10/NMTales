## A UI component representing a single heart icon in the health bar.
##
## Manages the display of full, half, and empty heart states by adjusting
## the region of an AtlasTexture.
class_name HeartIcon
extends TextureRect


## Sets the heart icon to display a full heart.
func set_full() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(0, 0, 16, 16)


## Sets the heart icon to display a half heart.
func set_half() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(16, 0, 16, 16)


## Sets the heart icon to display an empty heart.
func set_empty() -> void:
	if texture is AtlasTexture:
		texture.region = Rect2(32, 0, 16, 16)
