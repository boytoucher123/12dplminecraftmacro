#ifndef TEXTURES_H_INCLUDED
#define TEXTURES_H_INCLUDED

// ----------------------------------------------------------------
// 16 x 16 pixel textures, generated when the macro starts (and
// replaced by a resource pack's images if one is chosen, see
// resource_pack.h)
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
#define TEX_IRON_ORE           27
#define TEX_PLANT_GRASS        28     // plants and items are sprites:
#define TEX_PLANT_POPPY        29     // they have see-through pixels and
#define TEX_PLANT_DANDELION    30     // no base colour
#define TEX_PLANT_DEAD_BUSH    31
#define TEX_ITEM_STICK         32
#define TEX_ITEM_RAW_BEEF      33
#define TEX_ITEM_COOKED_BEEF   34
#define TEX_ITEM_COAL          35
#define TEX_ITEM_IRON_INGOT    36
#define TEX_ITEM_WOODEN_PICKAXE 37
#define TEX_ITEM_STONE_PICKAXE 38
#define TEX_ITEM_IRON_PICKAXE  39
#define TEX_ITEM_WOODEN_AXE    40
#define TEX_ITEM_STONE_AXE     41
#define TEX_ITEM_IRON_AXE      42
#define TEX_ITEM_WOODEN_SHOVEL 43
#define TEX_ITEM_STONE_SHOVEL  44
#define TEX_ITEM_IRON_SHOVEL   45
#define TEX_ITEM_WOODEN_SWORD  46
#define TEX_ITEM_STONE_SWORD   47
#define TEX_ITEM_IRON_SWORD    48
#define NUM_TEXTURES           48
#define TEX_FIRST_SPRITE       TEX_PLANT_GRASS   // every texture from here on is a sprite

#define TEXTURE_PIXELS         12288  // NUM_TEXTURES * 256
#define PALETTE_SIZE           8      // colours per texture
#define TEXTURE_PALETTES       384    // NUM_TEXTURES * PALETTE_SIZE
#define TEXTURE_QUADRANTS      192    // NUM_TEXTURES * 4
#define MAX_TEXTURE_RECTS      12000  // resource pack images can need more than the built-in ones

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
void    textures_generate      ();
void    textures_finish_all    ();
Integer texture_is_sprite      (Integer p_tex);
void    texture_set_palette    (Integer p_tex, Integer p_index, Integer p_red, Integer p_green, Integer p_blue);
void    texture_set            (Integer p_tex, Integer p_u, Integer p_v, Integer p_index);
Integer texture_get            (Integer p_tex, Integer p_u, Integer p_v);
void    texture_fill           (Integer p_tex, Integer p_index);
void    texture_fill_rect      (Integer p_tex, Integer p_u0, Integer p_v0, Integer p_u1, Integer p_v1, Integer p_index);
Real    texture_random         (Integer p_tex, Integer p_u, Integer p_v, Integer p_salt);
Real    texture_noise          (Integer p_tex, Integer p_u, Integer p_v, Integer p_cell, Integer p_salt);
void    texture_copy           (Integer p_from_tex, Integer p_to_tex);
void    texture_row            (Integer p_tex, Integer p_v, Text p_pixels);
void    texture_finish         (Integer p_tex);
Integer texture_palette_index  (Integer p_tex, Integer p_index);

#endif
