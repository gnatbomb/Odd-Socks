extends "res://Scripts/Player.gd"

func _setControls():
	controlDict = {"up":"P1up","swap":"P1down","left":"P1left","right":"P1right"}

func _on_Area2D_body_entered(body):
	if body.get_name() == "Player2":
		self.setVictoryFlag()
