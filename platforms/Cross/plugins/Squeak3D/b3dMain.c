/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dMain.c
*   CONTENT: Main rasterizer body
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
#include <stdio.h>  /* printf() */
#include <stdlib.h> /* exit()   */
#include <assert.h> /* assert() */
#include "b3d.h"

#ifndef NULL
#define NULL ((void*)0)
#endif

#ifdef B3D_PROFILE
unsigned int b3dObjSetupTime;
unsigned int b3dMapObjectTime;
unsigned int b3dVertexOrderTime;
unsigned int b3dSortFaceTime;
#endif

/* helpers */
#define rasterPosX rasterPos[0]
#define rasterPosY rasterPos[1]
#define rasterPosZ rasterPos[2]
#define rasterPosW rasterPos[3]

#define windowPosX windowPos[0]
#define windowPosY windowPos[1]

#define texCoordS texCoord[0]
#define texCoordT texCoord[1]

#define redValue   cc.color[RED_INDEX]
#define greenValue cc.color[GREEN_INDEX]
#define blueValue  cc.color[BLUE_INDEX]
#define alphaValue cc.color[ALPHA_INDEX]

/* globals */
B3DRasterizerState *currentState;

B3DActiveEdgeTable *aet;
B3DPrimitiveEdgeList *addedEdges;

B3DEdgeAllocList *edgeAlloc;
B3DFaceAllocList *faceAlloc;
B3DAttrAllocList *attrAlloc;

int nFaces = 0;
int maxFaces = 0;
int maxEdges = 0;
/*************************************************************/
/*************************************************************/
/*************************************************************/

void b3dAbort(char *msg){
	printf("%s\n", msg);
	exit(-1);
}

void b3dValidateEdgeOrder(B3DPrimitiveEdgeList *list)
{
	int i;

	if(list->size)
		if(list->data[0]->leftFace == list->data[0]->rightFace) {
			b3dAbort("Left face == right face");
		}
	for(i=1; i<list->size; i++) {
		if(list->data[i-1]->xValue > list->data[i]->xValue) {
			b3dAbort("Edge list is broken");
		}
		if(list->data[i]->leftFace == list->data[i]->rightFace) {
			b3dAbort("Left face == right face");
		}
	}
}

void b3dValidateAETOrder(B3DActiveEdgeTable *list)
{
	int i;

	if(list->size)
		if(list->data[0]->leftFace == list->data[0]->rightFace) {
			b3dAbort("Left face == right face");
		}
	for(i=1; i<list->size; i++) {
		if(list->data[i-1]->xValue > list->data[i]->xValue) {
			b3dAbort("Edge list is broken");
		}
		if(list->data[i]->leftFace == list->data[i]->rightFace) {
			b3dAbort("Left face == right face");
		}
	}
}

/*************************************************************/
/*************************************************************/
/*************************************************************/
/* b3dInitializeFace:
	Allocate a new primitive face based on the given vertices.
	Do the necessary initial setup, but don't set up any drawing attributes yet.
	Return the newly created face.
	NOTE: May cause allocation of one face!
*/
B3DPrimitiveFace *b3dInitializeFace(B3DPrimitiveVertex *v0,
									B3DPrimitiveVertex *v1,
									B3DPrimitiveVertex *v2,
									B3DTexture *texture, 
									int attrFlags)
{
	B3DPrimitiveFace *face;

	/* Compute major and minor reference edges */
	{
		float majorDx = v2->rasterPosX - v0->rasterPosX;
		float majorDy = v2->rasterPosY - v0->rasterPosY;
		float minorDx = v1->rasterPosX - v0->rasterPosX;
		float minorDy = v1->rasterPosY - v0->rasterPosY;
		float area = (majorDx * minorDy) - (minorDx * majorDy);

		if(area > -0.001 && area < 0.001) return NULL;
		/* Now that we know the face is valid, do the actual allocation */
		b3dAllocFace(faceAlloc, face);

		if(b3dDebug)
			if(!face) b3dAbort("Face allocation failed");

		face->v0 = v0;
		face->v1 = v1;
		face->v2 = v2;
		face->leftEdge = NULL;
		face->rightEdge = NULL;
		face->attributes = NULL;
		face->oneOverArea = (float) (1.0 / area);
		face->majorDx = majorDx;
		face->majorDy = majorDy;
		face->minorDx = minorDx;
		face->minorDy = minorDy;
		face->texture = texture;
		face->flags |= attrFlags & (B3D_ATTR_MASK << B3D_ATTR_SHIFT);

		{ /* Compute dzdx and dzdy */
			float majorDz = v2->rasterPosZ - v0->rasterPosZ;
			float minorDz = v1->rasterPosZ - v0->rasterPosZ;

			face->dzdx = face->oneOverArea * ((majorDz * minorDy) - (minorDz * majorDy));
			face->dzdy = face->oneOverArea * ((majorDx * minorDz) - (minorDx * majorDz));
		}
	}

	{/* Compute minZ/maxZ */
		float z0 = v0->rasterPosZ;
		float z1 = v1->rasterPosZ;
		float z2 = v2->rasterPosZ;
		if(z0 <= z1) {
			if(z1 <= z2) {
				face->minZ = z0;
				face->maxZ = z2;
			} else if(z0 <= z2) {
				face->minZ = z0;
				face->maxZ = z1;
			} else {
				face->minZ = z2;
				face->maxZ = z1;
			}
		} else if(z2 <= z1) {
			face->minZ = z2;
			face->maxZ = z0;
		} else if(z0 <= z2) {
			face->minZ = z1;
			face->maxZ = z0;
		} else {
			face->minZ = z1;
			face->maxZ = z0;
		}
	} /* End of minZ/maxZ */

	return face;
}

