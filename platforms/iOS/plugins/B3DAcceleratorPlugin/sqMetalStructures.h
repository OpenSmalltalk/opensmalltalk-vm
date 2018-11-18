#ifndef SQ_METAL_STRUCTURES_H
#define SQ_METAL_STRUCTURES_H

#define MAX_NUMBER_OF_LIGHTS 16

#ifdef __METAL_VERSION__
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef packed_float2 b3d_float2_t;
typedef packed_float3 b3d_float3_t;
typedef packed_float4 b3d_float4_t;
typedef float4x4 b3d_float4x4_t;

#else
#include <simd/simd.h>

typedef packed_float2 b3d_float2_t;
typedef struct {
	float x, y, z;
} b3d_float3_t;
typedef packed_float4 b3d_float4_t;

typedef matrix_float4x4 b3d_float4x4_t;

#endif

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

/**
 * The global lighting state
 */
typedef struct B3DMetalLightingState {
	unsigned int enabledLightMask;
	B3DMetalPrimitiveLight lights[MAX_NUMBER_OF_LIGHTS];
} B3DMetalLightingState;

/**
 * The global material state
 */
typedef struct B3DMetalMaterialState {
	int lightingEnabled;
	B3DMetalPrimitiveMaterial material;
} B3DMetalMaterialState;

/**
 * The global transformation state
 */
typedef struct B3DMetalTransformationState {
	b3d_float4x4_t modelViewMatrix;
	b3d_float4x4_t projectionMatrix;
} B3DMetalTransformationState;

#endif /* SQ_METAL_STRUCTURES_H */
