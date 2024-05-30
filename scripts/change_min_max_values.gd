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

func _ready():
	rows_slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	rows_line_edit.connect("text_changed", Callable(self, "_on_rows_or_columns_changed"))
	
	columns_slider.connect("value_changed", Callable(self, "_on_slider_value_changed"))
	columns_line_edit.connect("text_changed", Callable(self, "_on_rows_or_columns_changed"))

func _on_slider_value_changed(value):
	rows_line_edit.text = str(rows_slider.value)
	columns_line_edit.text = str(columns_slider.value)
	_on_rows_or_columns_changed(value)

func _on_rows_or_columns_changed(new_value):
	var rows_value = int(rows_line_edit.text)
	var columns_value = int(columns_line_edit.text)
	var total_tiles = rows_value * columns_value

	stones_slider.min_value = total_tiles / 10
	stones_slider.max_value = total_tiles / 5
	stones_slider.value = stones_slider.min_value
	stones_line_edit.text = str(stones_slider.min_value)
	label_stones_value.text = "(" + str(stones_slider.min_value) + " - " + str(stones_slider.max_value) + ")"
	
	wood_slider.min_value = total_tiles / 5
	wood_slider.max_value = total_tiles / 2
	wood_slider.value = wood_slider.min_value
	wood_line_edit.text = str(wood_slider.min_value)
	label_wood_value.text = "(" + str(wood_slider.min_value) + " - " + str(wood_slider.max_value) + ")"

	gold_slider.min_value = total_tiles / 6
	gold_slider.max_value = total_tiles / 3
	gold_slider.value = gold_slider.min_value
	gold_line_edit.text = str(gold_slider.min_value)
	label_gold_value.text = "(" + str(gold_slider.min_value) + " - " + str(gold_slider.max_value) + ")"

	agents_slider.min_value = total_tiles / 10
	agents_slider.max_value = total_tiles / 4
	agents_slider.value = agents_slider.min_value
	agents_line_edit.text = str(agents_slider.min_value)
	label_agents_value.text = "(" + str(agents_slider.min_value) + " - " + str(agents_slider.max_value) + ")"
