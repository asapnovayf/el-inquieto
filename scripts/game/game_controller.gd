class_name GameController
extends Node2D

# Evita que mantener fuego llene la pantalla de proyectiles.
const MAX_PLAYER_BULLETS := 2

# Controlador principal: conserva el estado y coordina la simulación y la entrada.
# El renderer, los datos estáticos y el guardado están separados en módulos propios.

# Estado del mundo. Los enemigos y proyectiles son diccionarios con posición/velocidad
# y propiedades específicas; esto permite crear patrones sin escenas por cada disparo.
var rng := RandomNumberGenerator.new()
var stars: Array[Dictionary] = []
var enemies: Array[Dictionary] = []
var player_bullets: Array[Dictionary] = []
var enemy_bullets: Array[Dictionary] = []
var score := 0
var best_score := 0
var selected_hero := 0
var lives := 3
var game_state := "select"
var selecting_hero := false
var paused := false
var player_x := 400.0
var player_y := 548.0
var player_speed := 310.0
var fire_cooldown := 0.0
var enemy_fire_clock := 1.0
var formation_direction := 1.0
var formation_speed := 24.0
var game_time := 0.0
var life_invulnerability := 0.0
var boss_index := 0
var boss_active := false
var boss_x := 400.0
var boss_direction := 1.0
var boss_hp := 0
var boss_max_hp := 1
var boss_fire_clock := 1.0
var boss_attack_step := 0
var boss_super_clock := 9.0
var boss_super_telegraph := 0.0
var boss_super_lane := 5
var boss_banner_time := 0.0
var boss_hit_flash := 0.0
var hit_flash := 0.0
var player_light: PointLight2D
@onready var renderer: Node2D = $Renderer

# Carga preferencias, prepara el fondo espacial y crea la luz que sigue al jugador.
func _ready() -> void:
	rng.randomize()
	var profile := SaveStore.load_profile(GameData.HEROES.size())
	best_score = profile.best_score
	selected_hero = profile.selected_hero
	_create_stars()
	_setup_player_light()

# Bucle visual por frame. La simulación solo avanza durante una partida activa,
# sin pausa ni menú de selección abierto.
func _process(delta: float) -> void:
	for star in stars:
		star.y += star.speed * delta
		if star.y > GameData.SCREEN.y:
			star.y = 0.0
	hit_flash = maxf(0.0, hit_flash - delta)
	boss_banner_time = maxf(0.0, boss_banner_time - delta)
	boss_hit_flash = maxf(0.0, boss_hit_flash - delta)
	if game_state == "playing" and not paused and not selecting_hero:
		_tick_game(delta)
	if player_light != null:
		player_light.position = Vector2(player_x, player_y - 7.0)
		player_light.color = Color(1.0, 0.04, 0.08) if hit_flash > 0.0 else GameData.CYAN
	renderer.queue_redraw()

# Actualiza la partida en orden: tiempo/entrada, enemigos o jefe, proyectiles y colisiones.
# Después revisa si se alcanzó el umbral de un jefe o si toca crear otra formación.
func _tick_game(delta: float) -> void:
	game_time += delta
	life_invulnerability = maxf(0.0, life_invulnerability - delta)
	fire_cooldown = maxf(0.0, fire_cooldown - delta)
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		player_x -= player_speed * delta
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		player_x += player_speed * delta
	player_x = clampf(player_x, 28.0, 772.0)
	if Input.is_key_pressed(KEY_SPACE) and fire_cooldown <= 0.0 and player_bullets.size() < MAX_PLAYER_BULLETS:
		_fire_player_bullet()
		fire_cooldown = 0.18

	if boss_active:
		_tick_boss(delta)
	else:
		_tick_formation(delta)
		_tick_enemy_fire(delta)
	_tick_bullets(delta)
	_tick_collisions()
	if game_state != "playing":
		return
	if not boss_active and boss_index < GameData.BOSSES.size() and score >= GameData.BOSS_THRESHOLDS[boss_index]:
		_start_boss()
	elif not boss_active and enemies.is_empty():
		_create_formation()
		formation_speed += 7.0

func _create_stars() -> void:
	stars.clear()
	for i in range(85):
		stars.append({"x": rng.randf_range(0.0, GameData.SCREEN.x), "y": rng.randf_range(0.0, GameData.SCREEN.y), "speed": rng.randf_range(5.0, 24.0), "size": rng.randi_range(1, 2)})

