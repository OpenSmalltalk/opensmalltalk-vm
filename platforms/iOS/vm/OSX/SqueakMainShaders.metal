//
//  SqueakMainShaders
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

 The end-user documentation included with the redistribution, if any, must include the following acknowledgment:
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com)
 and its contributors", in the same place and form as other third-party acknowledgments.
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other
 such third-party acknowledgments.
 */

#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

struct ScreenQuadVertex
{
    packed_float4 position;
    float2 texcoord;
};

struct FragmentData
{
    float4 clipSpacePosition [[position]];
    float2 texcoord;
};

vertex FragmentData screenQuadVertexShader(uint vertexID [[vertex_id]], device ScreenQuadVertex *vertices [[buffer(0)]])
{
    FragmentData out; 
    out.clipSpacePosition = vertices[vertexID].position;
    out.texcoord = vertices[vertexID].texcoord;
    return out;
}

vertex FragmentData screenQuadFlipVertexShader(uint vertexID [[vertex_id]], device ScreenQuadVertex *vertices [[buffer(0)]])
{
    FragmentData out; 
    out.clipSpacePosition = vertices[vertexID].position;
    out.texcoord = float2(vertices[vertexID].texcoord.x, 1.0 - vertices[vertexID].texcoord.y);
    return out;
}

fragment float4 screenQuadFragmentShader(FragmentData in [[stage_in]], texture2d<float> screenTexture [[texture(0)]])
{
    constexpr sampler textureSampler(mag_filter::nearest, min_filter::nearest);
    
    return screenTexture.sample(textureSampler, in.texcoord);
}
