# 生成方块
extends Node

var current_tetromino
var current_tetromino_medium
var next_tetromino
var next_tetromino_medium
@onready var board = $"../Board" as Board
@onready var cloud_board = $"../CloudBoard"
#@onready var ui = $"../UI"
var is_game_over = false
@onready var label = $"../Label"

func _ready():
	current_tetromino = Shared.Tetromino.values().pick_random()
	next_tetromino = Shared.Tetromino.values().pick_random()
	current_tetromino_medium = Shared.TetrominoMedium.values().pick_random()
	if current_tetromino_medium == Shared.TetrominoMedium.Vapour:
		current_tetromino_medium = Shared.TetrominoMedium.Stone
	if current_tetromino_medium == Shared.TetrominoMedium.Styrofoam: # 一开始不要随机到泡沫
		current_tetromino_medium = Shared.TetrominoMedium.Magmatic
	next_tetromino_medium = Shared.TetrominoMedium.values().pick_random()
	if next_tetromino_medium == Shared.TetrominoMedium.Vapour:
		next_tetromino_medium = Shared.TetrominoMedium.Stone
	board.spawn_tetromino(current_tetromino, current_tetromino_medium, false, null)
	board.spawn_tetromino(next_tetromino, next_tetromino_medium, true, Vector2(100, -500))
	board.tetromino_locked.connect(on_tetromino_locked)
	board.generate_vapour.connect(on_generate_vapour)
	board.game_over.connect(on_game_over)

func on_tetromino_locked():
	if is_game_over:
		return
	current_tetromino = next_tetromino
	current_tetromino_medium = next_tetromino_medium
	next_tetromino = Shared.Tetromino.values().pick_random()
	next_tetromino_medium = Shared.TetrominoMedium.values().pick_random()
	if next_tetromino_medium == Shared.TetrominoMedium.Vapour:
		next_tetromino_medium = Shared.TetrominoMedium.Stone
	board.spawn_tetromino(current_tetromino, current_tetromino_medium, false, null)
	board.spawn_tetromino(next_tetromino, next_tetromino_medium, true, Vector2(100,-500))
	# BUG ? 是不是每次都生成两个？
	
func on_generate_vapour(tetromino: Tetromino):
	var spawn_position = tetromino.global_position
	var new_tetromino = tetromino.tetromino_data.tetromino_type
	cloud_board.spawn_vapour_tetromino(new_tetromino, spawn_position)

func on_game_over():
	is_game_over = true
	var font_size = label.get_theme_font_size("Label")
	label.set("theme_override_font_sizes/font_size", 64) 
	label.set("theme_override_colors/font_color", Color.BROWN)
	label.text = "GAME\nOVER"

func raise_water():
	board.water_body.update_water_level(1)


