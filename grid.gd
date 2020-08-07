extends Node2D

export (int) var width
export (int) var height
export (int) var x_start
export (int) var y_start
export (int) var offset

var possible_pieces = [
	preload("res://Scenes/AttackGem.tscn"),
	preload("res://Scenes/BlockGem.tscn"),
	preload("res://Scenes/ChargeGem.tscn"),
	preload("res://Scenes/MoneyGem.tscn"),
	preload("res://Scenes/PotionGem.tscn"),
	preload("res://Scenes/TimeGem.tscn"),
	preload("res://Scenes/XPGem.tscn")
]

var all_pieces = []

var press = Vector2(0, 0)
var release = Vector2(0, 0)
var controlling = false

func _ready():
	randomize()
	all_pieces = make_2d_array()
	spawn_pieces()
	
func make_2d_array():
	var array = []
	for i in width:
		array.append([])
		for j in height:
			array[i].append(null)
	return array	

func spawn_pieces():
	for i in width:
		for j in height:
			var rand = floor(rand_range(0, possible_pieces.size()))
			var	piece = possible_pieces[rand].instance()
			var loops = 0
			while(match_at(i, j, piece.gemtype) && loops < 100):
				rand = floor(rand_range(0, possible_pieces.size()))
				loops += 1
				piece = possible_pieces[rand].instance()
			add_child(piece)
			piece.position = grid_to_pixel(i, j)
			all_pieces[i][j] = piece

func match_at(i, j, gemtype):
	if i > 1:
		if all_pieces[i - 1][j] != null && all_pieces[i - 2][j] != null:
			if all_pieces[i - 1][j].gemtype == gemtype && all_pieces[i - 2][j].gemtype == gemtype:	
				return true	
	if j > 1:
		if all_pieces[i][j - 1] != null && all_pieces[i][j - 2] != null:
			if all_pieces[i][j - 1].gemtype == gemtype && all_pieces[i][j - 2].gemtype == gemtype:	
				return true	
	
func grid_to_pixel(column, row):
	var new_x = x_start + offset * column
	var new_y = y_start + -offset * row
	return Vector2(new_x, new_y)
	
func pixel_to_grid(pixel_x, pixel_y):
	var new_x = round((pixel_x - x_start) / offset)
	var new_y = round((pixel_y - y_start) / -offset)
	return Vector2(new_x, new_y)
	pass

func is_in_grid(grid_position):
	if grid_position.x >= 0 && grid_position.x < width:
		if grid_position.y >= 0 && grid_position.y < height:
			return true
	return false		

func touch_input():
	if Input.is_action_just_pressed("ui_press"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)):
			press = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			controlling = true
	if Input.is_action_just_released("ui_press"):
		if is_in_grid(pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)) && controlling:
			controlling = false
			release = pixel_to_grid(get_global_mouse_position().x, get_global_mouse_position().y)
			touch_difference(press, release)

func swap_pieces(column, row, direction):
	var first_piece = all_pieces[column][row]
	var other_piece = all_pieces[column + direction.x][row + direction.y]
	all_pieces[column][row] = other_piece
	all_pieces[column + direction.x][row + direction.y] = first_piece
	first_piece.move(grid_to_pixel(column + direction.x, row + direction.y))
	other_piece.move(grid_to_pixel(column, row))
	find_matches()

func touch_difference(grid_1, grid_2):
	var difference = grid_2 - grid_1
	if abs(difference.x) > abs(difference.y):
		if difference.x > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(1, 0))
		elif difference.x < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(-1, 0))	
	elif abs(difference.y) > abs(difference.x):
		if difference.y > 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, 1))
		elif difference.y < 0:
			swap_pieces(grid_1.x, grid_1.y, Vector2(0, -1))						
	
func _process(_delta):
	touch_input()

func find_matches():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if i > 0 && i < width - 1:
					if all_pieces[i - 1][j] != null && all_pieces[i + 1][j] != null:
						all_pieces[i - 1][j].matched = true
						all_pieces[i][j].matched = true
						all_pieces[i + 1][j].matched = true
				if j > 0 && j < height - 1:
					if all_pieces[i][j - 1] != null && all_pieces[i][j + 1] != null:
						all_pieces[i][j - 1].matched = true
						all_pieces[i][j].matched = true
						all_pieces[i][j + 1].matched = true
	get_parent().get_node("destroy_timer").start()						

func destroy_matched():
	for i in width:
		for j in height:
			if all_pieces[i][j] != null:
				if all_pieces[i][j].matched:
					all_pieces[i][j].queue_free()

func _on_destroy_timer_timeout():
	destroy_matched()

