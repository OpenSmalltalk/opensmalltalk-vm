/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3d.h
*   CONTENT: Main include file
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3d.h,v 1.1 2001/10/24 23:12:22 rowledge Exp $
*
*   NOTES:
*
*
*****************************************************************************/
#ifndef __B3D_H
#define __B3D_H

#ifdef DEBUG
#define b3dDebug 1
#else
#define b3dDebug 0
#endif

#define b3dDoStats 1

/* primary include file */

#include "b3dTypes.h"
#include "b3dAlloc.h"

typedef int (*b3dDrawBufferFunction) (int leftX, int rightX, int yValue);

typedef struct B3DRasterizerState {

	/* The three sources for allocating 
	   temporary rasterizer objects */
	B3DFaceAllocList *faceAlloc;
	B3DEdgeAllocList *edgeAlloc;
	B3DAttrAllocList *attrAlloc;

	/* The active edge table */
	B3DActiveEdgeTable *aet;
	/* The list for newly added edges */
	B3DPrimitiveEdgeList *addedEdges;

	/* The fill list */
	B3DFillList *fillList;

	/* The input objects for the rasterizer */
	int nObjects;
	B3DPrimitiveObject **objects;

	/* The input textures for the rasterizer */
	int nTextures;
	B3DTexture *textures;

	/* Length and location of span buffer to use */
	int spanSize;
	unsigned int *spanBuffer;

	/* Function to call on drawing the output buffer */
	b3dDrawBufferFunction spanDrawer;

} B3DRasterizerState;

extern B3DRasterizerState *currentState;

/* from b3dInit.c */
int b3dInitializeEdgeAllocator(void* base, int length);
int b3dInitializeFaceAllocator(void* base, int length);
int b3dInitializeAttrAllocator(void* base, int length);
int b3dInitializeAET(void* base, int length);
int b3dInitializeEdgeList(void* base, int length);
int b3dInitializeFillList(void* base, int length);
int b3dSetupObjects(B3DRasterizerState *state);

int b3dAddPolygonObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DPrimitiveViewport *vp);

int b3dAddIndexedQuadObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DInputQuad *quadPtr, int nQuads,
						  B3DPrimitiveViewport *vp);

int b3dAddIndexedTriangleObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DInputFace *facePtr, int nFaces,
						  B3DPrimitiveViewport *vp);

int b3dLoadTexture(B3DTexture *texture,
				   int width, int height, int depth, unsigned int *bits,
				   int cmSize, unsigned int *colormap);


/* from b3dRemap.c */
int b3dValidateAndRemapState(B3DRasterizerState *state);

/* from b3dDraw.c */
typedef void (*b3dPixelDrawer) (int leftX, int rightX, int yValue, B3DPrimitiveFace *face);
extern b3dPixelDrawer B3D_FILL_FUNCTIONS[];

/* from b3dMain.c */
void b3dAbort(char *msg);
int b3dMainLoop(B3DRasterizerState *state, int stopReason);

#endif
