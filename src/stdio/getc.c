#include "../internal/internal.h"
int getc(FILE *fp)
{
	if (fp->len)
		fp->len--;
	if (((fp)->len > 0)) {
		return (unsigned char)*(fp)->rp++;
	}

	return _fillbuf(fp);
}
