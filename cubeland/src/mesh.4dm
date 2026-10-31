#ifndef MESH_4DM_INCLUDED
#define MESH_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/events.h"
#include "../include/blocks.h"
#include "../include/world.h"
#include "../include/mesh.h"

Integer mesh_section_index(Integer sx, Integer sy, Integer sz)
// ----------------------------------------------------------------
// Array position of section (sx, sy, sz), all 0-based
// ----------------------------------------------------------------
{
  return (sx * SECTIONS_Z + sz) * SECTIONS_Y + sy + 1;
}

void mesh_reset()
// ----------------------------------------------------------------
// Forget every cached face list (after generating or loading)
// ----------------------------------------------------------------
{
  Integer section = 0;

  for (section = 1; section <= NUM_SECTIONS; ++section) {
    g_section_state[section] = SECTION_UNBUILT;
    g_section_count[section] = 0;
  }
  g_mesh_overflow = 0;
  g_mesh_builds   = 0;
}

Integer mesh_section_buried(Integer sx, Integer sy, Integer sz)
// ----------------------------------------------------------------
// TRUE if, as generated, every block of the section and of the
// columns around it is solid up to above the section's top, so it
// cannot have a visible face. Only valid for unedited sections
// (edits mark sections dirty, which skips this shortcut).
// ----------------------------------------------------------------
{
  Integer top = sy * SECTION_SIZE + SECTION_SIZE - 1;
  Integer x   = 0;
  Integer z   = 0;
  Integer x0  = sx * SECTION_SIZE - 1;
  Integer z0  = sz * SECTION_SIZE - 1;

  for (x = x0; x <= x0 + SECTION_SIZE + 1; ++x) {
    if (x < 0 || x >= WORLD_SIZE_X) continue;
    for (z = z0; z <= z0 + SECTION_SIZE + 1; ++z) {
      if (z < 0 || z >= WORLD_SIZE_Z) continue;
      // Tree trunks replace grass with dirt but never dig, so the
      // generated height is a safe lower bound for the solid top
      if (g_height_map[x * WORLD_SIZE_Z + z + 1] <= top) return FALSE;
    }
  }
  return TRUE;
}

void mesh_build_section(Integer sx, Integer sy, Integer sz)
// ----------------------------------------------------------------
// Rebuild the face list of one section
// A solid block shows a face wherever its neighbour is air; faces
// against water are kept too but flagged wet (only drawn when the
// camera is under water). Water only shows faces against air.
// Outside the world counts as solid so the world edge isn't drawn.
// ----------------------------------------------------------------
{
  Integer section   = mesh_section_index(sx, sy, sz);
  Integer start     = (section - 1) * SECTION_FACE_CAP;
  Integer count     = 0;
  Integer x0        = sx * SECTION_SIZE;
  Integer y0        = sy * SECTION_SIZE;
  Integer z0        = sz * SECTION_SIZE;
  Integer x         = 0;
  Integer y         = 0;
  Integer z         = 0;
  Integer column    = 0;
  Integer cell      = 0;
  Integer block     = 0;
  Integer direction = 0;
  Integer neighbour = 0;
  Integer is_water  = 0;
  Integer flag      = 0;

  ++g_mesh_builds;

  if (g_section_state[section] == SECTION_UNBUILT) {
    if (mesh_section_buried(sx, sy, sz)) {
      g_section_count[section] = 0;
      g_section_state[section] = SECTION_BUILT;
      mesh_group_faces(section);
      return;
    }
  }

  for (x = x0; x < x0 + SECTION_SIZE; ++x) {
    for (z = z0; z < z0 + SECTION_SIZE; ++z) {
      column = world_index(x, 0, z);
      for (y = y0; y < y0 + SECTION_SIZE; ++y) {
        cell  = column + y;
        block = g_world[cell];
        if (block == BLOCK_AIR) continue;
        is_water = block == BLOCK_WATER;

        for (direction = DIR_PX; direction <= DIR_NZ; ++direction) {
          neighbour = BLOCK_STONE;
          if (direction == DIR_PX) {
            if (x + 1 < WORLD_SIZE_X) neighbour = g_world[cell + WORLD_STRIDE_X];
          } else if (direction == DIR_NX) {
            if (x > 0) neighbour = g_world[cell - WORLD_STRIDE_X];
          } else if (direction == DIR_PY) {
            neighbour = BLOCK_AIR;
            if (y + 1 < WORLD_HEIGHT) neighbour = g_world[cell + 1];
          } else if (direction == DIR_NY) {
            if (y > 0) neighbour = g_world[cell - 1];
          } else if (direction == DIR_PZ) {
            if (z + 1 < WORLD_SIZE_Z) neighbour = g_world[cell + WORLD_STRIDE_Z];
          } else {
            if (z > 0) neighbour = g_world[cell - WORLD_STRIDE_Z];
          }

          flag = -1;
          if (neighbour == BLOCK_AIR) {
            flag = 0;
          } else if (neighbour == BLOCK_WATER) {
            if (!is_water) flag = DIR_WET_FLAG;
          }
          if (flag < 0) continue;

          if (count >= SECTION_FACE_CAP) {
            ++g_mesh_overflow;
            continue;
          }
          ++count;
          g_face_x  [start + count] = x;
          g_face_y  [start + count] = y;
          g_face_z  [start + count] = z;
          g_face_dir[start + count] = direction + flag;
        }
      }
    }
  }

  g_section_count[section] = count;
  g_section_state[section] = SECTION_BUILT;
  mesh_group_faces(section);
}

