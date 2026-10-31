#ifndef EVENTS_4DM_INCLUDED
#define EVENTS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/events.h"

void events_clear()
// ----------------------------------------------------------------
// Drop every queued event
// ----------------------------------------------------------------
{
  g_event_head  = 1;
  g_event_count = 0;
  g_ev_type     = EVT_NONE;
}

void emit_event(Integer type, Integer i1, Integer i2, Integer i3, Integer i4, Real r1, Real r2, Real r3, Text text)
// ----------------------------------------------------------------
// Add an event to the end of the queue
// The queue is a ring buffer; if it is full the event is dropped
// and counted in g_event_lost
// ----------------------------------------------------------------
{
  Integer slot = 0;

  if (g_event_count >= EVENT_QUEUE_SIZE) {
    ++g_event_lost;
    return;
  }

  slot = g_event_head + g_event_count;
  if (slot > EVENT_QUEUE_SIZE) slot = slot - EVENT_QUEUE_SIZE;

  g_event_type[slot] = type;
  g_event_i1  [slot] = i1;
  g_event_i2  [slot] = i2;
  g_event_i3  [slot] = i3;
  g_event_i4  [slot] = i4;
  g_event_r1  [slot] = r1;
  g_event_r2  [slot] = r2;
  g_event_r3  [slot] = r3;
  g_event_text[slot] = text;

  ++g_event_count;
}

void emit_simple_event(Integer type)
// ----------------------------------------------------------------
// Event with no payload
// ----------------------------------------------------------------
{
  emit_event(type, 0, 0, 0, 0, 0.0, 0.0, 0.0, "");
}

void emit_cell_event(Integer type, Integer x, Integer y, Integer z, Integer block)
// ----------------------------------------------------------------
// Event about a block cell
// ----------------------------------------------------------------
{
  emit_event(type, x, y, z, block, 0.0, 0.0, 0.0, "");
}

void emit_item_event(Integer type, Integer item, Integer count)
// ----------------------------------------------------------------
// Event about an item stack
// ----------------------------------------------------------------
{
  emit_event(type, item, count, 0, 0, 0.0, 0.0, 0.0, "");
}

void emit_drop_event(Integer item, Integer count, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Ask for an item stack to be dropped into the world at (x, y, z)
// ----------------------------------------------------------------
{
  emit_event(EVT_SPAWN_DROP, item, count, 0, 0, x, y, z, "");
}

void emit_toast(Text text)
// ----------------------------------------------------------------
// Ask the HUD to show a short message
// ----------------------------------------------------------------
{
  emit_event(EVT_TOAST, 0, 0, 0, 0, 0.0, 0.0, 0.0, text);
}

Integer next_event()
// ----------------------------------------------------------------
// Take the oldest event off the queue into the g_ev_* globals
// Returns TRUE if there was one, FALSE if the queue was empty
// ----------------------------------------------------------------
{
  if (g_event_count <= 0) {
    g_ev_type = EVT_NONE;
    return FALSE;
  }

  g_ev_type = g_event_type[g_event_head];
  g_ev_i1   = g_event_i1  [g_event_head];
  g_ev_i2   = g_event_i2  [g_event_head];
  g_ev_i3   = g_event_i3  [g_event_head];
  g_ev_i4   = g_event_i4  [g_event_head];
  g_ev_r1   = g_event_r1  [g_event_head];
  g_ev_r2   = g_event_r2  [g_event_head];
  g_ev_r3   = g_event_r3  [g_event_head];
  g_ev_text = g_event_text[g_event_head];

  ++g_event_head;
  if (g_event_head > EVENT_QUEUE_SIZE) g_event_head = 1;
  --g_event_count;

  return TRUE;
}

#endif
