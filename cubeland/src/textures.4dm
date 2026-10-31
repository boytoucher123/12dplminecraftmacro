#ifndef TEXTURES_4DM_INCLUDED
#define TEXTURES_4DM_INCLUDED

#include "../include/common.h"
#include "../include/util.h"
#include "../include/textures.h"

// ---------------------------------------------------------------- texture access

Integer texture_palette_index(Integer tex, Integer index)
// ----------------------------------------------------------------
// Position of palette colour index (1..PALETTE_SIZE) of a texture
// in the g_tex_pal_* arrays
// ----------------------------------------------------------------
{
  return (tex - 1) * PALETTE_SIZE + index;
}

void texture_set_palette(Integer tex, Integer index, Integer red, Integer green, Integer blue)
// ----------------------------------------------------------------
// Define colour number index of a texture's palette
// ----------------------------------------------------------------
{
  Integer slot = texture_palette_index(tex, index);

  g_tex_pal_r[slot] = red;
  g_tex_pal_g[slot] = green;
  g_tex_pal_b[slot] = blue;
}

void texture_set(Integer tex, Integer u, Integer v, Integer index)
// ----------------------------------------------------------------
// Set one pixel; u is the column (1 = left), v is the row (1 = top)
// Pixels outside the texture are ignored
// ----------------------------------------------------------------
{
  if (u < 1 || u > TEX_SIZE || v < 1 || v > TEX_SIZE) return;

  g_tex_pixel[(tex - 1) * 256 + (v - 1) * TEX_SIZE + u] = index;
}

Integer texture_get(Integer tex, Integer u, Integer v)
// ----------------------------------------------------------------
// Palette index of one pixel, 0 outside the texture
// ----------------------------------------------------------------
{
  if (u < 1 || u > TEX_SIZE || v < 1 || v > TEX_SIZE) return 0;

  return g_tex_pixel[(tex - 1) * 256 + (v - 1) * TEX_SIZE + u];
}

void texture_fill(Integer tex, Integer index)
// ----------------------------------------------------------------
// Set every pixel of a texture
// ----------------------------------------------------------------
{
  texture_fill_rect(tex, 1, 1, TEX_SIZE, TEX_SIZE, index);
}

void texture_fill_rect(Integer tex, Integer u0, Integer v0, Integer u1, Integer v1, Integer index)
// ----------------------------------------------------------------
// Set every pixel in columns u0..u1 and rows v0..v1
// ----------------------------------------------------------------
{
  Integer u = 0;
  Integer v = 0;

  for (v = v0; v <= v1; ++v) {
    for (u = u0; u <= u1; ++u) {
      texture_set(tex, u, v, index);
    }
  }
}

void texture_copy(Integer from_tex, Integer to_tex)
// ----------------------------------------------------------------
// Copy the pixels and palette of one texture to another
// ----------------------------------------------------------------
{
  Integer pixel = 0;
  Integer index = 0;

  for (pixel = 1; pixel <= 256; ++pixel) {
    g_tex_pixel[(to_tex - 1) * 256 + pixel] = g_tex_pixel[(from_tex - 1) * 256 + pixel];
  }
  for (index = 1; index <= PALETTE_SIZE; ++index) {
    g_tex_pal_r[texture_palette_index(to_tex, index)] = g_tex_pal_r[texture_palette_index(from_tex, index)];
    g_tex_pal_g[texture_palette_index(to_tex, index)] = g_tex_pal_g[texture_palette_index(from_tex, index)];
    g_tex_pal_b[texture_palette_index(to_tex, index)] = g_tex_pal_b[texture_palette_index(from_tex, index)];
  }
}

Real texture_random(Integer tex, Integer u, Integer v, Integer salt)
// ----------------------------------------------------------------
// Repeatable random number in [0, 1) for one pixel
// ----------------------------------------------------------------
{
  return hash_real(tex * 13.37 + salt * 5.11, u * 1.0, v * 1.0);
}

