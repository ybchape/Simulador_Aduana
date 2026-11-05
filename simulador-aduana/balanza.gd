class_name Balanza
extends Node3D

@onready var label_peso: Label3D = $Label3D

var peso_en_balanza: float = 0.0

func _ready() -> void:
	if label_peso:
		label_peso.text = ""
	
	# Usamos CallDeferred para asegurarnos de que la escena principal ya esté completamente cargada en el árbol
	call_deferred("_pesar_caja_actual")

func _pesar_caja_actual() -> void:
	var caja_encontrada: Node3D = null
	var escena_principal = get_tree().current_scene

	if escena_principal:
		caja_encontrada = _buscar_caja_recursiva(escena_principal)

	if caja_encontrada:
		var script_caja = caja_encontrada.get_node_or_null("caja_interactiva")
		var nodo_objetivo = script_caja if script_caja else caja_encontrada
		
		var pedido = null
		if "info" in nodo_objetivo and nodo_objetivo.info:
			pedido = nodo_objetivo.info
		elif "pedido_asociado" in nodo_objetivo and nodo_objetivo.pedido_asociado:
			pedido = nodo_objetivo.pedido_asociado
		elif "pedido" in nodo_objetivo and nodo_objetivo.pedido:
			pedido = nodo_objetivo.pedido

		if pedido and "peso_kg" in pedido:
			peso_en_balanza = pedido.peso_kg
			if label_peso:
				label_peso.text = "%.3f kg" % peso_en_balanza
				label_peso.visible = true
			print("¡Peso real medido en balanza: ", peso_en_balanza, " kg!")
			return

	if label_peso:
		label_peso.text = "Error"
	print("No se pudo extraer el recurso de peso de la caja activa.")

func _buscar_caja_recursiva(nodo: Node) -> Node:
	if nodo == null:
		return null
		
	if nodo.has_node("caja_interactiva") or "pedido" in nodo or "info" in nodo:
		if nodo.name.to_lower().contains("caja") or nodo.has_node("caja_interactiva"):
			return nodo
			
	for hijo in nodo.get_children():
		var encontrada = _buscar_caja_recursiva(hijo)
		if encontrada:
			return encontrada
			
	return null
