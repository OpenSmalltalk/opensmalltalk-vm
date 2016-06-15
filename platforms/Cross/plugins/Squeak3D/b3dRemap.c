/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dRemap.c
*   CONTENT: Remapping functions for the B3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3dRemap.c,v 1.1 2001/10/24 23:12:24 rowledge Exp $
*
*   NOTES:
*
*
*****************************************************************************/
#include "b3d.h"

/* b3dRemapFaces:
	Remap all allocated faces using the given offsets
*/
/* INLINE b3dRemapFaces(list, attrOffset, edgeOffset) */
void b3dRemapFaces(B3DFaceAllocList *list, int attrOffset, int edgeOffset)
{
	int i;

	for(i=0; i<list->size;i++) {
		B3DPrimitiveFace *face = list->data + i;
		if(face->flags & B3D_ALLOC_FLAG) {
			if(face->attributes)
				face->attributes = (B3DPrimitiveAttribute*)((char*)face->attributes + attrOffset);
			if(face->leftEdge)
				face->leftEdge = (B3DPrimitiveEdge*)((char*)face->leftEdge + edgeOffset);
			if(face->rightEdge)
				face->rightEdge = (B3DPrimitiveEdge*)((char*)face->rightEdge + edgeOffset);
		}
	}
}
/* --INLINE-- */

/* b3dRemapEdges:
	Remap all allocated edges using the given offset
*/
/* INLINE b3dRemapEdges(list, faceOffset) */
void b3dRemapEdges(B3DEdgeAllocList *list, int faceOffset)
{
	int i;
	for(i=0; i<list->size;i++) {
		B3DPrimitiveEdge *edge = list->data + i;
		if(edge->flags & B3D_ALLOC_FLAG) {
			if(edge->leftFace)
				edge->leftFace = (B3DPrimitiveFace*)((char*)edge->leftFace + faceOffset);
			if(edge->rightFace)
				edge->rightFace  = (B3DPrimitiveFace*)((char*)edge->rightFace + faceOffset);
		}
	}
}
/* --INLINE-- */

/* b3dRemapFills:
	Remap the fill list using the given offset
*/
/* INLINE b3dRemapFills(fillList, offset) */
void b3dRemapFills(B3DFillList *fillList, int offset)
{
	B3DPrimitiveFace *temp;
	if(fillList->firstFace)
		fillList->firstFace = (B3DPrimitiveFace *)((char*)fillList->firstFace + offset);
	if(fillList->lastFace)
		fillList->lastFace = (B3DPrimitiveFace *)((char*)fillList->lastFace  + offset);
	temp = fillList->firstFace;
	while(temp) {
		if(temp->nextFace)
			temp->nextFace = (B3DPrimitiveFace *)((char*)temp->nextFace + offset);
		if(temp->prevFace)
			temp->prevFace = (B3DPrimitiveFace *)((char*)temp->prevFace + offset);
		temp = temp->nextFace;
	}
}
/* --INLINE-- */

/* b3dRemapEdgeList:
	Remap all edge pointers using the given offset
*/
/* INLINE b3dRemapEdgeList(list, edgeOffset) */
void b3dRemapEdgeList(B3DPrimitiveEdgeList *list, int edgeOffset)
{
	int i;
	for(i=0; i<list->size;i++) {
		list->data[i] = (B3DPrimitiveEdge *)((char*) list->data[i] + edgeOffset);
	}
}
/* --INLINE-- */

/* b3dRemapAET:
	Remap all edge pointers using the given offset
*/
/* INLINE b3dRemapAET(list, edgeOffset, aetOffset, firstEdge, lastEdge) */
void b3dRemapAET(B3DActiveEdgeTable *list, int edgeOffset, int aetOffset, void *firstEdge, void *lastEdge)
{
	int i;
	if(edgeOffset)
		for(i=0; i<list->size;i++)
			list->data[i] = (B3DPrimitiveEdge *)((char*) list->data[i] + edgeOffset);

	if((void*)list->leftEdge >= firstEdge && (void*)list->leftEdge < lastEdge)
		list->leftEdge = (B3DPrimitiveEdge *)((char*) list->leftEdge + edgeOffset);
	else if(list->leftEdge)
		list->leftEdge = (B3DPrimitiveEdge *)((char*) list->leftEdge + aetOffset);

	if((void*)list->rightEdge >= firstEdge && (void*)list->rightEdge < lastEdge)
		list->rightEdge = (B3DPrimitiveEdge *)((char*) list->rightEdge + edgeOffset);
	else if(list->rightEdge)
		list->rightEdge = (B3DPrimitiveEdge *)((char*) list->rightEdge + aetOffset);

	if(aetOffset) {
		list->nextIntersection = (B3DPrimitiveEdge *)((char*) list->nextIntersection + aetOffset);
		list->lastIntersection = (B3DPrimitiveEdge *)((char*) list->lastIntersection + aetOffset);
	}
}
/* --INLINE-- */

