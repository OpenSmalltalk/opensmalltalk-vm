/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dInit.c
*   CONTENT: Initialization functions for the B3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id$
*
*   NOTES:
*
*
*****************************************************************************/
#include <string.h>
#include <stdlib.h>
#include "b3d.h"

#define b3dCompensateWindowPos 1

/* helpers */
#define rasterPosX rasterPos[0]
#define rasterPosY rasterPos[1]
#define rasterPosZ rasterPos[2]
#define rasterPosW rasterPos[3]

#define windowPosX windowPos[0]
#define windowPosY windowPos[1]

#define texCoordS texCoord[0]
#define texCoordT texCoord[1]

/*************************************************************/
/*************************************************************/
/*************************************************************/
int b3dInitializeEdgeAllocator(void* base, int length)
{
	B3DEdgeAllocList *list = (B3DEdgeAllocList*) base;
	if(length<0 || (unsigned)length < sizeof(B3DEdgeAllocList))
		return B3D_GENERIC_ERROR;
	list->magic = B3D_EDGE_ALLOC_MAGIC;
	list->This = base;
	list->max = (length - sizeof(B3DEdgeAllocList)) / sizeof(B3DPrimitiveEdge) + 1;
	list->size = 0;
	list->nFree = list->max;
	list->firstFree = NULL;
	return B3D_NO_ERROR;
}

int b3dInitializeFaceAllocator(void* base, int length)
{
	B3DFaceAllocList *list = (B3DFaceAllocList*) base;
	if(length<0 || (unsigned)length < sizeof(B3DFaceAllocList))
		return B3D_GENERIC_ERROR;
	list->magic = B3D_FACE_ALLOC_MAGIC;
	list->This = base;
	list->max = (length - sizeof(B3DFaceAllocList)) / sizeof(B3DPrimitiveFace) + 1;
	list->size = 0;
	list->nFree = list->max;
	list->firstFree = NULL;
	return B3D_NO_ERROR;
}

int b3dInitializeAttrAllocator(void* base, int length)
{
	B3DAttrAllocList *list = (B3DAttrAllocList*) base;
	if(length<0 || (unsigned)length < sizeof(B3DAttrAllocList))
		return B3D_GENERIC_ERROR;
	list->magic = B3D_ATTR_ALLOC_MAGIC;
	list->This = base;
	list->max = (length - sizeof(B3DAttrAllocList)) / sizeof(B3DPrimitiveAttribute) + 1;
	list->size = 0;
	list->nFree = list->max;
	list->firstFree = NULL;
	return B3D_NO_ERROR;
}

int b3dInitializeEdgeList(void* base, int length)
{
	B3DPrimitiveEdgeList *list = (B3DPrimitiveEdgeList*) base;
	if(length<0 || (unsigned)length < sizeof(B3DPrimitiveEdgeList))
		return B3D_GENERIC_ERROR;
	list->magic = B3D_EDGE_LIST_MAGIC;
	list->This = base;
	list->max = (length - sizeof(B3DPrimitiveEdgeList)) / sizeof(B3DPrimitiveEdge*) + 1;
	list->size = 0;
	return B3D_NO_ERROR;
}

int b3dInitializeAET(void* base, int length)
{
	B3DActiveEdgeTable *aet = (B3DActiveEdgeTable *) base;
	if(length<0 || (unsigned)length < sizeof(B3DActiveEdgeTable))
		return B3D_GENERIC_ERROR;
	aet->magic = B3D_AET_MAGIC;
	aet->This = base;
	aet->max = (length - sizeof(B3DActiveEdgeTable)) / sizeof(B3DPrimitiveEdge*) + 1;
	aet->size = 0;
	aet->leftEdge = aet->rightEdge = NULL;
	aet->lastIntersection = &aet->tempEdge0;
	aet->nextIntersection = &aet->tempEdge1;
	return B3D_NO_ERROR;
}

int b3dInitializeFillList(void* base, int length)
{
	B3DFillList *list = (B3DFillList*) base;
	if(length<0 || (unsigned)length < sizeof(B3DFillList))
		return B3D_GENERIC_ERROR;
	list->magic = B3D_FILL_LIST_MAGIC;
	list->This = base;
	list->firstFace = list->lastFace = NULL;
	return B3D_NO_ERROR;
}

