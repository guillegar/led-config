extends CanvasLayer
## Controles táctiles (izquierda/derecha, gas/freno, reinicio) y velocímetro.
## Con teclado: flechas o WASD para conducir, Espacio o S para frenar, R para reiniciar.

var car: VehicleBody3D
var enabled := true

var gas_held := false
var brake_held := false
var left_held := false
var right_held := false

var speed_label: Label
var buttons := {}


func _ready() -> void:
	speed_label = Label.new()
	speed_label.add_theme_font_size_override("font_size", 30)
	speed_label.position = Vector2(20, 16)
	add_child(speed_label)

	buttons["left"] = _btn("◀", "left")
	buttons["right"] = _btn("▶", "right")
	buttons["brake"] = _btn("FRENO", "brake")
	buttons["gas"] = _btn("GAS", "gas")
	buttons["reset"] = _btn("VOLVER", "")
	buttons["reset"].pressed.connect(_on_reset)


func _btn(text: String, key: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 90)
	b.focus_mode = Control.FOCUS_NONE
	if key != "":
		b.button_down.connect(func(): _hold(key, true))
		b.button_up.connect(func(): _hold(key, false))
	add_child(b)
	return b


func _hold(key: String, v: bool) -> void:
	match key:
		"gas": gas_held = v
		"brake": brake_held = v
		"left": left_held = v
		"right": right_held = v


func _on_reset() -> void:
	if car:
		car.reset_to(Vector3(26.0, 1.5, 26.0))


func _process(_delta: float) -> void:
	var s := get_viewport().get_visible_rect().size
	buttons["left"].position = Vector2(20, s.y - 110)
	buttons["right"].position = Vector2(160, s.y - 110)
	buttons["brake"].position = Vector2(s.x - 290, s.y - 110)
	buttons["gas"].position = Vector2(s.x - 150, s.y - 110)
	buttons["reset"].position = Vector2(s.x - 150, 16)

	if car == null:
		return
	if enabled:
		car.throttle = 1.0 if (gas_held or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP)) else 0.0
		car.brake_on = brake_held or Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_SPACE)
		var st := 0.0
		if left_held or Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			st -= 1.0
		if right_held or Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			st += 1.0
		car.steer = st
		if Input.is_key_pressed(KEY_R):
			_on_reset()
	speed_label.text = "%d km/h" % int(car.speed_kmh())
