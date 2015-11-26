#include <stdio.h>
#include <stdint.h>
#include "float.h"
#include "fmul.h"

typedef union exponential
{
	struct
	{
		uint32_t base: 8;
		uint32_t uf: 1;
		uint32_t of: 1;
		uint32_t none: 22;
	};
	uint32_t ui;
} exponential;

uint32_t fmul (uint32_t _a, uint32_t _b)
{
	uint64_t tmp;
	int inf, zero, a_nan, b_nan, a_deno, b_deno;
	int a_deno_count, b_deno_count;
	int a_inf, b_inf, a_zero, b_zero;
	f32_uint a, b, c, hh, hl, lh, c_frac, a_hi, b_hi;
	exponential c_expo;

	a.ui = _a;
	b.ui = _b;

	a_nan  = (a.expo == (1<<8)-1) && (a.frac != 0);
	a_inf  = (a.expo == (1<<8)-1) && (a.frac == 0);

	a_zero = (a.expo == 0) && (a.frac == 0);
	a_deno = (a.expo == 0) && (a.frac != 0);

	b_nan  = (b.expo == (1<< 8)-1) && (b.frac != 0);
	b_inf  = (b.expo == (1<< 8)-1) && (b.frac == 0);
	b_zero = (b.expo == 0) && (b.frac == 0);
	b_deno = (b.expo == 0) && (b.frac != 0);

	inf  = a_inf  || b_inf;
	zero = a_zero || b_zero;

	c.sign = a.sign ^ b.sign;
	c_expo.ui = a.expo + b.expo + ((1<<7) + 1);

	a_hi.ui = (a_deno ? a.mhi : (a.mhi|IMPL1));
	b_hi.ui = (b_deno ? b.mhi : (b.mhi|IMPL1));

	a_hi.ui = a.mhi | IMPL1;
	b_hi.ui = b.mhi | IMPL1;

	hh.ui = a_hi.ui * b_hi.ui;
	hl.ui = a_hi.ui * b.mlo;
	lh.ui = a.mlo * b_hi.ui;
	c_frac.ui = (hh.ui<<1) + 1 + (hl.ui>>10) + (lh.ui>>10);

	if (a_deno || b_deno)
	{
		int i;
		for (i=26; i>0; i--)
		{

			if (c_frac.ui>>i)
			{
				c_expo.ui += (i-26);
				if (i>23)
				{
					c_frac.ui += c_frac.ui & (1<<(i-24));
					c_frac.ui >>= (i-23);
				} else
				if (i!=23)
				{
					c_frac.ui <<= (23-i);
					c_frac.ui += 1<<(22-i);
				}
				break;
			}
		}
	} else
	{
		if (c_frac.q26)
		{
			c_expo.ui += 1;
			c_frac.ui += c_frac.q02<<2;
			c_frac.ui >>= 3;
		} else
		{
			c_expo.ui += 0;
			c_frac.ui += c_frac.q01<<1;
			c_frac.ui >>= 2;
		}
	}

	if (b_nan)
	{
		c.sign = b.sign;
		c.expo = (1<<8)-1;
		c.frac = (1<<22) | b.frac;
	} else
	if (a_nan)
	{
		c.sign = a.sign;
		c.expo = (1<<8)-1;
		c.frac = (1<<22) | a.frac;
	} else
	// if ((a_inf || b_inf) && (a_zero || b_zero))
	// {
	// 	c.sign = c.sign;
	// 	c.expo = (1<<8)-1;
	// 	c.frac = (1<<22);
	// } else
	if (a_inf || b_inf)
	{
		c.sign = c.sign;
		c.expo = (1<<8)-1;
		c.frac = 0;
	} else
	// if (a_zero || b_zero)
	// {
	// 	c.sign = c.sign;
	// 	c.expo = 0;
	// 	c.frac = 0;
	// } else
	if (c_expo.of || (c_expo.uf &(c_expo.base==(1<<8)-1))) //overflow := 1x,xxxx,xxxx
	{
		c.sign = c.sign;
		c.expo = (1<<8)-1;
		c.frac = 0;
	} else
	if (!c_expo.uf || !c_expo.base) //underflow := 00,xxxx,xxxx or 01,0000,0000
	{
		c.sign = c.sign;
		c.expo = 0;
		// c.frac = c_frac.frac;
		c.frac = 0;
	} else
	{
		c.sign = c.sign;
		c.expo = c_expo.base;
		c.frac = c_frac.frac;
	}
	return c.ui;
}
