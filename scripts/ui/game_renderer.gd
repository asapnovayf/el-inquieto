class_name GameRenderer
extends Node2D

# Renderer hijo de GameController. Lee el estado del juego, pero solo se ocupa de dibujarlo.
@onready var game: GameController = get_parent() as GameController

# Dibuja la escena por capas según el estado: fondo, HUD, entidades e interfaz.
# Las formas se generan con CanvasItem, por eso no hacen falta sprites externos.
func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameData.SCREEN), GameData.BG)
	for star in game.stars:
		draw_rect(Rect2(Vector2(star.x, star.y), Vector2(star.size, star.size)), Color(0.34, 0.40, 0.47, 0.75))
	_draw_hud()
	if game.game_state == "select":
		_draw_character_select(false)
	elif game.game_state == "playing":
		for enemy in game.enemies:
			_draw_invader(enemy)
		for bullet in game.player_bullets:
			draw_rect(Rect2(bullet.pos - Vector2(2, 9), Vector2(4, 18)), GameData.CYAN)
			draw_rect(Rect2(bullet.pos - Vector2(4, 7), Vector2(8, 12)), Color(0.4, 1.0, 1.0, 0.2))
		for bullet in game.enemy_bullets:
			var radius: float = bullet.get("radius", 5.0)
			draw_rect(Rect2(bullet.pos - Vector2(radius * 0.6, radius), Vector2(radius * 1.2, radius * 2.0)), GameData.RED)
			_draw_danger_glow(bullet.pos, radius * 2.0)
		if game.boss_active:
			_draw_boss()
		_draw_player()
		if game.selecting_hero:
			_draw_character_select(true)
		elif game.paused:
			_draw_overlay("PAUSA", "P / ESC PARA CONTINUAR", "")
		if game.boss_banner_time > 0.0 and game.boss_active:
			draw_rect(Rect2(150, 205, 500, 54), Color(0.18, 0.01, 0.045, 0.88))
			draw_rect(Rect2(150, 205, 500, 54), GameData.RED, false, 2.0)
			draw_string(ThemeDB.fallback_font, Vector2(180, 229), "¡JEFE " + GameData.BOSSES[game.boss_index].name + "!", HORIZONTAL_ALIGNMENT_CENTER, 440, 19, GameData.RED)
			draw_string(ThemeDB.fallback_font, Vector2(180, 249), "ESPACIO: DISPARAR · A/D: ESQUIVAR", HORIZONTAL_ALIGNMENT_CENTER, 440, 12, GameData.YELLOW)
		if game.boss_active and game.boss_super_telegraph > 0.0:
			var warning_alpha := 0.6 + 0.4 * absf(sin(game.game_time * 13.0))
			if game.boss_index == 3:
				for lane in range(10):
					if lane != game.boss_super_lane:
						var lane_x := 80.0 + float(lane) * 71.0
						draw_rect(Rect2(lane_x - 12.0, 328.0, 24.0, 205.0), Color(1.0, 0.0, 0.33, 0.13))
			draw_rect(Rect2(165, 281, 470, 34), Color(0.32, 0.0, 0.06, 0.88))
			draw_rect(Rect2(165, 281, 470, 34), Color(1.0, 0.0, 0.34, warning_alpha), false, 2.0)
			var super_message := "¡SUPERATAQUE! ESQUIVA AHORA"
			if game.boss_index == 0:
				super_message = "BOWSER: MURO DE FUEGO · ESQUIVA"
			elif game.boss_index == 1:
				super_message = "RIDLEY: EMBESTIDA CRUZADA · ESQUIVA"
			elif game.boss_index == 2:
				super_message = "GANONDORF: ANILLO MAGICO · ESQUIVA"
			elif game.boss_index == 3:
				super_message = "FREEZER: RAYOS · BUSCA EL CARRIL LIBRE"
			draw_string(ThemeDB.fallback_font, Vector2(180, 304), super_message, HORIZONTAL_ALIGNMENT_CENTER, 440, 14, GameData.RED)
	elif game.game_state == "game_over":
		for enemy in game.enemies:
			_draw_invader(enemy)
		_draw_player()
		_draw_overlay("FIN DE PARTIDA", "PUNTAJE  %06d" % game.score, "R / ESPACIO PARA REINTENTAR · C CAMBIAR PILOTO")

