class_name ResourceList

enum ResourceKind { Mana, Nutrition }

var elements : Array[ResourceElement]

func _init(resourceList : Array[ResourceElement] = []):
	elements = resourceList

func add(resource : ResourceElement):
	var match_resource = match_element(resource)
	if match_resource != null:
		match_resource.amount += resource.amount
		return true
	elements.append(resource)
	return false

func match_element(resource : ResourceElement):
	for element in elements: 
		if element.color == resource.color and element.kind == resource.kind:
			return element
	return null

func combine(other : ResourceList):
	for element in other.elements:
		add(element)
		
func subtract(resource : ResourceElement):
	var match_resource = match_element(resource)
	if match_resource != null:
		match_resource.amount -= resource.amount
		if match_resource.amount == 0:
			elements.erase(match_resource)
		return true
	return false

func check_coverage(other : ResourceList, exact := false):
	for element in other.elements:
		var own_element = match_element(element)
		if own_element == null or own_element.amount < element.amount or (exact and own_element.amount > element.amount):
			return false
	return true

func total():
	var sum := 0
	for element in elements:
		sum += element.amount
	return sum

func reduce(resourceList : ResourceList):
	for element in resourceList.elements:
		if not subtract(element):
			print("something went wrong, reduced ResourceList %s by element with kind %s color %s amount %d which didnt exist" % [self.to_string(), element.kind, element.color, element.amount])
	
class ResourceElement:
	var kind : ResourceKind
	var color : Card.CardColor
	var amount : int
	
	func _init(_kind : ResourceKind, _color : Card.CardColor, _amount : int):
		kind = _kind
		color = _color
		amount = _amount
	
	func get_text():
		var resource_kind = "M"
		if kind == ResourceKind.Nutrition:
			resource_kind = "N"
		return "%d%s" % [amount, resource_kind]
	
	func get_rich_text():
		var element_text = get_text()
		match color:
			Card.CardColor.Yellow:
				element_text = "[color=yellow]%s[/color]" % element_text
			Card.CardColor.Blue:
				element_text = "[color=blue]%s[/color]" % element_text
			Card.CardColor.Green:
				element_text = "[color=green]%s[/color]" % element_text
			Card.CardColor.Red:
				element_text = "[color=red]%s[/color]" % element_text
			Card.CardColor.Black:
				element_text = "[color=black]%s[/color]" % element_text
			Card.CardColor.White:
				element_text = "[color=white]%s[/color]" % element_text
		return element_text
