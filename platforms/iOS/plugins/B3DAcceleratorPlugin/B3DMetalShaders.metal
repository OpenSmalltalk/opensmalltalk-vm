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

vertex SolidFragmentData solidVertexShader(VertexInput in [[stage_in]],
        constant const B3DMetalLightingState &lightingState [[buffer(0)]],
        constant const B3DMetalMaterialState &materialState [[buffer(1)]],
        constant const B3DMetalTransformationState &transformationState [[buffer(2)]]
        )
{
    SolidFragmentData out;
    float4 viewPosition4 = transformationState.modelViewMatrix * float4(in.position, 1.0);

    out.clipSpacePosition = transformationState.projectionMatrix * viewPosition4;
    out.color = lightingState.lights[0].ambient*materialState.material.ambient + in.color.bgra; // argb -> rgba
    return out;
}

fragment float4 solidFragmentShader(SolidFragmentData in [[stage_in]])
{
    return in.color;
}
