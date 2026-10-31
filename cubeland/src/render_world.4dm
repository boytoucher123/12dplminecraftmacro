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
#include "../include/drops.h"
#include "../include/furnace.h"
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

void render_set_detail(Integer level)
// ----------------------------------------------------------------
// 1 = low (short view, textures only up close), 2 = normal,
// 3 = high (long view, textures further out)
// ----------------------------------------------------------------
{
  g_detail_level = clamp_integer(level, 1, 3);

  if (g_detail_level == 1) {
    g_render_distance  = 12;
    g_lod_full_pixels  = 160.0;
    g_lod_major_pixels = 70.0;
  } else if (g_detail_level == 2) {
    g_render_distance  = 18;
    g_lod_full_pixels  = 110.0;
    g_lod_major_pixels = 44.0;
  } else {
    g_render_distance  = 26;
    g_lod_full_pixels  = 70.0;
    g_lod_major_pixels = 30.0;
  }
}

// ---------------------------------------------------------------- 2D helpers

void render_set_colour(Draw_Box box, Real red, Real green, Real blue)
// ----------------------------------------------------------------
// Set both the pen and the fill to one colour, so polygons have no
// differently coloured outline (and neighbours leave no gaps)
// ----------------------------------------------------------------
{
  Integer r = to_byte(red);
  Integer g = to_byte(green);
  Integer b = to_byte(blue);

  Set_colour     (box, r, g, b);
  Set_fill_colour(box, r, g, b);
}

void render_set_face_colour(Draw_Box box, Real red, Real green, Real blue)
// ----------------------------------------------------------------
// render_set_colour without the range checks, for face colours,
// which are always in range: palette * keep + add never passes 255
// because keep + fog <= 1 (see render_draw_face)
// ----------------------------------------------------------------
{
  Integer r = Floor(red);
  Integer g = Floor(green);
  Integer b = Floor(blue);

  Set_colour     (box, r, g, b);
  Set_fill_colour(box, r, g, b);
}

void render_fill_rect(Draw_Box box, Real x0, Real y0, Real x1, Real y1)
// ----------------------------------------------------------------
// Filled axis aligned rectangle in screen coordinates
// ----------------------------------------------------------------
{
  g_poly_x[1] = x0;
  g_poly_y[1] = y0;
  g_poly_x[2] = x1;
  g_poly_y[2] = y0;
  g_poly_x[3] = x1;
  g_poly_y[3] = y1;
  g_poly_x[4] = x0;
  g_poly_y[4] = y1;
  Draw_polygon(box, 4, g_poly_x, g_poly_y);
}

void render_line(Draw_Box box, Real x0, Real y0, Real x1, Real y1)
// ----------------------------------------------------------------
// Line in screen coordinates
// ----------------------------------------------------------------
{
  Move_to(box, x0, y0);
  Draw_to(box, x1, y1);
}

// ---------------------------------------------------------------- camera

void render_setup_camera(Real w, Real h, Real view_bottom)
// ----------------------------------------------------------------
// Camera at the player's eyes for a w x h view whose bottom
// view_bottom pixels are covered by the status strip
// ----------------------------------------------------------------
{
  Real cos_yaw   = Cos(g_player_yaw);
  Real sin_yaw   = Sin(g_player_yaw);
  Real cos_pitch = Cos(g_player_pitch);
  Real sin_pitch = Sin(g_player_pitch);
  Real tan_x     = 0.0;
  Real tan_y     = 0.0;

  g_screen_w    = w;
  g_screen_h    = h;
  g_view_bottom = view_bottom;
  g_centre_x    = w / 2.0;
  g_centre_y    = view_bottom + (h - view_bottom) / 2.0;
  g_focal       = (w / 2.0) * Cos(FIELD_OF_VIEW / 2.0) / Sin(FIELD_OF_VIEW / 2.0);

  g_cam_x = g_player_x;
  g_cam_y = player_eye_y();
  g_cam_z = g_player_z;

  g_fwd_x   =  cos_pitch * cos_yaw;
  g_fwd_y   =  sin_pitch;
  g_fwd_z   =  cos_pitch * sin_yaw;
  g_right_x = -sin_yaw;
  g_right_z =  cos_yaw;
  g_up_x    = -sin_pitch * cos_yaw;
  g_up_y    =  cos_pitch;
  g_up_z    = -sin_pitch * sin_yaw;

  // Frustum side planes (with a little margin) for culling
  tan_x = (w / 2.0 + 8.0) / g_focal;
  tan_y = ((h - view_bottom) / 2.0 + 8.0) / g_focal;
  g_cull_cos_x = 1.0 / Sqrt(1.0 + tan_x * tan_x);
  g_cull_sin_x = tan_x * g_cull_cos_x;
  g_cull_cos_y = 1.0 / Sqrt(1.0 + tan_y * tan_y);
  g_cull_sin_y = tan_y * g_cull_cos_y;

  // Fog
  g_fog_end   = g_render_distance;
  g_fog_start = g_render_distance * 0.55;
  g_fog_r     = 170.0;
  g_fog_g     = 205.0;
  g_fog_b     = 245.0;
  if (g_player_eye_in_water) {
    g_fog_start = 2.0;
    g_fog_end   = min_real(16.0, g_fog_end);
    g_fog_r     = 30.0;
    g_fog_g     = 62.0;
    g_fog_b     = 140.0;
  }
}

void render_to_camera(Real rel_x, Real rel_y, Real rel_z)
// ----------------------------------------------------------------
// Rotate a vector from the eye into camera space (x right, y up,
// z forward); the result is left in g_tc_x, g_tc_y, g_tc_z
// ----------------------------------------------------------------
{
  g_tc_x = rel_x * g_right_x + rel_z * g_right_z;
  g_tc_y = rel_x * g_up_x    + rel_y * g_up_y    + rel_z * g_up_z;
  g_tc_z = rel_x * g_fwd_x   + rel_y * g_fwd_y   + rel_z * g_fwd_z;
}

