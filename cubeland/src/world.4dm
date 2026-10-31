#ifndef WORLD_4DM_INCLUDED
#define WORLD_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"

// ---------------------------------------------------------------- access

Integer world_index(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Array position of a cell; the cell must be in bounds
// ----------------------------------------------------------------
{
  return (x * WORLD_SIZE_Z + z) * WORLD_HEIGHT + y + 1;
}

Integer world_in_bounds(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// TRUE if the cell lies inside the world
// ----------------------------------------------------------------
{
  if (x < 0 || y < 0 || z < 0) return FALSE;
  if (x >= WORLD_SIZE_X || y >= WORLD_HEIGHT || z >= WORLD_SIZE_Z) return FALSE;
  return TRUE;
}

Integer world_get_block(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Block at a cell; air outside the world (bedrock below it)
// ----------------------------------------------------------------
{
  if (y < 0) return BLOCK_BEDROCK;
  if (!world_in_bounds(x, y, z)) return BLOCK_AIR;
  return g_world[world_index(x, y, z)];
}

void world_set_block(Integer x, Integer y, Integer z, Integer block)
// ----------------------------------------------------------------
// Change a cell without telling anyone; used by generation and
// loading. Gameplay changes go through world_break_block and
// world_place_block so that other modules hear about them.
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, y, z)) return;
  g_world[world_index(x, y, z)] = block;
}

Integer world_is_solid(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// TRUE if a cell blocks movement. The sides of the world and the
// floor below it are solid, the sky above it is not.
// ----------------------------------------------------------------
{
  if (y < 0) return TRUE;
  if (y >= WORLD_HEIGHT) return FALSE;
  if (x < 0 || z < 0 || x >= WORLD_SIZE_X || z >= WORLD_SIZE_Z) return TRUE;
  return block_is_solid(g_world[world_index(x, y, z)]);
}

Integer world_top_solid_y(Integer x, Integer z)
// ----------------------------------------------------------------
// y of the highest solid block in a column, -1 if there is none
// ----------------------------------------------------------------
{
  Integer y    = 0;
  Integer base = 0;

  if (!world_in_bounds(x, 0, z)) return -1;

  base = world_index(x, 0, z);
  for (y = WORLD_HEIGHT - 1; y >= 0; --y) {
    if (block_is_solid(g_world[base + y])) return y;
  }
  return -1;
}

void world_break_block(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Remove a block during play and announce it with EVT_BLOCK_BROKEN
// A broken block next to water fills with water, so oceans stay
// level when the shore is dug away
// ----------------------------------------------------------------
{
  Integer old_block = world_get_block(x, y, z);
  Integer new_block = BLOCK_AIR;

  if (!world_in_bounds(x, y, z)) return;
  if (old_block == BLOCK_AIR) return;

  if (y < SEA_LEVEL) {
    if (world_get_block(x + 1, y, z) == BLOCK_WATER) new_block = BLOCK_WATER;
    if (world_get_block(x - 1, y, z) == BLOCK_WATER) new_block = BLOCK_WATER;
    if (world_get_block(x, y + 1, z) == BLOCK_WATER) new_block = BLOCK_WATER;
    if (world_get_block(x, y, z + 1) == BLOCK_WATER) new_block = BLOCK_WATER;
    if (world_get_block(x, y, z - 1) == BLOCK_WATER) new_block = BLOCK_WATER;
  }

  world_set_block(x, y, z, new_block);
  emit_cell_event(EVT_BLOCK_BROKEN, x, y, z, old_block);
  if (new_block == BLOCK_WATER) emit_cell_event(EVT_BLOCK_PLACED, x, y, z, BLOCK_WATER);
}

void world_place_block(Integer x, Integer y, Integer z, Integer block)
// ----------------------------------------------------------------
// Put a block down during play and announce it with
// EVT_BLOCK_PLACED
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, y, z)) return;

  world_set_block(x, y, z, block);
  emit_cell_event(EVT_BLOCK_PLACED, x, y, z, block);
}

// ---------------------------------------------------------------- terrain

void world_set_seed(Integer seed)
// ----------------------------------------------------------------
// Turn the world seed into the offsets used by the noise functions
// Any Integer works, including negative and very large seeds
// ----------------------------------------------------------------
{
  Integer low  = positive_mod(seed, 9973);
  Integer high = positive_mod(floor_divide(seed, 9973), 9967);

  g_world_seed   = seed;
  g_seed_shift_a = low  * 0.7310 + 13.0;
  g_seed_shift_b = high * 0.5170 + 7.0;
}

