#ifndef SETTINGS_4DM_INCLUDED
#define SETTINGS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/config.h"
#include "../include/util.h"
#include "../include/records.h"
#include "../include/settings.h"

void settings_defaults(Attributes &settings)
// ----------------------------------------------------------------
// Fill a settings record with the defaults
// ----------------------------------------------------------------
{
  record_clear      (settings, DATATYPE_SETTINGS);
  record_set_integer(settings, ATTR_SET_RENDER_DISTANCE, RENDER_DISTANCE_DEFAULT);
  record_set_integer(settings, ATTR_SET_DETAIL,          DETAIL_NORMAL);
  record_set_integer(settings, ATTR_SET_PLANTS,          TRUE);
  record_set_integer(settings, ATTR_SET_SHADING,         TRUE);
  record_set_integer(settings, ATTR_SET_AUTO_JUMP,       TRUE);
  record_set_integer(settings, ATTR_SET_FOV,             FOV_DEFAULT);
  record_set_integer(settings, ATTR_SET_SENSITIVITY,     SENSITIVITY_DEFAULT);
  record_set_integer(settings, ATTR_SET_SHOW_HUD,        TRUE);
  record_set_integer(settings, ATTR_SET_SHOW_DEBUG,      FALSE);
}

Integer settings_render_distance(Attributes &settings)
// ----------------------------------------------------------------
// How far the world is drawn, in blocks
// ----------------------------------------------------------------
{
  return clamp_integer(record_integer(settings, ATTR_SET_RENDER_DISTANCE), RENDER_DISTANCE_MIN, RENDER_DISTANCE_MAX);
}

Integer settings_detail(Attributes &settings)
// ----------------------------------------------------------------
// Texture detail: DETAIL_LOW, DETAIL_NORMAL or DETAIL_HIGH
// ----------------------------------------------------------------
{
  return clamp_integer(record_integer(settings, ATTR_SET_DETAIL), DETAIL_LOW, DETAIL_HIGH);
}

Integer settings_flag(Attributes &settings, Text field)
// ----------------------------------------------------------------
// An on/off setting (plants, shading, auto jump, HUD, debug)
// ----------------------------------------------------------------
{
  return record_integer(settings, field);
}

Integer settings_fov_degrees(Attributes &settings)
// ----------------------------------------------------------------
// Horizontal field of view in degrees
// ----------------------------------------------------------------
{
  return clamp_integer(record_integer(settings, ATTR_SET_FOV), FOV_MIN, FOV_MAX);
}

Real settings_fov_radians(Attributes &settings)
// ----------------------------------------------------------------
// Horizontal field of view in radians
// ----------------------------------------------------------------
{
  return settings_fov_degrees(settings) * PI / 180.0;
}

Real settings_mouse_scale(Attributes &settings)
// ----------------------------------------------------------------
// Radians turned per pixel of mouse movement
// ----------------------------------------------------------------
{
  return MOUSE_SENSITIVITY * clamp_integer(record_integer(settings, ATTR_SET_SENSITIVITY), SENSITIVITY_MIN, SENSITIVITY_MAX) / SENSITIVITY_DEFAULT;
}

void settings_change(Attributes &settings, Text field, Integer direction)
// ----------------------------------------------------------------
// Step a numeric setting up (direction 1) or down (-1), staying
// within its range
// ----------------------------------------------------------------
{
  Integer value = record_integer(settings, field);

  if (field == ATTR_SET_RENDER_DISTANCE) {
    value = clamp_integer(value + direction * RENDER_DISTANCE_STEP, RENDER_DISTANCE_MIN, RENDER_DISTANCE_MAX);
  } else if (field == ATTR_SET_DETAIL) {
    value = clamp_integer(value + direction, DETAIL_LOW, DETAIL_HIGH);
  } else if (field == ATTR_SET_FOV) {
    value = clamp_integer(value + direction * FOV_STEP, FOV_MIN, FOV_MAX);
  } else if (field == ATTR_SET_SENSITIVITY) {
    value = clamp_integer(value + direction, SENSITIVITY_MIN, SENSITIVITY_MAX);
  } else {
    return;
  }
  record_set_integer(settings, field, value);
}

void settings_toggle(Attributes &settings, Text field)
// ----------------------------------------------------------------
// Flip an on/off setting
// ----------------------------------------------------------------
{
  record_set_integer(settings, field, !record_integer(settings, field));
}

