class_name CardPlaceholder extends Control

signal data_drop_received(recipient : CardPlaceholder, data)

func _can_drop_data(at_position, data):
	return true

func _drop_data(at_position, data):
	data_drop_received.emit(self, data)
