extends Node2D

var agent: Node
var map_highlighted: bool = false

var agent_highlighted: bool = false  # To track if the agent is highlighted
var map_highlight_mode: String = ""  # To track the map highlight mode (known, unknown, or none)

signal highlight_agent(agent, highlight)
signal highlight_map(agent, mode)

@onready var label_agent_id = %LabelAgentID
@onready var label_agent_village = %LabelAgentVillage
@onready var label_state = %LabelState
@onready var label_energy = %LabelEnergy
@onready var label_resource = %LabelResource
@onready var label_map_discovery = %LabelMapDiscovery
@onready var label_wood_capacity = %LabelWoodCapacity
@onready var label_stone_capacity = %LabelStoneCapacity
@onready var label_gold_capacity = %LabelGoldCapacity

@onready var button_map = $Panel/ButtonMap


func _on_ready():
	update_info()

func update_info():
	if agent != null:
		
		# Convert the state enum to a string
		var state_string = ""
		
		match agent.current_state:
			agent.State.WALKING: state_string = "WALKING"
			agent.State.DECIDING: state_string = "DECIDING"
			agent.State.REFILLING: state_string = "REFILLING"
			agent.State.IDLE: state_string = "IDLE"
		label_state.text = "State: " + state_string
	
		label_agent_id.text = "Agent ID: " + str(agent.get_name())

		label_energy.text = "Energy: " + str(agent.energy) + "%"
		
		if agent.current_carrying_resource:
			label_resource.text = "Carrying: " + str(agent.current_carrying_resource.type) + " (" + str(agent.current_carrying_resource.quantity) + ")"
		else:
			label_resource.text = "Resource: None"
			
		update_chromosome_labels()

func update_chromosome_labels():
	if agent != null and agent.chromosome != null:
		var chromosome = agent.chromosome
		
		# Village type
		if chromosome[0] == "0":
			label_agent_village.text = "Village: 1"
			label_agent_village.modulate = Color(0, 15, 1) # Blue
		else:
			label_agent_village.text = "Village: 2"
			label_agent_village.modulate = Color(1, 0, 0) # Red
#
		## Speed
		#if chromosome[3] == "0":
			#label_chromosome_speed.text = "Speed: 100"
			#label_chromosome_speed.modulate = Color(0, 1, 0) # Green
		#else:
			#label_chromosome_speed.text = "Speed: 150"
			#label_chromosome_speed.modulate = Color(1, 0, 0) # Red
		#
		# Wood capacity
		var wood_capacity_bits = chromosome.substr(4, 2)
		match wood_capacity_bits:
			"00":
				label_wood_capacity.text = "Wood: 10"
				label_wood_capacity.modulate = Color(0, 1, 0) # Green
			"01":
				label_wood_capacity.text = "Wood: 20"
				label_wood_capacity.modulate = Color(0, 0, 1) # Blue
			"10":
				label_wood_capacity.text = "Wood: 30"
				label_wood_capacity.modulate = Color(1, 0.5, 0) # Orange
			"11":
				label_wood_capacity.text = "Wood: 40"
				label_wood_capacity.modulate = Color(1, 0, 0) # Red
		
		# Stone capacity
		var stone_capacity_bits = chromosome.substr(6, 2)
		match stone_capacity_bits:
			"00":
				label_stone_capacity.text = "Stone: 5"
				label_stone_capacity.modulate = Color(0, 1, 0) # Green
			"01":
				label_stone_capacity.text = "Stone: 10"
				label_stone_capacity.modulate = Color(0, 0, 1) # Blue
			"10":
				label_stone_capacity.text = "Stone: 15"
				label_stone_capacity.modulate = Color(1, 0.5, 0) # Orange
			"11":
				label_stone_capacity.text = "Stone: 20"
				label_stone_capacity.modulate = Color(1, 0, 0) # Red
		
		# Gold capacity
		if chromosome[8] == "0":
			label_gold_capacity.text = "Gold: 1"
			label_gold_capacity.modulate = Color(0, 1, 0) # Green
		else:
			label_gold_capacity.text = "Gold: 3"
			label_gold_capacity.modulate = Color(0, 0, 1) # Blue

func _on_ButtonHighlightMap_pressed():
	if map_highlight_mode == "":
		map_highlight_mode = "known"
	elif map_highlight_mode == "known":
		map_highlight_mode = "all"
	else:
		map_highlight_mode = ""
	emit_signal("highlight_map", agent, map_highlight_mode)

func _on_timer_timeout():
	update_info()
	if map_highlight_mode != "":
		emit_signal("highlight_map", agent, map_highlight_mode)
	if agent_highlighted:
		emit_signal("highlight_agent", agent, true)

func _on_button_agent_pressed():
	if agent_highlighted:
		emit_signal("highlight_agent", agent, false)
		agent_highlighted = false
	else:
		emit_signal("highlight_agent", agent, true)
		agent_highlighted = true
