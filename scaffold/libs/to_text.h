#ifndef to_text_h_included
#define to_text_h_included

Text to_text(Text text)
{
  return text;
}

Text to_text(void)
{
  return "void";
}

Text to_text(Real real)
{
  return To_text(real, 3);
}

Text to_text(Menu menu)
{
  return "menu";
}

Text to_text(Integer integer)
{
  return To_text(integer);
}

#endif