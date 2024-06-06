extends Node
# 展示下一个方块

class_name Board  # class_name 提供类型, 方便其他脚本调用，并提供补全，比如 res://scripts/piece_spawner.gd

signal tetromino_locked
signal game_over
signal generate_vapour(tetromino: Tetromino)

var tetrominos: Array[Tetromino] = []
var next_tetromino
@export var tetromino_scene: PackedScene
@onready var line_scene = preload("res://scenes/border_line.tscn")

@onready var water_body = $"../Waterbody"
@onready var clouds = $Clouds
@onready var cloud_board = $"../CloudBoard"
@onready var panel_container = $"../Label"
@onready var game_ui = $"../UI"
@onready var audio_stream_player_2d = $"../AudioStreamPlayer2D"


const ROW_COUNT = 20
const COLUMN_COUNT = 10

# scores
var clear_under_water_lines_cnt = 0
var bonus = 1
var clear_up_water_lines_cnt = 0

func _ready():
	cloud_board.clear_vapour_line.connect(on_clear_vapour_line)

func spawn_tetromino(type: Shared.Tetromino, tetromino_medium, is_next_piece, spawn_position):
	# 生成一个 tetromino
	#var tetromino_data = Shared.data[type]
	var tetromino_data = Tetromino_DATA.new()
	tetromino_data.tetromino_type = type
	tetromino_data.spawn_position = Vector2(-24, -456)
	#  --给 tetromino 赋予类型并且获取相应贴图
	# TEST 随机两种媒介
	#tetromino_medium = randi() % 2
	tetromino_data.piece_texture = get_tetromino_texture(type, tetromino_medium)
	tetromino_data.tetromino_medium = tetromino_medium
	# --生成实例
	var tetromino = tetromino_scene.instantiate() as Tetromino
	tetromino.tetromino_data = tetromino_data
	tetromino.is_next_piece = is_next_piece
	
	#...
	if is_next_piece == false:
		tetromino.position = tetromino_data.spawn_position
		var other_pieces = get_all_pieces()
		tetromino.other_tetrominos_pieces = other_pieces
		tetromino.water_height = water_body.get_water_height()  
		tetromino.lock_tetromino.connect(on_tetromino_locked)
		tetromino.generate_vapour.connect(on_generate_vapour)
		add_child(tetromino)
	else:
		tetromino.scale = Vector2(0.5, 0.5)
		next_tetromino = tetromino
		panel_container.add_child(tetromino)
		#tetromino.set_position(panel_container.global_position)
		var position_offset = Vector2(120, 150)
		tetromino.set_global_position(panel_container.global_position + position_offset)

func get_tetromino_texture(type: Shared.Tetromino, medium: Shared.TetrominoMedium):
	var index = Shared.texture_dictionary[type][medium]
	return Shared.medium_texture[medium].textures[index]

func get_all_pieces():
	var pieces = []
	for line in get_lines():
		pieces.append_array(line.get_children())
	return pieces

func on_tetromino_locked(tetromino: Tetromino):
	next_tetromino.queue_free()
	tetrominos.append(tetromino)
	add_tetromino_to_lines(tetromino)  # BUG 触发了第二次碰撞
	play_sound_block(tetromino.tetromino_data.tetromino_medium)
	remove_full_lines()
	tetromino_locked.emit()
	# 检查游戏是否结束
	check_game_over()

func check_game_over():
	for piece in get_all_pieces():
		var y_location = piece.global_position.y
		if y_location <= -456:
			game_over.emit()

func on_generate_vapour(tetromino: Tetromino):
	# spawn_vapour_tetromino(new_tetromino, spawn_position)
	play_sound_name("evaporation")
	generate_vapour.emit(tetromino)

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
		
# 获取每一行
func get_lines():
	return get_children().filter(func (c):return c is BorderLine)

func remove_full_lines():
	for line in get_lines():
		# 检查是否消除一行
		if line.is_line_full(COLUMN_COUNT):
			play_sound_clear_line()
			move_lines_down(line.global_position.y)
			# 水面下方
			if line.global_position.y > water_body.get_water_height():
				water_body.update_water_level(-1)
				clear_under_water_lines_cnt += 1
			# 水面上的行消除不降低水位
			else:
				if line.is_line_has_medium(Shared.TetrominoMedium.Styrofoam):
					# TODO 如果有这个材质那么怎么处理呢
					pass
				clear_up_water_lines_cnt += 1
			update_scores()
			line.free()  # 同步释放
			# BUG 这个 line 没有释放掉

func is_under_water(y_position):
	if y_position > water_body.get_water_height():
		return true
	return false

# 如果在水上，把 y_position 上面的都往下移动一格
# TODO：如果在水下, 把 y_position 上面的并且水下面的都往下移动一格，并且水上面的石头也往下移动
func move_lines_down(y_position):
	#var in_water = is_under_water(y_position)
	for line in get_lines():
		if line.global_position.y < y_position:
			line.global_position.y += Shared.PIECE_SIZE

func on_clear_vapour_line():
	bonus += 1
	update_scores()

func update_scores():
	game_ui.set_scores(get_score())
	game_ui.set_bonus(bonus)

func get_score():
	var score = clear_under_water_lines_cnt * bonus + clear_up_water_lines_cnt * 10
	return score

func play_sound_clear_line():
	audio_stream_player_2d.stream = Shared.sound_effects["clear_line"][0]
	audio_stream_player_2d.play()

func play_sound_name(sound_name):
	audio_stream_player_2d.stream = Shared.sound_effects[sound_name][0]
	audio_stream_player_2d.play()

func play_sound_block(medium : Shared.TetrominoMedium):
	var block_sound_cnt = Shared.sound_effects["heavy"].size()
	var sound_index = randi()%block_sound_cnt
	var rand_block_sound = Shared.sound_effects["heavy"][sound_index]
	var light_sound = Shared.sound_effects["sand"][0]
	if medium == Shared.TetrominoMedium.Stone or medium == Shared.TetrominoMedium.Magmatic:
		audio_stream_player_2d.stream = rand_block_sound
	else:
		audio_stream_player_2d.stream = light_sound
	audio_stream_player_2d.play()