Integer render_sphere_visible(Real rel_x, Real rel_y, Real rel_z, Real radius)
// ----------------------------------------------------------------
// FALSE if a sphere (centre relative to the eye) is certainly
// outside the view: behind the camera or past a side of the screen
// ----------------------------------------------------------------
{
  render_to_camera(rel_x, rel_y, rel_z);

  if (g_tc_z < -radius) return FALSE;
  if ( g_tc_x * g_cull_cos_x - g_tc_z * g_cull_sin_x > radius) return FALSE;
  if (-g_tc_x * g_cull_cos_x - g_tc_z * g_cull_sin_x > radius) return FALSE;
  if ( g_tc_y * g_cull_cos_y - g_tc_z * g_cull_sin_y > radius) return FALSE;
  if (-g_tc_y * g_cull_cos_y - g_tc_z * g_cull_sin_y > radius) return FALSE;
  return TRUE;
}

// ---------------------------------------------------------------- collecting faces

void render_add_face(Real c0x, Real c0y, Real c0z, Real e1x, Real e1y, Real e1z, Real e2x, Real e2y, Real e2z,
                     Integer tex, Real shade, Real distance_squared, Real size, Real tint, Integer crack)
// ----------------------------------------------------------------
// Queue a face for drawing. Corners are c0, c0 + e1, c0 + e1 + e2
// and c0 + e2 in camera space; e1 runs along the texture's u and e2
// along v (up the texture). distance_squared orders the painting,
// size (the face's width in blocks) picks the level of detail.
// ----------------------------------------------------------------
{
  Real    z1       = c0z + e1z;
  Real    z2       = c0z + e1z + e2z;
  Real    z3       = c0z + e2z;
  Real    distance = 0.0;
  Real    fog      = 0.0;
  Real    pixels   = 0.0;
  Integer bucket   = 0;
  Integer face     = 0;

  if (g_face_total >= MAX_DRAW_FACES) return;
  if (c0z < NEAR_PLANE && z1 < NEAR_PLANE && z2 < NEAR_PLANE && z3 < NEAR_PLANE) return;

  distance = Sqrt(distance_squared);
  fog      = clamp_real((distance - g_fog_start) / (g_fog_end - g_fog_start), 0.0, 1.0);
  if (fog >= 0.999) return;

  ++g_face_total;
  face = g_face_total;

  g_df_c0x[face] = c0x;
  g_df_c0y[face] = c0y;
  g_df_c0z[face] = c0z;
  g_df_e1x[face] = e1x;
  g_df_e1y[face] = e1y;
  g_df_e1z[face] = e1z;
  g_df_e2x[face] = e2x;
  g_df_e2y[face] = e2y;
  g_df_e2z[face] = e2z;
  g_df_tex   [face] = tex;
  g_df_shade [face] = shade;
  g_df_fog   [face] = fog;
  g_df_tint  [face] = tint;
  g_df_crack [face] = crack;
  pixels = g_focal * size / max_real(distance, 0.1);
  g_df_detail[face] = DETAIL_FLAT;
  if (pixels > g_lod_major_pixels) g_df_detail[face] = DETAIL_MAJOR;
  if (pixels > g_lod_full_pixels ) g_df_detail[face] = DETAIL_FULL;
  g_df_front [face] = c0z >= NEAR_PLANE && z1 >= NEAR_PLANE && z2 >= NEAR_PLANE && z3 >= NEAR_PLANE;

  bucket = Floor(distance_squared * BUCKETS_PER_UNIT) + 1;
  if (bucket > MAX_BUCKETS) bucket = MAX_BUCKETS;
  if (bucket < 1) bucket = 1;
  g_df_next[face]       = g_bucket_head[bucket];
  g_bucket_head[bucket] = face;
}

