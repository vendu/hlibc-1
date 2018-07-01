#include "internal.h"
#include <limits.h>

/* new API */

int __safe_uadd(uintmax_t a, uintmax_t b, uintmax_t *c, uintmax_t lim);
int __safe_usub(uintmax_t a, uintmax_t b, uintmax_t *c);
int __safe_sub(intmax_t a, intmax_t b, intmax_t *c)
{
	/*
		(-a - -b)
		-500 - -500 == 0
		A negative minus a negative will always fit
		as it always seeks to transform toward the negative 
		operand toward and over 0
	*/
	if(a < 0 && b < 0 ) {
		*c = a - b;
		return 0;
	}

	/*
		(-a - b)
		-500 - +250 == -750
		SIZE_MIN = 1000
		-1000 - -500 == -500
		flip -250
		-500 < -250 so it fits 
		A negative minus a positive needs the positive flipped
		and if the positive as a negative is less than the result
		of the minimum minus the left operand then it fits
	*/
	if (a < 0 && b > 0) {
		if ((INTMAX_MIN - a) <= -b)
		{
			*c = a - b;
			return 0;
		}
		return -1;
	}

	/*
		(a + b)
		a and b are positive so subtractions will always fit
	*/
	if (a > 0 && b > 0) {
		*c = a - b;
		return 0;
		
	}
	
	/*
		(a - -b)
		a is positive and b is negative so subtractions have the properties 
		of addition and can use the unsigned variant
	*/
	if (a > 0 && b < 0) {
		return __safe_uadd(a, b, c, INTMAX_MAX);
	}
		
	return -1;
}
int __safe_add(intmax_t a, intmax_t b, intmax_t *c)
{
	/*
		(a + b)
		this is the conventional case so call out to the unsigned API
	*/
	if (a > 0 && b > 0)
		return __safe_uadd(a, b, c, INTMAX_MAX); 
		
	/*
		(-a + -b)
		-100 + -100 == -200
		this will cause overflow and needs a check!

		-500 + -250 and lim is -1000
		-1000  - - 500 == -500
		-500 < - 250 ... so it fits
		else it is an overflow
	*/
	if (a < 0 && b < 0) {
		if (INTMAX_MIN - a < b ) {
			*c = a + b;
			return 0;
		}
		return -1;
	}

	/*
		(a + -b)
		100 + -900 == -800
		this should always fit as long as -b is *valid*
	*/
	/*
		(-a + b)
		-100 + 1000 == 900
		a negative plus a postive will always fit 
	*/
	*c = a + b;
	return 0;
}

int __safe_div(intmax_t a, intmax_t b, intmax_t *c)
{
	if(b != 0 && b != INTMAX_MIN)
	{
		*c = a / b;
		return 0;
	}
	return -1;
}

int __safe_mul(intmax_t a, intmax_t b, intmax_t *c)
{
	if(1)
	{
		*c = a * b;
		return 0;
	}
	return -1;
}

int __safe_usub(uintmax_t a, uintmax_t b, uintmax_t *c)
{
	if(a >= b) {
		*c = a - b;
		return 0;
	}
	return -1;
}

int __safe_uadd(uintmax_t a, uintmax_t b, uintmax_t *c, uintmax_t lim)
{
	size_t tmp = 0;
	if (__safe_usub(lim, a, &tmp) == -1)
		return -1;
	else if(tmp >= b) {
		*c = a + b;
		return 0;
	}
	return -1;
}

int __safe_udiv(uintmax_t a, uintmax_t b, uintmax_t *c)
{
	if(b != 0)
	{
		*c = a / b;
		return 0;
	}
	return -1;
}

int __safe_umul(uintmax_t a, uintmax_t b, uintmax_t *c, uintmax_t lim)
{
	if(a == 0 || lim / a >= b)
	{
		*c = a * b;
		return 0;
	}
	return -1;
}

/* old API */
size_t _safe_subtraction(size_t a, size_t b)
{
	if (a >= b)
		return a - b;
	return 0;
}

size_t _safe_addition(size_t a, size_t b, size_t lim)
{
	if (lim - a >= b)
		return a + b;
	return 0;
}

size_t _safe_division(size_t i, size_t x)
{
	if (x == 0) {
		return i; // divide by zero, return original number
	} else if ( i < x ) {
		return 0; // division will go past zero, return 0
	}
	return i / x; // division fits, perform it
}

size_t _safe_multiply(size_t i, size_t x, size_t lim)
{
	size_t tmp = _safe_division(lim, i);
	if (tmp >= x) { // Division was greater than or equal to x so
		return i * x; // so perform the multiplication.
	}
	else if (tmp == 0) { // The (uinteger) division won't fit so 0 was returned
		return lim; // therefore return the maximum saturation
		//return 0; // therefore return 0 as in multiplication by zero.
	}
	return lim; // return the maximum saturation
}

size_t _safe_upow(size_t i, size_t j)
{
	size_t t = 1;
	while (j--)
		t += _safe_multiply(t, i, ((size_t)-1));
	return t;
}

