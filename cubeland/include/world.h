#ifndef WORLD_H_INCLUDED
#define WORLD_H_INCLUDED

#include "config.h"
#include "records.h"

// ----------------------------------------------------------------
// The block grid and the seeded terrain generator
// Cell (x, y, z) has 0 <= x < WORLD_SIZE_X, 0 <= y < WORLD_HEIGHT,
// 0 <= z < WORLD_SIZE_Z and is stored at world_index(x, y, z)
// Columns are stored together, so y + 1 is the next array slot
//
// Table functions: everything that touches g_world and the column
// maps below. Only this module writes them; other modules read
// them through world_get_block and friends. Generation functions
// take the seed offsets and a random record as parameters.
// ----------------------------------------------------------------

#define BIOME_PLAINS        1
#define BIOME_FOREST        2
#define BIOME_DESERT        3
#define BIOME_BEACH         4
#define BIOME_OCEAN         5

#define MAX_CAVE_WORMS      14
#define CAVE_WORM_STEPS     90
#define COAL_VEINS          110
#define GRAVEL_POCKETS      40
#define MAX_PONDS           4

// The world record (spawn point and seed), see world_info_*
#define DATATYPE_WORLD_INFO ("world_info")
#define ATTR_WORLD_SEED     ("seed")
#define ATTR_SPAWN_X        ("spawn_x")
#define ATTR_SPAWN_Y        ("spawn_y")
#define ATTR_SPAWN_Z        ("spawn_z")
#define ATTR_SHIFT_A        ("shift_a")
#define ATTR_SHIFT_B        ("shift_b")
#define ATTR_HOUSE_X        ("house_x")
#define ATTR_HOUSE_Y        ("house_y")
#define ATTR_HOUSE_Z        ("house_z")

/*Global variables*/ {
  Integer g_world      [WORLD_CELLS];
  Integer g_height_map [WORLD_COLUMNS];   // y of the generated surface block
  Integer g_solid_below[WORLD_COLUMNS];   // as generated, every cell from 0 up to this y is solid
  Integer g_column_top [WORLD_COLUMNS];   // y of the highest block that blocks the sky (kept up to date)
  Integer g_biome_map  [WORLD_COLUMNS];
}

// ---------------------------------------------------------------- grid access
Integer world_index         (Integer x, Integer y, Integer z);
Integer world_column        (Integer x, Integer z);
Integer world_in_bounds     (Integer x, Integer y, Integer z);
Integer world_get_block     (Integer x, Integer y, Integer z);
void    world_set_block     (Integer x, Integer y, Integer z, Integer block);
Integer world_is_solid      (Integer x, Integer y, Integer z);
Integer world_top_solid_y   (Integer x, Integer z);
Integer world_sky_top       (Integer x, Integer z);
Integer world_solid_below   (Integer x, Integer z);
Integer world_biome         (Integer x, Integer z);
void    world_update_column_top(Integer x, Integer z);
void    world_break_block   (Attributes &events, Integer x, Integer y, Integer z, Integer tool_item);
void    world_place_block   (Attributes &events, Integer x, Integer y, Integer z, Integer block);

// ---------------------------------------------------------------- world record
void    world_info_clear    (Attributes &info, Integer seed);
Integer world_info_seed     (Attributes &info);
void    world_info_spawn    (Attributes &info, Real &x, Real &y, Real &z);
void    world_info_set_spawn(Attributes &info, Real x, Real y, Real z);

// ---------------------------------------------------------------- generation
void    world_seed_shifts   (Integer seed, Real &shift_a, Real &shift_b);
Real    world_value_noise   (Real x, Real z, Integer layer, Real shift_a, Real shift_b);
Integer world_column_biome  (Integer x, Integer z, Real shift_a, Real shift_b);
Integer world_terrain_height(Integer x, Integer z, Real shift_a, Real shift_b);
Real    world_desert_weight (Integer x, Integer z, Real shift_a, Real shift_b);
void    world_generate      (Attributes &info, Integer seed);
void    world_fill_columns  (Real shift_a, Real shift_b);
void    world_carve_sphere  (Real centre_x, Real centre_y, Real centre_z, Real radius);
void    world_carve_caves   (Attributes &random);
void    world_place_veins   (Attributes &random, Integer block, Integer count, Integer length, Integer max_y);
void    world_plant_tree    (Integer x, Integer ground_y, Integer z, Real shift_a, Real shift_b);
void    world_plant_trees   (Real shift_a, Real shift_b);
void    world_plant_cactus  (Integer x, Integer ground_y, Integer z, Integer tall);
void    world_add_plants    (Attributes &random, Real shift_a, Real shift_b);
void    world_mark_carved   (Integer x, Integer y, Integer z);
void    world_dig_pond      (Integer centre_x, Integer centre_z);
void    world_add_ponds     (Attributes &random);
Integer world_area_is_flat  (Integer x0, Integer z0, Integer x1, Integer z1, Integer &ground_y);
void    world_build_house   (Attributes &info, Integer origin_x, Integer ground_y, Integer origin_z);
void    world_find_spawn    (Real &spawn_x, Real &spawn_y, Real &spawn_z);
void    world_place_house_near(Attributes &info, Real spawn_x, Real spawn_z);
void    world_finish_maps   ();

#endif
