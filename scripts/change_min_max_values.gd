extends Node2D

@onready var rows_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerRow/HSlider
@onready var rows_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerRow/LineEdit

@onready var columns_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerColumn/HSlider
@onready var columns_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerColumn/LineEdit

@onready var stones_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerStone/HSlider
@onready var stones_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerStone/LineEdit
@onready var label_stones_value = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerValue/LabelStonesValue

@onready var wood_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerWood/HSlider
@onready var wood_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerWood/LineEdit
@onready var label_wood_value = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerValue/LabelWoodValue

@onready var gold_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerGold/HSlider
@onready var gold_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerGold/LineEdit
@onready var label_gold_value = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerValue/LabelGoldValue

@onready var agents_slider = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerAgents/HSlider
@onready var agents_line_edit = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerInput/HBoxContainerAgents/LineEdit
@onready var label_agents_value = $CenterContainer/VBoxContainer/GridContainerParameters/VBoxContainerValue/LabelAgentsValue

@onready var center_container = $CenterContainer

var total_max_resources = 0

func _ready():
	var viewport_size = get_viewport_rect().size

	center_container.set_position(Vector2(
		viewport_size.x / 2 - center_container.size.x / 2,
		viewport_size.y / 2 - center_container.size.y / 2
	))
	
	rows_slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	rows_line_edit.connect("text_changed", Callable(self, "_on_rows_or_columns_changed"))
	
	columns_slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	columns_line_edit.connect("text_changed", Callable(self, "_on_rows_or_columns_changed"))

	stones_slider.connect("value_changed", Callable(self, "_on_resource_slider_value_changed"))
	wood_slider.connect("value_changed", Callable(self, "_on_resource_slider_value_changed"))
	gold_slider.connect("value_changed", Callable(self, "_on_resource_slider_value_changed"))

func _on_slider_value_changed(value):
	rows_line_edit.text = str(rows_slider.value)
	columns_line_edit.text = str(columns_slider.value)
	_on_rows_or_columns_changed(value)

func _on_rows_or_columns_changed(new_value):
	var rows_value = int(rows_line_edit.text)
	var columns_value = int(columns_line_edit.text)
	var total_tiles = rows_value * columns_value

	total_max_resources = ceili(total_tiles * 0.01)

	var min_gold = max(1, int(total_max_resources * 0.1))
	var max_gold = max(1, int(total_max_resources * 0.2))

	var min_stones = max(1, int(total_max_resources * 0.3))
	var max_stones = max(1, int(total_max_resources * 0.4))

	var min_wood = max(1, int(total_max_resources * 0.4))
	var max_wood = max(1, int(total_max_resources * 0.6))

	var min_agents = max(1, int(total_max_resources * 0.1))
	var max_agents = max(1, int(total_max_resources * 0.2))

	stones_slider.min_value = min_stones
	stones_slider.max_value = max_stones
	stones_slider.value = stones_slider.min_value
	stones_line_edit.text = str(stones_slider.min_value)
	label_stones_value.text = "(" + str(stones_slider.min_value) + " - " + str(stones_slider.max_value) + ")"

	wood_slider.min_value = min_wood
	wood_slider.max_value = max_wood
	wood_slider.value = wood_slider.min_value
	wood_line_edit.text = str(wood_slider.min_value)
	label_wood_value.text = "(" + str(wood_slider.min_value) + " - " + str(wood_slider.max_value) + ")"

	gold_slider.min_value = min_gold
	gold_slider.max_value = max_gold
	gold_slider.value = gold_slider.min_value
	gold_line_edit.text = str(gold_slider.min_value)
	label_gold_value.text = "(" + str(gold_slider.min_value) + " - " + str(gold_slider.max_value) + ")"

	agents_slider.min_value = min_agents
	agents_slider.max_value = max_agents
	agents_slider.value = agents_slider.min_value
	agents_line_edit.text = str(agents_slider.min_value)
	label_agents_value.text = "(" + str(agents_slider.min_value) + " - " + str(agents_slider.max_value) + ")"

	_update_resource_sliders()

func _on_resource_slider_value_changed(value):
	_update_resource_sliders()

func _update_resource_sliders():
	var current_stones = int(stones_slider.value)
	var current_wood = int(wood_slider.value)
	var current_gold = int(gold_slider.value)

	var total_allocated = current_stones + current_wood + current_gold
	var remaining_resources = total_max_resources - total_allocated

	if remaining_resources != 0:
		if remaining_resources > 0:
			if current_stones < stones_slider.max_value:
				stones_slider.value = min(stones_slider.max_value, current_stones + remaining_resources)
				remaining_resources -= (stones_slider.value - current_stones)
				current_stones = int(stones_slider.value)

			if remaining_resources > 0 and current_wood < wood_slider.max_value:
				wood_slider.value = min(wood_slider.max_value, current_wood + remaining_resources)
				remaining_resources -= (wood_slider.value - current_wood)
				current_wood = int(wood_slider.value)

			if remaining_resources > 0 and current_gold < gold_slider.max_value:
				gold_slider.value = min(gold_slider.max_value, current_gold + remaining_resources)
				remaining_resources -= (gold_slider.value - current_gold)
				current_gold = int(gold_slider.value)
		else:
			if current_stones > stones_slider.min_value:
				stones_slider.value = max(stones_slider.min_value, current_stones + remaining_resources)
				remaining_resources -= (stones_slider.value - current_stones)
				current_stones = int(stones_slider.value)

			if remaining_resources < 0 and current_wood > wood_slider.min_value:
				wood_slider.value = max(wood_slider.min_value, current_wood + remaining_resources)
				remaining_resources -= (wood_slider.value - current_wood)
				current_wood = int(wood_slider.value)

			if remaining_resources < 0 and current_gold > gold_slider.min_value:
				gold_slider.value = max(gold_slider.min_value, current_gold + remaining_resources)
				remaining_resources -= (gold_slider.value - current_gold)
				current_gold = int(gold_slider.value)

	stones_line_edit.text = str(stones_slider.value)
	wood_line_edit.text = str(wood_slider.value)
	gold_line_edit.text = str(gold_slider.value)
	label_stones_value.text = "(" + str(stones_slider.min_value) + " - " + str(stones_slider.max_value) + ")"
	label_wood_value.text = "(" + str(wood_slider.min_value) + " - " + str(wood_slider.max_value) + ")"
	label_gold_value.text = "(" + str(gold_slider.min_value) + " - " + str(gold_slider.max_value) + ")"
