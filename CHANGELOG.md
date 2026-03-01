# 📑 Bunkers Anywhere - Historial de Cambios (Changelog)

### ✅ V 1.0.0 (Release Actual - Fix B42)

*   **🔧 Integración del Bunker Kit (Menús Contextuales):** Se permite desmantelar escaleras vanilla e instalar el kit con menús desplegables 100% operativos usando "Instalar Kit de Bunker".
*   **💻 Movilidad y Animación Reconstruidas:** 
    *   Nuevo sistema de _TimedActions_ genérico. 
    *   Teletransportarse, instalar y desinstalar ahora obligan al jugador a caminar a la casilla exacta de la trampilla antes de iniciar (`luautils.walk()`) con un retraso ultra-rápido calibrado a **0.5s** para subir o bajar 
    *   Se agregó la animación de agacharse (_"Loot Low"_) y sonidos de carpintería para maximizar el realismo de usar la escotilla.
*   **🔘 Interacción Rápida con la tecla "E":** Al pulsar la tecla genérica de interactuar del juego estando encima o junto a un búnker, el jugador usará su mecanismo inteligente para ingresar a las profundidades (Planta Baja Z+0 <~> Z-1 Sotano) automáticamente al instante y sin clicks adicionales.
*   **🏗️ Generación Permanente de Suelos:** Modificada la física de inserción de Chunk (guardados duros, `IsoGridSquare.new`, y `flagForHotSave`). Los agujeros dejados por las escaleras originales que se transformaban en zonas al vacío tras recargar partida ahora permanecen sólidamente parcheados por un piso de tablones de madera oficial (`carpentry_02_57`) que durará para siempre, inclusive apagando el servidor Multijugador.
*   **🎒 Distribuición del Botín:** El Kit de Bunker ya no es exclusivo de los paneles de administrador, logrando que el juego los introduzca de forma inmersiva y con un **5% de drop rate** en las tablas de: Ferreterías (StoreTools/Gigamart), Zonas Militares (Surplus), Coches Pequeños y Talleres Mecánicos.
*   **🚫 Solución de Errores Varios:** Solucionado el 'Null Pointer' al llamar a funciones antiguas de actualización de luces incompatibles o inexistentes con Build 42. Fallback de Lua arreglado.

---

### Versiones Anteriores (Archivadas)

- _V 0.9.x_ - Adición de sprites iniciales para la Escotilla (`street_decoration_01_15`) y la Escalera del sótano (`location_sewer_01_32`).
- _V 0.8.x_ - Pruebas tempranas del objeto "Bunker Door". Teletransportes estáticos por coordenadas.
