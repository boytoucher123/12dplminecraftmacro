#ifndef UTIL_H_INCLUDED
#define UTIL_H_INCLUDED

// ----------------------------------------------------------------
// Small maths, random number and text helpers
// ----------------------------------------------------------------

Real    clamp_real          (Real value, Real low, Real high);
Integer clamp_integer       (Integer value, Integer low, Integer high);
Real    min_real            (Real first, Real second);
Real    max_real            (Real first, Real second);
Integer floor_integer       (Real value);
Integer floor_divide        (Integer numerator, Integer denominator);
Integer positive_mod        (Integer value, Integer modulus);
Integer to_byte             (Real value);
Real    lerp_real           (Real from, Real to, Real amount);
Real    smooth_curve        (Real amount);
Real    hash_real           (Real first, Real second, Real third);
Real    random_real         ();
Integer random_integer      (Integer low, Integer high);
Real    wrap_angle          (Real angle);
Integer text_to_seed        (Text text);
Text    file_title_from_path(Text path);
Integer text_is_safe_name   (Text name);

#endif
