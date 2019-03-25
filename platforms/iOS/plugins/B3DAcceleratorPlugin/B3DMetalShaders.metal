//
//  B3DMetalShaders
//
//  Created by Ronie Salgado on 10-11-18.
/*
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:

 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 */
 
#include "sqMetalStructures.h"

STRINGIFY_SHADER(
struct VertexInput {
    float3 position [[attribute(0)]];
    float4 color [[attribute(1)]];
	float3 normal [[attribute(2)]];
	float2 texcoord [[attribute(3)]];
};

struct SolidFragmentData
{
    float4 clipSpacePosition [[position]];
    float4 color;
};

struct TexturedFragmentData
{
    float4 clipSpacePosition [[position]];
    float4 color;
    float2 texcoord;
};

B3DMetalMaterial combineMaterialAndVertex(constant const B3DMetalMaterial &globalMaterial, float4 vertexColor, int vertexFlags)
{
    B3DMetalMaterial material;
    // Emission color
    material.emission = globalMaterial.emission;
    if ((vertexFlags & B3D_VB_METAL_TRACK_EMISSION) != 0)
        material.emission += vertexColor;

    material.ambient = ((vertexFlags & B3D_VB_METAL_TRACK_AMBIENT) != 0) ? vertexColor : globalMaterial.ambient;
	material.diffuse = ((vertexFlags & B3D_VB_METAL_TRACK_DIFFUSE) != 0) ? vertexColor : globalMaterial.diffuse;
	material.specular = ((vertexFlags & B3D_VB_METAL_TRACK_SPECULAR) != 0) ? vertexColor : globalMaterial.specular;
	material.shininess = globalMaterial.shininess;

    return material;
}

float inverseLengthOf(float3 v)
{
    return 1.0 / length(v);
}

float4 computeLightContribution(constant const B3DMetalLight &light,
    constant const B3DMetalModelState &modelState,
    B3DMetalMaterial material,
    float3 N,
    float3 V,
    float3 P)
{
    // Compute the light vector.
    auto lightVector = light.position.xyz - P*light.position.w;
    auto L = lightVector;
    float lightDistance = 1.0;
    if(light.position.w != 0.0)
    {
        L = normalize(lightVector);
        lightDistance = length(lightVector);
    }

    // Compute the spot light effect.
    float spotAttenuation = 1.0f;
    if(light.spotMaxCos > -1.0)
    {
        float spotCos = dot(L, light.spotDirection);    
        if(spotCos < light.spotMinCos)
        {
            spotAttenuation = 0.0;
        }
        else
        {
            spotAttenuation = pow(smoothstep(light.spotMaxCos, light.spotMinCos, spotCos), light.spotExponent);
        }
    }
    
    // Compute the attenuation.
    float attenuation = spotAttenuation / (dot(float3(1.0, lightDistance, lightDistance*lightDistance), light.attenuation));

    // Always start with the ambient contribution.
    float4 lightedColor = 0.0;
    if(attenuation > 0.001)
    {
        // Add the ambient contribution.
        lightedColor += light.ambient*material.ambient*attenuation;

        // Compute the diffuse factor
        auto NdotL = dot(N, L);
        
        // Negate the cosine for one sided lights, if required.
        if((modelState.vertexBufferFlags & B3D_VB_METAL_TWO_SIDED) == 0 && NdotL < 0)
            NdotL = -NdotL;
        
        if(NdotL > 0.0)
        {        
            // Add the diffuse lighting contribution.
            lightedColor += material.diffuse*light.diffuse*attenuation*NdotL;    
        }
    }
    
    // Compute and add the specular contribution.
    if(material.shininess > 0.0)
    {
        auto H = normalize(L + V);
        
        auto NdotH = max(0.0, dot(N, H));
        auto specularFactor = pow(NdotH, material.shininess);
        lightedColor += material.specular*light.specular*specularFactor;
    }
    
    return lightedColor;
}

float4 computeB3DLighting(constant const B3DMetalLightingState &lightingState,
    constant const B3DMetalModelState &modelState,
    B3DMetalMaterial material,
    float3 N,
    float3 P)
{
    auto V = ((modelState.vertexBufferFlags & B3D_VB_METAL_LOCAL_VIEWER) != 0) ? normalize(-P) : float3(0.0, 0.0, -1.0);

    float4 lightedColor = lightingState.ambientLighting*material.ambient + material.emission;
    if(lightingState.enabledLightMask != 0)
    {
        unsigned int computedLights = 0;
        for(unsigned int i = 0; i < MAX_NUMBER_OF_LIGHTS && computedLights != lightingState.enabledLightMask; ++i)
        {
            auto lightBit = 1<<i;
            if(lightingState.enabledLightMask & lightBit)
            {
                lightedColor += computeLightContribution(lightingState.lights[i], modelState, material, N, V, P);
                computedLights |= lightBit;
            }
        }
    }
    
    return lightedColor;
}

// Solid color shaders
vertex SolidFragmentData solidB3DVertexShader(VertexInput in [[stage_in]],
        constant const B3DMetalLightingState &lightingState [[buffer(0)]],
        constant const B3DMetalMaterialState &materialState [[buffer(1)]],
        constant const B3DMetalTransformationState &transformationState [[buffer(2)]],
        constant const B3DMetalModelState &modelState [[buffer(3)]]
        )
{
    SolidFragmentData out;
    float4 viewPosition4 = transformationState.modelViewMatrix * float4(in.position, 1.0);

    float4 inVertexColor = (modelState.vertexBufferFlags & B3D_VB_METAL_TRACK_ALL) != 0 ? in.color.bgra : float4(1.0, 1.0, 1.0, 1.0);
    if(materialState.lightingEnabled) {
        float3 inVertexNormal = (modelState.vertexBufferFlags & B3D_VB_METAL_HAS_NORMALS) != 0 ? transformationState.normalMatrix * in.normal : in.normal;
        float3 normal = normalize(inVertexNormal);
        auto vertexMaterial = combineMaterialAndVertex(materialState.material, inVertexColor, modelState.vertexBufferFlags);
        out.color = computeB3DLighting(lightingState, modelState, vertexMaterial, normal, viewPosition4.xyz);
    } else {
        out.color = inVertexColor;
    }
    
    out.clipSpacePosition = transformationState.projectionMatrix * viewPosition4;
    return out;
}

fragment float4 solidB3DFragmentShader(SolidFragmentData in [[stage_in]])
{
    return in.color;
}

// Textured shaders
vertex TexturedFragmentData texturedB3DVertexShader(VertexInput in [[stage_in]],
        constant const B3DMetalLightingState &lightingState [[buffer(0)]],
        constant const B3DMetalMaterialState &materialState [[buffer(1)]],
        constant const B3DMetalTransformationState &transformationState [[buffer(2)]],
        constant const B3DMetalModelState &modelState [[buffer(3)]]
        )
{
    TexturedFragmentData out;
    float4 viewPosition4 = transformationState.modelViewMatrix * float4(in.position, 1.0);

    float4 inVertexColor = (modelState.vertexBufferFlags & B3D_VB_METAL_TRACK_ALL) != 0 ? in.color.bgra : float4(1.0, 1.0, 1.0, 1.0);
    if(materialState.lightingEnabled) {
        float3 inVertexNormal = (modelState.vertexBufferFlags & B3D_VB_METAL_HAS_NORMALS) != 0 ? transformationState.normalMatrix * in.normal : in.normal;
        float3 normal = normalize(inVertexNormal);
        auto vertexMaterial = combineMaterialAndVertex(materialState.material, inVertexColor, modelState.vertexBufferFlags);
        out.color = computeB3DLighting(lightingState, modelState, vertexMaterial, normal, viewPosition4.xyz);
    } else {
        out.color = inVertexColor;
    }
    
    out.texcoord = in.texcoord;
    out.clipSpacePosition = transformationState.projectionMatrix * viewPosition4;
    return out;
}

fragment float4 texturedB3DFragmentShader(TexturedFragmentData in [[stage_in]], texture2d<float> colorTexture [[texture(0)]])
{
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    
    return in.color*colorTexture.sample(textureSampler, in.texcoord);
}
)
