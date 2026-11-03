#ifndef WORLD_4DM_INCLUDED
#define WORLD_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"

// ---------------------------------------------------------------- grid access

Integer world_index(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Array position of a cell; the cell must be in bounds
// ----------------------------------------------------------------
{
  return (x * WORLD_SIZE_Z + z) * WORLD_HEIGHT + y + 1;
}

Integer world_column(Integer x, Integer z)
// ----------------------------------------------------------------
// Array position of a column in the column maps
// ----------------------------------------------------------------
{
  return x * WORLD_SIZE_Z + z + 1;
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

Integer world_sky_top(Integer x, Integer z)
// ----------------------------------------------------------------
// y of the highest sky-blocking block of a column (kept up to date
// as blocks change); cells above it are in daylight
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, 0, z)) return -1;
  return g_column_top[world_column(x, z)];
}

Integer world_solid_below(Integer x, Integer z)
// ----------------------------------------------------------------
// As generated, every cell of the column from 0 up to this y is
// solid (caves and ponds lower it). Used to skip buried sections.
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, 0, z)) return WORLD_HEIGHT;
  return g_solid_below[world_column(x, z)];
}

Integer world_biome(Integer x, Integer z)
// ----------------------------------------------------------------
// BIOME_* of a column
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, 0, z)) return BIOME_OCEAN;
  return g_biome_map[world_column(x, z)];
}

void world_update_column_top(Integer x, Integer z)
// ----------------------------------------------------------------
// Recompute the sky top of one column after a block changed
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, 0, z)) return;
  g_column_top[world_column(x, z)] = world_top_solid_y(x, z);
}

void world_break_block(Attributes &events, Integer x, Integer y, Integer z, Integer tool_item)
// ----------------------------------------------------------------
// Remove a block during play and announce it with EVT_BLOCK_BROKEN
// (tool_item is what it was broken with, so the drop can depend on
// it; ITEM_NONE for a bare hand)
// A broken block next to water fills with water, so oceans and
// ponds stay level when the shore is dug away
// ----------------------------------------------------------------
{
  Integer old_block = world_get_block(x, y, z);
  Integer new_block = BLOCK_AIR;

  if (!world_in_bounds(x, y, z)) return;
  if (old_block == BLOCK_AIR) return;

  if (world_get_block(x + 1, y, z) == BLOCK_WATER) new_block = BLOCK_WATER;
  if (world_get_block(x - 1, y, z) == BLOCK_WATER) new_block = BLOCK_WATER;
  if (world_get_block(x, y + 1, z) == BLOCK_WATER) new_block = BLOCK_WATER;
  if (world_get_block(x, y, z + 1) == BLOCK_WATER) new_block = BLOCK_WATER;
  if (world_get_block(x, y, z - 1) == BLOCK_WATER) new_block = BLOCK_WATER;

  world_set_block        (x, y, z, new_block);
  world_update_column_top(x, z);
  emit_event(events, EVT_BLOCK_BROKEN, x, y, z, old_block, tool_item * 1.0, 0.0, 0.0, "");
  if (new_block == BLOCK_WATER) emit_cell_event(events, EVT_BLOCK_PLACED, x, y, z, BLOCK_WATER);

  // A plant standing on the broken block goes with it
  if (block_is_plant(world_get_block(x, y + 1, z))) world_break_block(events, x, y + 1, z, ITEM_NONE);
}

void world_place_block(Attributes &events, Integer x, Integer y, Integer z, Integer block)
// ----------------------------------------------------------------
// Put a block down during play and announce it with
// EVT_BLOCK_PLACED
// ----------------------------------------------------------------
{
  if (!world_in_bounds(x, y, z)) return;

  world_set_block        (x, y, z, block);
  world_update_column_top(x, z);
  emit_cell_event(events, EVT_BLOCK_PLACED, x, y, z, block);
}

// ---------------------------------------------------------------- world record

void world_info_clear(Attributes &info, Integer seed)
// ----------------------------------------------------------------
// Start a world record for a seed
// ----------------------------------------------------------------
{
  Real shift_a = 0.0;
  Real shift_b = 0.0;

  world_seed_shifts(seed, shift_a, shift_b);

  record_clear      (info, DATATYPE_WORLD_INFO);
  record_set_integer(info, ATTR_WORLD_SEED, seed);
  record_set_real   (info, ATTR_SHIFT_A,    shift_a);
  record_set_real   (info, ATTR_SHIFT_B,    shift_b);
  world_info_set_spawn(info, WORLD_SIZE_X * 0.5, SEA_LEVEL + 8.0, WORLD_SIZE_Z * 0.5);
}

