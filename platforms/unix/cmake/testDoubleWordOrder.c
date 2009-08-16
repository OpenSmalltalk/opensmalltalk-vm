union { double d; int i[2]; } d;

int main(void)
{
  d.d= 1.0;
  return d.i[0] == 0;
}
