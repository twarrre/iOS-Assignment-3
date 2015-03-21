//
//  Shader.vsh
//  Flashlight
//
//  Created by Borna Noureddin.
//  Copyright (c) 2014 BCIT. All rights reserved.
//
precision mediump float;

uniform vec4 lightPosition;
uniform vec3 spotDirection;
uniform float spotCutoff;

varying vec4 lightPosVar;
varying vec3 spotDirVar;
varying float spotCutoffVar;

attribute vec4 position;
attribute vec3 normal;
attribute vec2 texCoordIn;

uniform float xInd;
uniform float yInd;
uniform int flashLight;
uniform int fog;

varying vec3 eyeNormal;
varying vec4 eyePos;
varying vec2 texCoordOut;
varying vec3 flashLightOn;
varying vec3 fogOn;
varying float fogFactor;
varying float atten;

uniform mat4 modelViewProjectionMatrix;
uniform mat4 modelViewMatrix;
uniform mat3 normalMatrix;
uniform float far;
uniform float near;

//varying mat3 normMat;
uniform mat3 invNormMat;

void main()
{
    spotDirVar = spotDirection;
    spotCutoffVar = spotCutoff;
    //normMat = normalMatrix;
    
    vec4 index = vec4(xInd, 0, yInd, 1);
    vec4 newPosition = position + index;
    // Calculate normal vector in eye coordinates
    eyeNormal = (normalMatrix * normal);
    
    // Calculate vertex position in view coordinates
    eyePos = modelViewMatrix * newPosition;
    
    // Pass through texture coordinate
    texCoordOut = texCoordIn;
    
    flashLightOn = vec3(flashLight, 0, 0);
    fogOn = vec3(fog, 0, 0);
    
    float z = length(eyePos);
    fogFactor = (far - z) / (far - near);
    fogFactor = clamp(fogFactor, 0.0, 1.0);

    gl_Position = modelViewProjectionMatrix * newPosition;
}
