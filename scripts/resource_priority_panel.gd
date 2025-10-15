extends Panel

# Resource priority control panel for Village 1
# Allows user to select which resource their agents should prioritize

@onready var button_wood = $VBoxContainer/HBoxContainerButtons/ButtonWood
@onready var button_stone = $VBoxContainer/HBoxContainerButtons/ButtonStone
@onready var button_gold = $VBoxContainer/HBoxContainerButtons/ButtonGold
@onready var button_auto = $VBoxContainer/HBoxContainerButtons/ButtonAuto
@onready var label_current_priority = $VBoxContainer/LabelCurrentPriority
@onready var label_win_probability = $VBoxContainer/LabelWinProbability
@onready var label_warning = $VBoxContainer/LabelWarning

var game_manager: GameManager
var current_selection: Village.ResourceType = Village.ResourceType.WOOD
var is_auto_mode: bool = false
var has_made_initial_selection: bool = false

# Colors for button states
var color_normal = Color(1, 1, 1, 1)  # White
var color_selected = Color(0.3, 0.8, 0.3, 1)  # Green
var color_auto_selected = Color(0.2, 0.6, 1.0, 1)  # Blue

func _ready():
	# Connect button signals
	button_wood.pressed.connect(_on_button_wood_pressed)
	button_stone.pressed.connect(_on_button_stone_pressed)
	button_gold.pressed.connect(_on_button_gold_pressed)
	button_auto.pressed.connect(_on_button_auto_pressed)
	
	# Initial state - no selection
	update_button_states()
	label_current_priority.text = "SELECT RESOURCE PRIORITY TO START"
	label_warning.text = ""
	label_win_probability.text = "Win Probability: --%"

func _process(_delta):
	# Update winning probability every frame
	if game_manager != null and has_made_initial_selection:
		var probability = game_manager.calculate_winning_probability()
		label_win_probability.text = "Win Probability: %d%%" % int(probability * 100)
		
		# Update current priority display if in auto mode
		if is_auto_mode and game_manager.village_1 != null:
			var current_resource = game_manager.village_1.get_current_priority_resource()
			var resource_name = Village.ResourceType.find_key(current_resource)
			label_current_priority.text = "Current Priority: %s (AUTO)" % resource_name

func _on_button_wood_pressed():
	select_resource(Village.ResourceType.WOOD, false)
	label_warning.text = ""

func _on_button_stone_pressed():
	select_resource(Village.ResourceType.STONE, false)
	label_warning.text = ""

func _on_button_gold_pressed():
	select_resource(Village.ResourceType.GOLD, false)
	label_warning.text = ""

func _on_button_auto_pressed():
	select_resource(Village.ResourceType.WOOD, true)  # Default, will be overridden
	label_warning.text = ""

func select_resource(resource_type: Village.ResourceType, auto: bool):
	"""
		Called when user selects a resource priority.
		Updates the game manager and visual feedback.
	"""
	current_selection = resource_type
	is_auto_mode = auto
	has_made_initial_selection = true
	
	# Update game manager
	if game_manager != null:
		game_manager.set_village_1_priority(resource_type, auto)
	
	# Update visual feedback
	update_button_states()
	
	if auto:
		label_current_priority.text = "Current Priority: AUTO MODE"
	else:
		var resource_name = Village.ResourceType.find_key(resource_type)
		label_current_priority.text = "Current Priority: %s" % resource_name

func update_button_states():
	"""
		Updates button visual states based on current selection.
	"""
	# Reset all buttons to normal
	button_wood.modulate = color_normal
	button_stone.modulate = color_normal
	button_gold.modulate = color_normal
	button_auto.modulate = color_normal
	
	# Highlight selected button
	if is_auto_mode:
		button_auto.modulate = color_auto_selected
	else:
		match current_selection:
			Village.ResourceType.WOOD:
				button_wood.modulate = color_selected
			Village.ResourceType.STONE:
				button_stone.modulate = color_selected
			Village.ResourceType.GOLD:
				button_gold.modulate = color_selected

func show_resource_depleted_warning(resource_type: Village.ResourceType):
	"""
		Shows a warning when the selected resource is depleted.
	"""
	var resource_name = Village.ResourceType.find_key(resource_type)
	label_warning.text = "WARNING: %s resources depleted!\nAgents will search for more." % resource_name
	
	# Auto-hide warning after 5 seconds
	await get_tree().create_timer(5.0).timeout
	if label_warning.text.contains(resource_name):
		label_warning.text = ""

func pause_game_for_selection():
	"""
		Pauses the game until user makes initial resource selection.
	"""
	if not has_made_initial_selection:
		Engine.time_scale = 0
		label_current_priority.text = "⚠ SELECT RESOURCE PRIORITY TO START ⚠"

func resume_game_after_selection():
	"""
		Resumes the game after user makes selection.
	"""
	if has_made_initial_selection:
		Engine.time_scale = 1