/*************************************************************/
/*************************************************************/
/*************************************************************/

/* b3dMapObjectVertices:
	 Map all the vertices of the given object into the designated viewport.
*/
void b3dMapObjectVertices(B3DPrimitiveObject *obj, B3DPrimitiveViewport *vp)
{
	double xScale, yScale, xOfs, yOfs;
	int minX, minY, maxX, maxY;
	double minZ, maxZ;
	B3DPrimitiveVertex *vtx;
	int i;

	xOfs = (vp->x0 + vp->x1) * 0.5 - 0.5;
	yOfs = (vp->y0 + vp->y1) * 0.5 - 0.5;
	xScale = (vp->x1 - vp->x0) * 0.5;
	yScale = (vp->y1 - vp->y0) * -0.5;

	minX = minY = maxX = maxY = 0x7FFFFFFF;
	minZ = maxZ = 0.0;
	vtx = obj->vertices + 1;
	for(i=1; i < obj->nVertices; i++, vtx++)
	{
		double x,y,z,w;
		int scaledX, scaledY;

		w = vtx->rasterPosW;
		if(w) w = 1.0 / w;
		x = vtx->rasterPosX * w * xScale + xOfs;
		y = vtx->rasterPosY * w * yScale + yOfs;
		z = vtx->rasterPosZ * w;

		if(!b3dCompensateWindowPos) {
			vtx->rasterPosX = (float)x;
			vtx->rasterPosY = (float)y;
		}
		vtx->rasterPosZ = (float)z;
		vtx->rasterPosW = (float)w;

		scaledX = (int) (x * B3D_FloatToFixed);
		scaledY = (int) (y * B3D_FloatToFixed);

		vtx->windowPosX = scaledX;
		vtx->windowPosY = scaledY;
		if(b3dCompensateWindowPos) {
			vtx->rasterPosX = (float) (scaledX * B3D_FixedToFloat);
			vtx->rasterPosY = (float) (scaledY * B3D_FixedToFloat);
		}
		/* Update min/max */
		if(i == 1) {
			minX = maxX = scaledX;
			minY = maxY = scaledY;
			minZ = maxZ = z;
		} else {
			if(scaledX < minX) minX = scaledX;
			else if(scaledX > maxX) maxX = scaledX;
			if(scaledY < minY) minY = scaledY;
			else if(scaledY > maxY) maxY = scaledY;
			if(z < minZ) minZ = z;
			else if(z > maxZ) maxZ = z;
		}

	}

	obj->minX = minX >> B3D_FixedToIntShift;
	obj->maxX = maxX >> B3D_FixedToIntShift;
	obj->minY = minY >> B3D_FixedToIntShift;
	obj->maxY = maxY >> B3D_FixedToIntShift;
	obj->minZ = (float)minZ;
	obj->maxZ = (float)maxZ;
}

/* b3dSetupVertexOrder:
     Setup the ordering of the vertices in each face so that
	   v0 sorts before v1 sorts before v2.
	 Gather some stats on how much locally sorted and invalid
	 faces the object includes.
*/

