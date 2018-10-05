#include <sys/stat.h>
#include <fcntl.h>
#include "syscall.h"

int mknod(const char *path, mode_t mode, dev_t dev)
{
#ifdef	SYS_mknod
	return syscall(SYS_mknod, path, mode, dev & 0xffff);
#else
// Try to make FreeBSD build
#ifdef SYS_mknodat
	return syscall(SYS_mknodat, AT_FDCWD, path, mode, dev & 0xffff);
#endif
#endif
}
