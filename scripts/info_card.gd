extends Control

var agent: Agent
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
@onready var label_speed = %LabelSpeed
@onready var button_map = %ButtonMap

@onready var button_wood = %ButtonWood
@onready var button_stone = %ButtonStone
@onready var button_gold = %ButtonGold
@onready var button_auto = %ButtonAuto
@onready var label_assignment = %LabelAssignment
@onready var container_assign = $Panel/VBoxContainer/HBoxContainerAssign

var color_normal = Color(1, 1, 1, 1)
var color_selected = Color(0.3, 0.8, 0.3, 1)
var color_auto_selected = Color(0.2, 0.6, 1.0, 1)

func _on_ready():
	update_info()
	_update_assignment_buttons()
	_update_assign_controls_visibility()

func update_info():
	if agent != null:
		
		# Convert the state enum to a string
		var state_string = ""
		
		match agent.current_state:
			agent.State.WALKING: state_string = "WALKING"
			agent.State.DECIDING: state_string = "DECIDING"
			agent.State.REFILLING: state_string = "REFILLING"
			agent.State.IDLE: state_string = "IDLE"
		label_state.text = "State: " + state_string + " "
	
		label_agent_id.text = "Agent ID: %s" % str(agent.id)

		label_energy.text = "Energy: %s" % str(agent.energy) + "% "
		
		var carrying_resource := agent.current_carrying_resource
		if carrying_resource:
			label_resource.text = "Carrying: " + Village.resource_type_to_str(carrying_resource.type) + " (" + str(agent.current_carrying_resource.quantity) + ") "
		else:
			label_resource.text = "Resource: None"
			
		update_chromosome_labels()
		_update_assignment_text()
	_update_assign_controls_visibility()

func update_chromosome_labels():
	if agent != null and agent.chromosome != null:
		var chromosome = agent.chromosome
		
		# Speed
		label_speed.text = "Speed: %s " % str(chromosome.speed)

		# Wood capacity
		label_wood_capacity.text = "Wood: %s " % str(chromosome.wood_carry_capacity)
		
		# Stone capacity
		label_stone_capacity.text = "Stone: %s " % str(chromosome.stone_carry_capacity)
		
		# Gold capacity
		label_gold_capacity.text = "Gold: %s " % str(chromosome.gold_carry_capacity)

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

# Assignment controls
func _on_button_wood_pressed():
	if agent and (agent.village == null or agent.village.control_mode != Village.ControlMode.AI_CONTROLLED):
		agent.set_user_resource_priority(Village.ResourceType.WOOD)
	_update_assignment_buttons()
	_update_assignment_text()

func _on_button_stone_pressed():
	if agent and (agent.village == null or agent.village.control_mode != Village.ControlMode.AI_CONTROLLED):
		agent.set_user_resource_priority(Village.ResourceType.STONE)
	_update_assignment_buttons()
	_update_assignment_text()

func _on_button_gold_pressed():
	if agent and (agent.village == null or agent.village.control_mode != Village.ControlMode.AI_CONTROLLED):
		agent.set_user_resource_priority(Village.ResourceType.GOLD)
	_update_assignment_buttons()
	_update_assignment_text()

func _on_button_auto_pressed():
	if agent and (agent.village == null or agent.village.control_mode != Village.ControlMode.AI_CONTROLLED):
		agent.clear_user_resource_priority()
	_update_assignment_buttons()
	_update_assignment_text()

func _update_assignment_buttons():
	if button_wood == null or button_stone == null or button_gold == null or button_auto == null:
		return
	# Reset
	button_wood.modulate = color_normal
	button_stone.modulate = color_normal
	button_gold.modulate = color_normal
	button_auto.modulate = color_normal
	# Highlight current
	if agent and agent.has_user_selection:
		match agent.user_selected_resource:
			Village.ResourceType.WOOD:
				button_wood.modulate = color_selected
			Village.ResourceType.STONE:
				button_stone.modulate = color_selected
			Village.ResourceType.GOLD:
				button_gold.modulate = color_selected
	else:
		button_auto.modulate = color_auto_selected

func _update_assignment_text():
	if label_assignment == null:
		return
	if agent == null:
		label_assignment.text = ""
		return
	if agent.has_user_selection:
		label_assignment.text = "Assigned: %s" % Village.ResourceType.find_key(agent.user_selected_resource)
	else:
		label_assignment.text = "Assigned: AUTO"

func _update_assign_controls_visibility():
	if container_assign == null:
		return
	var hide_controls := false
	if agent and agent.village:
		hide_controls = agent.village.control_mode == Village.ControlMode.AI_CONTROLLED
	container_assign.visible = not hide_controls
	if label_assignment:
		label_assignment.visible = not hide_controls