Real world_value_noise(Real x, Real z, Integer layer)
// ----------------------------------------------------------------
// Smooth 2D value noise in [0, 1] for the current seed
// layer picks an independent pattern
// ----------------------------------------------------------------
{
  Integer cell_x  = Floor(x);
  Integer cell_z  = Floor(z);
  Real    blend_x = smooth_curve(x - cell_x);
  Real    blend_z = smooth_curve(z - cell_z);
  Real    salt    = layer * 19.19 + g_seed_shift_b;
  Real    v00     = hash_real(cell_x       + g_seed_shift_a, cell_z       * 1.0, salt);
  Real    v10     = hash_real(cell_x + 1.0 + g_seed_shift_a, cell_z       * 1.0, salt);
  Real    v01     = hash_real(cell_x       + g_seed_shift_a, cell_z + 1.0      , salt);
  Real    v11     = hash_real(cell_x + 1.0 + g_seed_shift_a, cell_z + 1.0      , salt);

  return lerp_real(lerp_real(v00, v10, blend_x), lerp_real(v01, v11, blend_x), blend_z);
}

Integer world_terrain_height(Integer x, Integer z)
// ----------------------------------------------------------------
// y of the top block of a column
// A slow "continent" pattern decides land or sea, rolling hills
// sit on top, and a third pattern makes some areas mountainous
// Anything that comes out below SEA_LEVEL becomes ocean floor
// ----------------------------------------------------------------
{
  Real    continent = world_value_noise(x / 52.0, z / 52.0, 1);
  Real    hills     = world_value_noise(x / 22.0, z / 22.0, 2) * 0.60
                    + world_value_noise(x / 10.0, z / 10.0, 3) * 0.28
                    + world_value_noise(x / 4.5 , z / 4.5 , 4) * 0.12;
  Real    rugged    = world_value_noise(x / 34.0, z / 34.0, 5);
  Real    base      = 47.0 + continent * 30.0;
  Real    amplitude = 3.0 + rugged * rugged * 26.0;
  Real    height    = 0.0;
  Integer result    = 0;

  if (base < SEA_LEVEL) {
    // Deepen the sea floor away from the coast
    base      = SEA_LEVEL - (SEA_LEVEL - base) * 1.6;
    amplitude = 3.0;
  }

  height = base + (hills - 0.5) * amplitude * 2.0;
  result = Floor(height);

  return clamp_integer(result, 6, WORLD_HEIGHT - 14);
}

void world_plant_tree(Integer x, Integer ground_y, Integer z)
// ----------------------------------------------------------------
// An oak: a trunk of logs with a rounded crown of leaves
// The ground under the trunk becomes dirt
// ----------------------------------------------------------------
{
  Integer trunk  = 4 + Floor(hash_real(x * 3.1 + g_seed_shift_a, z * 1.7, 41.0) * 3.0);
  Integer top    = ground_y + trunk;
  Integer y      = 0;
  Integer dx     = 0;
  Integer dz     = 0;
  Integer radius = 0;
  Integer corner = 0;

  for (y = top - 2; y <= top + 1; ++y) {
    radius = 2;
    if (y >= top) radius = 1;
    for (dx = -radius; dx <= radius; ++dx) {
      for (dz = -radius; dz <= radius; ++dz) {
        corner = Absolute(dx) == radius && Absolute(dz) == radius;
        if (corner) {
          if (y == top + 1) continue;
          if (hash_real(x + dx * 1.0, y * 1.0, z + dz + g_seed_shift_b) < 0.55) continue;
        }
        if (world_get_block(x + dx, y, z + dz) == BLOCK_AIR) {
          world_set_block(x + dx, y, z + dz, BLOCK_LEAVES);
        }
      }
    }
  }

  for (y = ground_y + 1; y <= top; ++y) world_set_block(x, y, z, BLOCK_OAK_LOG);
  world_set_block(x, ground_y, z, BLOCK_DIRT);
}

