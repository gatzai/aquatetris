extends Control

@onready var score_label = $Score
@onready var bonus_label = $Control/Bonus
@onready var texture_rect = $Control/TextureRect

func set_scores(score):
	score_label.text = '' + str(score)

func set_bonus(bonus):
	bonus_label.text = "x" + str(bonus)
	if bonus > 1:
		texture_rect.show()

func _on_button_pressed():
	get_tree().reload_current_scene()
