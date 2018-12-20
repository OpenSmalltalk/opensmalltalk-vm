/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dAlloc.c
*   CONTENT: Memory allocation for the Balloon 3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3dAlloc.c,v 1.1 2001/10/24 23:12:22 rowledge Exp $
*
*   NOTES:
*
*
*****************************************************************************/
#include <assert.h>
#include "b3d.h"

#ifdef DEBUG_ALLOC
/* DEBUG versions of allocators */
B3DPrimitiveFace *dbg_b3dAllocFace(B3DFaceAllocList *list)
{
	B3DPrimitiveFace *result;
	if(list->firstFree) {
		result = list->firstFree;
		list->firstFree = list->firstFree->nextFree;
	    if(result->flags & B3D_ALLOC_FLAG)
			b3dAbort("list->firstFree has allocation bit set");
	} else {
		if(list->size < list->max) {
			result = list->data + list->size;
			list->size++;
		} else return NULL;
	}
	result->nextFree = NULL;
	result->flags = B3D_ALLOC_FLAG;
	list->nFree--;
	return result;
}

B3DPrimitiveEdge *dbg_b3dAllocEdge(B3DEdgeAllocList *list)
{
	B3DPrimitiveEdge *result;
	if(list->firstFree) {
		result = list->firstFree;
		list->firstFree = list->firstFree->nextFree;
	    if(result->flags & B3D_ALLOC_FLAG)
			b3dAbort("list->firstFree has allocation bit set");
	} else {
		if(list->size < list->max) {
			result = list->data + list->size;
			list->size++;
		} else return NULL;
	}
	result->nextFree = NULL;
	result->flags = B3D_ALLOC_FLAG;
	list->nFree--;
	return result;
}

void dbg_b3dFreeFace(B3DFaceAllocList *list, B3DPrimitiveFace *face)
{
	if(face < list->data || face >= (list->data + list->size))
		b3dAbort("face to free is not in list");
	if( ! (face->flags & B3D_ALLOC_FLAG) )
		b3dAbort("face to free has no allocation flag set");
	face->flags = 0;
	face->nextFree = list->firstFree;
	list->firstFree = face;
	list->nFree++;
}

void dbg_b3dFreeEdge(B3DEdgeAllocList *list, B3DPrimitiveEdge *edge)
{
	if(edge < list->data || edge >= (list->data + list->size))
		b3dAbort("edge to free is not in list");
	if( ! (edge->flags & B3D_ALLOC_FLAG) )
		b3dAbort("edge to free has no allocation flag set");
	edge->flags = 0;
	edge->nextFree = list->firstFree;
	list->firstFree = edge;
	list->nFree++;
}

B3DPrimitiveAttribute *dbg_b3dAllocSingleAttr(B3DAttrAllocList *list)
{
	B3DPrimitiveAttribute *result;
	if(list->firstFree) {
		result = list->firstFree;
		list->firstFree = list->firstFree->next;
	} else {
		if(list->size < list->max) {
			result = list->data + list->size;
			list->size++;
		} else return NULL;
	}
	list->nFree--;
	return result;
}

int dbg_b3dAllocAttrib(B3DAttrAllocList *attrList, B3DPrimitiveFace *face)
{
	B3DPrimitiveAttribute *firstAttr, *nextAttr;
	int i, nAttrs = 0;

	assert(face->attributes == NULL);
	if(face->flags & B3D_FACE_RGB) nAttrs += 3;
	if(face->flags & B3D_FACE_ALPHA) nAttrs += 1;
	if(face->flags & B3D_FACE_STW) nAttrs += 3;
	if(!nAttrs) return 1;
	firstAttr = nextAttr = NULL;
	for(i=0;i<nAttrs; i++) {
		nextAttr = dbg_b3dAllocSingleAttr(attrList);
		if(!nextAttr) return 0;
		nextAttr->next = firstAttr;
		firstAttr = nextAttr;
	}
	face->attributes = firstAttr;
	return 1;
}

void dbg_b3dFreeAttrib(B3DAttrAllocList *list, B3DPrimitiveFace *face)
{
	B3DPrimitiveAttribute *attr, *nextAttr = face->attributes;
	while(nextAttr) {
		attr = nextAttr;
		nextAttr = attr->next;
		if(attr < list->data || attr >= (list->data + list->size))
			b3dAbort("attributes to free are not in list");
		attr->next = list->firstFree;
		list->firstFree = attr;
		list->nFree++;
	}
}


#endif /* DEBUG */
