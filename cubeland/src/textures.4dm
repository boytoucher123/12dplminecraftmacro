#ifndef TEXTURES_4DM_INCLUDED
#define TEXTURES_4DM_INCLUDED

#include "../include/common.h"
#include "../include/util.h"
#include "../include/blocks.h"
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

void texture_row(Integer tex, Integer v, Text pixels)
// ----------------------------------------------------------------
// Set row v of a texture from 16 characters: "." is see-through,
// "1".."8" are palette colours. Used to draw sprites as pixel art.
// ----------------------------------------------------------------
{
  Text    digits    = "12345678";
  Text    character = "";
  Integer u         = 0;

  for (u = 1; u <= TEX_SIZE; ++u) {
    character = Get_subtext(pixels, u, u);
    texture_set(tex, u, v, Find_text(digits, character));
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
//  - the base (most common) colour and the average colour; a
//    texture with see-through pixels (index 0) is a sprite and has
//    no base colour
//  - the 2 x 2 quadrant colours
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
  Integer opaque    = 0;

  for (index = 1; index <= PALETTE_SIZE; ++index) g_tex_count[index] = 0;
  for (quadrant = 1; quadrant <= 4; ++quadrant) {
    g_tex_sum_r[quadrant] = 0.0;
    g_tex_sum_g[quadrant] = 0.0;
    g_tex_sum_b[quadrant] = 0.0;
    g_tex_sum_n[quadrant] = 0;
  }
  g_tex_is_sprite[tex] = FALSE;

  for (v = 1; v <= TEX_SIZE; ++v) {
    for (u = 1; u <= TEX_SIZE; ++u) {
      colour = texture_get(tex, u, v);
      if (colour == TEX_TRANSPARENT) {
        g_tex_is_sprite[tex] = TRUE;
        continue;
      }
      if (colour < 1 || colour > PALETTE_SIZE) colour = 1;
      g_tex_count[colour] = g_tex_count[colour] + 1;
      ++opaque;

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
      g_tex_sum_n[quadrant] = g_tex_sum_n[quadrant] + 1;
    }
  }
  if (opaque < 1) opaque = 1;

  for (index = 1; index <= PALETTE_SIZE; ++index) {
    if (g_tex_count[index] > g_tex_count[base]) base = index;
  }
  if (g_tex_is_sprite[tex]) base = 0;
  g_tex_base [tex] = base;
  g_tex_avg_r[tex] = sum_r / opaque;
  g_tex_avg_g[tex] = sum_g / opaque;
  g_tex_avg_b[tex] = sum_b / opaque;
  for (quadrant = 1; quadrant <= 4; ++quadrant) {
    if (g_tex_sum_n[quadrant] < 1) g_tex_sum_n[quadrant] = 1;
    g_tex_quad_r[(tex - 1) * 4 + quadrant] = g_tex_sum_r[quadrant] / g_tex_sum_n[quadrant];
    g_tex_quad_g[(tex - 1) * 4 + quadrant] = g_tex_sum_g[quadrant] / g_tex_sum_n[quadrant];
    g_tex_quad_b[(tex - 1) * 4 + quadrant] = g_tex_sum_b[quadrant] / g_tex_sum_n[quadrant];
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

void make_texture_sandstone_side(Integer tex)
// ----------------------------------------------------------------
// Sandy rock in layers, with a smooth band along the top
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 216, 202, 150);
  texture_set_palette(tex, 2, 196, 180, 128);
  texture_set_palette(tex, 3, 230, 220, 172);
  texture_fill     (tex, 1);
  texture_fill_rect(tex, 1, 1 , TEX_SIZE, 3 , 3);
  texture_fill_rect(tex, 1, 4 , TEX_SIZE, 4 , 2);
  texture_fill_rect(tex, 1, 10, TEX_SIZE, 10, 2);
  texture_blotch   (tex, 2, 4, 0.0, 0.18, 41);
}

void make_texture_sandstone_top(Integer tex)
// ----------------------------------------------------------------
// Smooth sandstone with a few darker grains
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 224, 212, 162);
  texture_set_palette(tex, 2, 204, 190, 140);
  texture_fill   (tex, 1);
  texture_speckle(tex, 2, 0.05, 42);
}