void b3dSetupVertexOrder(B3DPrimitiveObject *obj)
{
	B3DInputFace *face;
	int i, nSorted, nInvalid;
	B3DPrimitiveVertex *vtx, *lastTopVtx, *newTopVtx;

	face = obj->faces;
	vtx = obj->vertices;
	nSorted = nInvalid = 0;
	lastTopVtx = NULL;
	for(i=0;i<obj->nFaces; i++,face++)
	{
		B3DPrimitiveVertex *vtx0, *vtx1, *vtx2;
		int idx0, idx1, idx2;
		idx0 = face->i0;
		idx1 = face->i1;
		idx2 = face->i2;
		if(0 == (idx0 && idx1 && idx2)) {
			nInvalid++;
			continue;
		}
		vtx0 = vtx + idx0;
		vtx1 = vtx + idx1;
		vtx2 = vtx + idx2;
		if(vtxSortsBefore(vtx0,vtx1))
		{
			if(vtxSortsBefore(vtx1,vtx2)) { 
				face->i0 = idx0; 
				face->i1 = idx1; 
				face->i2 = idx2; 
			} else if(vtxSortsBefore(vtx0,vtx2)) {
				face->i0 = idx0;
				face->i1 = idx2;
				face->i2 = idx1;
			} else {
				face->i0 = idx2;
				face->i1 = idx0;
				face->i2 = idx1;
			}
		} else if(vtxSortsBefore(vtx0, vtx2)) {
			face->i0 = idx1;
			face->i1 = idx0;
			face->i2 = idx2;
		} else if(vtxSortsBefore(vtx1, vtx2)) {
			face->i0 = idx1;
			face->i1 = idx2;
			face->i2 = idx0;
		} else {
			face->i0 = idx2;
			face->i1 = idx1;
			face->i2 = idx0;
		}

		if(b3dDebug) {
			vtx0 = vtx + face->i0;
			vtx1 = vtx + face->i1;
			vtx2 = vtx + face->i2;
			if( !vtxSortsBefore(vtx0, vtx1) || 
				!vtxSortsBefore(vtx0, vtx2) || 
				!vtxSortsBefore(vtx1, vtx2))
					b3dAbort("Vertex order problem");
		}

		/* Experimental: Try to estimate how many faces are already sorted. */
		newTopVtx = vtx + face->i0;
		if(lastTopVtx)
			if(vtxSortsBefore(lastTopVtx, newTopVtx)) nSorted++;
		lastTopVtx = newTopVtx;
	}

	obj->nSortedFaces = nSorted;
	obj->nInvalidFaces = nInvalid;
}


/*************************************************************/
/*************************************************************/
/*************************************************************/

typedef struct stackEntry {
	int i, j;
} stackEntry;
static stackEntry *stack = NULL;
static int stackPointer = 0;
static int stackSize = 0;

#define PUSH(v1, v2) {\
		stack[stackPointer].i = v1;\
		stack[stackPointer].j = v2;\
		stackPointer++;\
	}
#define POP(v1, v2) { \
		stackPointer--; \
		v1 = stack[stackPointer].i; \
		v2 = stack[stackPointer].j; \
	}

#define INIT(k) { \
	if(stackSize < (k)) { \
		stackSize = k; \
		if(stack) free(stack); \
		stack = calloc(stackSize, sizeof(stackEntry)); \
		if(!stack) { \
			stackSize = 0; \
			return B3D_GENERIC_ERROR; \
		}\
	} \
	stackPointer = 0; \
}

/* b3dSortInitialFaces:
     Sort the faces of the given object according to the given sort order.
	 Note: It is assumed that the vertex order of the faces has been setup
	       before.
*/
int b3dQuickSortInitialFaces(B3DPrimitiveObject *obj, int i, int j)
{
  B3DInputFace tmp, *faces = obj->faces;
  int ij, k, l, n;
  B3DPrimitiveVertex *di, *dj, *dij, *tt, *vtx = obj->vertices;

  /* Keep us enough headroom */
  INIT((j-i)*2);
  PUSH(i,j);
  while(stackPointer > 0) {
    POP(i, j);
    n = j + 1 - i;
    if(n <= 1) continue;
    /* Sort di,dj. */
    di = vtx + faces[i].i0;
    dj = vtx + faces[j].i0;
    if(!vtxSortsBefore(di,dj)) {
      tmp = faces[i]; faces[i] = faces[j]; faces[j] = tmp;
      tt = di; di = dj; dj = tt;
    }
    
    if(n <= 2) continue;

    /* More than two elements. */
    ij = (i+j) >> 1; /* ij is the midpoint of i and j. */
    dij = vtx + faces[ij].i0;
    /* Sort di,dij,dj.  Make dij be their median. */
    if(vtxSortsBefore(di, dij)) {/* i.e. should di precede dij? */
      if(!vtxSortsBefore(dij, dj)) {/* i.e., should dij precede dj?*/
	tmp = faces[j]; faces[j] = faces[ij]; faces[ij] = tmp;
	dij = dj;
      }
    } else { /* i.e. di should come after dij */
      tmp = faces[i]; faces[i] = faces[ij]; faces[ij] = tmp;
      dij = di;
    }

    if(n <= 3) continue;

    /* More than three elements.
       Find k>i and l<j such that dk,dij,dl are in reverse order.
       Swap k and l.  Repeat this procedure until k and l pass each other.*/
    k = i;
    l = j;
    
    while(k <= l) {
      while(k <= --l && (vtxSortsBefore(dij, vtx + faces[l].i0)));
      while(++k <= l && (vtxSortsBefore(vtx + faces[k].i0, dij)));
      if(k <= l) {
	tmp = faces[k];
	faces[k] = faces[l];
	faces[l] = tmp;
      }
    }
    /* Now l<k (either 1 or 2 less), and di through dl are all less than 
       or equal to dk through dj.  Sort those two segments. */
    PUSH(i, l);
    PUSH(k, j);
  }
  return B3D_NO_ERROR;
}
/* b3dQuickSortObjects:
	Sort the objects in the given range.
*/