Real texture_noise(Integer tex, Integer u, Integer v, Integer cell, Integer salt)
// ----------------------------------------------------------------
// Smooth value noise over the texture with lattice spacing cell
// (cell must divide 16); wraps so the texture tiles seamlessly
// ----------------------------------------------------------------
{
  Integer lattice = floor_divide(TEX_SIZE, cell);
  Real    x       = (u - 0.5) / cell;
  Real    y       = (v - 0.5) / cell;
  Integer x0      = Floor(x);
  Integer y0      = Floor(y);
  Real    fx      = smooth_curve(x - x0);
  Real    fy      = smooth_curve(y - y0);
  Integer x1      = positive_mod(x0 + 1, lattice);
  Integer y1      = positive_mod(y0 + 1, lattice);
  Real    v00     = 0.0;
  Real    v10     = 0.0;
  Real    v01     = 0.0;
  Real    v11     = 0.0;

  x0  = positive_mod(x0, lattice);
  y0  = positive_mod(y0, lattice);
  v00 = hash_real(tex * 7.3 + salt, x0 * 1.0, y0 * 1.0);
  v10 = hash_real(tex * 7.3 + salt, x1 * 1.0, y0 * 1.0);
  v01 = hash_real(tex * 7.3 + salt, x0 * 1.0, y1 * 1.0);
  v11 = hash_real(tex * 7.3 + salt, x1 * 1.0, y1 * 1.0);

  return lerp_real(lerp_real(v00, v10, fx), lerp_real(v01, v11, fx), fy);
}

// ---------------------------------------------------------------- finishing

