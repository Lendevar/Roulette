extends Control

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"

var port = 1909

var connected = false

var currentPass

var confirmedCode

var spinState = "halt"

func connectToServer():
	network.create_client(ip, port)
	
	get_tree().set_network_peer(network)
	
	network.connect("connection_failed", self, "_OnConnectionFailed")
	network.connect("connection_succeeded", self, "_OnConnectionSucceeded")

func _ready():
	pass # Replace with function body.

func _OnConnectionFailed():
	print("Failed To Connect")
	$pnlRoulette.hide()
	$pnlStart.show()

remote func openRoulette():
	currentPass = $pnlStart/txtPass.text
	$pnlStart.hide()
	
	$pnlStart/lblError.hide()
	
	$pnlRoulette.show()

remote func loginDenied():
	$pnlStart/lblError.show()

func _OnConnectionSucceeded():
	print("Connection Established")
	print("Checking passcode")
	
	var passCode = $pnlStart/txtPass.text.strip_edges(true,true)
	
	rpc_id(1, "checkPassCode", passCode)

func _on_btnLogin_button_up():
	if get_tree().network_peer == null:
		connectToServer()
	else:
		var passCode = $pnlStart/txtPass.text.strip_edges(true,true)
		rpc_id(1, "checkPassCode", passCode)

func _on_btnCode_button_up():
	var currentCode = $pnlRoulette/pnlCode/txtCode.text.strip_edges(true,true)
	
	if get_tree().network_peer == null:
		connectToServer()
	else:
		rpc_id(1, "checkSpinCode", [currentPass,currentCode])

remote func codeConfirmed():
	confirmedCode = $pnlRoulette/pnlCode/txtCode.text.strip_edges(true,true)
	$pnlRoulette/pnlCode.hide()
	$pnlRoulette/pnlWheel.show()
	$pnlRoulette/pnlWheel/btnSpin.show()

remote func codeDenied():
	$pnlRoulette/pnlCode/lblError.show()

func goBack():
	$pnlRoulette/pnlWheel.hide()
	$pnlRoulette/pnlCode.show()
	$pnlRoulette/pnlCode/txtCode.text = ""
	
	$pnlRoulette/pnlWheel/wheel.rotation_degrees = 0
	leftToSpin = 0
	$pnlRoulette/pnlWheel/lblWin.text = ""
	$pnlRoulette/pnlWheel/lblWin.hide()

func _on_btnBack_button_up():
	goBack()

func _on_btnSpin_button_up():
	rpc_id(1, "makeSpin", confirmedCode)
	$pnlRoulette/pnlWheel/btnSpin.hide()

func showPrizeLabel(prize):
	$pnlRoulette/pnlWheel/lblWin.text = prize

var leftToSpin = 0

func getDegree(prize):
	var interval
	
	match prize:
		"10 литров":
			interval = [5,40]
		"0,5 литров":
			interval = [50, 84]
		"Попробуйте ещё":
			interval = [96,130]
		"5 литров":
			interval = [140,174]
		"Jackpot":
			interval = [186,220]
		"Подарок":
			interval = [230,264]
		"1 литр":
			interval = [276,310]
		"2 литра":
			interval = [320,354]
	
	return interval

remote func getSpinResult(res):
	showPrizeLabel(res)
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var fullSpins = rng.randi_range(8,15)
	
	leftToSpin += fullSpins * 360
	rng.randomize()
	
	var interval = getDegree(res)
	
	leftToSpin += rng.randi_range(interval[0], interval[1])
	
	spinState = "back"

var spinVelocity = 0

onready var wheel = $pnlRoulette/pnlWheel/wheel

var decel = 0

export var backdegree = -15
export var backAccel = 0.1

export var maxVelocity = 15
export var degreeToSlow = 1080
export var forwardAccel = 0.2

func _process(delta):
	
	if spinState == "back":
		
		spinVelocity -= backAccel
		
		if wheel.rotation_degrees <= backdegree:
			leftToSpin += abs(wheel.rotation_degrees) 
			spinState = "forward"
		else:
			wheel.rotation_degrees += spinVelocity
		
	
	if spinState == "forward":
		
		spinVelocity += forwardAccel
		
		if spinVelocity >= maxVelocity:
			spinVelocity = maxVelocity
		
		if leftToSpin <= degreeToSlow and leftToSpin >= 1:
			spinState = "slowing"
		
		wheel.rotation_degrees += spinVelocity
		leftToSpin -= spinVelocity
	
	
	if spinState == "slowing":
		spinVelocity -= backAccel
		if spinVelocity <= 2:
			spinVelocity = leftToSpin*delta
		
		wheel.rotation_degrees += spinVelocity
		leftToSpin -= spinVelocity
		
		
		if leftToSpin < 1:
			spinVelocity = 0
			spinState = "win"
	
	if spinState == "win":
		$pnlRoulette/pnlWheel/lblWin.show()
		spinState = "halt"
	
	
