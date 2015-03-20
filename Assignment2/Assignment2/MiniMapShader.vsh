//
//  Shader.vsh
//  Flashlight
//
//  Created by Borna Noureddin.
//  Copyright (c) 2014 BCIT. All rights reserved.
//
#define M_PI 3.1415926535897932384626433832795
precision mediump float;

attribute vec4 position;

uniform vec4 VertCol;
varying vec4 Color;

uniform float xInd;
uniform float yInd;
uniform mat4 rot;
uniform mat4 orient;
uniform vec4 scale;

void main()
{
    vec4 index = vec4(xInd, yInd, 0, 1);
    vec4 newPosition = position * rot * orient;
    vec4 finalPosition = newPosition + index;

    Color = VertCol;
    gl_Position = finalPosition * scale;
}