/* b3dInitializePass2:
	Do a second initialization pass if the face is known to be visible.
*/
int b3dInitializePass2(B3DPrimitiveFace *face)
{
	double majorDv, minorDv, baseValue;
	double dvdx, dvdy;
	B3DPrimitiveAttribute *attr;
	B3DPrimitiveVertex *v0 = face->v0;
	B3DPrimitiveVertex *v1 = face->v1;
	B3DPrimitiveVertex *v2 = face->v2;

	{
		int ok;
		b3dAllocAttrib(attrAlloc, face, ok);
		if(!ok) return 0; /* NOT initalized */
	}

	attr = face->attributes;
	assert(attr);
	
	if(face->flags & B3D_FACE_RGB) {
		/* Setup RGB interpolation */
		majorDv = v2->redValue - v0->redValue;
		minorDv = v1->redValue - v0->redValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) v0->redValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;

		majorDv = v2->greenValue - v0->greenValue;
		minorDv = v1->greenValue - v0->greenValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) v0->greenValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;

		majorDv = v2->blueValue - v0->blueValue;
		minorDv = v1->blueValue - v0->blueValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) v0->blueValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;
	}
	if(face->flags & B3D_FACE_ALPHA) {
		/* Setup alpha interpolation */
		majorDv = v2->alphaValue - v0->alphaValue;
		minorDv = v1->alphaValue - v0->alphaValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) v0->alphaValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;
	}
	if(face->flags & B3D_FACE_STW) {
		/* Setup texture coordinate interpolation */
		double w0 = v0->rasterPosW;
		double w1 = v1->rasterPosW;
		double w2 = v2->rasterPosW;

		majorDv = w2 - w0;
		minorDv = w1 - w0;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) w0;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;

		baseValue = v0->texCoordS * w0;
		majorDv = (v2->texCoordS * w2) - baseValue;
		minorDv = (v1->texCoordS * w1) - baseValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) baseValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;

		baseValue = v0->texCoordT * w0;
		majorDv = (v2->texCoordT * w2) - baseValue;
		minorDv = (v1->texCoordT * w1) - baseValue;
		dvdx = face->oneOverArea * ((majorDv * face->minorDy) - (minorDv * face->majorDy));
		dvdy = face->oneOverArea * ((minorDv * face->majorDx) - (majorDv * face->minorDx));
		attr->value = (float) baseValue;
		attr->dvdx  = (float) dvdx;
		attr->dvdy  = (float) dvdy;
		attr = attr->next;
	}
	face->flags |= B3D_FACE_INITIALIZED;
	return 1;
}

/* b3dInitializeEdge:
	Initialize the incremental values of the given edge.
*/
/* INLINE b3dInitializeEdge(edge) */
void b3dInitializeEdge(B3DPrimitiveEdge *edge)
{
	assert(edge);
	assert(edge->nLines);
	edge->xValue = edge->v0->windowPosX;
	edge->zValue = edge->v0->rasterPosZ;
	if(edge->nLines > 1) {
		edge->xIncrement = (edge->v1->windowPosX - edge->v0->windowPosX) / edge->nLines;
		edge->zIncrement = (edge->v1->rasterPosZ - edge->v0->rasterPosZ) / (float) edge->nLines;
	} else {
		edge->xIncrement = (edge->v1->windowPosX - edge->v0->windowPosX);
		edge->zIncrement = (edge->v1->rasterPosZ - edge->v0->rasterPosZ);
	}
}
/* --INLINE-- */


/*************************************************************/
/*************************************************************/
/*************************************************************/

/* b3dFirstIndexForInserting:
	Return the first possible index for inserting an edge with the given x value.
*/

int b3dFirstIndexForInserting(B3DPrimitiveEdgeList *list, int xValue)
{
	int low, high, index;
	low = 0;
	high = list->size-1;
	while(low <= high) {
		index = (low + high) >> 1;
		if(list->data[index]->xValue <= xValue)
			low = index+1;
		else
			high = index-1;
	}
	index = low;
	while(index > 0 && (list->data[index-1]->xValue) == xValue)
		index--;
	return index;
}

/* b3dAddEdgeBeforeIndex:
	Insert the edge to the list before the given index.
*/
/* INLINE b3dAddEdgeBeforeIndex(list, edge, index) */
void b3dAddEdgeBeforeIndex(B3DPrimitiveEdgeList *list, B3DPrimitiveEdge *edge, int index)
{
	int i;

	if(b3dDebug)
		if(list->size == list->max)
			b3dAbort("No more space for adding edges");

	assert( (list->size == index) || (list->data[index]->xValue >= edge->xValue));
	for(i=list->size-1; i >= index; i--)
		list->data[i+1] = list->data[i];
	list->data[index] = edge;
	list->size++;
}
/* --INLINE-- */

/* b3d2AddEdgesBeforeIndex:
	Insert the two edge to the list before the given index.
*/
/* INLINE b3dAdd2EdgesBeforeIndex(list, edge1, edge2, index) */
void b3dAdd2EdgesBeforeIndex(B3DPrimitiveEdgeList *list, 
							 B3DPrimitiveEdge *edge1, 
							 B3DPrimitiveEdge *edge2, 
							 int index)
{
	int i;

	if(b3dDebug)
		if(list->size+1 >= list->max)
			b3dAbort("No more space for adding edges");

	assert( edge1->xValue == edge2->xValue);
	assert( (list->size == index) || (list->data[index]->xValue >= edge1->xValue));

	for(i=list->size-1; i >= index; i--)
		list->data[i+2] = list->data[i];
	list->data[index] = edge1;
	list->data[index+1] = edge2;
	list->size += 2;
}
/* --INLINE-- */

/* b3dAdjustFaceEdges:
	Assign left and right edges to the given face.
*/
/* INLINE b3dAdjustFaceEdges(face, edge1, edge2) */
void b3dAdjustFaceEdges(B3DPrimitiveFace *face, B3DPrimitiveEdge *edge1, B3DPrimitiveEdge *edge2)
{
	assert(face);
	assert(edge1);
	assert(edge2);
	if(edge1->xValue == edge2->xValue) {
		if(edge1->xIncrement <= edge2->xIncrement) {
			face->leftEdge = edge1;
			face->rightEdge = edge2;
		} else {
			face->leftEdge = edge2;
			face->rightEdge = edge1;
		}
	} else {
		if(edge1->xValue <= edge2->xValue) {
			face->leftEdge = edge1;
			face->rightEdge = edge2;
		} else {
			face->leftEdge = edge2;
			face->rightEdge = edge1;
		}
	}
}
/* --INLINE-- */

