/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dAlloc.h
*   CONTENT: Memory allocation for the Balloon 3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3dAlloc.h,v 1.1 2001/10/24 23:12:22 rowledge Exp $
*
*   NOTES:
*
*
*****************************************************************************/
#ifndef B3D_ALLOC_H
#define B3D_ALLOC_H

#include "b3dTypes.h"

/************************ Allocator definitions ************************/
#define B3D_EDGE_ALLOC_MAGIC 0x45443341
typedef struct B3DEdgeAllocList {
	int magic;
	void *This;
	int max; /* Note: size is ALWAYS less than max */
	int size;
 	int nFree;
	B3DPrimitiveEdge *firstFree; /* pointer to the first free edge (< max) */
	B3DPrimitiveEdge data[1];
} B3DEdgeAllocList;

#define B3D_FACE_ALLOC_MAGIC 0x46443341
typedef struct B3DFaceAllocList {
	int magic;
	void *This;
	int max; /* Note: size is ALWAYS less than max */
	int size;
	int nFree;
	B3DPrimitiveFace *firstFree; /* pointer to the first free face (< max) */
	B3DPrimitiveFace data[1];
} B3DFaceAllocList;

#define B3D_ATTR_ALLOC_MAGIC  0x41443341
typedef struct B3DAttrAllocList {
	int magic;
	void *This;
	int max; /* Note: size is ALWAYS less than max */
	int size;
	int nFree;
	B3DPrimitiveAttribute *firstFree; /* pointer to the first free attribute (< max) */
	B3DPrimitiveAttribute data[1];
} B3DAttrAllocList;

/* The mapping from face flags to the number of attributes needed */
extern int B3D_ATTRIBUTE_SIZES[B3D_MAX_ATTRIBUTES];
#define B3D_FACE_ATTRIB_SIZE(face) (B3D_ATTRIBUTE_SIZES[(face->flags >> B3D_ATTR_SHIFT) & B3D_ATTR_MASK])

#ifdef DEBUG_ALLOC

B3DPrimitiveFace *dbg_b3dAllocFace(B3DFaceAllocList *list);
B3DPrimitiveEdge *dbg_b3dAllocEdge(B3DEdgeAllocList *list);
int dbg_b3dAllocAttrib(B3DAttrAllocList *attrList, B3DPrimitiveFace *face);
void dbg_b3dFreeFace(B3DFaceAllocList *list, B3DPrimitiveFace *face);
void dbg_b3dFreeEdge(B3DEdgeAllocList *list, B3DPrimitiveEdge *edge);
void dbg_b3dFreeAttrib(B3DAttrAllocList *list, B3DPrimitiveFace *face);

#define b3dAllocFace(list, face) face = dbg_b3dAllocFace(list);
#define b3dAllocEdge(list, edge) edge = dbg_b3dAllocEdge(list);
#define b3dAllocAttrib(attrList, face, result) result = dbg_b3dAllocAttrib(attrList, face);
#define b3dFreeFace(list, face) dbg_b3dFreeFace(list, face);
#define b3dFreeEdge(list, edge) dbg_b3dFreeEdge(list, edge);
#define b3dFreeAttrib(list, face) dbg_b3dFreeAttrib(list, face);

#else /* RELEASE */

#define b3dAlloc(list,object) \
{\
	if(list->firstFree) { \
		object = list->firstFree; \
		list->firstFree = object->nextFree; \
		object->flags = B3D_ALLOC_FLAG; \
		list->nFree--;\
	} else { \
		if(list->size < list->max) { \
			object = list->data + list->size; \
			list->size++;\
			object->flags = B3D_ALLOC_FLAG;\
			list->nFree--;\
		} else object = NULL;\
	}\
}

#define b3dFree(list, object) \
{\
	object->flags = 0;\
	object->nextFree = list->firstFree; \
	list->firstFree = object;\
	list->nFree++;\
}

#define b3dAllocFace(list, face) b3dAlloc(list,face)
#define b3dAllocEdge(list, edge) b3dAlloc(list, edge)
#define b3dFreeFace(list, face) b3dFree(list, face)
#define b3dFreeEdge(list, edge) b3dFree(list, edge)

#define b3dAllocSingleAttr(list,object) \
{\
	if(list->firstFree) { \
		object = list->firstFree; \
		list->firstFree = object->next; \
		list->nFree--;\
	} else { \
		if(list->size < list->max) { \
			object = list->data + list->size; \
			list->size++;\
			list->nFree--;\
		} else object = NULL;\
	}\
}

#define b3dAllocAttrib(attrList,face, result) \
{\
	B3DPrimitiveAttribute *firstAttr, *nextAttr;\
	int nAttrs = 0;\
\
	if(face->flags & B3D_FACE_RGB) nAttrs += 3;\
	if(face->flags & B3D_FACE_ALPHA) nAttrs += 1;\
	if(face->flags & B3D_FACE_STW) nAttrs += 3;\
	firstAttr = nextAttr = NULL;\
	while(nAttrs--) {\
		b3dAllocSingleAttr(attrList, nextAttr);\
		if(!nextAttr) break;\
		nextAttr->next = firstAttr;\
		firstAttr = nextAttr;\
	};\
	face->attributes = firstAttr;\
	result = nextAttr != NULL;\
}


#define b3dFreeAttrib(list, face) \
{\
	B3DPrimitiveAttribute *attr, *nextAttr = face->attributes;\
	while(nextAttr) {\
		attr = nextAttr;\
		nextAttr = attr->next;\
		attr->next = list->firstFree;\
		list->firstFree = attr;\
		list->nFree++;\
	}\
}

#endif

#endif /* ifndef B3D_ALLOC_H */
