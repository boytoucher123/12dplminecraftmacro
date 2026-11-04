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
Integer world_index         (Integer p_x, Integer p_y, Integer p_z);
Integer world_column        (Integer p_x, Integer p_z);
Integer world_in_bounds     (Integer p_x, Integer p_y, Integer p_z);
Integer world_get_block     (Integer p_x, Integer p_y, Integer p_z);
void    world_set_block     (Integer p_x, Integer p_y, Integer p_z, Integer p_block);
Integer world_is_solid      (Integer p_x, Integer p_y, Integer p_z);
Integer world_top_solid_y   (Integer p_x, Integer p_z);
Integer world_sky_top       (Integer p_x, Integer p_z);
Integer world_solid_below   (Integer p_x, Integer p_z);
Integer world_biome         (Integer p_x, Integer p_z);
void    world_update_column_top(Integer p_x, Integer p_z);
void    world_break_block   (Attributes &p_events, Integer p_x, Integer p_y, Integer p_z, Integer p_tool_item);
void    world_place_block   (Attributes &p_events, Integer p_x, Integer p_y, Integer p_z, Integer p_block);

// ---------------------------------------------------------------- world record
void    world_info_clear    (Attributes &p_info, Integer p_seed);
Integer world_info_seed     (Attributes &p_info);
void    world_info_spawn    (Attributes &p_info, Real &p_x, Real &p_y, Real &p_z);
void    world_info_set_spawn(Attributes &p_info, Real p_x, Real p_y, Real p_z);

// ---------------------------------------------------------------- generation
void    world_seed_shifts   (Integer p_seed, Real &p_shift_a, Real &p_shift_b);
Real    world_value_noise   (Real p_x, Real p_z, Integer p_layer, Real p_shift_a, Real p_shift_b);
Integer world_column_biome  (Integer p_x, Integer p_z, Real p_shift_a, Real p_shift_b);
Integer world_terrain_height(Integer p_x, Integer p_z, Real p_shift_a, Real p_shift_b);
Real    world_desert_weight (Integer p_x, Integer p_z, Real p_shift_a, Real p_shift_b);
void    world_generate      (Attributes &p_info, Integer p_seed);
void    world_fill_columns  (Real p_shift_a, Real p_shift_b);
void    world_carve_sphere  (Real p_centre_x, Real p_centre_y, Real p_centre_z, Real p_radius);
void    world_carve_caves   (Attributes &p_random);
void    world_place_veins   (Attributes &p_random, Integer p_block, Integer p_count, Integer p_length, Integer p_max_y);
void    world_plant_tree    (Integer p_x, Integer p_ground_y, Integer p_z, Real p_shift_a, Real p_shift_b);
void    world_plant_trees   (Real p_shift_a, Real p_shift_b);
void    world_plant_cactus  (Integer p_x, Integer p_ground_y, Integer p_z, Integer p_tall);
void    world_add_plants    (Attributes &p_random, Real p_shift_a, Real p_shift_b);
void    world_mark_carved   (Integer p_x, Integer p_y, Integer p_z);
void    world_dig_pond      (Integer p_centre_x, Integer p_centre_z);
void    world_add_ponds     (Attributes &p_random);
Integer world_area_is_flat  (Integer p_x0, Integer p_z0, Integer p_x1, Integer p_z1, Integer &p_ground_y);
void    world_build_house   (Attributes &p_info, Integer p_origin_x, Integer p_ground_y, Integer p_origin_z);
void    world_find_spawn    (Real &p_spawn_x, Real &p_spawn_y, Real &p_spawn_z);
void    world_place_house_near(Attributes &p_info, Real p_spawn_x, Real p_spawn_z);
void    world_finish_maps   ();

#endif