# Construye una formación de 4 filas por 9 columnas. Cada enemigo conserva su fila
# para determinar la puntuación que otorga al ser derrotado.
func _create_formation() -> void:
	enemies.clear()
	for row in range(4):
		for col in range(9):
			enemies.append({"x": 126.0 + col * 68.0, "y": 92.0 + row * 38.0, "row": row, "col": col})
	enemy_fire_clock = 0.8

# Mueve la formación de lado a lado. Al tocar un borde, invierte dirección y
# desciende; si alcanza la zona del jugador, se pierde una vida.
func _tick_formation(delta: float) -> void:
	if enemies.is_empty():
		return
	formation_speed = minf(24.0 + game_time * 0.42 + float(score) * 0.012, 105.0)
	var edge_hit := false
	for enemy in enemies:
		enemy.x += formation_direction * formation_speed * delta
		if enemy.x < 40.0 or enemy.x > 760.0:
			edge_hit = true
	if edge_hit:
		formation_direction *= -1.0
		for enemy in enemies:
			enemy.y += 16.0
			if enemy.y >= player_y - 36.0:
				_lose_life(true)
				return

# Elige un enemigo al azar para disparar hacia la posición actual del jugador.
# La presión aumenta gradualmente con el tiempo y el puntaje.
func _tick_enemy_fire(delta: float) -> void:
	enemy_fire_clock -= delta
	if enemy_fire_clock > 0.0 or enemies.is_empty():
		return
	var pressure := minf(game_time * 0.0035 + float(score) * 0.000035, 0.78)
	enemy_fire_clock = maxf(0.30, 1.15 - pressure)
	var shooter: Dictionary = enemies[rng.randi_range(0, enemies.size() - 1)]
	var aim := Vector2(player_x - shooter.x, 1.0).normalized()
	var shot_speed := 210.0 + minf(game_time * 0.75 + float(score) * 0.006, 150.0)
	enemy_bullets.append({"pos": Vector2(shooter.x, shooter.y + 11.0), "vel": aim * shot_speed, "radius": 4.0})

# Cada jefe combina movimiento lateral, disparos regulares y un superataque.
# El superataque se anuncia antes de ejecutarse para dar tiempo a esquivarlo.
func _tick_boss(delta: float) -> void:
	var pressure := minf(game_time * 0.001 + float(score) * 0.00004, 0.7)
	boss_x += boss_direction * (48.0 + boss_index * 10.0 + pressure * 32.0) * delta
	if boss_x < 86.0 or boss_x > 714.0:
		boss_direction *= -1.0
	if boss_super_telegraph > 0.0:
		boss_super_telegraph -= delta
		if boss_super_telegraph <= 0.0:
			_boss_super_attack()
	else:
		boss_super_clock -= delta
		if boss_super_clock <= 0.0:
			boss_super_clock = maxf(6.0, 10.0 - pressure * 3.0)
			boss_super_telegraph = 0.85
			if boss_index == 3:
				boss_super_lane = rng.randi_range(2, 7)
	boss_fire_clock -= delta
	if boss_fire_clock <= 0.0 and boss_super_telegraph <= 0.0:
		boss_attack_step += 1
		var fire_scale := 1.0 + pressure * 0.35
		match boss_index:
			0: # Bowser: alternating aimed fireballs and a three-lane flame spread.
				boss_fire_clock = maxf(0.55, 1.0 - pressure * 0.3)
				if boss_attack_step % 2 == 0:
					_spawn_boss_shot(Vector2(player_x - boss_x, 1.0), 245.0 * fire_scale, 6.0)
				else:
					for angle in [-0.34, 0.0, 0.34]:
						_spawn_boss_shot(Vector2(angle, 1.0), 225.0 * fire_scale, 5.0)
			1: # Ridley: fast crossing dives, alternating diagonals.
				boss_fire_clock = maxf(0.4, 0.82 - pressure * 0.25)
				var dive := -0.62 if boss_attack_step % 2 == 0 else 0.62
				_spawn_boss_shot(Vector2(dive, 1.0), 315.0 * fire_scale, 5.0)
				_spawn_boss_shot(Vector2(-dive * 0.55, 1.0), 270.0 * fire_scale, 4.0)
			2: # Ganondorf: measured aimed bolts, then a wide magic spread.
				boss_fire_clock = maxf(0.48, 0.9 - pressure * 0.28)
				if boss_attack_step % 3 == 0:
					for angle in [-0.48, -0.24, 0.0, 0.24, 0.48]:
						_spawn_boss_shot(Vector2(angle, 1.0), 245.0 * fire_scale, 5.0)
				else:
					_spawn_boss_shot(Vector2(player_x - boss_x, 1.0), 285.0 * fire_scale, 7.0)
			3: # Freezer: rapid frost volleys that widen with each burst.
				boss_fire_clock = maxf(0.32, 0.62 - pressure * 0.2)
				for angle in [-0.42, -0.21, 0.0, 0.21, 0.42]:
					_spawn_boss_shot(Vector2(angle, 1.0), 265.0 * fire_scale, 4.0)
			_: 
				boss_fire_clock = 0.7

