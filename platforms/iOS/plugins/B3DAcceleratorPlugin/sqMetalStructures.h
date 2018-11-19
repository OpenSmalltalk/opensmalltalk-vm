#ifndef SQ_METAL_STRUCTURES_H
#define SQ_METAL_STRUCTURES_H

#define MAX_NUMBER_OF_LIGHTS 16

/* Vertex buffer flags */
#define B3D_VB_METAL_TRACK_AMBIENT 1
#define B3D_VB_METAL_TRACK_DIFFUSE 2
#define B3D_VB_METAL_TRACK_SPECULAR 4
#define B3D_VB_METAL_TRACK_EMISSION 8
#define B3D_VB_METAL_TRACK_ALL (B3D_VB_METAL_TRACK_AMBIENT | B3D_VB_METAL_TRACK_DIFFUSE | B3D_VB_METAL_TRACK_SPECULAR | B3D_VB_METAL_TRACK_EMISSION)

#define B3D_VB_METAL_HAS_NORMALS 16
#define B3D_VB_METAL_HAS_TEXTURES 32

#define B3D_VB_METAL_TWO_SIDED 64
#define B3D_VB_METAL_LOCAL_VIEWER 128

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef float2 b3d_float2_t;
typedef float3 b3d_float3_t;
typedef float4 b3d_float4_t;
typedef float3x3 b3d_float3x3_t;
typedef float4x4 b3d_float4x4_t;

#else
#include <simd/simd.h>

typedef vector_float2 b3d_float2_t;
typedef vector_float3 b3d_float3_t;
typedef vector_float4 b3d_float4_t;

typedef matrix_float3x3 b3d_float3x3_t;
typedef matrix_float4x4 b3d_float4x4_t;

#endif

typedef struct B3DMetalMaterial {
	b3d_float4_t ambient;
	b3d_float4_t diffuse;
	b3d_float4_t specular;
	b3d_float4_t emission;
	float shininess;
} B3DMetalMaterial;

typedef struct B3DMetalLight {
    b3d_float4_t ambient;
    b3d_float4_t diffuse;
    b3d_float4_t specular;

    b3d_float4_t position;
    b3d_float3_t spotDirection;
    b3d_float3_t attenuation;

    float spotMinCos;
    float spotMaxCos;
    float spotDeltaCos;
    float spotExponent;
} B3DMetalLight;

/**
 * The global lighting state
 */
typedef struct B3DMetalLightingState {
	unsigned int enabledLightMask;
	b3d_float4_t ambientLighting;
	B3DMetalLight lights[MAX_NUMBER_OF_LIGHTS];
} B3DMetalLightingState;

/**
 * The global material state
 */
typedef struct B3DMetalMaterialState {
	int lightingEnabled;
	B3DMetalMaterial material;
} B3DMetalMaterialState;

/**
 * The global transformation state
 */
typedef struct B3DMetalTransformationState {
	b3d_float4x4_t modelViewMatrix;
	b3d_float4x4_t projectionMatrix;
	b3d_float3x3_t normalMatrix;
} B3DMetalTransformationState;

/**
 * The model specific state
 */
typedef struct B3DMetalModelState {
	int vertexBufferFlags;
} B3DMetalModelState;

#endif /* SQ_METAL_STRUCTURES_H */