/* b3dAddLowerEdgeFromFace:
	Add a new lower edge from the given face.
	NOTE: oldEdge may be NULL!
	NOTE: May cause allocation of one edge!
*/
B3DPrimitiveEdge *b3dAddLowerEdgeFromFace(B3DPrimitiveFace *face, B3DPrimitiveEdge *oldEdge)
{
	B3DPrimitiveVertex *v0 = face->v0;
	B3DPrimitiveVertex *v1 = face->v1;
	B3DPrimitiveVertex *v2 = face->v2;
	int xValue = v1->windowPosX;
	int index;

	/* Search the list of added edges to merge the edges from the face */
	index = b3dFirstIndexForInserting(addedEdges, xValue);
	for(;index<addedEdges->size; index++) {
		B3DPrimitiveEdge *edge = addedEdges->data[index];
		if(edge->xValue != xValue) break;
		if(edge->rightFace) continue;
		if((edge->v0 == v1 && edge->v1 == v2) || /* The simple test*/
			/* The complex test */
			(edge->v0->windowPosX == v1->windowPosX &&
			 edge->v0->windowPosY == v1->windowPosY &&
			 edge->v0->rasterPosZ == v1->rasterPosZ &&
			 edge->v1->windowPosX == v2->windowPosX &&
			 edge->v1->windowPosY == v2->windowPosY &&
			 edge->v1->rasterPosZ == v2->rasterPosZ)) {
			/* Found the edge */
			if(face->leftEdge == oldEdge)
				face->leftEdge = edge;
			else
				face->rightEdge = edge;
			edge->rightFace = face;
			return edge;
		}
	}
	/* Need to create a new edge.
	   NOTE: Index already points to the right insertion point.
	*/
	{
		B3DPrimitiveEdge *minorEdge;
		int nLines = (v2->windowPosY >> B3D_FixedToIntShift) - (v1->windowPosY >> B3D_FixedToIntShift);
		if(!nLines) return NULL; /* Edge is horizontal */
		b3dAllocEdge(edgeAlloc, minorEdge);

		if(b3dDebug)
			if(!minorEdge)
				b3dAbort("Edge allocation failed");

		minorEdge->v0 = v1;
		minorEdge->v1 = v2;
		minorEdge->nLines = nLines;
		minorEdge->leftFace = face;
		minorEdge->rightFace = NULL;
		if(face->leftEdge == oldEdge)
			face->leftEdge = minorEdge;
		else
			face->rightEdge = minorEdge;
		b3dInitializeEdge(minorEdge);
		b3dAddEdgeBeforeIndex(addedEdges, minorEdge, index);
		return minorEdge;
	}
	/* NOT REACHED */
}

/* b3dAddEdgesFromFace:
	Add the two new edges from the given primitive face.
	NOTE: May cause allocation of two edges (but not three)!
*/
void b3dAddEdgesFromFace(B3DPrimitiveFace *face, int yValue)
{
	int needMajor = 1;
	int needMinor = 1;
	B3DPrimitiveEdge *majorEdge = NULL;
	B3DPrimitiveEdge *minorEdge = NULL;
	B3DPrimitiveVertex *v0 = face->v0;
	B3DPrimitiveVertex *v1 = face->v1;
	B3DPrimitiveVertex *v2 = face->v2;
	int xValue = v0->windowPosX;
	int index;

	/* Search the list of added edges to merge the edges from the face */
	index = b3dFirstIndexForInserting(addedEdges, xValue);
	for(;index<addedEdges->size; index++) {
		B3DPrimitiveEdge *edge = addedEdges->data[index];
		if(edge->xValue != xValue) break;
		if(edge->rightFace) continue;
		if(edge->v0 != v0 &&
			(edge->v0->windowPosY != v0->windowPosY ||
			 edge->v0->rasterPosZ != v0->rasterPosZ)) continue;
		/* If we come to this point the edge might be usable for merging the face */
		if(needMajor && /* Test only if major edge is needed */
			(edge->v1 == v2 || /* Simple test */
			/* A more complex test */
			(edge->v1->windowPosX == v2->windowPosX &&
			 edge->v1->windowPosY == v2->windowPosY &&
			 edge->v1->rasterPosZ == v2->rasterPosZ))) {
			/* Yepp. That's the new major */
			majorEdge = edge;
			majorEdge->rightFace = face;
			majorEdge->flags  |= B3D_EDGE_RIGHT_MAJOR;
			
			if(b3dDoStats) nFaces++;

			if(!needMinor) {
				b3dAdjustFaceEdges(face, majorEdge, minorEdge);
				return; /* done */
			}
			needMajor = 0;
		} else if(needMinor && /* Test only if minor edge is needed */
			(edge->v1 == v1 || /* Simple test */
			/* A more complex test */
			(edge->v1->windowPosX == v1->windowPosX &&
			 edge->v1->windowPosY == v1->windowPosY &&
			 edge->v1->rasterPosZ == v1->rasterPosZ))) {
			/* Yepp. That's the new minor */
			minorEdge = edge;
			minorEdge->rightFace = face;
			minorEdge->flags |= B3D_EDGE_CONTINUE_RIGHT;
			if(!needMajor) {
				b3dAdjustFaceEdges(face, majorEdge, minorEdge);
				return; /* done */
			}
			needMinor = 0;
		}
	}
	/*  Need to create new edges.
		Note: index already points to the right insertion point in addedEdges 
	*/
	if(needMajor) {
		int nLines = (v2->windowPosY >> B3D_FixedToIntShift) - (v0->windowPosY >> B3D_FixedToIntShift);

		if(!nLines) {
			/* The major edge is horizontal. */
			b3dFreeFace(faceAlloc, face);
			return;
		}
		b3dAllocEdge(edgeAlloc, majorEdge);
		if(b3dDebug)
			if(!majorEdge) b3dAbort("Edge allocation failed");
		majorEdge->v0 = v0;
		majorEdge->v1 = v2;
		majorEdge->nLines = nLines;
		majorEdge->leftFace = face;
		majorEdge->rightFace = NULL;
		majorEdge->flags  |= B3D_EDGE_LEFT_MAJOR;
		b3dInitializeEdge(majorEdge);
		if(b3dDoStats) nFaces++;
	}

	if(needMinor) {
		int nLines = (v1->windowPosY >> B3D_FixedToIntShift) - (v0->windowPosY >> B3D_FixedToIntShift);

		if(!nLines) {
			/* Note: If the (upper) minor edge is horizontal, use the lower one.
			   Note: The lower edge cannot be horizontal if the major edge isn't
			*/
			if(needMajor) {
				b3dAddEdgeBeforeIndex(addedEdges, majorEdge, index);
			}
			minorEdge = b3dAddLowerEdgeFromFace(face,NULL);

			if(b3dDebug)
				if(!minorEdge || minorEdge->nLines == 0)
					b3dAbort("minor edge is horizontal");

			b3dAdjustFaceEdges(face, majorEdge, minorEdge);
			return;
		}

		b3dAllocEdge(edgeAlloc, minorEdge);

		if(b3dDebug)
			if(!minorEdge) b3dAbort("Edge allocation failed");

		minorEdge->v0 = v0;
		minorEdge->v1 = v1;
		minorEdge->nLines = nLines;
		minorEdge->leftFace = face;
		minorEdge->rightFace = NULL;
		minorEdge->flags  |= B3D_EDGE_CONTINUE_LEFT;
		b3dInitializeEdge(minorEdge);
	}

	/* Add the newly created edges to addedEdges */
	if(needMinor && needMajor) {
		b3dAdd2EdgesBeforeIndex(addedEdges, majorEdge, minorEdge, index);
	} else if(needMajor) {
		b3dAddEdgeBeforeIndex(addedEdges, majorEdge, index);
	} else {
		b3dAddEdgeBeforeIndex(addedEdges, minorEdge, index);
	}
	b3dAdjustFaceEdges(face, majorEdge, minorEdge);
}


