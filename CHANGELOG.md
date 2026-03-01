# 📑 Bunkers Anywhere - Changelog / Historial de Cambios

[🇪🇸 Leer en Español](#español)

### ✅ V 1.0.0 (Current Release - B42 Fix)

*   **🔧 Generic Bunker Kit Integration:** Now natively allows dismantling vanilla stairs and installing the kit from context menus that are 100% operative via "Install Bunker Kit" option.
*   **💻 Rebuilt Mobility & Animation:**
    *   New unified *TimedActions* generic system.
    *   Teleporting, installing, and uninstalling now *forces* the player to walk to the exact tile of the hatch before starting (`luautils.walk()`), preventing clipping and wall phasing issues.
    *   Ultra-fast delay calibrated at **0.5s** to ascend/descend.
    *   Added crouching animation (*"Loot Low"*) and carpentry sounds to maximize realism when interacting with the hatch.
*   **🔘 Fast "E" Key Interaction:** Pressing the game's generic interact key while standing on or adjacent to a bunker tile will now use its smart mechanism to delve into the depths (Ground Floor Z+0 <~> Z-1 Basement) seamlessly and instantly.
*   **🏗️ Permanent Floor Generation:** Adjusted the physics of Chunk insertion (Hard saves, `IsoGridSquare.new`, and `flagForHotSave`). The gaping holes left behind by original stairs that transformed into black voids upon reload are now permanently patched with official wooden plank floors (`carpentry_02_57`)! These will endure forever, even through Multiplayer Server reboots.
*   **🎒 Balanced Loot Distribution:** The Bunker Kit is no longer an admin panel exclusive. It is smoothly introduced into the world with a **5% drop rate** across Hardware shops, Army Surplus locations, Gigamart hardware sections, and Mechanics/Trunks.
*   **🚫 Critical Engine Fixes:** Solved the pesky 'Null Pointer' exceptions when calling deprecated lighting update functions that were incompatible with the **Build 42** Engine Architecture (Safe fallbacks implemented).

---

### Previous Versions (Archived)

- *V 0.9.x* - Added initial sprites for the Hatch (`street_decoration_01_15`) and Basement Ladder (`location_sewer_01_32`).
- *V 0.8.x* - Very early alpha tests for the "Bunker Door". Hardcoded coordinates testing.

---
---

<a name="español"></a>
# 📑 Bunkers Anywhere - Historial de Cambios (Changelog) - Español

### ✅ V 1.0.0 (Release Actual - Soporte y Fix B42)

*   **🔧 Integración Genérica del Bunker Kit:** Se permite desmantelar escaleras vanilla e instalar el kit con menús desplegables 100% operativos usando "Instalar Kit de Bunker".
*   **💻 Movilidad y Animación Reconstruidas:** 
    *   Nuevo sistema de *TimedActions* consolidado. 
    *   Teletransportarse, instalar y desinstalar ahora obligan al jugador a caminar a la casilla exacta de la trampilla antes de iniciar (`luautils.walk()`) previniendo traspasos de texturas (clipping).
    *   Retraso ultra-rápido calibrado a **0.5s** para subir o bajar.
    *   Se agregó la animación de agacharse (*"Loot Low"*) y sonidos de carpintería para maximizar el realismo de usar la escotilla.
*   **🔘 Interacción Rápida con la tecla "E":** Al pulsar la tecla genérica de interactuar del juego estando encima o junto a un búnker, el jugador usará su mecanismo inteligente para ingresar a las profundidades (Planta Baja Z+0 <~> Z-1 Sótano) automáticamente.
*   **🏗️ Generación Permanente de Suelos:** Modificada la física de inserción de World Chunks. Los agujeros dejados por las escaleras originales que se transformaban en zonas al vacío oscuro tras recargar partida ahora permanecen sólidamente parcheados por un piso de tablones de madera oficial (`carpentry_02_57`) que durará para siempre gracias a las etiquetas `flagForHotSave`.
*   **🎒 Distribución de Botín Equilibrada:** El Kit de Bunker ya no es exclusivo de los paneles de administrador, integrándose de forma inmersiva con un **5% de drop rate** en el mundo real en las áreas de herramientas de ferreterías, cuarteles e hipermercados.
*   **🚫 Solución de Errores Críticos Engine:** Solucionado el 'Null Pointer' al llamar a funciones antiguas de actualización de iluminación incompatibles o marcadas como obsoletas con la nueva arquitectura del motor en la **Build 42**. (Fallback seguro implementado).

---

### Versiones Anteriores (Archivadas)

- *V 0.9.x* - Adición de sprites iniciales para la Escotilla (`street_decoration_01_15`) y la Escalera del sótano (`location_sewer_01_32`).
- *V 0.8.x* - Pruebas tempranas del objeto "Bunker Door". Teletransportes estáticos experimentales.
