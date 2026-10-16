extends Node3D
const Track = preload("res://scripts/track.gd")
var sequence: Array = Track.DEMO.duplicate()
var samples: Array = []
var analysis: Dictionary = {}
var track_root := Node3D.new()
var camera := Camera3D.new()
var car := Node3D.new()
var list := ItemList.new()
var report := Label.new()
var telemetry := Label.new()
var ride_button: Button
var running := false
var riding := false
var distance := 0.0
var index := 0
var orbit := 0.55
var zoom := 145.0
var center := Vector3.ZERO

func _ready() -> void:
 add_child(track_root)
 add_child(camera)
 add_child(car)
 camera.far = 2000
 var sun := DirectionalLight3D.new()
 sun.rotation_degrees = Vector3(-48, -30, 0)
 sun.light_energy = 1.25
 add_child(sun)
 var env := WorldEnvironment.new()
 env.environment = Environment.new()
 env.environment.background_mode = Environment.BG_COLOR
 env.environment.background_color = Color("92bbce")
 env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
 env.environment.ambient_light_color = Color("cad7e0")
 env.environment.ambient_light_energy = 0.65
 add_child(env)
 box(self, Vector3(0,-0.3,-80), Vector3(600,0.5,600), Color("3b6554"))
 box(car, Vector3(0,0.45,0), Vector3(1.6,0.65,2.4), Color("ffb34c"))
 box(car, Vector3(0,0.9,0.65), Vector3(1.5,0.7,0.25), Color("162b42"))
 make_ui()
 rebuild()

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
 var mesh := MeshInstance3D.new()
 var shape := BoxMesh.new()
 shape.size = size
 mesh.mesh = shape
 var material := StandardMaterial3D.new()
 material.albedo_color = color
 material.roughness = 0.65
 mesh.material_override = material
 parent.add_child(mesh)
 mesh.position = pos
 return mesh

func beam(a: Vector3, b: Vector3, width: float, color: Color) -> void:
 if a.distance_to(b) < 0.001:
  return
 var item := box(track_root, (a+b)*0.5, Vector3(width,width,a.distance_to(b)),color)
 item.look_at(b, Vector3.UP if absf((b-a).normalized().y) < 0.99 else Vector3.RIGHT)

func button(parent: Node, title: String, action: Callable) -> Button:
 var b := Button.new()
 b.text = title
 b.custom_minimum_size = Vector2(0,48)
 b.pressed.connect(action)
 parent.add_child(b)
 return b

func make_ui() -> void:
 var layer := CanvasLayer.new()
 add_child(layer)
 var panel := PanelContainer.new()
 panel.position = Vector2(16,16)
 panel.size = Vector2(330,768)
 layer.add_child(panel)
 var v := VBoxContainer.new()
 v.add_theme_constant_override("separation", 6)
 panel.add_child(v)
 var title := Label.new()
 title.text = "ROLLER COASTER\nCREATOR  /  0.1.1"
 title.add_theme_font_size_override("font_size",24)
 v.add_child(title)
 var hint := Label.new()
 hint.text = "AUTO ASSEMBLY • select sections in order"
 hint.add_theme_font_size_override("font_size",14)
 v.add_child(hint)
 var picker := OptionButton.new()
 picker.custom_minimum_size.y = 48
 for kind in Track.CATALOG:
  picker.add_item(kind)
 var add_row := HBoxContainer.new()
 v.add_child(add_row)
 add_row.add_child(picker)
 button(add_row,"＋ Add",func(): sequence.append(picker.get_item_text(picker.selected)); rebuild())
 list.custom_minimum_size = Vector2(310,130)
 list.size_flags_vertical = Control.SIZE_EXPAND_FILL
 v.add_child(list)
 var row := HBoxContainer.new()
 v.add_child(row)
 button(row,"↑",func(): move_section(-1))
 button(row,"↓",func(): move_section(1))
 button(row,"Remove",func():
  if list.is_anything_selected():
   sequence.remove_at(list.get_selected_items()[0]); rebuild())
 button(v,"Test track / restart",func(): distance = 0; index = 0; running = true)
 ride_button = button(v,"Camera: overview",func(): riding = not riding; ride_button.text = "Camera: front seat" if riding else "Camera: overview")
 var saves := HBoxContainer.new()
 v.add_child(saves)
 button(saves,"Save",save_track)
 button(saves,"Load",load_track)
 button(saves,"Demo",func(): sequence = Track.DEMO.duplicate(); rebuild())
 button(saves,"Quit",func(): get_tree().quit())
 report.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 report.custom_minimum_size = Vector2(310,110)
 report.add_theme_font_size_override("font_size",16)
 v.add_child(report)
 telemetry.position = Vector2(365,20)
 telemetry.add_theme_color_override("font_color",Color("102c40"))
 telemetry.add_theme_font_size_override("font_size",22)
 layer.add_child(telemetry)
 var help := Label.new()
 help.text = "A: test   Y: camera   X: add straight   B: stop\nD-pad left/right: orbit   up/down: zoom\nOpen track prototype • manual editor coming later"
 help.position = Vector2(365,700)
 help.add_theme_color_override("font_color",Color("102c40"))
 layer.add_child(help)