/* b3dRemoveAETEdge:
	Remove the given edge from the AET.
	NOTE: May cause allocation of two edges!
*/
/* INLINE b3dRemoveAETEdge(aet, edge, yValue, aetPos) */
void b3dRemoveAETEdge(B3DActiveEdgeTable *aet, B3DPrimitiveEdge *edge, int yValue, int aetPos)
{
	/* Remove edge and add lower edges if necessary */
	int j;
	B3DPrimitiveEdge **aetData = aet->data;

	assert(aetData[aetPos] == edge);

	if(b3dDebug)
		if( (edge->v1->windowPosY >> B3D_FixedToIntShift) != yValue )
			b3dAbort("Edge exceeds range");

	/* Remove the edge and adjust the stuff */
	for(j=aetPos+1; j < aet->size; j++) aetData[j-1] = aetData[j];
	aet->size--;
	/* Add new lower edges */
	if(edge->flags & B3D_EDGE_CONTINUE_LEFT) {
		b3dAddLowerEdgeFromFace(edge->leftFace, edge);
	}
	if(edge->flags & B3D_EDGE_CONTINUE_RIGHT) {
		b3dAddLowerEdgeFromFace(edge->rightFace, edge);
	}
	if(edge->flags & B3D_EDGE_LEFT_MAJOR) {
		/* Free left face */
		b3dFreeAttrib(attrAlloc, edge->leftFace);
		b3dFreeFace(faceAlloc, edge->leftFace);
		if(b3dDoStats) nFaces--;
	}
	if(edge->flags & B3D_EDGE_RIGHT_MAJOR) {
		/* Free right face */
		b3dFreeAttrib(attrAlloc, edge->rightFace);
		b3dFreeFace(faceAlloc, edge->rightFace);
		if(b3dDoStats) nFaces--;
	}
	/* And free old edge */
	b3dFreeEdge(edgeAlloc, edge);
}
/* --INLINE-- */

/* b3dMergeAETEdgesFrom:
	Merge the edges from the given source into the AET.
*/
void b3dMergeAETEdgesFrom(B3DActiveEdgeTable *aet, B3DPrimitiveEdgeList *src)
{
	int srcIndex, aetIndex, outIndex, i;
	B3DPrimitiveEdge *srcEdge, *aetEdge;

	assert(aet);
	assert(src);
	assert(src->size);
	assert(aet->size + src->size <= aet->max);

	if(!aet->size) {
		for(i=0; i<src->size; i++) aet->data[i] = src->data[i];
		aet->size += src->size;
		return;
	}

	/* Merge the input by stepping backwards through the aet and checking each edge */
	outIndex = aet->size + src->size - 1;
	srcIndex = src->size-1;
	aetIndex = aet->size-1;
	srcEdge = src->data[srcIndex];
	aetEdge = aet->data[aetIndex];
	aet->size += src->size;
	while(1) {
		if(srcEdge->xValue >= aetEdge->xValue) {
			/* output srcEdge */
			aet->data[outIndex--] = srcEdge;
			if(!srcIndex--) return;
			srcEdge = src->data[srcIndex];
		} else {
			/* output aetEdge */
			aet->data[outIndex--] = aetEdge;
			if(!aetIndex--) {
				for(i=0; i <= srcIndex; i++) aet->data[i] = src->data[i];
				return;
			}
			aetEdge = aet->data[aetIndex];
		}
	}
}

/* INLINE b3dAdvanceAETEdge(edge, aetData, aetStart) */
void b3dAdvanceAETEdge(B3DPrimitiveEdge *edge,
					B3DPrimitiveEdge **aetData,
					int aetStart)
{
	/* Advance to next scan line */
	edge->zValue += edge->zIncrement;
	edge->xValue += edge->xIncrement;
	/* Check if AET sort order is okay */
	if(aetStart && aetData[aetStart-1]->xValue > edge->xValue) {
		/* Must resort rightEdge */
		int xValue = edge->xValue;
		int j = aetStart;
		/* Move the edge left */
		while(j>0 && aetData[j-1]->xValue > xValue) {
			aetData[j] = aetData[j-1];
			j--;
		}
		aetData[j] = edge;
	}
}
/* --INLINE-- */

/*************************************************************/
/*************************************************************/
/*************************************************************/
#ifdef DEBUG
double zValueAt(B3DPrimitiveFace *face, double xValue, double yValue)
{
	return 
		(face->v0->rasterPosZ +
			(((double)xValue - face->v0->rasterPosX) * face->dzdx) +
			(((double)yValue - face->v0->rasterPosY) * face->dzdy));
}
#else
#define zValueAt(face, xValue, yValue) \
		((face)->v0->rasterPosZ + \
			(((double)(xValue) - (face)->v0->rasterPosX) * (face)->dzdx) +\
			(((double)(yValue) - (face)->v0->rasterPosY) * (face)->dzdy))
#endif

/*************************************************************/
/*************************************************************/
/*************************************************************/

int b3dComputeIntersection(B3DPrimitiveFace *frontFace, 
						   B3DPrimitiveFace *backFace, 
						   int yValue, 
						   int errorValue)
{
	double dx1 = frontFace->rightEdge->xValue - frontFace->leftEdge->xValue;
	double dz1 = frontFace->rightEdge->zValue - frontFace->leftEdge->zValue;
	double dx2 = backFace->rightEdge->xValue - backFace->leftEdge->xValue;
	double dz2 = backFace->rightEdge->zValue - backFace->leftEdge->zValue;
	double px = backFace->leftEdge->xValue - frontFace->leftEdge->xValue;
	double pz = backFace->leftEdge->zValue - frontFace->leftEdge->zValue;
	double det = (dx1 * dz2) - (dx2 * dz1);
	if(det == 0.0) return errorValue;
	{ 
		double det2 = ((px * dz2) - (pz * dx2)) / det;
		return frontFace->leftEdge->xValue + (int)(dx1 * det2);
	}
	/* not reached */
}

