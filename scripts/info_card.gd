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
		label_agent_village.text = "Village: " + str(agent.village_type)
		label_energy.text = "Energy: " + str(agent.energy) + "%"
		if agent.current_carrying_resource:
			label_resource.text = "Resource: " + str(agent.current_carrying_resource.type) + " (" + str(agent.current_carrying_resource.quantity) + ")"
		else:
			label_resource.text = "Resource: None"
		#label_map_discovery.text = "Map Discovery: " + str(agent.map_discovery)

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