int b3dQuickSortObjects(B3DPrimitiveObject **array, int i, int j)
{
  int ij, k, l, n;
  B3DPrimitiveObject *di, *dj, *dij, *tmp;
	
  /* Keep us enough headroom */
  INIT((j-i)*2);
  PUSH(i,j);
  while(stackPointer > 0) {
    POP(i, j);

    n = j + 1 - i;
    if(n <= 1) continue;
    /* Sort di,dj. */
    di = array[i];
    dj = array[j];
    if(!objSortsBefore(di,dj)) {
      tmp = array[i]; array[i] = array[j]; array[j] = tmp;
      tmp = di; di = dj; dj = tmp;
    }

    if(n <= 2) continue;

    /* More than two elements. */
    ij = (i+j) >> 1; /* ij is the midpoint of i and j. */
    dij = array[ij];
    /* Sort di,dij,dj.  Make dij be their median. */
    if(objSortsBefore(di, dij)) {/* i.e. should di precede dij? */
      if(!objSortsBefore(dij, dj)) {/* i.e., should dij precede dj?*/
	tmp = array[j]; array[j] = array[ij]; array[ij] = tmp;
	dij = dj;
      }
    } else { /* i.e. di should come after dij */
      tmp = array[i]; array[i] = array[ij]; array[ij] = tmp;
      dij = di;
    }
    
    if(n <= 3) continue;

    /* More than three elements.
       Find k>i and l<j such that dk,dij,dl are in reverse order.
       Swap k and l.  Repeat this procedure until k and l pass each other.*/
    k = i;
    l = j;

    while(k <= l) {
      while(k <= --l && (objSortsBefore(dij, array[l])));
      while(++k <= l && (objSortsBefore(array[k], dij)));
      if(k <= l) { tmp = array[k]; array[k] = array[l]; array[l] = tmp; }
    }
    /* Now l<k (either 1 or 2 less), and di through dl are all less than 
       or equal to dk through dj.  Sort those two segments. */
    PUSH(i, l);
    PUSH(k, j);
  }
  return B3D_NO_ERROR;
}

#undef INIT
#undef PUSH
#undef POP

/*************************************************************/
/*************************************************************/
/*************************************************************/


void b3dValidateObjectFaces(B3DPrimitiveObject *obj)
{
	int i;
	B3DInputFace *face,*nextFace;

	face = obj->faces;
	nextFace = face + 1;
	for(i=1; i < obj->nFaces; i++, face++, nextFace++) {
		if(!vtxSortsBefore(obj->vertices + face->i0, obj->vertices + nextFace->i0))
			b3dAbort("Face sorting problem");
	}
}


#define InitObject(obj, objBase, objFlags, textureIndex) \
	obj = (B3DPrimitiveObject*) objBase; \
	obj->magic = B3D_PRIMITIVE_OBJECT_MAGIC; \
	obj->This = objBase; \
	obj->start = 0; \
	obj->next = NULL; \
	obj->flags = objFlags; \
	obj->textureIndex = textureIndex; \
	obj->texture = NULL;

#define InitVertex(vtx) \
		(vtx)->rasterPosX =				\
		(vtx)->rasterPosY =				\
		(vtx)->rasterPosZ =				\
		(vtx)->rasterPosW =				\
		(vtx)->texCoordS  =				\
		(vtx)->texCoordT  = (float) 0.0;\
		(vtx)->windowPosX =				\
		(vtx)->windowPosY = 0x7FFFFFFF;	\
		(vtx)->cc.pixelValue32 = 0;


