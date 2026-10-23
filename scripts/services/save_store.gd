class_name SaveStore
extends RefCounted

# Godot lo almacena en los datos de usuario, no junto a los archivos del juego.
const SAVE_PATH := "user://save.cfg"

# Devuelve valores por defecto si aún no existe un guardado y limita el héroe al catálogo.
static func load_profile(hero_count: int) -> Dictionary:
	var config := ConfigFile.new()
	var profile := {"best_score": 0, "selected_hero": 0}
	if config.load(SAVE_PATH) == OK:
		profile.best_score = int(config.get_value("scores", "best", 0))
		profile.selected_hero = clampi(int(config.get_value("settings", "hero", 0)), 0, hero_count - 1)
	return profile

# Persiste récord y personaje; el progreso de una partida se reinicia al iniciar otra.
static func save_profile(best_score: int, selected_hero: int) -> void:
	var config := ConfigFile.new()
	config.load(SAVE_PATH)
	config.set_value("scores", "best", best_score)
	config.set_value("settings", "hero", selected_hero)
	config.save(SAVE_PATH)
