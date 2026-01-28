#version 460 core

precision mediump float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;       // Size of the input texture
uniform sampler2D uTexture; // Input texture (the image)
uniform sampler2D uLut;     // The flattened 3D LUT (e.g. 1024x32 for a 32-sized cube)

// This shader applies a Color Lookup Table (LUT) to an input image.
// A LUT is essentially a map that transforms an input color (RGB) to a new output color,
// commonly used for color grading and cinematic filters.
//
// 3D TEXTURE HACK:
// Ideally, a LUT is a 3D texture (Cube) where R, G, and B map directly to X, Y, and Z coordinates.
// However, since 3D texture support can be inconsistent across devices or backends,
// we use a common technique to "flatten" the 3D data into a 2D texture strip.
//
// For a standard 32x32x32 LUT:
// - We cut the cube into 32 slices along the Z axis (Blue channel).
// - Each slice is a 32x32 pixel grid representing the R (X) and G (Y) axes.
// - We lay these slices out horizontally, creating a 1024x32 texture (32 * 32 width).
//
// In the shader, we manually calculate which slice(s) to read from based on the Blue channel,
// and interpolate between them to simulate trilinear filtering.

uniform float uIntensity;

out vec4 fragColor;

void main() {
    vec4 color = texture(uTexture, FlutterFragCoord().xy / uSize);
    
    // The dimension of the LUT (nodes per axis). Standard is often 32 or 64.
    float dimension = 32.0;
    
    // Map the Blue channel to a "depth" index (Z-axis).
    // range: 0.0 to 31.0
    float blueColor = color.b * (dimension - 1.0);
    
    // We need to sample from two adjacent slices to interpolate the Z-axis manualy.
    float quad1 = floor(blueColor);
    float quad2 = min(dimension - 1.0, floor(blueColor) + 1.0);
    
    // The fractional part of the Blue channel determines how much to mix the two slices.
    float fractBlue = blueColor - quad1;
    
    // Compute UV coordinates within a single 32x32 slice.
    // Note: We need to offset by half a pixel to sample the center of texels correctly.
    float halfPixelX = 0.5 / (dimension * dimension);
    float halfPixelY = 0.5 / dimension;
    
    // Calculate the base UV for R (X) and G (Y) within a slice.
    // The R coordinate spans 1/dimension of the total texture width per slice.
    // The G coordinate spans the full height of the texture.
    float rOffset = halfPixelX + color.r * (1.0 - 1.0/dimension) / dimension;
    float gOffset = halfPixelY + color.g * (1.0 - 1.0/dimension);
    
    // Calculate final UVs for both the "lower" and "upper" Z-slices.
    // We add (quad / dimension) to X to shift to the correct slice in the horizontal strip.
    vec2 uv1 = vec2(quad1 / dimension + rOffset, gOffset);
    vec2 uv2 = vec2(quad2 / dimension + rOffset, gOffset);
    
    // Sample the LUT at both slices.
    vec3 lutColor1 = texture(uLut, uv1).rgb;
    vec3 lutColor2 = texture(uLut, uv2).rgb;
    
    // Interpolate between the two samples based on the Blue channel fraction (Z-axis lerp).
    vec3 finalColor = mix(lutColor1, lutColor2, fractBlue);
    
    // Mix the original color with the LUT result based on the uniform intensity.
    fragColor = vec4(mix(color.rgb, finalColor, uIntensity), color.a);
}
