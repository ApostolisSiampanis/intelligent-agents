extends Button

@onready var line_edit_row = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerRow/LineEdit"
@onready var line_edit_column = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerColumn/LineEdit"
@onready var line_edit_stone = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerStone/LineEdit"
@onready var line_edit_wood = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerWood/LineEdit"
@onready var line_edit_gold = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerGold/LineEdit"
@onready var line_edit_agents = $"../../GridContainerParameters/VBoxContainerInput/HBoxContainerAgents/LineEdit"

const MapGenerator = preload("res://scripts/map_generator.gd")

func _on_button_start_pressed():
	var rows = line_edit_row.text.to_int()
	var cols = line_edit_column.text.to_int()
	var stone = line_edit_stone.text.to_int()
	var wood = line_edit_wood.text.to_int()
	var gold = line_edit_gold.text.to_int()
	var agents = line_edit_agents.text.to_int()
	
	MapGenerator.set_input_arguments(rows,cols,stone,wood,gold,agents)
	get_tree().change_scene_to_file("res://scenes/map_generator.tscn")