void make_texture_cactus_side(Integer tex)
// ----------------------------------------------------------------
// Green ribs with pale spines
// ----------------------------------------------------------------
{
  Integer u = 0;

  texture_set_palette(tex, 1, 58 , 128, 48 );
  texture_set_palette(tex, 2, 38 , 96 , 34 );
  texture_set_palette(tex, 3, 214, 226, 170);
  texture_fill(tex, 1);
  for (u = 2; u <= TEX_SIZE; u = u + 4) texture_fill_rect(tex, u, 1, u, TEX_SIZE, 2);
  texture_speckle(tex, 3, 0.05, 43);
}

void make_texture_cactus_top(Integer tex)
// ----------------------------------------------------------------
// Top of a cactus: lighter centre with a dark rim
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 76 , 146, 62);
  texture_set_palette(tex, 2, 38 , 96 , 34);
  texture_set_palette(tex, 3, 110, 170, 84);
  texture_fill     (tex, 2);
  texture_fill_rect(tex, 2, 2, 15, 15, 1);
  texture_fill_rect(tex, 6, 6, 11, 11, 3);
}

void make_texture_coal_ore(Integer tex)
// ----------------------------------------------------------------
// Stone with black lumps of coal
// ----------------------------------------------------------------
{
  make_texture_stone(tex);
  texture_set_palette(tex, 4, 34, 34, 36);
  texture_set_palette(tex, 5, 64, 64, 68);
  texture_fill_rect(tex, 3 , 3 , 5 , 4 , 4);
  texture_fill_rect(tex, 4 , 5 , 5 , 5 , 5);
  texture_fill_rect(tex, 10, 5 , 13, 7 , 4);
  texture_fill_rect(tex, 11, 8 , 12, 8 , 5);
  texture_fill_rect(tex, 5 , 11, 7 , 13, 4);
  texture_fill_rect(tex, 12, 12, 13, 14, 4);
}

void make_texture_gravel(Integer tex)
// ----------------------------------------------------------------
// Loose grey and brown pebbles
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 132, 126, 124);
  texture_set_palette(tex, 2, 96 , 90 , 88 );
  texture_set_palette(tex, 3, 168, 160, 156);
  texture_set_palette(tex, 4, 120, 100, 86 );
  texture_fill  (tex, 1);
  texture_blotch(tex, 2, 2, 0.0 , 0.25, 44);
  texture_blotch(tex, 3, 2, 0.78, 1.0 , 45);
  texture_speckle(tex, 4, 0.08, 46);
}

void make_texture_plant_grass(Integer tex)
// ----------------------------------------------------------------
// A tuft of grass blades (sprite)
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 2, 82 , 150, 56);
  texture_set_palette(tex, 3, 120, 186, 80);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, "................");
  texture_row(tex,  4, "................");
  texture_row(tex,  5, "......2.....2...");
  texture_row(tex,  6, "..2...2....23...");
  texture_row(tex,  7, "..23..32...2....");
  texture_row(tex,  8, "...2..2...32..2.");
  texture_row(tex,  9, "...32.2..2...32.");
  texture_row(tex, 10, "....2.32.2..2...");
  texture_row(tex, 11, ".2..2..2.2.32...");
  texture_row(tex, 12, ".32..2.2.2.2....");
  texture_row(tex, 13, "..2..2.22.2.....");
  texture_row(tex, 14, "..32.22.2.2.....");
  texture_row(tex, 15, "...2.2.222......");
  texture_row(tex, 16, "...2222222......");
}

