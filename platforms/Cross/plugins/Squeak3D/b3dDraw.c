/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dDraw.c
*   CONTENT: Pixel drawing functions for the B3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3dDraw.c,v 1.1 2001/10/24 23:12:23 rowledge Exp $
*
*   NOTES:  LOTS of stuff missing here...
*
*	- A note on RGBA interpolation:
*	For low polygon models it makes sense to compute both, the left and
*	the right attribute value if there might be any overflow at all.
*	Since we're usually drawing many pixels in a row we can clamp the
*	left and right value and thus be safe during the interpolation stage.
*
*****************************************************************************/
#include "b3d.h"

#define rasterPosX rasterPos[0]
#define rasterPosY rasterPos[1]

#define redValue   color[RED_INDEX]
#define greenValue color[GREEN_INDEX]
#define blueValue  color[BLUE_INDEX]
#define alphaValue color[ALPHA_INDEX]

/* The following defines the maximum number of pixels 
   we treat in one loop. This value should be carefully
   chosen: Setting it high will increase speed for larger
   polygons but reduce speed for smaller ones. Setting
   it low will do the opposite. Also, since I'm assuming
   a smart compiler, the code size will probably increase
   with this number (if loops are unrolled by the compiler).

   The current value of 5 should be a good median (32 pixels
   are processed at most and we'll have the overhead of 5
   tests for a one-pixel polygon).
*/
#define MAX_PIXEL_SHIFT 5


/* USE_MULTBL: Replace up a couple of multiplications by table lookups.
	On PowerPC, the lookup seems to be slightly slower.
	On Intel, the lookup is way faster.
*/
#ifndef USE_MULTBL
# ifdef __POWERPC__
#  define USE_MULTBL 0
# else
#  define USE_MULTBL 1
# endif
#endif

/* Clamp the given value */
#define CLAMP(value, min, max)\
	if((value) < (min)) (value) = (min); \
	else if((value) > (max)) (value) = (max);

/* Clamp a set of fixed point RGB values */
#define CLAMP_RGB(r,g,b) \
	CLAMP(r,B3D_FixedHalf, (255 << B3D_IntToFixedShift) + B3D_FixedHalf)\
	CLAMP(g,B3D_FixedHalf, (255 << B3D_IntToFixedShift) + B3D_FixedHalf)\
	CLAMP(b,B3D_FixedHalf, (255 << B3D_IntToFixedShift) + B3D_FixedHalf)


#ifdef DEBUG_ATTR
double attrValueAt(B3DPrimitiveFace *face, B3DPrimitiveAttribute *attr, double xValue, double yValue)
{
	return 
		(attr->value +
			((xValue - face->v0->rasterPosX) * attr->dvdx) +
			((yValue - face->v0->rasterPosY) * attr->dvdy));
}
#else
#define attrValueAt(face,attr,xValue,yValue) \
		((attr)->value + \
			(((double)(xValue) - (face)->v0->rasterPosX) * (attr)->dvdx) + \
			(((double)(yValue) - (face)->v0->rasterPosY) * (attr)->dvdy))
#endif


#define SETUP_RGB \
	rValue = (int)(attrValueAt(face, attr, floatX, floatY) * B3D_FloatToFixed); \
	deltaR = (int) (attr->dvdx * B3D_FloatToFixed);  \
	attr = attr->next; \
	gValue = (int)(attrValueAt(face, attr, floatX, floatY) * B3D_FloatToFixed);\
	deltaG = (int) (attr->dvdx * B3D_FloatToFixed); \
	attr = attr->next; \
	bValue = (int)(attrValueAt(face, attr, floatX, floatY) * B3D_FloatToFixed); \
	deltaB = (int) (attr->dvdx * B3D_FloatToFixed); \
	attr = attr->next;\
	CLAMP_RGB(rValue, gValue, bValue);

#define SETUP_STW \
	wValue = attrValueAt(face, attr, floatX, floatY); \
	wDelta = attr->dvdx; \
	attr = attr->next; \
	sValue = attrValueAt(face, attr, floatX, floatY); \
	sDelta = attr->dvdx; \
	attr = attr->next; \
	tValue = attrValueAt(face, attr, floatX, floatY); \
	tDelta = attr->dvdx; \
	attr = attr->next;

#define STEP_STW \
	sValue += sDelta;\
	tValue += tDelta;\
	wValue += wDelta;


