extends Node2D
class_name Tetromino

signal lock_tetromino(tetromino: Tetromino)
signal generate_vapour(tetromino: Tetromino)

var bounds = {
	"min_x": -216,
	"max_x": 216,
	"max_y": 457,
	"min_y": -457
}

var rotation_index = 0
var wall_kicks
var tetromino_data
var is_next_piece
# 当前 tetromino 的构成子方块
var pieces = []
# 正在下落的不算，只要落下来锁定了，就会移到这里面
#var other_tetrominos: Array[Tetromino] = []
var other_tetrominos_pieces = []

var water_height = 0  # 在生成 tetromino 时初始化

@onready var piece_scene = preload("res://scenes/piece.tscn")
@onready var timer = $Timer

var tetromino_cells
var touched_water = false

func _ready():
	tetromino_cells = Shared.cells[tetromino_data.tetromino_type]
	
	# 生成一个块
	for cell in tetromino_cells:
		var piece = piece_scene.instantiate() as Piece
		pieces.append(piece)
		add_child(piece)
		piece.set_texture(tetromino_data.piece_texture)
		piece.position = cell * piece.get_size()
		piece.medium = tetromino_data.tetromino_medium

	# 旋转方式
	if is_next_piece == false:
		position = tetromino_data.spawn_position
		wall_kicks = Shared.wall_kicks_i if tetromino_data.tetromino_type ==  Shared.Tetromino.I else Shared.wall_kicks_jlostz
	else:
		set_process_input(false)
		timer.stop()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

# 处理输入
func _input(event):
	if Input.is_action_just_pressed("up"):
		test()
	if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Vapour:
		return
	if Input.is_action_just_pressed("left"):
		move(Vector2.LEFT)
	elif Input.is_action_just_pressed("right"):
		move(Vector2.RIGHT)
	elif Input.is_action_just_pressed("down"):
		move(Vector2.DOWN)
	elif Input.is_action_just_pressed("hard_drop"):
		hard_drop()
	elif Input.is_action_just_pressed("rotate_left"):
		rotate_tetromino(-1)
	elif Input.is_action_just_pressed("rotate_right"):
		rotate_tetromino(1)

func test():
	print('test')

# 处理移动
func move(direction: Vector2) -> bool:
	var new_position = calculate_global_position(direction, global_position)
	if new_position:
		# BUG: new_position 为 （0，0） 就无法更新坐标
		global_position = new_position
		return true
	return false

func calculate_global_position(direction: Vector2, starting_global_position: Vector2):
	# 检测与其他 tetromino 的碰撞
	if is_colliding_with_other_tetrominos(direction, starting_global_position):
		return null
	# 检查边界
	if !is_within_game_bounds(direction, starting_global_position):
		return null
	
	# 检查其他媒介的移动
	if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Styrofoam and is_touch_water(direction, starting_global_position):
		return null
	
	# TODO magmatic 接触水面时生成云块， 用信号告知 board 
	if !touched_water and tetromino_data.tetromino_medium == Shared.TetrominoMedium.Magmatic and is_touch_water(direction, starting_global_position):
		print('yes')
		generate_vapour.emit(self)
	return starting_global_position + direction * pieces[0].get_size()

func is_touch_water(direction: Vector2, starting_global_position: Vector2):
	for piece in pieces:
		var new_position = piece.position + starting_global_position + direction * piece.get_size()
		if new_position.y >= water_height:
			touched_water = true
			return true
	return false

func is_within_game_bounds(direction: Vector2, starting_global_position: Vector2):
	for piece in pieces:
		var new_position = piece.position + starting_global_position + direction * piece.get_size()
		if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Vapour:
			if new_position.x < bounds.get("min_x") || new_position.x > bounds.get("max_x") || new_position.y <= bounds.get("min_y"):
				return false
		else:
			if new_position.x < bounds.get("min_x") || new_position.x > bounds.get("max_x") || new_position.y >= bounds.get("max_y"):
				return false
	return true

func is_colliding_with_other_tetrominos(direction: Vector2, starting_global_position: Vector2):
	for tetromino_piece in other_tetrominos_pieces:
		# TODO 当前块是否为云块
		# 其他块和当前块所有的小方块做位置检查
		for piece in pieces:
			# BUG tetromino_piece 为空怎么处理
			if !tetromino_piece:
				continue
				
			if starting_global_position + piece.position + direction * piece.get_size().x == tetromino_piece.global_position:
				# tetromino_piece.medium == Shared.TetrominoMedium.Styrofoam and
				if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Magmatic and !piece.burned:
					# 火山岩石超级猛
					tetromino_piece.queue_free()
					piece.burned = true
					# 换一个贴图
					piece.set_texture(Shared.medium_texture[Shared.TetrominoMedium.Magmatic].textures[2])
				else:
					return true
	return false

func rotate_tetromino(direction: int):
	var original_rotation_index = rotation_index
	if tetromino_data.tetromino_type == Shared.Tetromino.O:
		return

	apply_rotation(direction)
	rotation_index = wrap(direction + rotation_index, 0, 4)
	if !test_wall_kicks(rotation_index, direction):
		rotation_index = original_rotation_index
		apply_rotation(-direction)

func test_wall_kicks(rotation_index: int, rotation_direction: int):
	var wall_kick_index = get_wall_kick_index(rotation_index, rotation_direction)
	for i in wall_kicks[0].size():
		var translation = wall_kicks[wall_kick_index][i]
		if move(translation):
			return true
	return false

func get_wall_kick_index(rotation_index: int, rotation_direction):
	var wall_kick_index = rotation_index * 2
	if rotation_direction < 0:
		wall_kick_index -= 1
	return wrap(wall_kick_index, 0 , wall_kicks.size())
	
func apply_rotation(direction: int):
	var rotation_matrix = Shared.clockwise_rotation_matrix if direction == 1 else Shared.counter_clockwise_rotation_matrix
	var tetromino_cells = Shared.cells[tetromino_data.tetromino_type]
	# 计算新坐标
	for i in tetromino_cells.size():
		var cell = tetromino_cells[i]
		var coordinates = rotation_matrix[0] * cell.x + rotation_matrix[1] * cell.y
		tetromino_cells[i] = coordinates
	# 给每个小方块设置新坐标
	for i in pieces.size():
		var piece = pieces[i]
		piece.position = tetromino_cells[i] * piece.get_size()

func hard_drop():
	var direction = Vector2.DOWN
	if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Vapour:
		direction = Vector2.UP
	while(move(direction)):
		continue
	lock()
	
func lock():
	timer.stop()
	lock_tetromino.emit(self)
	set_process_input(false)

func _on_timer_timeout():
	var direction = Vector2.DOWN
	if tetromino_data.tetromino_medium == Shared.TetrominoMedium.Vapour:
		direction = Vector2.UP
	var should_lock = !move(direction)
	if should_lock:
		lock()