void mesh_group_faces(Integer section)
// ----------------------------------------------------------------
// Sort a section's faces by direction (a counting sort) and record
// where each direction's group starts. The renderer can then skip a
// whole group when the camera is behind every face in it.
// ----------------------------------------------------------------
{
  Integer start     = (section - 1) * SECTION_FACE_CAP;
  Integer count     = g_section_count[section];
  Integer group     = (section - 1) * 6;
  Integer entry     = 0;
  Integer direction = 0;
  Integer position  = 0;
  Integer running   = 0;

  for (direction = 1; direction <= 6; ++direction) g_section_dir_count[group + direction] = 0;

  for (entry = 1; entry <= count; ++entry) {
    direction = g_face_dir[start + entry];
    if (direction > DIR_WET_FLAG) direction = direction - DIR_WET_FLAG;
    g_section_dir_count[group + direction] = g_section_dir_count[group + direction] + 1;
  }

  running = 0;
  for (direction = 1; direction <= 6; ++direction) {
    g_section_dir_start[group + direction] = running + 1;
    g_sort_next[direction] = running + 1;
    running = running + g_section_dir_count[group + direction];
  }

  for (entry = 1; entry <= count; ++entry) {
    direction = g_face_dir[start + entry];
    if (direction > DIR_WET_FLAG) direction = direction - DIR_WET_FLAG;
    position = g_sort_next[direction];
    g_sort_next[direction] = position + 1;
    g_sort_x  [position] = g_face_x  [start + entry];
    g_sort_y  [position] = g_face_y  [start + entry];
    g_sort_z  [position] = g_face_z  [start + entry];
    g_sort_dir[position] = g_face_dir[start + entry];
  }

  for (entry = 1; entry <= count; ++entry) {
    g_face_x  [start + entry] = g_sort_x  [entry];
    g_face_y  [start + entry] = g_sort_y  [entry];
    g_face_z  [start + entry] = g_sort_z  [entry];
    g_face_dir[start + entry] = g_sort_dir[entry];
  }
}

Integer mesh_ensure_section(Integer sx, Integer sy, Integer sz)
// ----------------------------------------------------------------
// Make sure a section's face list is current and return its index
// ----------------------------------------------------------------
{
  Integer section = mesh_section_index(sx, sy, sz);

  if (g_section_state[section] != SECTION_BUILT) mesh_build_section(sx, sy, sz);

  return section;
}

void mesh_mark_dirty(Integer x, Integer y, Integer z)
// ----------------------------------------------------------------
// A block changed: its section, and any section it borders, must
// be rebuilt before it is next drawn
// ----------------------------------------------------------------
{
  Integer dx = 0;
  Integer dy = 0;
  Integer dz = 0;
  Integer sx = 0;
  Integer sy = 0;
  Integer sz = 0;

  for (dx = -1; dx <= 1; ++dx) {
    for (dy = -1; dy <= 1; ++dy) {
      for (dz = -1; dz <= 1; ++dz) {
        if (Absolute(dx) + Absolute(dy) + Absolute(dz) > 1) continue;
        if (!world_in_bounds(x + dx, y + dy, z + dz)) continue;
        sx = floor_divide(x + dx, SECTION_SIZE);
        sy = floor_divide(y + dy, SECTION_SIZE);
        sz = floor_divide(z + dz, SECTION_SIZE);
        g_section_state[mesh_section_index(sx, sy, sz)] = SECTION_DIRTY;
      }
    }
  }
}

void mesh_on_event()
// ----------------------------------------------------------------
// Event handler: rebuild sections around changed blocks
// ----------------------------------------------------------------
{
  if (g_ev_type == EVT_BLOCK_BROKEN || g_ev_type == EVT_BLOCK_PLACED) {
    mesh_mark_dirty(g_ev_i1, g_ev_i2, g_ev_i3);
  }
}

#endif
