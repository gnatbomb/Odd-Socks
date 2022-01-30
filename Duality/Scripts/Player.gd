extends KinematicBody2D

#CONSTANTS
const FLOOR = Vector2(0,-1)

#EXPORTS
export (float) var speed = 100
export (float) var gravity = 7
export (float) var jumpForce = 180
export (float) var boostForce = 290
export (float,0,1) var friction = 0.325
export var terminalVelocity = 250
export var partnerPath:NodePath
export (int) var playernum
export var DresserPath:NodePath

#GLOBALS
var velocity = Vector2.ZERO
onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
var jumpOnCooldown = false
var victory = false
var controlDict = {}
onready var partner = get_node(partnerPath)
onready var dresser = get_node(DresserPath)
var alive = true

func _ready():
	_setControls()
	
func _physics_process(delta):
	if (victory):
		win()
		
	if(alive and outOfFrame()):
		inputHandler(delta)
	else:
		death()
	return

#set controls
func _setControls():
	pass

#buffer input to make jump more responsive some ideas how:https://www.reddit.com/r/godot/comments/fifs2k/how_to_jump_make_more_responsive/
func inputHandler(delta):
	var input_vector = Vector2.ZERO	
	var on_floor = is_on_floor()
	var on_ceiling = is_on_ceiling()
	
	if Input.is_action_just_pressed(controlDict["swap"]):
		swap()
		return input_vector
	
	if Input.is_action_pressed(controlDict["left"]):
		input_vector.x += -1
	if Input.is_action_pressed(controlDict["right"]):
		input_vector.x += 1
	if Input.is_action_just_pressed(controlDict["up"]):
		input_vector.y = -1
	
	if(input_vector.x!=0):
		#make sock face correct way
		animationTree.set("parameters/Idle/blend_position",input_vector)
		animationTree.set("parameters/Walk/blend_position",input_vector)
		animationTree.set("parameters/Jump/blend_position",input_vector)
		animationTree.set("parameters/Fall/blend_position",input_vector)
		animationTree.set("parameters/Death/blend_position",input_vector)
		if(on_floor):
			animationState.travel("Walk")
			MusicController.play_SE(self.playernum, "steppy")
		velocity.x = input_vector.x*speed
		
	if(input_vector.y!=0 and jumpOnCooldown==false):
		animationState.travel("Jump")
		velocity.y = input_vector.y*jumpForce
		jumpOnCooldown = true
		MusicController.play_SE(self.playernum, "jump")
		
	if (on_floor and jumpOnCooldown and input_vector.y == 0):
		MusicController.play_SE(self.playernum, "land")
		jumpOnCooldown=false
	
	if(input_vector==Vector2.ZERO and on_floor):
		animationState.travel("Idle")
	elif(!on_floor and velocity.y>=7 and animationState.get_current_node()!="Fall"):
		animationState.travel("Fall")
	
	if(on_ceiling):
		velocity.y = 0
	
	move_and_slide(velocity,FLOOR)
	velocity.x = lerp(velocity.x,0,friction)
	velocity.y += gravity
	velocity.y = clamp(velocity.y,-boostForce,terminalVelocity)

func swap():
	print(partner.position,self.position)
	var temp = self.position
	self.position = partner.position
	partner.position = temp
	print(partner.position,self.position)
	
	#swap dressers
	temp = self.dresser.position
	self.dresser.position = partner.dresser.position
	partner.dresser.position = temp
	
	
	MusicController.play_SE(self.playernum, "swap")

#take logic of respawn out and into game manager!
func hitSpike():
	MusicController.play_SE(self.playernum, "owie")	
	#MusicController.play_SE(self.playernum, "death")
	alive = false
	print("died")

func hitSpring():
	animationState.travel("Jump")
	#jumpOnCooldown = true <<-----REMOVE DOUBLE JUMP
	velocity.y = -boostForce
	MusicController.play_SE(self.playernum, "spring")

func setVictoryFlag():
	MusicController.play_SE(0, "embrace")
	victory = true
	
func win():
#	animationTree.set("parameters/Death/blend_position",Vector2(1,0))
#	animationState.travel("Victory")
#	yield(get_tree().create_timer(0.6),"timeout")
	print("victory")
	victory = false
	
func death():
	animationState.travel("Death")
	print(animationState.get_current_node())
	velocity = Vector2.ZERO
	yield(get_tree().create_timer(0.6),"timeout")
	#NAT LOOK HERE!!! ^ above sets a timer that godot waits for right now the timer is the length of the death anim which is 0.6
	#add the audio stuff here

	position = dresser.position
	animationState.travel("Idle")
	alive = true

func outOfFrame():
	var x = self.position.x
	var y = self.position.y
	if(x<0 or x>560):
		return false
	if(y<0 or y>315):
		return false
	return true