/* b3dAddIndexedTriangleObject:
     Create a new primitive object.
*/
int b3dAddIndexedTriangleObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DInputFace *facePtr, int nFaces,
						  B3DPrimitiveViewport *vp)
{
	B3DPrimitiveObject *obj;
	int sizeNeeded;

	sizeNeeded = sizeof(B3DPrimitiveObject) + 
				 sizeof(B3DPrimitiveVertex) * (nVertices+1) +
				 sizeof(B3DInputFace) * nFaces;

	if(!objBase || objLength < sizeNeeded) 
		return B3D_GENERIC_ERROR;

	InitObject(obj, objBase, objFlags, textureIndex);

	/* copy in the primitive vertices (starting immediately after the prim object) */
	obj->nVertices = nVertices+1; /* For one-based indexing leave one more entry */
	obj->vertices = (B3DPrimitiveVertex*) (obj + 1);
	memcpy(obj->vertices+1, vtxPointer, nVertices * sizeof(B3DPrimitiveVertex));

	/* copy in the input faces (starting after the vertices) */
	obj->nFaces = nFaces;
	obj->faces = (B3DInputFace*) (obj->vertices + obj->nVertices);
	memcpy(obj->faces, facePtr, nFaces * sizeof(B3DInputFace));

	/* Initialize the first vertex with something useful */
	InitVertex(obj->vertices);
	b3dMapObjectVertices(obj, vp);
	b3dSetupVertexOrder(obj);
	if(b3dQuickSortInitialFaces(obj,0,obj->nFaces-1) != B3D_NO_ERROR)
		return B3D_GENERIC_ERROR;


	if(b3dDebug)
		b3dValidateObjectFaces(obj);

	return B3D_NO_ERROR;
}

/* b3dAddIndexedQuadObject:
     Create a new primitive object.
*/
int b3dAddIndexedQuadObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DInputQuad *quadPtr, int nQuads,
						  B3DPrimitiveViewport *vp)
{
	B3DPrimitiveObject *obj;
	int sizeNeeded;

	sizeNeeded = sizeof(B3DPrimitiveObject) + 
				 sizeof(B3DPrimitiveVertex) * (nVertices+1) +
				 sizeof(B3DInputFace) * nQuads * 2;

	if(!objBase || objLength < sizeNeeded) 
		return B3D_GENERIC_ERROR;

	InitObject(obj, objBase, objFlags, textureIndex);

	/* copy in the primitive vertices (starting immediately after the prim object) */
	obj->nVertices = nVertices+1; /* For one-based indexing leave one more entry */
	obj->vertices = (B3DPrimitiveVertex*) (obj + 1);
	memcpy(obj->vertices+1, vtxPointer, nVertices * sizeof(B3DPrimitiveVertex));

	/* copy in the input faces (starting after the vertices) */
	obj->nFaces = nQuads * 2;
	obj->faces = (B3DInputFace*) (obj->vertices + obj->nVertices);
	{
		int i;
		B3DInputQuad *src = quadPtr;
		B3DInputFace *dst = obj->faces;

		for(i=0; i < nQuads; i++, src++) {
			dst->i0 = src->i0;
			dst->i1 = src->i1;
			dst->i2 = src->i2;
			dst++;
			dst->i0 = src->i2;
			dst->i1 = src->i3;
			dst->i2 = src->i0;
			dst++;
		}
	}

	/* Initialize the first vertex with something useful */
	InitVertex(obj->vertices);
	b3dMapObjectVertices(obj, vp);
	b3dSetupVertexOrder(obj);
	if(b3dQuickSortInitialFaces(obj,0,obj->nFaces-1) != B3D_NO_ERROR)
		return B3D_GENERIC_ERROR;

	if(b3dDebug)
		b3dValidateObjectFaces(obj);

	return B3D_NO_ERROR;
}