# Marcador, récord, vidas, barra del jefe y recordatorio de controles.
func _draw_hud() -> void:
	draw_string(ThemeDB.fallback_font, Vector2(30, 32), "1UP", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, GameData.RED)
	draw_string(ThemeDB.fallback_font, Vector2(350, 32), "%06d" % game.score, HORIZONTAL_ALIGNMENT_LEFT, 110, 22, GameData.YELLOW)
	draw_string(ThemeDB.fallback_font, Vector2(620, 30), "RECORD %06d" % game.best_score, HORIZONTAL_ALIGNMENT_LEFT, 150, 12, GameData.MUTED)
	for i in range(game.lives):
		var x := 35.0 + i * 25.0
		draw_colored_polygon(PackedVector2Array([Vector2(x, 53), Vector2(x + 8, 53), Vector2(x + 4, 44)]), GameData.CYAN)
	if game.boss_active:
		var ratio := clampf(float(game.boss_hp) / float(game.boss_max_hp), 0.0, 1.0)
		draw_rect(Rect2(250, 51, 300, 7), Color(0.2, 0.08, 0.12))
		draw_rect(Rect2(250, 51, 300 * ratio, 7), GameData.RED)
		draw_string(ThemeDB.fallback_font, Vector2(350, 73), GameData.BOSSES[game.boss_index].name, HORIZONTAL_ALIGNMENT_CENTER, 100, 11, GameData.YELLOW)
		draw_string(ThemeDB.fallback_font, Vector2(285, 90), "ESPACIO: DISPARAR · A/D: ESQUIVAR", HORIZONTAL_ALIGNMENT_CENTER, 230, 10, GameData.RED)
	draw_string(ThemeDB.fallback_font, Vector2(30, 583), "A/D o FLECHAS: MOVER    ESPACIO: DISPARAR    C: CAMBIAR PERSONAJE    P: PAUSA", HORIZONTAL_ALIGNMENT_LEFT, 740, 11, GameData.MUTED)

func _draw_player() -> void:
	if game.life_invulnerability > 0.0 and int(game.life_invulnerability * 12.0) % 2 == 0:
		return
	var hero: Dictionary = GameData.HEROES[game.selected_hero]
	_draw_hero(Vector2(game.player_x, game.player_y - 18.0), game.selected_hero, 1.35)
	var ship := Vector2(game.player_x, game.player_y + 8.0)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-22, 13), ship + Vector2(-16, -4), ship + Vector2(-5, -10), ship + Vector2(5, -10), ship + Vector2(16, -4), ship + Vector2(22, 13)]), GameData.CYAN)
	draw_rect(Rect2(ship + Vector2(-5, -5), Vector2(10, 10)), hero.accent)
	draw_rect(Rect2(ship + Vector2(-2, 9), Vector2(4, 5)), GameData.YELLOW)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(-12, 6), ship + Vector2(-8, 14), ship + Vector2(-4, 8)]), GameData.YELLOW)
	draw_colored_polygon(PackedVector2Array([ship + Vector2(12, 6), ship + Vector2(8, 14), ship + Vector2(4, 8)]), GameData.YELLOW)

# Retratos pixelados construidos con rectángulos y polígonos; el estilo y los
# colores vienen de GameData para compartirlos entre selección y nave del jugador.
func _draw_hero(center: Vector2, hero_index: int, scale: float) -> void:
	var hero: Dictionary = GameData.HEROES[hero_index]
	var unit := scale * 2.0
	var head := Rect2(center + Vector2(-5.0 * unit, -14.0 * unit), Vector2(10.0 * unit, 9.0 * unit))
	var body := Rect2(center + Vector2(-6.0 * unit, -4.0 * unit), Vector2(12.0 * unit, 10.0 * unit))
	draw_rect(body, hero.outfit)
	draw_rect(Rect2(center + Vector2(-8.0 * unit, -1.0 * unit), Vector2(3.0 * unit, 7.0 * unit)), hero.accent)
	draw_rect(Rect2(center + Vector2(5.0 * unit, -1.0 * unit), Vector2(3.0 * unit, 7.0 * unit)), hero.accent)
	draw_rect(head, hero.skin)
	var style: String = hero.style
	if style == "cap":
		draw_rect(Rect2(center + Vector2(-6.0 * unit, -16.0 * unit), Vector2(12.0 * unit, 3.0 * unit)), hero.hair)
		draw_rect(Rect2(center + Vector2(-5.0 * unit, -19.0 * unit), Vector2(10.0 * unit, 4.0 * unit)), hero.outfit)
	elif style == "headband":
		draw_rect(Rect2(center + Vector2(-6.0 * unit, -17.0 * unit), Vector2(12.0 * unit, 5.0 * unit)), hero.hair)
		draw_rect(Rect2(center + Vector2(-5.0 * unit, -12.0 * unit), Vector2(10.0 * unit, 2.0 * unit)), hero.accent)
		draw_rect(Rect2(center + Vector2(3.0 * unit, -11.0 * unit), Vector2(4.0 * unit, 2.0 * unit)), GameData.CYAN)
	elif style == "helmet":
		draw_rect(Rect2(center + Vector2(-6.0 * unit, -17.0 * unit), Vector2(12.0 * unit, 13.0 * unit)), hero.hair)
		draw_rect(Rect2(center + Vector2(-4.0 * unit, -11.0 * unit), Vector2(8.0 * unit, 3.0 * unit)), hero.accent)
	elif style == "quills":
		draw_colored_polygon(PackedVector2Array([center + Vector2(-5 * unit, -8 * unit), center + Vector2(-11 * unit, -17 * unit), center + Vector2(-2 * unit, -13 * unit), center + Vector2(2 * unit, -20 * unit), center + Vector2(4 * unit, -12 * unit), center + Vector2(10 * unit, -15 * unit), center + Vector2(6 * unit, -6 * unit)]), hero.hair)
	else:
		draw_colored_polygon(PackedVector2Array([center + Vector2(-5 * unit, -9 * unit), center + Vector2(-10 * unit, -18 * unit), center + Vector2(-3 * unit, -15 * unit), center + Vector2(-1 * unit, -22 * unit), center + Vector2(3 * unit, -15 * unit), center + Vector2(7 * unit, -21 * unit), center + Vector2(7 * unit, -11 * unit), center + Vector2(10 * unit, -17 * unit), center + Vector2(6 * unit, -7 * unit)]), hero.hair)
	if style in ["cap", "helmet"]:
		draw_rect(Rect2(center + Vector2(-4.0 * unit, -10.0 * unit), Vector2(2.0 * unit, 2.0 * unit)), Color("201c25"))
		draw_rect(Rect2(center + Vector2(2.0 * unit, -10.0 * unit), Vector2(2.0 * unit, 2.0 * unit)), Color("201c25"))
	else:
		draw_rect(Rect2(center + Vector2(-3.0 * unit, -11.0 * unit), Vector2(2.0 * unit, 2.0 * unit)), Color("201c25"))
		draw_rect(Rect2(center + Vector2(2.0 * unit, -11.0 * unit), Vector2(2.0 * unit, 2.0 * unit)), Color("201c25"))

