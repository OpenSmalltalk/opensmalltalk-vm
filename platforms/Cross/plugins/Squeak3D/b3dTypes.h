/****************************************************************************
*   PROJECT: Balloon 3D Graphics Subsystem for Squeak
*   FILE:    b3dTypes.h
*   CONTENT: Type declarations for the B3D rasterizer
*
*   AUTHOR:  Andreas Raab (ar)
*   ADDRESS: Walt Disney Imagineering, Glendale, CA
*   EMAIL:   andreasr@wdi.disney.com
*   RCSID:   $Id: b3dTypes.h,v 1.1 2001/10/24 23:12:24 rowledge Exp $
*
*   NOTES:
*
*
*****************************************************************************/
#ifndef B3D_TYPES_H
#define B3D_TYPES_H

#ifndef NULL
#define NULL ((void*)0)
#endif

/* Error constants */
#define B3D_NO_ERROR 0
/* Generic error */
#define B3D_GENERIC_ERROR -1
/* Bad magic number */
#define B3D_MAGIC_ERROR -2

/* Note: The error codes that allow resuming
		must be positive. They'll be combined
		with the resume codes */
/* no more space in edge allocation list */
#define B3D_NO_MORE_EDGES 1
/* no more space in face allocation list */
#define B3D_NO_MORE_FACES 2
/* no more space in attribute allocation list */
#define B3D_NO_MORE_ATTRS 3
/* no more space in active edge table */
#define B3D_NO_MORE_AET   4
/* no more space for added edges */
#define B3D_NO_MORE_ADDED 5

/* Resume codes */
#define B3D_RESUME_MASK 0xF0000
/* Resume adding objects/edges */
#define B3D_RESUME_ADDING   0x10000
/* Resume merging added edges */
#define B3D_RESUME_MERGING  0x20000
/* Resume painting faces */
#define B3D_RESUME_PAINTING 0x40000
/* Resume updating the AET */
#define B3D_RESUME_UPDATING 0x80000

/* Factor to convert from float to fixed pt */
#define B3D_FloatToFixed 4096.0
/* Factor to convert from fixed pt to float */
#define B3D_FixedToFloat 0.000244140625
/* Shift value to convert from integer to fixed pt */
#define B3D_IntToFixedShift 12
#define B3D_FixedToIntShift 12
/* 0.5 in fixed pt representation */
#define B3D_FixedHalf 2048

/* Max. possible x value */
#define B3D_MAX_X 0x7FFFFFFF

/* Allocation flag: If this flag is not set then the nextFree pointer is valid */
#define B3D_ALLOC_FLAG 1

/************************ PrimitiveColor definition ************************/
typedef unsigned char B3DPrimitiveColor[4];

/* An ugly hack but I can't find the global defs in CodeWarrior on the Mac */
#ifndef LSB_FIRST
	#define MSB_FIRST
#endif

#ifndef MSB_FIRST
	#define RED_INDEX 0
	#define GREEN_INDEX 1
	#define BLUE_INDEX 2
	#define ALPHA_INDEX 3
#else
	#define ALPHA_INDEX 0
	#define BLUE_INDEX 1
	#define GREEN_INDEX 2
	#define RED_INDEX 3
#endif

/************************ PrimitiveVertex definition ************************/
typedef struct B3DPrimitiveVertex {
	float position[3];
	float normal[3];
	float texCoord[2];
	float rasterPos[4];
	union {
		int pixelValue32;
		B3DPrimitiveColor color;
	} cc;
	int clipFlags;
	int windowPos[2];
} B3DPrimitiveVertex;

/* sort order for primitive vertices */
#define vtxSortsBefore(vtx1, vtx2) ( (vtx1)->windowPosY == (vtx2)->windowPosY ? (vtx1)->windowPosX <= (vtx2)->windowPosX : (vtx1)->windowPosY <= (vtx2)->windowPosY)

