//
//  Shader.fsh
//  Flashlight
//
//  Created by Borna Noureddin.
//  Copyright (c) 2014 BCIT. All rights reserved.
//
precision mediump float;

varying vec3 spotDirVar;
varying float spotCutoffVar;
varying mat3 normMat;

varying vec3 eyeNormal;
varying vec4 eyePos;
varying vec2 texCoordOut;
varying vec3 flashLightOn;
varying vec3 fogOn;
varying float fogFactor;
/* set up a uniform sampler2D to get texture */
uniform sampler2D texture;

/* set up uniforms for lighting parameters */
uniform vec3 flashlightPosition;
uniform vec3 diffuseLightPosition;
uniform vec4 diffuseComponent;
uniform float shininess;
uniform vec4 specularComponent;
uniform vec4 ambientComponent;

uniform mat4 modelViewMatrix;
uniform mat3 invNormMat;

void main()
{
    vec4 lightPos;
    vec3 spotDir;
    vec3 lightDir;
    float angle;
    
    lightPos = vec4(0.0, 0.0, 0.0, 1.0) * modelViewMatrix;
    spotDir = normalize(invNormMat * spotDirVar);
    lightDir = normalize(eyePos.xyz - flashlightPosition);
    
    angle = dot(normalize(spotDir), -normalize(lightDir));
    angle = max(angle, 0.0);
    
    
    vec4 ambient = ambientComponent;
    
    vec3 N = normalize(eyeNormal);
    float nDotVP = max(0.0, dot(N, normalize(diffuseLightPosition)));
    vec4 diffuse = diffuseComponent * nDotVP;
    
    //vec3 newEye = vec3(eyePos.x * fLRot.x, eyePos.y * fLRot.y, eyePos.z * fLRot.z);
    vec3 E = normalize(-eyePos.xyz);
    vec3 L = normalize(flashlightPosition + eyePos.xyz);
    vec3 H = normalize(L+E);
    float Ks = pow(max(dot(N, H), 0.0), shininess);
    vec4 specular;
    
    if(flashLightOn.x > 0.5)
    {
    
        if(acos(angle) < radians(spotCutoffVar))
        {
            specular = clamp(Ks*specularComponent, 0.0, 1.0);
        }
        else
        {
            specular = vec4(0.0, 0.0, 0.0, 1.0);
        }
    }
    else
    {
        specular = vec4(0.0, 0.0, 0.0, 1.0);
    }
    /*
    if( dot(L, N) < 0.0  || flashLightOn.x < 0.5) {
        specular = vec4(0.0, 0.0, 0.0, 1.0);
    }
    else
    {
        specular = Ks*specularComponent;
    }*/
    
    /* add ambient and specular components here as in:
     gl_FragColor = (ambient + diffuse + specular) * texture2D(texture, texCoordOut);
     */
    vec4 fogCol = vec4(0.5, 0.5, 0.5, 1.0);
    vec4 finalCol = (ambient + diffuse + specular) * texture2D(texture, texCoordOut);
    if(fogOn.x > 0.5)
    {
        gl_FragColor = mix(fogCol, finalCol, fogFactor);
    }
    else
    {
        gl_FragColor = finalCol;
    }
    gl_FragColor.a = 1.0;
}
