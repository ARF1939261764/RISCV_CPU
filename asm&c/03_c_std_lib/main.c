#include "stdio.h"
#include "time.h"
#include "sys/times.h"
#include "sys/stat.h"
#include "sys/types.h"
#include "DSP.h"

int main(void)
{
	printf("hello world:%d",123456);
	return 0;
}
int _system (const char *i)
{

}
int _rename (const char *i, const char *j)
{

}
int _isatty (int i)
{

}
clock_t _times (struct tms *i)
{

}
int _gettimeofday (struct timeval *i, void *j)
{

}
int _unlink (const char *i)
{

}
int _link (void)
{

}
int _stat (const char *i, struct stat *j)
{

}
int _fstat (int j, struct stat *i)
{

}
int _swistat (int fd, struct stat * st)
{

}
caddr_t _sbrk (int i)
{

}
int _getpid (int i)
{

}
int _close (int i)
{

}
clock_t _clock (void)
{

}
int _swiclose (int i)
{

}
int _open (const char *i, int j, ...)
{

}
int _swiopen (const char *i, int j)
{

}
int _write (int id, char *buff, int n)
{
	static char *p=(char *)0x100000;
	int i;
	for(i=0;i<n;i++)
	{
		*p++=buff[i];
	}
}
int _swiwrite (int k, char *i, int j)
{

}
int _lseek (int i, int j, int k)
{

}
int _swilseek (int i, int j, int k)
{

}
int _read (int i, char *j, int k)
{

}
int _swiread (int i, char *j, int k)
{

}
