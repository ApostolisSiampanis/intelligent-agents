extends Node

# Debug Logger - Saves all debug output to a file
# Singleton that can be accessed from anywhere in the game

var log_file: FileAccess
var log_path: String

func _ready():
	# Create logs directory if it doesn't exist
	var dir = DirAccess.open("res://")
	if not dir.dir_exists("logs"):
		dir.make_dir("logs")
	
	# Create log file with timestamp
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	log_path = "res://logs/game_log_%s.txt" % timestamp
	
	log_file = FileAccess.open(log_path, FileAccess.WRITE)
	
	if log_file:
		write_log("=".repeat(80))
		write_log("DEBUG LOG STARTED - %s" % Time.get_datetime_string_from_system())
		write_log("=".repeat(80))
	else:
		push_error("Failed to create log file at: " + log_path)

func write_log(message: String):
	"""
		Logs a message to both console and file.
	"""
	print(message)  # Print to console
	
	if log_file:
		var time = Time.get_time_string_from_system()
		log_file.store_line("[%s] %s" % [time, message])
		log_file.flush()  # Ensure it's written immediately

func _exit_tree():
	"""
		Close the log file when the game exits.
	"""
	if log_file:
		write_log("=".repeat(80))
		write_log("DEBUG LOG ENDED - %s" % Time.get_datetime_string_from_system())
		write_log("=".repeat(80))
		log_file.close()
