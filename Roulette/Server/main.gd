extends Control

const SQLite = preload("res://addons/godot-sqlite/bin/gdsqlite.gdns")

var db
var db_name = "res://database.db"

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_users = 1000

var currentlySelected = []
var currentSellerId

var currentSellerCodes = []

func openDataBase():
	db = SQLite.new()
	db.path = db_name
	db.open_db()

var currentlyOnline = []

class seller:
	var id
	var adress
	var passcode

var probabilities = {}

func startServer():
	network.create_server(port, max_users)
	
	get_tree().set_network_peer(network)
	
	print("Server Started")
	
	network.connect("peer_connected", self, "_Peer_Connected")
	network.connect("peer_disconnected", self, "_Peer_Disconnected")

func _Peer_Connected(player_id):
	print("User " + str(player_id) + " connected")

func _Peer_Disconnected(player_id):
	print("User " + str(player_id) + " is out")

remote func checkPassCode(code):
	var sender = get_tree().get_rpc_sender_id()
	
	var arrayCodes = []
	
	var j = 1
	
	while j < $listAdress.get_item_count():
		arrayCodes += [$listAdress.get_item_text(j)]
		j += 2
	
	print(arrayCodes)
	
	if arrayCodes.find(code) != -1:
		var newOnlineSeller = seller.new()
		
		openDataBase()
		
		var queryGetSellerId = "SELECT id FROM seller where passcode = '" + arrayCodes[arrayCodes.find(code)] + "';"
		db.query(queryGetSellerId)
		
		var onlineId = db.query_result[0].values()[0]
		
		#newOnlineSeller.id = onlineId
		#newOnlineSeller.adress = adr
		#newOnlineSeller.passcode = code
		#currentlyOnline += [newOnlineSeller]
		
		rpc_id(sender, "openRoulette")
		db.close_db()
	else:
		rpc_id(sender, "loginDenied")

remote func checkSpinCode(args):
	var sender = get_tree().get_rpc_sender_id()
	var senderPass = args[0]
	var code = args[1]
	
	print(sender, code)
	
	openDataBase()
	
	var queryGetSellerId = "SELECT id FROM seller where passcode = '" +  senderPass + "';"
	db.query(queryGetSellerId)
	
	var senderId = db.query_result[0].values()[0]
	
	var queryGetCodes = "SELECT code, used FROM codes JOIN seller_codes ON codes.id = seller_codes.code_id "
	queryGetCodes += "WHERE seller_codes.seller_id = " + str(senderId) + " ORDER BY used"
	
	db.query(queryGetCodes)
	var arrayCodes = db.query_result
	
	var arrayCodeValues = {}
	
	
	for row in arrayCodes:
		arrayCodeValues[row.values()[0]] = row.values()[1]
	
	if arrayCodeValues.keys().find(code) != -1:
		var id = arrayCodeValues.keys().find(code)
		if arrayCodeValues.values()[id] == 0:
			rpc_id(sender, "codeConfirmed")
			
			var queryUpdateLoggedIn = "UPDATE codes SET used = 2 WHERE code = '" + str(code) + "'"
			db.query(queryUpdateLoggedIn)
		else:
			rpc_id(sender, "codeDenied")
	else:
		rpc_id(sender, "codeDenied")
	
	db.close_db()

remote func makeSpin(code):
	openDataBase()
	
	var querySelect = "SELECT variant, prob FROM probabilities ORDER BY id ASC"
	db.query(querySelect)
	
	var arrRow = []
	
	var res = db.query_result
	for row in res:
		arrRow += [row.values()]
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var rngResult = rng.randi_range(0, 100)
	print("rng = ", rngResult)
	
	var prize
	var summ = 0
	
	for i in range(0, arrRow.size()):
		if rngResult >= summ and rngResult < arrRow[i][1] + summ:
			prize = arrRow[i][0]
		
		summ += arrRow[i][1]
	
	if rngResult == 100:
		prize = "Jackpot"
	
	var sender = get_tree().get_rpc_sender_id()
	
	var queryUpdateCode = "UPDATE codes SET used = 1, win = '" + prize + "' WHERE code = '" + code + "';"
	db.query(queryUpdateCode)
	
	rpc_id(sender, "getSpinResult", prize)
	
	db.close_db()


func _ready():
	startServer()
	readData()
	getProbabilities()

func getProbabilities():
	openDataBase()
	
	var querySelect = "SELECT variant, prob FROM probabilities ORDER BY id ASC"
	db.query(querySelect)
	
	var res = db.query_result
	for row in res:
		var arrRow = row.values()
		probabilities[arrRow[0]] = arrRow[1]
	
	$pnlProb.inputProb(probabilities)
	
	db.close_db()


func readData():
	openDataBase()
	var querySelect = "SELECT adress, passcode FROM seller"
	db.query(querySelect)
	
	var res = db.query_result
	
	$listAdress.clear()
	
	$txtAdressEdit.text = ""
	$txtPassCode.text = ""
	
	for row in res:
		var arrRow = row.values()
		var adr = arrRow[0]
		var pas = arrRow[1]
		
		print(adr, " ", pas)
		
		$listAdress.add_item(adr)
		$listAdress.add_item(str(pas))
	
	db.close_db()