/* b3dRemapEdgeVertices:
	Remap all vertices in the specified range using the given offset
*/
/* INLINE b3dRemapEdgeVertices(list, vtxOffset, firstVtx, lastVtx) */
void b3dRemapEdgeVertices(B3DEdgeAllocList *list, int vtxOffset, void *firstVtx, void *lastVtx)
{
	int i;
	for(i=0; i<list->size; i++) {
		B3DPrimitiveEdge *edge = list->data + i;
		if((edge->flags & B3D_ALLOC_FLAG) && ((void*)edge->v0 >= (void*)firstVtx) && ((void*)edge->v0 < (void*)lastVtx)) {
			edge->v0 = (B3DPrimitiveVertex *)((char*) edge->v0 + vtxOffset);
			 edge->v1 = (B3DPrimitiveVertex *)((char*) edge->v1 + vtxOffset);
		}
	}
}
/* --INLINE-- */

/* b3dRemapFaceVertices:
	Remap all vertices in the specified range using the given offset
*/
/* INLINE b3dRemapFaceVertices(list, vtxOffset, firstVtx, lastVtx) */
void b3dRemapFaceVertices(B3DFaceAllocList *list, int vtxOffset, void *firstVtx, void *lastVtx)
{
	int i;
	for(i=0; i<list->size; i++) {
		B3DPrimitiveFace *face = list->data + i;
		if((face->flags & B3D_ALLOC_FLAG) && ((void*)face->v0 >= (void*)firstVtx) && ((void*)face->v0 < (void*)lastVtx)) {
			face->v0 = (B3DPrimitiveVertex *)((char*) face->v0 + vtxOffset);
			face->v1 = (B3DPrimitiveVertex *)((char*) face->v1 + vtxOffset);
			face->v2 = (B3DPrimitiveVertex *)((char*) face->v2 + vtxOffset);
		}
	}
}
/* --INLINE-- */

/* b3dRemapFaceFree:
	Remap all free faces using the given offset
*/
/* INLINE b3dRemapFaceFree(list, faceOffset) */
void b3dRemapFaceFree(B3DFaceAllocList *list, int faceOffset)
{
	B3DPrimitiveFace *freeObj;
	if(list->firstFree) {
		list->firstFree = (B3DPrimitiveFace *)((char*)list->firstFree + faceOffset);
		freeObj = list->firstFree;
		while(freeObj->nextFree) {
			freeObj->nextFree= (B3DPrimitiveFace *)((char*) freeObj->nextFree + faceOffset);
			freeObj = freeObj->nextFree;
		}
	}
}
/* --INLINE-- */

/* b3dRemapEdgeFree:
	Remap all free edges using the given offset
*/
/* INLINE b3dRemapEdgeFree(list, edgeOffset) */
void b3dRemapEdgeFree(B3DEdgeAllocList *list, int edgeOffset)
{
	B3DPrimitiveEdge *freeObj;
	if(list->firstFree) {
		list->firstFree = (B3DPrimitiveEdge *)((char*)list->firstFree + edgeOffset);
		freeObj = list->firstFree;
		while(freeObj->nextFree) {
			freeObj->nextFree = (B3DPrimitiveEdge *)((char*) freeObj->nextFree + edgeOffset);
			freeObj = freeObj->nextFree;
		}
	}
}
/* --INLINE-- */