void texture_finish(Integer tex)
// ----------------------------------------------------------------
// Work out the drawing data for a finished texture:
//  - the base (most common) colour and the average colour
//  - the 2 x 2 quadrant colours used by item icons
//  - rectangles covering every non-base pixel, grown greedily
//    right then down so that runs of one colour share a polygon
// ----------------------------------------------------------------
{
  Integer index     = 0;
  Integer base      = 1;
  Integer u         = 0;
  Integer v         = 0;
  Integer u_end     = 0;
  Integer v_end     = 0;
  Integer colour    = 0;
  Integer slot      = 0;
  Integer grow      = 0;
  Integer row_ok    = 0;
  Integer check_u   = 0;
  Integer quadrant  = 0;
  Real    sum_r     = 0.0;
  Real    sum_g     = 0.0;
  Real    sum_b     = 0.0;

  for (index = 1; index <= PALETTE_SIZE; ++index) g_tex_count[index] = 0;
  for (quadrant = 1; quadrant <= 4; ++quadrant) {
    g_tex_sum_r[quadrant] = 0.0;
    g_tex_sum_g[quadrant] = 0.0;
    g_tex_sum_b[quadrant] = 0.0;
  }

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      colour = texture_get(tex, u, v);
      if (colour < 1 || colour > PALETTE_SIZE) colour = 1;
      g_tex_count[colour] = g_tex_count[colour] + 1;

      slot  = texture_palette_index(tex, colour);
      sum_r = sum_r + g_tex_pal_r[slot];
      sum_g = sum_g + g_tex_pal_g[slot];
      sum_b = sum_b + g_tex_pal_b[slot];

      // quadrant 1 top left, 2 top right, 3 bottom left, 4 bottom right
      quadrant = 1;
      if (u > 8) quadrant = quadrant + 1;
      if (v > 8) quadrant = quadrant + 2;
      g_tex_sum_r[quadrant] = g_tex_sum_r[quadrant] + g_tex_pal_r[slot];
      g_tex_sum_g[quadrant] = g_tex_sum_g[quadrant] + g_tex_pal_g[slot];
      g_tex_sum_b[quadrant] = g_tex_sum_b[quadrant] + g_tex_pal_b[slot];
    }
  }

  for (index = 1; index <= PALETTE_SIZE; ++index) {
    if (g_tex_count[index] > g_tex_count[base]) base = index;
  }
  g_tex_base [tex] = base;
  g_tex_avg_r[tex] = sum_r / 256.0;
  g_tex_avg_g[tex] = sum_g / 256.0;
  g_tex_avg_b[tex] = sum_b / 256.0;
  for (quadrant = 1; quadrant <= 4; ++quadrant) {
    g_tex_quad_r[(tex - 1) * 4 + quadrant] = g_tex_sum_r[quadrant] / 64.0;
    g_tex_quad_g[(tex - 1) * 4 + quadrant] = g_tex_sum_g[quadrant] / 64.0;
    g_tex_quad_b[(tex - 1) * 4 + quadrant] = g_tex_sum_b[quadrant] / 64.0;
  }

  // Rectangles
  for (index = 1; index <= 256; ++index) g_tex_mark[index] = 0;
  g_tex_rect_first[tex] = g_rect_total + 1;
  g_tex_rect_count[tex] = 0;

  // One colour at a time, so a texture's rectangles come grouped by
  // colour and the renderer only changes colour between groups
  for (colour = 1; colour <= PALETTE_SIZE; ++colour) {
    if (colour == base) continue;
    for (v = 1; v <= TEX_SIZE; ++v) {
      for (u = 1; u <= TEX_SIZE; ++u) {
        if (texture_get(tex, u, v) != colour) continue;
        if (g_tex_mark[(v - 1) * TEX_SIZE + u] != 0) continue;

        // Grow right along the row
        u_end = u;
        grow  = TRUE;
        while (grow) {
          grow = FALSE;
          if (u_end < TEX_SIZE) {
            if (texture_get(tex, u_end + 1, v) == colour) {
              if (g_tex_mark[(v - 1) * TEX_SIZE + u_end + 1] == 0) {
                ++u_end;
                grow = TRUE;
              }
            }
          }
        }

        // Grow down while the whole span below matches
        v_end = v;
        grow  = TRUE;
        while (grow) {
          grow = FALSE;
          if (v_end < TEX_SIZE) {
            row_ok = TRUE;
            for (check_u = u; check_u <= u_end; ++check_u) {
              if (texture_get(tex, check_u, v_end + 1) != colour) row_ok = FALSE;
              if (g_tex_mark[v_end * TEX_SIZE + check_u] != 0) row_ok = FALSE;
            }
            if (row_ok) {
              ++v_end;
              grow = TRUE;
            }
          }
        }

        for (index = v; index <= v_end; ++index) {
          for (check_u = u; check_u <= u_end; ++check_u) {
            g_tex_mark[(index - 1) * TEX_SIZE + check_u] = 1;
          }
        }

        if (g_rect_total >= MAX_TEXTURE_RECTS) continue;

        ++g_rect_total;
        // Texture rows run top to bottom, face v runs bottom (0) to top (1)
        g_rect_u0  [g_rect_total] = (u - 1) / 16.0;
        g_rect_u1  [g_rect_total] = u_end / 16.0;
        g_rect_v0  [g_rect_total] = 1.0 - v_end / 16.0;
        g_rect_v1  [g_rect_total] = 1.0 - (v - 1) / 16.0;
        g_rect_pal [g_rect_total] = colour;
        g_rect_area[g_rect_total] = (u_end - u + 1) * (v_end - v + 1);
        g_tex_rect_count[tex] = g_tex_rect_count[tex] + 1;
      }
    }
  }
}

// ---------------------------------------------------------------- the textures

void texture_speckle(Integer tex, Integer index, Real chance, Integer salt)
// ----------------------------------------------------------------
// Scatter single pixels of colour index over a texture
// ----------------------------------------------------------------
{
  Integer u = 0;
  Integer v = 0;

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      if (texture_random(tex, u, v, salt) < chance) texture_set(tex, u, v, index);
    }
  }
}

