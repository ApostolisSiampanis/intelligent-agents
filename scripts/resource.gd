extends Area2D

@onready var label = $Label

var type: Common.TileType
var total_quantity: int
var current_quantity: int
var was_depleted: bool = false

signal resource_depleted(resource_type: Common.TileType)


func set_total_quantity(quantity: int) -> void:
	self.total_quantity = quantity
	self.current_quantity = quantity
	# Update label immediately if it's available (node already in tree)
	if is_inside_tree():
		update_label()


func _on_ready():
	# Ensure label is updated when node enters tree
	update_label()

func _on_body_entered(body):
	DebugLogger.write_log("[RESOURCE] Body entered: " + str(body.name) + " at position " + str(position))
	body.on_resource_interact(self)

func loot(quantity):
	DebugLogger.write_log("[RESOURCE] Looting " + str(quantity) + " from " + str(Common.TileType.find_key(type)) + " resource. Current: " + str(current_quantity))
	var quantity_to_return = quantity if current_quantity >= quantity else current_quantity
	current_quantity -= quantity_to_return
	update_label()
	
	DebugLogger.write_log("[RESOURCE] After loot - Remaining: " + str(current_quantity) + "/" + str(total_quantity) + ", Returned: " + str(quantity_to_return))
	
	# Check if resource just became depleted
	if current_quantity == 0 and not was_depleted:
		was_depleted = true
		resource_depleted.emit(type)
	
	return quantity_to_return

func update_label():
	label.text = str(current_quantity) + "/" + str(total_quantity)
