class_name Field extends Node2D

var rows := 0
var colums := 0
var cells : Array[Array]
const CELLWIDTHFACTOR = sqrt(12) / 4.0
const CELLHEIGHTFACTOR = 3.0 / 4.0
@export var cellradius := 130.0
var fieldpreset : Dictionary
var middle : Vector2

func initialize(fieldtemplate_key : String):
	fieldpreset = Templates.field_templates[fieldtemplate_key]
	rows = fieldpreset.dimensions[1]
	colums = fieldpreset.dimensions[0]
	var celldiameter = 2 * cellradius
	var row_offset := Vector2(0,0)
	var column_offset : Vector2
	for row in range(rows):
		column_offset = Vector2(0,0)
		var row_array = []
		for column in range(colums):
			var celltype = fieldpreset.types[row][column]
			var cell = Cell.new(row_offset + column_offset, celldiameter * 0.99, row, column, celltype[0], celltype[1], celltype[2])
			row_array.append(cell)
			add_child(cell)
			column_offset += Vector2(CELLWIDTHFACTOR * celldiameter, 0)
		row_offset += Vector2(0, CELLHEIGHTFACTOR * celldiameter)
		if row % 2 != 0:
			row_offset += Vector2(CELLWIDTHFACTOR * cellradius, 0)
		else:
			row_offset += Vector2(CELLWIDTHFACTOR * -cellradius, 0)
		cells.append(row_array)
	middle = (row_offset + column_offset)

func get_neighbors(x_index : int, y_index : int):
	var lower_x : int = x_index - y_index % 2
	var upper_x : int = lower_x + 1
	var neighbors : Array[Cell] = []
	if y_index > 0:
		if lower_x >= 0:
			neighbors.append(cells[y_index - 1][lower_x])
		if upper_x < len(cells[y_index - 1]):
			neighbors.append(cells[y_index - 1][upper_x])
	if x_index > 0:
		neighbors.append(cells[y_index][x_index - 1])
	if y_index < len(cells) and x_index < len(cells[y_index]) - 1:
		neighbors.append(cells[y_index][x_index + 1])
	if y_index < len(cells) - 1:
		if lower_x >= 0:
			neighbors.append(cells[y_index + 1][lower_x])
		if upper_x < len(cells[y_index + 1]):
			neighbors.append(cells[y_index + 1][upper_x])
	return neighbors

func get_neighbor_cells(cell : Cell, fieldcells_only = true):
	var neighbors : Array[Cell] = get_neighbors(cell.grid_column, cell.grid_row)
	if fieldcells_only:
		neighbors = neighbors.filter(func(cell : Cell): return cell.cell_type == Cell.CellType.Field)
	return neighbors

func get_cells_in_distance(search_cells : Array[Cell], distance : int, skip_unwalkable = true):
	var return_cells : Array[Cell] = search_cells
	var new_cells = search_cells
	for step in range(distance):
		var step_cells : Array[Cell] = []
		for new_cell in new_cells:
			step_cells.append_array(get_neighbor_cells(new_cell, not skip_unwalkable).filter(func(cell : Cell): return cell not in step_cells))
		new_cells = step_cells.filter(func(cell : Cell): return cell not in return_cells)
		return_cells.append_array(new_cells)
	return_cells = return_cells.filter(func(cell : Cell): return cell.cell_type == Cell.CellType.Field)
	return return_cells