void texture_blotch(Integer tex, Integer index, Integer cell, Real below, Real above, Integer salt)
// ----------------------------------------------------------------
// Paint colour index wherever smooth noise lies in [below, above]
// ----------------------------------------------------------------
{
  Integer u     = 0;
  Integer v     = 0;
  Real    value = 0.0;

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      value = texture_noise(tex, u, v, cell, salt);
      if (value >= below && value <= above) texture_set(tex, u, v, index);
    }
  }
}

void make_texture_stone(Integer tex)
// ----------------------------------------------------------------
// Grey rock with soft darker and lighter patches
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 128, 128, 128);
  texture_set_palette(tex, 2, 108, 108, 111);
  texture_set_palette(tex, 3, 147, 147, 147);
  texture_fill  (tex, 1);
  texture_blotch(tex, 2, 4, 0.0 , 0.33, 1);
  texture_blotch(tex, 3, 4, 0.74, 1.0 , 2);
}

void make_texture_bedrock(Integer tex)
// ----------------------------------------------------------------
// Very dark mottled rock
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 72 , 72 , 72 );
  texture_set_palette(tex, 2, 38 , 38 , 40 );
  texture_set_palette(tex, 3, 112, 112, 112);
  texture_fill  (tex, 1);
  texture_blotch(tex, 2, 4, 0.0 , 0.42, 3);
  texture_blotch(tex, 3, 2, 0.80, 1.0 , 4);
}

void make_texture_cobblestone(Integer tex)
// ----------------------------------------------------------------
// Rounded stones set in dark mortar, built from the distance to a
// handful of random points (nearest point = which stone a pixel is
// part of, close to two points = mortar)
// ----------------------------------------------------------------
{
  Integer point    = 0;
  Integer u        = 0;
  Integer v        = 0;
  Integer nearest  = 0;
  Real    first    = 0.0;
  Real    second   = 0.0;
  Real    du       = 0.0;
  Real    dv       = 0.0;
  Real    distance = 0.0;

  texture_set_palette(tex, 1, 124, 124, 124);
  texture_set_palette(tex, 2, 142, 142, 142);
  texture_set_palette(tex, 3, 106, 106, 108);
  texture_set_palette(tex, 4, 66 , 66 , 68 );

  for (point = 1; point <= 9; ++point) {
    g_cobble_u[point] = 0.5 + texture_random(tex, point, 1, 7) * 15.0;
    g_cobble_v[point] = 0.5 + texture_random(tex, point, 2, 7) * 15.0;
  }

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      first   = 1000.0;
      second  = 1000.0;
      nearest = 1;
      for (point = 1; point <= 9; ++point) {
        du = Absolute(u - 0.5 - g_cobble_u[point]);
        dv = Absolute(v - 0.5 - g_cobble_v[point]);
        if (du > 8.0) du = 16.0 - du;
        if (dv > 8.0) dv = 16.0 - dv;
        distance = Sqrt(du * du + dv * dv);
        if (distance < first) {
          second  = first;
          first   = distance;
          nearest = point;
        } else if (distance < second) {
          second = distance;
        }
      }
      if (second - first < 1.0) {
        texture_set(tex, u, v, 4);
      } else {
        texture_set(tex, u, v, 1 + positive_mod(nearest, 3));
      }
    }
  }
}

void make_texture_dirt(Integer tex)
// ----------------------------------------------------------------
// Brown earth with darker clods and a few light grains
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 134, 96 , 66);
  texture_set_palette(tex, 2, 110, 77 , 52);
  texture_set_palette(tex, 3, 156, 116, 83);
  texture_fill   (tex, 1);
  texture_blotch (tex, 2, 4, 0.0, 0.28, 5);
  texture_speckle(tex, 2, 0.03, 6);
  texture_speckle(tex, 3, 0.03, 8);
}

