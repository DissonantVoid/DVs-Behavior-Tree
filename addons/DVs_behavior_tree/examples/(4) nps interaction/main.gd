extends Node2D

@onready var craft_table : Marker2D = $Markers/CraftTable
@onready var craftsman_rest : Marker2D = $Markers/CraftsmanRest
@onready var seller_stock : Marker2D = $Markers/SellerStock
@onready var seller_rest : Marker2D = $Markers/SellerRest
@onready var sell_point : Marker2D = $Markers/SellPoint


@onready var materials_container : Node2D = $Materials
@onready var goods_container : Node2D = $Goods
@onready var crafts_container : Node2D = $Crafts

const _materials_scene : PackedScene = preload("materials.tscn")

func _input(event : InputEvent):
	if event is InputEventMouseButton && event.pressed && event.button_index == MOUSE_BUTTON_LEFT:
		var materials := _materials_scene.instantiate()
		materials_container.add_child(materials)
		materials.global_position = get_global_mouse_position()
