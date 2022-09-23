extends Panel

var arraySliders = []

class sliderRow:
	var sliderObj
	var lbl
	var lblValue

func inputProb(dictProb):
	for i in range(0, dictProb.size()):
		var newSliderRow = sliderRow.new()
		
		var newLabel = Label.new()
		add_child(newLabel)
		newLabel.rect_position = $lblAll.rect_position
		newLabel.rect_position.y = $lblAll.rect_position.y + (i+1)*25
		newLabel.text = dictProb.keys()[i]
		newLabel.theme = load("res://style/new_theme.tres")
		
		var newLabelValue = Label.new()
		add_child(newLabelValue)
		newLabelValue.rect_position = $lblAllValue.rect_position
		newLabelValue.rect_position.y = $lblAllValue.rect_position.y + (i+1)*25
		newLabelValue.text = str(dictProb.values()[i])
		
		var newSlider = HSlider.new()
		add_child(newSlider)
		newSlider.rect_position = $sldAll.rect_position
		newSlider.rect_position.y = $sldAll.rect_position.y + (i+1)*25
		newSlider.rect_size = $sldAll.rect_size
		newSlider.value = dictProb.values()[i]
		newSlider.connect("value_changed", self, "changeLabelValue", [newLabelValue])
		
		newSliderRow.sliderObj = newSlider
		newSliderRow.lbl = newLabel
		newSliderRow.lblValue = newLabelValue
		
		arraySliders += [newSliderRow]

func changeLabelValue(sliderValue, label):
	label.text = str(sliderValue)
	
	var allProbs = 0
	
	for sliderRow in arraySliders:
		allProbs += sliderRow.sliderObj.value
	
	allProbs = 100 - allProbs
	$sldAll.value = allProbs
	$lblAllValue.text = str(allProbs)
	

func retrieveRemain():
	return int($lblAllValue.text)

func retreiveProbabilities():
	var returningDict = {}
	
	for row in arraySliders:
		returningDict[row.lbl.text] = int(row.lblValue.text)
	return returningDict






func _ready():
	pass # Replace with function body.



