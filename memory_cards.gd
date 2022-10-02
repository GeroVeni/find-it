extends Node2D

@onready var memorise_scene : Node2D = $MemoriseScene
@onready var finding_scene : Node2D = $FindingScene

var level : int = 1
var current_selection

var skip_memory = false

func get_spawn_count():
	return level + 2

func _ready():
	memorise_scene.memorise_finished.connect(_on_memorise_scene_memorise_finished)
	finding_scene.finding_finished.connect(_on_finding_scene_finding_finished)
	current_selection = ItemManager.random_selection(get_spawn_count())
	print(current_selection)

	if skip_memory:
		start_finding_scene()
	else:
		start_memorise_scene()

func start_memorise_scene():
	memorise_scene.active = true
	finding_scene.active = false
	current_selection = ItemManager.random_selection(get_spawn_count())
	memorise_scene.start(current_selection, level)

func start_finding_scene():
	memorise_scene.active = false
	finding_scene.active = true
	finding_scene.start(current_selection)

func _on_memorise_scene_memorise_finished():
	start_finding_scene()

func _on_finding_scene_finding_finished(restart):
	level += 1
	if restart:
		level = 1
	start_memorise_scene()
