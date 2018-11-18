#ifndef SQ_METAL_STRUCTURES_H
#define SQ_METAL_STRUCTURES_H

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef packed_float2 b3d_float2_t;
typedef packed_float3 b3d_float3_t;
typedef packed_float4 b3d_float4_t;

#else

typedef float b3d_float2_t[2];
typedef float b3d_float3_t[3];
typedef float b3d_float4_t[4];

#endif

/* This is the same as B3DPrimitiveVertex */
typedef struct B3DMetalPrimitiveVertex {
	b3d_float3_t position;
	b3d_float3_t normal;
	b3d_float2_t texCoord;
	b3d_float4_t rasterPos;
	int pixelValue32;
	int clipFlags;
	int windowPos[2];
} B3DMetalPrimitiveVertex;

typedef struct B3DMetalPrimitiveMaterial {
	b3d_float4_t ambient;
	b3d_float4_t diffuse;
	b3d_float4_t specular;
	b3d_float4_t emission;
	b3d_float4_t shininess;
} B3DMetalPrimitiveMaterial;

typedef struct B3DMetalPrimitiveLight {
    b3d_float4_t ambient;
    b3d_float4_t diffuse;
    b3d_float4_t specular;

    b3d_float3_t position;
    b3d_float3_t direction;
    b3d_float3_t attenuation;
    int flags;

    float spotMinCos;
    float spotMaxCos;
    float spotDeltaCos;
    float spotExponent;
} B3DMetalPrimitiveLight;

#endif /* SQ_METAL_STRUCTURES_H */
