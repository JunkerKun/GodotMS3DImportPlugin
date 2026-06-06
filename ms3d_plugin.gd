# ms3d_plugin.gd
tool
extends EditorPlugin

var importPlugin

func _enter_tree():
	importPlugin = preload("import_ms3d.gd").new()
	add_import_plugin(importPlugin)

func _exit_tree():
	remove_import_plugin(importPlugin)
	importPlugin = null
