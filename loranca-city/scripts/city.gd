extends Node3D
## Ciudad procedural por bloques. Cada chunk son 3x3 manzanas; se cargan los chunks
## cercanos al objetivo y se descargan los lejanos. Edificios deterministas por semilla.

const PITCH := 52.0    # distancia entre centros de manzana (40 de manzana + 12 de calle)
const BLOCK := 40.0
const CHUNK := 3       # manzanas por lado
const RADIUS := 2      # chunks cargados alrededor del objetivo

var target: Node3D = null
var loaded := {}       # Vector2i -> Node3D (raíz del chunk)

var mat_road: StandardMaterial3D
var mat_walk: StandardMaterial3D
var mat_line: StandardMaterial3D
var bld_mats: Array[StandardMaterial3D] = []


func _ready() -> void:
	mat_road = _mat(Color(0.16, 0.17, 0.19))
	mat_walk = _mat(Color(0.5, 0.48, 0.45))
	mat_line = _mat(Color(0.9, 0.88, 0.8))
	for col in [Color(0.62, 0.5, 0.4), Color(0.45, 0.44, 0.5), Color(0.72, 0.66, 0.55), Color(0.38, 0.42, 0.46), Color(0.6, 0.42, 0.36)]:
		bld_mats.append(_mat(col))
	# Precarga síncrona del entorno inicial para que el coche no caiga al vacío
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var c := Vector2i(dx, dz)
			loaded[c] = _build_chunk(c)


func _process(_delta: float) -> void:
	if target == null:
		return
	var bi := roundi(target.global_position.x / PITCH)
	var bj := roundi(target.global_position.z / PITCH)
	var pc := Vector2i(floori(bi / float(CHUNK)), floori(bj / float(CHUNK)))

	# Como máximo un chunk nuevo por fotograma para no provocar tirones
	var built := 0
	for dx in range(-RADIUS, RADIUS + 1):
		for dz in range(-RADIUS, RADIUS + 1):
			var c := pc + Vector2i(dx, dz)
			if not loaded.has(c) and built < 1:
				loaded[c] = _build_chunk(c)
				built += 1

	for c in loaded.keys():
		if absi(c.x - pc.x) > RADIUS + 1 or absi(c.y - pc.y) > RADIUS + 1:
			loaded[c].queue_free()
			loaded.erase(c)


func _build_chunk(c: Vector2i) -> Node3D:
	var root := Node3D.new()
	add_child(root)

	var span := CHUNK * PITCH
	var cx := c.x * span + PITCH   # centro del chunk
	var cz := c.y * span + PITCH

	# Asfalto y líneas de calle
	_static_box(root, Vector3(span, 0.2, span), mat_road, Vector3(cx, -0.1, cz))
	for k in range(CHUNK + 1):
		var x := (c.x * CHUNK + k - 0.5) * PITCH
		_visual_box(root, Vector3(0.3, 0.02, span), mat_line, Vector3(x, 0.01, cz))
		var z := (c.y * CHUNK + k - 0.5) * PITCH
		_visual_box(root, Vector3(span, 0.02, 0.3), mat_line, Vector3(cx, 0.01, z))

	# Manzanas con edificios
	for bx in range(CHUNK):
		for bz in range(CHUNK):
			var bi := c.x * CHUNK + bx
			var bj := c.y * CHUNK + bz
			var bc := Vector3(bi * PITCH, 0.0, bj * PITCH)
			_static_box(root, Vector3(BLOCK, 0.3, BLOCK), mat_walk, bc + Vector3(0, 0.15, 0))

			var rng := RandomNumberGenerator.new()
			rng.seed = hash("%d_%d_%d_%d" % [c.x, c.y, bi, bj])
			var n := 1 + rng.randi() % 3
			for i in range(n):
				var w := rng.randf_range(9.0, 17.0)
				var d := rng.randf_range(9.0, 17.0)
				var h := rng.randf_range(6.0, 40.0)
				var room_x := (BLOCK - w) * 0.5 - 2.0
				var room_z := (BLOCK - d) * 0.5 - 2.0
				var pos := bc + Vector3(rng.randf_range(-room_x, room_x), h * 0.5 + 0.3, rng.randf_range(-room_z, room_z))
				_static_box(root, Vector3(w, h, d), bld_mats[rng.randi() % bld_mats.size()], pos)
	return root


func _visual_box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _static_box(parent: Node3D, size: Vector3, mat: Material, pos: Vector3) -> void:
	var body := StaticBody3D.new()
	body.position = pos
	parent.add_child(body)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	body.add_child(mi)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m