/* Load the four neighbouring texels into tex00, tex01, tex10, and tex11 */
#define LOAD_4_RGB_TEXEL_32(fixedS, fixedT, texture) \
{\
	int sIndex, tIndex;\
\
	if(texture->sMask) {\
		sIndex = (fixedS >> B3D_FixedToIntShift) & texture->sMask;\
	} else {\
		sIndex = (fixedS >> B3D_FixedToIntShift) % texture->width;\
	}\
	if(texture->tMask) {\
		tIndex = (fixedT >> B3D_FixedToIntShift) & texture->tMask;\
	} else {\
		tIndex = (fixedT >> B3D_FixedToIntShift) % texture->height;\
	}\
	/* Load the 4 texels, wrapping if necessary */\
	tex00 = (struct b3dPixelColor *) texture->data + (tIndex * texture->width) + sIndex;\
	tex01 = tex00 + 1;\
	tex10 = tex00 + texture->width;\
	tex11 = tex10 + 1;\
	if(sIndex+1 == texture->width) {\
		tex01 -= texture->width;\
		tex11 -= texture->width;\
	}\
	if(tIndex+1 == texture->height) {\
		int tsize = texture->height * texture->width;\
		tex10 -= tsize;\
		tex11 -= tsize;\
	}\
}


#if USE_MULTBL /* Use a 16x256 table for lookups */

unsigned short MULTBL[17][256];

static int multblInit = 0;

static void MULTBL_Init(void)
{
	int i,j;
	for(i=0;i<17;i++)
		for(j=0; j<256; j++)
			MULTBL[i][j] = (i*j) >> 4;
	multblInit = 1;
}

#define INIT_MULTBL { if (!multblInit) MULTBL_Init(); }

#define DO_RGB_INTERPOLATION(sf, si, tf, ti) \
	tr = (MULTBL[ti][(MULTBL[si][tex00->redValue] + MULTBL[sf][tex01->redValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->redValue] + MULTBL[sf][tex11->redValue])]);\
	tg = (MULTBL[ti][(MULTBL[si][tex00->greenValue] + MULTBL[sf][tex01->greenValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->greenValue] + MULTBL[sf][tex11->greenValue])]);\
	tb = (MULTBL[ti][(MULTBL[si][tex00->blueValue] + MULTBL[sf][tex01->blueValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->blueValue] + MULTBL[sf][tex11->blueValue])]);

#define DO_RGBA_INTERPOLATION(sf, si, tf, ti)\
	tr = (MULTBL[ti][(MULTBL[si][tex00->redValue] + MULTBL[sf][tex01->redValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->redValue] + MULTBL[sf][tex11->redValue])]);\
	tg = (MULTBL[ti][(MULTBL[si][tex00->greenValue] + MULTBL[sf][tex01->greenValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->greenValue] + MULTBL[sf][tex11->greenValue])]);\
	tb = (MULTBL[ti][(MULTBL[si][tex00->blueValue] + MULTBL[sf][tex01->blueValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->blueValue] + MULTBL[sf][tex11->blueValue])]); \
	ta = (MULTBL[ti][(MULTBL[si][tex00->alphaValue] + MULTBL[sf][tex01->alphaValue])] + \
			MULTBL[tf][(MULTBL[si][tex10->alphaValue] + MULTBL[sf][tex11->alphaValue])]);

#else

#define INIT_MULTBL

#define DO_RGB_INTERPOLATION(sf, si, tf, ti) \
	tr = (ti * (si * tex00->redValue + sf * tex01->redValue) +\
			tf * (si * tex10->redValue + sf * tex11->redValue)) >> 8;\
	tg = (ti * (si * tex00->greenValue + sf * tex01->greenValue) +\
			tf * (si * tex10->greenValue + sf * tex11->greenValue)) >> 8;\
	tb = (ti * (si * tex00->blueValue + sf * tex01->blueValue) +\
			tf * (si * tex10->blueValue + sf * tex11->blueValue)) >> 8;\