void world_generate(Integer seed)
// ----------------------------------------------------------------
// Fill the whole world from a seed: bedrock floor, stone, a few
// layers of dirt topped with grass, sandy shores and sea bed,
// water up to SEA_LEVEL, then trees in forested areas
// ----------------------------------------------------------------
{
  Integer x        = 0;
  Integer z        = 0;
  Integer y        = 0;
  Integer height   = 0;
  Integer base     = 0;
  Integer block    = 0;
  Integer surface  = 0;
  Integer under    = 0;
  Integer column   = 0;
  Integer cell_x   = 0;
  Integer cell_z   = 0;
  Integer tree_x   = 0;
  Integer tree_z   = 0;
  Real    forest   = 0.0;
  Real    chance   = 0.0;

  world_set_seed(seed);

  for (x = 0; x < WORLD_SIZE_X; ++x) {
    for (z = 0; z < WORLD_SIZE_Z; ++z) {
      height = world_terrain_height(x, z);
      base   = world_index(x, 0, z);
      column = x * WORLD_SIZE_Z + z + 1;
      g_height_map[column] = height;

      surface = BLOCK_GRASS;
      under   = BLOCK_DIRT;
      if (height < SEA_LEVEL + 1) {
        surface = BLOCK_SAND;
        under   = BLOCK_SAND;
        if (height < SEA_LEVEL - 7) {
          surface = BLOCK_DIRT;
          under   = BLOCK_DIRT;
        }
      }

      for (y = 0; y < WORLD_HEIGHT; ++y) {
        block = BLOCK_AIR;
        if (y == 0) {
          block = BLOCK_BEDROCK;
        } else if (y <= 3 && hash_real(x * 1.0, y * 1.0, z + g_seed_shift_a) < 0.7 / y) {
          block = BLOCK_BEDROCK;
        } else if (y < height - 3) {
          block = BLOCK_STONE;
        } else if (y < height) {
          block = under;
        } else if (y == height) {
          block = surface;
        } else if (y < SEA_LEVEL) {
          block = BLOCK_WATER;
        }
        g_world[base + y] = block;
      }
    }
  }

  // Trees: at most one per 6 x 6 patch, more where the forest
  // pattern is strong, never near the edge of the world
  for (cell_x = 0; cell_x < floor_divide(WORLD_SIZE_X, 6); ++cell_x) {
    for (cell_z = 0; cell_z < floor_divide(WORLD_SIZE_Z, 6); ++cell_z) {
      tree_x = cell_x * 6 + 1 + Floor(hash_real(cell_x * 1.0, cell_z * 1.0, 51.0 + g_seed_shift_a) * 4.0);
      tree_z = cell_z * 6 + 1 + Floor(hash_real(cell_x * 1.0, cell_z * 1.0, 52.0 + g_seed_shift_b) * 4.0);
      if (tree_x < 3 || tree_z < 3 || tree_x > WORLD_SIZE_X - 4 || tree_z > WORLD_SIZE_Z - 4) continue;

      forest = world_value_noise(tree_x / 30.0, tree_z / 30.0, 6);
      chance = forest * forest * 1.4 - 0.08;
      if (hash_real(cell_x * 1.0, cell_z * 1.0, 53.0 + g_seed_shift_a) > chance) continue;

      height = g_height_map[tree_x * WORLD_SIZE_Z + tree_z + 1];
      if (world_get_block(tree_x, height, tree_z) != BLOCK_GRASS) continue;
      if (height + 8 >= WORLD_HEIGHT) continue;

      world_plant_tree(tree_x, height, tree_z);
    }
  }

  world_find_spawn();
}

void world_find_spawn()
// ----------------------------------------------------------------
// Pick the grass column nearest the middle of the world, searching
// outwards in growing squares, and stand the spawn point on it
// ----------------------------------------------------------------
{
  Integer centre_x = floor_divide(WORLD_SIZE_X, 2);
  Integer centre_z = floor_divide(WORLD_SIZE_Z, 2);
  Integer radius   = 0;
  Integer x        = 0;
  Integer z        = 0;
  Integer top      = 0;

  for (radius = 0; radius < centre_x - 2; ++radius) {
    for (x = centre_x - radius; x <= centre_x + radius; ++x) {
      for (z = centre_z - radius; z <= centre_z + radius; ++z) {
        if (Absolute(x - centre_x) != radius && Absolute(z - centre_z) != radius) continue;
        top = world_top_solid_y(x, z);
        if (top < SEA_LEVEL) continue;
        if (world_get_block(x, top, z) != BLOCK_GRASS) continue;
        g_spawn_x = x + 0.5;
        g_spawn_y = top + 1.0;
        g_spawn_z = z + 0.5;
        return;
      }
    }
  }

  // No land at all: stand on top of whatever is in the middle
  top = world_top_solid_y(centre_x, centre_z);
  if (top < SEA_LEVEL - 1) top = SEA_LEVEL - 1;
  g_spawn_x = centre_x + 0.5;
  g_spawn_y = top + 1.0;
  g_spawn_z = centre_z + 0.5;
}

#endif
