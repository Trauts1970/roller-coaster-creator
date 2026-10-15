extends SceneTree
var failures := 0
func check(ok: bool, message: String) -> void:
 if not ok:
  push_error(message)
  failures += 1
func _init() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.add_child(game)
 await process_frame
 check(game.samples.size()>300,"Scene builds track")
 var panel = game.get_children().filter(func(node): return node is CanvasLayer)[0].get_child(0)
 check(panel.position.y+panel.size.y<=800,"Touch panel fits 800-pixel viewport")
 game.sequence = ["Station","Straight"]
 game.rebuild()
 game.list.select(1)
 game.move_section(-1)
 check(game.sequence[0]=="Straight","Reorder selected section")
 # Preserve any real save around this test.
 var path := "user://track.json"
 var existed := FileAccess.file_exists(path)
 var original := FileAccess.get_file_as_bytes(path) if existed else PackedByteArray()
 game.save_track()
 game.sequence = []
 game.rebuild()
 game.load_track()
 check(game.sequence==["Straight","Station"],"Track save/load round trip")
 var file := FileAccess.open(path,FileAccess.WRITE)
 file.store_string('{"version":1,"sections":["BAD"]}')
 file.close()
 game.load_track()
 check(game.sequence==["Straight","Station"],"Corrupt save preserves current track")
 if existed:
  file = FileAccess.open(path,FileAccess.WRITE)
  file.store_buffer(original)
  file.close()
 else:
  DirAccess.remove_absolute(path)
 game.sequence = game.Track.DEMO.duplicate()
 game.rebuild()
 game.running = true
 for i in range(10000): game._process(1.0/60.0)
 check(not game.running,"Ride reaches endpoint and stops")
 game.ride_button.pressed.emit()
 check(game.riding,"Ride camera toggles")
 game._process(0.016)
 game.queue_free()
 await process_frame
 print("Scene tests: ","PASS" if failures==0 else "FAIL", " (",failures," failures)")
 quit(1 if failures else 0)
