extends Node

var items = [
	"tweezers",
	"spring",
	"mp3 player",
	"newspaper",
	"socks",
	"wallet",
	"pen",
	"magnet",
	"pants",
	"charger",
	"window",
	"button",
	"clock",
	"bottle",
	"knife",
	"remote",
	"food",
	"computer",
	"ring",
	"chocolate",
	"shoes",
	"balloon",
	"money",
	"video games",
	"glasses",
	"book",
	"car",
	"mouse",
	"speakers",
	"toothpaste",
	"credit card",
	"carrot",
	"paint brush",
	"box",
	"camera",
	"table",
	"headphones",
	"piano",
	"flag",
	"usb drive",
	"key",
	"shovel",
	"tooth picks",
	"banana",
	"cookie",
	"fork",
	"t shirt",
	"sun",
	"house",
	"chair"
]

func random_selection(n: int) -> Array:
	var bag = ItemManager.items.duplicate()
	bag.shuffle()
	return bag.slice(0, n)