void make_texture_grass_top(Integer tex)
// ----------------------------------------------------------------
// Green turf seen from above
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 92 , 158, 52);
  texture_set_palette(tex, 2, 74 , 134, 41);
  texture_set_palette(tex, 3, 112, 178, 64);
  texture_fill   (tex, 1);
  texture_blotch (tex, 2, 4, 0.0, 0.30, 9);
  texture_speckle(tex, 3, 0.05, 10);
  texture_speckle(tex, 2, 0.02, 11);
}

void make_texture_grass_side(Integer tex)
// ----------------------------------------------------------------
// Dirt with a ragged band of turf along the top edge
// ----------------------------------------------------------------
{
  Integer u = 0;

  texture_copy(TEX_DIRT, tex);
  texture_set_palette(tex, 4, 92, 158, 52);
  texture_set_palette(tex, 5, 74, 134, 41);

  texture_fill_rect(tex, 1, 1, TEX_SIZE, 3, 4);
  for (u = 1; u <= TEX_SIZE; ++u) {
    if (texture_random(tex, u, 1, 12) < 0.6 ) texture_set(tex, u, 4, 4);
    if (texture_random(tex, u, 2, 12) < 0.22) texture_set(tex, u, 5, 5);
    if (texture_random(tex, u, 3, 12) < 0.25) texture_set(tex, u, 2, 5);
  }
}

void make_texture_log_side(Integer tex)
// ----------------------------------------------------------------
// Bark: vertical grooves of darker and lighter wood
// ----------------------------------------------------------------
{
  Integer u      = 0;
  Integer v      = 0;
  Integer stripe = 1;
  Real    choice = 0.0;

  texture_set_palette(tex, 1, 104, 82, 50);
  texture_set_palette(tex, 2, 82 , 63, 37);
  texture_set_palette(tex, 3, 124, 99, 62);
  texture_fill(tex, 1);

  for (u = 1; u <= TEX_SIZE; ++u) {
    choice = texture_random(tex, u, 0, 13);
    stripe = 1;
    if (choice < 0.38) stripe = 2;
    if (choice > 0.84) stripe = 3;
    for (v = 1; v <= TEX_SIZE; ++v) {
      if (texture_random(tex, u, v, 14) > 0.12) texture_set(tex, u, v, stripe);
    }
  }
}

void make_texture_log_top(Integer tex)
// ----------------------------------------------------------------
// Cut end of a log: growth rings inside a ring of bark
// ----------------------------------------------------------------
{
  Integer u        = 0;
  Integer v        = 0;
  Integer ring     = 0;
  Real    distance = 0.0;

  texture_set_palette(tex, 1, 178, 142, 90);
  texture_set_palette(tex, 2, 150, 116, 70);
  texture_set_palette(tex, 3, 104, 82 , 50);

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      distance = Sqrt((u - 8.5) * (u - 8.5) + (v - 8.5) * (v - 8.5));
      ring     = Floor(distance / 2.2);
      if (distance > 7.1) {
        texture_set(tex, u, v, 3);
      } else if (positive_mod(ring, 2) == 1) {
        texture_set(tex, u, v, 2);
      } else {
        texture_set(tex, u, v, 1);
      }
    }
  }
}

void make_texture_leaves(Integer tex)
// ----------------------------------------------------------------
// Clumps of leaves with dark gaps between them
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 58 , 124, 40);
  texture_set_palette(tex, 2, 42 , 98 , 30);
  texture_set_palette(tex, 3, 28 , 66 , 20);
  texture_set_palette(tex, 4, 78 , 146, 54);
  texture_fill   (tex, 1);
  texture_blotch (tex, 2, 4, 0.0 , 0.36, 15);
  texture_blotch (tex, 4, 4, 0.72, 1.0 , 16);
  texture_speckle(tex, 3, 0.06, 17);
}

