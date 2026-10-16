extends SceneTree
const Track = preload("res://scripts/track.gd")
var failures := 0
func check(condition: bool, message: String) -> void:
 if not condition:
  push_error(message)
  failures += 1
func _init() -> void:
 var demo := Track.build(Track.DEMO)
 check(demo.size() > 300,"Demo must contain sampled geometry")
 for i in range(1,demo.size()):
  check(absf(demo[i].p.distance_to(demo[i-1].p)-0.5)<0.001,"Continuous half-metre joints")
 var result := Track.analyze(demo)
 print("DEMO: ", result.outcome, " peak=", result.max_speed, " m/s")
 check(result.traversable,"Demo must reach endpoint")
 check(result.safe,"Default demo must pass prototype load limits")
 var banked := Track.build(["Station","Lift","Crest","Drop","Valley","Banked left"])
 var unbanked := banked.duplicate(true)
 for sample in unbanked: sample.bank = 0.0
 check(Track.analyze(banked).max_lateral_g < Track.analyze(unbanked).max_lateral_g,"Banking reduces lateral loads on identical geometry")
 check(absf(banked[-1].bank)<0.001,"Bank returns upright at section joint")
 var opposite := Track.build(["Banked right"])
 check(opposite[opposite.size()/2].bank > 0,"Right turn banks in opposite direction")
 check(result.speeds.size()==demo.size(),"Every reachable sample needs a speed")
 check(result.max_speed>10,"Gravity must accelerate cart")
 check(not Track.analyze(Track.build(["Hill","Hill","Hill"])).traversable,"Unpowered climb must stall")
 check(Track.analyze(Track.build(["Drop","Drop"])).outcome.begins_with("Terrain"),"Below-ground track must fail")
 check(not Track.analyze([]).traversable,"Empty track cannot pass")
 check(Track.build(["unknown"]).is_empty(),"Reject unknown section")
 var turn := Track.build(["Straight","Left turn"])
 check(turn[-1].t.x < -0.8,"Left turn must turn left")
 print("Track tests: ","PASS" if failures == 0 else "FAIL", " (",failures," failures)")
 quit(1 if failures else 0)

