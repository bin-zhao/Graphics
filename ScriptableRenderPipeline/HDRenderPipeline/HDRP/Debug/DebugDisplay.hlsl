#ifndef UNITY_DEBUG_DISPLAY_INCLUDED
#define UNITY_DEBUG_DISPLAY_INCLUDED

#include "CoreRP/ShaderLibrary/Debug.hlsl"
#include "DebugDisplay.cs.hlsl"
#include "MaterialDebug.cs.hlsl"
#include "LightingDebug.cs.hlsl"
#include "MipMapDebug.cs.hlsl"
#include "ColorPickerDebug.cs.hlsl"

// Set of parameters available when switching to debug shader mode
int _DebugLightingMode; // Match enum DebugLightingMode
int _DebugViewMaterial; // Contain the id (define in various materialXXX.cs.hlsl) of the property to display
int _DebugMipMapMode; // Match enum DebugMipMapMode
float4 _DebugLightingAlbedo; // xyz = albedo for diffuse, w unused
float4 _DebugLightingSmoothness; // x == bool override, y == override value
float4 _MousePixelCoord;  // xy unorm, zw norm

TEXTURE2D(_DebugFont); // Debug font to write string in shader

void GetPropertiesDataDebug(uint paramId, inout float3 result, inout bool needLinearToSRGB)
{
    switch (paramId)
    {
        case DEBUGVIEWPROPERTIES_TESSELLATION:
#ifdef TESSELLATION_ON
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

        case DEBUGVIEWPROPERTIES_PIXEL_DISPLACEMENT:
#ifdef _PIXEL_DISPLACEMENT // Caution: This define is related to a shader features (But it may become a standard features for HD)
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

        case DEBUGVIEWPROPERTIES_VERTEX_DISPLACEMENT:
#ifdef _VERTEX_DISPLACEMENT // Caution: This define is related to a shader features (But it may become a standard features for HD)
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

        case DEBUGVIEWPROPERTIES_TESSELLATION_DISPLACEMENT:
#ifdef _TESSELLATION_DISPLACEMENT // Caution: This define is related to a shader features (But it may become a standard features for HD)
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

        case DEBUGVIEWPROPERTIES_DEPTH_OFFSET:
#ifdef _DEPTHOFFSET_ON  // Caution: This define is related to a shader features (But it may become a standard features for HD)
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

        case DEBUGVIEWPROPERTIES_LIGHTMAP:
#if defined(LIGHTMAP_ON) || defined (DIRLIGHTMAP_COMBINED) || defined(DYNAMICLIGHTMAP_ON)
            result = float3(1.0, 0.0, 0.0);
#else
            result = float3(0.0, 0.0, 0.0);
#endif
            break;

    }
}

float3 GetTextureDataDebug(uint paramId, float2 uv, Texture2D tex, float4 texelSize, float4 mipInfo, float3 originalColor)
{
    switch (paramId)
    {
    case DEBUGMIPMAPMODE_MIP_RATIO:
        return GetDebugMipColorIncludingMipReduction(originalColor, tex, texelSize, uv, mipInfo);
    case DEBUGMIPMAPMODE_MIP_COUNT:
        return GetDebugMipCountColor(originalColor, tex);
    case DEBUGMIPMAPMODE_MIP_COUNT_REDUCTION:
        return GetDebugMipReductionColor(tex, mipInfo);
    case DEBUGMIPMAPMODE_STREAMING_MIP_BUDGET:
        return GetDebugStreamingMipColor(tex, mipInfo);
    case DEBUGMIPMAPMODE_STREAMING_MIP:
        return GetDebugStreamingMipColorBlended(originalColor, tex, mipInfo);
    }

    return originalColor;
}

// DebugFont code assume black and white font with texture size 256x128 with bloc of 16x16
#define DEBUG_FONT_TEXT_WIDTH	16
#define DEBUG_FONT_TEXT_HEIGHT	16
#define DEBUG_FONT_TEXT_COUNT_X	16
#define DEBUG_FONT_TEXT_COUNT_Y	8
#define DEBUG_FONT_TEXT_ASCII_START 32

#define DEBUG_FONT_TEXT_SCALE_WIDTH	10 // This control the spacing between characters (if a character fill the text block it will overlap).

