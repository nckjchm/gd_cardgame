class_name CardPlaceholder extends Control

signal data_drop_received(recipient : CardPlaceholder, data)

func _can_drop_data(at_position, data):
	print("hovering")
	return true

func _drop_data(at_position, data):
	print("data drop received in placeholder")
	data_drop_received.emit(self, data)
