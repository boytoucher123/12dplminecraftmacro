#ifndef RECORDS_4DM_INCLUDED
#define RECORDS_4DM_INCLUDED

#include "../include/common.h"
#include "../include/records.h"

// ---------------------------------------------------------------- field access

Integer record_integer(Attributes &record, Text field)
// ----------------------------------------------------------------
// Integer field of a record, 0 if the record doesn't have it
// ----------------------------------------------------------------
{
  Integer value = 0;

  if (Get_attribute(record, field, value) != 0) value = 0;

  return value;
}

Real record_real(Attributes &record, Text field)
// ----------------------------------------------------------------
// Real field of a record, 0.0 if the record doesn't have it
// ----------------------------------------------------------------
{
  Real value = 0.0;

  if (Get_attribute(record, field, value) != 0) value = 0.0;

  return value;
}

Text record_text(Attributes &record, Text field)
// ----------------------------------------------------------------
// Text field of a record, "" if the record doesn't have it
// ----------------------------------------------------------------
{
  Text value = "";

  if (Get_attribute(record, field, value) != 0) value = "";

  return value;
}

void record_set_integer(Attributes &record, Text field, Integer value)
// ----------------------------------------------------------------
// Set (creating if needed) an Integer field
// A field keeps the type it was created with, so always write a
// field with the same setter
// ----------------------------------------------------------------
{
  Set_attribute(record, field, value);
}

void record_set_real(Attributes &record, Text field, Real value)
// ----------------------------------------------------------------
// Set (creating if needed) a Real field
// ----------------------------------------------------------------
{
  Set_attribute(record, field, value);
}

void record_set_text(Attributes &record, Text field, Text value)
// ----------------------------------------------------------------
// Set (creating if needed) a Text field
// ----------------------------------------------------------------
{
  Set_attribute(record, field, value);
}

void record_clear(Attributes &record, Text datatype)
// ----------------------------------------------------------------
// Remove every field and stamp the record with its datatype, so a
// dump of the record says what it is
// ----------------------------------------------------------------
{
  Attribute_delete_all(record);
  Set_attribute(record, ATTR_DATATYPE, datatype);
}

Text record_datatype(Attributes &record)
// ----------------------------------------------------------------
// The datatype a record was stamped with by record_clear
// ----------------------------------------------------------------
{
  return record_text(record, ATTR_DATATYPE);
}

// ---------------------------------------------------------------- collections

Text record_field_at(Text field, Integer index)
// ----------------------------------------------------------------
// Name of field of entity number index: ("x", 3) -> "x_3"
// ----------------------------------------------------------------
{
  return field + "_" + To_text(index);
}

Integer record_integer_at(Attributes &record, Text field, Integer index)
// ----------------------------------------------------------------
// Integer field of entity number index
// ----------------------------------------------------------------
{
  return record_integer(record, record_field_at(field, index));
}

Real record_real_at(Attributes &record, Text field, Integer index)
// ----------------------------------------------------------------
// Real field of entity number index
// ----------------------------------------------------------------
{
  return record_real(record, record_field_at(field, index));
}

Text record_text_at(Attributes &record, Text field, Integer index)
// ----------------------------------------------------------------
// Text field of entity number index
// ----------------------------------------------------------------
{
  return record_text(record, record_field_at(field, index));
}

void record_set_integer_at(Attributes &record, Text field, Integer index, Integer value)
// ----------------------------------------------------------------
// Set an Integer field of entity number index
// ----------------------------------------------------------------
{
  record_set_integer(record, record_field_at(field, index), value);
}

void record_set_real_at(Attributes &record, Text field, Integer index, Real value)
// ----------------------------------------------------------------
// Set a Real field of entity number index
// ----------------------------------------------------------------
{
  record_set_real(record, record_field_at(field, index), value);
}

void record_set_text_at(Attributes &record, Text field, Integer index, Text value)
// ----------------------------------------------------------------
// Set a Text field of entity number index
// ----------------------------------------------------------------
{
  record_set_text(record, record_field_at(field, index), value);
}

// ---------------------------------------------------------------- random numbers

void random_seed(Attributes &random, Integer seed)
// ----------------------------------------------------------------
// Start a random sequence. The same seed gives the same sequence.
// ----------------------------------------------------------------
{
  Real state = Absolute(seed * 1.0);

  state = state - Floor(state / (RANDOM_MODULUS - 1.0)) * (RANDOM_MODULUS - 1.0) + 1.0;

  record_clear   (random, DATATYPE_RANDOM);
  record_set_real(random, ATTR_RANDOM_STATE, state);
}

Real random_next(Attributes &random)
// ----------------------------------------------------------------
// Next number in [0, 1) of the sequence (Park-Miller generator;
// every product fits exactly in a Real)
// ----------------------------------------------------------------
{
  Real state = record_real(random, ATTR_RANDOM_STATE);

  if (state < 1.0) state = 1.0;
  state = state * RANDOM_MULTIPLIER;
  state = state - Floor(state / RANDOM_MODULUS) * RANDOM_MODULUS;
  record_set_real(random, ATTR_RANDOM_STATE, state);

  return (state - 1.0) / (RANDOM_MODULUS - 1.0);
}

Integer random_range(Attributes &random, Integer low, Integer high)
// ----------------------------------------------------------------
// Random Integer in [low, high]
// ----------------------------------------------------------------
{
  Integer value = low + Floor(random_next(random) * (high - low + 1));

  if (value > high) value = high;

  return value;
}

Real random_between(Attributes &random, Real low, Real high)
// ----------------------------------------------------------------
// Random Real in [low, high)
// ----------------------------------------------------------------
{
  return low + random_next(random) * (high - low);
}

#endif