// Only support ASCII symbol from DEBUG_FONT_TEXT_ASCII_START to 126
// return black or white depends if we hit font character or not
// currentUnormCoord is current unormalized screen position
// fixedUnormCoord is the position where we want to draw something, this will be incremented by block font size in provided direction
// color is current screen color
// color of the font to use
// direction is 1 or -1 and indicate fixedUnormCoord block shift
void DrawCharacter(uint asciiValue, float3 fontColor, uint2 currentUnormCoord, inout uint2 fixedUnormCoord, inout float3 color, int direction)
{
    // Are we inside a font display block on the screen ?
    uint2 localCharCoord = currentUnormCoord - fixedUnormCoord;
    if (localCharCoord.x >= 0 && localCharCoord.x < DEBUG_FONT_TEXT_WIDTH && localCharCoord.y >= 0 && localCharCoord.y < DEBUG_FONT_TEXT_HEIGHT)
    {
        #if UNITY_UV_STARTS_AT_TOP
        localCharCoord.y = DEBUG_FONT_TEXT_HEIGHT - localCharCoord.y;
        #endif

        asciiValue -= DEBUG_FONT_TEXT_ASCII_START; // Our font start at ASCII table 32;
        uint2 asciiCoord = uint2(asciiValue % DEBUG_FONT_TEXT_COUNT_X, asciiValue / DEBUG_FONT_TEXT_COUNT_X);
        // Unorm coordinate inside the font texture
        uint2 unormTexCoord = asciiCoord * uint2(DEBUG_FONT_TEXT_WIDTH, DEBUG_FONT_TEXT_HEIGHT) + localCharCoord;
        // normalized coordinate
        float2 normTexCoord = float2(unormTexCoord) / float2(DEBUG_FONT_TEXT_WIDTH * DEBUG_FONT_TEXT_COUNT_X, DEBUG_FONT_TEXT_HEIGHT * DEBUG_FONT_TEXT_COUNT_Y);

        #if UNITY_UV_STARTS_AT_TOP
        normTexCoord.y = 1.0 - normTexCoord.y;
        #endif

        float charColor = SAMPLE_TEXTURE2D_LOD(_DebugFont, s_point_clamp_sampler, normTexCoord, 0).r;
        color = color * (1.0 - charColor) + charColor * fontColor;
    }

    fixedUnormCoord.x += DEBUG_FONT_TEXT_SCALE_WIDTH * direction;
}

// Shortcut to not have to file direction
void DrawCharacter(uint asciiValue, float3 fontColor, uint2 currentUnormCoord, inout uint2 fixedUnormCoord, inout float3 color)
{
    DrawCharacter(asciiValue, fontColor, currentUnormCoord, fixedUnormCoord, color, 1);
}

// Draw a signed integer
// Can't display more than 16 digit
void DrawInteger(int intValue, float3 fontColor, uint2 currentUnormCoord, inout uint2 fixedUnormCoord, inout float3 color)
{
    const uint maxStringSize = 16;

    int absIntValue = abs(intValue);

    // 1. Get size of the number of display
    int numEntries = min((intValue == 0 ? 0 : log10(absIntValue)) + (intValue < 0 ? 1 : 0), maxStringSize);

    // 2. Shift curseur to last location as we will go reverse
    fixedUnormCoord.x += numEntries * DEBUG_FONT_TEXT_SCALE_WIDTH;

    // 3. Display the number
    for (uint i = 0; i < maxStringSize; ++i)
    {
        // Numeric value incurrent font start on the second row at 0
        DrawCharacter((absIntValue % 10) + '0', fontColor, currentUnormCoord, fixedUnormCoord, color, -1);
        if (absIntValue  < 10)
            break;
        absIntValue /= 10;
    }

    // 4. Display sign
    if (intValue < 0)
    {
        DrawCharacter('-', fontColor, currentUnormCoord, fixedUnormCoord, color, -1);
    }

    // 5. Reset cursor at end location
    fixedUnormCoord.x += (numEntries + 2) * DEBUG_FONT_TEXT_SCALE_WIDTH;
}

void DrawFloat(float floatValue, float3 fontColor, uint2 currentUnormCoord, inout uint2 fixedUnormCoord, inout float3 color)
{
    int intValue = int(floatValue);
    DrawInteger(intValue, fontColor, currentUnormCoord, fixedUnormCoord, color);
    DrawCharacter('.', fontColor, currentUnormCoord, fixedUnormCoord, color);
    int fracValue = int(frac(floatValue) * 1e6); // 6 digit
    DrawInteger(fracValue, fontColor, currentUnormCoord, fixedUnormCoord, color);
}

#endif
