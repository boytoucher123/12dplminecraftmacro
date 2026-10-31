#ifndef INCLUDE_BUILD_4DM
#define INCLUDE_BUILD_4DM

// Build settings

#define RELEASE
//#define DEBUG


// Build logic
#if defined(DEBUG) && defined(RELEASE)
#warning Conflicting build modes enabled <RELEASE|DEBUG>
#elif !defined(DEBUG) && !defined(RELEASE)
#warning Build mode unspecified : <RELEASE|DEBUG>
#endif

#ifdef RELEASE
#undef DEBUG
#endif

#include "../include/debug.h"


// Source files (each includes the headers it needs, so the order
// here doesn't matter)
#include "util.4dm"
#include "events.4dm"
#include "blocks.4dm"
#include "textures.4dm"
#include "world.4dm"
#include "mesh.4dm"
#include "physics.4dm"
#include "inventory.4dm"
#include "crafting.4dm"
#include "furnace.4dm"
#include "cows.4dm"
#include "drops.4dm"
#include "player.4dm"
#include "render_world.4dm"
#include "render_hud.4dm"
#include "render_ui.4dm"
#include "save.4dm"
#include "game.4dm"
#include "menu_panel.4dm"
#include "game_panel.4dm"


// Error for multiple inclusions of build.4dm
#else
#error Don't include build.4dm more than once
#endif
