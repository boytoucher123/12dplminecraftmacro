#ifndef UTIL_4DM_INCLUDED
#define UTIL_4DM_INCLUDED

#include "../include/common.h"
#include "../include/util.h"

Real clamp_real(Real value, Real low, Real high)
// ----------------------------------------------------------------
// Limit value to the range [low, high]
// ----------------------------------------------------------------
{
  Real result = value;

  if (result < low ) result = low;
  if (result > high) result = high;

  return result;
}

Integer clamp_integer(Integer value, Integer low, Integer high)
// ----------------------------------------------------------------
// Limit value to the range [low, high]
// ----------------------------------------------------------------
{
  Integer result = value;

  if (result < low ) result = low;
  if (result > high) result = high;

  return result;
}

Real min_real(Real first, Real second)
// ----------------------------------------------------------------
// The smaller of two values
// ----------------------------------------------------------------
{
  if (first < second) return first;
  return second;
}

Real max_real(Real first, Real second)
// ----------------------------------------------------------------
// The larger of two values
// ----------------------------------------------------------------
{
  if (first > second) return first;
  return second;
}

Integer floor_integer(Real value)
// ----------------------------------------------------------------
// Round towards negative infinity and return as an Integer
// ----------------------------------------------------------------
{
  Integer result = Floor(value);
  return result;
}

Integer floor_divide(Integer numerator, Integer denominator)
// ----------------------------------------------------------------
// Integer division rounding towards negative infinity
// Done in Reals so the result never depends on how the language
// rounds negative Integer division
// ----------------------------------------------------------------
{
  Integer result = Floor(numerator / (1.0 * denominator));
  return result;
}

Integer positive_mod(Integer value, Integer modulus)
// ----------------------------------------------------------------
// value modulo modulus, always in the range [0, modulus - 1]
// ----------------------------------------------------------------
{
  Integer result = value - floor_divide(value, modulus) * modulus;
  return result;
}

Integer to_byte(Real value)
// ----------------------------------------------------------------
// Convert a colour channel to an Integer in [0, 255]
// ----------------------------------------------------------------
{
  Integer result = Floor(clamp_real(value, 0.0, 255.0));
  return result;
}

Real lerp_real(Real from, Real to, Real amount)
// ----------------------------------------------------------------
// Linear interpolation, amount 0 gives from and 1 gives to
// ----------------------------------------------------------------
{
  return from + (to - from) * amount;
}

Real smooth_curve(Real amount)
// ----------------------------------------------------------------
// Smoothstep easing of amount in [0, 1]
// ----------------------------------------------------------------
{
  return amount * amount * (3.0 - 2.0 * amount);
}

Real hash_real(Real first, Real second, Real third)
// ----------------------------------------------------------------
// Deterministic pseudo random number in [0, 1) from three values
// Used by terrain and texture generation so that a seed always
// produces the same result regardless of call order
// ----------------------------------------------------------------
{
  Real value = Sin(first * 127.1 + second * 311.7 + third * 74.7) * 43758.5453123;
  return value - Floor(value);
}

Real random_real()
// ----------------------------------------------------------------
// Random number in [0, 1] from the 12d random number generator
// Set_random_number(seed, 1) must have been called first
// ----------------------------------------------------------------
{
  Real value = Get_random_number_closed();
  return value;
}

Integer random_integer(Integer low, Integer high)
// ----------------------------------------------------------------
// Random Integer in [low, high]
// ----------------------------------------------------------------
{
  Integer value = low + Floor(random_real() * (high - low + 1));

  if (value > high) value = high;

  return value;
}

Real wrap_angle(Real angle)
// ----------------------------------------------------------------
// Bring an angle into the range [0, 2 pi)
// ----------------------------------------------------------------
{
  return angle - Floor(angle / TWO_PI) * TWO_PI;
}

Integer text_to_seed(Text text)
// ----------------------------------------------------------------
// Turn the seed typed by the player into an Integer seed
// Whole numbers (optionally negative) are used as they are, any
// other text is hashed so that words make repeatable worlds too
// ----------------------------------------------------------------
{
  Text    trimmed    = Text_justify(text);
  Text    digits     = "0123456789";
  Text    charset    = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_.,!?:;()+=*/@#$%&";
  Text    character  = "";
  Integer length     = Text_length(trimmed);
  Integer position   = 0;
  Integer digit      = 0;
  Integer is_number  = TRUE;
  Integer negative   = FALSE;
  Integer start      = 1;
  Integer seed       = 0;
  Real    accumulate = 0.0;

  if (length == 0) return 0;

  if (Get_subtext(trimmed, 1, 1) == "-") {
    negative = TRUE;
    start    = 2;
  }
  if (start > length) is_number = FALSE;
  if (length - start + 1 > 9) is_number = FALSE;

  for (position = start; position <= length; ++position) {
    character = Get_subtext(trimmed, position, position);
    if (Find_text(digits, character) == 0) is_number = FALSE;
  }

  if (is_number) {
    for (position = start; position <= length; ++position) {
      character = Get_subtext(trimmed, position, position);
      digit     = Find_text(digits, character) - 1;
      seed      = seed * 10 + digit;
    }
    if (negative) seed = -seed;
    return seed;
  }

  for (position = 1; position <= length; ++position) {
    character  = Get_subtext(trimmed, position, position);
    accumulate = accumulate * 31.0 + Find_text(charset, character) + 1.0;
    accumulate = accumulate - Floor(accumulate / 2147483.0) * 2147483.0;
  }
  seed = Floor(accumulate);

  return seed;
}

Text file_title_from_path(Text path)
// ----------------------------------------------------------------
// "C:\folder\name.ext" -> "name"
// Accepts either slash style
// ----------------------------------------------------------------
{
  Integer length    = Text_length(path);
  Integer position  = 0;
  Integer first     = 1;
  Integer last      = length;
  Text    character = "";

  for (position = 1; position <= length; ++position) {
    character = Get_subtext(path, position, position);
    if (character == "/" || character == "\\") first = position + 1;
  }
  for (position = length; position >= first; --position) {
    character = Get_subtext(path, position, position);
    if (character == ".") {
      last = position - 1;
      break;
    }
  }

  if (last < first) return "";

  return Get_subtext(path, first, last);
}

Integer text_is_safe_name(Text name)
// ----------------------------------------------------------------
// TRUE if name only uses letters, digits, spaces, - and _
// so that it can be used as a file name
// ----------------------------------------------------------------
{
  Text    allowed   = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 -_";
  Text    character = "";
  Integer length    = Text_length(name);
  Integer position  = 0;

  if (length == 0 || length > 40) return FALSE;

  for (position = 1; position <= length; ++position) {
    character = Get_subtext(name, position, position);
    if (Find_text(allowed, character) == 0) return FALSE;
  }

  return TRUE;
}

#endif
