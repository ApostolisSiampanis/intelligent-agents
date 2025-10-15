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


func _on_ready():
	update_label()

func _on_body_entered(body):
	body.on_resource_interact(self)

func loot(quantity):
	var quantity_to_return = quantity if current_quantity >= quantity else current_quantity
	current_quantity -= quantity_to_return
	update_label()
	
	# Check if resource just became depleted
	if current_quantity == 0 and not was_depleted:
		was_depleted = true
		resource_depleted.emit(type)
	
	return quantity_to_return

func update_label():
	label.text = str(current_quantity) + "/" + str(total_quantity)
