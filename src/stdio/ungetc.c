#include "../internal/internal.h"

int ungetc(int c, FILE *fp)
{
	if (c == EOF)
		return c;
	*fp->rp-- = (char)c;
	return c;
}