void make_texture_plant_flower(Integer tex, Integer red, Integer green, Integer blue)
// ----------------------------------------------------------------
// A flower on a stem (sprite) with petals of the given colour
// ----------------------------------------------------------------
{
  Integer dark_red     = Floor(red   * 0.55);
  Integer dark_green   = Floor(green * 0.55);
  Integer dark_blue    = Floor(blue  * 0.55);
  Integer light_red    = Floor(red   * 0.75 + 60.0);
  Integer light_green  = Floor(green * 0.75 + 60.0);
  Integer light_blue   = Floor(blue  * 0.75 + 60.0);

  texture_set_palette(tex, 1, dark_red , dark_green , dark_blue );
  texture_set_palette(tex, 2, red      , green      , blue      );
  texture_set_palette(tex, 3, light_red, light_green, light_blue);
  texture_set_palette(tex, 4, 60 , 44 , 20 );
  texture_set_palette(tex, 5, 70 , 136, 50 );
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, ".....1111.......");
  texture_row(tex,  4, "....122221......");
  texture_row(tex,  5, "...12233221.....");
  texture_row(tex,  6, "...12234321.....");
  texture_row(tex,  7, "...12233221.....");
  texture_row(tex,  8, "....122221......");
  texture_row(tex,  9, ".....1551.......");
  texture_row(tex, 10, "......5.........");
  texture_row(tex, 11, "......5..55.....");
  texture_row(tex, 12, ".....55.555.....");
  texture_row(tex, 13, "..55..5.55......");
  texture_row(tex, 14, "...55.555.......");
  texture_row(tex, 15, "....5555........");
  texture_row(tex, 16, "......5.........");
}

void make_texture_plant_dead_bush(Integer tex)
// ----------------------------------------------------------------
// Dry twigs for the desert (sprite)
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 128, 86, 40);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, "..1.......1.....");
  texture_row(tex,  4, "...1..1..1...1..");
  texture_row(tex,  5, "...1..1.1...1...");
  texture_row(tex,  6, "1...1.1.1..1....");
  texture_row(tex,  7, ".1..1..11.1..1..");
  texture_row(tex,  8, "..1..1.1.11.1...");
  texture_row(tex,  9, "...1.1.1.1.1....");
  texture_row(tex, 10, "....11.111......");
  texture_row(tex, 11, ".....1.11.......");
  texture_row(tex, 12, "......111.......");
  texture_row(tex, 13, "......11........");
  texture_row(tex, 14, "......1.........");
  texture_row(tex, 15, "......1.........");
  texture_row(tex, 16, "......1.........");
}

void make_texture_item_stick(Integer tex)
// ----------------------------------------------------------------
// Item picture: a stick (sprite)
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 40 , 28 , 12);
  texture_set_palette(tex, 4, 104, 76 , 44);
  texture_set_palette(tex, 5, 150, 112, 66);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, "............11..");
  texture_row(tex,  4, "...........1551.");
  texture_row(tex,  5, "..........15541.");
  texture_row(tex,  6, ".........15441..");
  texture_row(tex,  7, "........15441...");
  texture_row(tex,  8, ".......15441....");
  texture_row(tex,  9, "......15441.....");
  texture_row(tex, 10, ".....15441......");
  texture_row(tex, 11, "....15441.......");
  texture_row(tex, 12, "...15441........");
  texture_row(tex, 13, "..15441.........");
  texture_row(tex, 14, ".1441...........");
  texture_row(tex, 15, ".111............");
  texture_row(tex, 16, "................");
}

void make_texture_item_beef(Integer tex, Integer cooked)
// ----------------------------------------------------------------
// Item picture: a steak, red when raw and brown when cooked
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 60 , 20 , 16 );
  texture_set_palette(tex, 2, 196, 58 , 54 );
  texture_set_palette(tex, 3, 232, 160, 150);
  texture_set_palette(tex, 4, 156, 38 , 36 );
  if (cooked) {
    texture_set_palette(tex, 1, 50 , 28 , 14 );
    texture_set_palette(tex, 2, 136, 82 , 48 );
    texture_set_palette(tex, 3, 176, 120, 74 );
    texture_set_palette(tex, 4, 92 , 54 , 32 );
  }
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, "......1111......");
  texture_row(tex,  4, "....11222211....");
  texture_row(tex,  5, "...1223322221...");
  texture_row(tex,  6, "..122333222221..");
  texture_row(tex,  7, "..123322244221..");
  texture_row(tex,  8, ".12222224442221.");
  texture_row(tex,  9, ".12244222222221.");
  texture_row(tex, 10, ".12244222233321.");
  texture_row(tex, 11, "..1222222333221.");
  texture_row(tex, 12, "..112222222211..");
  texture_row(tex, 13, "....11122111....");
  texture_row(tex, 14, ".......11.......");
  texture_row(tex, 15, "................");
  texture_row(tex, 16, "................");
}