/************************ InputFace definition ************************/
/* Note: The following is mainly so that we don't need these weird int[3] declarations. */
typedef struct B3DInputFace {
	int i0;
	int i1;
	int i2;
} B3DInputFace;

typedef struct B3DInputQuad {
	int i0;
	int i1;
	int i2;
	int i3;
} B3DInputQuad;

/************************ PrimitiveEdge definition ************************/
/* Edge flags:
    B3D_EDGE_CONTINUE_LEFT  - continue with the lower edge of the left face
	B3D_EDGE_CONTINUE_RIGHT - continue with the lower edge of the right face
	B3D_EDGE_LEFT_MAJOR     - edge is major edge for left face
	B3D_EDGE_RIGHT_MAJOR    - edge is major edge for right face
*/

#define B3D_EDGE_CONTINUE_LEFT  0x10
#define B3D_EDGE_CONTINUE_RIGHT 0x20
#define B3D_EDGE_LEFT_MAJOR     0x40
#define B3D_EDGE_RIGHT_MAJOR    0x80

typedef struct B3DPrimitiveEdge {
	int flags;
	struct B3DPrimitiveEdge *nextFree;

	/* start/end of edge */
	struct B3DPrimitiveVertex *v0;
	struct B3DPrimitiveVertex *v1;

	/* left/right face of edge (NOT meant literally) */
	struct B3DPrimitiveFace *leftFace;
	struct B3DPrimitiveFace *rightFace;

	/* current x/z value */
	int xValue;
	float zValue;
	/* x/z increment per scan line */
	int xIncrement;
	float zIncrement;

	/* number of remaining scan lines */
	int nLines;
} B3DPrimitiveEdge;


/* B3DPrimitiveEdgeList: A list of pointers to primitive edges */
#define B3D_EDGE_LIST_MAGIC  0x45553342
typedef struct B3DPrimitiveEdgeList {
	int magic;
	void *This;
	int start;
	int size;
	int max;
	B3DPrimitiveEdge *data[1];
} B3DPrimitiveEdgeList;

/* B3DActiveEdgeTable: The active edge table (basically a primitive
	edge table with few additional entries) */
#define B3D_AET_MAGIC   0x41455420
typedef struct B3DActiveEdgeTable {
	int magic;
	void *This;
	int start;
	int size;
	int max;
	/* Backups for proceeding after failure */
	int yValue;
	B3DPrimitiveEdge *leftEdge;
	B3DPrimitiveEdge *rightEdge;
	B3DPrimitiveEdge *lastIntersection;
	B3DPrimitiveEdge *nextIntersection;
	/* That's where lastIntersection and nextIntersection point to */
	B3DPrimitiveEdge tempEdge0;
	B3DPrimitiveEdge tempEdge1;
	/* Actual data */
	B3DPrimitiveEdge *data[1];
} B3DActiveEdgeTable ;

/************************ PrimitiveFace definition ************************/

/* Face flags:
	B3D_FACE_INITIALIZED - have the face attributes been initialized?!
	B3D_FACE_ACTIVE      - is the face currently in the fill list?!
	B3D_FACE_HAS_ALPHA   - can the face eventually be transparent?!

    B3D_FACE_RGB         - R,G,B interpolation values
	B3D_FACE_ALPHA       - Alpha interpolation values
	B3D_FACE_STW         - S,T,W interpolation values
*/

#define B3D_FACE_INITIALIZED 0x10
#define B3D_FACE_ACTIVE      0x20
#define B3D_FACE_HAS_ALPHA   0x40

#define B3D_FACE_RGB         0x100
#define B3D_FACE_ALPHA       0x200
#define B3D_FACE_STW         0x400

/* # of possible combinations AND maximum (e.g., R+G+B+A+S+T+W) of attribs */
/* NOTE: This is a really ugly hack - I'll have to fix that */
#define B3D_MAX_ATTRIBUTES 8
/* mask out the face attributes */
#define B3D_ATTR_MASK 0x7
/* shift for getting the attributes */
#define B3D_ATTR_SHIFT 8

