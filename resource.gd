extends Area2D

var resources = {
	"stone": $StoneSprite,
	"wood": $WoodSprite,
	"gold": $GoldSprite
}

@onready var label = $Label

var type := "stone"
const TOTAL_AMOUNT = 11
var current_amount := TOTAL_AMOUNT

func _on_ready():
	update_label()

func _on_body_entered(body):
	print("Hello from on body entered method!")
	body.on_resource_interact(self)

func loot(amount):
	var amount_to_return = amount if current_amount >= amount else current_amount
	current_amount -= amount_to_return
	update_label()
	return amount_to_return

func update_label():
	label.text = str(current_amount) + "/" + str(TOTAL_AMOUNT)
