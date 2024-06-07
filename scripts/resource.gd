extends Area2D

var resources = {
	"stone": $StoneSprite,
	"wood": $WoodSprite,
	"gold": $GoldSprite
}

@onready var label = $Label

var type := "stone"
const TOTAL_QUANTITY = 11
var current_quantity := TOTAL_QUANTITY

func _on_ready():
	update_label()

func _on_body_entered(body):
	body.on_resource_interact(self)

func loot(quantity):
	var quantity_to_return = quantity if current_quantity >= quantity else current_quantity
	current_quantity -= quantity_to_return
	update_label()
	return quantity_to_return

func update_label():
	label.text = str(current_quantity) + "/" + str(TOTAL_QUANTITY)
