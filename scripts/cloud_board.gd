extends Node

const ROW_COUNT = 20
const COLUMN_COUNT = 10
var vapour_tetrominos: Array[Tetromino] = []
@export var tetromino_scene: PackedScene
@onready var line_scene = preload("res://scenes/border_line.tscn")
@onready var water_body = $"../Waterbody"
@onready var timer = $Timer

signal clear_vapour_line

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.
	
func spawn_vapour_tetromino(type: Shared.Tetromino, spawn_position):
	# 生成一个 tetromino
	var tetromino_data = Tetromino_DATA.new()
	tetromino_data.tetromino_type = type
	#  --给 tetromino 赋予类型并且获取相应贴图
	var tetromino_medium = Shared.TetrominoMedium.Vapour
	tetromino_data.piece_texture = get_tetromino_texture(type, tetromino_medium)
	tetromino_data.tetromino_medium = tetromino_medium
	# --生成实例
	var tetromino = tetromino_scene.instantiate() as Tetromino
	tetromino.tetromino_data = tetromino_data
	tetromino.is_next_piece = false
	
	var other_pieces = get_all_pieces()
	tetromino.other_tetrominos_pieces = other_pieces
	tetromino.lock_tetromino.connect(on_tetromino_locked)
	add_child(tetromino)
	tetromino.global_position = spawn_position
	tetromino.timer.set_wait_time(0.5)

func on_tetromino_locked(tetromino: Tetromino):
	print('lock, cloud')
	#tetrominos.append(tetromino)
	add_tetromino_to_lines(tetromino)  # BUG 触发了第二次碰撞
	remove_full_lines()
	#tetromino_locked.emit()

func get_tetromino_texture(type: Shared.Tetromino, medium: Shared.TetrominoMedium):
	var index = Shared.texture_dictionary[type][medium]
	return Shared.medium_texture[medium].textures[index]

func add_tetromino_to_lines(tetromino: Tetromino):
	var medium = tetromino.tetromino_data.tetromino_medium
	if medium == Shared.TetrominoMedium.Styrofoam:
		pass
	var tetromino_pieces = tetromino.get_children().filter(func (c):return c is Piece)
	for piece in tetromino_pieces:
		var y_position = piece.global_position.y
		var has_that_line = false  # 标记是否存在对应坐标的行
		for line in get_lines():
			if line.global_position.y == y_position:
				piece.reparent(line)
				has_that_line = true
		if !has_that_line:
			var piece_line = line_scene.instantiate() as BorderLine
			piece_line.global_position = Vector2(0, y_position)
			add_child(piece_line) # BUG 触发了第二次碰撞
			piece.reparent(piece_line)

func remove_full_lines():
	for line in get_lines():
		# 检查是否消除一行
		if line.is_line_full(COLUMN_COUNT):
			# 消除云朵，先出发粒子动画，然后再上升水位
			water_body.cpu_particles_2d.emitting = true
			timer.start(1)
			move_lines_up(line.global_position.y)
			clear_vapour_line.emit()
			line.free()  # 同步释放
			# BUG 这个 line 没有释放掉

func move_lines_up(y_position):
	#var in_water = is_under_water(y_position)
	for line in get_lines():
		if line.global_position.y > y_position:
			line.global_position.y -= Shared.PIECE_SIZE

func get_all_pieces():
	var pieces = []
	for line in get_lines():
		pieces.append_array(line.get_children())
	return pieces

# 获取每一行
func get_lines():
	return get_children().filter(func (c):return c is BorderLine)


func _on_timer_timeout():
	water_body.cpu_particles_2d.emitting = false
	water_body.update_water_level(2)  #水位上升
