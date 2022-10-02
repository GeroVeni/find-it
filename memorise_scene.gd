extends Node2D

signal memorise_finished

const card_scene = preload("res://card.tscn")
const card_pool_max_size = 200
var card_pool = []

var level: int
var items: Array

@export var angle_lerp_weight : = 0.2
@export var position_lerp_weight : = 0.5

var hover_cards = {}

@onready var spawn_area : CollisionShape2D = $SpawnArea/Shape
@onready var card_holder : Node2D = $Cards
@onready var timer : Timer = $Timer
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var countdown_time_label : Label = $CanvasLayer/CountdownTimeLabel
@onready var countdown_desc_label : Label = $CanvasLayer/CountdownDescLabel
@onready var memorising_time_label : Label = $CanvasLayer/MemorisingTimeLabel
@onready var level_label : Label = $CanvasLayer/LevelLabel

var _active: bool = false
var active: bool:
	get: return _active
	set(v):
		_active = v
		visible = v
		canvas_layer.visible = v

var countdown_time = 3
var memorise_time = 10

enum Mode {
	COUNTDOWN,
	MEMORISING,
	IDLE
}

var mode : Mode

func get_spawn_rect():
	return Rect2(spawn_area.global_position - spawn_area.shape.size / 2, spawn_area.shape.size)

const HUE_DIVS = 7

func _ready():
	for i in card_pool_max_size:
		var new_card = card_scene.instantiate()
		new_card.card_entered.connect(card_entered.bind(new_card))
		new_card.card_exited.connect(card_exited.bind(new_card))
		card_pool.append(new_card)

	timer.timeout.connect(_on_timer_timeout)

func start(p_items, p_level):
	level = p_level
	level_label.text = "Level %d" % level
	items = p_items
	mode = Mode.COUNTDOWN
	init_memorizing_view()
	update_view()
	timer.start(countdown_time)

func _on_timer_timeout():
	if mode == Mode.COUNTDOWN:
		# Go to memorising
		mode = Mode.MEMORISING
		timer.start(memorise_time)
	elif mode == Mode.MEMORISING:
		mode = Mode.IDLE
		timer.stop()
		# Go to guessing screen
		memorise_finished.emit()
	update_view()

func _process(_delta):
	if mode == Mode.COUNTDOWN:
		countdown_time_label.text = String.num(ceil(timer.time_left))
	elif mode == Mode.MEMORISING:
		memorising_time_label.text = String.num(timer.time_left, 1) + "s"

func update_view():
	card_holder.visible = mode == Mode.MEMORISING
	countdown_time_label.visible = mode == Mode.COUNTDOWN
	countdown_desc_label.visible = mode == Mode.COUNTDOWN
	level_label.visible = mode == Mode.COUNTDOWN
	memorising_time_label.visible = mode == Mode.MEMORISING

func delete_all_cards(node: Node2D):
	for ch in node.get_children():
		node.remove_child(ch)
		card_pool.append(ch)
	hover_cards.clear()
	holding_card = null

func create_card(item, hue):
	var c = card_pool.pop_back()
	card_holder.add_child(c)	
	c.set_item(item)
	var vprect = get_spawn_rect()
	c.set_hue(hue)
	c.highlight = false
	c.global_position = c.size() / 2 + Vector2(
		randf_range(vprect.position.x, vprect.end.x - c.size().x),
		randf_range(vprect.position.y, vprect.end.y - c.size().y)
	)
	c.rotation = randf_range(0, 2 * PI)

func init_memorizing_view():
	delete_all_cards(card_holder)

	for i in items.size():
		create_card(items[i], float(i) / HUE_DIVS)

var holding_card = null

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed && holding_card == null:
				if !hover_cards.is_empty():
					var highest = hover_cards.keys()[0]
					var highest_index = get_children().find(highest)
					for hc in hover_cards.keys():
						var index = get_children().find(hc)
						if highest_index < index:
							highest_index = index
							highest = hc
					holding_card = highest
					holding_card.highlight = true
					move_child(highest, -1)
			elif !event.pressed && holding_card:
				holding_card.highlight = false
				holding_card = null
	
func _physics_process(_delta):
	if holding_card:
		holding_card.rotation = lerp_angle(holding_card.rotation, 0, angle_lerp_weight)
		holding_card.global_position = holding_card.global_position.lerp(get_global_mouse_position(), position_lerp_weight)
		var vprect = get_spawn_rect()
		holding_card.global_position = holding_card.global_position.clamp(
			vprect.position + holding_card.size() / 2,
			vprect.end - holding_card.size() / 2)

func card_entered(card):
	if !hover_cards.has(card):
		hover_cards[card] = true

func card_exited(card):
	if hover_cards.has(card):
		hover_cards.erase(card)