void make_texture_water(Integer tex)
// ----------------------------------------------------------------
// Blue water with broken bands of ripples
// ----------------------------------------------------------------
{
  Integer u = 0;

  texture_set_palette(tex, 1, 44, 92 , 186);
  texture_set_palette(tex, 2, 70, 124, 212);
  texture_set_palette(tex, 3, 36, 76 , 164);
  texture_fill(tex, 1);

  for (u = 1; u <= TEX_SIZE; ++u) {
    if (positive_mod(u + 1 , 8) < 4) texture_set(tex, u, 3 , 2);
    if (positive_mod(u + 5 , 8) < 3) texture_set(tex, u, 8 , 2);
    if (positive_mod(u + 3 , 8) < 4) texture_set(tex, u, 13, 2);
    if (positive_mod(u + 6 , 8) < 3) texture_set(tex, u, 5 , 3);
    if (positive_mod(u + 2 , 8) < 3) texture_set(tex, u, 11, 3);
  }
}

void make_texture_planks(Integer tex)
// ----------------------------------------------------------------
// Four horizontal boards with dark seams, staggered butt joints
// and a little grain
// ----------------------------------------------------------------
{
  Integer board = 0;
  Integer top   = 0;
  Integer joint = 0;
  Integer u     = 0;

  texture_set_palette(tex, 1, 172, 136, 84);
  texture_set_palette(tex, 2, 152, 118, 71);
  texture_set_palette(tex, 3, 112, 86 , 52);
  texture_fill(tex, 1);

  for (board = 0; board <= 3; ++board) {
    top = board * 4 + 1;
    texture_fill_rect(tex, 1, top + 3, TEX_SIZE, top + 3, 3);
    joint = 5 + positive_mod(board * 7, 9);
    texture_fill_rect(tex, joint, top, joint, top + 2, 3);
    for (u = 1; u <= TEX_SIZE; ++u) {
      if (texture_random(tex, u, board, 18) < 0.16) texture_set(tex, u, top + 1, 2);
    }
  }
}

void make_texture_table_top(Integer tex)
// ----------------------------------------------------------------
// Workbench top: planks inside a dark frame with a worn square
// ----------------------------------------------------------------
{
  texture_copy(TEX_PLANKS, tex);
  texture_set_palette(tex, 4, 96 , 70 , 42);
  texture_set_palette(tex, 5, 186, 152, 100);

  texture_fill_rect(tex, 1 , 1 , 16, 2 , 4);
  texture_fill_rect(tex, 1 , 15, 16, 16, 4);
  texture_fill_rect(tex, 1 , 1 , 2 , 16, 4);
  texture_fill_rect(tex, 15, 1 , 16, 16, 4);
  texture_fill_rect(tex, 5 , 5 , 12, 12, 5);
  texture_fill_rect(tex, 6 , 6 , 11, 11, 1);
}

void make_texture_table_side(Integer tex)
// ----------------------------------------------------------------
// Workbench side: planks with a saw and a mallet hanging on them
// ----------------------------------------------------------------
{
  texture_copy(TEX_PLANKS, tex);
  texture_set_palette(tex, 4, 96 , 70 , 42 );
  texture_set_palette(tex, 5, 176, 178, 184);
  texture_set_palette(tex, 6, 70 , 50 , 30 );

  texture_fill_rect(tex, 1 , 1 , 16, 2 , 4);
  // saw: blade and handle
  texture_fill_rect(tex, 2 , 5 , 8 , 7 , 5);
  texture_fill_rect(tex, 3 , 8 , 7 , 8 , 5);
  texture_fill_rect(tex, 9 , 4 , 10, 8 , 6);
  // mallet: head and handle
  texture_fill_rect(tex, 11, 5 , 15, 7 , 6);
  texture_fill_rect(tex, 13, 8 , 13, 13, 6);
}

