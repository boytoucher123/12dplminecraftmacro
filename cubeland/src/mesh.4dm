#ifndef MESH_4DM_INCLUDED
#define MESH_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
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
// cannot have a visible face. Caves and ponds lower a column's
// solid depth. Only valid for unedited sections (edits mark
// sections dirty, which skips this shortcut).
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
      if (world_solid_below(x, z) <= top) return FALSE;
    }
  }
  return TRUE;
}

void mesh_build_section(Integer sx, Integer sy, Integer sz)
// ----------------------------------------------------------------
// Rebuild the face list of one section
// A solid block shows a face wherever its neighbour doesn't hide it
// (air or a plant); faces against water are kept too but flagged
// wet (only drawn when the camera is under water). Water only
// shows faces against air. Plants are one DIR_PLANT entry.
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

        if (block_is_plant(block)) {
          if (count >= SECTION_FACE_CAP) {
            ++g_mesh_overflow;
            continue;
          }
          ++count;
          g_face_x    [start + count] = x;
          g_face_y    [start + count] = y;
          g_face_z    [start + count] = z;
          g_face_dir  [start + count] = DIR_PLANT;
          g_face_light[start + count] = mesh_face_light(x, y, z, 0);
          continue;
        }

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

          if (block_hides_faces(neighbour)) continue;
          flag = 0;
          if (neighbour == BLOCK_WATER) {
            if (is_water) continue;
            flag = DIR_WET_FLAG;
          }

          if (count >= SECTION_FACE_CAP) {
            ++g_mesh_overflow;
            continue;
          }
          ++count;
          g_face_x    [start + count] = x;
          g_face_y    [start + count] = y;
          g_face_z    [start + count] = z;
          g_face_dir  [start + count] = direction + flag;
          g_face_light[start + count] = mesh_face_light(x, y, z, direction);
        }
      }
    }
  }

  g_section_count[section] = count;
  g_section_state[section] = SECTION_BUILT;
  mesh_group_faces(section);
}

Integer mesh_face_light(Integer x, Integer y, Integer z, Integer direction)
// ----------------------------------------------------------------
// Light level (0..LIGHT_FULL) of the face of cell (x, y, z) facing
// direction, or of the cell itself for direction 0 (plants)
// Daylight fades with depth below the sky top of the column in
// front of the face; then the face is darkened by solid blocks
// around the cell in front: 4 edge neighbours count 2, 4 corner
// neighbours count 1, out of 12.
// ----------------------------------------------------------------
{
  Integer front_x  = x;
  Integer front_y  = y;
  Integer front_z  = z;
  Integer sky_top  = 0;
  Integer light    = LIGHT_FULL;
  Integer enclosed = 0;
  Integer a        = 0;
  Integer b        = 0;

  if (direction == DIR_PX) front_x = x + 1;
  if (direction == DIR_NX) front_x = x - 1;
  if (direction == DIR_PY) front_y = y + 1;
  if (direction == DIR_NY) front_y = y - 1;
  if (direction == DIR_PZ) front_z = z + 1;
  if (direction == DIR_NZ) front_z = z - 1;

  sky_top = world_sky_top(front_x, front_z);
  if (front_y <= sky_top) {
    light = LIGHT_FULL - (sky_top - front_y + 1) * LIGHT_DEPTH_STEP;
    if (light < LIGHT_MIN) light = LIGHT_MIN;
  }
  if (direction == 0) return light;

  // The two axes across the face, a and b, each -1..1
  for (a = -1; a <= 1; ++a) {
    for (b = -1; b <= 1; ++b) {
      if (a == 0 && b == 0) continue;
      if (direction == DIR_PX || direction == DIR_NX) {
        if (!world_is_solid(front_x, front_y + a, front_z + b)) continue;
      } else if (direction == DIR_PY || direction == DIR_NY) {
        if (!world_is_solid(front_x + a, front_y, front_z + b)) continue;
      } else {
        if (!world_is_solid(front_x + a, front_y + b, front_z)) continue;
      }
      if (a == 0 || b == 0) {
        enclosed = enclosed + 2;
      } else {
        enclosed = enclosed + 1;
      }
    }
  }

  return light - floor_divide(light * enclosed * LIGHT_AO_STRENGTH, 1200);
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
  Integer group     = (section - 1) * NUM_FACE_GROUPS;
  Integer entry     = 0;
  Integer direction = 0;
  Integer position  = 0;
  Integer running   = 0;

  for (direction = 1; direction <= NUM_FACE_GROUPS; ++direction) g_section_dir_count[group + direction] = 0;

  for (entry = 1; entry <= count; ++entry) {
    direction = g_face_dir[start + entry];
    if (direction > DIR_WET_FLAG) direction = direction - DIR_WET_FLAG;
    g_section_dir_count[group + direction] = g_section_dir_count[group + direction] + 1;
  }

  running = 0;
  for (direction = 1; direction <= NUM_FACE_GROUPS; ++direction) {
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
    g_sort_light[position] = g_face_light[start + entry];
  }

  for (entry = 1; entry <= count; ++entry) {
    g_face_x  [start + entry] = g_sort_x  [entry];
    g_face_y  [start + entry] = g_sort_y  [entry];
    g_face_z  [start + entry] = g_sort_z  [entry];
    g_face_dir[start + entry] = g_sort_dir[entry];
    g_face_light[start + entry] = g_sort_light[entry];
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
// be rebuilt before it is next drawn. Light depends on the blocks
// above and around, so the sections below the change (shadows) and
// the diagonal neighbours (corner shading) are rebuilt too.
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
        if (!world_in_bounds(x + dx, y + dy, z + dz)) continue;
        sx = floor_divide(x + dx, SECTION_SIZE);
        sy = floor_divide(y + dy, SECTION_SIZE);
        sz = floor_divide(z + dz, SECTION_SIZE);
        g_section_state[mesh_section_index(sx, sy, sz)] = SECTION_DIRTY;
      }
    }
  }

  // Shadow below: the section under the change in this column (the
  // shadow reaches further, but rebuilding every section down to
  // the bedrock would stall the game; deeper ones catch up when
  // something near them changes)
  sx = floor_divide(x, SECTION_SIZE);
  sz = floor_divide(z, SECTION_SIZE);
  sy = floor_divide(y, SECTION_SIZE) - 1;
  if (sy >= 0) g_section_state[mesh_section_index(sx, sy, sz)] = SECTION_DIRTY;
}

void mesh_on_event(Attributes &event)
// ----------------------------------------------------------------
// Event handler: rebuild sections around changed blocks
// ----------------------------------------------------------------
{
  Integer type = event_type(event);

  if (type == EVT_BLOCK_BROKEN || type == EVT_BLOCK_PLACED) {
    mesh_mark_dirty(event_integer(event, 1), event_integer(event, 2), event_integer(event, 3));
  }
}

#endif