Text settings_describe(Attributes &settings, Text field)
// ----------------------------------------------------------------
// One line describing the current value of a setting
// ----------------------------------------------------------------
{
  Integer value  = record_integer(settings, field);
  Text    on_off = "Off";

  if (value) on_off = "On";

  if (field == ATTR_SET_RENDER_DISTANCE) return "Render distance: " + To_text(settings_render_distance(settings)) + " blocks";
  if (field == ATTR_SET_FOV            ) return "Field of view: " + To_text(settings_fov_degrees(settings)) + " degrees";
  if (field == ATTR_SET_SENSITIVITY    ) return "Mouse sensitivity: " + To_text(value) + " / " + To_text(SENSITIVITY_MAX);
  if (field == ATTR_SET_DETAIL) {
    if (value == DETAIL_LOW ) return "Texture detail: Low (textures only up close)";
    if (value == DETAIL_HIGH) return "Texture detail: High (full textures further out)";
    return "Texture detail: Normal";
  }
  if (field == ATTR_SET_PLANTS    ) return "Grass and flowers: " + on_off;
  if (field == ATTR_SET_SHADING   ) return "Shadows and corner shading: " + on_off;
  if (field == ATTR_SET_AUTO_JUMP ) return "Auto-jump: " + on_off;
  if (field == ATTR_SET_SHOW_HUD  ) return "Show HUD: " + on_off;
  if (field == ATTR_SET_SHOW_DEBUG) return "Show position and frame statistics: " + on_off;
  return field;
}

Text settings_line(Text name, Integer value)
// ----------------------------------------------------------------
// "name value", one line of the settings file
// ----------------------------------------------------------------
{
  return name + " " + To_text(value);
}

Integer settings_save(Attributes &settings, Text path)
// ----------------------------------------------------------------
// Write the settings as "name value" lines. Returns SUCCESS or
// FAILURE.
// ----------------------------------------------------------------
{
  File file;

  if (File_open(path, "w", "", file) != 0) return FAILURE;

  File_write_line(file, settings_line(ATTR_SET_RENDER_DISTANCE, settings_render_distance(settings)));
  File_write_line(file, settings_line(ATTR_SET_DETAIL, settings_detail(settings)));
  File_write_line(file, settings_line(ATTR_SET_PLANTS, settings_flag(settings, ATTR_SET_PLANTS)));
  File_write_line(file, settings_line(ATTR_SET_SHADING, settings_flag(settings, ATTR_SET_SHADING)));
  File_write_line(file, settings_line(ATTR_SET_AUTO_JUMP, settings_flag(settings, ATTR_SET_AUTO_JUMP)));
  File_write_line(file, settings_line(ATTR_SET_FOV, settings_fov_degrees(settings)));
  File_write_line(file, settings_line(ATTR_SET_SENSITIVITY, record_integer(settings, ATTR_SET_SENSITIVITY)));
  File_write_line(file, settings_line(ATTR_SET_SHOW_HUD, settings_flag(settings, ATTR_SET_SHOW_HUD)));
  File_write_line(file, settings_line(ATTR_SET_SHOW_DEBUG, settings_flag(settings, ATTR_SET_SHOW_DEBUG)));

  File_close(file);
  return SUCCESS;
}

Integer settings_load(Attributes &settings, Text path)
// ----------------------------------------------------------------
// Start from the defaults and apply any "name value" lines found in
// the file. Unknown names are ignored. Returns SUCCESS, or FAILURE
// if there is no file (the defaults are kept).
// ----------------------------------------------------------------
{
  File         file;
  Text         line  = "";
  Text         name  = "";
  Text         word  = "";
  Integer      value = 0;
  Integer      count = 0;
  Dynamic_Text words;

  settings_defaults(settings);
  if (!File_exists(path)) return FAILURE;
  if (File_open(path, "r", "", file) != 0) return FAILURE;

  while (File_read_line(file, line) == 0) {
    Null(words);
    count = From_text(line, words);
    if (count < 2) continue;
    Get_item(words, 1, name);
    Get_item(words, 2, word);
    if (From_text(word, value) != 0) continue;
    if (name == ATTR_SET_RENDER_DISTANCE || name == ATTR_SET_DETAIL    || name == ATTR_SET_PLANTS   ||
        name == ATTR_SET_SHADING         || name == ATTR_SET_AUTO_JUMP || name == ATTR_SET_FOV      ||
        name == ATTR_SET_SENSITIVITY     || name == ATTR_SET_SHOW_HUD  || name == ATTR_SET_SHOW_DEBUG) {
      record_set_integer(settings, name, value);
    }
  }

  File_close(file);
  return SUCCESS;
}

#endif
