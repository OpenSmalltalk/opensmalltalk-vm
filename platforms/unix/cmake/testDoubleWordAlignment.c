int f(void *i)
{
  *(double *)i= *(double *)(i + 4);
  return *(char *)i;
}

int main()
{
  char b[12];
  b[0]=1; b[1]=2; b[2]=3; b[3]=4; b[4]=0; b[5]=0; b[6]=0; b[7]=0; b[8]=0; b[9]=0; b[10]=0; b[11]=0;
  return f(b);
}
