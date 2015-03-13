//
//  Shader.fsh
//  Flashlight
//
//  Created by Borna Noureddin.
//  Copyright (c) 2014 BCIT. All rights reserved.
//
precision mediump float;
varying lowp vec4 Color;

void main()
{
    gl_FragColor = Color;
}
