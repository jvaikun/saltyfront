extends PanelContainer

export var title = ""

onready var header = $Body/Title
onready var item_list = $Body/ItemList

func _ready():
	header.text = title
