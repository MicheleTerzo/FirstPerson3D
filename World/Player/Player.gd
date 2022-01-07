extends KinematicBody

# velocita delle azioni del player
const normalSpeed = 7
const sprintingSpeed = 12
const walkingSpeed = 4
const crouchingSpeedLoss = 4
const stanceTransitionSpeed = 3

const standingHeight = 1.8
const crouchHeight = 0.9

# Forza di accelerazione
var accelerationForce = 5

# Gavita assegnata al giocatore
var gravityForce = 30

# forza salto del giocatore
var jumpForce = 10

# sensibilit� del mouse
var mouse_sensitivity = 0.05

# vettore di direzione
var directionVector = Vector3()

# Vettore di velocita
var velocity = Vector3()

# Vettore di caduta
var fall = Vector3()

# stati del giocatore
var isPlayerSprinting = false
var isPlayerCrouch = false
var isPlayerProne = false
var isPlayerWalking = false

# riferimenti variabili esterne
onready var head = $Head
onready var playerCollision = $CollisionShape
onready var bonker = $HeadBonker


# Esegue la funzione al caricamento del player
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


# MOVIMENTO DEL MOUSE
func _input(event):
	if event is InputEventMouseMotion:
		rotate_y(deg2rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg2rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg2rad(-70), deg2rad(70))

func sprint():
	if Input.is_action_pressed("sprint") && bonker.is_colliding() == false:
		print("sprint")
		isPlayerSprinting = true
		isPlayerWalking = false
		isPlayerCrouch = false
	else:
		isPlayerSprinting = false

func walk():
	if Input.is_action_just_pressed("walk"):
		print("walk")
		isPlayerWalking = !isPlayerWalking

func jump():
	if Input.is_action_just_pressed("jump") && bonker.is_colliding() == false:
		fall.y = jumpForce
		fall.x = velocity.x
		fall.z = velocity.z
		isPlayerCrouch = false
		playerCollision.shape.height = standingHeight

	

# GESTISCE IL MOVIMENTO DEL GIOCATORE
func processMovement(delta):
	directionVector = Vector3()


	var speed = normalSpeed
	

	# Applica la gravita in ogni momento
	fall.y -= gravityForce * delta

	# Determina la velocità del movimento in base agli stati del giocatore
	if isPlayerWalking:
			speed = walkingSpeed
	elif isPlayerSprinting:
		speed = sprintingSpeed
	else:
		if isPlayerCrouch:
			speed = normalSpeed - crouchingSpeedLoss
		else:
			speed = normalSpeed

	# Gestisce l'azione di crouching
	if isPlayerCrouch:
		playerCollision.shape.height -= stanceTransitionSpeed * delta
	else:
		playerCollision.shape.height += stanceTransitionSpeed * delta	
	playerCollision.shape.height = clamp(playerCollision.shape.height, crouchHeight, standingHeight)
	

	move_and_slide(fall, Vector3.UP)

	if is_on_floor():
		fall = Vector3()
		
		jump()

		# CROUCH
		if Input.is_action_just_pressed("crouch"):
			isPlayerCrouch = !isPlayerCrouch
			
		# SPOSTAMENTO PUNTI CARDINALI
		if Input.is_action_pressed("move_forward"):
			directionVector -= transform.basis.z
		elif Input.is_action_pressed("move_back"):
			directionVector += transform.basis.z

		if Input.is_action_pressed("move_left"):
			directionVector -= transform.basis.x
		elif Input.is_action_pressed("move_right"):
			directionVector += transform.basis.x

		# SPRINT
		sprint()

		# WALK
		walk()

	# Previene il il movimento piu veloce spostandosi in diagonale
	directionVector = directionVector.normalized()

	# Calcola la velocita
	velocity = velocity.linear_interpolate(directionVector * speed, accelerationForce * delta)
	velocity = move_and_slide(velocity, Vector3.UP)

	# Viene chiamata ogni frame


func _process(delta):

	if Input.is_action_just_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	processMovement(delta)
