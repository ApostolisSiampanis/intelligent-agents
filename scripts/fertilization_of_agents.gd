extends Node


func fertilize(parent_1: Node, parent_2: Node) -> void:
	"""
		- This function simulates the fertilization process by performing a
		  two-point crossover between the chromosomes of two parent nodes.
		- Additionally, it introduces a mutation with a probability of 0.1
		  to each parent's chromosome.
		- Hides both Agent_1 and Agent_2 Sprite2D for each parent and then
		  shows the appropriate Agent Sprite2D based on the village the parent
		  belongs to after the crossover.
	"""
	two_point_crossover(parent_1, parent_2)
	parent_1.chromosome =\
		mutate(parent_1.chromosome) if randf() <= 0.1 else parent_1.chromosome
	parent_2.chromosome =\
		mutate(parent_2.chromosome) if randf() <= 0.1 else parent_2.chromosome
	
	# Hide both Agent_1 and Agent_2 Sprite2D for each parent
	for i in range(2):
		parent_1.get_child(i).visible = false
		parent_2.get_child(i).visible = false
	
	# Show the appropriate Agent Sprite2D based on what village the parent belongs to after the crossover
	parent_1.get_child(parent_1.chromosome[0]).visible = true
	parent_2.get_child(parent_2.chromosome[0]).visible = true

func two_point_crossover(parent_1: Node, parent_2: Node) -> void:
	"""
		- This function performs a two-point crossover on the chromosomes of two parent nodes.
		- A set of valid crossover points is defined based on whether the parents belong to the same village.
		- Two unique points are randomly selected and sorted as crossover points.
		- Using these points, two child chromosomes are created by swapping segments of the parent chromosomes.
		- The original chromosomes of parent_1 and parent_2 are then replaced by the new child chromosomes.
	"""
	var chromosome_1: String = parent_1.chromosome
	var chromosome_2: String = parent_2.chromosome
	var same_village := chromosome_1[0] == chromosome_2[0]
	var valid_points := [2, 3, 4, 6, 8] if same_village else [1, 2, 3, 4, 6, 8]
	var points := []
	
	# Find crossover points
	points.append(valid_points.pop_at(randi_range(0, len(valid_points)-1)))
	points.append(valid_points.pop_at(randi_range(0, len(valid_points)-1)))
	points.sort()
	
	# Perform two-point crossover
	var child_chromosome_1 := chromosome_1.substr(0, points[0]) +\
								chromosome_2.substr(points[0], points[1]-points[0]) +\
									chromosome_1.substr(points[1], len(chromosome_1)-points[1])

	var child_chromosome_2 := chromosome_2.substr(0, points[0]) +\
								chromosome_1.substr(points[0], points[1]-points[0]) +\
									chromosome_2.substr(points[1], len(chromosome_1)-points[1])
	
	# Parents become the new offsprings
	parent_1.chromosome = child_chromosome_1
	parent_2.chromosome = child_chromosome_2

func mutate(chromosome: String) -> String:
	"""
		This function randomly mutates a single bit (except the village bit)
		within the given chromosome string.
	"""
	var idx := randi_range(1, len(chromosome)-1)
	chromosome[idx] = "0" if chromosome[idx] == "1" else "1"
	return chromosome
