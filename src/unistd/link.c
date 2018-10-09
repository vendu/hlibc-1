#include <sys/syscall.h>
#include <unistd.h>
int link(const char *existing, const char *new)
{
#ifdef  SYS_link
	return __syscall(SYS_link, existing, new);
#else
	return __syscall(SYS_linkat, AT_FDCWD, existing, new);
#endif
}