func _spawn_boss_shot(direction: Vector2, speed: float, radius: float) -> void:
	var velocity := direction.normalized()
	if velocity.y < 0.2:
		velocity.y = 0.2
		velocity = velocity.normalized()
	enemy_bullets.append({"pos": Vector2(boss_x, 158.0), "vel": velocity * speed, "radius": radius})

# Patrones especiales por jefe: abanico de fuego, embestida cruzada,
# anillo de proyectiles o rayos con un carril seguro.
func _boss_super_attack() -> void:
	match boss_index:
		0: # Bowser: wall of fireballs aimed across the arena.
			for i in range(9):
				var angle := lerpf(-0.72, 0.72, float(i) / 8.0)
				_spawn_boss_shot(Vector2(angle, 1.0), 275.0, 6.0)
		1: # Ridley: two fast diagonal dive volleys.
			for i in range(5):
				var offset := float(i - 2) * 0.16
				_spawn_boss_shot(Vector2(-0.75 + offset, 1.0), 355.0, 5.0)
				_spawn_boss_shot(Vector2(0.75 - offset, 1.0), 355.0, 5.0)
		2: # Ganondorf: expanding ring of magic bolts.
			for i in range(12):
				var angle := TAU * float(i) / 12.0
				enemy_bullets.append({"pos": Vector2(boss_x, 145.0), "vel": Vector2.RIGHT.rotated(angle) * 230.0, "radius": 6.0})
		3: # Freezer: sweeping ice beams with gaps between lanes.
			for lane in range(10):
				if lane == boss_super_lane:
					continue
				var x := 80.0 + float(lane) * 71.0
				enemy_bullets.append({"pos": Vector2(x, 160.0), "vel": Vector2(0.0, 390.0), "radius": 8.0})
	boss_fire_clock = 0.45

# Avanza ambos grupos de proyectiles, elimina los que salen de pantalla y
# resuelve impactos. Las balas del jugador dañan enemigos/jefes; las hostiles
# consumen una vida respetando el breve periodo de invulnerabilidad.
func _tick_bullets(delta: float) -> void:
	for i in range(player_bullets.size() - 1, -1, -1):
		var bullet := player_bullets[i]
		bullet.pos += bullet.vel * delta
		if bullet.pos.y < 38.0:
			player_bullets.remove_at(i)
			continue
		if boss_active and absf(bullet.pos.x - boss_x) < 72.0 and absf(bullet.pos.y - 128.0) < 42.0:
			player_bullets.remove_at(i)
			boss_hp -= 1
			boss_hit_flash = 0.12
			if boss_hp <= 0:
				_defeat_boss()
			continue
		var hit_index := -1
		for j in range(enemies.size() - 1, -1, -1):
			var enemy: Dictionary = enemies[j]
			if absf(bullet.pos.x - enemy.x) < 14.0 and absf(bullet.pos.y - enemy.y) < 12.0:
				hit_index = j
				break
		if hit_index >= 0:
			var enemy: Dictionary = enemies[hit_index]
			enemies.remove_at(hit_index)
			player_bullets.remove_at(i)
			score += 60 if enemy.row == 0 else 40
			continue
		player_bullets[i] = bullet

	for i in range(enemy_bullets.size() - 1, -1, -1):
		var bullet := enemy_bullets[i]
		bullet.pos += bullet.vel * delta
		if bullet.pos.y > GameData.SCREEN.y + 12.0 or bullet.pos.y < -12.0 or bullet.pos.x < -12.0 or bullet.pos.x > GameData.SCREEN.x + 12.0:
			enemy_bullets.remove_at(i)
			continue
		if life_invulnerability <= 0.0 and absf(bullet.pos.x - player_x) < 19.0 and absf(bullet.pos.y - player_y) < 20.0:
			enemy_bullets.remove_at(i)
			_lose_life(false)
			if game_state != "playing":
				return
		else:
			enemy_bullets[i] = bullet

func _tick_collisions() -> void:
	if not boss_active:
		for enemy in enemies:
			if enemy.y > player_y - 25.0:
				_lose_life(true)
				return

