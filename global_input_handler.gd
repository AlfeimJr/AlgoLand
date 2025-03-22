extends Node

func _process(_delta):
	if DragDropManager.is_dragging:
		DragDropManager.update_drag_position(get_viewport().get_mouse_position())
		
func _input(event):
	if DragDropManager.is_dragging:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
				# Se soltar o botão longe de qualquer slot, cancelar o arrasto
				var found_slot = false
				for slot in get_tree().get_nodes_in_group("item_slots"):
					if slot is ItemSlot and slot.is_hovering:
						found_slot = true
						break
				
				if not found_slot:
					DragDropManager.cancel_drag()
					
		elif event is InputEventKey:
			if event.keycode == KEY_ESCAPE and event.pressed:
				DragDropManager.cancel_drag()
