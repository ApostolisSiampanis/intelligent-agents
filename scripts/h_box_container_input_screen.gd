extends HBoxContainer

var slider: HSlider
var line_edit: LineEdit

var updating_slider: bool = false
var updating_line_edit: bool = false

var last_valid_value: float = 0.0

func _ready():
	slider = $HSlider
	line_edit = $LineEdit
	
	last_valid_value = slider.value
	
	slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	line_edit.connect("text_changed", Callable(self, "_on_line_edit_text_changed"))

func _on_slider_value_changed(value):
	if updating_line_edit:
		return
	updating_slider = true
	line_edit.text = str(value)
	last_valid_value = value
	updating_slider = false

func _on_line_edit_text_changed(new_text):
	if updating_slider:
		return
	updating_line_edit = true
	var value = new_text.to_float()
	if not is_nan(value):
		if value >= slider.min_value and value <= slider.max_value:
			slider.value = value
			last_valid_value = value
			print("Input was correct " + str(last_valid_value))
	else:
		# Value is not a number
		line_edit.text = str(last_valid_value)
	updating_line_edit = false