void render_add_block_face(Integer x, Integer y, Integer z, Integer direction, Integer block, Real distance_squared, Integer crack)
// ----------------------------------------------------------------
// Queue one face of the block at cell (x, y, z)
// The face corners are built from the camera space images of the
// three world axes, so each corner is just a few additions
// ----------------------------------------------------------------
{
  Real    rel_x = x - g_cam_x;
  Real    rel_y = y - g_cam_y;
  Real    rel_z = z - g_cam_z;
  // camera space images of the unit x, y and z axes
  Real    ax_x  = g_right_x;
  Real    ax_y  = g_up_x;
  Real    ax_z  = g_fwd_x;
  Real    ay_y  = g_up_y;
  Real    ay_z  = g_fwd_y;
  Real    az_x  = g_right_z;
  Real    az_y  = g_up_z;
  Real    az_z  = g_fwd_z;
  Real    ox    = rel_x * ax_x + rel_z * az_x;
  Real    oy    = rel_x * ax_y + rel_y * ay_y + rel_z * az_y;
  Real    oz    = rel_x * ax_z + rel_y * ay_z + rel_z * az_z;
  Real    top   = 1.0;
  Integer tex   = block_face_texture(block, direction);
  Real    shade = block_face_shade(direction);

  if (block == BLOCK_WATER) top = WATER_TOP;
  if (tex == TEX_FURNACE_FRONT) {
    if (furnace_is_lit(x, y, z)) tex = TEX_FURNACE_FRONT_LIT;
  }

  if (direction == DIR_PX) {
    render_add_face(ox + ax_x + az_x, oy + ax_y + az_y, oz + ax_z + az_z,
                    -az_x, -az_y, -az_z,  0.0, ay_y * top, ay_z * top,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  } else if (direction == DIR_NX) {
    render_add_face(ox, oy, oz,
                    az_x, az_y, az_z,  0.0, ay_y * top, ay_z * top,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  } else if (direction == DIR_PY) {
    render_add_face(ox, oy + ay_y * top, oz + ay_z * top,
                    ax_x, ax_y, ax_z,  az_x, az_y, az_z,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  } else if (direction == DIR_NY) {
    render_add_face(ox + az_x, oy + az_y, oz + az_z,
                    ax_x, ax_y, ax_z,  -az_x, -az_y, -az_z,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  } else if (direction == DIR_PZ) {
    render_add_face(ox + az_x, oy + az_y, oz + az_z,
                    ax_x, ax_y, ax_z,  0.0, ay_y * top, ay_z * top,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  } else {
    render_add_face(ox + ax_x, oy + ax_y, oz + ax_z,
                    -ax_x, -ax_y, -ax_z,  0.0, ay_y * top, ay_z * top,
                    tex, shade, distance_squared, 1.0, 0.0, crack);
  }
}

void render_collect_blocks()
// ----------------------------------------------------------------
// Walk the cached face lists of the sections in view and queue the
// faces that point towards the eye, are within the view distance
// and inside the screen
// ----------------------------------------------------------------
{
  Integer range     = g_render_distance;
  Real    range_sq  = range * range;
  Integer sx0       = clamp_integer(floor_integer((g_cam_x - range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer sx1       = clamp_integer(floor_integer((g_cam_x + range) / SECTION_SIZE), 0, SECTIONS_X - 1);
  Integer sy0       = clamp_integer(floor_integer((g_cam_y - range) / SECTION_SIZE), 0, SECTIONS_Y - 1);
  Integer sy1       = clamp_integer(floor_integer((g_cam_y + range) / SECTION_SIZE), 0, SECTIONS_Y - 1);
  Integer sz0       = clamp_integer(floor_integer((g_cam_z - range) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  Integer sz1       = clamp_integer(floor_integer((g_cam_z + range) / SECTION_SIZE), 0, SECTIONS_Z - 1);
  Integer sx        = 0;
  Integer sy        = 0;
  Integer sz        = 0;
  Integer section   = 0;
  Integer start     = 0;
  Integer last      = 0;
  Integer entry     = 0;
  Integer x         = 0;
  Integer y         = 0;
  Integer z         = 0;
  Integer direction = 0;
  Integer group     = 0;
  Integer block     = 0;
  Integer crack     = 0;
  Integer stage     = player_break_stage();
  Real    centre_x  = 0.0;
  Real    centre_y  = 0.0;
  Real    centre_z  = 0.0;
  Real    reach     = 0.0;
  Real    rel_x     = 0.0;
  Real    rel_y     = 0.0;
  Real    rel_z     = 0.0;
  Real    dist_sq   = 0.0;
  Real    normal_x  = 0.0;
  Real    normal_y  = 0.0;
  Real    normal_z  = 0.0;

  reach = range + SECTION_RADIUS;

  for (sx = sx0; sx <= sx1; ++sx) {
    for (sz = sz0; sz <= sz1; ++sz) {
      for (sy = sy0; sy <= sy1; ++sy) {
        centre_x = sx * SECTION_SIZE + 8.0 - g_cam_x;
        centre_y = sy * SECTION_SIZE + 8.0 - g_cam_y;
        centre_z = sz * SECTION_SIZE + 8.0 - g_cam_z;
        if (centre_x * centre_x + centre_y * centre_y + centre_z * centre_z > reach * reach) continue;
        if (!render_sphere_visible(centre_x, centre_y, centre_z, SECTION_RADIUS)) continue;

        section = mesh_ensure_section(sx, sy, sz);
        if (g_section_count[section] == 0) continue;
        ++g_stat_sections;

        for (group = 1; group <= 6; ++group) {
          // Skip a direction whose faces all point away from the eye
          if (group == DIR_PX && g_cam_x <= sx * SECTION_SIZE + 1.0 ) continue;
          if (group == DIR_NX && g_cam_x >= sx * SECTION_SIZE + 15.0) continue;
          if (group == DIR_PY && g_cam_y <= sy * SECTION_SIZE + 1.0 && !g_player_eye_in_water) continue;
          if (group == DIR_NY && g_cam_y >= sy * SECTION_SIZE + 15.0) continue;
          if (group == DIR_PZ && g_cam_z <= sz * SECTION_SIZE + 1.0 ) continue;
          if (group == DIR_NZ && g_cam_z >= sz * SECTION_SIZE + 15.0) continue;

          start = (section - 1) * SECTION_FACE_CAP + g_section_dir_start[(section - 1) * 6 + group];
          last  = start + g_section_dir_count[(section - 1) * 6 + group] - 1;
          for (entry = start; entry <= last; ++entry) {
            direction = g_face_dir[entry];
            if (direction > DIR_WET_FLAG) {
              if (!g_player_eye_in_water) continue;
              direction = direction - DIR_WET_FLAG;
            }
            x = g_face_x[entry];
            y = g_face_y[entry];
            z = g_face_z[entry];
            rel_x = x - g_cam_x;
            rel_y = y - g_cam_y;
            rel_z = z - g_cam_z;

            // Only faces that point towards the eye (water surfaces
            // can be seen from either side)
            normal_x = 0.0;
            normal_y = 0.0;
            normal_z = 0.0;
            if (direction == DIR_PX) {
              if (rel_x + 1.0 >= 0.0) continue;
              normal_x = 1.0;
            } else if (direction == DIR_NX) {
              if (rel_x <= 0.0) continue;
              normal_x = -1.0;
            } else if (direction == DIR_PY) {
              if (rel_y + 1.0 >= 0.0) {
                if (!g_player_eye_in_water) continue;
                if (g_world[world_index(x, y, z)] != BLOCK_WATER) continue;
              }
              normal_y = 1.0;
            } else if (direction == DIR_NY) {
              if (rel_y <= 0.0) continue;
              normal_y = -1.0;
            } else if (direction == DIR_PZ) {
              if (rel_z + 1.0 >= 0.0) continue;
              normal_z = 1.0;
            } else {
              if (rel_z <= 0.0) continue;
              normal_z = -1.0;
            }

            dist_sq = (rel_x + 0.5) * (rel_x + 0.5) + (rel_y + 0.5) * (rel_y + 0.5) + (rel_z + 0.5) * (rel_z + 0.5);
            if (dist_sq > range_sq) continue;
            if (!render_sphere_visible(rel_x + 0.5 + normal_x * 0.5, rel_y + 0.5 + normal_y * 0.5, rel_z + 0.5 + normal_z * 0.5, 0.72)) continue;

            block = g_world[world_index(x, y, z)];
            crack = 0;
            if (stage > 0) {
              if (x == g_break_x && y == g_break_y && z == g_break_z) crack = stage;
            }
            render_add_block_face(x, y, z, direction, block, dist_sq, crack);
          }
        }
      }
    }
  }
}

Real render_side_shade(Real normal_x, Real normal_z)
// ----------------------------------------------------------------
// Light level of an upright face of an entity box from its normal,
// matching block_face_shade for faces that line up with the grid
// ----------------------------------------------------------------
{
  return 0.70 * normal_x * normal_x + 0.84 * normal_z * normal_z;
}

void render_add_box(Real centre_x, Real centre_y, Real centre_z, Real yaw, Real half_f, Real half_y, Real half_s,
                    Integer tex_side, Integer tex_top, Integer tex_front, Real tint)
// ----------------------------------------------------------------
// Queue the visible faces of an upright box turned to yaw
// half_f is its half length along the facing direction, half_s its
// half width and half_y its half height. tex_front is drawn on the
// face it looks out of, tex_top on the top and bottom.
// ----------------------------------------------------------------
{
  Real    facing_x = Cos(yaw);
  Real    facing_z = Sin(yaw);
  Real    side_x   = -facing_z;
  Real    side_z   =  facing_x;
  Real    rel_x    = centre_x - g_cam_x;
  Real    rel_y    = centre_y - g_cam_y;
  Real    rel_z    = centre_z - g_cam_z;
  Real    dist_sq  = rel_x * rel_x + rel_y * rel_y + rel_z * rel_z;
  Real    size     = 2.0 * max_real(half_f, max_real(half_y, half_s));
  Real    eye_f    = -(rel_x * facing_x + rel_z * facing_z);
  Real    eye_s    = -(rel_x * side_x   + rel_z * side_z);
  Real    eye_y    = -rel_y;
  Real    m_x      = 0.0;
  Real    m_y      = 0.0;
  Real    m_z      = 0.0;
  Real    f_x      = 0.0;
  Real    f_y      = 0.0;
  Real    f_z      = 0.0;
  Real    u_x      = 0.0;
  Real    u_y      = 0.0;
  Real    u_z      = 0.0;
  Real    s_x      = 0.0;
  Real    s_y      = 0.0;
  Real    s_z      = 0.0;

  if (dist_sq > g_render_distance * g_render_distance) return;
  if (!render_sphere_visible(rel_x, rel_y, rel_z, Sqrt(half_f * half_f + half_y * half_y + half_s * half_s))) return;

  // Corner with the lowest f, y and s, and the three edge vectors,
  // all in camera space
  render_to_camera(rel_x - facing_x * half_f - side_x * half_s, rel_y - half_y, rel_z - facing_z * half_f - side_z * half_s);
  m_x = g_tc_x;
  m_y = g_tc_y;
  m_z = g_tc_z;
  render_to_camera(facing_x * half_f * 2.0, 0.0, facing_z * half_f * 2.0);
  f_x = g_tc_x;
  f_y = g_tc_y;
  f_z = g_tc_z;
  render_to_camera(0.0, half_y * 2.0, 0.0);
  u_x = g_tc_x;
  u_y = g_tc_y;
  u_z = g_tc_z;
  render_to_camera(side_x * half_s * 2.0, 0.0, side_z * half_s * 2.0);
  s_x = g_tc_x;
  s_y = g_tc_y;
  s_z = g_tc_z;

  if (eye_f > half_f) {
    render_add_face(m_x + f_x + s_x, m_y + f_y + s_y, m_z + f_z + s_z, -s_x, -s_y, -s_z, u_x, u_y, u_z,
                    tex_front, render_side_shade(facing_x, facing_z), dist_sq, size, tint, 0);
  }
  if (eye_f < -half_f) {
    render_add_face(m_x, m_y, m_z, s_x, s_y, s_z, u_x, u_y, u_z,
                    tex_side, render_side_shade(facing_x, facing_z), dist_sq, size, tint, 0);
  }
  if (eye_s > half_s) {
    render_add_face(m_x + s_x, m_y + s_y, m_z + s_z, f_x, f_y, f_z, u_x, u_y, u_z,
                    tex_side, render_side_shade(side_x, side_z), dist_sq, size, tint, 0);
  }
  if (eye_s < -half_s) {
    render_add_face(m_x + f_x, m_y + f_y, m_z + f_z, -f_x, -f_y, -f_z, u_x, u_y, u_z,
                    tex_side, render_side_shade(side_x, side_z), dist_sq, size, tint, 0);
  }
  if (eye_y > half_y) {
    render_add_face(m_x + u_x, m_y + u_y, m_z + u_z, f_x, f_y, f_z, s_x, s_y, s_z,
                    tex_top, 1.0, dist_sq, size, tint, 0);
  }
  if (eye_y < -half_y) {
    render_add_face(m_x + s_x, m_y + s_y, m_z + s_z, f_x, f_y, f_z, -s_x, -s_y, -s_z,
                    tex_top, 0.55, dist_sq, size, tint, 0);
  }
}

void render_cow_part(Integer cow, Real along, Real up, Real across, Real half_f, Real half_y, Real half_s,
                     Integer tex_front, Real tint)
// ----------------------------------------------------------------
// One box of a cow, placed relative to the cow's feet and facing
// ----------------------------------------------------------------
{
  Real yaw      = g_cow_yaw[cow];
  Real facing_x = Cos(yaw);
  Real facing_z = Sin(yaw);

  render_add_box(g_cow_x[cow] + facing_x * along - facing_z * across,
                 g_cow_y[cow] + up,
                 g_cow_z[cow] + facing_z * along + facing_x * across,
                 yaw, half_f, half_y, half_s, TEX_COW_HIDE, TEX_COW_HIDE, tex_front, tint);
}

void render_collect_cows()
// ----------------------------------------------------------------
// Queue every cow in view: body, head and four swinging legs
// ----------------------------------------------------------------
{
  Integer cow   = 0;
  Real    tint  = 0.0;
  Real    swing = 0.0;
  Real    dx    = 0.0;
  Real    dz    = 0.0;

  for (cow = 1; cow <= MAX_COWS; ++cow) {
    if (!g_cow_alive[cow]) continue;
    dx = g_cow_x[cow] - g_cam_x;
    dz = g_cow_z[cow] - g_cam_z;
    if (dx * dx + dz * dz > (g_render_distance + 2.0) * (g_render_distance + 2.0)) continue;

    tint = 0.0;
    if (g_cow_flash[cow] > 0.0) tint = 0.55;
    swing = Sin(g_cow_step[cow]) * 0.09;

    render_cow_part(cow,  0.00        , 0.95, 0.00, 0.60, 0.30, 0.38, TEX_COW_HIDE, tint);
    render_cow_part(cow,  0.80        , 1.12, 0.00, 0.20, 0.22, 0.25, TEX_COW_FACE, tint);
    render_cow_part(cow,  0.42 + swing, 0.33, 0.22, 0.10, 0.33, 0.10, TEX_COW_HIDE, tint);
    render_cow_part(cow,  0.42 - swing, 0.33,-0.22, 0.10, 0.33, 0.10, TEX_COW_HIDE, tint);
    render_cow_part(cow, -0.42 - swing, 0.33, 0.22, 0.10, 0.33, 0.10, TEX_COW_HIDE, tint);
    render_cow_part(cow, -0.42 + swing, 0.33,-0.22, 0.10, 0.33, 0.10, TEX_COW_HIDE, tint);
  }
}

void render_collect_drops()
// ----------------------------------------------------------------
// Queue dropped items as small spinning, bobbing cubes
// ----------------------------------------------------------------
{
  Integer drop = 0;
  Real    bob  = 0.0;

  for (drop = 1; drop <= MAX_DROPS; ++drop) {
    if (!g_drop_used[drop]) continue;
    bob = 0.06 + Sin(g_drop_age[drop] * 3.0) * 0.05;
    render_add_box(g_drop_x[drop], g_drop_y[drop] + DROP_HALF_SIZE + bob, g_drop_z[drop],
                   g_drop_age[drop] * 1.8, DROP_HALF_SIZE, DROP_HALF_SIZE, DROP_HALF_SIZE,
                   item_side_texture(g_drop_item[drop]), item_top_texture(g_drop_item[drop]),
                   item_side_texture(g_drop_item[drop]), 0.0);
  }
}

// ---------------------------------------------------------------- drawing faces

void render_clip_screen_edge(Integer axis, Real limit, Integer keep_above)
// ----------------------------------------------------------------
// Clip the screen polygon in g_poly_x/y (g_clip_count points)
// against one edge: axis 1 = x, 2 = y; keeps the side above limit
// if keep_above, else the side below
// ----------------------------------------------------------------
{
  Integer count  = 0;
  Integer point  = 0;
  Integer next   = 0;
  Real    value  = 0.0;
  Real    other  = 0.0;
  Integer inside = 0;
  Integer next_inside = 0;
  Real    t      = 0.0;

  for (point = 1; point <= g_clip_count; ++point) {
    next = point + 1;
    if (next > g_clip_count) next = 1;

    value = g_poly_x[point];
    other = g_poly_x[next];
    if (axis == 2) {
      value = g_poly_y[point];
      other = g_poly_y[next];
    }
    inside      = value >= limit;
    next_inside = other >= limit;
    if (!keep_above) {
      inside      = value <= limit;
      next_inside = other <= limit;
    }

    if (inside) {
      ++count;
      g_temp_x[count] = g_poly_x[point];
      g_temp_y[count] = g_poly_y[point];
    }
    if (inside != next_inside) {
      t = (limit - value) / (other - value);
      ++count;
      g_temp_x[count] = g_poly_x[point] + (g_poly_x[next] - g_poly_x[point]) * t;
      g_temp_y[count] = g_poly_y[point] + (g_poly_y[next] - g_poly_y[point]) * t;
    }
  }

  for (point = 1; point <= count; ++point) {
    g_poly_x[point] = g_temp_x[point];
    g_poly_y[point] = g_temp_y[point];
  }
  g_clip_count = count;
}

Integer render_clip_and_draw(Draw_Box box)
// ----------------------------------------------------------------
// Draw the camera space polygon in g_clip_x/y/z (g_clip_count
// points): clip it to the near plane (unless the face is known to
// be in front), project it, clip it to the screen if it reaches far
// outside, and fill it. Returns TRUE if anything was drawn.
// ----------------------------------------------------------------
{
  Integer count       = 0;
  Integer point       = 0;
  Integer next        = 0;
  Integer inside      = 0;
  Integer next_inside = 0;
  Integer far_out     = FALSE;
  Real    t           = 0.0;
  Real    scale       = 0.0;

  if (!g_q_front) {
    for (point = 1; point <= g_clip_count; ++point) {
      next = point + 1;
      if (next > g_clip_count) next = 1;
      inside      = g_clip_z[point] >= NEAR_PLANE;
      next_inside = g_clip_z[next ] >= NEAR_PLANE;
      if (inside) {
        ++count;
        g_temp_x[count] = g_clip_x[point];
        g_temp_y[count] = g_clip_y[point];
        g_temp_z[count] = g_clip_z[point];
      }
      if (inside != next_inside) {
        t = (NEAR_PLANE - g_clip_z[point]) / (g_clip_z[next] - g_clip_z[point]);
        ++count;
        g_temp_x[count] = g_clip_x[point] + (g_clip_x[next] - g_clip_x[point]) * t;
        g_temp_y[count] = g_clip_y[point] + (g_clip_y[next] - g_clip_y[point]) * t;
        g_temp_z[count] = NEAR_PLANE;
      }
    }
    if (count < 3) return FALSE;
    for (point = 1; point <= count; ++point) {
      g_clip_x[point] = g_temp_x[point];
      g_clip_y[point] = g_temp_y[point];
      g_clip_z[point] = g_temp_z[point];
    }
    g_clip_count = count;
  }

  for (point = 1; point <= g_clip_count; ++point) {
    scale = g_focal / g_clip_z[point];
    g_poly_x[point] = g_centre_x + g_clip_x[point] * scale;
    g_poly_y[point] = g_centre_y + g_clip_y[point] * scale;
    if (g_poly_x[point] < -GUARD_BAND || g_poly_x[point] > g_screen_w + GUARD_BAND) far_out = TRUE;
    if (g_poly_y[point] < -GUARD_BAND || g_poly_y[point] > g_screen_h + GUARD_BAND) far_out = TRUE;
  }

  if (far_out) {
    render_clip_screen_edge(1, -2.0, TRUE);
    if (g_clip_count >= 3) render_clip_screen_edge(1, g_screen_w + 2.0, FALSE);
    if (g_clip_count >= 3) render_clip_screen_edge(2, -2.0, TRUE);
    if (g_clip_count >= 3) render_clip_screen_edge(2, g_screen_h + 2.0, FALSE);
    if (g_clip_count < 3) return FALSE;
  }

  Draw_polygon(box, g_clip_count, g_poly_x, g_poly_y);
  ++g_stat_polygons;
  return TRUE;
}

void render_quad(Draw_Box box, Real u0, Real v0, Real u1, Real v1)
// ----------------------------------------------------------------
// Draw the part u0..u1, v0..v1 of the current face (g_q_*)
// Because a face is flat, a point on it is c0 + u e1 + v e2 in
// camera space, which keeps the perspective exact
// ----------------------------------------------------------------
{
  Real scale = 0.0;
  Real x     = 0.0;
  Real y     = 0.0;
  Real z     = 0.0;

  // Whole face in front of the camera and well inside the guard
  // band: every part of it can be projected and drawn directly
  if (g_q_safe) {
    x = g_q_c0x + u0 * g_q_e1x + v0 * g_q_e2x;
    y = g_q_c0y + u0 * g_q_e1y + v0 * g_q_e2y;
    z = g_q_c0z + u0 * g_q_e1z + v0 * g_q_e2z;
    scale = g_focal / z;
    g_poly_x[1] = g_centre_x + x * scale;
    g_poly_y[1] = g_centre_y + y * scale;
    x = g_q_c0x + u1 * g_q_e1x + v0 * g_q_e2x;
    y = g_q_c0y + u1 * g_q_e1y + v0 * g_q_e2y;
    z = g_q_c0z + u1 * g_q_e1z + v0 * g_q_e2z;
    scale = g_focal / z;
    g_poly_x[2] = g_centre_x + x * scale;
    g_poly_y[2] = g_centre_y + y * scale;
    x = g_q_c0x + u1 * g_q_e1x + v1 * g_q_e2x;
    y = g_q_c0y + u1 * g_q_e1y + v1 * g_q_e2y;
    z = g_q_c0z + u1 * g_q_e1z + v1 * g_q_e2z;
    scale = g_focal / z;
    g_poly_x[3] = g_centre_x + x * scale;
    g_poly_y[3] = g_centre_y + y * scale;
    x = g_q_c0x + u0 * g_q_e1x + v1 * g_q_e2x;
    y = g_q_c0y + u0 * g_q_e1y + v1 * g_q_e2y;
    z = g_q_c0z + u0 * g_q_e1z + v1 * g_q_e2z;
    scale = g_focal / z;
    g_poly_x[4] = g_centre_x + x * scale;
    g_poly_y[4] = g_centre_y + y * scale;
    Draw_polygon(box, 4, g_poly_x, g_poly_y);
    ++g_stat_polygons;
    return;
  }

  g_clip_x[1] = g_q_c0x + u0 * g_q_e1x + v0 * g_q_e2x;
  g_clip_y[1] = g_q_c0y + u0 * g_q_e1y + v0 * g_q_e2y;
  g_clip_z[1] = g_q_c0z + u0 * g_q_e1z + v0 * g_q_e2z;
  g_clip_x[2] = g_q_c0x + u1 * g_q_e1x + v0 * g_q_e2x;
  g_clip_y[2] = g_q_c0y + u1 * g_q_e1y + v0 * g_q_e2y;
  g_clip_z[2] = g_q_c0z + u1 * g_q_e1z + v0 * g_q_e2z;
  g_clip_x[3] = g_q_c0x + u1 * g_q_e1x + v1 * g_q_e2x;
  g_clip_y[3] = g_q_c0y + u1 * g_q_e1y + v1 * g_q_e2y;
  g_clip_z[3] = g_q_c0z + u1 * g_q_e1z + v1 * g_q_e2z;
  g_clip_x[4] = g_q_c0x + u0 * g_q_e1x + v1 * g_q_e2x;
  g_clip_y[4] = g_q_c0y + u0 * g_q_e1y + v1 * g_q_e2y;
  g_clip_z[4] = g_q_c0z + u0 * g_q_e1z + v1 * g_q_e2z;
  g_clip_count = 4;

  render_clip_and_draw(box);
}

void render_face_line(Draw_Box box, Real u0, Real v0, Real u1, Real v1)
// ----------------------------------------------------------------
// Draw a line across the current face between two (u, v) points
// Lines that cross the near plane are shortened to it
// ----------------------------------------------------------------
{
  Real x0 = g_q_c0x + u0 * g_q_e1x + v0 * g_q_e2x;
  Real y0 = g_q_c0y + u0 * g_q_e1y + v0 * g_q_e2y;
  Real z0 = g_q_c0z + u0 * g_q_e1z + v0 * g_q_e2z;
  Real x1 = g_q_c0x + u1 * g_q_e1x + v1 * g_q_e2x;
  Real y1 = g_q_c0y + u1 * g_q_e1y + v1 * g_q_e2y;
  Real z1 = g_q_c0z + u1 * g_q_e1z + v1 * g_q_e2z;
  Real t  = 0.0;

  if (z0 < NEAR_PLANE && z1 < NEAR_PLANE) return;
  if (z0 < NEAR_PLANE) {
    t  = (NEAR_PLANE - z0) / (z1 - z0);
    x0 = x0 + (x1 - x0) * t;
    y0 = y0 + (y1 - y0) * t;
    z0 = NEAR_PLANE;
  } else if (z1 < NEAR_PLANE) {
    t  = (NEAR_PLANE - z1) / (z0 - z1);
    x1 = x1 + (x0 - x1) * t;
    y1 = y1 + (y0 - y1) * t;
    z1 = NEAR_PLANE;
  }

  render_line(box, g_centre_x + x0 * g_focal / z0, g_centre_y + y0 * g_focal / z0,
                   g_centre_x + x1 * g_focal / z1, g_centre_y + y1 * g_focal / z1);
}

void render_palette_colour(Draw_Box box, Integer tex, Integer index)
// ----------------------------------------------------------------
// Set the colour of palette entry index of a texture, lit and
// fogged for the current face
// ----------------------------------------------------------------
{
  Integer slot = texture_palette_index(tex, index);

  render_set_face_colour(box, g_tex_pal_r[slot] * g_q_keep + g_q_add_r,
                         g_tex_pal_g[slot] * g_q_keep + g_q_add_g,
                         g_tex_pal_b[slot] * g_q_keep + g_q_add_b);
}

void render_draw_face(Draw_Box box, Integer face)
// ----------------------------------------------------------------
// Paint one queued face: the base colour over the whole face, then
// (when close enough) the rectangles of the texture's other colours
// ----------------------------------------------------------------
{
  Integer tex     = g_df_tex[face];
  Integer detail  = g_df_detail[face];
  Real    fog     = g_df_fog[face];
  Real    tint    = g_df_tint[face];
  Real    lit     = g_df_shade[face] * (1.0 - fog);
  Integer rect    = 0;
  Integer first   = 0;
  Integer last    = 0;
  Integer segment = 0;
  Integer colour  = 0;
  Integer corner  = 0;
  Real    x       = 0.0;
  Real    y       = 0.0;
  Real    z       = 0.0;
  Real    px      = 0.0;
  Real    py      = 0.0;

  g_q_c0x   = g_df_c0x[face];
  g_q_c0y   = g_df_c0y[face];
  g_q_c0z   = g_df_c0z[face];
  g_q_e1x   = g_df_e1x[face];
  g_q_e1y   = g_df_e1y[face];
  g_q_e1z   = g_df_e1z[face];
  g_q_e2x   = g_df_e2x[face];
  g_q_e2y   = g_df_e2y[face];
  g_q_e2z   = g_df_e2z[face];
  g_q_front = g_df_front[face];

  // Safe to project parts of the face directly if all four corners
  // are in front of the camera and inside the guard band
  g_q_safe = g_q_front;
  if (g_q_safe) {
    for (corner = 1; corner <= 4; ++corner) {
      x = g_q_c0x;
      y = g_q_c0y;
      z = g_q_c0z;
      if (corner == 2 || corner == 3) {
        x = x + g_q_e1x;
        y = y + g_q_e1y;
        z = z + g_q_e1z;
      }
      if (corner >= 3) {
        x = x + g_q_e2x;
        y = y + g_q_e2y;
        z = z + g_q_e2z;
      }
      px = g_centre_x + x * g_focal / z;
      py = g_centre_y + y * g_focal / z;
      if (px < -GUARD_BAND || px > g_screen_w + GUARD_BAND) g_q_safe = FALSE;
      if (py < -GUARD_BAND || py > g_screen_h + GUARD_BAND) g_q_safe = FALSE;
    }
  }

  // colour = palette * keep + add (shade, red hurt flash, then fog)
  g_q_keep  = lit * (1.0 - tint);
  g_q_add_r = fog * g_fog_r + lit * tint * 230.0;
  g_q_add_g = fog * g_fog_g + lit * tint * 40.0;
  g_q_add_b = fog * g_fog_b + lit * tint * 30.0;

  if (detail == DETAIL_FLAT) {
    render_set_face_colour(box, g_tex_avg_r[tex] * g_q_keep + g_q_add_r,
                           g_tex_avg_g[tex] * g_q_keep + g_q_add_g,
                           g_tex_avg_b[tex] * g_q_keep + g_q_add_b);
    render_quad(box, 0.0, 0.0, 1.0, 1.0);
  } else {
    render_palette_colour(box, tex, g_tex_base[tex]);
    render_quad(box, 0.0, 0.0, 1.0, 1.0);

    first = g_tex_rect_first[tex];
    last  = first + g_tex_rect_count[tex] - 1;
    // Rectangles are grouped by colour, so the colour is only set
    // when it changes
    colour = 0;
    for (rect = first; rect <= last; ++rect) {
      if (detail == DETAIL_MAJOR && g_rect_area[rect] < MAJOR_RECT_AREA) continue;
      if (g_rect_pal[rect] != colour) {
        colour = g_rect_pal[rect];
        render_palette_colour(box, tex, colour);
      }
      render_quad(box, g_rect_u0[rect], g_rect_v0[rect], g_rect_u1[rect], g_rect_v1[rect]);
    }
  }

  if (g_df_crack[face] > 0) {
    render_set_colour(box, 24.0 * g_q_keep + g_q_add_r, 22.0 * g_q_keep + g_q_add_g, 20.0 * g_q_keep + g_q_add_b);
    for (segment = 1; segment <= g_df_crack[face] * 2; ++segment) {
      render_face_line(box, g_crack_u0[segment], g_crack_v0[segment], g_crack_u1[segment], g_crack_v1[segment]);
    }
  }
}

void render_draw_faces(Draw_Box box)
// ----------------------------------------------------------------
// Paint every queued face, farthest bucket first
// ----------------------------------------------------------------
{
  Integer bucket = 0;
  Integer face   = 0;

  for (bucket = MAX_BUCKETS; bucket >= 1; --bucket) {
    face = g_bucket_head[bucket];
    while (face > 0) {
      render_draw_face(box, face);
      face = g_df_next[face];
    }
  }
}

// ---------------------------------------------------------------- sky and overlays

void render_sky(Draw_Box box)
// ----------------------------------------------------------------
// Sky gradient (pale at the horizon, deep blue overhead), a haze
// below the horizon and the sun. Under water: murky blue.
// ----------------------------------------------------------------
{
  Real    horizon  = g_centre_y - g_focal * Sin(g_player_pitch) / Cos(g_player_pitch);
  Real    band_h   = (g_screen_h - g_view_bottom) / 16.0;
  Real    y0       = 0.0;
  Real    y1       = 0.0;
  Real    height   = 0.0;
  Real    amount   = 0.0;
  Real    sun_x    = 0.42;
  Real    sun_y    = 0.62;
  Real    sun_z    = 0.66;
  Real    sun_size = 0.0;
  Real    px       = 0.0;
  Real    py       = 0.0;
  Integer band     = 0;

  if (g_player_eye_in_water) {
    render_set_colour(box, g_fog_r, g_fog_g, g_fog_b);
    render_fill_rect(box, 0.0, g_view_bottom, g_screen_w, g_screen_h);
    return;
  }

  for (band = 1; band <= 16; ++band) {
    y0     = g_view_bottom + (band - 1) * band_h;
    y1     = g_view_bottom + band * band_h + 1.0;
    height = (y0 + band_h / 2.0 - horizon) / (g_screen_h - g_view_bottom);
    if (height >= 0.0) {
      amount = clamp_real(height * 1.7, 0.0, 1.0);
      render_set_colour(box, lerp_real(g_fog_r, 92.0, amount), lerp_real(g_fog_g, 146.0, amount), lerp_real(g_fog_b, 232.0, amount));
    } else {
      amount = clamp_real(-height * 2.0, 0.0, 1.0);
      render_set_colour(box, lerp_real(g_fog_r, 120.0, amount), lerp_real(g_fog_g, 150.0, amount), lerp_real(g_fog_b, 190.0, amount));
    }
    render_fill_rect(box, 0.0, y0, g_screen_w, y1);
  }

  // The sun: a square in a fixed direction in the sky
  render_to_camera(sun_x, sun_y, sun_z);
  if (g_tc_z > 0.1) {
    px       = g_centre_x + g_tc_x * g_focal / g_tc_z;
    py       = g_centre_y + g_tc_y * g_focal / g_tc_z;
    sun_size = g_focal * 0.07;
    render_set_colour(box, 255.0, 246.0, 200.0);
    render_fill_rect(box, px - sun_size, py - sun_size, px + sun_size, py + sun_size);
    render_set_colour(box, 255.0, 255.0, 236.0);
    render_fill_rect(box, px - sun_size * 0.6, py - sun_size * 0.6, px + sun_size * 0.6, py + sun_size * 0.6);
  }
}

void render_target_outline(Draw_Box box)
// ----------------------------------------------------------------
// Thin dark frame around the edges of the targeted block's faces
// that face the eye
// ----------------------------------------------------------------
{
  Real    rel_x = 0.0;
  Real    rel_y = 0.0;
  Real    rel_z = 0.0;
  Real    grow  = 0.004;
  Integer face  = 0;

  if (g_target_kind != TARGET_BLOCK) return;

  rel_x = g_target_x - grow - g_cam_x;
  rel_y = g_target_y - grow - g_cam_y;
  rel_z = g_target_z - grow - g_cam_z;
  g_q_front = FALSE;
  render_set_colour(box, 16.0, 16.0, 16.0);

  for (face = DIR_PX; face <= DIR_NZ; ++face) {
    if (face == DIR_PX && rel_x + 1.0 + 2.0 * grow >= 0.0) continue;
    if (face == DIR_NX && rel_x <= 0.0) continue;
    if (face == DIR_PY && rel_y + 1.0 + 2.0 * grow >= 0.0) continue;
    if (face == DIR_NY && rel_y <= 0.0) continue;
    if (face == DIR_PZ && rel_z + 1.0 + 2.0 * grow >= 0.0) continue;
    if (face == DIR_NZ && rel_z <= 0.0) continue;

    // The face as c0, e1, e2 in camera space, then its four edges
    if (face == DIR_PX) {
      render_to_camera(rel_x + 1.0 + 2.0 * grow, rel_y, rel_z);
    } else if (face == DIR_PY) {
      render_to_camera(rel_x, rel_y + 1.0 + 2.0 * grow, rel_z);
    } else if (face == DIR_PZ) {
      render_to_camera(rel_x, rel_y, rel_z + 1.0 + 2.0 * grow);
    } else {
      render_to_camera(rel_x, rel_y, rel_z);
    }
    g_q_c0x = g_tc_x;
    g_q_c0y = g_tc_y;
    g_q_c0z = g_tc_z;

    if (face == DIR_PX || face == DIR_NX) {
      render_to_camera(0.0, 0.0, 1.0 + 2.0 * grow);
    } else {
      render_to_camera(1.0 + 2.0 * grow, 0.0, 0.0);
    }
    g_q_e1x = g_tc_x;
    g_q_e1y = g_tc_y;
    g_q_e1z = g_tc_z;

    if (face == DIR_PY || face == DIR_NY) {
      render_to_camera(0.0, 0.0, 1.0 + 2.0 * grow);
    } else {
      render_to_camera(0.0, 1.0 + 2.0 * grow, 0.0);
    }
    g_q_e2x = g_tc_x;
    g_q_e2y = g_tc_y;
    g_q_e2z = g_tc_z;

    render_face_line(box, 0.0, 0.0, 1.0, 0.0);
    render_face_line(box, 1.0, 0.0, 1.0, 1.0);
    render_face_line(box, 1.0, 1.0, 0.0, 1.0);
    render_face_line(box, 0.0, 1.0, 0.0, 0.0);
  }
}

void render_world(Draw_Box box, Real w, Real h, Real view_bottom)
// ----------------------------------------------------------------
// Draw the 3D view: sky, then every face far to near, then the
// outline of the targeted block. Must be inside a batch draw.
// ----------------------------------------------------------------
{
  Integer bucket = 0;

  render_setup_camera(w, h, view_bottom);

  g_face_total     = 0;
  g_stat_faces     = 0;
  g_stat_polygons  = 0;
  g_stat_sections  = 0;
  for (bucket = 1; bucket <= MAX_BUCKETS; ++bucket) g_bucket_head[bucket] = 0;

  render_sky(box);
  render_collect_blocks();
  render_collect_cows();
  render_collect_drops();
  g_stat_faces = g_face_total;

  render_draw_faces(box);
  render_target_outline(box);
}

#endif
