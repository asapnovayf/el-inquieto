class_name GameData
extends RefCounted

# Catálogo de valores estáticos compartidos; no contiene estado mutable de una partida.

const SCREEN := Vector2(800, 600)
const BG := Color("0b0c10")
const CYAN := Color("66fcf1")
const RED := Color("ff0055")
const YELLOW := Color("ffe608")
const GREEN := Color("00ff66")
const MUTED := Color("89919f")
# Apariencia y metadatos usados por el selector, el piloto y la nave.
const HEROES := [
	{"name": "GOKU", "series": "DRAGON BALL", "hair": Color("171723"), "skin": Color("f2bd91"), "outfit": Color("f28322"), "accent": Color("2875e8"), "style": "spikes"},
	{"name": "NARUTO", "series": "NARUTO", "hair": Color("f3c736"), "skin": Color("f4c69b"), "outfit": Color("f07822"), "accent": Color("2a79c5"), "style": "headband"},
	{"name": "MARIO", "series": "SUPER MARIO", "hair": Color("6a321b"), "skin": Color("f0bc8c"), "outfit": Color("df2d37"), "accent": Color("3154b8"), "style": "cap"},
	{"name": "SONIC", "series": "SONIC THE HEDGEHOG", "hair": Color("1678ed"), "skin": Color("f3c392"), "outfit": Color("1678ed"), "accent": Color("e43139"), "style": "quills"},
	{"name": "LINK", "series": "THE LEGEND OF ZELDA", "hair": Color("e8c65a"), "skin": Color("f1c49c"), "outfit": Color("29a766"), "accent": Color("c33b39"), "style": "cap"},
	{"name": "SAMUS", "series": "METROID", "hair": Color("ff9b25"), "skin": Color("f0c28a"), "outfit": Color("e87d24"), "accent": Color("ffe45e"), "style": "helmet"}
]
# Orden de encuentros: coincide con BOSS_THRESHOLDS y boss_index del controlador.
const BOSSES := [
	{"name": "BOWSER", "title": "REY DE LOS KOOPAS", "style": "shell", "hp": 12},
	{"name": "RIDLEY", "title": "DEPREDADOR GALACTICO", "style": "wings", "hp": 18},
	{"name": "GANONDORF", "title": "LORD DEL MAL", "style": "armor", "hp": 24},
	{"name": "FREEZER", "title": "EMPERADOR DEL UNIVERSO", "style": "alien", "hp": 32}
]
const BOSS_THRESHOLDS := [800, 2200, 4000, 6500]
