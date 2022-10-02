extends Node2D

@tool

signal card_entered
signal card_exited

@onready var card_mesh: MultiMeshInstance2D = $CardMesh
@onready var rect1 : MeshInstance2D = $CardMesh/Rect1 # horizontal
@onready var rect2 : MeshInstance2D = $CardMesh/Rect2 # vertical
@onready var circle1 : MeshInstance2D = $CardMesh/Circle1 # top left
@onready var circle2 : MeshInstance2D = $CardMesh/Circle2 # top right
@onready var circle3 : MeshInstance2D = $CardMesh/Circle3 # bot right
@onready var circle4 : MeshInstance2D = $CardMesh/Circle4 # bot left
@onready var click_area = $ClickArea
@onready var sprite : Sprite2D = $Sprite
@onready var label : Label = $Label

const LABEL_PADDING : = 10.0

var _card_width: float = 100
var _card_height: float = 100
var _rounded_radius: float = 10

@export_range(0, 1000, 1.0) var card_width: float = 100:
	get: return _card_width
	set(v):
		_card_width = v
		rounded_radius = rounded_radius
		update_card_dimensions()

@export_range(0, 1000, 1.0) var card_height: float = 100:
	get: return _card_height
	set(v):
		_card_height = v
		rounded_radius = rounded_radius
		update_card_dimensions()
	
@export_range(0, 1000, 0.5) var rounded_radius: float = 10:
	get: return _rounded_radius
	set(v):
		_rounded_radius = clamp(v, 0, min(card_width, card_height) / 2)
		update_card_dimensions()

func unscaled_size() -> Vector2:
	return Vector2(card_width, card_height)

func size() -> Vector2:
	return unscaled_size() * scale

func set_item(item_id):
	label.text = item_id
	sprite.texture = load("res://card_images/ldjam52/" + item_id + ".PNG")

func update_card_dimensions():
	if !rect1:
		return
	rect1.mesh.size.x = card_width
	rect1.mesh.size.y = card_height - 2 * rounded_radius

	rect2.mesh.size.x = card_width - 2 * rounded_radius
	rect2.mesh.size.y = card_height

	var circles = [circle1, circle2, circle3, circle4]
	var offsets = [Vector2(-1, 1), Vector2(1, 1), Vector2(1, -1), Vector2(-1, -1)]
	for i in 4:
		circles[i].mesh.radius = rounded_radius
		circles[i].mesh.height = 2 * rounded_radius
		circles[i].position = Vector2(card_width / 2 - rounded_radius, card_height / 2 - rounded_radius) * offsets[i]
	label.position.y = card_height / 2 - label.size.y - LABEL_PADDING

func _on_card_entered():
	card_entered.emit()
func _on_card_exited():
	card_exited.emit()

const SATURATION = 0.6
const LIGHTNESS = 0.5
const HIGHLIGHT_SATURATION = 0.6
const HIGHLIGHT_LIGHTNESS = 0.9
const DISABLED_SATURATION = 0.6
const DISABLED_LIGHTNESS = 0.2

var hue: float

func set_hue(h: float):
	hue = h
	update_color()

var _highlight: bool
@export var highlight: bool:
	get: return _highlight
	set(v):
		_highlight = v
		update_color()

var _disabled: bool
@export var disabled: bool:
	get: return _disabled
	set(v):
		_disabled = v
		update_color()

func update_color():
	if !card_mesh:
		return
	if disabled:
		card_mesh.modulate = Color.from_ok_hsl(hue, DISABLED_SATURATION, DISABLED_LIGHTNESS)
	elif highlight:
		card_mesh.modulate = Color.from_ok_hsl(hue, HIGHLIGHT_SATURATION, HIGHLIGHT_LIGHTNESS)
	else:
		card_mesh.modulate = Color.from_ok_hsl(hue, SATURATION, LIGHTNESS)

func _ready():
	click_area.mouse_entered.connect(_on_card_entered)
	click_area.mouse_exited.connect(_on_card_exited)
	highlight = false
