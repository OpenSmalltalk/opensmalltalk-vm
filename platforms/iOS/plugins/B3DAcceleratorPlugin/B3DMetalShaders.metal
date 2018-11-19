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

B3DMetalMaterial combineMaterialAndVertex(constant const B3DMetalMaterial &globalMaterial, float4 vertexColor, int vertexFlags)
{
    B3DMetalMaterial material;
    material.ambient = ((vertexFlags & B3D_VB_METAL_TRACK_AMBIENT) != 0) ? vertexColor : globalMaterial.ambient;
	material.diffuse = ((vertexFlags & B3D_VB_METAL_TRACK_DIFFUSE) != 0) ? vertexColor : globalMaterial.diffuse;
	material.specular = ((vertexFlags & B3D_VB_METAL_TRACK_SPECULAR) != 0) ? vertexColor : globalMaterial.specular;
	material.emission = ((vertexFlags & B3D_VB_METAL_TRACK_EMISSION) != 0) ? vertexColor : globalMaterial.emission;
	material.shininess = globalMaterial.shininess;
    return material;
}

float4 computeLightContribution(constant const B3DMetalLight &light,
    constant const B3DMetalModelState &modelState,
    B3DMetalMaterial material,
    float3 N,
    float3 V,
    float3 P)
{
    // Always start with the ambient contribution.
    float4 lightedColor = light.ambient*material.ambient;

    // Compute the light vector.
    auto lightVector = light.position.xyz - P*light.position.w;
    
    auto L = normalize(lightVector);
    
    // Compute the diffuse factor
    auto NdotL = dot(N, L);
    if(NdotL >= 0.0)
    {
        // Compute the spot light effect.
        float spotAttenuation = 1.0f;
        if(light.spotMaxCos > -1.0)
        {
            float spotCos = dot(L, light.spotDirection);    
            if(spotCos < light.spotMaxCos)
                return lightedColor;
                
            spotAttenuation = smoothstep(light.spotMaxCos, light.spotMinCos, spotCos)*pow(spotCos, light.spotExponent);
        }
        
        // Compute the attenuation.
        float lightDistance = length(lightVector);
        float attenuation = spotAttenuation / (dot(float3(1.0, lightDistance, lightDistance*lightDistance), light.attenuation));
        
        // Add the diffuse lighting contribution.
        lightedColor += material.diffuse*light.diffuse*attenuation*NdotL;
        
        // Compute and add the specular contribution.
        auto H = normalize(L + V);
        auto NdotH = max(0.0, dot(N, H));
        if(NdotH > 0.0)
            lightedColor += material.specular*light.specular*pow(NdotH, material.shininess)*attenuation;
    }
    
    return lightedColor;
}

float4 computeLighting(constant const B3DMetalLightingState &lightingState,
    constant const B3DMetalModelState &modelState,
    B3DMetalMaterial material,
    float3 N,
    float3 P)
{
    auto V = (modelState.vertexBufferFlags & B3D_VB_METAL_LOCAL_VIEWER) ? float3(0.0, 0.0, 1.0) : normalize(-P);
    if((modelState.vertexBufferFlags & B3D_VB_METAL_TWO_SIDED) != 0 && dot(N, V) < 0)
    {
        // Flip the normal of back faces.
        N = -N;        
    }

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

vertex SolidFragmentData solidVertexShader(VertexInput in [[stage_in]],
        constant const B3DMetalLightingState &lightingState [[buffer(0)]],
        constant const B3DMetalMaterialState &materialState [[buffer(1)]],
        constant const B3DMetalTransformationState &transformationState [[buffer(2)]],
        constant const B3DMetalModelState &modelState [[buffer(3)]]
        )
{
    SolidFragmentData out;
    float4 viewPosition4 = transformationState.modelViewMatrix * float4(in.position, 1.0);

    float4 inVertexColor = (modelState.vertexBufferFlags & B3D_VB_METAL_TRACK_ALL) != 0 ? in.color.bgar : float4(1.0, 1.0, 1.0, 1.0);
    if(materialState.lightingEnabled) {
        float3 inVertexNormal = (modelState.vertexBufferFlags & B3D_VB_METAL_HAS_NORMALS) != 0 ? in.normal : float3(0.0, 0.0, 1.0);
        float3 normal = normalize(transformationState.normalMatrix * inVertexNormal);
        auto vertexMaterial = combineMaterialAndVertex(materialState.material, inVertexColor, modelState.vertexBufferFlags);
        out.color = computeLighting(lightingState, modelState, vertexMaterial, normal, viewPosition4.xyz);
    } else {
        out.color = inVertexColor;
    }
    
    out.clipSpacePosition = transformationState.projectionMatrix * viewPosition4;
    return out;
}

fragment float4 solidFragmentShader(SolidFragmentData in [[stage_in]])
{
    return in.color;
}