Integer world_info_seed(Attributes &info)
// ----------------------------------------------------------------
// The seed a world was made from
// ----------------------------------------------------------------
{
  return record_integer(info, ATTR_WORLD_SEED);
}

void world_info_spawn(Attributes &info, Real &x, Real &y, Real &z)
// ----------------------------------------------------------------
// Where the player starts and respawns
// ----------------------------------------------------------------
{
  x = record_real(info, ATTR_SPAWN_X);
  y = record_real(info, ATTR_SPAWN_Y);
  z = record_real(info, ATTR_SPAWN_Z);
}

void world_info_set_spawn(Attributes &info, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Set where the player starts and respawns
// ----------------------------------------------------------------
{
  record_set_real(info, ATTR_SPAWN_X, x);
  record_set_real(info, ATTR_SPAWN_Y, y);
  record_set_real(info, ATTR_SPAWN_Z, z);
}

// ---------------------------------------------------------------- noise

void world_seed_shifts(Integer seed, Real &shift_a, Real &shift_b)
// ----------------------------------------------------------------
// Turn the world seed into the offsets used by the noise functions
// Any Integer works, including negative and very large seeds
// ----------------------------------------------------------------
{
  Integer low  = positive_mod(seed, 9973);
  Integer high = positive_mod(floor_divide(seed, 9973), 9967);

  shift_a = low  * 0.7310 + 13.0;
  shift_b = high * 0.5170 + 7.0;
}

Real world_value_noise(Real x, Real z, Integer layer, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// Smooth 2D value noise in [0, 1] for a seed's shifts
// layer picks an independent pattern
// ----------------------------------------------------------------
{
  Integer cell_x  = Floor(x);
  Integer cell_z  = Floor(z);
  Real    blend_x = smooth_curve(x - cell_x);
  Real    blend_z = smooth_curve(z - cell_z);
  Real    salt    = layer * 19.19 + shift_b;
  Real    v00     = hash_real(cell_x       + shift_a, cell_z       * 1.0, salt);
  Real    v10     = hash_real(cell_x + 1.0 + shift_a, cell_z       * 1.0, salt);
  Real    v01     = hash_real(cell_x       + shift_a, cell_z + 1.0      , salt);
  Real    v11     = hash_real(cell_x + 1.0 + shift_a, cell_z + 1.0      , salt);

  return lerp_real(lerp_real(v00, v10, blend_x), lerp_real(v01, v11, blend_x), blend_z);
}

Real world_desert_weight(Integer x, Integer z, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// 0 outside deserts, 1 deep inside one, smooth in between so the
// land flattens gradually towards a desert instead of stepping
// ----------------------------------------------------------------
{
  Real heat = world_value_noise(x / 58.0, z / 58.0, 7, shift_a, shift_b);

  return smooth_curve(clamp_real((heat - 0.56) / 0.12, 0.0, 1.0));
}

Integer world_column_biome(Integer x, Integer z, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// Land biome of a column (oceans and beaches are decided from the
// height afterwards)
// ----------------------------------------------------------------
{
  if (world_desert_weight(x, z, shift_a, shift_b) > 0.5) return BIOME_DESERT;
  if (world_value_noise(x / 34.0, z / 34.0, 6, shift_a, shift_b) > 0.52) return BIOME_FOREST;
  return BIOME_PLAINS;
}

Integer world_terrain_height(Integer x, Integer z, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// y of the top block of a column
// A slow "continent" pattern decides land or sea and gentle hills
// sit on top. A third pattern makes a few areas hilly; most land
// is rolling. Deserts are flatter. Anything that comes out below
// SEA_LEVEL becomes ocean floor.
// ----------------------------------------------------------------
{
  Real    continent = world_value_noise(x / 64.0, z / 64.0, 1, shift_a, shift_b);
  Real    hills     = world_value_noise(x / 30.0, z / 30.0, 2, shift_a, shift_b) * 0.72
                    + world_value_noise(x / 13.0, z / 13.0, 3, shift_a, shift_b) * 0.28;
  Real    rugged    = world_value_noise(x / 40.0, z / 40.0, 5, shift_a, shift_b);
  Real    desert    = world_desert_weight(x, z, shift_a, shift_b);
  Real    base      = 53.0 + continent * 26.0;
  Real    amplitude = 2.5 + rugged * rugged * rugged * 22.0;
  Real    height    = 0.0;
  Integer result    = 0;

  amplitude = amplitude * (1.0 - 0.6 * desert);
  base      = base + 2.0 * desert;

  if (base < SEA_LEVEL) {
    // Deepen the sea floor away from the coast
    base      = SEA_LEVEL - (SEA_LEVEL - base) * 1.6;
    amplitude = 3.0;
  }

  height = base + (hills - 0.5) * amplitude * 2.0;
  result = Floor(height);

  return clamp_integer(result, 6, WORLD_HEIGHT - 14);
}

// ---------------------------------------------------------------- generation

void world_fill_columns(Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// Fill every column: bedrock floor, stone, a biome surface (grass
// on dirt, sand on sandstone in deserts, sand on beaches and the
// sea bed, gravel in the deep sea) and water up to SEA_LEVEL
// ----------------------------------------------------------------
{
  Integer x       = 0;
  Integer z       = 0;
  Integer y       = 0;
  Integer height  = 0;
  Integer biome   = 0;
  Integer base    = 0;
  Integer column  = 0;
  Integer block   = 0;
  Integer surface = 0;
  Integer under   = 0;
  Integer deep    = 0;
  Integer depth   = 0;

  for (x = 0; x < WORLD_SIZE_X; ++x) {
    for (z = 0; z < WORLD_SIZE_Z; ++z) {
      height = world_terrain_height(x, z, shift_a, shift_b);
      biome  = world_column_biome  (x, z, shift_a, shift_b);
      base   = world_index (x, 0, z);
      column = world_column(x, z);

      surface = BLOCK_GRASS;
      under   = BLOCK_DIRT;
      deep    = BLOCK_DIRT;
      depth   = 3;
      if (biome == BIOME_DESERT) {
        surface = BLOCK_SAND;
        under   = BLOCK_SAND;
        deep    = BLOCK_SANDSTONE;
        depth   = 6;
      }
      if (height < SEA_LEVEL + 1) {
        biome   = BIOME_BEACH;
        surface = BLOCK_SAND;
        under   = BLOCK_SAND;
        deep    = BLOCK_SANDSTONE;
        if (height < SEA_LEVEL - 2) biome = BIOME_OCEAN;
        if (height < SEA_LEVEL - 9) {
          surface = BLOCK_GRAVEL;
          under   = BLOCK_DIRT;
          deep    = BLOCK_DIRT;
        }
      }

      g_height_map [column] = height;
      g_solid_below[column] = height;
      g_biome_map  [column] = biome;

      for (y = 0; y < WORLD_HEIGHT; ++y) {
        block = BLOCK_AIR;
        if (y == 0) {
          block = BLOCK_BEDROCK;
        } else if (y <= 3 && hash_real(x * 1.0, y * 1.0, z + shift_a) < 0.7 / y) {
          block = BLOCK_BEDROCK;
        } else if (y < height - depth) {
          block = BLOCK_STONE;
        } else if (y < height - 3) {
          block = deep;
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
}

void world_mark_carved(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// Note that a generated column is no longer solid up to its
// surface (so meshing doesn't skip the hollow section)
// ----------------------------------------------------------------
{
  Integer column = 0;

  if (!world_in_bounds(x, y, z)) return;
  column = world_column(x, z);
  if (y - 1 < g_solid_below[column]) g_solid_below[column] = y - 1;
}

void world_carve_sphere(Real centre_x, Real centre_y, Real centre_z, Real radius)
// ----------------------------------------------------------------
// Hollow out a ball of underground blocks for a cave. Water, the
// cells next to water and the bottom of the world are left alone
// so caves never drain the sea or break through the bedrock.
// ----------------------------------------------------------------
{
  Integer x0    = Floor(centre_x - radius);
  Integer x1    = Floor(centre_x + radius);
  Integer y0    = Floor(centre_y - radius);
  Integer y1    = Floor(centre_y + radius);
  Integer z0    = Floor(centre_z - radius);
  Integer z1    = Floor(centre_z + radius);
  Integer x     = 0;
  Integer y     = 0;
  Integer z     = 0;
  Integer block = 0;
  Integer wet   = 0;
  Real    dx    = 0.0;
  Real    dy    = 0.0;
  Real    dz    = 0.0;

  for (x = x0; x <= x1; ++x) {
    for (z = z0; z <= z1; ++z) {
      for (y = y0; y <= y1; ++y) {
        if (y <= 4) continue;
        if (!world_in_bounds(x, y, z)) continue;
        dx = x + 0.5 - centre_x;
        dy = (y + 0.5 - centre_y) * 1.3;
        dz = z + 0.5 - centre_z;
        if (dx * dx + dy * dy + dz * dz > radius * radius) continue;

        block = world_get_block(x, y, z);
        if (block == BLOCK_AIR || block == BLOCK_WATER || block == BLOCK_BEDROCK) continue;

        wet = FALSE;
        if (world_get_block(x + 1, y, z) == BLOCK_WATER) wet = TRUE;
        if (world_get_block(x - 1, y, z) == BLOCK_WATER) wet = TRUE;
        if (world_get_block(x, y + 1, z) == BLOCK_WATER) wet = TRUE;
        if (world_get_block(x, y, z + 1) == BLOCK_WATER) wet = TRUE;
        if (world_get_block(x, y, z - 1) == BLOCK_WATER) wet = TRUE;
        if (wet) continue;

        world_set_block  (x, y, z, BLOCK_AIR);
        world_mark_carved(x, y, z);
      }
    }
  }
}

void world_carve_caves(Attributes &random)
// ----------------------------------------------------------------
// Caves are dug by "worms": each starts somewhere underground and
// wanders, turning a little at every step, hollowing out a ball
// whose size swells and shrinks. A few reach the surface.
// ----------------------------------------------------------------
{
  Integer worms  = random_range(random, MAX_CAVE_WORMS - 5, MAX_CAVE_WORMS);
  Integer worm   = 0;
  Integer step   = 0;
  Integer top    = 0;
  Real    x      = 0.0;
  Real    y      = 0.0;
  Real    z      = 0.0;
  Real    yaw    = 0.0;
  Real    pitch  = 0.0;
  Real    phase  = 0.0;
  Real    radius = 0.0;

  for (worm = 1; worm <= worms; ++worm) {
    x     = random_between(random, 10.0, WORLD_SIZE_X - 10.0);
    z     = random_between(random, 10.0, WORLD_SIZE_Z - 10.0);
    top   = g_height_map[world_column(floor_integer(x), floor_integer(z))];
    y     = random_between(random, 10.0, max_real(12.0, top - 4.0));
    yaw   = random_between(random, 0.0, TWO_PI);
    pitch = random_between(random, -0.25, 0.25);
    phase = random_between(random, 0.0, TWO_PI);

    for (step = 1; step <= CAVE_WORM_STEPS; ++step) {
      radius = 1.5 + 1.0 * Sin(step * 0.16 + phase);
      world_carve_sphere(x, y, z, radius);

      x     = x + Cos(yaw) * Cos(pitch);
      z     = z + Sin(yaw) * Cos(pitch);
      y     = y + Sin(pitch);
      yaw   = yaw + random_between(random, -0.35, 0.35);
      pitch = clamp_real(pitch * 0.9 + random_between(random, -0.18, 0.18), -0.6, 0.6);

      if (y < 7.0) pitch = Absolute(pitch);
      if (x < 4.0 || z < 4.0 || x > WORLD_SIZE_X - 4.0 || z > WORLD_SIZE_Z - 4.0) break;
    }
  }
}

void world_place_veins(Attributes &random, Integer block, Integer count, Integer length, Integer max_y)
// ----------------------------------------------------------------
// Scatter count small veins of block through the stone below
// max_y, each a short random walk of length cells
// ----------------------------------------------------------------
{
  Integer vein = 0;
  Integer cell = 0;
  Integer x    = 0;
  Integer y    = 0;
  Integer z    = 0;
  Integer axis = 0;

  for (vein = 1; vein <= count; ++vein) {
    x = random_range(random, 1, WORLD_SIZE_X - 2);
    z = random_range(random, 1, WORLD_SIZE_Z - 2);
    y = random_range(random, 5, max_y);

    for (cell = 1; cell <= length; ++cell) {
      if (world_get_block(x, y, z) == BLOCK_STONE) world_set_block(x, y, z, block);
      axis = random_range(random, 1, 6);
      if (axis == 1) ++x;
      if (axis == 2) --x;
      if (axis == 3) ++y;
      if (axis == 4) --y;
      if (axis == 5) ++z;
      if (axis == 6) --z;
    }
  }
}

void world_plant_tree(Integer x, Integer ground_y, Integer z, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// An oak: a trunk of logs with a rounded crown of leaves
// The ground under the trunk becomes dirt
// ----------------------------------------------------------------
{
  Integer trunk  = 4 + Floor(hash_real(x * 3.1 + shift_a, z * 1.7, 41.0) * 3.0);
  Integer top    = ground_y + trunk;
  Integer y      = 0;
  Integer dx     = 0;
  Integer dz     = 0;
  Integer radius = 0;
  Integer corner = 0;
  Integer here   = 0;

  for (y = top - 2; y <= top + 1; ++y) {
    radius = 2;
    if (y >= top) radius = 1;
    for (dx = -radius; dx <= radius; ++dx) {
      for (dz = -radius; dz <= radius; ++dz) {
        corner = Absolute(dx) == radius && Absolute(dz) == radius;
        if (corner) {
          if (y == top + 1) continue;
          if (hash_real(x + dx * 1.0, y * 1.0, z + dz + shift_b) < 0.55) continue;
        }
        here = world_get_block(x + dx, y, z + dz);
        if (here == BLOCK_AIR || block_is_plant(here)) world_set_block(x + dx, y, z + dz, BLOCK_LEAVES);
      }
    }
  }

  for (y = ground_y + 1; y <= top; ++y) world_set_block(x, y, z, BLOCK_OAK_LOG);
  world_set_block(x, ground_y, z, BLOCK_DIRT);
}

void world_plant_trees(Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// At most one tree per 5 x 5 patch: many in forests, the odd one on
// the plains (leaving open clearings), none in deserts or on sand
// ----------------------------------------------------------------
{
  Integer cell_x = 0;
  Integer cell_z = 0;
  Integer tree_x = 0;
  Integer tree_z = 0;
  Integer height = 0;
  Integer biome  = 0;
  Real    forest = 0.0;
  Real    chance = 0.0;

  for (cell_x = 0; cell_x < floor_divide(WORLD_SIZE_X, 5); ++cell_x) {
    for (cell_z = 0; cell_z < floor_divide(WORLD_SIZE_Z, 5); ++cell_z) {
      tree_x = cell_x * 5 + 1 + Floor(hash_real(cell_x * 1.0, cell_z * 1.0, 51.0 + shift_a) * 3.0);
      tree_z = cell_z * 5 + 1 + Floor(hash_real(cell_x * 1.0, cell_z * 1.0, 52.0 + shift_b) * 3.0);
      if (tree_x < 3 || tree_z < 3 || tree_x > WORLD_SIZE_X - 4 || tree_z > WORLD_SIZE_Z - 4) continue;

      biome  = world_biome(tree_x, tree_z);
      forest = world_value_noise(tree_x / 34.0, tree_z / 34.0, 6, shift_a, shift_b);
      chance = 0.04;
      if (biome == BIOME_FOREST) chance = 0.25 + (forest - 0.52) * 3.0;
      if (biome != BIOME_FOREST && biome != BIOME_PLAINS) chance = 0.0;
      if (hash_real(cell_x * 1.0, cell_z * 1.0, 53.0 + shift_a) > chance) continue;

      height = g_height_map[world_column(tree_x, tree_z)];
      if (world_get_block(tree_x, height, tree_z) != BLOCK_GRASS) continue;
      if (world_get_block(tree_x, height + 1, tree_z) != BLOCK_AIR) continue;
      if (height + 8 >= WORLD_HEIGHT) continue;

      world_plant_tree(tree_x, height, tree_z, shift_a, shift_b);
    }
  }
}

void world_plant_cactus(Integer x, Integer ground_y, Integer z, Integer tall)
// ----------------------------------------------------------------
// A cactus of tall blocks on sand, if nothing is next to it
// ----------------------------------------------------------------
{
  Integer y = 0;

  if (world_get_block(x + 1, ground_y + 1, z) != BLOCK_AIR) return;
  if (world_get_block(x - 1, ground_y + 1, z) != BLOCK_AIR) return;
  if (world_get_block(x, ground_y + 1, z + 1) != BLOCK_AIR) return;
  if (world_get_block(x, ground_y + 1, z - 1) != BLOCK_AIR) return;

  for (y = ground_y + 1; y <= ground_y + tall; ++y) world_set_block(x, y, z, BLOCK_CACTUS);
}

void world_add_plants(Attributes &random, Real shift_a, Real shift_b)
// ----------------------------------------------------------------
// Grass tufts and patches of flowers on open grass (thickest in
// meadows), cacti and dead bushes in the desert
// ----------------------------------------------------------------
{
  Integer x      = 0;
  Integer z      = 0;
  Integer top    = 0;
  Integer biome  = 0;
  Integer ground = 0;
  Real    meadow = 0.0;
  Real    roll   = 0.0;

  for (x = 1; x < WORLD_SIZE_X - 1; ++x) {
    for (z = 1; z < WORLD_SIZE_Z - 1; ++z) {
      top    = g_height_map[world_column(x, z)];
      ground = world_get_block(x, top, z);
      if (world_get_block(x, top + 1, z) != BLOCK_AIR) continue;
      biome  = world_biome(x, z);
      roll   = random_next(random);

      if (ground == BLOCK_GRASS) {
        meadow = world_value_noise(x / 18.0, z / 18.0, 8, shift_a, shift_b);
        if (roll < 0.06 + meadow * 0.22) {
          world_set_block(x, top + 1, z, BLOCK_TALL_GRASS);
        } else if (roll > 0.995 - meadow * 0.02) {
          if (world_value_noise(x / 9.0, z / 9.0, 9, shift_a, shift_b) > 0.5) {
            world_set_block(x, top + 1, z, BLOCK_POPPY);
          } else {
            world_set_block(x, top + 1, z, BLOCK_DANDELION);
          }
        }
      } else if (ground == BLOCK_SAND && biome == BIOME_DESERT) {
        if (roll < 0.012) {
          world_set_block(x, top + 1, z, BLOCK_DEAD_BUSH);
        } else if (roll < 0.030) {
          world_plant_cactus(x, top, z, random_range(random, 1, 3));
        }
      }
    }
  }
}

Integer world_area_is_flat(Integer x0, Integer z0, Integer x1, Integer z1, Integer &ground_y)
// ----------------------------------------------------------------
// TRUE if every generated surface in the rectangle is dry grass or
// sand within one block of the others; ground_y is set to the most
// common lower height to build on
// ----------------------------------------------------------------
{
  Integer x      = 0;
  Integer z      = 0;
  Integer height = 0;
  Integer low    = WORLD_HEIGHT;
  Integer high   = -1;
  Integer block  = 0;

  for (x = x0; x <= x1; ++x) {
    for (z = z0; z <= z1; ++z) {
      if (!world_in_bounds(x, 0, z)) return FALSE;
      height = g_height_map[world_column(x, z)];
      block  = world_get_block(x, height, z);
      if (height <= SEA_LEVEL) return FALSE;
      if (block != BLOCK_GRASS && block != BLOCK_SAND) return FALSE;
      if (height < low ) low  = height;
      if (height > high) high = height;
    }
  }
  ground_y = low;
  if (high - low > 1) return FALSE;
  return TRUE;
}

void world_dig_pond(Integer centre_x, Integer centre_z)
// ----------------------------------------------------------------
// A small round pond, 2 deep in the middle, in flat grassland
// ----------------------------------------------------------------
{
  Integer ground = 0;
  Integer x      = 0;
  Integer z      = 0;
  Integer y      = 0;
  Integer depth  = 0;
  Real    reach  = 0.0;

  if (!world_area_is_flat(centre_x - 4, centre_z - 4, centre_x + 4, centre_z + 4, ground)) return;

  for (x = centre_x - 3; x <= centre_x + 3; ++x) {
    for (z = centre_z - 3; z <= centre_z + 3; ++z) {
      reach = (x - centre_x) * (x - centre_x) + (z - centre_z) * (z - centre_z);
      if (reach > 10.5) continue;
      depth = 1;
      if (reach < 4.5) depth = 2;
      for (y = ground + 1; y <= ground + 3; ++y) world_set_block(x, y, z, BLOCK_AIR);
      for (y = ground - depth + 1; y <= ground; ++y) {
        world_set_block  (x, y, z, BLOCK_WATER);
        world_mark_carved(x, y, z);
      }
      world_set_block(x, ground - depth, z, BLOCK_SAND);
    }
  }
}

void world_add_ponds(Attributes &random)
// ----------------------------------------------------------------
// Try a few spots for ponds; most worlds get one or two
// ----------------------------------------------------------------
{
  Integer attempt = 0;
  Integer x       = 0;
  Integer z       = 0;
  Integer biome   = 0;

  for (attempt = 1; attempt <= MAX_PONDS * 6; ++attempt) {
    x     = random_range(random, 10, WORLD_SIZE_X - 11);
    z     = random_range(random, 10, WORLD_SIZE_Z - 11);
    biome = world_biome(x, z);
    if (biome != BIOME_PLAINS && biome != BIOME_FOREST) continue;
    if (random_next(random) > 0.25) continue;
    world_dig_pond(x, z);
  }
}

void world_build_house(Attributes &info, Integer origin_x, Integer ground_y, Integer origin_z)
// ----------------------------------------------------------------
// The starter house: a 7 x 7 cabin with a cobblestone floor_y, log
// corner posts, plank walls, a doorway facing -z, a window in each
// other wall and a stepped plank roof. Inside are a crafting table
// and a furnace. The ground is levelled under it and cleared around
// it. The spawn point is put inside.
// ----------------------------------------------------------------
{
  Integer x0     = origin_x;
  Integer z0     = origin_z;
  Integer x1     = origin_x + 6;
  Integer z1     = origin_z + 6;
  Integer floor_y  = ground_y;
  Integer x      = 0;
  Integer y      = 0;
  Integer z      = 0;
  Integer edge_x = 0;
  Integer edge_z = 0;
  Integer block  = 0;

  // Level: solid foundation below, open air above (one block of
  // margin all round so trees and plants don't touch the walls)
  for (x = x0 - 1; x <= x1 + 1; ++x) {
    for (z = z0 - 1; z <= z1 + 1; ++z) {
      for (y = floor_y + 1; y <= floor_y + 8; ++y) world_set_block(x, y, z, BLOCK_AIR);
      for (y = floor_y - 4; y <= floor_y; ++y) {
        if (!block_is_solid(world_get_block(x, y, z))) world_set_block(x, y, z, BLOCK_DIRT);
      }
      if (x < x0 || x > x1 || z < z0 || z > z1) world_set_block(x, floor_y, z, BLOCK_GRASS);
    }
  }

  for (x = x0; x <= x1; ++x) {
    for (z = z0; z <= z1; ++z) {
      edge_x = x == x0 || x == x1;
      edge_z = z == z0 || z == z1;

      world_set_block(x, floor_y, z, BLOCK_COBBLESTONE);

      for (y = floor_y + 1; y <= floor_y + 3; ++y) {
        block = BLOCK_AIR;
        if (edge_x || edge_z) block = BLOCK_PLANKS;
        if (edge_x && edge_z) block = BLOCK_OAK_LOG;
        world_set_block(x, y, z, block);
      }

      // Roof: a plank layer with log trim, then a smaller layer
      block = BLOCK_PLANKS;
      if (edge_x || edge_z) block = BLOCK_OAK_LOG;
      world_set_block(x, floor_y + 4, z, block);
      if (!edge_x && !edge_z) world_set_block(x, floor_y + 5, z, BLOCK_PLANKS);
    }
  }

  // Doorway in the middle of the -z wall, windows in the others
  world_set_block(x0 + 3, floor_y + 1, z0    , BLOCK_AIR);
  world_set_block(x0 + 3, floor_y + 2, z0    , BLOCK_AIR);
  world_set_block(x0    , floor_y + 2, z0 + 3, BLOCK_AIR);
  world_set_block(x1    , floor_y + 2, z0 + 3, BLOCK_AIR);
  world_set_block(x0 + 3, floor_y + 2, z1    , BLOCK_AIR);

  // Furniture along the back wall; the furnace faces the door
  world_set_block(x0 + 1, floor_y + 1, z1 - 1, BLOCK_CRAFTING_TABLE);
  world_set_block(x1 - 1, floor_y + 1, z1 - 1, BLOCK_FURNACE_NZ);

  record_set_integer(info, ATTR_HOUSE_X, x0);
  record_set_integer(info, ATTR_HOUSE_Y, floor_y);
  record_set_integer(info, ATTR_HOUSE_Z, z0);
  world_info_set_spawn(info, x0 + 3.5, floor_y + 1.0, z0 + 2.5);
}

void world_place_house_near(Attributes &info, Real spawn_x, Real spawn_z)
// ----------------------------------------------------------------
// Find the flattest dry spot for the starter house close to the
// spawn point, searching outwards in growing squares. If none is
// flat enough the house is built on the spawn point regardless
// (the foundation fills any dips).
// ----------------------------------------------------------------
{
  Integer centre_x = floor_integer(spawn_x) - 3;
  Integer centre_z = floor_integer(spawn_z) - 3;
  Integer radius   = 0;
  Integer x        = 0;
  Integer z        = 0;
  Integer ground   = 0;

  for (radius = 0; radius <= 24; ++radius) {
    for (x = centre_x - radius; x <= centre_x + radius; ++x) {
      for (z = centre_z - radius; z <= centre_z + radius; ++z) {
        if (Absolute(x - centre_x) != radius && Absolute(z - centre_z) != radius) continue;
        if (x < 3 || z < 3 || x + 10 > WORLD_SIZE_X || z + 10 > WORLD_SIZE_Z) continue;
        if (!world_area_is_flat(x - 1, z - 1, x + 7, z + 7, ground)) continue;
        world_build_house(info, x, ground, z);
        return;
      }
    }
  }

  x = clamp_integer(centre_x, 3, WORLD_SIZE_X - 10);
  z = clamp_integer(centre_z, 3, WORLD_SIZE_Z - 10);
  ground = g_height_map[world_column(x + 3, z + 3)];
  if (ground < SEA_LEVEL) ground = SEA_LEVEL;
  world_build_house(info, x, ground, z);
}

void world_find_spawn(Real &spawn_x, Real &spawn_y, Real &spawn_z)
// ----------------------------------------------------------------
// Pick the grass column nearest the middle of the world, searching
// outwards in growing squares
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
        spawn_x = x + 0.5;
        spawn_y = top + 1.0;
        spawn_z = z + 0.5;
        return;
      }
    }
  }

  // No land at all: stand on top of whatever is in the middle
  top = world_top_solid_y(centre_x, centre_z);
  if (top < SEA_LEVEL - 1) top = SEA_LEVEL - 1;
  spawn_x = centre_x + 0.5;
  spawn_y = top + 1.0;
  spawn_z = centre_z + 0.5;
}

void world_finish_maps()
// ----------------------------------------------------------------
// Work out the sky top of every column (after generating, and
// again after a save's edits are applied)
// ----------------------------------------------------------------
{
  Integer x = 0;
  Integer z = 0;

  for (x = 0; x < WORLD_SIZE_X; ++x) {
    for (z = 0; z < WORLD_SIZE_Z; ++z) {
      g_column_top[world_column(x, z)] = world_top_solid_y(x, z);
    }
  }
}

void world_generate(Attributes &info, Integer seed)
// ----------------------------------------------------------------
// Make the whole world from a seed: terrain and biomes, caves,
// coal and gravel, ponds, trees, plants, then the starter house
// near the middle where the player spawns
// ----------------------------------------------------------------
{
  Attributes random;
  Real       shift_a = 0.0;
  Real       shift_b = 0.0;
  Real       spawn_x = 0.0;
  Real       spawn_y = 0.0;
  Real       spawn_z = 0.0;

  world_info_clear (info, seed);
  world_seed_shifts(seed, shift_a, shift_b);
  random_seed      (random, seed);

  world_fill_columns(shift_a, shift_b);
  world_carve_caves (random);
  world_place_veins (random, BLOCK_COAL_ORE, COAL_VEINS, 6, 56);
  world_place_veins (random, BLOCK_GRAVEL, GRAVEL_POCKETS, 10, 50);
  world_add_ponds   (random);
  world_plant_trees (shift_a, shift_b);
  world_add_plants  (random, shift_a, shift_b);

  world_find_spawn      (spawn_x, spawn_y, spawn_z);
  world_info_set_spawn  (info, spawn_x, spawn_y, spawn_z);
  world_place_house_near(info, spawn_x, spawn_z);

  world_finish_maps();
}

#endif
