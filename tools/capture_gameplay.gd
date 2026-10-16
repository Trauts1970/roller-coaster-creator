extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://scenes/main.tscn").instantiate()
 root.size = Vector2i(1280,800)
 root.content_scale_size = Vector2i(ProjectSettings.get_setting("display/window/size/viewport_width",1280),ProjectSettings.get_setting("display/window/size/viewport_height",800))
 root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
 root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
 root.add_child(game)
 await process_frame
 game.running = true
 await create_timer(2.0).timeout
 if game is Node2D: game.queue_redraw()
 await process_frame
 await RenderingServer.frame_post_draw
 var args:=OS.get_cmdline_user_args()
 var destination:=args[0] if args.size()>0 else "res://build/graphics-preview.png"
 DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
 var result = root.get_texture().get_image().save_png(destination)
 print("CAPTURE_RESULT ", result)
 game.queue_free()
 await process_frame
 await process_frame
 quit()