/* b3dRemapAttrFree:
	Remap all free attributes using the given offset
*/
/* INLINE b3dRemapAttrFree(list, attrOffset) */
void b3dRemapAttributes(B3DAttrAllocList *list, int attrOffset)
{
	int i;
	for(i=0; i < list->size; i++) {
		B3DPrimitiveAttribute *attr = list->data + i;
		if(attr->next)
			attr->next = (B3DPrimitiveAttribute *)((char*) attr->next + attrOffset);
	}
}
/* --INLINE-- */

/* b3dValidateAndRemapState:
	Validate the rasterizer state and remap the objects if necessary.
*/
int b3dValidateAndRemapState(B3DRasterizerState *state)
{
	int faceOffset, edgeOffset, attrOffset, aetOffset, objOffset, i;
	B3DPrimitiveObject *obj;

	if(!state) return B3D_GENERIC_ERROR;
	
	/* Check the magic numbers */
	if(state->faceAlloc->magic  != B3D_FACE_ALLOC_MAGIC) return B3D_MAGIC_ERROR;
	if(state->edgeAlloc->magic  != B3D_EDGE_ALLOC_MAGIC) return B3D_MAGIC_ERROR;
	if(state->attrAlloc->magic  != B3D_ATTR_ALLOC_MAGIC) return B3D_MAGIC_ERROR;
	if(state->aet->magic        != B3D_AET_MAGIC) return B3D_MAGIC_ERROR;
	if(state->addedEdges->magic != B3D_EDGE_LIST_MAGIC) return B3D_MAGIC_ERROR;
	if(state->fillList->magic   != B3D_FILL_LIST_MAGIC) return B3D_MAGIC_ERROR;

	/* Check if we need to relocate objects */
	faceOffset = (int)state->faceAlloc - (int)state->faceAlloc->This;
	edgeOffset = (int)state->edgeAlloc - (int)state->edgeAlloc->This;
	attrOffset = (int)state->attrAlloc - (int)state->attrAlloc->This;
	aetOffset = (int)state->aet - (int)state->aet->This;
	
	/* remap faces */
	if(attrOffset || edgeOffset)
		b3dRemapFaces(state->faceAlloc, attrOffset, edgeOffset);
	
	/* remap fills and edges */
	if(faceOffset) {
		b3dRemapFills(state->fillList, faceOffset);
		b3dRemapEdges(state->edgeAlloc, faceOffset);
		b3dRemapFaceFree(state->faceAlloc, faceOffset);
	}
	
	/* Remap AET */
	if(edgeOffset || aetOffset) {
		void *firstEdge = state->edgeAlloc->data;
		void *lastEdge = state->edgeAlloc->data + state->edgeAlloc->size;
		b3dRemapAET(state->aet, edgeOffset, aetOffset, firstEdge, lastEdge);
	}

	/* Remap addedEdges and edge free list*/
	if(edgeOffset) {
		b3dRemapEdgeList(state->addedEdges, edgeOffset);
		b3dRemapEdgeFree(state->edgeAlloc, edgeOffset);
	}

	if(attrOffset)
		b3dRemapAttributes(state->attrAlloc, attrOffset);
	
	state->faceAlloc->This = (void*) state->faceAlloc;
	state->edgeAlloc->This = (void*) state->edgeAlloc;
	state->attrAlloc->This = (void*) state->attrAlloc;
	state->aet->This = (void*) state->aet;

	/* Remap any vertex pointers */
	for(i=0; i<state->nObjects; i++) {
		obj = state->objects[i];
		if(obj->magic != B3D_PRIMITIVE_OBJECT_MAGIC) return B3D_MAGIC_ERROR;
		objOffset = (int)obj - (int)obj->This;
		if(objOffset) {
			if((obj->flags & B3D_OBJECT_ACTIVE)) {
				B3DPrimitiveVertex *firstVtx = obj->vertices;
				B3DPrimitiveVertex *lastVtx = obj->vertices + obj->nVertices;
				b3dRemapFaceVertices(state->faceAlloc, objOffset, firstVtx, lastVtx);
				b3dRemapEdgeVertices(state->edgeAlloc, objOffset, firstVtx, lastVtx);
			}
			obj->vertices = (B3DPrimitiveVertex*) (obj + 1);
			obj->faces = (B3DInputFace*) (obj->vertices + obj->nVertices);
		}
		obj->This = (void*) obj;
	}

	return B3D_NO_ERROR;
}
