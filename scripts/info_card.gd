extends Node2D

var agent: Node
var map_highlighted: bool = false

var agent_highlighted: bool = false  # To track if the agent is highlighted
var map_highlight_mode: String = "all"  # To track the map highlight mode (known, unknown, or none)

signal highlight_agent(agent, highlight)
signal highlight_map(agent, mode)

@onready var label_agent_id = %LabelAgentID
@onready var label_state = %LabelState
@onready var label_energy = %LabelEnergy
@onready var label_resource = %LabelResource
@onready var label_map_discovery = %LabelMapDiscovery
@onready var label_wood_capacity = %LabelWoodCapacity
@onready var label_stone_capacity = %LabelStoneCapacity
@onready var label_gold_capacity = %LabelGoldCapacity
@onready var button_map = $Panel/VBoxContainer/HBoxContainer4/ButtonMap


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
	
		label_agent_id.text = "Agent ID: %" % str(agent.id)

		label_energy.text = "Energy: %s%" % str(agent.energy)
		
		if agent.current_carrying_resource:
			label_resource.text = "Carrying: " + str(agent.current_carrying_resource.type) + " (" + str(agent.current_carrying_resource.quantity) + ")"
		else:
			label_resource.text = "Resource: None"
			
		update_chromosome_labels()

func update_chromosome_labels():
	if agent != null and agent.chromosome != null:
		var chromosome = agent.chromosome
		
		## Speed
		#if chromosome[3] == "0":
			#label_chromosome_speed.text = "Speed: 100"
		#else:
			#label_chromosome_speed.text = "Speed: 150"

		# Wood capacity
		label_wood_capacity.text = "Wood: %s" % str(chromosome.wood_carry_capacity)
		
		# Stone capacity
		label_stone_capacity.text = "Stone: %s" % str(chromosome.stone_carry_capacity)
		
		# Gold capacity
		label_stone_capacity.text = "Gold: %s" % str(chromosome.gold_carry_capacity)

func _on_ButtonHighlightMap_pressed():
	if map_highlight_mode == "all":
		map_highlight_mode = "known"
	elif map_highlight_mode == "known":
		map_highlight_mode = "all"

	emit_signal("highlight_map", agent, map_highlight_mode)

func _on_timer_timeout():
	update_info()
	if map_highlight_mode != "all":
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
