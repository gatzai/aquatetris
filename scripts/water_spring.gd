extends Node2D

var velocity = 0
var force = 0
var height = position.y
var target_height = position.y - 80

# 弹簧刚度常数
var k = 0.025
# 弹簧阻尼
var d = 0.03

func water_update(spring_constant, dampening):
	# 使用胡克定律
	height = position.y
	var x = height - target_height
	var loss = -dampening * velocity
	# hooke's law
	force = - spring_constant * x + loss
	velocity += force
	position.y += velocity

# 改变水平面
func set_level(level):
	var h = 10 * Shared.PIECE_SIZE - level
	height = h
	target_height = h
	position.y = h
	velocity = 2

func change_level(delta):
	set_level(height + delta)

func initialize(pos):
	height = position.y
	target_height = position.y
	position.x = pos.x
	position.y = pos.y
	velocity = 0
	
func _ready():
	pass # Replace with function body.

#func _physics_process(delta):
#	water_update(k, d)
