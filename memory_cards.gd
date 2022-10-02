extends Node2D

const card_scene = preload("res://card.tscn")
const card_pool_max_size = 200
var card_pool = []

@export var angle_lerp_weight : = 0.2
@export var position_lerp_weight : = 0.5

@onready var memorize_view = $memorize_view
@onready var finding_view = $finding_view

@export var finding_grid_rows: int = 5
@export var finding_grid_cols: int = 10
@export var finding_grid_gap: float = 10

var items = [
	"twezzers",
	"spring",
	"mp3 player",
	"newspaper",
	"socks",
	"wallet",
	"lace",
	"magnet",
	"pants",
	"charger",
	"seat belt",
	"button",
	"stockings",
	"rubber duck",
	"knife",
	"remote",
	"food",
	"computer",
	"key chain",
	"chocolate",
	"shoes",
	"balloon",
	"twister",
	"video games",
	"thermostat",
	"chapter book",
	"purse",
	"coasters",
	"controller",
	"toothpaste",
	"credit card",
	"water bottle",
	"paint brush",
	"bottle cap",
	"conditioner",
	"table",
	"headphones",
	"cookie jar",
	"mop",
	"USB drive",
	"puddle",
	"shovel",
	"tooth picks",
	"doll",
	"bracelet",
	"hair tie",
	"piano",
	"sidewalk",
	"nail clippers",
	"deodorant"
]

var hover_cards = {}

func _ready():
	if finding_grid_rows * finding_grid_cols != items.size():
		print("grid size does not match item count: grid size ", finding_grid_rows * finding_grid_cols, " - item count ", items.size())
	for i in card_pool_max_size:
		var new_card = card_scene.instantiate()
		new_card.card_entered.connect(card_entered.bind(new_card))
		new_card.card_exited.connect(card_exited.bind(new_card))
		card_pool.append(new_card)

	init_finding_view()
	get_viewport().size_changed.connect(_on_viewport_size_changed)

func _on_viewport_size_changed():
	update_view()

func delete_all_cards(node: Node2D):
	for ch in node.get_children():
		node.remove_child(ch)
		card_pool.append(ch)
	hover_cards.clear()
	holding_card = null

func init_memorizing_view():
	get_viewport().canvas_transform = Transform2D.IDENTITY
	memorize_view.visible = true
	finding_view.visible = false
	search_label.visible = false

	delete_all_cards(memorize_view)

	var spawn_count : = 10
	var sel = random_selection(spawn_count)
	for i in spawn_count:
		var item = sel[i]
		var c = card_pool.pop_back()
		memorize_view.add_child(c)	
		c.set_item(item)
		var vprect = get_screen_rect()
		c.set_hue(float(i) / 5.0)
		c.highlight = false
		c.position = c.size() / 2 + Vector2(
			randf_range(vprect.position.x, vprect.end.x - c.size().x),
			randf_range(vprect.position.y, vprect.end.y - c.size().y)
		)
		c.rotation = randf_range(0, 2 * PI)

func max_fit_size(div_count: int, length: float, gap: float = 0.0) -> float:
	return (length - gap) / div_count - gap

func init_finding_view():
	get_viewport().canvas_transform = Transform2D.IDENTITY * 0.5
	memorize_view.visible = false
	finding_view.visible = true
	search_label.visible = true

	delete_all_cards(finding_view)
	var vprect = get_screen_rect()
	var max_width = max_fit_size(finding_grid_cols, vprect.size.x, finding_grid_gap)
	var max_height = max_fit_size(finding_grid_rows, vprect.size.y, finding_grid_gap)
	var max_size = min(max_width, max_height)
	print(max_size)

	for i in finding_grid_rows:
		for j in finding_grid_cols:
			var ind = finding_grid_cols * i + j
			var c = card_pool.pop_back()
			finding_view.add_child(c)
			c.set_item(items[ind % items.size()])
			c.scale = max_size * Vector2.ONE / c.unscaled_size()
			c.set_hue(float(ind) / 5)
			c.highlight = false
			c.position = (Vector2(j, i) + Vector2.ONE) * (c.size() + finding_grid_gap * Vector2.ONE) - c.size() / 2

func get_screen_rect() -> Rect2:
	return get_viewport().canvas_transform.affine_inverse() * get_viewport().get_visible_rect()

var holding_card = null
var _search_text: String
var search_text : String = "":
	get: return _search_text
	set(v):
		_search_text = v
		update_search()

@onready var search_label = $CanvasLayer/Label

func update_view():
	if finding_view.visible:
		init_finding_view()
	else:
		init_memorizing_view()

func update_search():
	search_label.text = search_text
	for ch in finding_view.get_children():
		ch.disabled = !search_text.is_empty() && !ch.label.text.contains(search_text)

var guessed_cards = {}

func _input(event):
	if event is InputEventMouseButton:
		if memorize_view.visible:
			if event.button_index == MOUSE_BUTTON_LEFT:
				if event.pressed && holding_card == null:
					if !hover_cards.is_empty():
						var highest = hover_cards.keys()[0]
						var highest_index = memorize_view.get_children().find(highest)
						for hc in hover_cards.keys():
							var index = memorize_view.get_children().find(hc)
							if highest_index < index:
								highest_index = index
								highest = hc
						holding_card = highest
						holding_card.highlight = true
						memorize_view.move_child(highest, -1)
				elif !event.pressed && holding_card:
					holding_card.highlight = false
					holding_card = null
		elif finding_view.visible:
			if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
				if !hover_cards.is_empty():
					var card = hover_cards.keys()[0]
					if guessed_cards.has(card):
						card.highlight = false
						guessed_cards.erase(card)
					else:
						card.highlight = true
						guessed_cards[card] = true
					print(guessed_cards.size())
	elif finding_view.visible && event is InputEventKey && event.pressed:
		print("key")
		if (event.keycode >= KEY_A && event.keycode <= KEY_Z) || event.keycode == KEY_SPACE:
			var ch = String.chr(event.keycode + 32)
			search_text += ch
			print("key ", ch)
		elif event.keycode == KEY_BACKSPACE:
			print("backspace")
			if search_text.length() > 0:
				search_text = search_text.substr(0, search_text.length() - 1)

	# elif event is InputEventKey && event.pressed && event.keycode == KEY_M:
	# 	init_memorizing_view()
	# elif event is InputEventKey && event.pressed && event.keycode == KEY_F:
	# 	init_finding_view()
	
func _physics_process(_delta):
	if holding_card:
		holding_card.rotation = lerp_angle(holding_card.rotation, 0, angle_lerp_weight)
		holding_card.global_position = holding_card.position.lerp(get_global_mouse_position(), position_lerp_weight)
		var vprect = get_screen_rect()
		holding_card.global_position = holding_card.global_position.clamp(
			vprect.position + holding_card.size() / 2,
			vprect.end - holding_card.size() / 2)

func card_entered(card):
	if !hover_cards.has(card):
		hover_cards[card] = true

func card_exited(card):
	if hover_cards.has(card):
		hover_cards.erase(card)

func random_selection(n: int):
	var bag = items.duplicate()
	bag.shuffle()
	return bag.slice(0, n)
