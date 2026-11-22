extends VehicleBody3D
## Coche con físicas de VehicleBody3D: tracción trasera, dirección delantera, freno.
## Los valores de entrada (throttle, steer, brake_on) los fija el HUD o el test.

const MAX_ENGINE := 2600.0
const MAX_STEER := 0.5       # radianes
const MAX_BRAKE := 45.0

var throttle := 0.0          # 0..1
var steer := 0.0             # -1 izquierda .. 1 derecha
var brake_on := false

var wheels: Array[VehicleWheel3D] = []


func _ready() -> void:
	mass = 1200.0

	# Carrocería
	_add_box(Vector3(1.8, 0.7, 4.0), Vector3(0, 0.75, 0), Color(0.8, 0.2, 0.2), true)
	# Cabina
	_add_box(Vector3(1.6, 0.5, 2.0), Vector3(0, 1.35, -0.2), Color(0.12, 0.14, 0.18), false)

	for p in [Vector3(-0.85, 0.3, -1.4), Vector3(0.85, 0.3, -1.4), Vector3(-0.85, 0.3, 1.4), Vector3(0.85, 0.3, 1.4)]:
		var w := VehicleWheel3D.new()
		w.position = p
		w.use_as_steering = p.z < 0.0
		w.use_as_traction = p.z > 0.0
		w.wheel_radius = 0.38
		w.wheel_rest_length = 0.25
		w.suspension_travel = 0.3
		w.suspension_stiffness = 45.0
		w.suspension_max_force = 6000.0
		w.damping_compression = 0.9
		w.damping_relaxation = 1.1
		w.wheel_friction_slip = 2.5
		w.wheel_roll_influence = 0.3

		var wm := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.38
		cyl.bottom_radius = 0.38
		cyl.height = 0.3
		wm.mesh = cyl
		wm.rotation.z = PI / 2.0
		wm.material_override = _mat(Color(0.08, 0.08, 0.08))
		w.add_child(wm)

		add_child(w)
		wheels.append(w)


func _physics_process(delta: float) -> void:
	var steer_target := steer * MAX_STEER
	for w in wheels:
		if w.use_as_steering:
			w.steering = lerpf(w.steering, steer_target, clampf(delta * 8.0, 0.0, 1.0))
		if w.use_as_traction:
			w.engine_force = throttle * MAX_ENGINE
		w.brake = MAX_BRAKE if brake_on else 0.0


func speed_kmh() -> float:
	return linear_velocity.length() * 3.6


func reset_to(p: Vector3) -> void:
	global_transform = Transform3D(Basis(), p)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO


func _add_box(size: Vector3, pos: Vector3, color: Color, collide: bool) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = _mat(color)
	mi.position = pos
	mi.castShadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(mi)
	if collide:
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		cs.position = pos
		add_child(cs)


func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.6
	return m
