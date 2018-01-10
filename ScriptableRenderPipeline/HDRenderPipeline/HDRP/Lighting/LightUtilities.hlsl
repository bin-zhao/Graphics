﻿#ifndef UNITY_LIGHT_UTILITIES_INCLUDED
#define UNITY_LIGHT_UTILITIES_INCLUDED

#include "LightDefinition.cs.hlsl"

// The EnvLightData of the sky light contains a bunch of compile-time constants.
// This function sets them directly to allow the compiler to propagate them and optimize the code.
EnvLightData InitSkyEnvLightData(int envIndex)
{
    EnvLightData output;
    output.envShapeType = ENVSHAPETYPE_SKY;
    output.envIndex = envIndex;
    output.forward = float3(0.0, 0.0, 1.0);
    output.up = float3(0.0, 1.0, 0.0);
    output.right = float3(1.0, 0.0, 0.0);
    output.capturePositionWS = float3(0.0, 0.0, 0.0);
    output.offsetLS = float3(0.0, 0.0, 0.0);
    output.influenceExtents = float3(0.0, 0.0, 0.0);
    output.blendDistancePositive = float3(0.0, 0.0, 0.0);
    output.blendDistanceNegative = float3(0.0, 0.0, 0.0);
    output.blendNormalDistancePositive = float3(0.0, 0.0, 0.0);
    output.blendNormalDistanceNegative = float3(0.0, 0.0, 0.0);
    output.boxSideFadePositive = float3(0.0, 0.0, 0.0);
    output.boxSideFadeNegative = float3(0.0, 0.0, 0.0);
    output.dimmer = 1.0;

    return output;
}

EnvProxyData InitSkyEnvProxyData(int envIndex)
{
    EnvProxyData output;

    output.positionWS = float3(0.0, 0.0, 0.0);
    output.envShapeType = ENVSHAPETYPE_SKY;
    output.forward = float3(0.0, 0.0, 1.0);
    output.up = float3(0.0, 1.0, 0.0);
    output.right = float3(1.0, 0.0, 0.0);
    output.minProjectionDistance = 65504.0f;
    output.extents = float3(0.0, 0.0, 0.0);

    return output;
}

#endif // UNITY_LIGHT_UTILITIES_INCLUDED