#define DO_RGBA_INTERPOLATION(sf, si, tf, ti) \
	tr = (ti * (si * tex00->redValue + sf * tex01->redValue) +\
			tf * (si * tex10->redValue + sf * tex11->redValue)) >> 8;\
	tg = (ti * (si * tex00->greenValue + sf * tex01->greenValue) +\
			tf * (si * tex10->greenValue + sf * tex11->greenValue)) >> 8;\
	tb = (ti * (si * tex00->blueValue + sf * tex01->blueValue) +\
			tf * (si * tex10->blueValue + sf * tex11->blueValue)) >> 8;\
	ta = (ti * (si * tex00->alphaValue + sf * tex01->alphaValue) +\
			tf * (si * tex10->alphaValue + sf * tex11->alphaValue)) >> 8;

#endif /* No MULTBL */

#define INTERPOLATE_RGB_TEXEL(fixedS, fixedT)\
{	int sf, si, tf, ti;\
	sf = (fixedS >> (B3D_FixedToIntShift - 4)) & 15; si = 16 - sf;\
	tf = (fixedT >> (B3D_FixedToIntShift - 4)) & 15; ti = 16 - tf;\
	DO_RGB_INTERPOLATION(sf, si, tf, ti)\
}

void b3dNoDraw     (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawRGB    (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawRGBA   (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawSTW    (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawSTWA   (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawSTWRGB (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
void b3dDrawSTWARGB(int leftX, int rightX, int yValue, B3DPrimitiveFace *face);

b3dPixelDrawer B3D_FILL_FUNCTIONS[B3D_MAX_ATTRIBUTES] = {
	b3dNoDraw,      /* No attributes */
	b3dDrawRGB,     /* B3D_FACE_RGB */
	b3dNoDraw,      /* B3D_FACE_ALPHA -- IGNORED!!! */
	b3dDrawRGBA,    /* B3D_FACE_RGB | B3D_FACE_ALPHA */
	b3dDrawSTW,     /* B3D_FACE_STW */
	b3dDrawSTWRGB,  /* B3D_FACE_STW | B3D_FACE_RGB */
	b3dDrawSTWA,    /* B3D_FACE_STW | B3D_FACE_ALPHA */
	b3dDrawSTWARGB  /* B3D_FACE_STW | B3D_FACE_RGB | B3D_FACE_ALPHA */
};

void b3dNoDraw(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	if(b3dDebug)
		b3dAbort("b3dNoDraw called!");
}

void b3dDrawRGBFlat(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	struct b3dPixelColor { B3DPrimitiveColor color; } pv, *bits;
	int rValue, gValue, bValue;
	int deltaR, deltaG, deltaB;


	{
		B3DPrimitiveAttribute *attr = face->attributes;
		/* Ughh ... I'm having a sampling problem somewhere.
		   In theory, the faces should be sampled *exactly* at integer
		   values (the necessary offset should be done before) so that
		   we always sample inside the triangle. For some reason that
		   doesn't quite work yet and that's why here is the strange
		   0.5 offset and the awful lot of tests. At some time I'll
		   review this but for now I have more important things to do.
		*/
		double floatX = leftX;
		double floatY = yValue+0.5;

		if(b3dDebug)
			if(!attr) b3dAbort("face has no RGB attributes");

		SETUP_RGB;
	}

	bits = (struct b3dPixelColor *) currentState->spanBuffer;
	pv.redValue   = (unsigned char) (rValue >> B3D_FixedToIntShift);
	pv.greenValue = (unsigned char) (gValue >> B3D_FixedToIntShift);
	pv.blueValue  = (unsigned char) (bValue >> B3D_FixedToIntShift);
	pv.alphaValue = 255;

	while(leftX <= rightX) {
		bits[leftX++] = pv;
	}
}

void b3dDrawRGB(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	struct b3dPixelColor { B3DPrimitiveColor color; } pv, *bits;
	int rValue, gValue, bValue;
	int deltaR, deltaG, deltaB;
	int deltaX, pixelShift;

	{
		B3DPrimitiveAttribute *attr = face->attributes;
		/* Ughh ... I'm having a sampling problem somewhere.
		   In theory, the faces should be sampled *exactly* at integer
		   values (the necessary offset should be done before) so that
		   we always sample inside the triangle. For some reason that
		   doesn't quite work yet and that's why here is the strange
		   0.5 offset and the awful lot of tests. At some time I'll
		   review this but for now I have more important things to do.
		*/
		double floatX = leftX;
		double floatY = yValue+0.5;

		if(b3dDebug)
			if(!attr) b3dAbort("face has no RGB attributes");

		SETUP_RGB;
	}

	bits = (struct b3dPixelColor *) currentState->spanBuffer;
	pv.alphaValue = 255;

	/*	Reduce the overhead of clamping by precomputing 
		the deltas for each power of two step. A good question here
		is whether or not it is a good idea to do 2 pixels by this... */
	deltaX = rightX - leftX + 1;

	/* Now do all the powers of two except the last one pixel */
	/* Note: A smart compiler (== gcc) should unroll the following loop */
	for(pixelShift= MAX_PIXEL_SHIFT; pixelShift> 0; pixelShift--) {
		int nPixels = 1 << pixelShift;
		/* Note: The 'if' here is possible since 
		   we have dealt with huge polys above */
		while(deltaX >= nPixels) {	
			{	/* Compute right most values of color interpolation */
				int maxR = rValue + (deltaR << pixelShift);
				int maxG = gValue + (deltaG << pixelShift);
				int maxB = bValue + (deltaB << pixelShift);
				/* Clamp those guys */
				CLAMP_RGB(maxR, maxG, maxB);
				/* And compute the actual delta */
				deltaR = (maxR - rValue) >> pixelShift;
				deltaG = (maxG - gValue) >> pixelShift;
				deltaB = (maxB - bValue) >> pixelShift;
			}
			/* Do the inner loop */
			{	int n = nPixels;
				while(n--) {
					pv.redValue   = (unsigned char) (rValue >> B3D_FixedToIntShift);
					pv.greenValue = (unsigned char) (gValue >> B3D_FixedToIntShift);
					pv.blueValue  = (unsigned char) (bValue >> B3D_FixedToIntShift);
					bits[leftX++] = pv;
					rValue += deltaR;
					gValue += deltaG;
					bValue += deltaB;
				}
			}
			/* Finally, adjust the number of pixels left */
			deltaX -= nPixels;
		}
	}
	/* The last pixel is done separately */
	if(deltaX) {
		pv.redValue   = (unsigned char) (rValue >> B3D_FixedToIntShift);
		pv.greenValue = (unsigned char) (gValue >> B3D_FixedToIntShift);
		pv.blueValue  = (unsigned char) (bValue >> B3D_FixedToIntShift);
		bits[leftX++] = pv;
	}
}

void b3dDrawSTWRGB(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	struct b3dPixelColor { B3DPrimitiveColor color; } pv, *bits, *tex00, *tex10, *tex01, *tex11;
	double sValue, tValue, wValue, sDelta, tDelta, wDelta, oneOverW;
	int rValue, gValue, bValue;
	int deltaR, deltaG, deltaB;
	int tr, tg, tb, ta;
	int fixedLeftS, fixedRightS, fixedLeftT, fixedRightT, fixedDeltaS, fixedDeltaT;
	int deltaX, pixelShift;

	B3DTexture *texture = face->texture;

	INIT_MULTBL;

	if(!texture || 0) {
		/* If no texture simply draw RGB */
		b3dDrawRGB(leftX, rightX, yValue, face);
		return;
	}
	if(texture->depth < 16 && (texture->cmSize < (1 << texture->depth)))
		return; /* Colormap not installed */

	{
		B3DPrimitiveAttribute *attr = face->attributes;
		/* See above */
		double floatX = leftX;
		double floatY = yValue+0.5;

		if(b3dDebug)
			if(!attr) b3dAbort("face has no RGB attributes");

		SETUP_RGB;
		SETUP_STW;
	}

	tr = tg = tb = ta = 255;

	bits = (struct b3dPixelColor *) currentState->spanBuffer;
	pv.alphaValue = 255;

	/*	VERY Experimental: Reduce the overhead of clamping
		as well as division by W by precomputing the deltas 
		for each power of two step */
	deltaX = rightX - leftX + 1;
	if(wValue) oneOverW = 1.0 / wValue;
	else oneOverW = 0.0;
	fixedLeftS = (int) (sValue * oneOverW * (texture->width << B3D_IntToFixedShift));
	fixedLeftT = (int) (tValue * oneOverW * (texture->height << B3D_IntToFixedShift));

	for(pixelShift = MAX_PIXEL_SHIFT; pixelShift > 0; pixelShift--) {
		int nPixels = 1 << pixelShift;
		while(deltaX >= nPixels) {
			{	/* Compute right most values of color interpolation */
				int maxR = rValue + (deltaR << pixelShift);
				int maxG = gValue + (deltaG << pixelShift);
				int maxB = bValue + (deltaB << pixelShift);
				/* Clamp those guys */
				CLAMP_RGB(maxR, maxG, maxB);
				/* And compute the actual delta */
				deltaR = (maxR - rValue) >> pixelShift;
				deltaG = (maxG - gValue) >> pixelShift;
				deltaB = (maxB - bValue) >> pixelShift;
			}
			/* Compute the RIGHT s/t values (the left ones are kept from the last loop) */
			wValue += wDelta * nPixels;
			sValue += sDelta * nPixels;
			tValue += tDelta * nPixels;
			if(wValue) oneOverW = 1.0 / wValue;
			else oneOverW = 0.0;
			fixedRightS = (int) (sValue * oneOverW * (texture->width << B3D_IntToFixedShift));
			fixedDeltaS = (fixedRightS - fixedLeftS) >> pixelShift;
			fixedRightT = (int) (tValue * oneOverW * (texture->height << B3D_IntToFixedShift));
			fixedDeltaT = (fixedRightT - fixedLeftT) >> pixelShift;
			/* Do the inner loop */
			{	int n = nPixels;
				while(n--) {
					/* Do the texture load ... hmm ... there should be a way
					   to avoid loading the texture on each pixel... 
					   On the other hand, the texture load does not seem
					   too expensive if compared with the texture interpolation.
					*/
					LOAD_4_RGB_TEXEL_32(fixedLeftS, fixedLeftT, texture);
					/* Do the interpolation based on tex00, tex01, tex10, tex11.
					   THIS seems to be one of the real bottlenecks here...
					*/
					INTERPOLATE_RGB_TEXEL(fixedLeftS, fixedLeftT);
#if USE_MULTBL
					pv.redValue   = (unsigned char) (MULTBL[rValue >> (B3D_FixedToIntShift+4)][tr]);
					pv.greenValue = (unsigned char) (MULTBL[gValue >> (B3D_FixedToIntShift+4)][tg]);
					pv.blueValue  = (unsigned char) (MULTBL[bValue >> (B3D_FixedToIntShift+4)][tb]);
#else
					pv.redValue   = (unsigned char) ((tr * rValue) >> (B3D_FixedToIntShift + 8));
					pv.greenValue = (unsigned char) ((tg * gValue) >> (B3D_FixedToIntShift + 8));
					pv.blueValue  = (unsigned char) ((tb * bValue) >> (B3D_FixedToIntShift + 8));
#endif
					bits[leftX++] = pv;
					rValue += deltaR;
					gValue += deltaG;
					bValue += deltaB;
					fixedLeftS += fixedDeltaS;
					fixedLeftT += fixedDeltaT;
				}
			}
			/* Finally, adjust the number of pixels left and update s/t */
			deltaX -= nPixels;
			fixedLeftS = fixedRightS;
			fixedLeftT = fixedRightT;
		}
	}
	/* The last pixel is done separately */
	if(deltaX) {
		/* Do the texture load */
		LOAD_4_RGB_TEXEL_32(fixedLeftS, fixedLeftT, texture);
		/* Do the interpolation */
		INTERPOLATE_RGB_TEXEL(fixedLeftS, fixedLeftT);
#if USE_MULTBL
		pv.redValue   = (unsigned char) (MULTBL[rValue >> (B3D_FixedToIntShift+4)][tr]);
		pv.greenValue = (unsigned char) (MULTBL[gValue >> (B3D_FixedToIntShift+4)][tg]);
		pv.blueValue  = (unsigned char) (MULTBL[bValue >> (B3D_FixedToIntShift+4)][tb]);
#else
		pv.redValue   = (unsigned char) ((tr * rValue) >> (B3D_FixedToIntShift + 8));
		pv.greenValue = (unsigned char) ((tg * gValue) >> (B3D_FixedToIntShift + 8));
		pv.blueValue  = (unsigned char) ((tb * bValue) >> (B3D_FixedToIntShift + 8));
#endif
		bits[leftX++] = pv;
	}
}

void b3dDrawSTWARGB(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	/* not yet implemented */
}

void b3dDrawRGBA(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	/* not yet implemented */
}

void b3dDrawSTW(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	/* not yet implemented */
}

void b3dDrawSTWA(int leftX, int rightX, int yValue, B3DPrimitiveFace *face)
{
	/* not yet implemented */
}