void make_texture_furnace_side(Integer tex)
// ----------------------------------------------------------------
// Grey masonry: courses of blocks with offset joints
// ----------------------------------------------------------------
{
  Integer course = 0;
  Integer top    = 0;
  Integer offset = 0;

  texture_set_palette(tex, 1, 124, 124, 124);
  texture_set_palette(tex, 2, 92 , 92 , 94 );
  texture_set_palette(tex, 3, 142, 142, 142);
  texture_fill(tex, 1);
  texture_speckle(tex, 3, 0.06, 19);

  for (course = 0; course <= 3; ++course) {
    top    = course * 4 + 1;
    offset = 4 * positive_mod(course, 2);
    texture_fill_rect(tex, 1, top + 3, TEX_SIZE, top + 3, 2);
    texture_fill_rect(tex, 1 + offset, top, 1 + offset, top + 2, 2);
    texture_fill_rect(tex, 9 + offset, top, 9 + offset, top + 2, 2);
  }
}

void make_texture_furnace_top(Integer tex)
// ----------------------------------------------------------------
// Smooth grey slab with a bevelled rim
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 132, 132, 132);
  texture_set_palette(tex, 2, 100, 100, 102);
  texture_set_palette(tex, 3, 150, 150, 150);
  texture_fill     (tex, 1);
  texture_fill_rect(tex, 1 , 1 , 16, 1 , 2);
  texture_fill_rect(tex, 1 , 16, 16, 16, 2);
  texture_fill_rect(tex, 1 , 1 , 1 , 16, 2);
  texture_fill_rect(tex, 16, 1 , 16, 16, 2);
  texture_fill_rect(tex, 3 , 3 , 14, 3 , 3);
  texture_speckle  (tex, 2, 0.04, 20);
}

void make_texture_furnace_front(Integer tex, Integer lit)
// ----------------------------------------------------------------
// Masonry with a vent across the top and a fire box below
// lit = TRUE draws flames in the fire box
// ----------------------------------------------------------------
{
  Integer u = 0;
  Integer v = 0;

  texture_copy(TEX_FURNACE_SIDE, tex);
  texture_set_palette(tex, 4, 34 , 32 , 30 );
  texture_set_palette(tex, 5, 70 , 70 , 72 );
  texture_set_palette(tex, 6, 236, 132, 36 );
  texture_set_palette(tex, 7, 252, 214, 84 );

  // vent
  texture_fill_rect(tex, 3, 3, 14, 4, 4);
  // fire box with a frame
  texture_fill_rect(tex, 3, 8 , 14, 15, 5);
  texture_fill_rect(tex, 4, 9 , 13, 14, 4);

  if (lit) {
    texture_fill_rect(tex, 4, 12, 13, 14, 6);
    for (u = 4; u <= 13; ++u) {
      for (v = 9; v <= 11; ++v) {
        if (texture_random(tex, u, v, 21) < 0.25 + (v - 9) * 0.25) texture_set(tex, u, v, 6);
      }
      if (texture_random(tex, u, 13, 22) < 0.5) texture_set(tex, u, 13, 7);
    }
  }
}

void make_texture_sand(Integer tex)
// ----------------------------------------------------------------
// Pale sand with scattered darker and lighter grains
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 218, 206, 160);
  texture_set_palette(tex, 2, 200, 187, 141);
  texture_set_palette(tex, 3, 232, 222, 182);
  texture_fill   (tex, 1);
  texture_blotch (tex, 2, 4, 0.0, 0.25, 23);
  texture_speckle(tex, 3, 0.06, 24);
}

void make_texture_cow_hide(Integer tex)
// ----------------------------------------------------------------
// White hide with large black patches
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 236, 234, 226);
  texture_set_palette(tex, 2, 44 , 40 , 38 );
  texture_fill  (tex, 1);
  texture_blotch(tex, 2, 8, 0.0, 0.40, 25);
}