/* b3dAddPolygonObject:
     Create a new primitive object.
*/
int b3dAddPolygonObject(void *objBase, int objLength, int objFlags, int textureIndex,
						  B3DPrimitiveVertex *vtxPointer, int nVertices,
						  B3DPrimitiveViewport *vp)
{
	B3DPrimitiveObject *obj;
	int sizeNeeded;

	sizeNeeded = sizeof(B3DPrimitiveObject) + 
				 sizeof(B3DPrimitiveVertex) * (nVertices+1) +
				 sizeof(B3DInputFace) * (nVertices - 2);

	if(!objBase || objLength < sizeNeeded) 
		return B3D_GENERIC_ERROR;

	InitObject(obj, objBase, objFlags, textureIndex);

	/* copy in the primitive vertices (starting immediately after the prim object) */
	obj->nVertices = nVertices+1; /* For one-based indexing leave one more entry */
	obj->vertices = (B3DPrimitiveVertex*) (obj + 1);
	memcpy(obj->vertices+1, vtxPointer, nVertices * sizeof(B3DPrimitiveVertex));

	/* copy in the input faces (starting after the vertices) */
	obj->nFaces = nVertices - 2;
	obj->faces = (B3DInputFace*) (obj->vertices + obj->nVertices);
	{
		B3DInputFace *dst = obj->faces;
		int i, nFaces = obj->nFaces;

		for(i=0; i < nFaces; i++, dst++) {
			dst->i0 = 1;
			dst->i1 = 2+i;
			dst->i2 = 3+i;
		}
	}

	/* Initialize the first vertex with something useful */
	InitVertex(obj->vertices);
	b3dMapObjectVertices(obj, vp);
	b3dSetupVertexOrder(obj);
	if(b3dQuickSortInitialFaces(obj,0,obj->nFaces-1) != B3D_NO_ERROR)
		return B3D_GENERIC_ERROR;

	if(b3dDebug)
		b3dValidateObjectFaces(obj);

	return B3D_NO_ERROR;
}

/*************************************************************/
/*************************************************************/
/*************************************************************/

int b3dLoadTexture(B3DTexture *texture,
				   int width, int height, int depth, unsigned int *bits,
				   int cmSize, unsigned int *colormap)
{	int nBits;

	if(width < 1 || height < 1) return B3D_GENERIC_ERROR;
	if(depth != 32) return B3D_GENERIC_ERROR;
	if(depth != 8  && depth != 16 && depth != 32) return B3D_GENERIC_ERROR;
	if(depth == 8 && cmSize < 256) return B3D_GENERIC_ERROR;
	texture->width = width;
	texture->height = height;
	texture->depth = depth;
	texture->data = bits;
	texture->cmSize = cmSize;
	texture->colormap = colormap;
	texture->rowLength = width;
	nBits = 1;
	while((1 << nBits) < width) nBits++;
	if((1<<nBits) == width) {
		texture->sMask = (1<<nBits) - 1;
		texture->sShift = nBits;
	} else {
		texture->sMask = texture->sShift = 0;
	}
	while((1 << nBits) < height) nBits++;
	if((1<<nBits) == height) {
		texture->tMask = (1<<nBits) - 1;
		texture->tShift = nBits;
	} else {
		texture->tMask = texture->tShift = 0;
	}
	return B3D_NO_ERROR;
}
/*************************************************************/
/*************************************************************/
/*************************************************************/
/* b3dSetupObjects:
	Sort the objects and create a linked list between the objects.
*/
int b3dSetupObjects(B3DRasterizerState *state)
{
	int i, textureIndex, nTextures = state->nTextures, nObjects = state->nObjects;
	B3DPrimitiveObject *obj, **objects = state->objects;
	B3DTexture *textures = state->textures;

	if(b3dQuickSortObjects(objects, 0, nObjects-1) != B3D_NO_ERROR)
		return B3D_GENERIC_ERROR;

	for(i=0; i<nObjects; i++) {

		if(b3dDebug && i) {
			if(!objSortsBefore(objects[i-1], objects[i]))
				b3dAbort("Object sorting problem");
		}

		obj = objects[i];
		obj->flags &= ~(B3D_OBJECT_ACTIVE | B3D_OBJECT_DONE);
		obj->start = 0;
		/*-- Note: The following is important --*/
		obj->nFaces -= obj->nInvalidFaces;
		obj->nInvalidFaces = 0;
		if(!obj->nFaces) break;
		/*-- End --*/
		textureIndex = obj->textureIndex - 1;
		if(textureIndex >= 0 && textureIndex < nTextures) {
			obj->texture = textures + textureIndex;
			obj->flags |= B3D_FACE_STW;
		} else obj->texture = NULL;
		obj->next = NULL;
		if(i) {
			objects[i-1]->next = obj;
			obj->prev = objects[i-1];
		}
	}
	return B3D_NO_ERROR;
}
