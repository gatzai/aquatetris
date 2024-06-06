# 全局脚本，相当于 singleton 单例
extends Node
enum Tetromino{
	I, O, T, J, L, S, Z
}
enum TetrominoMedium{
	Stone,
	Magmatic,
	Styrofoam,
	Vapour
}

# 方块构成
var cells = {
	Tetromino.I: [Vector2(-1, 0), Vector2(0, 0), Vector2(1, 0), Vector2(2, 0)],
#-------------------------------------------------------------------
	Tetromino.J: [Vector2(-1, 1), Vector2(-1, 0), Vector2(0,0), Vector2(1, 0 )],
	#-------------------------------------------------------------------
	Tetromino.L: [Vector2(1,1), Vector2(-1, 0), Vector2(0,0), Vector2(1,0)],
	#-------------------------------------------------------------------
	Tetromino.O: [Vector2(0,1), Vector2(1,1), Vector2(0,0), Vector2(1,0)],
	#-------------------------------------------------------------------
	Tetromino.S: [Vector2(0,1), Vector2(1,1), Vector2(-1, 0), Vector2(0,0)],
	#-------------------------------------------------------------------
	Tetromino.T: [Vector2(0,1), Vector2(-1, 0), Vector2(0,0), Vector2(1,0)],
	#-------------------------------------------------------------------
	Tetromino.Z: [Vector2(-1, 1), Vector2(0, 1), Vector2(0,0), Vector2(1, 0)]
}

# 在墙边旋转的尝试
var wall_kicks_i = [
	[Vector2(0,0), Vector2(-2,0), Vector2(1,0), Vector2(-2,-1), Vector2(1,2)],
	[Vector2(0,0), Vector2(2,0), Vector2(-1, 0), Vector2(2,1), Vector2(-1, -2)],
	[Vector2(0,0), Vector2(-1, 0), Vector2(2,0), Vector2(-1,2), Vector2(2, -1)],
	[Vector2(0,0), Vector2(1,0), Vector2(-2, 0), Vector2(1, -2), Vector2(-2, 1)],
	[Vector2(0,0), Vector2(2,0), Vector2(-1, 0), Vector2(2,1), Vector2(-1, -2)],
	[Vector2(0,0), Vector2(-2,0), Vector2(1, 0), Vector2(-2, -1), Vector2(1, 2)],
	[Vector2(0,0), Vector2(1,0), Vector2(-2,0), Vector2(1, -2), Vector2(-2,1)],
	[Vector2(0,0), Vector2(-1, 0), Vector2(2, 0), Vector2(-1,2), Vector2(2, -1)]
]

var wall_kicks_jlostz = [
	[Vector2(0,0), Vector2(-1,0), Vector2(-1,1), Vector2(0,-2), Vector2(-1, -2)],
	[Vector2(0,0), Vector2(1,0), Vector2(1, -1), Vector2(0,2), Vector2(1, 2)],
	[Vector2(0,0), Vector2(1, 0), Vector2(1,-1), Vector2(0,2), Vector2(1, 2)],
	[Vector2(0,0), Vector2(-1,0), Vector2(-1, 1), Vector2(0, -2), Vector2(-1, -2)],
	[Vector2(0,0), Vector2(1,0), Vector2(1, 1), Vector2(0,-2), Vector2(1, -2)],
	[Vector2(0,0), Vector2(-1,0), Vector2(-1, -1), Vector2(0, 2), Vector2(-1, 2)],
	[Vector2(0,0), Vector2(-1,0), Vector2(-1,-1), Vector2(0, 2), Vector2(-1, 2)],
	[Vector2(0,0), Vector2(1, 0), Vector2(1, 1), Vector2(0,-2), Vector2(1, -2)]
]

var medium_texture = {
	TetrominoMedium.Stone     : preload("res://resources/stone_data.tres"), 
	TetrominoMedium.Vapour    : preload("res://resources/vapour_data.tres"),
	TetrominoMedium.Styrofoam : preload("res://resources/styrofoam_data.tres"),
	TetrominoMedium.Magmatic  :	preload("res://resources/magmatic_data.tres")
}

var data = {
	Tetromino.I: preload("res://resources/i_piece_data.tres"),
	Tetromino.O: preload("res://resources/o_piece_data.tres"),
	Tetromino.J: preload("res://resources/i_piece_data.tres"),
	Tetromino.L: preload("res://resources/i_piece_data.tres"),
	Tetromino.S: preload("res://resources/i_piece_data.tres"),
	Tetromino.T: preload("res://resources/o_piece_data.tres"),
	Tetromino.Z: preload("res://resources/o_piece_data.tres")
}

var texture_dictionary = {
	Tetromino.I: {
		TetrominoMedium.Stone : 0,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 0
	},
	Tetromino.O: {
		TetrominoMedium.Stone : 1,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 1
	},
	Tetromino.J: {
		TetrominoMedium.Stone : 2,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 0
	},
	Tetromino.L: {
		TetrominoMedium.Stone : 3,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 0
	},
	Tetromino.S: {
		TetrominoMedium.Stone : 4,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 1
	},
	Tetromino.T: {
		TetrominoMedium.Stone : 5,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 0
	},
	Tetromino.Z: {
		TetrominoMedium.Stone : 6,
		TetrominoMedium.Vapour: 0,
		TetrominoMedium.Styrofoam: 0,
		TetrominoMedium.Magmatic: 1
	},
}

var sound_effects = {
	"heavy": [
		preload("res://assets/sounds/block1.wav"),
		preload("res://assets/sounds/block2.wav")
	],
	"sand":[
		preload("res://assets/sounds/sand1.wav")
	],
	"evaporation":[
		preload("res://assets/sounds/evaporation.wav")
	],
	"clear_line":[
		preload("res://assets/sounds/clear.wav")
	]
}

# 旋转矩阵
var clockwise_rotation_matrix = [Vector2(0, -1), Vector2(1, 0)]
var counter_clockwise_rotation_matrix = [Vector2(0, 1), Vector2(-1, 0)]

# 小方块的大小
var PIECE_SIZE = 48

func _ready():
	var image = Image.new()
	var err = image.load("res://assets/magmatic/Red.png")
	if err != OK:
		print("无法加载图片")
		print_stack()
		return
	var texture = ImageTexture.new()
	texture.create_from_image(image)
	# prite.texture = texture
	
	#medium_texture[TetrominoMedium.Styrofoam] = []