func move_section(delta: int) -> void:
 if not list.is_anything_selected(): return
 var source := list.get_selected_items()[0]
 var target := clampi(source+delta,0,sequence.size()-1)
 var item: String = sequence.pop_at(source)
 sequence.insert(target,item)
 rebuild()
 list.select(target)

func rebuild() -> void:
 running = false
 distance = 0
 index = 0
 for child in track_root.get_children():
  track_root.remove_child(child)
  child.queue_free()
 samples = Track.build(sequence)
 analysis = Track.analyze(samples)
 list.clear()
 for i in range(sequence.size()): list.add_item("%02d   %s" % [i+1,sequence[i]])
 center = Vector3.ZERO
 for i in range(samples.size()):
  var p: Vector3 = samples[i].p
  center += p
  if i > 0:
   var prev: Vector3 = samples[i-1].p
   var right: Vector3 = samples[i].t.cross(Vector3.UP).normalized().rotated(samples[i].t, samples[i].get("bank", 0.0))*0.8
   var previous_right: Vector3 = samples[i-1].t.cross(Vector3.UP).normalized().rotated(samples[i-1].t, samples[i-1].get("bank", 0.0))*0.8
   beam(prev-previous_right,p-right,0.12,Color("e5edf0"))
   beam(prev+previous_right,p+right,0.12,Color("e5edf0"))
   if i % 4 == 0: beam(p-right,p+right,0.16,Color("d98940"))
   if i % 16 == 0: beam(Vector3(p.x,0,p.z),p,0.24,Color("263e51"))
 if not samples.is_empty(): center /= samples.size()
 report.text = "%s\nPeak %.0f km/h · vertical %.1f…%.1f g\nLateral %.1f g · %.0f m\nIllustrative model; no engineering certification." % [analysis.outcome,analysis.max_speed*3.6,analysis.min_vertical_g,analysis.max_vertical_g,analysis.max_lateral_g,samples[-1].s if not samples.is_empty() else 0.0]

func _process(delta: float) -> void:
 if samples.size() < 2: return
 if running:
  distance += float(analysis.speeds[mini(index,analysis.speeds.size()-1)])*delta
  while index < samples.size()-2 and samples[index+1].s < distance: index += 1
  if index >= int(analysis.stop_index) or distance >= float(samples[-1].s): running = false
 var a: Dictionary = samples[index]
 var b: Dictionary = samples[mini(index+1,samples.size()-1)]
 var u := clampf((distance-float(a.s))/maxf(0.001,float(b.s-a.s)),0,1)
 car.position = a.p.lerp(b.p,u)
 var forward: Vector3 = a.t.lerp(b.t,u).normalized()
 var bank := lerpf(float(a.get("bank",0.0)),float(b.get("bank",0.0)),u)
 var up := forward.cross(Vector3.UP).normalized().cross(forward).normalized().rotated(forward,bank)
 car.look_at(car.position+forward,up)
 if riding:
  camera.position = car.position + up*1.35 + forward*0.65
  camera.look_at(camera.position+forward*8,up)
 else:
  camera.position = center + Vector3(sin(orbit)*zoom,zoom*0.65,cos(orbit)*zoom)
  camera.look_at(center,Vector3.UP)
 telemetry.text = "%s  |  %.0f km/h  |  %.0f / %.0f m" % ["RUNNING" if running else "READY / STOPPED",float(analysis.speeds[mini(index,analysis.speeds.size()-1)])*3.6 if running else 0.0,distance,samples[-1].s]

func _input(event: InputEvent) -> void:
 if event is InputEventJoypadButton and event.pressed:
  match event.button_index:
   JOY_BUTTON_A: distance = 0; index = 0; running = true
   JOY_BUTTON_Y: ride_button.pressed.emit()
   JOY_BUTTON_X: sequence.append("Straight"); rebuild()
   JOY_BUTTON_B: running = false
   JOY_BUTTON_DPAD_LEFT: orbit -= 0.15
   JOY_BUTTON_DPAD_RIGHT: orbit += 0.15
   JOY_BUTTON_DPAD_UP: zoom = maxf(30,zoom-10)
   JOY_BUTTON_DPAD_DOWN: zoom = minf(350,zoom+10)
 if event is InputEventMouseButton and event.pressed:
  if event.button_index == MOUSE_BUTTON_WHEEL_UP: zoom = maxf(30,zoom-8)
  if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: zoom = minf(350,zoom+8)
 if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): orbit -= event.relative.x*0.008

func save_track() -> void:
 var file := FileAccess.open("user://track.json",FileAccess.WRITE)
 if file == null:
  report.text = "Save failed: unable to open track file."
  return
 file.store_string(JSON.stringify({"version":1,"sections":sequence}))
 report.text = "Track saved. User data is stored outside the install folder."

func load_track() -> void:
 if not FileAccess.file_exists("user://track.json"):
  report.text = "No saved track yet."
  return
 var data = JSON.parse_string(FileAccess.get_file_as_string("user://track.json"))
 if not data is Dictionary or not data.get("sections") is Array or data.get("version") != 1:
  report.text = "Save file is invalid. Current track preserved."
  return
 for kind in data.sections:
  if not kind is String or not Track.CATALOG.has(kind):
   report.text = "Unknown saved section. Current track preserved."
   return
 sequence = data.sections.duplicate()
 rebuild()

