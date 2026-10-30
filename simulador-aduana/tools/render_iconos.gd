extends Node

## Herramienta de desarrollo: renderiza modelos 3D a iconos PNG cuadrados con
## fondo transparente, para usarlos como iconos 2D del inventario.
##
## CÓMO USARLA:
##   1. Agregá una entrada a TRABAJOS con el modelo (.glb/.gltf/.tscn) y el PNG
##      de salida.
##   2. Abrí y ejecutá la escena res://tools/render_iconos.tscn (F6).
##   3. El PNG se guarda en la ruta "salida" (sobreescribe si ya existe).
##
## Así los iconos del inventario siempre coinciden con los modelos reales.

# Lista de trabajos: cada entrada es un modelo y el PNG de icono de salida.
const TRABAJOS: Array = [
	{"modelo": "res://assets/escaner/pistol_scanner_godot.glb", "salida": "res://assets/generated/icono_escaner.png"},
	{"modelo": "res://assets/cuter/boxcutter.obj.glb", "salida": "res://assets/generated/icono_cuter.png"},
]

func _ready() -> void:
	for t in TRABAJOS:
		await _renderizar(t["modelo"], t["salida"], 320)
	await get_tree().create_timer(0.3).timeout
	get_tree().quit()


func _renderizar(modelo_path: String, salida: String, tam: int) -> void:
	var vp := SubViewport.new()
	vp.size = Vector2i(tam, tam)
	vp.transparent_bg = true
	vp.own_world_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)

	var modelo: Node3D = (load(modelo_path) as PackedScene).instantiate()
	vp.add_child(modelo)
	# Vista 3/4 del modelo.
	modelo.rotate_y(deg_to_rad(-35.0))

	var caja := _aabb_de(modelo)
	var centro := caja.get_center()
	var diagonal := caja.size.length()
	var cam := Camera3D.new()
	cam.fov = 35.0
	var dist: float = (diagonal * 0.5) / tan(deg_to_rad(cam.fov * 0.5)) * 1.2
	cam.position = centro + Vector3(0.55, 0.5, 1.0).normalized() * dist
	vp.add_child(cam)
	cam.look_at(centro, Vector3.UP)
	cam.current = true

	var luz := DirectionalLight3D.new()
	luz.rotation_degrees = Vector3(-50, -40, 0)
	luz.light_energy = 1.4
	vp.add_child(luz)
	var luz2 := DirectionalLight3D.new()
	luz2.rotation_degrees = Vector3(25, 160, 0)
	luz2.light_energy = 0.7
	vp.add_child(luz2)

	var entorno := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(1, 1, 1)
	env.ambient_light_energy = 0.9
	entorno.environment = env
	vp.add_child(entorno)

	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = vp.get_texture().get_image()
	img.save_png(salida)
	print("RENDER_OK path=", salida, " size=", img.get_size(), " centro=", centro, " diag=", diagonal)


func _aabb_de(raiz: Node) -> AABB:
	var resultado := AABB()
	var primera := true
	var pila: Array[Node] = [raiz]
	while not pila.is_empty():
		var n: Node = pila.pop_back()
		if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
			var a: AABB = (n as MeshInstance3D).transform * (n as MeshInstance3D).mesh.get_aabb()
			if primera:
				resultado = a
				primera = false
			else:
				resultado = resultado.merge(a)
		for c in n.get_children():
			pila.append(c)
	return resultado