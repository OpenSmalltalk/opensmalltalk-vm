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

#ifdef STRINGIFY_SHADER

#define B3D_STRUCTURES_DEF_MACRO(x) #x
#define EMIT_SHADER_CONSTANT(x) "#define " #x " " STRINGIFY_SHADER(x) "\n"

"#include <metal_stdlib>\n"
"#include <simd/simd.h>\n"

EMIT_SHADER_CONSTANT(MAX_NUMBER_OF_LIGHTS)

EMIT_SHADER_CONSTANT(B3D_VB_METAL_TRACK_AMBIENT)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_TRACK_DIFFUSE)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_TRACK_SPECULAR)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_TRACK_EMISSION)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_TRACK_ALL)

EMIT_SHADER_CONSTANT(B3D_VB_METAL_HAS_NORMALS)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_HAS_TEXTURES)

EMIT_SHADER_CONSTANT(B3D_VB_METAL_TWO_SIDED)
EMIT_SHADER_CONSTANT(B3D_VB_METAL_LOCAL_VIEWER)

STRINGIFY_SHADER(
using namespace metal;

typedef float2 b3d_float2_t;
typedef float3 b3d_float3_t;
typedef float4 b3d_float4_t;
typedef float3x3 b3d_float3x3_t;
typedef float4x4 b3d_float4x4_t;
)

#else

#include <simd/simd.h>

#define B3D_STRUCTURES_DEF_MACRO(x) x

typedef vector_float2 b3d_float2_t;
typedef vector_float3 b3d_float3_t;
typedef vector_float4 b3d_float4_t;

typedef matrix_float3x3 b3d_float3x3_t;
typedef matrix_float4x4 b3d_float4x4_t;

#endif

B3D_STRUCTURES_DEF_MACRO(
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
)

#undef B3D_STRUCTURES_DEF_MACRO