func _on_btnAdd_button_up():
	var newAdress = $txtAdress.text
	
	openDataBase()
	
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	
	var number = rng.randi_range(10000,99999)
	
	var queryAdd = "INSERT INTO seller (adress, passcode) VALUES ('" + str(newAdress) + "','" + str(number) + "')"
	db.query(queryAdd)
	
	db.close_db()
	
	readData()

func loadCodes():
	openDataBase()
	
	var adr = $listAdress.get_item_text(currentlySelected[0])
	var code = $listAdress.get_item_text(currentlySelected[1])
	
	var queryGetSellerId = "SELECT id FROM seller where adress = '" + adr + "' and passcode = '" + code + "';"
	db.query(queryGetSellerId)
	
	currentSellerId = db.query_result[0].values()[0]
	
	var queryGetCodes = "SELECT code, used, win FROM codes JOIN seller_codes ON codes.id = seller_codes.code_id "
	queryGetCodes += "WHERE seller_codes.seller_id = " + str(currentSellerId) + " ORDER BY used"
	
	db.query(queryGetCodes)
	var arrayCodes = db.query_result
	
	$listCodes.clear()
	$txtForCopy.text = ""
	
	currentSellerCodes = []
	
	for row in arrayCodes:
		var values = row.values()
		
		$listCodes.add_item(str(values[0]))
		
		if str(values[1]) == "1":
			$listCodes.add_item("Использован")
		else:
			if str(values[1]) == "2":
				$listCodes.add_item("Зашли без спина")
			else:
				$listCodes.add_item("Действителен")
				$txtForCopy.text += str(values[0]) + " , "
				
				currentSellerCodes += [str(values[0])]
		
		$listCodes.add_item(str(values[2]))
		

func _on_listAdress_multi_selected(index, selected):
	if index % 2 == 1:
		$txtPassCode.text = $listAdress.get_item_text(index)
		$listAdress.select(index - 1, false)
		$txtAdressEdit.text = $listAdress.get_item_text(index-1)
	
	if index % 2 == 0:
		$txtAdressEdit.text = $listAdress.get_item_text(index)
		$listAdress.select(index + 1, false)
		$txtPassCode.text = $listAdress.get_item_text(index+1)
	
	currentlySelected = $listAdress.get_selected_items()
	
	loadCodes()

func _on_btnEdit_button_up():
	
	var oldAdr = str($listAdress.get_item_text(currentlySelected[0]))
	var oldPass = str($listAdress.get_item_text(currentlySelected[1]))
	
	openDataBase()
	
	var queryUpdate = "UPDATE seller SET adress ='" + $txtAdressEdit.text + "', passcode ='" + $txtPassCode.text + "'"
	queryUpdate += " WHERE adress = '" + oldAdr + "' and passcode = '" + oldPass + "';"
	
	db.query(queryUpdate)
	db.close_db()
	
	readData()


func _on_btnAddCode_button_up():
	
	openDataBase()
	#var letterString = "0123456789abcdefghijklmopqrstuvwxyz"
	
	var letterString = "0123456789"
	
	var rng = RandomNumberGenerator.new()
	
	var newCode = ""
	
	for i in range(0, 4):
		rng.randomize()
		newCode += letterString[rng.randi_range(0, letterString.length()-1)]
	
	var queryGetCodes = "SELECT code FROM codes"
	
	db.query(queryGetCodes)
	var allCodes = db.query_result
	var allCodesArray = []
	
	for code in allCodes:
		allCodesArray += [code.values()[0]]
	
	if allCodes.find(newCode) == -1 and currentSellerId != null:
		var queryAddCode = "INSERT INTO codes (code, used, win) VALUES ('" + newCode + "','"
		queryAddCode += "0','');"
		
		db.query(queryAddCode)
		
		var queryFindLastCode = "SELECT id FROM codes WHERE code = '" + newCode + "';"
		db.query(queryFindLastCode)
		
		var lastId = db.query_result
		lastId = lastId[0].values()[0]
		print(lastId)
		
		var queryConnect = "INSERT INTO seller_codes (seller_id , code_id) "
		queryConnect += "VALUES ('" + str(currentSellerId) + "', '" + str(lastId) + "');"
		
		db.query(queryConnect)
		db.close_db()
		loadCodes()
	else:
		db.close_db()

func _on_btnProb_button_up():
	var whatRemain = $pnlProb.retrieveRemain()
	if whatRemain == 0:
		$lblErrorRemain.hide()
		var newProbs = $pnlProb.retreiveProbabilities()
		
		openDataBase()
		
		for i in range(0, newProbs.size()):
			var queryUpdateProbs = "UPDATE probabilities SET prob = " + str(newProbs.values()[i]) + " WHERE "
			queryUpdateProbs += "variant = '" + newProbs.keys()[i] + "'"
			
			db.query(queryUpdateProbs)
		
		$lblUpdated.show()
		db.close_db()
	else:
		$lblErrorRemain.show()
		$lblUpdated.hide()
