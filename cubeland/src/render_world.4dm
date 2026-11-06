#ifndef RENDER_WORLD_4DM_INCLUDED
#define RENDER_WORLD_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/blocks.h"
#include "../include/textures.h"
#include "../include/world.h"
#include "../include/mesh.h"
#include "../include/player.h"
#include "../include/cows.h"
#include "../include/slots.h"
#include "../include/drops.h"
#include "../include/furnace.h"
#include "../include/records.h"
#include "../include/settings.h"
#include "../include/render.h"

// ---------------------------------------------------------------- set up

void render_init()
// ----------------------------------------------------------------
// One-off set up: the crack pattern and default detail
// ----------------------------------------------------------------
{
  g_crack_u0[1] = 0.50; g_crack_v0[1] = 0.50; g_crack_u1[1] = 0.30; g_crack_v1[1] = 0.62;
  g_crack_u0[2] = 0.50; g_crack_v0[2] = 0.50; g_crack_u1[2] = 0.66; g_crack_v1[2] = 0.36;
  g_crack_u0[3] = 0.30; g_crack_v0[3] = 0.62; g_crack_u1[3] = 0.14; g_crack_v1[3] = 0.56;
  g_crack_u0[4] = 0.66; g_crack_v0[4] = 0.36; g_crack_u1[4] = 0.80; g_crack_v1[4] = 0.20;
  g_crack_u0[5] = 0.50; g_crack_v0[5] = 0.50; g_crack_u1[5] = 0.57; g_crack_v1[5] = 0.80;
  g_crack_u0[6] = 0.50; g_crack_v0[6] = 0.50; g_crack_u1[6] = 0.36; g_crack_v1[6] = 0.28;
  g_crack_u0[7] = 0.57; g_crack_v0[7] = 0.80; g_crack_u1[7] = 0.72; g_crack_v1[7] = 0.90;
  g_crack_u0[8] = 0.36; g_crack_v0[8] = 0.28; g_crack_u1[8] = 0.22; g_crack_v1[8] = 0.14;

  render_set_detail(2);
}

void render_set_detail(Integer p_level)
// ----------------------------------------------------------------
// Texture detail: 1 = low (textures only up close), 2 = normal,
// 3 = high (all 16 x 16 pixels from further out). Faces smaller
// on screen than these sizes get fewer texture rectangles.
// ----------------------------------------------------------------
{
  if (p_level <= 1) {
    g_lod_full_pixels  = 150.0;
    g_lod_major_pixels = 64.0;
    g_view_plant_range = 10;
  } else if (p_level == 2) {
    g_lod_full_pixels  = 96.0;
    g_lod_major_pixels = 40.0;
    g_view_plant_range = 16;
  } else {
    g_lod_full_pixels  = 48.0;
    g_lod_major_pixels = 24.0;
    g_view_plant_range = 24;
  }
}

void render_view_from(Attributes &p_player, Attributes &p_settings, Real p_time_of_day, Real p_now)
// ----------------------------------------------------------------
// Copy what this frame needs from the player and settings records
// into the renderer's frame globals (the only place they're set)
// ----------------------------------------------------------------
{
  g_render_distance   = settings_render_distance(p_settings);
  g_view_plants       = settings_flag(p_settings, ATTR_SET_PLANTS);
  g_view_shading      = settings_flag(p_settings, ATTR_SET_SHADING);
  g_view_eye_in_water = player_eye_in_water(p_player);
  g_view_target_kind  = player_target_kind(p_player);
  g_view_break_stage  = player_break_stage(p_player, p_now);
  g_view_break_x      = record_integer(p_player, ATTR_BREAK_X);
  g_view_break_y      = record_integer(p_player, ATTR_BREAK_Y);
  g_view_break_z      = record_integer(p_player, ATTR_BREAK_Z);
  player_target_cell(p_player, g_view_target_x, g_view_target_y, g_view_target_z);
  render_set_detail(settings_detail(p_settings));
  g_view_time     = p_time_of_day;
  g_view_now      = p_now;
  g_view_daylight = world_daylight(p_time_of_day);

  // Spread the squared distances out over the buckets
  g_bucket_scale = (MAX_BUCKETS - 1.0) / (g_render_distance * g_render_distance + 60.0);
}

Text render_stats_text()
// ----------------------------------------------------------------
// One line of drawing statistics for the last frame
// ----------------------------------------------------------------
{
  return "faces " + To_text(g_stat_faces) + "   polygons " + To_text(g_stat_polygons) + "   sections " + To_text(g_stat_sections);
}

// ---------------------------------------------------------------- 2D helpers

void render_set_colour(Draw_Box p_box, Real p_red, Real p_green, Real p_blue)
// ----------------------------------------------------------------
// Set both the pen and the fill to one colour, so polygons have no
// differently coloured outline (and neighbours leave no gaps)
// ----------------------------------------------------------------
{
  Integer l_r = to_byte(p_red);
  Integer l_g = to_byte(p_green);
  Integer l_b = to_byte(p_blue);

  Set_colour     (p_box, l_r, l_g, l_b);
  Set_fill_colour(p_box, l_r, l_g, l_b);
}

void render_set_face_colour(Draw_Box p_box, Real p_red, Real p_green, Real p_blue)
// ----------------------------------------------------------------
// render_set_colour without the range checks, for face colours,
// which are always in range: palette * keep + add never passes 255
// because keep + fog <= 1 (see render_draw_face)
// ----------------------------------------------------------------
{
  Integer l_r = Floor(p_red);
  Integer l_g = Floor(p_green);
  Integer l_b = Floor(p_blue);

  Set_colour     (p_box, l_r, l_g, l_b);
  Set_fill_colour(p_box, l_r, l_g, l_b);
}

void render_fill_rect(Draw_Box p_box, Real p_x0, Real p_y0, Real p_x1, Real p_y1)
// ----------------------------------------------------------------
// Filled axis aligned rectangle in screen coordinates
// ----------------------------------------------------------------
{
  g_poly_x[1] = p_x0;
  g_poly_y[1] = p_y0;
  g_poly_x[2] = p_x1;
  g_poly_y[2] = p_y0;
  g_poly_x[3] = p_x1;
  g_poly_y[3] = p_y1;
  g_poly_x[4] = p_x0;
  g_poly_y[4] = p_y1;
  Draw_polygon(p_box, 4, g_poly_x, g_poly_y);
}

void render_line(Draw_Box p_box, Real p_x0, Real p_y0, Real p_x1, Real p_y1)
// ----------------------------------------------------------------
// Line in screen coordinates
// ----------------------------------------------------------------
{
  Move_to(p_box, p_x0, p_y0);
  Draw_to(p_box, p_x1, p_y1);
}

// ---------------------------------------------------------------- camera

void render_setup_camera(Real p_w, Real p_h, Real p_view_bottom, Real p_eye_x, Real p_eye_y, Real p_eye_z,
                         Real p_yaw, Real p_pitch, Real p_field_of_view)
// ----------------------------------------------------------------
// Camera at (eye_x, eye_y, eye_z) looking along yaw and pitch, for
// a w x h view whose bottom view_bottom pixels are covered by the
// status strip; field_of_view is horizontal, in radians
// ----------------------------------------------------------------
{
  Real l_cos_yaw   = Cos(p_yaw);
  Real l_sin_yaw   = Sin(p_yaw);
  Real l_cos_pitch = Cos(p_pitch);
  Real l_sin_pitch = Sin(p_pitch);
  Real l_tan_x     = 0.0;
  Real l_tan_y     = 0.0;

  g_screen_w    = p_w;
  g_screen_h    = p_h;
  g_view_bottom = p_view_bottom;
  g_centre_x    = p_w / 2.0;
  g_centre_y    = p_view_bottom + (p_h - p_view_bottom) / 2.0;
  g_focal       = (p_w / 2.0) * Cos(p_field_of_view / 2.0) / Sin(p_field_of_view / 2.0);
  g_view_pitch  = p_pitch;

  g_cam_x = p_eye_x;
  g_cam_y = p_eye_y;
  g_cam_z = p_eye_z;

  g_fwd_x   =  l_cos_pitch * l_cos_yaw;
  g_fwd_y   =  l_sin_pitch;
  g_fwd_z   =  l_cos_pitch * l_sin_yaw;
  g_right_x = -l_sin_yaw;
  g_right_z =  l_cos_yaw;
  g_up_x    = -l_sin_pitch * l_cos_yaw;
  g_up_y    =  l_cos_pitch;
  g_up_z    = -l_sin_pitch * l_sin_yaw;

  // Frustum side planes (with a little margin) for culling
  l_tan_x = (p_w / 2.0 + 8.0) / g_focal;
  l_tan_y = ((p_h - p_view_bottom) / 2.0 + 8.0) / g_focal;
  g_cull_cos_x = 1.0 / Sqrt(1.0 + l_tan_x * l_tan_x);
  g_cull_sin_x = l_tan_x * g_cull_cos_x;
  g_cull_cos_y = 1.0 / Sqrt(1.0 + l_tan_y * l_tan_y);
  g_cull_sin_y = l_tan_y * g_cull_cos_y;

  // Fog
  g_fog_end   = g_render_distance;
  g_fog_start = g_render_distance * 0.55;
  render_sky_colours(g_view_time);
  if (g_view_eye_in_water) {
    g_fog_start = 2.0;
    g_fog_end   = min_real(16.0, g_fog_end);
    g_fog_r     = 30.0;
    g_fog_g     = 62.0;
    g_fog_b     = 140.0;
  }
}

