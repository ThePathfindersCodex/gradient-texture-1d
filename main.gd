extends Node2D

const GRADIENT_FOLDER := "res://gradients/"
const PREVIEW_WIDTH := 96
const PREVIEW_HEIGHT := 16

@onready var option_button : OptionButton = %OptionButtonGradients
@onready var gradient_rect : ColorRect = %ColorRectCurrentGradient1D
@onready var gradient2_rect : ColorRect = %ColorRectCurrentGradientDiagonal
@onready var gradient3_rect : ColorRect = %ColorRectCurrentGradientRadial
@onready var gradient4_rect : ColorRect = %ColorRectCurrentGradientConical
@onready var gradient5_rect : TextureRect = %TextureRectGrayscaleTest

var gradient_resources : Array = []

func _ready():
	_load_gradients()

func _load_gradients():
	option_button.clear()
	gradient_resources.clear()

	var dir := DirAccess.open(GRADIENT_FOLDER)
	if dir == null:
		push_error("Gradient folder not found: " + GRADIENT_FOLDER)
		return

	var files : Array[String] = []
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if !dir.current_is_dir():
			if file.get_extension() == "tres":
				files.append(file)
		file = dir.get_next()
	dir.list_dir_end()

	# Sort alphabetically
	files.sort()
	for file_name in files:

		var path := GRADIENT_FOLDER + file_name
		var res := load(path)

		if res is GradientTexture1D:

			var gradient_tex : GradientTexture1D = res
			var preview := _generate_preview(gradient_tex)

			var index := gradient_resources.size()

			gradient_resources.append(gradient_tex)

			option_button.add_icon_item(
				preview,
				file_name.get_basename(),
				index
			)

	# Preselect first gradient
	if gradient_resources.size() > 0:
		option_button.select(0)
		_apply_gradient(0)

func _generate_preview(gradient_tex:GradientTexture1D) -> Texture2D:

	var img := Image.create(PREVIEW_WIDTH, PREVIEW_HEIGHT, false, Image.FORMAT_RGBA8)

	for x in PREVIEW_WIDTH:

		var t := float(x) / float(PREVIEW_WIDTH - 1)
		var col : Color = gradient_tex.gradient.sample(t)

		for y in PREVIEW_HEIGHT:
			img.set_pixel(x, y, col)

	var tex := ImageTexture.create_from_image(img)

	return tex

func _on_option_button_gradients_item_selected(index:int) -> void:
	_apply_gradient(index)

func _set_shader_parameters(parameter_key, value) -> void:
	var mat := gradient_rect.material as ShaderMaterial
	if mat:
		mat.set_shader_parameter(parameter_key, value)
		
	var mat2 := gradient2_rect.material as ShaderMaterial
	if mat2:
		mat2.set_shader_parameter(parameter_key, value)

	var mat3 := gradient3_rect.material as ShaderMaterial
	if mat3:
		mat3.set_shader_parameter(parameter_key, value)
		
	var mat4 := gradient4_rect.material as ShaderMaterial
	if mat4:
		mat4.set_shader_parameter(parameter_key, value)
		
	var mat5 := gradient5_rect.material as ShaderMaterial
	if mat5:
		mat5.set_shader_parameter(parameter_key, value)

func _apply_gradient(index:int):
	if index < 0 or index >= gradient_resources.size():
		return

	var gradient_tex : GradientTexture1D = gradient_resources[index]
	_set_shader_parameters("gradient_texture", gradient_tex)

func _on_h_slider_steps_value_changed(value: float) -> void:
	_set_shader_parameters("steps", value)

func _on_h_slider_hue_shift_value_changed(value: float) -> void:
	_set_shader_parameters("hue_shift", value)
