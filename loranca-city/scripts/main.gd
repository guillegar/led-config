extends Node3D
## Punto de entrada: monta el entorno, el coche, la ciudad, la cámara y el HUD.
## Con el argumento --smoke (tras "--") ejecuta una prueba automática y termina.

const CAR_SCRIPT := preload("res://scripts/car.gd")
const CITY_SCRIPT := preload("res://scripts/city.gd")
const HUD_SCRIPT := preload("res://scripts/hud.gd")

const SPAWN := Vector3(26.0, 1.5, 26.0)  # cruce de calles, sobre la carretera

var car: VehicleBody3D
var city: Node3D
var cam: Camera3D
var hud: CanvasLayer

var smoke := false
var frames := 0


func _ready() -> void:
	smoke = "--smoke" in OS.get_cmdline_user_args()

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.62, 0.8)  # cielo de atardecer
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.65, 0.8)
	env.ambient_light_energy = 0.6
	env.fog_enabled = true
	env.fog_light_color = Color(0.55, 0.62, 0.8)
	env.fog_density = 0.003
	env_node.environment = env
	add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 35, 0)
	sun.shadow_enabled = true
	add_child(sun)

	city = Node3D.new()
	city.set_script(CITY_SCRIPT)
	add_child(city)

	car = VehicleBody3D.new()
	car.set_script(CAR_SCRIPT)
	add_child(car)
	car.position = SPAWN

	city.target = car

	cam = Camera3D.new()
	add_child(cam)
	cam.current = true
	cam.global_position = SPAWN + Vector3(0, 3, 7)

	hud = CanvasLayer.new()
	hud.set_script(HUD_SCRIPT)
	add_child(hud)
	hud.car = car
	hud.enabled = not smoke


func _process(delta: float) -> void:
	var t := car.global_transform
	# basis.z apunta hacia atrás del coche (el frente es -Z)
	var target := t.origin + t.basis.z * 7.0 + Vector3.UP * 3.0
	cam.global_position = cam.global_position.lerp(target, 1.0 - exp(-6.0 * delta))
	cam.look_at(t.origin + Vector3.UP * 1.0, Vector3.UP)


func _physics_process(_delta: float) -> void:
	if car.global_position.y < -10.0:
		car.reset_to(SPAWN)

	if not smoke:
		return
	frames += 1
	if frames == 5:
		car.throttle = 1.0
	if frames == 240:
		var v := car.linear_velocity.length()
		var ok := v > 5.0 and car.global_position.y > -1.0 and city.loaded.size() > 0
		print("SMOKE speed=%.2f m/s chunks=%d pos=%s" % [v, city.loaded.size(), str(car.global_position)])
		print("SMOKE ", "OK" if ok else "FAIL")
		get_tree().quit(0 if ok else 1)
