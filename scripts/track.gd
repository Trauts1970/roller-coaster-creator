extends RefCounted
## Geometric centerline and point-mass model. Metres, seconds, radians.
const STEP := 0.5
const CATALOG := {
 "Station": [12.0, 0.0, 0.0, true],
 "Lift": [90.0, 28.0, 0.0, true],
 "Crest": [18.0, -48.0, 0.0, false],
 "Drop": [14.0, -48.0, 0.0, false],
 "Valley": [20.0, 0.0, 0.0, false],
 "Straight": [18.0, 0.0, 0.0, false],
 "Left turn": [32.0, 0.0, -60.0, false],
 "Right turn": [32.0, 0.0, 60.0, false],
 "Hill": [20.0, 25.0, 0.0, false],
 "Brakes": [25.0, 0.0, 0.0, false]
}
const DEMO := ["Station", "Lift", "Crest", "Drop", "Valley", "Left turn", "Straight", "Brakes"]

static func build(sequence: Array) -> Array:
 var samples: Array = []
 var p := Vector3(0, 3, 0)
 var yaw := 0.0
 var pitch := 0.0
 var distance := 0.0
 samples.append({"p": p, "s": distance, "t": Vector3.FORWARD, "kind": "Station"})
 for kind in sequence:
  if not CATALOG.has(kind):
   return []
  var spec: Array = CATALOG[kind]
  var count := int(ceil(float(spec[0]) / STEP))
  var ds := float(spec[0]) / count
  var start_pitch := pitch
  var target_pitch := deg_to_rad(float(spec[1]))
  var start_yaw := yaw
  for i in range(1, count + 1):
   var u := float(i) / count
   pitch = lerp(start_pitch, target_pitch, u * u * (3.0 - 2.0 * u))
   yaw = start_yaw + deg_to_rad(float(spec[2])) * u
   var tangent := Vector3(sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
   p += tangent * ds
   distance += ds
   samples.append({"p": p, "s": distance, "t": tangent, "kind": kind})
 return samples

static func analyze(samples: Array) -> Dictionary:
 var result := {"outcome": "No track", "traversable": false, "safe": false, "speeds": [], "max_speed": 0.0, "max_vertical_g": 1.0, "min_vertical_g": 1.0, "max_lateral_g": 0.0, "stop_index": 0, "duration": 0.0}
 if samples.size() < 2:
  return result
 var speed := 5.0
 result.speeds.append(speed)
 for i in range(1, samples.size()):
  var a: Dictionary = samples[i - 1]
  var b: Dictionary = samples[i]
  var ds: float = b.s - a.s
  if b.p.y < 0.75:
   result.outcome = "Terrain collision at %.1f m" % b.s
   return result
  var energy: float = speed * speed - 2.0 * 9.81 * (b.p.y - a.p.y) - 2.0 * (0.04 + 0.0015 * speed * speed) * ds
  if b.kind in ["Station", "Lift"] or (b.kind == "Crest" and b.t.y > 0.0):
   energy = maxf(energy, 36.0)
  if energy <= 0.0:
   result.outcome = "Stall at %.1f m" % b.s
   return result
  speed = sqrt(energy)
  if b.kind == "Brakes":
   speed = maxf(2.0, sqrt(maxf(0.0, energy - 4.0 * ds)))
  result.duration += ds / maxf(speed, 0.1)
  var tangent: Vector3 = b.t
  var right := tangent.cross(Vector3.UP).normalized()
  var up := right.cross(tangent).normalized()
  var acceleration: Vector3 = (b.t - a.t) / ds * speed * speed
  var load := (acceleration + Vector3.UP * 9.81) / 9.81
  var vertical := load.dot(up)
  result.max_vertical_g = maxf(result.max_vertical_g, vertical)
  result.min_vertical_g = minf(result.min_vertical_g, vertical)
  result.max_lateral_g = maxf(result.max_lateral_g, absf(load.dot(right)))
  result.max_speed = maxf(result.max_speed, speed)
  result.speeds.append(speed)
  result.stop_index = i
 result.traversable = true
 result.safe = result.max_vertical_g <= 4.5 and result.min_vertical_g >= -1.0 and result.max_lateral_g <= 1.5
 result.outcome = "Traversable • prototype load limits passed" if result.safe else "Traversable • excessive passenger loads"
 return result