void make_texture_cow_face(Integer tex)
// ----------------------------------------------------------------
// Front of the cow's head: hide, two eyes and a pink muzzle
// ----------------------------------------------------------------
{
  texture_copy(TEX_COW_HIDE, tex);
  texture_set_palette(tex, 3, 22 , 20 , 20 );
  texture_set_palette(tex, 4, 224, 166, 156);
  texture_set_palette(tex, 5, 160, 98 , 92 );

  texture_fill_rect(tex, 1 , 4 , 16, 7 , 1);
  texture_fill_rect(tex, 3 , 5 , 5 , 6 , 3);
  texture_fill_rect(tex, 12, 5 , 14, 6 , 3);
  texture_fill_rect(tex, 3 , 10, 14, 16, 4);
  texture_fill_rect(tex, 5 , 12, 6 , 13, 5);
  texture_fill_rect(tex, 11, 12, 12, 13, 5);
}

void make_texture_stick(Integer tex)
// ----------------------------------------------------------------
// Pale wood with a darker grain
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 140, 106, 62);
  texture_set_palette(tex, 2, 104, 76 , 44);
  texture_fill   (tex, 1);
  texture_speckle(tex, 2, 0.12, 26);
}

void make_texture_raw_beef(Integer tex)
// ----------------------------------------------------------------
// Red meat marbled with fat
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 196, 58 , 54 );
  texture_set_palette(tex, 2, 232, 160, 150);
  texture_set_palette(tex, 3, 156, 38 , 36 );
  texture_fill   (tex, 1);
  texture_blotch (tex, 2, 4, 0.0, 0.22, 27);
  texture_speckle(tex, 3, 0.08, 28);
}

void make_texture_cooked_beef(Integer tex)
// ----------------------------------------------------------------
// Browned meat with grill marks
// ----------------------------------------------------------------
{
  Integer line = 0;

  texture_set_palette(tex, 1, 136, 82 , 48);
  texture_set_palette(tex, 2, 92 , 54 , 32);
  texture_set_palette(tex, 3, 172, 114, 70);
  texture_fill  (tex, 1);
  texture_blotch(tex, 3, 4, 0.75, 1.0, 29);
  for (line = 0; line <= 3; ++line) {
    texture_fill_rect(tex, 1, 3 + line * 4, TEX_SIZE, 3 + line * 4, 2);
  }
}

void textures_init()
// ----------------------------------------------------------------
// Generate every texture and its drawing data
// Order matters where one texture starts as a copy of another
// ----------------------------------------------------------------
{
  Integer tex = 0;

  g_rect_total = 0;

  make_texture_bedrock      (TEX_BEDROCK);
  make_texture_stone        (TEX_STONE);
  make_texture_cobblestone  (TEX_COBBLESTONE);
  make_texture_dirt         (TEX_DIRT);
  make_texture_grass_top    (TEX_GRASS_TOP);
  make_texture_grass_side   (TEX_GRASS_SIDE);
  make_texture_log_side     (TEX_LOG_SIDE);
  make_texture_log_top      (TEX_LOG_TOP);
  make_texture_leaves       (TEX_LEAVES);
  make_texture_water        (TEX_WATER);
  make_texture_planks       (TEX_PLANKS);
  make_texture_table_top    (TEX_TABLE_TOP);
  make_texture_table_side   (TEX_TABLE_SIDE);
  make_texture_furnace_side (TEX_FURNACE_SIDE);
  make_texture_furnace_top  (TEX_FURNACE_TOP);
  make_texture_furnace_front(TEX_FURNACE_FRONT, FALSE);
  make_texture_furnace_front(TEX_FURNACE_FRONT_LIT, TRUE);
  make_texture_sand         (TEX_SAND);
  make_texture_cow_hide     (TEX_COW_HIDE);
  make_texture_cow_face     (TEX_COW_FACE);
  make_texture_stick        (TEX_STICK);
  make_texture_raw_beef     (TEX_RAW_BEEF);
  make_texture_cooked_beef  (TEX_COOKED_BEEF);

  for (tex = 1; tex <= NUM_TEXTURES; ++tex) texture_finish(tex);
}

#endif