void make_texture_item_coal(Integer tex)
// ----------------------------------------------------------------
// Item picture: a lump of coal
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 14 , 14 , 16 );
  texture_set_palette(tex, 2, 46 , 46 , 50 );
  texture_set_palette(tex, 3, 90 , 90 , 98 );
  texture_set_palette(tex, 4, 30 , 30 , 34 );
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "................");
  texture_row(tex,  3, "................");
  texture_row(tex,  4, ".......111......");
  texture_row(tex,  5, ".....1122211....");
  texture_row(tex,  6, "....122332221...");
  texture_row(tex,  7, "...12233222221..");
  texture_row(tex,  8, "...12322222221..");
  texture_row(tex,  9, "..122222222221..");
  texture_row(tex, 10, "..122224222221..");
  texture_row(tex, 11, "..112222222211..");
  texture_row(tex, 12, "...1122222211...");
  texture_row(tex, 13, ".....111111.....");
  texture_row(tex, 14, "................");
  texture_row(tex, 15, "................");
  texture_row(tex, 16, "................");
}

void make_tool_palette(Integer tex, Integer tier)
// ----------------------------------------------------------------
// Colours of a tool picture: 1 outline, 2 and 3 the head (wood or
// stone), 4 and 5 the wooden handle
// ----------------------------------------------------------------
{
  texture_set_palette(tex, 1, 40 , 28 , 12 );
  texture_set_palette(tex, 4, 104, 76 , 44 );
  texture_set_palette(tex, 5, 150, 112, 66 );
  if (tier == TIER_STONE) {
    texture_set_palette(tex, 2, 118, 118, 118);
    texture_set_palette(tex, 3, 170, 170, 170);
  } else {
    texture_set_palette(tex, 2, 150, 112, 66 );
    texture_set_palette(tex, 3, 188, 152, 98 );
  }
}

void make_texture_item_pickaxe(Integer tex, Integer tier)
// ----------------------------------------------------------------
// Item picture: a pickaxe
// ----------------------------------------------------------------
{
  make_tool_palette(tex, tier);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "....111111......");
  texture_row(tex,  3, "...12333321.....");
  texture_row(tex,  4, "....1112222.1...");
  texture_row(tex,  5, "........11221...");
  texture_row(tex,  6, "........154121..");
  texture_row(tex,  7, ".......1541.121.");
  texture_row(tex,  8, "......15441..11.");
  texture_row(tex,  9, ".....15441......");
  texture_row(tex, 10, "....15441.......");
  texture_row(tex, 11, "...15441........");
  texture_row(tex, 12, "..15441.........");
  texture_row(tex, 13, ".15441..........");
  texture_row(tex, 14, ".1441...........");
  texture_row(tex, 15, ".111............");
  texture_row(tex, 16, "................");
}

void make_texture_item_axe(Integer tex, Integer tier)
// ----------------------------------------------------------------
// Item picture: an axe
// ----------------------------------------------------------------
{
  make_tool_palette(tex, tier);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "........111.....");
  texture_row(tex,  3, ".......12331....");
  texture_row(tex,  4, "......1233331...");
  texture_row(tex,  5, "......12333331..");
  texture_row(tex,  6, ".......1223331..");
  texture_row(tex,  7, "........15411...");
  texture_row(tex,  8, ".......15441....");
  texture_row(tex,  9, "......15441.....");
  texture_row(tex, 10, ".....15441......");
  texture_row(tex, 11, "....15441.......");
  texture_row(tex, 12, "...15441........");
  texture_row(tex, 13, "..15441.........");
  texture_row(tex, 14, ".1441...........");
  texture_row(tex, 15, ".111............");
  texture_row(tex, 16, "................");
}

