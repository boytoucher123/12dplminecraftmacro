#ifndef TEXTURES_H_INCLUDED
#define TEXTURES_H_INCLUDED

// ----------------------------------------------------------------
// 16 x 16 pixel textures, generated when the macro starts
// Each texture is a grid of palette indices. For drawing, the most
// common index is the base colour and every other colour is merged
// into rectangles, so a face is one base polygon plus a few rects.
// Sprites (plants and item pictures) use index 0 for see-through
// pixels: they have no base polygon, only rectangles.
//
// Table functions: everything here reads or writes the g_tex_*
// and g_rect_* tables. They are filled once by textures_init and
// are read-only afterwards.
// ----------------------------------------------------------------

#define TEX_SIZE               16
#define TEX_TRANSPARENT        0      // palette index of see-through pixels
#define TEX_BEDROCK            1
#define TEX_STONE              2
#define TEX_COBBLESTONE        3
#define TEX_DIRT               4
#define TEX_GRASS_TOP          5
#define TEX_GRASS_SIDE         6
#define TEX_LOG_SIDE           7
#define TEX_LOG_TOP            8
#define TEX_LEAVES             9
#define TEX_WATER              10
#define TEX_PLANKS             11
#define TEX_TABLE_TOP          12
#define TEX_TABLE_SIDE         13
#define TEX_FURNACE_FRONT      14
#define TEX_FURNACE_FRONT_LIT  15
#define TEX_FURNACE_SIDE       16
#define TEX_FURNACE_TOP        17
#define TEX_SAND               18
#define TEX_COW_HIDE           19
#define TEX_COW_FACE           20
#define TEX_SANDSTONE_TOP      21
#define TEX_SANDSTONE_SIDE     22
#define TEX_CACTUS_TOP         23
#define TEX_CACTUS_SIDE        24
#define TEX_COAL_ORE           25
#define TEX_GRAVEL             26
#define TEX_PLANT_GRASS        27     // plants and items are sprites:
#define TEX_PLANT_POPPY        28     // they have see-through pixels and
#define TEX_PLANT_DANDELION    29     // no base colour
#define TEX_PLANT_DEAD_BUSH    30
#define TEX_ITEM_STICK         31
#define TEX_ITEM_RAW_BEEF      32
#define TEX_ITEM_COOKED_BEEF   33
#define TEX_ITEM_COAL          34
#define TEX_ITEM_WOODEN_PICKAXE 35
#define TEX_ITEM_STONE_PICKAXE 36
#define TEX_ITEM_WOODEN_AXE    37
#define TEX_ITEM_STONE_AXE     38
#define TEX_ITEM_WOODEN_SHOVEL 39
#define TEX_ITEM_STONE_SHOVEL  40
#define TEX_ITEM_WOODEN_SWORD  41
#define TEX_ITEM_STONE_SWORD   42
#define NUM_TEXTURES           42

#define TEXTURE_PIXELS         10752  // NUM_TEXTURES * 256
#define PALETTE_SIZE           8      // colours per texture
#define TEXTURE_PALETTES       336    // NUM_TEXTURES * PALETTE_SIZE
#define TEXTURE_QUADRANTS      168    // NUM_TEXTURES * 4
#define MAX_TEXTURE_RECTS      6000

/*Global variables*/ {
  Integer g_tex_pixel     [TEXTURE_PIXELS];
  Integer g_tex_pal_r     [TEXTURE_PALETTES];
  Integer g_tex_pal_g     [TEXTURE_PALETTES];
  Integer g_tex_pal_b     [TEXTURE_PALETTES];
  Integer g_tex_base      [NUM_TEXTURES];   // 0 for sprites (no base polygon)
  Integer g_tex_is_sprite [NUM_TEXTURES];
  Real    g_tex_avg_r     [NUM_TEXTURES];
  Real    g_tex_avg_g     [NUM_TEXTURES];
  Real    g_tex_avg_b     [NUM_TEXTURES];
  Real    g_tex_quad_r    [TEXTURE_QUADRANTS];   // 2 x 2 average colours for icons
  Real    g_tex_quad_g    [TEXTURE_QUADRANTS];
  Real    g_tex_quad_b    [TEXTURE_QUADRANTS];
  Integer g_tex_rect_first[NUM_TEXTURES];
  Integer g_tex_rect_count[NUM_TEXTURES];

  Integer g_rect_total = 0;
  Real    g_rect_u0 [MAX_TEXTURE_RECTS];
  Real    g_rect_u1 [MAX_TEXTURE_RECTS];
  Real    g_rect_v0 [MAX_TEXTURE_RECTS];
  Real    g_rect_v1 [MAX_TEXTURE_RECTS];
  Integer g_rect_pal[MAX_TEXTURE_RECTS];
  Integer g_rect_area[MAX_TEXTURE_RECTS];   // in pixels, small ones are skipped at medium detail

  // Scratch space used while generating
  Integer g_tex_mark [256];
  Integer g_tex_count[PALETTE_SIZE];
  Real    g_tex_sum_r[4];
  Real    g_tex_sum_g[4];
  Real    g_tex_sum_b[4];
  Integer g_tex_sum_n[4];
  Real    g_cobble_u [9];
  Real    g_cobble_v [9];
}

void    textures_init          ();
void    texture_set_palette    (Integer tex, Integer index, Integer red, Integer green, Integer blue);
void    texture_set            (Integer tex, Integer u, Integer v, Integer index);
Integer texture_get            (Integer tex, Integer u, Integer v);
void    texture_fill           (Integer tex, Integer index);
void    texture_fill_rect      (Integer tex, Integer u0, Integer v0, Integer u1, Integer v1, Integer index);
Real    texture_random         (Integer tex, Integer u, Integer v, Integer salt);
Real    texture_noise          (Integer tex, Integer u, Integer v, Integer cell, Integer salt);
void    texture_copy           (Integer from_tex, Integer to_tex);
void    texture_row            (Integer tex, Integer v, Text pixels);
void    texture_finish         (Integer tex);
Integer texture_palette_index  (Integer tex, Integer index);

#endif