func _draw_invader(enemy: Dictionary) -> void:
	var p := Vector2(enemy.x, enemy.y)
	var s := 4.0
	var c := GameData.RED
	if enemy.row == 0:
		draw_rect(Rect2(p + Vector2(-2 * s, -2 * s), Vector2(4 * s, 4 * s)), c)
		draw_rect(Rect2(p + Vector2(-4 * s, -s), Vector2(2 * s, 2 * s)), c)
		draw_rect(Rect2(p + Vector2(2 * s, -s), Vector2(2 * s, 2 * s)), c)
		draw_rect(Rect2(p + Vector2(-3 * s, 2 * s), Vector2(2 * s, s)), c)
		draw_rect(Rect2(p + Vector2(s, 2 * s), Vector2(2 * s, s)), c)
	else:
		draw_rect(Rect2(p + Vector2(-3 * s, -2 * s), Vector2(6 * s, s)), c)
		draw_rect(Rect2(p + Vector2(-4 * s, -s), Vector2(8 * s, 2 * s)), c)
		draw_rect(Rect2(p + Vector2(-3 * s, s), Vector2(6 * s, s)), c)
		draw_rect(Rect2(p + Vector2(-5 * s, -s), Vector2(s, 3 * s)), c)
		draw_rect(Rect2(p + Vector2(4 * s, -s), Vector2(s, 3 * s)), c)
	draw_rect(Rect2(p + Vector2(-2 * s, -s), Vector2(s, s)), GameData.BG)
	draw_rect(Rect2(p + Vector2(s, -s), Vector2(s, s)), GameData.BG)

