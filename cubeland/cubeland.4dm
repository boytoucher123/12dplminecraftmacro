//------------------------------------------------------------
// Cubeland
//
// A first person block building sandbox drawn in a 12d Draw_Box.
//
// Generate seeded worlds of hills, forests and oceans (water fills
// everything below y 62), walk and jump around them, break blocks
// and pick up what they drop, build with what you carry, punch
// trees for wood, craft planks, sticks, a crafting table and a
// furnace, and cook beef from the cows that wander the grassland.
//
//   Blocks      16 x 16 pixel textures, generated when the macro
//               starts; dirt, grass, stone, cobblestone, sand,
//               oak logs, leaves, planks, water, bedrock, crafting
//               table and furnace
//   Player      1.8 blocks tall, 5 blocks of reach, gravity and
//               collision, swimming, fall damage and a health bar
//   Inventory   9 slot hotbar and 27 slot (9 x 3) inventory, 2 x 2
//               crafting in the inventory and 3 x 3 at a table,
//               wooden and stone tools
//   Worlds      saved in the "cubeland_worlds" folder of the 12d
//               working folder, made from a seed you can type in
//
// Controls are listed on the help screen (H) inside the game.
//
// Structure
//   cubeland.4dm      this file: main()
//   src/build.4dm     includes every source file
//   include/*.h       constants, global data and prototypes
//   src/*.4dm         model (world, player, cows, ...), views
//                     (render_*) and controllers (*_panel)
// Modules don't report to each other directly: they emit game
// events (include/events.h) and game_dispatch_events() passes each
// event to every module's *_on_event() handler.
// Game state lives in records (12d Attributes used like structs)
// that are passed to every function that uses them; see
// CODING_RULES.md.
//------------------------------------------------------------

#ifdef CUBELAND_BASE_FILE_4DM_INCLUDED
#error Do not include the base file!
#endif
#define CUBELAND_BASE_FILE_4DM_INCLUDED

#include "src/build.4dm"

void main()
// --------------------------------------------------------
// Entry point: world menu, then the game, until Quit
// --------------------------------------------------------
{
  Integer l_running   = TRUE;
  Integer l_result    = 0;
  Integer l_time_seed = 0;

  Get_time(l_time_seed);
  game_init_once(g_game, g_book, g_settings, g_random, l_time_seed);

  while (l_running) {
    l_result = menu_panel_run(g_game, g_random, g_settings);

    if (l_result == MENU_RESULT_QUIT || l_result == SHUTDOWN_CODE) {
      l_running = FALSE;
    } else {
      l_result = game_panel_run(record_text(g_game, ATTR_MENU_WORLD), l_result == MENU_RESULT_CREATE,
                              record_integer(g_game, ATTR_MENU_SEED));
      if (l_result == SHUTDOWN_CODE) l_running = FALSE;
    }
  }
}
