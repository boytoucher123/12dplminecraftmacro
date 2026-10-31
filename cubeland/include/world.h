#ifndef WORLD_H_INCLUDED
#define WORLD_H_INCLUDED

#include "config.h"

// ----------------------------------------------------------------
// The block grid and the seeded terrain generator
// Cell (x, y, z) has 0 <= x < WORLD_SIZE_X, 0 <= y < WORLD_HEIGHT,
// 0 <= z < WORLD_SIZE_Z and is stored at world_index(x, y, z)
// Columns are stored together, so y + 1 is the next array slot
// ----------------------------------------------------------------

/*Global variables*/ {
  Integer g_world[WORLD_CELLS];
  Integer g_height_map[WORLD_COLUMNS];   // highest solid y of each column when generated

  Integer g_world_seed   = 0;
  Real    g_seed_shift_a = 0.0;
  Real    g_seed_shift_b = 0.0;

  Real    g_spawn_x = 64.5;
  Real    g_spawn_y = 70.0;
  Real    g_spawn_z = 64.5;
}

Integer world_index         (Integer x, Integer y, Integer z);
Integer world_in_bounds     (Integer x, Integer y, Integer z);
Integer world_get_block     (Integer x, Integer y, Integer z);
void    world_set_block     (Integer x, Integer y, Integer z, Integer block);
Integer world_is_solid      (Integer x, Integer y, Integer z);
Integer world_top_solid_y   (Integer x, Integer z);
void    world_break_block   (Integer x, Integer y, Integer z);
void    world_place_block   (Integer x, Integer y, Integer z, Integer block);
void    world_set_seed      (Integer seed);
Real    world_value_noise   (Real x, Real z, Integer layer);
Integer world_terrain_height(Integer x, Integer z);
void    world_generate      (Integer seed);
void    world_plant_tree    (Integer x, Integer ground_y, Integer z);
void    world_find_spawn    ();

#endif