# Dibuja la silueta apropiada según el estilo declarado para el jefe.
func _draw_boss() -> void:
	var boss: Dictionary = GameData.BOSSES[game.boss_index]
	var p := Vector2(game.boss_x, 134.0)
	_draw_danger_glow(p, 62.0)
	var shell := Color("a51645")
	var bright := Color("ff4774")
	var dark := Color("6e1237")
	var style: String = boss.style
	if style == "shell":
		draw_rect(Rect2(p + Vector2(-38, -20), Vector2(76, 45)), GameData.GREEN)
		draw_rect(Rect2(p + Vector2(-29, -27), Vector2(58, 57)), shell)
		draw_rect(Rect2(p + Vector2(-18, -14), Vector2(36, 30)), dark)
		draw_rect(Rect2(p + Vector2(-53, -26), Vector2(15, 9)), bright)
		draw_rect(Rect2(p + Vector2(38, -26), Vector2(15, 9)), bright)
	elif style == "wings":
		draw_colored_polygon(PackedVector2Array([p + Vector2(-19, -4), p + Vector2(-65, -48), p + Vector2(-50, 2), p + Vector2(-73, 33), p + Vector2(-20, 20)]), shell)
		draw_colored_polygon(PackedVector2Array([p + Vector2(19, -4), p + Vector2(65, -48), p + Vector2(50, 2), p + Vector2(73, 33), p + Vector2(20, 20)]), shell)
		draw_rect(Rect2(p + Vector2(-22, -27), Vector2(44, 57)), dark)
		draw_rect(Rect2(p + Vector2(-11, -39), Vector2(22, 20)), bright)
	elif style == "armor":
		draw_rect(Rect2(p + Vector2(-43, -15), Vector2(86, 39)), dark)
		draw_rect(Rect2(p + Vector2(-26, -34), Vector2(52, 57)), shell)
		draw_rect(Rect2(p + Vector2(-43, -34), Vector2(18, 8)), bright)
		draw_rect(Rect2(p + Vector2(25, -34), Vector2(18, 8)), bright)
		draw_rect(Rect2(p + Vector2(-15, -8), Vector2(30, 19)), Color("f2bd91"))
	else:
		draw_rect(Rect2(p + Vector2(-38, -25), Vector2(76, 50)), Color("eee8f5"))
		draw_rect(Rect2(p + Vector2(-27, -37), Vector2(54, 23)), bright)
		draw_rect(Rect2(p + Vector2(-18, -6), Vector2(36, 16)), Color("b898dc"))
		draw_rect(Rect2(p + Vector2(-9, -1), Vector2(6, 4)), GameData.BG)
		draw_rect(Rect2(p + Vector2(4, -1), Vector2(6, 4)), GameData.BG)
	draw_rect(Rect2(p + Vector2(-30, -9), Vector2(8, 5)), Color("ffe6ee"))
	draw_rect(Rect2(p + Vector2(22, -9), Vector2(8, 5)), Color("ffe6ee"))
	if game.boss_hit_flash > 0.0:
		draw_arc(p, 67.0, 0.0, TAU, 36, Color.WHITE, 3.0, true)

func _draw_danger_glow(center: Vector2, radius: float) -> void:
	draw_circle(center, radius, Color(1.0, 0.0, 0.33, 0.06))
	draw_arc(center, radius, 0.0, TAU, 32, Color(1.0, 0.12, 0.38, 0.38), 2.0)

# La misma pantalla sirve antes de empezar y durante la partida; el parámetro
# cambia el texto de la acción disponible.
func _draw_character_select(in_game: bool) -> void:
	draw_rect(Rect2(60, 85, 680, 465), Color(0.015, 0.02, 0.035, 0.96))
	draw_rect(Rect2(60, 85, 680, 465), GameData.CYAN if not in_game else GameData.GREEN, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(200, 126), "ELIGE TU PERSONAJE", HORIZONTAL_ALIGNMENT_CENTER, 400, 23, GameData.CYAN)
	_draw_hero(Vector2(400, 300), game.selected_hero, 4.0)
	draw_colored_polygon(PackedVector2Array([Vector2(355, 367), Vector2(445, 367), Vector2(430, 390), Vector2(370, 390)]), GameData.CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(200, 428), GameData.HEROES[game.selected_hero].name, HORIZONTAL_ALIGNMENT_CENTER, 400, 24, GameData.YELLOW)
	draw_string(ThemeDB.fallback_font, Vector2(200, 452), GameData.HEROES[game.selected_hero].series, HORIZONTAL_ALIGNMENT_CENTER, 400, 13, GameData.MUTED)
	draw_string(ThemeDB.fallback_font, Vector2(170, 488), "◀   ANTERIOR", HORIZONTAL_ALIGNMENT_LEFT, 180, 13, GameData.CYAN)
	draw_string(ThemeDB.fallback_font, Vector2(452, 488), "SIGUIENTE   ▶", HORIZONTAL_ALIGNMENT_LEFT, 180, 13, GameData.CYAN)
	var instruction := "C / ENTER: VOLVER A LA PARTIDA" if in_game else "ENTER / ESPACIO: EMPEZAR"
	draw_string(ThemeDB.fallback_font, Vector2(200, 535), instruction, HORIZONTAL_ALIGNMENT_CENTER, 400, 14, GameData.GREEN)

func _draw_overlay(title: String, subtitle: String, footer: String) -> void:
	draw_rect(Rect2(90, 220, 620, 165), Color(0.01, 0.015, 0.025, 0.92))
	draw_rect(Rect2(90, 220, 620, 165), GameData.RED, false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(180, 275), title, HORIZONTAL_ALIGNMENT_CENTER, 440, 29, GameData.RED)
	draw_string(ThemeDB.fallback_font, Vector2(130, 316), subtitle, HORIZONTAL_ALIGNMENT_CENTER, 540, 15, GameData.YELLOW)
	if footer != "":
		draw_string(ThemeDB.fallback_font, Vector2(130, 352), footer, HORIZONTAL_ALIGNMENT_CENTER, 540, 12, GameData.MUTED)
