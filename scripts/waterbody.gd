extends Node2D

# 弹簧刚度常数
@export var k = 0.025
# 弹簧阻尼
@export var d = 0.03
# 传播广度
@export var spread = 0.002

@export var distance_between_springs = 24
@export var spring_number = 21

@onready var water_spring = preload("res://scenes/water_spring.tscn")

# 水的形状
@export var water_depth = 480
var target_height = global_position.y
var bottom = target_height + water_depth
var horizontal_plane = 8  # 水面下有多少格子

@onready var water_border = $WaterBorder as SmoothPath
@export var water_border_thickness = 1.1
@onready var collision_shape_2d = $Area2D/CollisionShape2D

@onready var water_polygon = $WaterPolygon

@onready var cpu_particles_2d = $CPUParticles2D

var springs = []
var passes = 8   # 没看懂是干嘛的

func _ready():
	#water_border.width = water_border_thickness
	for i in range(spring_number):
		var x_position = distance_between_springs * i
		var w = water_spring.instantiate()
		springs.append(w)
		add_child(w)
		w.initialize(Vector2(x_position, horizontal_plane))
	set_water_level(10)
	splash(randi()%spring_number, 8)

func update_water_level(delta):
	set_water_level(horizontal_plane + delta)

func set_water_level(level):
	horizontal_plane = level
	horizontal_plane = clamp(horizontal_plane, 0, 20)
	for spring in springs:
		spring.set_level(level * Shared.PIECE_SIZE)
	# 设置碰撞区域
	var wh = get_water_height()
	var pos_y = (bottom + wh) / 2
	collision_shape_2d.shape.size = Vector2(Shared.PIECE_SIZE * 10, bottom - wh)
	collision_shape_2d.position = Vector2(Shared.PIECE_SIZE * 5, pos_y)

# 获取水面高度
func get_water_height():
	return bottom - Shared.PIECE_SIZE * horizontal_plane

func _physics_process(delta):
	for i in springs:
		i.water_update(k, d)
	
	# 每个点与左边点的高度差
	var left_deltas = []
	# 每个点与右边点的高度差
	var right_deltas = []
	for i in range(spring_number):
		left_deltas.append(0)
		right_deltas.append(0)
	
	for i in range(spring_number):
		if i > 0:
			left_deltas[i] = spread * (springs[i].height - springs[i-1].height)
			springs[i-1].velocity += left_deltas[i]
		if i < spring_number-1:
			right_deltas[i] = spread * (springs[i].height - springs[i-1].height)
			springs[i+1].velocity += right_deltas[i]
	# TODO 很奇怪，平滑曲线变成了一坨
	draw_border()
	draw_water_body()

func splash(index, speed):
	if index >= 0 and index < spring_number:
		springs[index].velocity += speed

func draw_border():
	var curve = Curve2D.new().duplicate()
	var surface_points = []
	for spring in springs:
		surface_points.append(spring.position)
	#for i in springs.size:
	#	surface_points.append(springs[i].position)
	
	for point in surface_points:
		curve.add_point(point)
	#for i in surface_points.size():
	#	curve.add_point(surface_points[i])	
	water_border.curve = curve
	water_border.smooth(true)
	#water_border.update()

func draw_water_body():
	# 水表面所有的点
	var surface_points = []

	for i in range(spring_number):
		surface_points.append(springs[i].position)
	
	var first_index = 0
	var last_index = surface_points.size()-1

	var water_polygon_points = surface_points
	water_polygon_points.append(Vector2(surface_points[last_index].x, bottom))
	water_polygon_points.append(Vector2(surface_points[first_index].x, bottom))

	water_polygon_points = PackedVector2Array(water_polygon_points)
	water_polygon.set_polygon(water_polygon_points)
	#water_polygon.position = Vector2(0,0)

var water_dic = {}

func _on_area_2d_area_entered(area):
	var tetromino = area.get_parent()
	#area.get_child(1).disabled = true
	var dash_point = (area.global_position.x + Shared.PIECE_SIZE * 5) / (Shared.PIECE_SIZE * 10) * (spring_number-1)
	#print(dash_point)
	splash(int(dash_point), 8)
	if tetromino not in water_dic and tetromino is Tetromino:
		print(tetromino.name)
		water_dic[tetromino] = tetromino.name