typedef struct B3DPrimitiveFace {
	int flags;
	struct B3DPrimitiveFace *nextFree;

	/* The three vertices of the face */
	struct B3DPrimitiveVertex *v0;
	struct B3DPrimitiveVertex *v1;
	struct B3DPrimitiveVertex *v2;

	/* The links for the (depth sorted) list of fills */
	struct B3DPrimitiveFace *prevFace;
	struct B3DPrimitiveFace *nextFace;

	/* The left and right edge of the face (not taken too literally) */
	struct B3DPrimitiveEdge *leftEdge;
	struct B3DPrimitiveEdge *rightEdge;

	/* The deltas for the major (e.g., v0-v2) and the first minor (e.g., v0-v1) edge */
	float majorDx, majorDy;
	float minorDx, minorDy;

	/* The inverse area covered by (twice) the triangle */
	float oneOverArea;

	/* Depth attributes are kept here since we almost always need 'em */
	float minZ, maxZ;
	float dzdx, dzdy;

	/* The pointer to the texture */
	struct B3DTexture *texture;
	/* The pointer to the extended (per face) interpolation values */
	struct B3DPrimitiveAttribute *attributes;
} B3DPrimitiveFace;


/* B3DFillList: A (depth-sorted) list of primitive faces */
#define B3D_FILL_LIST_MAGIC  0x46443342
typedef struct B3DFillList {
	int magic;
	void *This;
	B3DPrimitiveFace *firstFace;
	B3DPrimitiveFace *lastFace;
} B3DFillList;

/************************ PrimitiveAttribute definition ************************/

typedef struct B3DPrimitiveAttribute {
	/* Note: next is either nextFree or or nextUsed */
	struct B3DPrimitiveAttribute *next;
	/* value at the face->v0 */
	float value;
	/* value / dx derivative for face */
	float dvdx;
	/* value / dy derivative for face */
	float dvdy;
} B3DPrimitiveAttribute;

/************************ Texture definition ************************/
#define B3D_TEXTURE_POWER_OF_2 0x10
typedef struct B3DTexture {
	int width;
	int height;
	int depth;
	int rowLength; /* 32bit words per scan line */
	int sMask;	/* Nonzero for power of two width */
	int sShift;
	int tMask;	/* Nonzero for power of two height */
	int tShift;
	int cmSize; /* length of color map */
	unsigned int *colormap;
	unsigned int *data;
} B3DTexture;

/************************ PrimitiveViewport definition ************************/

typedef struct B3DPrimitiveViewport {
	int x0, y0, x1, y1;
} B3DPrimitiveViewport;

/************************ PrimitiveObject definition ************************/
#define B3D_OBJECT_ACTIVE 0x10
#define B3D_OBJECT_DONE   0x20

#define B3D_PRIMITIVE_OBJECT_MAGIC  0x4F443342
typedef struct B3DPrimitiveObject {
	int magic;
	void *This;
	int __oop__; /* actual ST oop */
	struct B3DPrimitiveObject *next;
	struct B3DPrimitiveObject *prev;

	int flags;

	int textureIndex;
	struct B3DTexture *texture;

	int minX, maxX, minY, maxY;
	float minZ, maxZ;

	int nSortedFaces;
	int nInvalidFaces;
	

	int start;
	int nFaces;
	B3DInputFace *faces;
	int nVertices;
	B3DPrimitiveVertex *vertices;
} B3DPrimitiveObject;

/* sort order for primitive objects */
#define objSortsBefore(obj1, obj2) ( (obj1)->minY == (obj2)->minY ? (obj1)->minX <= (obj2)->minX : (obj1)->minY <= (obj2)->minY)

#endif /* ifndef B3D_TYPES_H */
