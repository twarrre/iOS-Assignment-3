 //////////////////////////////////////////////////////////////////////////
//
//  FBXRender
//
//  (c) 2010-2015 Borna Noureddin
//
//////////////////////////////////////////////////////////////////////////


#define _USE_MATH_DEFINES
#include <math.h>
#include "FBXRender.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))


bool FBXRender::Initialize(FbxNode* rootNode, GLuint shaderPosAttr, GLuint shaderNormalAttr, GLuint shaderTexCoordAttr)
{
	glGenBuffers(3, vbo);
	vertices = normals = uvs =  NULL;
	numVertices = numNormals = numUVs = 0;

    if (rootNode)
        TraverseFBXNodes(rootNode);
	//LoadVBO(shaderPosAttr, shaderNormalAttr);

    initialized = true;

    return true;
}

void FBXRender::Purge()
{
    if (!initialized)
        return;
    glDeleteBuffers(1, &vbo[2]);
    glDeleteBuffers(1, &vbo[1]);
	glDeleteBuffers(1, &vbo[0]);
	if (vertices)
		delete vertices;
	if (normals)
		delete normals;
    if (uvs)
        delete uvs;
}

bool FBXRender::Update()
{
    if (!initialized)
        return false;
	return true;
}

bool FBXRender::Render()
{
    if (!initialized)
        return false;

    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

	if (indices)
	{
		glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, vidx);
		glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, NULL);
	}
	else
	{
		glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
		glDrawArrays(GL_TRIANGLES, 0, numVertices);
	}

	return true;
}

void FBXRender::TraverseFBXNodes(FbxNode* node)
{
	// Get any transforms that could change the position
	FbxDouble3 trans = node->LclTranslation.Get();
	FbxDouble3 rot = node->LclRotation.Get();
	FbxDouble3 scale = node->LclScaling.Get();
	
	// Determine the number of children there are
	int numChildren = node->GetChildCount();
	FbxNode* childNode = 0;
	for (int i = 0; i < numChildren; i++) {
		childNode = node->GetChild(i);
		FbxMesh* mesh = childNode->GetMesh();
		if (mesh != NULL) {
			// ========= Get the vertices from the mesh ==============
            
            // ========= Get the indices from the mesh ===============
            numIndices = mesh->GetPolygonVertexCount();
            indices = (GLuint *)mesh->GetPolygonVertices();
            
			GLfloat* tempVerts = new GLfloat[numIndices * 3];
			for (int j = 0; j < numIndices; j++) {
				FbxVector4 coord = mesh->GetControlPointAt(indices[j]);
				tempVerts[j*3+0] = (GLfloat)coord.mData[0];
				tempVerts[j*3+1] = (GLfloat)coord.mData[1];
				tempVerts[j*3+2] = (GLfloat)coord.mData[2];
                //index++;
			}
			vertices = tempVerts;
			numVertices = numIndices;
			
			// ========= Get the normals from the mesh ===============
			FbxGeometryElementNormal* normalElement = mesh->GetElementNormal();
			if (normalElement) {
				numNormals = mesh->GetPolygonCount()*3;
				GLfloat* tempNormals = new GLfloat[numNormals*3];
				int vertexCounter = 0;
				// Loop through the triangle meshes
				for(int polyCounter = 0; polyCounter < mesh->GetPolygonCount(); polyCounter++)
                {
					// Loop through each vertex of the triangle
                    for(int i = 0; i < 3; i++)
                    {
                        //Get the normal for this vertex
                        FbxVector4 normal = normalElement->GetDirectArray().GetAt(vertexCounter);
						tempNormals[vertexCounter*3+0] = normal[0];
						tempNormals[vertexCounter*3+1] = normal[1];
						tempNormals[vertexCounter*3+2] = normal[2];
                    }
					vertexCounter += 3;
                }
				normals = tempNormals;
			}
            
            // ==== Texture Coordinates
            FbxGeometryElementUV* uvElement = mesh->GetElementUV(0);
            if(uvElement)
            {
                numUVs = mesh->GetPolygonCount()*3;
                GLfloat* tempUVs = new GLfloat[numUVs * 2];
                int vertexCounter = 0;
                
                for(int polyCounter = 0; polyCounter < mesh->GetPolygonCount(); polyCounter++)
                {
                    int sInd = mesh->GetPolygonVertexIndex(polyCounter);
                    for(int i = 0; i < 3; i++)
                    {
                        int uvIndex = mesh->GetTextureUVIndex(polyCounter, i);
                        FbxVector2 uv = uvElement->GetDirectArray().GetAt(uvIndex);
                        tempUVs[(sInd + i) * 2] = uv[0];
                        tempUVs[(sInd + i) * 2 + 1] = uv[1] * -1;
                    }
                    vertexCounter += 1;
                }
                uvs = tempUVs;
            }
		} // else

		TraverseFBXNodes(childNode);
	} // for
}

void FBXRender::LoadVBO(GLuint shaderPosAttr, GLuint shaderNormalAttr)
{
	if (vertices) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo[0]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 3 * numVertices, vertices, GL_STATIC_DRAW);
        glEnableVertexAttribArray(shaderPosAttr);
        glVertexAttribPointer(shaderPosAttr, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
	}

	if (normals) {
        glBindBuffer(GL_ARRAY_BUFFER, vbo[1]);
        glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat) * 3 * numNormals, normals, GL_STATIC_DRAW);
        glEnableVertexAttribArray(shaderNormalAttr);
        glVertexAttribPointer(shaderNormalAttr, 3, GL_FLOAT, GL_FALSE, 3 * sizeof(float), 0);
	}
}
