#ifndef EVENTS_4DM_INCLUDED
#define EVENTS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/records.h"
#include "../include/events.h"

void events_clear(Attributes &events)
// ----------------------------------------------------------------
// Empty the queue
// ----------------------------------------------------------------
{
  record_clear      (events, DATATYPE_EVENT_QUEUE);
  record_set_integer(events, ATTR_EVENT_HEAD, 1);
  record_set_integer(events, ATTR_COUNT,      0);
  record_set_integer(events, ATTR_EVENT_LOST, 0);
}

void emit_event(Attributes &events, Integer type, Integer i1, Integer i2, Integer i3, Integer i4, Real r1, Real r2, Real r3, Text text)
// ----------------------------------------------------------------
// Add an event to the end of the queue
// The queue is a ring of EVENT_QUEUE_SIZE entries; if it is full
// the event is dropped and counted in the "lost" field
// ----------------------------------------------------------------
{
  Integer head  = record_integer(events, ATTR_EVENT_HEAD);
  Integer count = record_integer(events, ATTR_COUNT);
  Integer slot  = 0;

  if (count >= EVENT_QUEUE_SIZE) {
    record_set_integer(events, ATTR_EVENT_LOST, record_integer(events, ATTR_EVENT_LOST) + 1);
    return;
  }
  if (head < 1) head = 1;

  slot = head + count;
  if (slot > EVENT_QUEUE_SIZE) slot = slot - EVENT_QUEUE_SIZE;

  record_set_integer_at(events, ATTR_TYPE,     slot, type);
  record_set_integer_at(events, ATTR_EVENT_I1, slot, i1);
  record_set_integer_at(events, ATTR_EVENT_I2, slot, i2);
  record_set_integer_at(events, ATTR_EVENT_I3, slot, i3);
  record_set_integer_at(events, ATTR_EVENT_I4, slot, i4);
  record_set_real_at   (events, ATTR_EVENT_R1, slot, r1);
  record_set_real_at   (events, ATTR_EVENT_R2, slot, r2);
  record_set_real_at   (events, ATTR_EVENT_R3, slot, r3);
  record_set_text_at   (events, ATTR_TEXT,     slot, text);

  record_set_integer(events, ATTR_EVENT_HEAD, head);
  record_set_integer(events, ATTR_COUNT,      count + 1);
}

void emit_simple_event(Attributes &events, Integer type)
// ----------------------------------------------------------------
// Event with no payload
// ----------------------------------------------------------------
{
  emit_event(events, type, 0, 0, 0, 0, 0.0, 0.0, 0.0, "");
}

void emit_cell_event(Attributes &events, Integer type, Integer x, Integer y, Integer z, Integer block)
// ----------------------------------------------------------------
// Event about a block cell
// ----------------------------------------------------------------
{
  emit_event(events, type, x, y, z, block, 0.0, 0.0, 0.0, "");
}

void emit_item_event(Attributes &events, Integer type, Integer item, Integer count)
// ----------------------------------------------------------------
// Event about an item stack
// ----------------------------------------------------------------
{
  emit_event(events, type, item, count, 0, 0, 0.0, 0.0, 0.0, "");
}

void emit_drop_event(Attributes &events, Integer item, Integer count, Integer damage, Real x, Real y, Real z)
// ----------------------------------------------------------------
// Ask for an item stack to be dropped into the world at (x, y, z)
// damage is the wear of a tool (0 for other items)
// ----------------------------------------------------------------
{
  emit_event(events, EVT_SPAWN_DROP, item, count, damage, 0, x, y, z, "");
}

void emit_toast(Attributes &events, Text text)
// ----------------------------------------------------------------
// Ask the HUD to show a short message
// ----------------------------------------------------------------
{
  emit_event(events, EVT_TOAST, 0, 0, 0, 0, 0.0, 0.0, 0.0, text);
}

Integer events_pending(Attributes &events)
// ----------------------------------------------------------------
// Number of events waiting in the queue
// ----------------------------------------------------------------
{
  return record_integer(events, ATTR_COUNT);
}

Integer next_event(Attributes &events, Attributes &event)
// ----------------------------------------------------------------
// Move the oldest event off the queue into the event record
// Returns TRUE if there was one, FALSE if the queue was empty
// ----------------------------------------------------------------
{
  Integer head  = record_integer(events, ATTR_EVENT_HEAD);
  Integer count = record_integer(events, ATTR_COUNT);

  record_clear(event, DATATYPE_EVENT);
  if (count <= 0) {
    record_set_integer(event, ATTR_TYPE, EVT_NONE);
    return FALSE;
  }

  record_set_integer(event, ATTR_TYPE,     record_integer_at(events, ATTR_TYPE,     head));
  record_set_integer(event, ATTR_EVENT_I1, record_integer_at(events, ATTR_EVENT_I1, head));
  record_set_integer(event, ATTR_EVENT_I2, record_integer_at(events, ATTR_EVENT_I2, head));
  record_set_integer(event, ATTR_EVENT_I3, record_integer_at(events, ATTR_EVENT_I3, head));
  record_set_integer(event, ATTR_EVENT_I4, record_integer_at(events, ATTR_EVENT_I4, head));
  record_set_real   (event, ATTR_EVENT_R1, record_real_at   (events, ATTR_EVENT_R1, head));
  record_set_real   (event, ATTR_EVENT_R2, record_real_at   (events, ATTR_EVENT_R2, head));
  record_set_real   (event, ATTR_EVENT_R3, record_real_at   (events, ATTR_EVENT_R3, head));
  record_set_text   (event, ATTR_TEXT,     record_text_at   (events, ATTR_TEXT,     head));

  ++head;
  if (head > EVENT_QUEUE_SIZE) head = 1;
  record_set_integer(events, ATTR_EVENT_HEAD, head);
  record_set_integer(events, ATTR_COUNT,      count - 1);

  return TRUE;
}

Integer event_type(Attributes &event)
// ----------------------------------------------------------------
// EVT_* type of an event record
// ----------------------------------------------------------------
{
  return record_integer(event, ATTR_TYPE);
}

Integer event_integer(Attributes &event, Integer which)
// ----------------------------------------------------------------
// Integer payload number which (1..4) of an event record
// ----------------------------------------------------------------
{
  if (which == 1) return record_integer(event, ATTR_EVENT_I1);
  if (which == 2) return record_integer(event, ATTR_EVENT_I2);
  if (which == 3) return record_integer(event, ATTR_EVENT_I3);
  return record_integer(event, ATTR_EVENT_I4);
}

Real event_real(Attributes &event, Integer which)
// ----------------------------------------------------------------
// Real payload number which (1..3) of an event record
// ----------------------------------------------------------------
{
  if (which == 1) return record_real(event, ATTR_EVENT_R1);
  if (which == 2) return record_real(event, ATTR_EVENT_R2);
  return record_real(event, ATTR_EVENT_R3);
}

Text event_text(Attributes &event)
// ----------------------------------------------------------------
// Text payload of an event record
// ----------------------------------------------------------------
{
  return record_text(event, ATTR_TEXT);
}

#endif