func _fire_player_bullet() -> void:
	var start := Vector2(player_x, player_y - 24.0)
	player_bullets.append({"pos": start, "vel": Vector2.UP * 560.0})

# Centraliza el daño. Los choques con la formación son instantáneos; los disparos
# respetan la invulnerabilidad temporal para evitar perder varias vidas de golpe.
func _lose_life(instant: bool) -> void:
	if not instant and life_invulnerability > 0.0:
		return
	lives -= 1
	hit_flash = 0.2
	life_invulnerability = 1.0
	player_x = 400.0
	if lives <= 0:
		game_state = "game_over"
		if score > best_score:
			best_score = score
		_save_data()

# Sustituye la oleada por el jefe correspondiente y limpia proyectiles antiguos,
# así el encuentro comienza sin amenazas residuales de la formación previa.
func _start_boss() -> void:
	boss_active = true
	boss_hp = GameData.BOSSES[boss_index].hp
	boss_max_hp = boss_hp
	boss_x = 400.0
	boss_direction = 1.0
	boss_fire_clock = 0.25
	boss_attack_step = 0
	boss_super_clock = maxf(6.0, 10.0 - minf(game_time * 0.001 + float(score) * 0.00004, 0.7) * 3.0)
	boss_super_telegraph = 0.0
	boss_banner_time = 2.4
	enemies.clear()
	enemy_bullets.clear()
	player_bullets.clear()

# Da la recompensa, avanza al siguiente jefe y prepara una nueva oleada.
func _defeat_boss() -> void:
	score += 500 + boss_index * 250
	boss_index += 1
	boss_active = false
	enemy_bullets.clear()
	player_bullets.clear()
	_create_formation()

# Delega el guardado para que el controlador no dependa de los detalles del archivo.
func _save_data() -> void:
	SaveStore.save_profile(best_score, selected_hero)

func _change_hero(direction: int) -> void:
	selected_hero = posmod(selected_hero + direction, GameData.HEROES.size())
	_save_data()

# Reinicia variables de partida y prepara la primera formación sin borrar
# el récord ni la selección persistente del personaje.
func _new_game() -> void:
	score = 0
	lives = 3
	player_x = 400.0
	fire_cooldown = 0.0
	formation_direction = 1.0
	formation_speed = 24.0
	game_time = 0.0
	boss_index = 0
	boss_active = false
	boss_hp = 0
	boss_attack_step = 0
	boss_super_clock = 9.0
	boss_super_telegraph = 0.0
	paused = false
	selecting_hero = false
	player_bullets.clear()
	enemy_bullets.clear()
	_create_formation()
	game_state = "playing"

# Crea una luz radial procedimental; no necesita textura externa.
func _setup_player_light() -> void:
	player_light = PointLight2D.new()
	var light_texture := GradientTexture2D.new()
	light_texture.width = 128
	light_texture.height = 128
	light_texture.fill = GradientTexture2D.FILL_RADIAL
	light_texture.fill_from = Vector2(0.5, 0.5)
	light_texture.fill_to = Vector2(0.5, 0.0)
	var gradient := Gradient.new()
	gradient.set_color(0, Color(1.0, 1.0, 1.0, 0.42))
	gradient.set_color(1, Color(1.0, 1.0, 1.0, 0.0))
	light_texture.gradient = gradient
	player_light.texture = light_texture
	player_light.color = GameData.CYAN
	player_light.energy = 0.8
	player_light.texture_scale = 1.45
	player_light.shadow_enabled = false
	player_light.position = Vector2(player_x, player_y - 7.0)
	add_child(player_light)

# Gestiona acciones de una sola pulsación (menús, pausa y cambios de personaje).
# El movimiento y el disparo mantenido se leen en _tick_game.
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if game_state == "select":
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_change_hero(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_change_hero(1)
		elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE:
			_new_game()
	elif game_state == "game_over":
		if event.keycode == KEY_R or event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_new_game()
		elif event.keycode == KEY_C:
			game_state = "select"
	elif selecting_hero:
		if event.keycode == KEY_LEFT or event.keycode == KEY_A:
			_change_hero(-1)
		elif event.keycode == KEY_RIGHT or event.keycode == KEY_D:
			_change_hero(1)
		elif event.keycode == KEY_C or event.keycode == KEY_ENTER or event.keycode == KEY_ESCAPE:
			selecting_hero = false
	elif event.keycode == KEY_C:
		selecting_hero = true
	elif event.keycode == KEY_P or event.keycode == KEY_ESCAPE:
		paused = not paused