/* b3dCheckIntersectionOfFaces:
	Compute the possible intersection of frontFace and backFace.
	Store the result in nextIntersection if it is before any other
	intersection. Return true if other intersections tests should
	be performed, false otherwise.
*/
int b3dCheckIntersectionOfFaces(B3DPrimitiveFace *frontFace,
								 B3DPrimitiveFace *backFace,
								 int yValue,
								 B3DPrimitiveEdge *leftEdge,
								 B3DPrimitiveEdge *nextIntersection)
{
	double frontZ, backZ;
	int xValue, rightX;

	/* Check if the backFace is completely behind the front face */
	if(backFace->minZ >= frontFace->maxZ) return 0; /* abort */

	/* Check if front and back face share any edges */
	if(frontFace->leftEdge == backFace->leftEdge) return 1; /* proceed */
	if(frontFace->rightEdge == backFace->rightEdge) return 1; /* proceed */

	/* Check if either front or back face are less than 1 pixel wide */
	if( (frontFace->leftEdge->xValue >> B3D_FixedToIntShift) ==
		(frontFace->rightEdge->xValue >> B3D_FixedToIntShift)) return 0; /* abort */
	if( (backFace->leftEdge->xValue >> B3D_FixedToIntShift) ==
		(backFace->rightEdge->xValue >> B3D_FixedToIntShift)) return 1; /* proceed */

	/* Choose the right x value of either front or back face,
		whichever is less (this is so we sample inside both faces) */
	if(frontFace->rightEdge->xValue <= backFace->rightEdge->xValue) {
		rightX = frontFace->rightEdge->xValue;
		frontZ = frontFace->rightEdge->zValue;
		backZ = zValueAt(backFace, rightX * B3D_FixedToFloat, yValue);
	} else {
		rightX = backFace->rightEdge->xValue;
		backZ = backFace->rightEdge->zValue;
		frontZ = zValueAt(frontFace, rightX * B3D_FixedToFloat, yValue);
	}

	if(backZ < frontZ) {
		/* possible intersection found */
		xValue = b3dComputeIntersection(frontFace, backFace, yValue, leftEdge->xValue);
		if(xValue > rightX) xValue = rightX;
		/* Ignore intersections at or before the leftEdge's x value. Important. */
		if((xValue >> B3D_FixedToIntShift) <= (leftEdge->xValue >> B3D_FixedToIntShift))
			xValue = ((leftEdge->xValue >> B3D_FixedToIntShift) + 1) << B3D_IntToFixedShift;
		if(xValue < nextIntersection->xValue) {
			nextIntersection->xValue = xValue;
			nextIntersection->leftFace = frontFace;
			nextIntersection->rightFace = backFace;
		}
	}
	return 1;
}

/* b3dAdjustIntersections:
	Compute the possible intersections of the current front face
	with all active faces. Store the next intersection if any.
*/
/* INLINE b3dAdjustIntersections(fillList, yValue, topEdge, nextIntersection) */
void b3dAdjustIntersections(B3DFillList *fillList,
							int yValue,
							B3DPrimitiveEdge *topEdge,
							B3DPrimitiveEdge *nextIntersection)
{
	B3DPrimitiveFace *frontFace = fillList->firstFace;
	if(frontFace) {
		B3DPrimitiveFace *backFace = frontFace->nextFace;
		int proceed = 1;
		while(backFace && proceed) {
			proceed = b3dCheckIntersectionOfFaces(frontFace, backFace, yValue, topEdge, nextIntersection);
			backFace = backFace->nextFace;
		}
	}
}
/* --INLINE-- */

/*************************************************************/
/*************************************************************/
/*************************************************************/

void b3dValidateFillList(B3DFillList *list)
{
	B3DPrimitiveFace *firstFace = list->firstFace;
	B3DPrimitiveFace *lastFace = list->lastFace;
	B3DPrimitiveFace *face;

	if(!firstFace && !lastFace) return;
	if(firstFace->prevFace)
		b3dAbort("Bad fill list");
	if(lastFace->nextFace)
		b3dAbort("Bad fill list");
	face = firstFace;
	while(face != lastFace)
		face = face->nextFace;
	/* Validate sort order */
	if(firstFace == lastFace)
		return; /* 0 or 1 element */
	face = firstFace->nextFace;
	while(face->nextFace) {
		if(face->minZ > face->nextFace->minZ)
			b3dAbort("Fill list sorting problem");
		face = face->nextFace;
	}
}