void make_texture_item_shovel(Integer tex, Integer tier)
// ----------------------------------------------------------------
// Item picture: a shovel
// ----------------------------------------------------------------
{
  make_tool_palette(tex, tier);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "...........111..");
  texture_row(tex,  3, "..........12331.");
  texture_row(tex,  4, ".........123321.");
  texture_row(tex,  5, ".........122321.");
  texture_row(tex,  6, "..........1221..");
  texture_row(tex,  7, ".........1541...");
  texture_row(tex,  8, "........15441...");
  texture_row(tex,  9, ".......15441....");
  texture_row(tex, 10, "......15441.....");
  texture_row(tex, 11, ".....15441......");
  texture_row(tex, 12, "....15441.......");
  texture_row(tex, 13, "...15441........");
  texture_row(tex, 14, "..1441..........");
  texture_row(tex, 15, "..111...........");
  texture_row(tex, 16, "................");
}

void make_texture_item_sword(Integer tex, Integer tier)
// ----------------------------------------------------------------
// Item picture: a sword
// ----------------------------------------------------------------
{
  make_tool_palette(tex, tier);
  texture_row(tex,  1, "................");
  texture_row(tex,  2, "............111.");
  texture_row(tex,  3, "...........13321");
  texture_row(tex,  4, "..........133321");
  texture_row(tex,  5, ".........133321.");
  texture_row(tex,  6, "........133321..");
  texture_row(tex,  7, ".......133321...");
  texture_row(tex,  8, "..1...133321....");
  texture_row(tex,  9, "..11.133321.....");
  texture_row(tex, 10, "...113321.......");
  texture_row(tex, 11, "...11321........");
  texture_row(tex, 12, "..15411.........");
  texture_row(tex, 13, ".1541.11........");
  texture_row(tex, 14, ".141...1........");
  texture_row(tex, 15, ".11.............");
  texture_row(tex, 16, "................");
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
  make_texture_sandstone_top (TEX_SANDSTONE_TOP);
  make_texture_sandstone_side(TEX_SANDSTONE_SIDE);
  make_texture_cactus_top    (TEX_CACTUS_TOP);
  make_texture_cactus_side   (TEX_CACTUS_SIDE);
  make_texture_coal_ore      (TEX_COAL_ORE);
  make_texture_gravel        (TEX_GRAVEL);
  make_texture_plant_grass   (TEX_PLANT_GRASS);
  make_texture_plant_flower  (TEX_PLANT_POPPY, 214, 40, 34);
  make_texture_plant_flower  (TEX_PLANT_DANDELION, 240, 214, 40);
  make_texture_plant_dead_bush(TEX_PLANT_DEAD_BUSH);
  make_texture_item_stick    (TEX_ITEM_STICK);
  make_texture_item_beef     (TEX_ITEM_RAW_BEEF, FALSE);
  make_texture_item_beef     (TEX_ITEM_COOKED_BEEF, TRUE);
  make_texture_item_coal     (TEX_ITEM_COAL);
  make_texture_item_pickaxe  (TEX_ITEM_WOODEN_PICKAXE, TIER_WOOD);
  make_texture_item_pickaxe  (TEX_ITEM_STONE_PICKAXE, TIER_STONE);
  make_texture_item_axe      (TEX_ITEM_WOODEN_AXE, TIER_WOOD);
  make_texture_item_axe      (TEX_ITEM_STONE_AXE, TIER_STONE);
  make_texture_item_shovel   (TEX_ITEM_WOODEN_SHOVEL, TIER_WOOD);
  make_texture_item_shovel   (TEX_ITEM_STONE_SHOVEL, TIER_STONE);
  make_texture_item_sword    (TEX_ITEM_WOODEN_SWORD, TIER_WOOD);
  make_texture_item_sword    (TEX_ITEM_STONE_SWORD, TIER_STONE);

  for (tex = 1; tex <= NUM_TEXTURES; ++tex) texture_finish(tex);
}

#endif