void render_to_camera(Real p_rel_x, Real p_rel_y, Real p_rel_z)
// ----------------------------------------------------------------
// Rotate a vector from the eye into camera space (x right, y up,
// z forward); the result is left in g_tc_x, g_tc_y, g_tc_z
// ----------------------------------------------------------------
{
  g_tc_x = p_rel_x * g_right_x + p_rel_z * g_right_z;
  g_tc_y = p_rel_x * g_up_x    + p_rel_y * g_up_y    + p_rel_z * g_up_z;
  g_tc_z = p_rel_x * g_fwd_x   + p_rel_y * g_fwd_y   + p_rel_z * g_fwd_z;
}

Integer render_sphere_visible(Real p_rel_x, Real p_rel_y, Real p_rel_z, Real p_radius)
// ----------------------------------------------------------------
// FALSE if a sphere (centre relative to the eye) is certainly
// outside the view: behind the camera or past a side of the screen
// ----------------------------------------------------------------
{
  render_to_camera(p_rel_x, p_rel_y, p_rel_z);

  if (g_tc_z < -p_radius) return FALSE;
  if ( g_tc_x * g_cull_cos_x - g_tc_z * g_cull_sin_x > p_radius) return FALSE;
  if (-g_tc_x * g_cull_cos_x - g_tc_z * g_cull_sin_x > p_radius) return FALSE;
  if ( g_tc_y * g_cull_cos_y - g_tc_z * g_cull_sin_y > p_radius) return FALSE;
  if (-g_tc_y * g_cull_cos_y - g_tc_z * g_cull_sin_y > p_radius) return FALSE;
  return TRUE;
}

// ---------------------------------------------------------------- collecting faces

void render_add_face(Real p_c0x, Real p_c0y, Real p_c0z, Real p_e1x, Real p_e1y, Real p_e1z, Real p_e2x, Real p_e2y, Real p_e2z,
                     Integer p_tex, Real p_shade, Real p_distance_squared, Real p_size, Real p_tint, Integer p_crack)
// ----------------------------------------------------------------
// Queue a face for drawing. Corners are c0, c0 + e1, c0 + e1 + e2
// and c0 + e2 in camera space; e1 runs along the texture's u and e2
// along v (up the texture). distance_squared orders the painting,
// size (the face's width in blocks) picks the level of detail.
// ----------------------------------------------------------------
{
  Real    l_z1       = p_c0z + p_e1z;
  Real    l_z2       = p_c0z + p_e1z + p_e2z;
  Real    l_z3       = p_c0z + p_e2z;
  Real    l_distance = 0.0;
  Real    l_fog      = 0.0;
  Real    l_pixels   = 0.0;
  Integer l_bucket   = 0;
  Integer l_face     = 0;

  if (g_face_total >= MAX_DRAW_FACES) return;
  if (p_c0z < NEAR_PLANE && l_z1 < NEAR_PLANE && l_z2 < NEAR_PLANE && l_z3 < NEAR_PLANE) return;

  l_distance = Sqrt(p_distance_squared);
  l_fog      = clamp_real((l_distance - g_fog_start) / (g_fog_end - g_fog_start), 0.0, 1.0);
  if (l_fog >= 0.999) return;

  ++g_face_total;
  l_face = g_face_total;

  g_df_c0x[l_face] = p_c0x;
  g_df_c0y[l_face] = p_c0y;
  g_df_c0z[l_face] = p_c0z;
  g_df_e1x[l_face] = p_e1x;
  g_df_e1y[l_face] = p_e1y;
  g_df_e1z[l_face] = p_e1z;
  g_df_e2x[l_face] = p_e2x;
  g_df_e2y[l_face] = p_e2y;
  g_df_e2z[l_face] = p_e2z;
  g_df_tex   [l_face] = p_tex;
  g_df_shade [l_face] = p_shade;
  g_df_fog   [l_face] = l_fog;
  g_df_tint  [l_face] = p_tint;
  g_df_crack [l_face] = p_crack;
  l_pixels = g_focal * p_size / max_real(l_distance, 0.1);
  g_df_detail[l_face] = DETAIL_FLAT;
  if (l_pixels > g_lod_major_pixels) g_df_detail[l_face] = DETAIL_MAJOR;
  if (l_pixels > g_lod_full_pixels ) g_df_detail[l_face] = DETAIL_FULL;
  g_df_front [l_face] = p_c0z >= NEAR_PLANE && l_z1 >= NEAR_PLANE && l_z2 >= NEAR_PLANE && l_z3 >= NEAR_PLANE;

  l_bucket = Floor(p_distance_squared * g_bucket_scale) + 1;
  if (l_bucket > MAX_BUCKETS) l_bucket = MAX_BUCKETS;
  if (l_bucket < 1) l_bucket = 1;
  g_df_next[l_face]       = g_bucket_head[l_bucket];
  g_bucket_head[l_bucket] = l_face;
}

void render_add_block_face(Attributes &p_furnaces, Integer p_x, Integer p_y, Integer p_z, Integer p_direction, Integer p_block,
                           Real p_distance_squared, Integer p_crack, Real p_light)
