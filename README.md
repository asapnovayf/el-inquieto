# El Inquieto

Arcade fixed shooter 2D inspirado en los juegos de oleadas espaciales clásicos. Proyecto hecho en Godot 4, renderizador Compatibility, resolución base 800 × 600. No requiere assets externos.

## Estructura del proyecto

- `scripts/game/game_controller.gd`: estado, controles, oleadas, proyectiles, colisiones y jefes.
- `scripts/ui/game_renderer.gd`: dibujo de la arena, entidades y pantallas; lee el estado del controlador.
- `scripts/data/game_data.gd`: define personajes, jefes, colores y umbrales.
- `scripts/services/save_store.gd`: carga y guarda récord y personaje elegido.
- `main.tscn`: escena de entrada del juego.

## Ejecutar

1. Abre Godot y elige **Importar**.
2. Selecciona `project.godot` dentro de esta carpeta.
3. Ejecuta el juego con F5.

## Controles

- A/D o flechas izquierda/derecha: mover la nave.
- Espacio: mantener para disparar, tanto en oleadas como contra los jefes.
- C: abrir/cerrar la selección de personaje durante la partida.
- Flechas izquierda/derecha: cambiar personaje en selección.
- Enter o Espacio: empezar desde la pantalla de selección.
- P o Escape: pausar.
- R o Espacio: reiniciar después de perder.

## Personajes y jefes

Puedes elegir entre Goku, Naruto, Mario, Sonic, Link y Samus. Sus retratos pixelados usan formas dibujadas en Godot y la nave cambia su color de acento. Cuatro jefes aparecen al superar los puntajes objetivo: Bowser (800), Ridley (2200), Ganondorf (4000) y Freezer (6500). Derrotarlos otorga puntos y la partida continúa con una nueva oleada.

La dificultad aumenta gradualmente con el tiempo y el puntaje: las formaciones se mueven más rápido y los enemigos disparan más seguido y con más velocidad. Cada jefe tiene patrones propios y un superataque con aviso visual para poder esquivarlo: Bowser lanza una pared de fuego, Ridley hace una embestida cruzada, Ganondorf libera un anillo de proyectiles y Freezer barre la pantalla con rayos que dejan un carril seguro.

## Dirección visual

Fondo espacial #0B0C10, jugador cian #66FCF1, peligros magenta #FF0055, marcador amarillo #FFE608 y acentos verdes #00FF66. El diseño usa formas de baja resolución, estrellas, siluetas claras y halos dibujados para conservar Compatibility.
