extends Node2D

signal finding_finished(restart: bool)

const card_scene = preload("res://card.tscn")
const card_pool_max_size = 200
var card_pool = []

@onready var spawn_area : CollisionShape2D = $SpawnArea/Shape
@onready var card_holder : Node2D = $Cards
@onready var timer : Timer = $Timer
@onready var countdown_time_label : Label = $CanvasLayer/CountdownTimeLabel
@onready var countdown_desc_label : Label = $CanvasLayer/CountdownDescLabel
@onready var memorising_time_label : Label = $CanvasLayer/MemorisingTimeLabel
@onready var canvas_layer: CanvasLayer = $CanvasLayer
@onready var search_line_edit : LineEdit = $CanvasLayer/LineEdit

@onready var results_node: Control = $CanvasLayer/Results
@onready var result_label: Label = $CanvasLayer/Results/Panel/ResultLabel
@onready var details_label: Label = $CanvasLayer/Results/Panel/DetailsLabel
@onready var next_button: Button = $CanvasLayer/Results/Panel/NextButton

@export var finding_grid_rows: int = 5
@export var finding_grid_cols: int = 10
@export var finding_grid_gap: float = 10

var _active: bool = false
var active: bool:
	get: return _active
	set(v):
		_active = v
		visible = v
		canvas_layer.visible = v

var hover_cards = {}
var items: Array

const HUE_DIVS = 7

var countdown_time = 3
var memorise_time = 10

enum Mode {
	COUNTDOWN,
	FINDING,
	RESULTS,
	IDLE
}

var mode : Mode
var success : = false

func get_score():
	var count = 0
	for ch in guessed_cards:
		if items.has(ch.label.text):
			count += 1
	return count

func update_view():
	card_holder.visible = mode == Mode.FINDING || mode == Mode.RESULTS
	countdown_time_label.visible = mode == Mode.COUNTDOWN
	countdown_desc_label.visible = mode == Mode.COUNTDOWN
	memorising_time_label.visible = mode == Mode.FINDING
	results_node.visible = mode == Mode.RESULTS

	update_search()
	if mode == Mode.RESULTS:
		var score = get_score()
		success = false
		result_label.text = "Game Over"
		details_label.text = "You found %d out of %d items" % [score, items.size()]
		next_button.text = "Start over"
		if score == items.size():
			success = true
			result_label.text = "Congratulations!"
			details_label.text = "You found all the items"
			next_button.text = "Next level"
		for ch in card_holder.get_children():
			var item_name = ch.label.text
			ch.highlight = false
			ch.disabled = !items.has(item_name)
			if !ch.disabled:
				if guessed_cards.has(ch):
					ch.set_hue(0.333)
				else:
					ch.set_hue(0)

func update_search():
	search_line_edit.visible = mode == Mode.FINDING
	if mode != Mode.FINDING:
		return
	search_line_edit.text = search_text
	for ch in card_holder.get_children():
		ch.disabled = !search_text.is_empty() && !ch.label.text.to_lower().contains(search_text.to_lower())

func get_spawn_rect():
	return Rect2(spawn_area.global_position - spawn_area.shape.size / 2, spawn_area.shape.size)

func _ready():
	if finding_grid_rows * finding_grid_cols != ItemManager.items.size():
		print("grid size does not match item count: grid size ", finding_grid_rows * finding_grid_cols, " - item count ", ItemManager.items.size())
	for i in card_pool_max_size:
		var new_card = card_scene.instantiate()
		new_card.card_entered.connect(card_entered.bind(new_card))
		new_card.card_exited.connect(card_exited.bind(new_card))
		card_pool.append(new_card)

	timer.timeout.connect(_on_timer_timeout)
	# prevent focus from line edit
	search_line_edit.focus_entered.connect(func(): search_line_edit.release_focus())

func start(p_items):
	items = p_items
	mode = Mode.COUNTDOWN
	init_finding_view()
	update_view()
	timer.start(countdown_time)

func _process(_delta):
	if mode == Mode.COUNTDOWN:
		countdown_time_label.text = String.num(ceil(timer.time_left))
	elif mode == Mode.FINDING:
		memorising_time_label.text = String.num(timer.time_left, 1) + "s"

func _on_timer_timeout():
	if mode == Mode.COUNTDOWN:
		# Go to memorising
		mode = Mode.FINDING
		timer.start(memorise_time)
	elif mode == Mode.FINDING:
		mode = Mode.RESULTS
		timer.stop()
		search_text = ""
	update_view()

func delete_all_cards(node: Node2D):
	for ch in node.get_children():
		node.remove_child(ch)
		card_pool.append(ch)
	hover_cards.clear()
	holding_card = null

func max_fit_size(div_count: int, length: float, gap: float = 0.0) -> float:
	return (length - gap) / div_count - gap

func init_finding_view():
	card_holder.visible = true
	search_line_edit.visible = true
	guessed_cards.clear()

	delete_all_cards(card_holder)
	var vprect = get_spawn_rect()
	var max_width = max_fit_size(finding_grid_cols, vprect.size.x, finding_grid_gap)
	var max_height = max_fit_size(finding_grid_rows, vprect.size.y, finding_grid_gap)
	var max_size = min(max_width, max_height)

	for i in finding_grid_rows:
		for j in finding_grid_cols:
			var ind = finding_grid_cols * i + j
			var c = card_pool.pop_back()
			card_holder.add_child(c)
			c.set_item(ItemManager.items[ind % ItemManager.items.size()])
			c.scale = max_size * Vector2.ONE / c.unscaled_size()
			c.set_hue(float(ind) / HUE_DIVS)
			c.highlight = false
			c.global_position = get_spawn_rect().position + (Vector2(j, i) + Vector2.ONE) * (c.size() + finding_grid_gap * Vector2.ONE) - c.size() / 2

var holding_card = null
var _search_text: String
var search_text : String = "":
	get: return _search_text
	set(v):
		_search_text = v
		update_search()


var guessed_cards = {}

func _input(event):
	if mode != Mode.FINDING:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if !hover_cards.is_empty():
				var card = hover_cards.keys()[0]
				if guessed_cards.has(card):
					card.highlight = false
					guessed_cards.erase(card)
				elif guessed_cards.size() < items.size():
					card.highlight = true
					guessed_cards[card] = true
				search_text = ""
	elif event is InputEventKey && event.pressed:
		if (event.keycode >= KEY_A && event.keycode <= KEY_Z) || event.keycode == KEY_SPACE:
			var ch = String.chr(event.keycode + 32)
			search_text += ch
		elif event.keycode == KEY_BACKSPACE:
			if event.ctrl_pressed:
				search_text = ""
			elif search_text.length() > 0:
				search_text = search_text.substr(0, search_text.length() - 1)

func card_entered(card):
	if !hover_cards.has(card):
		hover_cards[card] = true

func card_exited(card):
	if hover_cards.has(card):
		hover_cards.erase(card)

func _on_main_menu_button_pressed():
	SceneManager.goto_main_menu_scene()

func _on_next_button_pressed():
	finding_finished.emit(!success)