// ----------------------------------------------------------------
// Queue one face of the block at cell (x, y, z), lit by light
// (0..1, from the mesh)
// The face corners are built from the camera space images of the
// three world axes, so each corner is just a few additions
// ----------------------------------------------------------------
{
  Real    l_rel_x = p_x - g_cam_x;
  Real    l_rel_y = p_y - g_cam_y;
  Real    l_rel_z = p_z - g_cam_z;
  // camera space images of the unit x, y and z axes
  Real    l_ax_x  = g_right_x;
  Real    l_ax_y  = g_up_x;
  Real    l_ax_z  = g_fwd_x;
  Real    l_ay_y  = g_up_y;
  Real    l_ay_z  = g_fwd_y;
  Real    l_az_x  = g_right_z;
  Real    l_az_y  = g_up_z;
  Real    l_az_z  = g_fwd_z;
  Real    l_ox    = l_rel_x * l_ax_x + l_rel_z * l_az_x;
  Real    l_oy    = l_rel_x * l_ax_y + l_rel_y * l_ay_y + l_rel_z * l_az_y;
  Real    l_oz    = l_rel_x * l_ax_z + l_rel_y * l_ay_z + l_rel_z * l_az_z;
  Real    l_top   = 1.0;
  Integer l_tex   = block_face_texture(p_block, p_direction);
  Real    l_shade = block_face_shade(p_direction) * p_light;

  if (p_block == BLOCK_WATER) {
    l_top = WATER_TOP;
    // Ripples: light and dark bands drift across the surface
    if (p_direction == DIR_PY) {
      l_shade = l_shade * (1.0 + 0.08 * Sin(p_x * 0.9 + p_z * 0.6 + g_view_now * 1.8)
                               + 0.05 * Sin(p_z * 1.3 - p_x * 0.4 + g_view_now * 2.7));
    }
  }
  if (l_tex == TEX_FURNACE_FRONT) {
    if (furnace_is_lit(p_furnaces, p_x, p_y, p_z)) {
      l_tex   = TEX_FURNACE_FRONT_LIT;
      l_shade = block_face_shade(p_direction);
    }
  }

  if (p_direction == DIR_PX) {
    render_add_face(l_ox + l_ax_x + l_az_x, l_oy + l_ax_y + l_az_y, l_oz + l_ax_z + l_az_z,
                    -l_az_x, -l_az_y, -l_az_z,  0.0, l_ay_y * l_top, l_ay_z * l_top,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  } else if (p_direction == DIR_NX) {
    render_add_face(l_ox, l_oy, l_oz,
                    l_az_x, l_az_y, l_az_z,  0.0, l_ay_y * l_top, l_ay_z * l_top,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  } else if (p_direction == DIR_PY) {
    render_add_face(l_ox, l_oy + l_ay_y * l_top, l_oz + l_ay_z * l_top,
                    l_ax_x, l_ax_y, l_ax_z,  l_az_x, l_az_y, l_az_z,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  } else if (p_direction == DIR_NY) {
    render_add_face(l_ox + l_az_x, l_oy + l_az_y, l_oz + l_az_z,
                    l_ax_x, l_ax_y, l_ax_z,  -l_az_x, -l_az_y, -l_az_z,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  } else if (p_direction == DIR_PZ) {
    render_add_face(l_ox + l_az_x, l_oy + l_az_y, l_oz + l_az_z,
                    l_ax_x, l_ax_y, l_ax_z,  0.0, l_ay_y * l_top, l_ay_z * l_top,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  } else {
    render_add_face(l_ox + l_ax_x, l_oy + l_ax_y, l_oz + l_ax_z,
                    -l_ax_x, -l_ax_y, -l_ax_z,  0.0, l_ay_y * l_top, l_ay_z * l_top,
                    l_tex, l_shade, p_distance_squared, 1.0, 0.0, p_crack);
  }
}

void render_add_sprite(Real p_rel_x, Real p_rel_y, Real p_rel_z, Real p_half_width, Real p_height, Integer p_tex,
                       Real p_shade, Real p_distance_squared)
// ----------------------------------------------------------------
// Queue a picture standing upright at (rel_x, rel_y, rel_z)
// (bottom centre, relative to the eye) that turns to face the
// camera: plants and dropped items that aren't blocks
// ----------------------------------------------------------------
{
  render_to_camera(p_rel_x, p_rel_y, p_rel_z);
  if (g_tc_z < NEAR_PLANE) return;

  render_add_face(g_tc_x - p_half_width, g_tc_y, g_tc_z,
                  p_half_width * 2.0, 0.0, 0.0,
                  0.0, g_up_y * p_height, g_fwd_y * p_height,
                  p_tex, p_shade, p_distance_squared, p_half_width * 2.0, 0.0, 0);
}

void render_collect_blocks(Attributes &p_furnaces)
// ----------------------------------------------------------------
// Walk the cached face lists of the sections in view and queue the
// faces that point towards the eye, are within the view distance
// and inside the screen
// ----------------------------------------------------------------
{
  Integer l_range     = g_render_distance;
  Real    l_range_sq  = l_range * l_range;
  Integer l_sx0       = clamp_integer(floor_integer((g_cam_x - l_range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer l_sx1       = clamp_integer(floor_integer((g_cam_x + l_range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer l_sy0       = clamp_integer(floor_integer((g_cam_y - l_range) / SECTION_SIZE), 0, SECTIONS_Y - 1);
  Integer l_sy1       = clamp_integer(floor_integer((g_cam_y + l_range) / SECTION_SIZE), 0, SECTIONS_Y - 1);
  Integer l_sz0       = clamp_integer(floor_integer((g_cam_z - l_range) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  Integer l_sz1       = clamp_integer(floor_integer((g_cam_z + l_range) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  Integer l_sx        = 0;
  Integer l_sy        = 0;
  Integer l_sz        = 0;
  Integer l_section   = 0;
  Integer l_start     = 0;
  Integer l_last      = 0;
  Integer l_entry     = 0;
  Integer l_x         = 0;
  Integer l_y         = 0;
  Integer l_z         = 0;
  Integer l_direction = 0;
  Integer l_group     = 0;
  Integer l_block     = 0;
  Integer l_crack     = 0;
  Integer l_stage     = g_view_break_stage;
  Integer l_plant_sq  = g_view_plant_range * g_view_plant_range;
  Integer l_entry_tex = 0;
  Real    l_light     = 1.0;
  Integer l_code      = 0;
  Integer l_torch     = 0;
  Integer l_sky       = 0;
  Integer l_vertical  = min_integer(l_range, VERTICAL_RANGE);
  Real    l_centre_x  = 0.0;
  Real    l_centre_y  = 0.0;
  Real    l_centre_z  = 0.0;
  Real    l_reach     = 0.0;
  Real    l_rel_x     = 0.0;
  Real    l_rel_y     = 0.0;
  Real    l_rel_z     = 0.0;
  Real    l_dist_sq   = 0.0;
  Real    l_normal_x  = 0.0;
  Real    l_normal_y  = 0.0;
  Real    l_normal_z  = 0.0;

  l_reach = l_range + SECTION_RADIUS;

  // Not much is worth drawing far above or below the eye
  l_sy0 = clamp_integer(floor_integer((g_cam_y - l_vertical) / SECTION_SIZE), 0, SECTIONS_Y - 1);
  l_sy1 = clamp_integer(floor_integer((g_cam_y + l_vertical) / SECTION_SIZE), 0, SECTIONS_Y - 1);

  for (l_sx = l_sx0; l_sx <= l_sx1; ++l_sx) {
    for (l_sz = l_sz0; l_sz <= l_sz1; ++l_sz) {
      for (l_sy = l_sy0; l_sy <= l_sy1; ++l_sy) {
        l_centre_x = l_sx * SECTION_SIZE + 8.0 - g_cam_x;
        l_centre_y = l_sy * SECTION_SIZE + 8.0 - g_cam_y;
        l_centre_z = l_sz * SECTION_SIZE + 8.0 - g_cam_z;
        if (l_centre_x * l_centre_x + l_centre_y * l_centre_y + l_centre_z * l_centre_z > l_reach * l_reach) continue;
        if (!render_sphere_visible(l_centre_x, l_centre_y, l_centre_z, SECTION_RADIUS)) continue;

        l_section = mesh_ensure_section(l_sx, l_sy, l_sz);
        if (g_section_count[l_section] == 0) continue;
        ++g_stat_sections;

        for (l_group = 1; l_group <= NUM_FACE_GROUPS; ++l_group) {
          // Skip a direction whose faces all point away from the eye
          if (l_group == DIR_PX && g_cam_x <= l_sx * SECTION_SIZE + 1.0 ) continue;
          if (l_group == DIR_NX && g_cam_x >= l_sx * SECTION_SIZE + 15.0) continue;
          if (l_group == DIR_PY && g_cam_y <= l_sy * SECTION_SIZE + 1.0 && !g_view_eye_in_water) continue;
          if (l_group == DIR_NY && g_cam_y >= l_sy * SECTION_SIZE + 15.0) continue;
          if (l_group == DIR_PZ && g_cam_z <= l_sz * SECTION_SIZE + 1.0 ) continue;
          if (l_group == DIR_NZ && g_cam_z >= l_sz * SECTION_SIZE + 15.0) continue;

          if (l_group == DIR_PLANT && !g_view_plants) continue;

          l_start = (l_section - 1) * SECTION_FACE_CAP + g_section_dir_start[(l_section - 1) * NUM_FACE_GROUPS + l_group];
          l_last  = l_start + g_section_dir_count[(l_section - 1) * NUM_FACE_GROUPS + l_group] - 1;
          for (l_entry = l_start; l_entry <= l_last; ++l_entry) {
            l_direction = g_face_dir[l_entry];
            if (l_direction > DIR_WET_FLAG) {
              if (!g_view_eye_in_water) continue;
              l_direction = l_direction - DIR_WET_FLAG;
            }
            l_x = g_face_x[l_entry];
            l_y = g_face_y[l_entry];
            l_z = g_face_z[l_entry];
            l_rel_x = l_x - g_cam_x;
            l_rel_y = l_y - g_cam_y;
            l_rel_z = l_z - g_cam_z;
            // Sky light (dimmed at night) or torch light, whichever is brighter
            l_code  = g_face_light[l_entry];
            l_torch = 0;
            if (l_code >= FACE_TORCH_SCALE) l_torch = Floor(l_code / (1.0 * FACE_TORCH_SCALE));
            l_sky   = l_code - FACE_TORCH_SCALE * l_torch;
            if (!g_view_shading) l_sky = LIGHT_FULL;
            l_light = max_real(l_sky * g_view_daylight, l_torch * 1.0) / LIGHT_FULL;

            // Plants: a picture facing the camera, only fairly close
            if (l_direction == DIR_PLANT) {
              l_dist_sq = (l_rel_x + 0.5) * (l_rel_x + 0.5) + (l_rel_y + 0.5) * (l_rel_y + 0.5) + (l_rel_z + 0.5) * (l_rel_z + 0.5);
              if (l_dist_sq > l_plant_sq || l_dist_sq > l_range_sq) continue;
              if (!render_sphere_visible(l_rel_x + 0.5, l_rel_y + 0.5, l_rel_z + 0.5, 0.72)) continue;
              l_entry_tex = block_plant_texture(world_cell_block(g_world[world_index(l_x, l_y, l_z)]));
              if (l_entry_tex > 0) render_add_sprite(l_rel_x + 0.5, l_rel_y, l_rel_z + 0.5, PLANT_HALF_WIDTH, 0.9, l_entry_tex, l_light, l_dist_sq);
              continue;
            }

            // Only faces that point towards the eye (water surfaces
            // can be seen from either side)
            l_normal_x = 0.0;
            l_normal_y = 0.0;
            l_normal_z = 0.0;
            if (l_direction == DIR_PX) {
              if (l_rel_x + 1.0 >= 0.0) continue;
              l_normal_x = 1.0;
            } else if (l_direction == DIR_NX) {
              if (l_rel_x <= 0.0) continue;
              l_normal_x = -1.0;
            } else if (l_direction == DIR_PY) {
              if (l_rel_y + 1.0 >= 0.0) {
                if (!g_view_eye_in_water) continue;
                if (world_cell_block(g_world[world_index(l_x, l_y, l_z)]) != BLOCK_WATER) continue;
              }
              l_normal_y = 1.0;
            } else if (l_direction == DIR_NY) {
              if (l_rel_y <= 0.0) continue;
              l_normal_y = -1.0;
            } else if (l_direction == DIR_PZ) {
              if (l_rel_z + 1.0 >= 0.0) continue;
              l_normal_z = 1.0;
            } else {
              if (l_rel_z <= 0.0) continue;
              l_normal_z = -1.0;
            }

            l_dist_sq = (l_rel_x + 0.5) * (l_rel_x + 0.5) + (l_rel_y + 0.5) * (l_rel_y + 0.5) + (l_rel_z + 0.5) * (l_rel_z + 0.5);
            if (l_dist_sq > l_range_sq) continue;
            if (!render_sphere_visible(l_rel_x + 0.5 + l_normal_x * 0.5, l_rel_y + 0.5 + l_normal_y * 0.5, l_rel_z + 0.5 + l_normal_z * 0.5, 0.72)) continue;

            l_block = world_cell_block(g_world[world_index(l_x, l_y, l_z)]);
            l_crack = 0;
            if (l_stage > 0) {
              if (l_x == g_view_break_x && l_y == g_view_break_y && l_z == g_view_break_z) l_crack = l_stage;
            }
            render_add_block_face(p_furnaces, l_x, l_y, l_z, l_direction, l_block, l_dist_sq, l_crack, l_light);
          }
        }
      }
    }
  }
}

Real render_side_shade(Real p_normal_x, Real p_normal_z)
// ----------------------------------------------------------------
// Light level of an upright face of an entity box from its normal,
// matching block_face_shade for faces that line up with the grid
// ----------------------------------------------------------------
{
  return 0.70 * p_normal_x * p_normal_x + 0.84 * p_normal_z * p_normal_z;
}

void render_add_box(Real p_centre_x, Real p_centre_y, Real p_centre_z, Real p_yaw, Real p_half_f, Real p_half_y, Real p_half_s,
                    Integer p_tex_side, Integer p_tex_top, Integer p_tex_front, Integer p_tex_back, Real p_tint)
// ----------------------------------------------------------------
// Queue the visible faces of an upright box turned to yaw
// half_f is its half length along the facing direction, half_s its
// half width and half_y its half height. tex_front is drawn on the
// face it looks out of, tex_back on the opposite one, tex_side on
// the left and right and tex_top on the top and bottom. On the
// sides and the top the texture's u runs from the back to the
// front, so both sides show the same picture (mirrored, like a
// model's left and right legs).
// ----------------------------------------------------------------
{
  Real    l_facing_x = Cos(p_yaw);
  Real    l_facing_z = Sin(p_yaw);
  Real    l_side_x   = -l_facing_z;
  Real    l_side_z   =  l_facing_x;
  Real    l_rel_x    = p_centre_x - g_cam_x;
  Real    l_rel_y    = p_centre_y - g_cam_y;
  Real    l_rel_z    = p_centre_z - g_cam_z;
  Real    l_dist_sq  = l_rel_x * l_rel_x + l_rel_y * l_rel_y + l_rel_z * l_rel_z;
  Real    l_size     = 2.0 * max_real(p_half_f, max_real(p_half_y, p_half_s));
  Real    l_eye_f    = -(l_rel_x * l_facing_x + l_rel_z * l_facing_z);
  Real    l_eye_s    = -(l_rel_x * l_side_x   + l_rel_z * l_side_z);
  Real    l_eye_y    = -l_rel_y;
  Real    l_m_x      = 0.0;
  Real    l_m_y      = 0.0;
  Real    l_m_z      = 0.0;
  Real    l_f_x      = 0.0;
  Real    l_f_y      = 0.0;
  Real    l_f_z      = 0.0;
  Real    l_u_x      = 0.0;
  Real    l_u_y      = 0.0;
  Real    l_u_z      = 0.0;
  Real    l_s_x      = 0.0;
  Real    l_s_y      = 0.0;
  Real    l_s_z      = 0.0;

  if (l_dist_sq > g_render_distance * g_render_distance) return;
  if (!render_sphere_visible(l_rel_x, l_rel_y, l_rel_z, Sqrt(p_half_f * p_half_f + p_half_y * p_half_y + p_half_s * p_half_s))) return;

  // Corner with the lowest f, y and s, and the three edge vectors,
  // all in camera space
  render_to_camera(l_rel_x - l_facing_x * p_half_f - l_side_x * p_half_s, l_rel_y - p_half_y, l_rel_z - l_facing_z * p_half_f - l_side_z * p_half_s);
  l_m_x = g_tc_x;
  l_m_y = g_tc_y;
  l_m_z = g_tc_z;
  render_to_camera(l_facing_x * p_half_f * 2.0, 0.0, l_facing_z * p_half_f * 2.0);
  l_f_x = g_tc_x;
  l_f_y = g_tc_y;
  l_f_z = g_tc_z;
  render_to_camera(0.0, p_half_y * 2.0, 0.0);
  l_u_x = g_tc_x;
  l_u_y = g_tc_y;
  l_u_z = g_tc_z;
  render_to_camera(l_side_x * p_half_s * 2.0, 0.0, l_side_z * p_half_s * 2.0);
  l_s_x = g_tc_x;
  l_s_y = g_tc_y;
  l_s_z = g_tc_z;

  if (l_eye_f > p_half_f) {
    render_add_face(l_m_x + l_f_x + l_s_x, l_m_y + l_f_y + l_s_y, l_m_z + l_f_z + l_s_z, -l_s_x, -l_s_y, -l_s_z, l_u_x, l_u_y, l_u_z,
                    p_tex_front, g_box_light * render_side_shade(l_facing_x, l_facing_z), l_dist_sq, l_size, p_tint, 0);
  }
  if (l_eye_f < -p_half_f) {
    render_add_face(l_m_x, l_m_y, l_m_z, l_s_x, l_s_y, l_s_z, l_u_x, l_u_y, l_u_z,
                    p_tex_back, g_box_light * render_side_shade(l_facing_x, l_facing_z), l_dist_sq, l_size, p_tint, 0);
  }
  if (l_eye_s > p_half_s) {
    render_add_face(l_m_x + l_s_x, l_m_y + l_s_y, l_m_z + l_s_z, l_f_x, l_f_y, l_f_z, l_u_x, l_u_y, l_u_z,
                    p_tex_side, g_box_light * render_side_shade(l_side_x, l_side_z), l_dist_sq, l_size, p_tint, 0);
  }
  if (l_eye_s < -p_half_s) {
    render_add_face(l_m_x, l_m_y, l_m_z, l_f_x, l_f_y, l_f_z, l_u_x, l_u_y, l_u_z,
                    p_tex_side, g_box_light * render_side_shade(l_side_x, l_side_z), l_dist_sq, l_size, p_tint, 0);
  }
  if (l_eye_y > p_half_y) {
    render_add_face(l_m_x + l_u_x, l_m_y + l_u_y, l_m_z + l_u_z, l_f_x, l_f_y, l_f_z, l_s_x, l_s_y, l_s_z,
                    p_tex_top, g_box_light, l_dist_sq, l_size, p_tint, 0);
  }
  if (l_eye_y < -p_half_y) {
    render_add_face(l_m_x + l_s_x, l_m_y + l_s_y, l_m_z + l_s_z, l_f_x, l_f_y, l_f_z, -l_s_x, -l_s_y, -l_s_z,
                    p_tex_top, 0.55 * g_box_light, l_dist_sq, l_size, p_tint, 0);
  }
}

Real render_light_at(Real p_x, Real p_y, Real p_z)
// ----------------------------------------------------------------
// Light (0..1) for an entity at a point: daylight, or the torch
// light of its cell if that is brighter
// ----------------------------------------------------------------
{
  Real l_torch = world_get_light(floor_integer(p_x), floor_integer(p_y), floor_integer(p_z)) / (1.0 * LIGHT_MAX_LEVEL);

  return max_real(g_view_daylight, l_torch);
}

void render_mob_part(Real p_mob_x, Real p_mob_y, Real p_mob_z, Real p_yaw, Real p_along, Real p_up, Real p_across,
                     Real p_half_f, Real p_half_y, Real p_half_s, Integer p_tex_side, Integer p_tex_top, Integer p_tex_front,
                     Integer p_tex_back, Real p_tint)
// ----------------------------------------------------------------
// One box of an animal with its own textures, placed relative to
// its feet and facing
// ----------------------------------------------------------------
{
  Real l_facing_x = Cos(p_yaw);
  Real l_facing_z = Sin(p_yaw);

  render_add_box(p_mob_x + l_facing_x * p_along - l_facing_z * p_across,
                 p_mob_y + p_up,
                 p_mob_z + l_facing_z * p_along + l_facing_x * p_across,
                 p_yaw, p_half_f, p_half_y, p_half_s, p_tex_side, p_tex_top, p_tex_front, p_tex_back, p_tint);
}

void render_zombie(Real p_x, Real p_y, Real p_z, Real p_yaw, Real p_swing, Real p_tint)
// ----------------------------------------------------------------
// A zombie: two legs, a body, arms held out in front and a head
// ----------------------------------------------------------------
{
  //              position                  along     up     across  half f  half y  half s  side                   top                  front             back
  render_mob_part(p_x, p_y, p_z, p_yaw,  p_swing, 0.375,  0.12, 0.12, 0.375, 0.12, TEX_ZOMBIE_PANTS     , TEX_ZOMBIE_PANTS     , TEX_ZOMBIE_PANTS, TEX_ZOMBIE_PANTS    , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw, -p_swing, 0.375, -0.12, 0.12, 0.375, 0.12, TEX_ZOMBIE_PANTS     , TEX_ZOMBIE_PANTS     , TEX_ZOMBIE_PANTS, TEX_ZOMBIE_PANTS    , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.0    , 1.125,  0.0 , 0.13, 0.375, 0.25, TEX_ZOMBIE_SHIRT_SIDE, TEX_ZOMBIE_SHIRT_SIDE, TEX_ZOMBIE_SHIRT, TEX_ZOMBIE_SHIRT    , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.30   , 1.38 ,  0.37, 0.32, 0.11, 0.11, TEX_ZOMBIE_ARM       , TEX_ZOMBIE_ARM       , TEX_ZOMBIE_SKIN , TEX_ZOMBIE_SHIRT_SIDE, p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.30   , 1.38 , -0.37, 0.32, 0.11, 0.11, TEX_ZOMBIE_ARM       , TEX_ZOMBIE_ARM       , TEX_ZOMBIE_SKIN , TEX_ZOMBIE_SHIRT_SIDE, p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.0    , 1.65 ,  0.0 , 0.25, 0.25, 0.25, TEX_ZOMBIE_HEAD_SIDE , TEX_ZOMBIE_HEAD_TOP  , TEX_ZOMBIE_FACE , TEX_ZOMBIE_HEAD_SIDE, p_tint);
}

void render_cow(Real p_x, Real p_y, Real p_z, Real p_yaw, Real p_swing, Real p_tint)
// ----------------------------------------------------------------
// A cow, sized like the block game's model (1 pixel of its skin is
// 1/16 block): a 12 x 10 x 18 body on four 4 x 12 legs, an 8 x 8 x 6
// head with two small horns. The model is moved back 0.15 so it
// sits over the cow's collision box.
// ----------------------------------------------------------------
{
  //              position                  along             up      across  half f  half y  half s  side              top               front             back
  render_mob_part(p_x, p_y, p_z, p_yaw, -0.150          , 1.0625,  0.0  , 0.5625, 0.3125, 0.375 , TEX_COW_HIDE     , TEX_COW_BODY_TOP , TEX_COW_BODY_END , TEX_COW_BODY_END , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.5375         , 1.25  ,  0.0  , 0.1875, 0.25  , 0.25  , TEX_COW_HEAD_SIDE, TEX_COW_HEAD_TOP , TEX_COW_FACE     , TEX_COW_HEAD_SIDE, p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.570          , 1.47  ,  0.28 , 0.031 , 0.094 , 0.031 , TEX_COW_HORN     , TEX_COW_HORN     , TEX_COW_HORN     , TEX_COW_HORN     , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.570          , 1.47  , -0.28 , 0.031 , 0.094 , 0.031 , TEX_COW_HORN     , TEX_COW_HORN     , TEX_COW_HORN     , TEX_COW_HORN     , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.1625 + p_swing, 0.375 ,  0.25 , 0.125 , 0.375 , 0.125 , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw,  0.1625 - p_swing, 0.375 , -0.25 , 0.125 , 0.375 , 0.125 , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw, -0.5875 - p_swing, 0.375 ,  0.25 , 0.125 , 0.375 , 0.125 , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , p_tint);
  render_mob_part(p_x, p_y, p_z, p_yaw, -0.5875 + p_swing, 0.375 , -0.25 , 0.125 , 0.375 , 0.125 , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , TEX_COW_LEG      , p_tint);
}

void render_collect_cows(Attributes &p_cows)
// ----------------------------------------------------------------
// Queue every cow in view: body, head and four swinging legs
// ----------------------------------------------------------------
{
  Integer l_cow   = 0;
  Integer l_live  = 0;
  Real    l_tint  = 0.0;
  Real    l_swing = 0.0;
  Real    l_x     = 0.0;
  Real    l_y     = 0.0;
  Real    l_z     = 0.0;
  Real    l_yaw   = 0.0;

  for (l_live = 1; l_live <= slots_count(SLOT_POOL_MOBS); ++l_live) {
    l_cow = slots_at(SLOT_POOL_MOBS, l_live);
    cow_position(p_cows, l_cow, l_x, l_y, l_z);
    if ((l_x - g_cam_x) * (l_x - g_cam_x) + (l_z - g_cam_z) * (l_z - g_cam_z) > (g_render_distance + 2.0) * (g_render_distance + 2.0)) continue;

    g_box_light = render_light_at(l_x, l_y + 1.0, l_z);
    l_yaw  = cow_yaw(p_cows, l_cow);
    l_tint = 0.0;
    if (cow_flash(p_cows, l_cow) > 0.0) l_tint = 0.55;
    l_swing = Sin(cow_step(p_cows, l_cow)) * 0.09;
    if (mob_kind(p_cows, l_cow) == MOB_ZOMBIE) {
      render_zombie(l_x, l_y, l_z, l_yaw, l_swing * 1.6, l_tint);
      continue;
    }

    render_cow(l_x, l_y, l_z, l_yaw, l_swing, l_tint);
  }
}

void render_collect_drops(Attributes &p_drops)
// ----------------------------------------------------------------
// Queue dropped items: blocks as small spinning, bobbing cubes,
// everything else as its picture facing the camera
// ----------------------------------------------------------------
{
  Integer l_drop    = 0;
  Integer l_live    = 0;
  Integer l_item    = 0;
  Real    l_bob     = 0.0;
  Real    l_age     = 0.0;
  Real    l_x       = 0.0;
  Real    l_y       = 0.0;
  Real    l_z       = 0.0;
  Real    l_dist_sq = 0.0;

  for (l_live = 1; l_live <= slots_count(SLOT_POOL_DROPS); ++l_live) {
    l_drop = slots_at(SLOT_POOL_DROPS, l_live);
    l_item = drop_item(p_drops, l_drop);
    l_age  = drop_age (p_drops, l_drop);
    drop_position(p_drops, l_drop, l_x, l_y, l_z);
    l_bob = 0.06 + Sin(l_age * 3.0) * 0.05;
    g_box_light = render_light_at(l_x, l_y + 0.3, l_z);

    if (item_is_block(l_item)) {
      render_add_box(l_x, l_y + DROP_HALF_SIZE + l_bob, l_z, l_age * 1.8, DROP_HALF_SIZE, DROP_HALF_SIZE, DROP_HALF_SIZE,
                     item_side_texture(l_item), item_top_texture(l_item), item_side_texture(l_item), item_side_texture(l_item), 0.0);
    } else {
      l_dist_sq = (l_x - g_cam_x) * (l_x - g_cam_x) + (l_y - g_cam_y) * (l_y - g_cam_y) + (l_z - g_cam_z) * (l_z - g_cam_z);
      if (l_dist_sq > g_render_distance * g_render_distance) continue;
      if (!render_sphere_visible(l_x - g_cam_x, l_y + 0.2 - g_cam_y, l_z - g_cam_z, 0.3)) continue;
      render_add_sprite(l_x - g_cam_x, l_y + l_bob - g_cam_y, l_z - g_cam_z, 0.2, 0.4, item_sprite_texture(l_item), 0.95 * g_box_light, l_dist_sq);
    }
  }
}

// ---------------------------------------------------------------- drawing faces

void render_clip_screen_edge(Integer p_axis, Real p_limit, Integer p_keep_above)
// ----------------------------------------------------------------
// Clip the screen polygon in g_poly_x/y (g_clip_count points)
// against one edge: axis 1 = x, 2 = y; keeps the side above limit
// if keep_above, else the side below
// ----------------------------------------------------------------
{
  Integer l_count  = 0;
  Integer l_point  = 0;
  Integer l_next   = 0;
  Real    l_value  = 0.0;
  Real    l_other  = 0.0;
  Integer l_inside = 0;
  Integer l_next_inside = 0;
  Real    l_t      = 0.0;

  for (l_point = 1; l_point <= g_clip_count; ++l_point) {
    l_next = l_point + 1;
    if (l_next > g_clip_count) l_next = 1;

    l_value = g_poly_x[l_point];
    l_other = g_poly_x[l_next];
    if (p_axis == 2) {
      l_value = g_poly_y[l_point];
      l_other = g_poly_y[l_next];
    }
    l_inside      = l_value >= p_limit;
    l_next_inside = l_other >= p_limit;
    if (!p_keep_above) {
      l_inside      = l_value <= p_limit;
      l_next_inside = l_other <= p_limit;
    }

    if (l_inside) {
      ++l_count;
      g_temp_x[l_count] = g_poly_x[l_point];
      g_temp_y[l_count] = g_poly_y[l_point];
    }
    if (l_inside != l_next_inside) {
      l_t = (p_limit - l_value) / (l_other - l_value);
      ++l_count;
      g_temp_x[l_count] = g_poly_x[l_point] + (g_poly_x[l_next] - g_poly_x[l_point]) * l_t;
      g_temp_y[l_count] = g_poly_y[l_point] + (g_poly_y[l_next] - g_poly_y[l_point]) * l_t;
    }
  }

  for (l_point = 1; l_point <= l_count; ++l_point) {
    g_poly_x[l_point] = g_temp_x[l_point];
    g_poly_y[l_point] = g_temp_y[l_point];
  }
  g_clip_count = l_count;
}

Integer render_clip_and_draw(Draw_Box p_box)
// ----------------------------------------------------------------
// Draw the camera space polygon in g_clip_x/y/z (g_clip_count
// points): clip it to the near plane (unless the face is known to
// be in front), project it, clip it to the screen if it reaches far
// outside, and fill it. Returns TRUE if anything was drawn.
// ----------------------------------------------------------------
{
  Integer l_count       = 0;
  Integer l_point       = 0;
  Integer l_next        = 0;
  Integer l_inside      = 0;
  Integer l_next_inside = 0;
  Integer l_far_out     = FALSE;
  Real    l_t           = 0.0;
  Real    l_scale       = 0.0;

  if (!g_q_front) {
    for (l_point = 1; l_point <= g_clip_count; ++l_point) {
      l_next = l_point + 1;
      if (l_next > g_clip_count) l_next = 1;
      l_inside      = g_clip_z[l_point] >= NEAR_PLANE;
      l_next_inside = g_clip_z[l_next ] >= NEAR_PLANE;
      if (l_inside) {
        ++l_count;
        g_temp_x[l_count] = g_clip_x[l_point];
        g_temp_y[l_count] = g_clip_y[l_point];
        g_temp_z[l_count] = g_clip_z[l_point];
      }
      if (l_inside != l_next_inside) {
        l_t = (NEAR_PLANE - g_clip_z[l_point]) / (g_clip_z[l_next] - g_clip_z[l_point]);
        ++l_count;
        g_temp_x[l_count] = g_clip_x[l_point] + (g_clip_x[l_next] - g_clip_x[l_point]) * l_t;
        g_temp_y[l_count] = g_clip_y[l_point] + (g_clip_y[l_next] - g_clip_y[l_point]) * l_t;
        g_temp_z[l_count] = NEAR_PLANE;
      }
    }
    if (l_count < 3) return FALSE;
    for (l_point = 1; l_point <= l_count; ++l_point) {
      g_clip_x[l_point] = g_temp_x[l_point];
      g_clip_y[l_point] = g_temp_y[l_point];
      g_clip_z[l_point] = g_temp_z[l_point];
    }
    g_clip_count = l_count;
  }

  for (l_point = 1; l_point <= g_clip_count; ++l_point) {
    l_scale = g_focal / g_clip_z[l_point];
    g_poly_x[l_point] = g_centre_x + g_clip_x[l_point] * l_scale;
    g_poly_y[l_point] = g_centre_y + g_clip_y[l_point] * l_scale;
    if (g_poly_x[l_point] < -GUARD_BAND || g_poly_x[l_point] > g_screen_w + GUARD_BAND) l_far_out = TRUE;
    if (g_poly_y[l_point] < -GUARD_BAND || g_poly_y[l_point] > g_screen_h + GUARD_BAND) l_far_out = TRUE;
  }

  if (l_far_out) {
    render_clip_screen_edge(1, -2.0, TRUE);
    if (g_clip_count >= 3) render_clip_screen_edge(1, g_screen_w + 2.0, FALSE);
    if (g_clip_count >= 3) render_clip_screen_edge(2, -2.0, TRUE);
    if (g_clip_count >= 3) render_clip_screen_edge(2, g_screen_h + 2.0, FALSE);
    if (g_clip_count < 3) return FALSE;
  }

  Draw_polygon(p_box, g_clip_count, g_poly_x, g_poly_y);
  ++g_stat_polygons;
  return TRUE;
}

void render_quad(Draw_Box p_box, Real p_u0, Real p_v0, Real p_u1, Real p_v1)
// ----------------------------------------------------------------
// Draw the part u0..u1, v0..v1 of the current face (g_q_*)
// Because a face is flat, a point on it is c0 + u e1 + v e2 in
// camera space, which keeps the perspective exact
// ----------------------------------------------------------------
{
  Real l_scale = 0.0;
  Real l_x     = 0.0;
  Real l_y     = 0.0;
  Real l_z     = 0.0;

  // Whole face in front of the camera and well inside the guard
  // band: every part of it can be projected and drawn directly
  if (g_q_safe) {
    l_x = g_q_c0x + p_u0 * g_q_e1x + p_v0 * g_q_e2x;
    l_y = g_q_c0y + p_u0 * g_q_e1y + p_v0 * g_q_e2y;
    l_z = g_q_c0z + p_u0 * g_q_e1z + p_v0 * g_q_e2z;
    l_scale = g_focal / l_z;
    g_poly_x[1] = g_centre_x + l_x * l_scale;
    g_poly_y[1] = g_centre_y + l_y * l_scale;
    l_x = g_q_c0x + p_u1 * g_q_e1x + p_v0 * g_q_e2x;
    l_y = g_q_c0y + p_u1 * g_q_e1y + p_v0 * g_q_e2y;
    l_z = g_q_c0z + p_u1 * g_q_e1z + p_v0 * g_q_e2z;
    l_scale = g_focal / l_z;
    g_poly_x[2] = g_centre_x + l_x * l_scale;
    g_poly_y[2] = g_centre_y + l_y * l_scale;
    l_x = g_q_c0x + p_u1 * g_q_e1x + p_v1 * g_q_e2x;
    l_y = g_q_c0y + p_u1 * g_q_e1y + p_v1 * g_q_e2y;
    l_z = g_q_c0z + p_u1 * g_q_e1z + p_v1 * g_q_e2z;
    l_scale = g_focal / l_z;
    g_poly_x[3] = g_centre_x + l_x * l_scale;
    g_poly_y[3] = g_centre_y + l_y * l_scale;
    l_x = g_q_c0x + p_u0 * g_q_e1x + p_v1 * g_q_e2x;
    l_y = g_q_c0y + p_u0 * g_q_e1y + p_v1 * g_q_e2y;
    l_z = g_q_c0z + p_u0 * g_q_e1z + p_v1 * g_q_e2z;
    l_scale = g_focal / l_z;
    g_poly_x[4] = g_centre_x + l_x * l_scale;
    g_poly_y[4] = g_centre_y + l_y * l_scale;
    Draw_polygon(p_box, 4, g_poly_x, g_poly_y);
    ++g_stat_polygons;
    return;
  }

  g_clip_x[1] = g_q_c0x + p_u0 * g_q_e1x + p_v0 * g_q_e2x;
  g_clip_y[1] = g_q_c0y + p_u0 * g_q_e1y + p_v0 * g_q_e2y;
  g_clip_z[1] = g_q_c0z + p_u0 * g_q_e1z + p_v0 * g_q_e2z;
  g_clip_x[2] = g_q_c0x + p_u1 * g_q_e1x + p_v0 * g_q_e2x;
  g_clip_y[2] = g_q_c0y + p_u1 * g_q_e1y + p_v0 * g_q_e2y;
  g_clip_z[2] = g_q_c0z + p_u1 * g_q_e1z + p_v0 * g_q_e2z;
  g_clip_x[3] = g_q_c0x + p_u1 * g_q_e1x + p_v1 * g_q_e2x;
  g_clip_y[3] = g_q_c0y + p_u1 * g_q_e1y + p_v1 * g_q_e2y;
  g_clip_z[3] = g_q_c0z + p_u1 * g_q_e1z + p_v1 * g_q_e2z;
  g_clip_x[4] = g_q_c0x + p_u0 * g_q_e1x + p_v1 * g_q_e2x;
  g_clip_y[4] = g_q_c0y + p_u0 * g_q_e1y + p_v1 * g_q_e2y;
  g_clip_z[4] = g_q_c0z + p_u0 * g_q_e1z + p_v1 * g_q_e2z;
  g_clip_count = 4;

  render_clip_and_draw(p_box);
}

void render_face_line(Draw_Box p_box, Real p_u0, Real p_v0, Real p_u1, Real p_v1)
// ----------------------------------------------------------------
// Draw a line across the current face between two (u, v) points
// Lines that cross the near plane are shortened to it
// ----------------------------------------------------------------
{
  Real l_x0 = g_q_c0x + p_u0 * g_q_e1x + p_v0 * g_q_e2x;
  Real l_y0 = g_q_c0y + p_u0 * g_q_e1y + p_v0 * g_q_e2y;
  Real l_z0 = g_q_c0z + p_u0 * g_q_e1z + p_v0 * g_q_e2z;
  Real l_x1 = g_q_c0x + p_u1 * g_q_e1x + p_v1 * g_q_e2x;
  Real l_y1 = g_q_c0y + p_u1 * g_q_e1y + p_v1 * g_q_e2y;
  Real l_z1 = g_q_c0z + p_u1 * g_q_e1z + p_v1 * g_q_e2z;
  Real l_t  = 0.0;

  if (l_z0 < NEAR_PLANE && l_z1 < NEAR_PLANE) return;
  if (l_z0 < NEAR_PLANE) {
    l_t  = (NEAR_PLANE - l_z0) / (l_z1 - l_z0);
    l_x0 = l_x0 + (l_x1 - l_x0) * l_t;
    l_y0 = l_y0 + (l_y1 - l_y0) * l_t;
    l_z0 = NEAR_PLANE;
  } else if (l_z1 < NEAR_PLANE) {
    l_t  = (NEAR_PLANE - l_z1) / (l_z0 - l_z1);
    l_x1 = l_x1 + (l_x0 - l_x1) * l_t;
    l_y1 = l_y1 + (l_y0 - l_y1) * l_t;
    l_z1 = NEAR_PLANE;
  }

  render_line(p_box, g_centre_x + l_x0 * g_focal / l_z0, g_centre_y + l_y0 * g_focal / l_z0,
                   g_centre_x + l_x1 * g_focal / l_z1, g_centre_y + l_y1 * g_focal / l_z1);
}

void render_palette_colour(Draw_Box p_box, Integer p_tex, Integer p_index)
// ----------------------------------------------------------------
// Set the colour of palette entry index of a texture, lit and
// fogged for the current face
// ----------------------------------------------------------------
{
  Integer l_slot = texture_palette_index(p_tex, p_index);

  render_set_face_colour(p_box, g_tex_pal_r[l_slot] * g_q_keep + g_q_add_r,
                         g_tex_pal_g[l_slot] * g_q_keep + g_q_add_g,
                         g_tex_pal_b[l_slot] * g_q_keep + g_q_add_b);
}

void render_draw_face(Draw_Box p_box, Integer p_face)
// ----------------------------------------------------------------
// Paint one queued face: the base colour over the whole face, then
// (when close enough) the rectangles of the texture's other colours
// ----------------------------------------------------------------
{
  Integer l_tex     = g_df_tex[p_face];
  Integer l_detail  = g_df_detail[p_face];
  Real    l_fog     = g_df_fog[p_face];
  Real    l_tint    = g_df_tint[p_face];
  Real    l_lit     = g_df_shade[p_face] * (1.0 - l_fog);
  Integer l_rect    = 0;
  Integer l_first   = 0;
  Integer l_last    = 0;
  Integer l_segment = 0;
  Integer l_colour  = 0;
  Integer l_corner  = 0;
  Real    l_x       = 0.0;
  Real    l_y       = 0.0;
  Real    l_z       = 0.0;
  Real    l_px      = 0.0;
  Real    l_py      = 0.0;

  g_q_c0x   = g_df_c0x[p_face];
  g_q_c0y   = g_df_c0y[p_face];
  g_q_c0z   = g_df_c0z[p_face];
  g_q_e1x   = g_df_e1x[p_face];
  g_q_e1y   = g_df_e1y[p_face];
  g_q_e1z   = g_df_e1z[p_face];
  g_q_e2x   = g_df_e2x[p_face];
  g_q_e2y   = g_df_e2y[p_face];
  g_q_e2z   = g_df_e2z[p_face];
  g_q_front = g_df_front[p_face];

  // Safe to project parts of the face directly if all four corners
  // are in front of the camera and inside the guard band
  g_q_safe = g_q_front;
  if (g_q_safe) {
    for (l_corner = 1; l_corner <= 4; ++l_corner) {
      l_x = g_q_c0x;
      l_y = g_q_c0y;
      l_z = g_q_c0z;
      if (l_corner == 2 || l_corner == 3) {
        l_x = l_x + g_q_e1x;
        l_y = l_y + g_q_e1y;
        l_z = l_z + g_q_e1z;
      }
      if (l_corner >= 3) {
        l_x = l_x + g_q_e2x;
        l_y = l_y + g_q_e2y;
        l_z = l_z + g_q_e2z;
      }
      l_px = g_centre_x + l_x * g_focal / l_z;
      l_py = g_centre_y + l_y * g_focal / l_z;
      if (l_px < -GUARD_BAND || l_px > g_screen_w + GUARD_BAND) g_q_safe = FALSE;
      if (l_py < -GUARD_BAND || l_py > g_screen_h + GUARD_BAND) g_q_safe = FALSE;
    }
  }

  // colour = palette * keep + add (shade, red hurt flash, then fog)
  g_q_keep  = l_lit * (1.0 - l_tint);
  g_q_add_r = l_fog * g_fog_r + l_lit * l_tint * 230.0;
  g_q_add_g = l_fog * g_fog_g + l_lit * l_tint * 40.0;
  g_q_add_b = l_fog * g_fog_b + l_lit * l_tint * 30.0;

  // Pictures have no base colour: never draw them as one block of
  // colour, at least their larger patches
  if (g_tex_is_sprite[l_tex] && l_detail == DETAIL_FLAT) l_detail = DETAIL_MAJOR;

  if (l_detail == DETAIL_FLAT) {
    render_set_face_colour(p_box, g_tex_avg_r[l_tex] * g_q_keep + g_q_add_r,
                           g_tex_avg_g[l_tex] * g_q_keep + g_q_add_g,
                           g_tex_avg_b[l_tex] * g_q_keep + g_q_add_b);
    render_quad(p_box, 0.0, 0.0, 1.0, 1.0);
  } else {
    if (g_tex_base[l_tex] > 0) {
      render_palette_colour(p_box, l_tex, g_tex_base[l_tex]);
      render_quad(p_box, 0.0, 0.0, 1.0, 1.0);
    }

    l_first = g_tex_rect_first[l_tex];
    l_last  = l_first + g_tex_rect_count[l_tex] - 1;
    // Rectangles are grouped by colour, so the colour is only set
    // when it changes
    l_colour = 0;
    for (l_rect = l_first; l_rect <= l_last; ++l_rect) {
      if (l_detail == DETAIL_MAJOR && g_rect_area[l_rect] < MAJOR_RECT_AREA) continue;
      if (g_rect_pal[l_rect] != l_colour) {
        l_colour = g_rect_pal[l_rect];
        render_palette_colour(p_box, l_tex, l_colour);
      }
      render_quad(p_box, g_rect_u0[l_rect], g_rect_v0[l_rect], g_rect_u1[l_rect], g_rect_v1[l_rect]);
    }
  }

  if (g_df_crack[p_face] > 0) {
    render_set_colour(p_box, 24.0 * g_q_keep + g_q_add_r, 22.0 * g_q_keep + g_q_add_g, 20.0 * g_q_keep + g_q_add_b);
    for (l_segment = 1; l_segment <= g_df_crack[p_face] * 2; ++l_segment) {
      render_face_line(p_box, g_crack_u0[l_segment], g_crack_v0[l_segment], g_crack_u1[l_segment], g_crack_v1[l_segment]);
    }
  }
}

void render_draw_faces(Draw_Box p_box)
// ----------------------------------------------------------------
// Paint every queued face, farthest bucket first
// ----------------------------------------------------------------
{
  Integer l_bucket = 0;
  Integer l_face   = 0;

  for (l_bucket = MAX_BUCKETS; l_bucket >= 1; --l_bucket) {
    l_face = g_bucket_head[l_bucket];
    while (l_face > 0) {
      render_draw_face(p_box, l_face);
      l_face = g_df_next[l_face];
    }
  }
}

// ---------------------------------------------------------------- sky and overlays

void render_sky_colours(Real p_time_of_day)
// ----------------------------------------------------------------
// Horizon (fog) and overhead sky colours for a time of day: blue by
// day, dark navy at night, orange at the horizon around sunrise and
// sunset
// ----------------------------------------------------------------
{
  Real l_day    = clamp_real((world_sun_height(p_time_of_day) + 0.15) / 0.45, 0.0, 1.0);
  Real l_glow   = 1.0 - clamp_real(Absolute(world_sun_height(p_time_of_day)) / 0.25, 0.0, 1.0);

  g_fog_r     = lerp_real(14.0, 170.0, l_day);
  g_fog_g     = lerp_real(18.0, 205.0, l_day);
  g_fog_b     = lerp_real(34.0, 245.0, l_day);
  g_sky_top_r = lerp_real(4.0 , 92.0 , l_day);
  g_sky_top_g = lerp_real(6.0 , 146.0, l_day);
  g_sky_top_b = lerp_real(18.0, 232.0, l_day);

  // sunrise and sunset glow at the horizon
  g_fog_r = lerp_real(g_fog_r, 236.0, l_glow * 0.65);
  g_fog_g = lerp_real(g_fog_g, 140.0, l_glow * 0.65);
  g_fog_b = lerp_real(g_fog_b, 84.0 , l_glow * 0.65);
}

void render_sky_disc(Draw_Box p_box, Real p_dir_x, Real p_dir_y, Real p_dir_z, Real p_size, Integer p_moon)
// ----------------------------------------------------------------
// The sun (a bright square with a paler core) or the moon (a pale
// square with darker patches) in a direction from the eye
// ----------------------------------------------------------------
{
  Real l_px   = 0.0;
  Real l_py   = 0.0;
  Real l_size = g_focal * p_size;

  render_to_camera(p_dir_x, p_dir_y, p_dir_z);
  if (g_tc_z <= 0.1) return;
  l_px = g_centre_x + g_tc_x * g_focal / g_tc_z;
  l_py = g_centre_y + g_tc_y * g_focal / g_tc_z;
  if (p_moon) {
    render_set_colour(p_box, 214.0, 218.0, 226.0);
    render_fill_rect(p_box, l_px - l_size, l_py - l_size, l_px + l_size, l_py + l_size);
    render_set_colour(p_box, 168.0, 172.0, 184.0);
    render_fill_rect(p_box, l_px - l_size * 0.5, l_py + l_size * 0.1, l_px - l_size * 0.1, l_py + l_size * 0.5);
    render_fill_rect(p_box, l_px + l_size * 0.2, l_py - l_size * 0.5, l_px + l_size * 0.55, l_py - l_size * 0.2);
  } else {
    render_set_colour(p_box, 255.0, 246.0, 200.0);
    render_fill_rect(p_box, l_px - l_size, l_py - l_size, l_px + l_size, l_py + l_size);
    render_set_colour(p_box, 255.0, 255.0, 236.0);
    render_fill_rect(p_box, l_px - l_size * 0.6, l_py - l_size * 0.6, l_px + l_size * 0.6, l_py + l_size * 0.6);
  }
}

void render_stars(Draw_Box p_box, Real p_brightness)
// ----------------------------------------------------------------
// Fixed stars over the sky, fading in as the light goes
// ----------------------------------------------------------------
{
  Integer l_star  = 0;
  Real    l_x     = 0.0;
  Real    l_y     = 0.0;
  Real    l_z     = 0.0;
  Real    l_px    = 0.0;
  Real    l_py    = 0.0;
  Real    l_level = 0.0;

  for (l_star = 1; l_star <= NUM_STARS; ++l_star) {
    l_x = hash_real(l_star * 1.0, 3.7, 11.0) * 2.0 - 1.0;
    l_z = hash_real(l_star * 1.0, 8.1, 5.0) * 2.0 - 1.0;
    l_y = 0.15 + hash_real(l_star * 1.0, 1.3, 7.0);
    render_to_camera(l_x, l_y, l_z);
    if (g_tc_z <= 0.1) continue;
    l_px = g_centre_x + g_tc_x * g_focal / g_tc_z;
    l_py = g_centre_y + g_tc_y * g_focal / g_tc_z;
    if (l_px < 0.0 || l_px > g_screen_w || l_py < g_view_bottom || l_py > g_screen_h) continue;
    l_level = p_brightness * (150.0 + 100.0 * hash_real(l_star * 1.0, 2.0, 2.0));
    render_set_colour(p_box, lerp_real(g_sky_top_r, 255.0, l_level / 255.0), lerp_real(g_sky_top_g, 255.0, l_level / 255.0), lerp_real(g_sky_top_b, 240.0, l_level / 255.0));
    render_fill_rect(p_box, l_px - 1.0, l_py - 1.0, l_px + 1.0, l_py + 1.0);
  }
}

void render_sky(Draw_Box p_box)
// ----------------------------------------------------------------
// Sky gradient (pale at the horizon, deep blue overhead, both
// following the time of day), a haze below the horizon, stars, the
// sun and the moon. Under water: murky blue.
// ----------------------------------------------------------------
{
  Real    l_horizon  = g_centre_y - g_focal * Sin(g_view_pitch) / Cos(g_view_pitch);
  Real    l_band_h   = (g_screen_h - g_view_bottom) / 16.0;
  Real    l_y0       = 0.0;
  Real    l_y1       = 0.0;
  Real    l_height   = 0.0;
  Real    l_amount   = 0.0;
  Real    l_sun_x    = 0.42;
  Real    l_sun_y    = 0.62;
  Real    l_sun_z    = 0.66;
  Integer l_band     = 0;

  if (g_view_eye_in_water) {
    render_set_colour(p_box, g_fog_r, g_fog_g, g_fog_b);
    render_fill_rect(p_box, 0.0, g_view_bottom, g_screen_w, g_screen_h);
    return;
  }

  for (l_band = 1; l_band <= 16; ++l_band) {
    l_y0     = g_view_bottom + (l_band - 1) * l_band_h;
    l_y1     = g_view_bottom + l_band * l_band_h + 1.0;
    l_height = (l_y0 + l_band_h / 2.0 - l_horizon) / (g_screen_h - g_view_bottom);
    if (l_height >= 0.0) {
      l_amount = clamp_real(l_height * 1.7, 0.0, 1.0);
      render_set_colour(p_box, lerp_real(g_fog_r, g_sky_top_r, l_amount), lerp_real(g_fog_g, g_sky_top_g, l_amount), lerp_real(g_fog_b, g_sky_top_b, l_amount));
    } else {
      l_amount = clamp_real(-l_height * 2.0, 0.0, 1.0);
      render_set_colour(p_box, lerp_real(g_fog_r, g_fog_r * 0.75, l_amount), lerp_real(g_fog_g, g_fog_g * 0.78, l_amount), lerp_real(g_fog_b, g_fog_b * 0.8, l_amount));
    }
    render_fill_rect(p_box, 0.0, l_y0, g_screen_w, l_y1);
  }

  // Stars at night, then the sun and moon, which cross the sky from
  // east (+x) to west through the day
  if (g_view_daylight < 0.6) render_stars(p_box, clamp_real((0.6 - g_view_daylight) / 0.4, 0.0, 1.0));
  l_sun_x = Cos(g_view_time * TWO_PI);
  l_sun_y = Sin(g_view_time * TWO_PI);
  l_sun_z = 0.3;
  render_sky_disc(p_box,  l_sun_x,  l_sun_y,  l_sun_z, 0.07, FALSE);
  render_sky_disc(p_box, -l_sun_x, -l_sun_y, -l_sun_z, 0.05, TRUE);
}

void render_target_outline(Draw_Box p_box)
// ----------------------------------------------------------------
// Thin dark frame around the edges of the targeted block's faces
// that face the eye
// ----------------------------------------------------------------
{
  Real    l_rel_x = 0.0;
  Real    l_rel_y = 0.0;
  Real    l_rel_z = 0.0;
  Real    l_grow  = 0.004;
  Integer l_face  = 0;

  if (g_view_target_kind != TARGET_BLOCK) return;

  l_rel_x = g_view_target_x - l_grow - g_cam_x;
  l_rel_y = g_view_target_y - l_grow - g_cam_y;
  l_rel_z = g_view_target_z - l_grow - g_cam_z;
  g_q_front = FALSE;
  render_set_colour(p_box, 16.0, 16.0, 16.0);

  for (l_face = DIR_PX; l_face <= DIR_NZ; ++l_face) {
    if (l_face == DIR_PX && l_rel_x + 1.0 + 2.0 * l_grow >= 0.0) continue;
    if (l_face == DIR_NX && l_rel_x <= 0.0) continue;
    if (l_face == DIR_PY && l_rel_y + 1.0 + 2.0 * l_grow >= 0.0) continue;
    if (l_face == DIR_NY && l_rel_y <= 0.0) continue;
    if (l_face == DIR_PZ && l_rel_z + 1.0 + 2.0 * l_grow >= 0.0) continue;
    if (l_face == DIR_NZ && l_rel_z <= 0.0) continue;

    // The face as c0, e1, e2 in camera space, then its four edges
    if (l_face == DIR_PX) {
      render_to_camera(l_rel_x + 1.0 + 2.0 * l_grow, l_rel_y, l_rel_z);
    } else if (l_face == DIR_PY) {
      render_to_camera(l_rel_x, l_rel_y + 1.0 + 2.0 * l_grow, l_rel_z);
    } else if (l_face == DIR_PZ) {
      render_to_camera(l_rel_x, l_rel_y, l_rel_z + 1.0 + 2.0 * l_grow);
    } else {
      render_to_camera(l_rel_x, l_rel_y, l_rel_z);
    }
    g_q_c0x = g_tc_x;
    g_q_c0y = g_tc_y;
    g_q_c0z = g_tc_z;

    if (l_face == DIR_PX || l_face == DIR_NX) {
      render_to_camera(0.0, 0.0, 1.0 + 2.0 * l_grow);
    } else {
      render_to_camera(1.0 + 2.0 * l_grow, 0.0, 0.0);
    }
    g_q_e1x = g_tc_x;
    g_q_e1y = g_tc_y;
    g_q_e1z = g_tc_z;

    if (l_face == DIR_PY || l_face == DIR_NY) {
      render_to_camera(0.0, 0.0, 1.0 + 2.0 * l_grow);
    } else {
      render_to_camera(0.0, 1.0 + 2.0 * l_grow, 0.0);
    }
    g_q_e2x = g_tc_x;
    g_q_e2y = g_tc_y;
    g_q_e2z = g_tc_z;

    render_face_line(p_box, 0.0, 0.0, 1.0, 0.0);
    render_face_line(p_box, 1.0, 0.0, 1.0, 1.0);
    render_face_line(p_box, 1.0, 1.0, 0.0, 1.0);
    render_face_line(p_box, 0.0, 1.0, 0.0, 0.0);
  }
}

void render_world(Draw_Box p_box, Real p_w, Real p_h, Real p_view_bottom, Attributes &p_player, Attributes &p_cows,
                  Attributes &p_drops, Attributes &p_furnaces, Attributes &p_settings, Real p_time_of_day, Real p_now)
// ----------------------------------------------------------------
// Draw the 3D view from the player's eyes: sky, then every face far
// to near, then the outline of the targeted block. Must be inside a
// batch draw.
// ----------------------------------------------------------------
{
  Integer l_bucket = 0;
  Real    l_x      = 0.0;
  Real    l_y      = 0.0;
  Real    l_z      = 0.0;
  Real    l_yaw    = 0.0;
  Real    l_pitch  = 0.0;

  render_view_from(p_player, p_settings, p_time_of_day, p_now);
  player_position (p_player, l_x, l_y, l_z);
  player_look     (p_player, l_yaw, l_pitch);
  render_setup_camera(p_w, p_h, p_view_bottom, l_x, player_eye_y(p_player), l_z, l_yaw, l_pitch, settings_fov_radians(p_settings));

  g_face_total     = 0;
  g_stat_faces     = 0;
  g_stat_polygons  = 0;
  g_stat_sections  = 0;
  for (l_bucket = 1; l_bucket <= MAX_BUCKETS; ++l_bucket) g_bucket_head[l_bucket] = 0;

  render_sky(p_box);
  render_collect_blocks(p_furnaces);
  render_collect_cows  (p_cows);
  render_collect_drops (p_drops);
  g_box_light = 1.0;
  g_stat_faces = g_face_total;

  render_draw_faces(p_box);
  render_target_outline(p_box);
}

#endif
