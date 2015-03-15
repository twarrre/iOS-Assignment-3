//////////////////////////////////////////////////////////////////////////
//
//  FBXRender
//
//  (c) 2010-2015 Borna Noureddin
//
//////////////////////////////////////////////////////////////////////////

#ifndef FBXRENDER_H
#define FBXRENDER_H

#define FBXSDK_NEW_API
#include "fbxsdk.h"
#include <OpenGLES/ES2/gl.h>

using namespace std;

struct MeshExtents
{
	bool xInit, yInit, zInit;
	GLfloat xMin, xMax;
	GLfloat yMin, yMax;
	GLfloat zMin, zMax;
};


class FBXRender
{
public:

    FBXRender() { initialized = false; };
    ~FBXRender() { initialized = false; };

	bool Initialize(FbxNode *rootNode, GLuint shaderPosAttr, GLuint shaderNormalAttr, GLuint shaderTexCoordAttr);
	void Purge();
	bool Update();
	bool Render();
    
    GLfloat *vertices;
    GLfloat *normals;
    GLfloat *uvs;
    GLuint *indices;
    GLuint *uvIndices;
    GLuint numVertices, numNormals, numIndices, numUVs, numUVIndices;

private:
    bool initialized;
	//GLfloat *vertices;
	//GLfloat *normals;
	//GLuint *indices;
	//GLuint numVertices, numNormals, numIndices;
    GLuint vbo[2];
    GLuint vidx;
	MeshExtents meshExtents;

	void TraverseFBXNodes(FbxNode* node);
	void LoadVBO(GLuint shaderPosAttr, GLuint shaderNormalAttr);
};


#endif