/* INLINE b3dAddFirstFill(fillList, aFace) */
void b3dAddFirstFill(B3DFillList *fillList, B3DPrimitiveFace *aFace)
{
	B3DPrimitiveFace *firstFace = fillList->firstFace;
	if(firstFace)
		firstFace->prevFace = aFace;
	else
		fillList->lastFace = aFace;
	aFace->nextFace = firstFace;
	aFace->prevFace = NULL;
	fillList->firstFace = aFace;
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dAddLastFill(fillList, aFace) */
void b3dAddLastFill(B3DFillList *fillList, B3DPrimitiveFace *aFace)
{
	B3DPrimitiveFace *lastFace = fillList->lastFace;
	if(lastFace)
		lastFace->nextFace = aFace;
	else
		fillList->firstFace = aFace;
	aFace->prevFace = lastFace;
	aFace->nextFace = NULL;
	fillList->lastFace = aFace;
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dRemoveFill(fillList, aFace) */
void b3dRemoveFill(B3DFillList *fillList, B3DPrimitiveFace *aFace)
{
	if(b3dDebug) b3dValidateFillList(fillList);
	if(aFace->prevFace)
		aFace->prevFace->nextFace = aFace->nextFace;
	else
		fillList->firstFace = aFace->nextFace;
	if(aFace->nextFace)
		aFace->nextFace->prevFace = aFace->prevFace;
	else
		fillList->lastFace = aFace->prevFace;
}
/* --INLINE-- */

/* INLINE b3dInsertBeforeFill(fillList, aFace, otherFace) */
void b3dInsertBeforeFill(B3DFillList *fillList, B3DPrimitiveFace *aFace, B3DPrimitiveFace *otherFace)
{
	assert(otherFace != fillList->firstFace);

	aFace->nextFace = otherFace;
	aFace->prevFace = otherFace->prevFace;
	aFace->prevFace->nextFace = aFace;
	otherFace->prevFace = aFace;
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dAddFrontFill(fillList, aFace) */
void b3dAddFrontFill(B3DFillList *fillList, B3DPrimitiveFace *aFace)
{
	B3DPrimitiveFace *firstFace = fillList->firstFace;
	if(firstFace != fillList->lastFace) {
		/* Meaning that we must find the new position for the old front face */
		B3DPrimitiveFace *backFace = firstFace->nextFace;
		float minZ = firstFace->minZ;

		while(backFace && backFace->minZ < minZ)
			backFace = backFace->nextFace;

		/* Insert firstFace before backFace */
		if(firstFace->nextFace != backFace) {
			B3DPrimitiveFace *tempFace = firstFace;

			b3dRemoveFill(fillList, tempFace);
			if(backFace) {
				b3dInsertBeforeFill(fillList, tempFace, backFace);
			} else {
				b3dAddLastFill(fillList, tempFace);
			}
		}
	}
	b3dAddFirstFill(fillList, aFace);
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dAddBackFill(fillList, aFace) */
void b3dAddBackFill(B3DFillList *fillList, B3DPrimitiveFace *aFace)
{
	B3DPrimitiveFace *firstFace = fillList->firstFace;
	B3DPrimitiveFace *lastFace = fillList->lastFace;
	B3DPrimitiveFace *face;
	float minZ = aFace->minZ;

	assert(firstFace);

	if(firstFace == lastFace || minZ >= lastFace->minZ) {
		b3dAddLastFill(fillList, aFace);
	} else {
		/* Try an estimation on how to search */
		if(minZ <= (firstFace->minZ + lastFace->minZ) * 0.5) {
			/* search front to back */
			face = firstFace->nextFace;
			while(face->minZ < minZ) face = face->nextFace;
		} else {
			/* search back to front */
			face = lastFace->prevFace; /* already checked if lastFace->minZ <= minZ */
			while(face->minZ > minZ) face = face->prevFace;
			face = face->nextFace;
		}
		b3dInsertBeforeFill(fillList, aFace, face);
	}
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dCleanupFill(fillList) */
void b3dCleanupFill(B3DFillList *fillList)
{
	B3DPrimitiveFace *firstFace = fillList->firstFace;

	while(firstFace) {
		firstFace->flags ^= B3D_FACE_ACTIVE;
		firstFace = firstFace->nextFace;
	}
	fillList->firstFace = fillList->lastFace = NULL;
}
/* --INLINE-- */

void b3dSearchForNewTopFill(B3DFillList *fillList, int scaledX, int yValue)
{
	B3DPrimitiveFace *topFace = fillList->firstFace;

	if(b3dDebug) b3dValidateFillList(fillList);
	if(topFace) { /* only if there is any */
		B3DPrimitiveFace *face = topFace->nextFace;
		double xValue = scaledX * B3D_FixedToFloat;
		double topZ = zValueAt(topFace, xValue, yValue);

		/* Note: since the list is ordered we need only to search until face->minZ >= topZ */
		while(face && face->minZ <= topZ) {
			double faceZ = zValueAt(face, xValue, yValue);
			if(faceZ < topZ) {
				topZ = faceZ;
				topFace = face;
			}
			face = face->nextFace;
		}
		/* and move the guy to front */
		b3dRemoveFill(fillList, topFace);
		b3dAddFrontFill(fillList, topFace);
	}
}

/* INLINE b3dToggleTopFills(fillList, edge, yValue) */
void b3dToggleTopFills(B3DFillList *fillList, B3DPrimitiveEdge *edge, int yValue)
{
	B3DPrimitiveFace *leftFace = edge->leftFace;
	B3DPrimitiveFace *rightFace = edge->rightFace;
	if(b3dDebug) b3dValidateFillList(fillList);
	assert(leftFace != rightFace);
	if(rightFace) {
		int xorMask = leftFace->flags ^ rightFace->flags;
		if(xorMask & B3D_FACE_ACTIVE) {
			if(leftFace->flags & B3D_FACE_ACTIVE) {
				b3dRemoveFill(fillList, leftFace);
				b3dAddFrontFill(fillList, rightFace);
			} else {
				b3dRemoveFill(fillList, rightFace);
				b3dAddFrontFill(fillList, leftFace);
			}
		} else {
			if(leftFace->flags & B3D_FACE_ACTIVE) {
				b3dRemoveFill(fillList, leftFace);
				b3dRemoveFill(fillList, rightFace);
				b3dSearchForNewTopFill(fillList, edge->xValue, yValue);
			} else {
				if(leftFace->dzdx <= rightFace->dzdx) {
					b3dAddFrontFill(fillList, leftFace);
					b3dAddBackFill(fillList, rightFace);
				} else {
					b3dAddFrontFill(fillList, rightFace);
					b3dAddBackFill(fillList, leftFace);
				}
			}
		}
		leftFace->flags ^= B3D_FACE_ACTIVE;
		rightFace->flags ^= B3D_FACE_ACTIVE;
	} else {
		if(leftFace->flags & B3D_FACE_ACTIVE) {
			b3dRemoveFill(fillList, leftFace);
			b3dSearchForNewTopFill(fillList, edge->xValue, yValue);
		} else {
			b3dAddFrontFill(fillList, leftFace);
		}
		leftFace->flags ^= B3D_FACE_ACTIVE;
	}
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/* INLINE b3dToggleBackFills(fillList, edge, yValue, nextIntersection) */
void b3dToggleBackFills(B3DFillList *fillList, 
						B3DPrimitiveEdge *edge, 
						int yValue,
						B3DPrimitiveEdge *nextIntersection)
{
	B3DPrimitiveFace *face = edge->leftFace;
	if(b3dDebug) b3dValidateFillList(fillList);
	if(face->flags & B3D_FACE_ACTIVE) {
		b3dRemoveFill(fillList, face);
	} else {
		b3dAddBackFill(fillList, face);
		b3dCheckIntersectionOfFaces(fillList->firstFace, face, yValue, edge, nextIntersection);
	}
	face->flags ^= B3D_FACE_ACTIVE;
	face = edge->rightFace;
	if(face) {
		if(face->flags & B3D_FACE_ACTIVE) {
			b3dRemoveFill(fillList, face);
		} else {
			b3dAddBackFill(fillList, face);
			b3dCheckIntersectionOfFaces(fillList->firstFace, face, yValue, edge, nextIntersection);
		}
		face->flags ^= B3D_FACE_ACTIVE;
	}
	if(b3dDebug) b3dValidateFillList(fillList);
}
/* --INLINE-- */

/*************************************************************/
/*************************************************************/
/*************************************************************/

/* INLINE b3dClearSpanBuffer(aet) */
void b3dClearSpanBuffer(B3DActiveEdgeTable *aet)
{
	int i, leftX, rightX;
	unsigned int *buffer = currentState->spanBuffer;
	if(aet->size && buffer) {
		leftX = aet->data[0]->xValue >> B3D_FixedToIntShift;
		rightX = aet->data[aet->size-1]->xValue >> B3D_FixedToIntShift;
		if(leftX < 0) leftX = 0;
		if(rightX >= currentState->spanSize) rightX = currentState->spanSize-1;
		for(i=leftX;i<=rightX;i++) buffer[i] = 0;
	}
}
/* --INLINE-- */

/* INLINE b3dDrawSpanBuffer(aet, yValue) */
void b3dDrawSpanBuffer(B3DActiveEdgeTable *aet, int yValue)
{
	int leftX, rightX;
	if(aet->size && currentState->spanDrawer) {
		leftX = aet->data[0]->xValue >> B3D_FixedToIntShift;
		rightX = aet->data[aet->size-1]->xValue >> B3D_FixedToIntShift;
		if(leftX < 0) leftX = 0;
		if(rightX > currentState->spanSize) rightX = currentState->spanSize;
		currentState->spanDrawer(leftX, rightX, yValue);
	}
}
/* --INLINE-- */

/*************************************************************/
/*************************************************************/
/*************************************************************/
/* General failure */
#define FAIL(reason,resume) { aet->yValue = yValue; return reason | resume; }
#define PROCEED { yValue = aet->yValue; }

/* Failure adding objects */
#define FAIL_ADDING(reason) { obj->start = objStart; FAIL(reason, B3D_RESUME_ADDING) }
#define PROCEED_ADDING { objStart = obj->start; PROCEED }

/* Failure merging objects */
#define FAIL_MERGING(reason) { FAIL(reason, B3D_RESUME_MERGING); }
#define PROCEED_MERGING { PROCEED }

/* Failure during paint */
#define FAIL_PAINTING(reason) { aet->start = aetStart; aet->leftEdge = leftEdge; aet->rightEdge = rightEdge; FAIL(reason, B3D_RESUME_PAINTING) }
#define PROCEED_PAINTING(reason) { aetStart = aet->start; leftEdge = aet->leftEdge; rightEdge = aet->rightEdge; PROCEED }

#define FAIL_UPDATING(reason)

int b3dMainLoop(B3DRasterizerState *state, int stopReason)
{
	B3DPrimitiveObject *activeStart, *passiveStart;
	int yValue, nextObjY, nextEdgeY;
	B3DFillList *fillList;
	B3DPrimitiveEdge *lastIntersection, *nextIntersection;


	if(!state)
		return B3D_GENERIC_ERROR;

	if(!state->nObjects)
		return B3D_NO_ERROR;

	if(b3dValidateAndRemapState(state) != B3D_NO_ERROR)
		return B3D_GENERIC_ERROR;

	if(stopReason == B3D_NO_ERROR)
		if(b3dSetupObjects(state) != B3D_NO_ERROR)
			return B3D_GENERIC_ERROR;

	if(b3dDebug) {
		/* check the sort order of objects */
		int i;
		for(i=2; i<state->nObjects;i++)
			if(!objSortsBefore(state->objects[i-1], state->objects[i]))
				b3dAbort("Objects not sorted");
	}

	currentState = state;
	faceAlloc = state->faceAlloc;
	edgeAlloc = state->edgeAlloc;
	attrAlloc = state->attrAlloc;
	addedEdges = state->addedEdges;
	fillList = state->fillList;
	aet = state->aet;
	nextIntersection = aet->nextIntersection;
	lastIntersection = aet->lastIntersection;

	if(b3dDoStats) nFaces = 0;

	if(stopReason == B3D_NO_ERROR) {
		activeStart = passiveStart = state->objects[0];
		yValue = nextEdgeY = nextObjY = passiveStart->minY;
	} else {
		int resumeCode;
		resumeCode = stopReason & B3D_RESUME_MASK;
		if(resumeCode == B3D_RESUME_ADDING  ) goto RESUME_ADDING;
		if(resumeCode == B3D_RESUME_MERGING ) goto RESUME_MERGING;
		if(resumeCode == B3D_RESUME_PAINTING) goto RESUME_PAINTING;
		if(resumeCode == B3D_RESUME_UPDATING) goto RESUME_UPDATING;
		return B3D_GENERIC_ERROR;
	}

	/**** BEGIN MAINLOOP ****/
	while(activeStart || passiveStart || aet->size) {

RESUME_ADDING:

		/* STEP 1: Add new objects if necessary */
		if(yValue == nextObjY) {
			nextEdgeY = nextObjY;
			while(passiveStart && passiveStart->minY == nextObjY) {
				passiveStart->flags |= B3D_OBJECT_ACTIVE;
				passiveStart = passiveStart->next;
			}
			if(passiveStart)
				nextObjY = passiveStart->minY;
			else
				nextObjY = 99999;
		} /* End of adding objects */



		/* STEP 2: Add new edges if necessary */
		if(yValue == nextEdgeY) {
			B3DPrimitiveObject *obj = activeStart;
			int scaledY = (yValue+1) << B3D_IntToFixedShift;

			nextEdgeY = nextObjY << B3D_IntToFixedShift;
			while(obj != passiveStart) {
				B3DInputFace *objFaces = obj->faces;
				B3DPrimitiveVertex *objVtx = obj->vertices;
				int objStart = obj->start;
				int objSize = obj->nFaces;
				int tempY;

				assert(obj->flags & B3D_OBJECT_ACTIVE);

				while(objStart < objSize && ((tempY = objVtx[objFaces[objStart].i0].windowPosY) < scaledY)) {
					/* add edges from face at objFaces[objStart] */
					B3DInputFace *inputFace = objFaces + objStart;
					B3DPrimitiveFace *face;

					/* NOTE: If any of the following fails, 
					         we can re-enter the main loop later on. */

					if(faceAlloc->nFree == 0)
						FAIL_ADDING(B3D_NO_MORE_FACES);
					
					if(edgeAlloc->nFree < 2)
						FAIL_ADDING(B3D_NO_MORE_EDGES);

					if(addedEdges->size+2 > addedEdges->max)
						FAIL_ADDING(B3D_NO_MORE_ADDED);

					/* Allocate a new face and do the initial setup */
					face = b3dInitializeFace(objVtx + inputFace->i0, 
											 objVtx + inputFace->i1,
											 objVtx + inputFace->i2,
											 obj->texture,
											 obj->flags);
					if(face) {
						b3dAddEdgesFromFace(face, yValue);
					}
					objStart++;
				}

				obj->start = objStart;
				if(objStart != objSize) {
					if(tempY < nextEdgeY) nextEdgeY = tempY;
				} else {
					/* Unlink obj from activeStart list */
					obj->flags |= B3D_OBJECT_DONE;
					if(obj == activeStart) {
						activeStart = obj->next;
					} else {
						obj->prev->next = obj->next;
					}
				}
				obj = obj->next;
			}

			nextEdgeY >>= B3D_FixedToIntShift;
		} /* End of adding edges */


		/* STEP 3: Merge all newly added edges from addedList into the AET */
		if(addedEdges->size) {
RESUME_MERGING:
			if(b3dDebug)
				b3dValidateEdgeOrder(addedEdges);
			/* NOTE: If the following fails, we can re-enter the main loop later on. */
			if(aet->size + addedEdges->size > aet->max)
				FAIL_MERGING(B3D_NO_MORE_AET);
			b3dMergeAETEdgesFrom(aet, addedEdges);
			if(b3dDebug) {
				b3dValidateAETOrder(aet);
			}
			addedEdges->size = 0; /* reset added */
		} /* End of merging edges */


		/********** THIS IS THE CORE LOOP ********/
		/* while(yValue < nextEdgeY && !addedEdges->size && aet->size) { */

			if(b3dDoStats) {
				/* Gather stats */
				if(aet->size > maxEdges) maxEdges = aet->size;
				if(nFaces > maxFaces) maxFaces = nFaces;
			}

			/* STEP 4: Draw the current span */

			/* STEP 4a: Clear the span buffer */
			b3dClearSpanBuffer(aet);

			/* STEP 4b: Scan out the AET */
			if(aet->size) {
				B3DPrimitiveEdge *leftEdge;
				B3DPrimitiveEdge *rightEdge;
				B3DPrimitiveEdge **aetData = aet->data;
				int aetStart = 1;
				int aetSize = aet->size;

				/* clean up old fills if any */
				b3dCleanupFill(fillList);

				nextIntersection->xValue = B3D_MAX_X;
				leftEdge = aetData[0];
				while(aetStart < aetSize) {

					/*-- Toggle the faces of the top edge (the left edge is always on top) --*/
					if(leftEdge == lastIntersection) {
						/* Special case if this is a intersection edge */
						assert(fillList->firstFace == leftEdge->leftFace);
						b3dRemoveFill(fillList, leftEdge->rightFace);
						b3dAddFrontFill(fillList, leftEdge->rightFace);
					} else {
						b3dToggleTopFills(fillList, leftEdge, yValue);
					}
					/*-- end of toggling top edge faces --*/

					/* after getting a new top fill we must adjust intersections */
					b3dAdjustIntersections(fillList, yValue, leftEdge, nextIntersection);

					/*-- search for the next top edge which will be the right edge --*/
					assert(aetStart < aetSize);
					if(!fillList->firstFace)
						rightEdge = aetData[aetStart++]; /* If no current top fill just use the next edge */
					else while(aetStart < aetSize) { /* Search for the next top edge in the AET */
						rightEdge = aetData[aetStart];
						/* If we have an intersection use the intersection edge */
						if(nextIntersection->xValue <= rightEdge->xValue) {
							rightEdge = nextIntersection;
							break;
						}
						aetStart++;
						/* Check if this edge is on top */
						assert(fillList->firstFace);
						{
							double xValue = rightEdge->xValue * B3D_FixedToFloat;
							B3DPrimitiveFace *topFace = fillList->firstFace;
							if( rightEdge->leftFace == topFace || 
								rightEdge->rightFace == topFace || 
								rightEdge->zValue < zValueAt(topFace, xValue, yValue))
								break; /* rightEdge is on top */
						}
						/* If the edge is not on top toggle its (back) fills */
						b3dToggleBackFills(fillList, rightEdge, yValue, nextIntersection);
						rightEdge = NULL;
					}
					/*-- end of search for next top edge --*/

					/*-- Now do the drawing from leftEdge to rightEdge --*/
					assert(rightEdge);
					if(fillList->firstFace) {
						/* Note: We fill *including* leftX and rightX */
						int leftX = (leftEdge->xValue >> B3D_FixedToIntShift) + 1;
						int rightX = (rightEdge->xValue >> B3D_FixedToIntShift);
						B3DPrimitiveFace *topFace = fillList->firstFace;

						if(leftX < 0) leftX = 0;
						if(rightX >= currentState->spanSize) rightX = currentState->spanSize-1;
						if(leftX <= rightX) {
							/* Since we know now that some serious filling operation
							   will happen, initialize the attributes of the face if
							   this hasn't been done before. */
RESUME_PAINTING:
							if( (topFace->flags & B3D_FACE_INITIALIZED) == 0) {
								assert(topFace->attributes == NULL);
								if(!b3dInitializePass2(topFace))
									FAIL_PAINTING(B3D_NO_MORE_ATTRS);
							}
							/* And dispatch on the actual pixel drawers */
							(*B3D_FILL_FUNCTIONS[(topFace->flags >> B3D_ATTR_SHIFT) & B3D_ATTR_MASK])
								(leftX, rightX, yValue, topFace);
						}
					}
					/*-- End of drawing -- */

					/* prepare for new top edge */
					leftEdge = rightEdge;
					/* use a new intersection if necessary */
					if(leftEdge == nextIntersection) {
						nextIntersection = lastIntersection;
						lastIntersection = leftEdge;
					}
					nextIntersection->xValue = B3D_MAX_X;
				}
				/* clean up old fills if any */
				b3dCleanupFill(fillList);
			}

			/* STEP 4c: Display the pixels from the span buffer */
			b3dDrawSpanBuffer(aet, yValue);

			/* STEP 5: Go to next y value and update AET entries */
			yValue++;
			if(aet->size) {
				int aetStart = 0;
				int aetSize = aet->size;
				B3DPrimitiveEdge **aetData = aet->data;

				aetStart = 0;
				while(aetStart < aetSize) {
					B3DPrimitiveEdge *edge = aetData[aetStart];

					if(--(edge->nLines)) {
						/* Advance to next scan line and resort edge */
						b3dAdvanceAETEdge(edge, aetData, aetStart);
						aetStart++;
					} else {
						/* Remove edge and add lower edges if necessary */
RESUME_UPDATING:
						if(edgeAlloc->nFree < 2)
							FAIL_UPDATING(B3D_NO_MORE_EDGES);
						if(addedEdges->size + 2 > addedEdges->max)
							FAIL_UPDATING(B3D_NO_MORE_ADDED);
						b3dRemoveAETEdge(aet, edge, yValue, aetStart);
						aetSize = aet->size;
						/* Do NOT advance aetStart here */
					}
				}
			}
			/* End of AET update */
			if(b3dDebug) {
				b3dValidateAETOrder(aet);
			}

		/*}*/ /******** END OF CORE LOOP ********/

	}  /**** END MAINLOOP ****/

	return B3D_NO_ERROR;
}
