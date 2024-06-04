extends Area2D

var resources = {
	"stone": $StoneSprite,
	"wood": $WoodSprite,
	"gold": $GoldSprite
}

var type := "stone"
var current_amount := 11

func _on_body_entered(body):
	print("Hello from on body entered method!")
	body.on_resource_interact(self)

func loot(amount):
	var amount_to_return = amount if current_amount >= amount else current_amount
	current_amount -= amount_to_return
	return amount_to_return
