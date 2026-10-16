extends SceneTree

func _initialize() -> void:
    DirAccess.make_dir_recursive_absolute("res://build/linux")
    var file := FileAccess.open("res://build/linux/THIRD_PARTY_NOTICES.txt",FileAccess.WRITE)
    if file == null:
        printerr("FAIL: cannot write third-party notices")
        quit(1)
        return
    file.store_string("ROLLER COASTER CREATOR — GODOT ENGINE AND BUNDLED THIRD-PARTY NOTICES\n\n")
    file.store_string(Engine.get_license_text() + "\n\n")
    file.store_string("BUNDLED COMPONENT COPYRIGHT INFORMATION\n\n")
    file.store_string(JSON.stringify(Engine.get_copyright_info(),"  ") + "\n\n")
    var licenses := Engine.get_license_info()
    var names := licenses.keys()
    names.sort()
    for name: String in names:
        file.store_string("\n========== " + name + " ==========\n\n" + str(licenses[name]) + "\n")
    file.close()
    print("THIRD-PARTY NOTICES WRITTEN")
    quit()

