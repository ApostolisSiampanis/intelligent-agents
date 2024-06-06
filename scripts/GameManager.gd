extends Node

class TeamScore:
	var target_wood_amount: int
	var target_stone_amount: int
	var targer_gold_amount: int
	var current_wood_amount := 0
	var current_stone_amount := 0
	var current_gold_amount := 0
	
	func _init(target_wood_amount, target_stone_amount, targer_gold_amount):
		self.target_wood_amount = target_wood_amount
		self.target_stone_amount = target_stone_amount
		self.targer_gold_amount = targer_gold_amount
