int sequence(int i)
{
  if(i==0||i==1)
  {
    return 1;
  }
  else
  {
    return sequence(i-1)+sequence(i-2);
  }
}

int main(void)
{
  unsigned int *p=(unsigned int *)0x1;
  int i;
  for(i=0;i<10;i++)
  {
    p[i]=sequence(i)*1.5;
  }
  return 0;
}
