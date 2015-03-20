//
//  GameViewController.m
//  Flashlight
//
//  Created by Borna Noureddin.
//  Copyright (c) 2014 BCIT. All rights reserved.
//

#import "GameViewController.h"
#import <OpenGLES/ES2/glext.h>
#import "fbxsdk.h"
#import "Common.h"
#import "main.h"
#include "FBXRender.h"

#define BUFFER_OFFSET(i) ((char *)NULL + (i))

// Shader uniform indices
enum
{
    UNIFORM_MODELVIEWPROJECTION_MATRIX,
    UNIFORM_NORMAL_MATRIX,
    UNIFORM_MODELVIEW_MATRIX,
    /* more uniforms needed here... */
    UNIFORM_TEXTURE,
    UNIFORM_FLASHLIGHT_POSITION,
    UNIFORM_DIFFUSE_LIGHT_POSITION,
    UNIFORM_SHININESS,
    UNIFORM_AMBIENT_COMPONENT,
    UNIFORM_DIFFUSE_COMPONENT,
    UNIFORM_SPECULAR_COMPONENT,
    UNIFORM_X_INDEX,
    UNIFORM_Y_INDEX,
    UNIFORM_FLASHLIGHT,
    UNIFORM_FOG,
    UNIFORM_NEAR,
    UNIFORM_FAR,
    UNIFORM_FLASHLIGHT_ROT,
    UNIFORM_LIGHT_POS,
    UNIFORM_SPOT_DIR,
    UNIFORM_SPOT_CUTOFF,
    UNIFORM_INV_NORM,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

// Mini Map Shader uniform indices
enum
{
    MM_UNIFORM_X_INDEX,
    MM_UNIFORM_Y_INDEX,
    MM_UNIFORM_ROT,
    MM_UNIFORM_COLOR,
    MM_UNIFORM_SCALE,
    MM_UNIFORM_ORIENT,
    MM_NUM_UNIFORMS
};
GLint mmUniforms[MM_NUM_UNIFORMS];


@interface GameViewController () {
    GLuint _program;
    GLuint _mmProgram;
    
    // Shader uniforms
    GLKMatrix4 _modelViewProjectionMatrix;
    GLKMatrix4 _modelViewMatrix;
    GLKMatrix3 _normalMatrix;
    
    // Cube matrices
    GLKMatrix4 _cubeMVPMatrix;
    GLKMatrix4 _cubeMVMatrix;
    GLKMatrix3 _cubeNormalMatrix;
    
    // Cube matrices
    GLKMatrix4 _fbxMVPMatrix;
    GLKMatrix4 _fbxMVMatrix;
    GLKMatrix3 _fbxNormalMatrix;
    
    // Lighting parameters
    /* specify lighting parameters here...e.g., GLKVector3 flashlightPosition; */
    GLKVector3 flashlightPosition;
    GLKVector3 diffuseLightPosition;
    GLKVector4 diffuseComponent;
    float shininess;
    GLKVector4 specularComponent;
    GLKVector4 ambientDayComponent;
    GLKVector4 ambientNightComponent;
    
    // Transformation parameters
    float _rotation;
    float xRot, yRot;
    CGPoint dragStart;
    
    // Shape vertices, etc. and textures
    GLfloat *vertices, *normals, *texCoords,
        *playerVertices, *playerNormals, *playerTexCoords,
        *floorVertices, *floorNormals, *floorTexCoords,
        *ceilingVertices, *ceilingNormals, *ceilingTexCoords,
        *northVertices, *northNormals, *northTexCoords,
        *southVertices, *southNormals, *southTexCoords,
        *westVertices, *westNormals, *westTexCoords,
        *eastVertices, *eastNormals, *eastTexCoords,
        *fbxVertices, *fbxNormals,
        *enemyMapVertices, *enemyMapNormals, *enemyMapTexCoords;
    
    GLuint numIndices, *indices,
        playerNumIndices, *playerIndices,
        floorNumIndices, *floorIndices,
        ceilingNumIndices, *ceilingIndices,
        northNumIndices, *northIndices,
        southNumIndices, *southIndices,
        westNumIndices, *westIndices,
        eastNumIndices, *eastIndices,
        fbxNumIndices, *fbxIndices,
        enemyMapNumIndices, *enemyMapIndices;
    
    /* texture parameters ??? */
    GLuint crateTexture,
    crateNoWallTexture,
    crateNoLeftTexture,
    crateNoRightTexture,
    crateLeftAndRightTexture,
    extraTexture,
    fbxTexture;
    
    // GLES buffer IDs
    GLuint _vertexArray;
    GLuint _vertexBuffers[3];
    GLuint _indexBuffer;
    
    GLuint _enemyMapVertArray;
    GLuint _enemyMapVertBuffers[3];
    GLuint _enemyMapIndexBuffer;
    
    GLuint _playerVertArray;
    GLuint _playerVertBuffers[3];
    GLuint _playerIndexBuffer;
    
    GLuint _floorVertArray;
    GLuint _floorVertBuffers[3];
    GLuint _floorIndexBuffer;
    
    GLuint _ceilingVertArray;
    GLuint _ceilingVertBuffers[3];
    GLuint _ceilingIndexBuffer;
    
    GLuint _northVertArray;
    GLuint _northVertBuffers[3];
    GLuint _northIndexBuffer;
    
    GLuint _southVertArray;
    GLuint _southVertBuffers[3];
    GLuint _southIndexBuffer;
    
    GLuint _westVertArray;
    GLuint _westVertBuffers[3];
    GLuint _westIndexBuffer;
    
    GLuint _eastVertArray;
    GLuint _eastVertBuffers[3];
    GLuint _eastIndexBuffer;
    
    GLuint _fbxVertArray;
    GLuint _fbxVertBuffers[3];
    GLuint _fbxIndexBuffer;
    
    GLKVector2 _transBegin;
    GLKVector2 _transEnd;
    GLKVector2 _rotBegin;
    GLKVector2 _rotEnd;
    
    GLKVector2 _fbxTransBegin;
    GLKVector2 _fbxTransEnd;
    GLKVector2 _fbxRotBegin;
    GLKVector2 _fbxRotEnd;
    float _fbxScale;
    float _fbxScalePrev;
    
    float cubeYRot;
    bool isDay;
    int isFlashLightOn;
    int isFogOn;
    bool consoleMap;
    bool fbxMovementToggle;
    
    GLKVector3 _directVec;
    GLKVector4 mapScale;
    
    FbxManager *_sdkManager;
    FbxScene *_scene;
    FbxArray<FbxString*> animStackNameArray;
    FBXRender fbxRender;
    
    GLKVector3 fbxTarget;
    GLKVector3 fbxPosition;
    GLKVector3 heading;
    bool isMoving;
}

@property (strong, nonatomic) EAGLContext *context;

- (void)setupGL;
- (void)tearDownGL;

- (BOOL)loadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;

@end

@implementation GameViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    mapScale = GLKVector4Make(-0.2f, 0.2f, 0.2f, 1.0f);
    _MiniMap.numberOfLines = 0;
    _rotEnd.x = 180 * M_PI / 180;
    _directVec = GLKVector3Make(0.0, 0.0, 1.0);
    isDay = YES;
    isFlashLightOn = 1;
    isFogOn = 1;
    consoleMap = NO;
    fbxMovementToggle = YES;
    _fbxScale = 0.1;
 
    
    // Set up iOS gesture recognizers
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doSingleTap:)];
    singleTap.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:singleTap];
    
    UITapGestureRecognizer *doubleTap =
    [[UITapGestureRecognizer alloc] initWithTarget:
     self action:@selector(doDoubleTap:)];
    doubleTap.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:doubleTap];
    
    UITapGestureRecognizer *doubleTwoFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:
     self action:@selector(doDoubleTwoFingerTap:)];
    doubleTwoFingerTap.numberOfTapsRequired = 2;
    [doubleTwoFingerTap setNumberOfTouchesRequired:2];
    [self.view addGestureRecognizer:doubleTwoFingerTap];
    
    UIPanGestureRecognizer *rotObj = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doRotate:)];
    rotObj.minimumNumberOfTouches = 1;
    rotObj.maximumNumberOfTouches = 1;
    [self.view addGestureRecognizer:rotObj];
    
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(doTranslate:)];
    pan.minimumNumberOfTouches = 2;
    pan.maximumNumberOfTouches = 2;
    [self.view addGestureRecognizer:pan];
    
    UIPanGestureRecognizer *fbxPan = [[UIPanGestureRecognizer alloc] initWithTarget: self action:@selector(doFBXPan:)];
    fbxPan.minimumNumberOfTouches = 3;
    fbxPan.maximumNumberOfTouches = 3;
    [self.view addGestureRecognizer:fbxPan];
    
    UIPanGestureRecognizer *fbxRot = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(doRotate:)];
    fbxRot.minimumNumberOfTouches = 4;
    fbxRot.maximumNumberOfTouches = 4;
    [self.view addGestureRecognizer:rotObj];
    
    UIPinchGestureRecognizer *pinchZoom = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(doPinch:)];
    [self.view addGestureRecognizer:pinchZoom];

    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *)self.view;
    view.context = self.context;
    view.drawableDepthFormat = GLKViewDrawableDepthFormat24;
    
    mazeLevel = [[MazeGen alloc] init];
    [mazeLevel CreateMaze];
    
    isMoving = YES;
    fbxTarget = GLKVector3Make(0, 0, 0);
    fbxPosition = GLKVector3Make(0, 0, 0);
    heading = GLKVector3Make(0, 0, 0);
    
    // Set up GL
    [self setupGL];
    
}

- (void)dealloc
{
    [self CleanupFBX];
    
    [self tearDownGL];
    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    
    if ([self isViewLoaded] && ([[self view] window] == nil)) {
        self.view = nil;
        
        [self tearDownGL];
        
        if ([EAGLContext currentContext] == self.context) {
            [EAGLContext setCurrentContext:nil];
        }
        self.context = nil;
    }
}

- (void)setupGL
{
    [EAGLContext setCurrentContext:self.context];
    
    // Load shaders
    [self loadShaders];
    
    // Get uniform locations.
    uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX] = glGetUniformLocation(_program, "modelViewProjectionMatrix");
    uniforms[UNIFORM_NORMAL_MATRIX] = glGetUniformLocation(_program, "normalMatrix");
    uniforms[UNIFORM_MODELVIEW_MATRIX] = glGetUniformLocation(_program, "modelViewMatrix");
    /* more needed here... */
    uniforms[UNIFORM_TEXTURE] = glGetUniformLocation(_program, "texture");
    uniforms[UNIFORM_FLASHLIGHT_POSITION] = glGetUniformLocation(_program, "flashlightPosition");
    uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION] = glGetUniformLocation(_program, "diffuseLightPosition");
    uniforms[UNIFORM_SHININESS] = glGetUniformLocation(_program, "shininess");
    uniforms[UNIFORM_AMBIENT_COMPONENT] = glGetUniformLocation(_program, "ambientComponent");
    uniforms[UNIFORM_DIFFUSE_COMPONENT] = glGetUniformLocation(_program, "diffuseComponent");
    uniforms[UNIFORM_SPECULAR_COMPONENT] = glGetUniformLocation(_program, "specularComponent");
    uniforms[UNIFORM_X_INDEX] = glGetUniformLocation(_program, "xInd");
    uniforms[UNIFORM_Y_INDEX] = glGetUniformLocation(_program, "yInd");
    uniforms[UNIFORM_FLASHLIGHT] = glGetUniformLocation(_program, "flashLight");
    uniforms[UNIFORM_FOG] = glGetUniformLocation(_program, "fog");
    uniforms[UNIFORM_NEAR] = glGetUniformLocation(_program, "near");
    uniforms[UNIFORM_FAR] = glGetUniformLocation(_program, "far");
    uniforms[UNIFORM_FLASHLIGHT_ROT] = glGetUniformLocation(_program, "flashLightRot");
    uniforms[UNIFORM_LIGHT_POS] = glGetUniformLocation(_program, "lightPosition");
    uniforms[UNIFORM_SPOT_DIR] = glGetUniformLocation(_program, "spotDirection");
    uniforms[UNIFORM_SPOT_CUTOFF] = glGetUniformLocation(_program, "spotCutoff");
    uniforms[UNIFORM_INV_NORM] = glGetUniformLocation(_program, "invNormMat");
    
    // Get minimap uniform locations.
    mmUniforms[MM_UNIFORM_X_INDEX] = glGetUniformLocation(_mmProgram, "xInd");
    mmUniforms[MM_UNIFORM_Y_INDEX] = glGetUniformLocation(_mmProgram, "yInd");
    mmUniforms[MM_UNIFORM_ROT] = glGetUniformLocation(_mmProgram, "rot");
    mmUniforms[MM_UNIFORM_COLOR] = glGetUniformLocation(_mmProgram, "VertCol");
    mmUniforms[MM_UNIFORM_SCALE] = glGetUniformLocation(_mmProgram, "scale");
    mmUniforms[MM_UNIFORM_ORIENT] = glGetUniformLocation(_mmProgram, "orient");
    
    
    // Set up lighting parameters
    /* set values, e.g., flashlightPosition = GLKVector3Make(0.0, 0.0, 1.0); */
    flashlightPosition = GLKVector3Make(_transEnd.x, 0.0f, _transEnd.y + 1);
    diffuseLightPosition = GLKVector3Make(0.0, 1.0, 0.0);
    diffuseComponent = GLKVector4Make(0.8, 0.1, 0.1, 1.0);
    shininess = 200.0;
    specularComponent = GLKVector4Make(1.0, 1.0, 1.0, 1.0);
    
    ambientDayComponent = GLKVector4Make(0.8, 0.8, 0.8, 1.0);
    ambientNightComponent = GLKVector4Make(0.2, 0.2, 0.2, 1.0);
    
    // Initialize GL and get buffers
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_CULL_FACE);
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(3, _vertexBuffers);
    glGenBuffers(1, &_indexBuffer);
    
    // Generate vertices
    int numVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    numIndices = generateCube(0.2, &vertices, &normals, &texCoords, &indices, &numVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*numVerts, texCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*numIndices, indices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    
    // Load in and set texture
    /* use setupTexture to create crate texture */
    crateTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    crateNoWallTexture = [self setupTexture:@"crateNoWall.jpg"];
    glActiveTexture(GL_TEXTURE0);
    
    crateNoLeftTexture = [self setupTexture:@"crateNoLeft.jpg"];
    glActiveTexture(GL_TEXTURE0);
    
    crateNoRightTexture = [self setupTexture:@"crateNoRight.jpg"];
    glActiveTexture(GL_TEXTURE0);
    
    crateLeftAndRightTexture = [self setupTexture:@"crateLeftAndRight.jpg"];
    glActiveTexture(GL_TEXTURE0);
    
    fbxTexture = [self setupTexture:@"crate.jpg"];
    glActiveTexture(GL_TEXTURE0);
    
    //////////////////////////////////////////////////////////////////////////////////////
    // Generate Enemy MiniMap vertices
    
    glGenVertexArraysOES(1, &_enemyMapVertArray);
    glBindVertexArrayOES(_enemyMapVertArray);
    
    glGenBuffers(3, _enemyMapVertBuffers);
    glGenBuffers(1, &_enemyMapIndexBuffer);
    
    //
    // Generate vertices
    //
    // Player
    int enemyMapNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    enemyMapNumIndices = generateEnemy(1, &enemyMapVertices, &enemyMapNormals, &enemyMapTexCoords, &enemyMapIndices, &enemyMapNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _enemyMapVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*enemyMapNumVerts, enemyMapVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _enemyMapVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*enemyMapNumVerts, enemyMapNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _enemyMapVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*enemyMapNumVerts, enemyMapTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _enemyMapIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*enemyMapNumIndices, enemyMapIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);

    
    //////////////////////////////////////////////////////////////////////////////////////
    // Generate Maze vertices
    
    glGenVertexArraysOES(1, &_playerVertArray);
    glBindVertexArrayOES(_playerVertArray);
    
    glGenBuffers(3, _playerVertBuffers);
    glGenBuffers(1, &_playerIndexBuffer);
    
    //
    // Generate vertices
    //
    // Player
    int playerNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    playerNumIndices = generatePlayer(1, &playerVertices, &playerNormals, &playerTexCoords, &playerIndices, &playerNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _playerVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*playerNumVerts, playerVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _playerVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*playerNumVerts, playerNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _playerVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*playerNumVerts, playerTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _playerIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*playerNumIndices, playerIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    
    
    glGenVertexArraysOES(1, &_floorVertArray);
    glBindVertexArrayOES(_floorVertArray);
    
    glGenBuffers(3, _floorVertBuffers);
    glGenBuffers(1, &_floorIndexBuffer);

    //
    // Generate vertices
    //
    // Floor
    int floorNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    floorNumIndices = generateFloor(1, &floorVertices, &floorNormals, &floorTexCoords, &floorIndices, &floorNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _floorVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*floorNumVerts, floorVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _floorVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*floorNumVerts, floorNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _floorVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*floorNumVerts, floorTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _floorIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*floorNumIndices, floorIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);

    
    glGenVertexArraysOES(1, &_ceilingVertArray);
    glBindVertexArrayOES(_ceilingVertArray);
    
    glGenBuffers(3, _ceilingVertBuffers);
    glGenBuffers(1, &_ceilingIndexBuffer);
    
    //
    // Generate vertices
    //
    // Ceiling
    int ceilingNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    ceilingNumIndices = generateCeiling(1, &ceilingVertices, &ceilingNormals, &ceilingTexCoords, &ceilingIndices, &ceilingNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _ceilingVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*ceilingNumVerts, ceilingVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _ceilingVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*ceilingNumVerts, ceilingNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _ceilingVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*ceilingNumVerts, ceilingTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _ceilingIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*ceilingNumIndices, ceilingIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);

    
    glGenVertexArraysOES(1, &_northVertArray);
    glBindVertexArrayOES(_northVertArray);
    
    glGenBuffers(3, _northVertBuffers);
    glGenBuffers(1, &_northIndexBuffer);
    
    //
    // Generate vertices
    //
    // North
    int northNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    northNumIndices = generateNorthWall(1, &northVertices, &northNormals, &northTexCoords, &northIndices, &northNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _northVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*northNumVerts, northVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _northVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*northNumVerts, northNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _northVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*northNumVerts, northTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _northIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*northNumIndices, northIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);

    
    glGenVertexArraysOES(1, &_southVertArray);
    glBindVertexArrayOES(_southVertArray);
    
    glGenBuffers(3, _southVertBuffers);
    glGenBuffers(1, &_southIndexBuffer);
    
    //
    // Generate vertices
    //
    // South
    int southNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    southNumIndices = generateSouthWall(1, &southVertices, &southNormals, &southTexCoords, &southIndices, &southNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _southVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*southNumVerts, southVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _southVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*southNumVerts, southNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _southVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*southNumVerts, southTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _southIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*southNumIndices, southIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    
    
    glGenVertexArraysOES(1, &_westVertArray);
    glBindVertexArrayOES(_westVertArray);
    
    glGenBuffers(3, _westVertBuffers);
    glGenBuffers(1, &_westIndexBuffer);
    
    //
    // Generate vertices
    //
    // West
    int westNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    westNumIndices = generateWestWall(1, &westVertices, &westNormals, &westTexCoords, &westIndices, &westNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _westVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*westNumVerts, westVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _westVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*westNumVerts, westNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _westVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*westNumVerts, westTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _westIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*westNumIndices, westIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    
    
    glGenVertexArraysOES(1, &_eastVertArray);
    glBindVertexArrayOES(_eastVertArray);
    
    glGenBuffers(3, _eastVertBuffers);
    glGenBuffers(1, &_eastIndexBuffer);
    
    //
    // Generate vertices
    //
    // East
    int eastNumVerts;
    //numIndices = generateSphere(50, 1, &vertices, &normals, &texCoords, &indices, &numVerts);
    eastNumIndices = generateEastWall(1, &eastVertices, &eastNormals, &eastTexCoords, &eastIndices, &eastNumVerts);
    
    // Set up GL buffers
    glBindBuffer(GL_ARRAY_BUFFER, _eastVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*eastNumVerts, eastVertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _eastVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*eastNumVerts, eastNormals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _eastVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*eastNumVerts, eastTexCoords, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _eastIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*eastNumIndices, eastIndices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);
    
    [self InitializeFBX];
    
    //
    // Generate vertices
    //
    // fbx
    // Set up GL buffers
    
    glGenVertexArraysOES(1, &_fbxVertArray);
    glBindVertexArrayOES(_fbxVertArray);
    
    glGenBuffers(3, _fbxVertBuffers);
    glGenBuffers(1, &_fbxIndexBuffer);

    glBindBuffer(GL_ARRAY_BUFFER, _fbxVertBuffers[0]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*fbxRender.numVertices, fbxRender.vertices, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _fbxVertBuffers[1]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*3*fbxRender.numNormals, fbxRender.normals, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribNormal);
    glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, 3*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ARRAY_BUFFER, _fbxVertBuffers[2]);
    glBufferData(GL_ARRAY_BUFFER, sizeof(GLfloat)*2*fbxRender.numUVs, fbxRender.uvs, GL_STATIC_DRAW);
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, 2*sizeof(float), BUFFER_OFFSET(0));
    
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _fbxIndexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(int)*fbxRender.numIndices, fbxRender.indices, GL_STATIC_DRAW);
    
    glBindVertexArrayOES(0);

}

- (void)tearDownGL
{
    [EAGLContext setCurrentContext:self.context];
    
    // Delete GL buffers
    glDeleteBuffers(3, _vertexBuffers);
    glDeleteBuffers(1, &_indexBuffer);
    glDeleteVertexArraysOES(1, &_vertexArray);
    
    // Delete vertices buffers
    if (vertices)
        free(vertices);
    if (indices)
        free(indices);
    if (normals)
        free(normals);
    if (texCoords)
        free(texCoords);
    
    // Delete shader program
    if (_program) {
        glDeleteProgram(_program);
        _program = 0;
    }
}


#pragma mark - iOS gesture events

- (IBAction)doSingleTap:(UITapGestureRecognizer *)recognizer
{
    dragStart = [recognizer locationInView:self.view];
}

- (IBAction)doDoubleTap:(UITapGestureRecognizer *) recognizer
{
    xRot = 30 * M_PI / 180;;
    _rotEnd.x = 180 * M_PI / 180;;
    _rotation = 0.0f;
    _transEnd.x = 0.0f;
    _transEnd.y = 0.0f;
    
}

- (IBAction)doDoubleTwoFingerTap:(UITapGestureRecognizer *)recognizer
{
    consoleMap = !consoleMap;
}

- (IBAction)doRotate:(UIPanGestureRecognizer *)recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        _rotBegin = GLKVector2Make(0.0f, 0.0f);
    }
    CGPoint rotation = [recognizer translationInView:recognizer.view];
    float x = rotation.x / recognizer.view.frame.size.width * 5.0f;
    float y = rotation.y / recognizer.view.frame.size.height * 5.0f;
    
    float dx = _rotEnd.x + (x-_rotBegin.x);
    float dy = _rotEnd.y - (y-_rotBegin.y);
    
    _rotEnd = GLKVector2Make(dx, dy);
    _rotBegin = GLKVector2Make(x, y);
}

- (IBAction)doTranslate:(UIPanGestureRecognizer *) recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        _transBegin = GLKVector2Make(0.0f, 0.0f);
    }
    CGPoint translation = [recognizer translationInView:recognizer.view];
    float x = translation.x / recognizer.view.frame.size.width * 5.0f;
    float y = translation.y / recognizer.view.frame.size.height * 5.0f;
    
    float dx = _transEnd.x + (x-_transBegin.x);
    float dy = _transEnd.y - (y-_transBegin.y);
    
    _transEnd = GLKVector2Make(dx, dy);
    _transBegin = GLKVector2Make(x, y);
}

- (IBAction)doFBXPan:(UIPanGestureRecognizer *) recognizer
{
    if ([recognizer state] == UIGestureRecognizerStateBegan)
    {
        if(fbxMovementToggle)
            _fbxTransBegin = GLKVector2Make(0.0f, 0.0f);
        else
            _fbxRotBegin = GLKVector2Make(0.0f, 0.0f);
    }
    
    CGPoint translation = [recognizer translationInView:recognizer.view];
    float x = translation.x / recognizer.view.frame.size.width * 5.0f;
    float y = translation.y / recognizer.view.frame.size.height * 5.0f;
    
    float dx = 0;
    float dy = 0;
    if(fbxMovementToggle)
    {
        dx = _fbxTransEnd.x + (x-_fbxTransBegin.x);
        dy = _fbxTransEnd.y - (y-_fbxTransBegin.y);
    }
    else
    {
        dx = _fbxRotEnd.x + (x-_fbxRotBegin.x);
        dy = _fbxRotEnd.y - (y-_fbxRotBegin.y);

    }
    
    if(fbxMovementToggle)
    {
        _fbxTransEnd = GLKVector2Make(dx, dy);
        _fbxTransBegin = GLKVector2Make(x, y);
    }
    else
    {
        _fbxRotEnd = GLKVector2Make(dx, dy);
        _fbxRotBegin = GLKVector2Make(x, y);
    }
}

-(IBAction)doPinch:(UIPinchGestureRecognizer *)recognizer
{

    if([(UIPinchGestureRecognizer*)recognizer state] == UIGestureRecognizerStateBegan)
    {
        _fbxScalePrev = _fbxScale;
    }
    
    _fbxScale = _fbxScalePrev * recognizer.scale;
    
    if(_fbxScale > 1)
        _fbxScale = 1;
    else if(_fbxScale < 0.01)
        _fbxScale = 0.01;
}

#pragma mark - GLKView and GLKViewController delegate methods

- (void)update
{
    if(isMoving)
    {
        if(abs(fbxPosition.x - fbxTarget.x) < 0.005 && abs(fbxPosition.z - fbxTarget.z) < 0.005)
        {
            int direction = arc4random() % 4;
            
            switch(direction)
            {
                case 0:
                {
                    if(![mazeLevel GetCellAt:floor(fbxPosition.x) And:floor(fbxPosition.z)][0])//North
                    {
                        if(floor(fbxPosition.x) == 0 &&floor(fbxPosition.z) == 0)
                        {
                            heading = GLKVector3Make(0, 0, 0);
                            fbxPosition = fbxTarget;
                            fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z);
                        }
                        else
                        {
                            heading = GLKVector3Make(-0.001, 0, 0);
                            fbxPosition = fbxTarget;
                            fbxTarget = GLKVector3Make(fbxPosition.x - 0.5, fbxPosition.y, fbxPosition.z);
                        }
                    }
                    else
                    {
                        heading = GLKVector3Make(0, 0, 0);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z);
                    }
                    break;
                }
                case 1:
                {
                    if(![mazeLevel GetCellAt:floor(fbxPosition.x) And:floor(fbxPosition.z)][1])//south
                    {
                        heading = GLKVector3Make(0.001, 0, 0);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x + 0.5, fbxPosition.y, fbxPosition.z);
                    }
                    else
                    {
                        heading = GLKVector3Make(0, 0, 0);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z);
                    }
                    break;
                }
                case 2:
                {
                    if(![mazeLevel GetCellAt:floor(fbxPosition.x) And:floor(fbxPosition.z)][2])//west
                    {
                        heading = GLKVector3Make(0, 0, -0.001);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z - 0.5);
                    }
                    else
                    {
                        heading = GLKVector3Make(0, 0, 0);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z);

                    }
                    break;
                }
                case 3:
                {
                    if(![mazeLevel GetCellAt:floor(fbxPosition.x) And:floor(fbxPosition.z)][3])//east
                    {
                        heading = GLKVector3Make(0, 0, 0.001);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z + 0.5);
                    }
                    else
                    {
                        heading = GLKVector3Make(0, 0, 0);
                        fbxPosition = fbxTarget;
                        fbxTarget = GLKVector3Make(fbxPosition.x, fbxPosition.y, fbxPosition.z);
                    }
                    break;
                }
            }
            
        }
        fbxPosition = GLKVector3Make(fbxPosition.x + heading.x, fbxPosition.y + heading.y, fbxPosition.z + heading.z);
    }
    
    printf("Target: %f, %f, %f\n", fbxTarget.x, fbxTarget.y, fbxTarget.z);
    printf("Position: %f, %f, %f\n", fbxPosition.x, fbxPosition.y, fbxPosition.z);
    //heading = GLKVector3Make(0, 0, -0.001);
    //fbxPosition = GLKVector3Make(fbxPosition.x + heading.x, fbxPosition.y + heading.y, fbxPosition.z + heading.z);
    
    cubeYRot += 0.005f;
    // Set up base model view matrix (place camera)
    GLKMatrix4 baseModelViewMatrix = GLKMatrix4MakeTranslation(0.0f, 0.0f, 0.0f);
    baseModelViewMatrix = GLKMatrix4Rotate(baseModelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    
    // Set up model view matrix (place model in world)
    _modelViewMatrix = GLKMatrix4Identity;

    //_modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, xRot, 1.0f, 0.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, _rotEnd.x, 0.0f, 1.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Rotate(_modelViewMatrix, _rotation, 0.0f, 1.0f, 0.0f);
    _modelViewMatrix = GLKMatrix4Translate(_modelViewMatrix, _transEnd.x, 0.0f, _transEnd.y);
    _modelViewMatrix = GLKMatrix4Multiply(baseModelViewMatrix, _modelViewMatrix);
    
    // Calculate normal matrix
    _normalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(_modelViewMatrix), NULL);
    
    // Calculate projection matrix
    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0.1f, 100.0f);
    
    _modelViewProjectionMatrix = GLKMatrix4Multiply(projectionMatrix, _modelViewMatrix);
    
    _cubeMVMatrix = GLKMatrix4Identity;
    _cubeMVMatrix = GLKMatrix4Rotate(_cubeMVMatrix, _rotEnd.x, 0.0f, 1.0f, 0.0f);
    _cubeMVMatrix = GLKMatrix4Translate(_cubeMVMatrix, _transEnd.x, 0.0f, _transEnd.y);
    _cubeMVMatrix = GLKMatrix4Rotate(_cubeMVMatrix, cubeYRot, 0.0f, 1.0f, 0.0f);

    _cubeMVMatrix = GLKMatrix4Multiply(baseModelViewMatrix, _cubeMVMatrix);
    
    _cubeNormalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(_cubeMVMatrix), NULL);
    _cubeMVPMatrix = GLKMatrix4Multiply(projectionMatrix, _cubeMVMatrix);
    
    _fbxMVMatrix = GLKMatrix4Identity;
    //_fbxMVMatrix = GLKMatrix4Translate(_fbxMVMatrix, _transEnd.x, 0.0f, _transEnd.y);
    _fbxMVMatrix = GLKMatrix4Translate(_fbxMVMatrix, -_fbxTransEnd.x, _fbxTransEnd.y, 0.0f);
    _fbxMVMatrix = GLKMatrix4Translate(_fbxMVMatrix, fbxPosition.x, fbxPosition.y, fbxPosition.z);
    _fbxMVMatrix = GLKMatrix4Scale(_fbxMVMatrix, _fbxScale, _fbxScale, _fbxScale);
    //_fbxMVMatrix = GLKMatrix4Rotate(_fbxMVMatrix, _rotEnd.x, 0.0f, 1.0f, 0.0f);
    _fbxMVMatrix = GLKMatrix4Rotate(_fbxMVMatrix, _fbxRotEnd.x, 0.0f, 1.0f, 0.0f);
    _fbxMVMatrix = GLKMatrix4Rotate(_fbxMVMatrix, -_fbxRotEnd.y, 1.0f, 0.0f, 0.0f);
    //_fbxMVMatrix = GLKMatrix4Rotate(_fbxMVMatrix, _rotation, 0.0f, 1.0f, 0.0f);

    _fbxMVMatrix = GLKMatrix4Multiply(_modelViewMatrix, _fbxMVMatrix);
    
    _fbxNormalMatrix = GLKMatrix3InvertAndTranspose(GLKMatrix4GetMatrix3(_fbxMVMatrix), NULL);
    _fbxMVPMatrix = GLKMatrix4Multiply(projectionMatrix, _fbxMVMatrix);
}

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
    // Clear window
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Select VAO and shaders
    glUseProgram(_program);
    
    GLKMatrix4 rotate = GLKMatrix4Rotate(GLKMatrix4Identity, _rotEnd.x, 0.0, 1.0, 0.0);
    GLKVector3 spotDirVec = GLKVector3Make(0.0, 0.0, 1.0);
    spotDirVec = GLKMatrix4MultiplyVector3(rotate, spotDirVec);
    // Set up uniforms
    glUniform4fv(uniforms[UNIFORM_LIGHT_POS], 1, GLKVector4Make(0.0, 0.0, 0.0, 1.0).v);
    glUniform3fv(uniforms[UNIFORM_SPOT_DIR], 1, spotDirVec.v);
    glUniform1f(uniforms[UNIFORM_SPOT_CUTOFF], 30);
    glUniformMatrix3fv(uniforms[UNIFORM_INV_NORM], 1, 0, GLKMatrix3Invert(_normalMatrix, 0).m);
    
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _cubeMVPMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _cubeNormalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _cubeMVMatrix.m);
    /* set lighting parameters... */
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform1i(uniforms[UNIFORM_FLASHLIGHT], isFlashLightOn);
    glUniform1i(uniforms[UNIFORM_FOG], isFogOn);
    glUniform1f(uniforms[UNIFORM_NEAR], _NearSlider.value);
    glUniform1f(uniforms[UNIFORM_FAR], _FarSlider.value);
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_ROT], 1, GLKVector3Make(_rotEnd.x, 0.0f, 0.0f).v);
    if(isDay)
    {
        glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientDayComponent.v);
    }
    else
    {
        glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientNightComponent.v);
    }

    glUniform1f(uniforms[UNIFORM_X_INDEX], 0);
    glUniform1f(uniforms[UNIFORM_Y_INDEX], 0);
    
    glBindTexture(GL_TEXTURE_2D, crateTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    // Select VBO and draw
    glBindVertexArrayOES(_vertexArray);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glDrawElements(GL_TRIANGLES, numIndices, GL_UNSIGNED_INT, 0);
    
    //Draw the fbx
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _fbxMVPMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _fbxNormalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _fbxMVMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_INV_NORM], 1, 0, GLKMatrix3Invert(_fbxNormalMatrix, 0).m);
    glUniform1f(uniforms[UNIFORM_X_INDEX], 0);
    glUniform1f(uniforms[UNIFORM_Y_INDEX], 0);
    
    glBindTexture(GL_TEXTURE_2D, fbxTexture);
    glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
    
    glBindVertexArrayOES(_fbxVertArray);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _fbxIndexBuffer);
    glDrawElements(GL_TRIANGLES, fbxRender.numIndices, GL_UNSIGNED_INT, 0);
    
    // Set up uniforms
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEWPROJECTION_MATRIX], 1, 0, _modelViewProjectionMatrix.m);
    glUniformMatrix3fv(uniforms[UNIFORM_NORMAL_MATRIX], 1, 0, _normalMatrix.m);
    glUniformMatrix4fv(uniforms[UNIFORM_MODELVIEW_MATRIX], 1, 0, _modelViewMatrix.m);
    /* set lighting parameters... */
    glUniform3fv(uniforms[UNIFORM_FLASHLIGHT_POSITION], 1, flashlightPosition.v);
    glUniform3fv(uniforms[UNIFORM_DIFFUSE_LIGHT_POSITION], 1, diffuseLightPosition.v);
    glUniform4fv(uniforms[UNIFORM_DIFFUSE_COMPONENT], 1, diffuseComponent.v);
    glUniform1f(uniforms[UNIFORM_SHININESS], shininess);
    glUniform4fv(uniforms[UNIFORM_SPECULAR_COMPONENT], 1, specularComponent.v);
    glUniform1i(uniforms[UNIFORM_FLASHLIGHT], isFlashLightOn);
    glUniform1i(uniforms[UNIFORM_FOG], isFogOn);
    glUniform1f(uniforms[UNIFORM_NEAR], _NearSlider.value);
    glUniform1f(uniforms[UNIFORM_FAR], _FarSlider.value);
    glUniform1f(uniforms[UNIFORM_FLASHLIGHT_ROT], _rotEnd.x);
    if(isDay)
    {
        glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientDayComponent.v);
    }
    else
    {
        glUniform4fv(uniforms[UNIFORM_AMBIENT_COMPONENT], 1, ambientNightComponent.v);
    }
    glUniform1f(uniforms[UNIFORM_X_INDEX], 0);
    glUniform1f(uniforms[UNIFORM_Y_INDEX], 0);
    
    //Draw Maze
    for(int x = 0; x < [mazeLevel GetWidth]; x++)
    {
        for(int y = 0; y < [mazeLevel GetLength]; y++)
        {
            glBindVertexArrayOES(_floorVertArray);
            glUniform1f(uniforms[UNIFORM_X_INDEX], x);
            glUniform1f(uniforms[UNIFORM_Y_INDEX], y);
            glBindTexture(GL_TEXTURE_2D, crateTexture);
            glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
            glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _floorIndexBuffer);
            glDrawElements(GL_TRIANGLES, floorNumIndices, GL_UNSIGNED_INT, 0);
            
            if([mazeLevel GetCellAt:x And:y][0])
            {
                if([mazeLevel GetCellAt:x And:y][2])
                {
                    if([mazeLevel GetCellAt:x And:y][3])
                    {
                        glBindTexture(GL_TEXTURE_2D, crateLeftAndRightTexture);
                    }
                    else
                    {
                        glBindTexture(GL_TEXTURE_2D, crateNoRightTexture);
                    }
                }
                else if([mazeLevel GetCellAt:x And:y][3])
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoLeftTexture);
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoWallTexture);
                }
                
                glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                
                glBindVertexArrayOES(_northVertArray);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _northIndexBuffer);
                glDrawElements(GL_TRIANGLES, northNumIndices, GL_UNSIGNED_INT, 0);
            }
            if([mazeLevel GetCellAt:x And:y][1])
            {
                if([mazeLevel GetCellAt:x And:y][3])
                {
                    if([mazeLevel GetCellAt:x And:y][2])
                    {
                        glBindTexture(GL_TEXTURE_2D, crateLeftAndRightTexture);
                    }
                    else
                    {
                        glBindTexture(GL_TEXTURE_2D, crateNoRightTexture);
                    }
                }
                else if([mazeLevel GetCellAt:x And:y][2])
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoLeftTexture);
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoWallTexture);
                }
                glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                glBindVertexArrayOES(_southVertArray);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _southIndexBuffer);
                glDrawElements(GL_TRIANGLES, southNumIndices, GL_UNSIGNED_INT, 0);
            }
            if([mazeLevel GetCellAt:x And:y][2])
            {
                if([mazeLevel GetCellAt:x And:y][1])
                {
                    if([mazeLevel GetCellAt:x And:y][0])
                    {
                        glBindTexture(GL_TEXTURE_2D, crateLeftAndRightTexture);
                    }
                    else
                    {
                        glBindTexture(GL_TEXTURE_2D, crateNoRightTexture);
                    }
                }
                else if([mazeLevel GetCellAt:x And:y][0])
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoLeftTexture);
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoWallTexture);
                }
                glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                glBindVertexArrayOES(_westVertArray);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _westIndexBuffer);
                glDrawElements(GL_TRIANGLES, westNumIndices, GL_UNSIGNED_INT, 0);
            }
            if([mazeLevel GetCellAt:x And:y][3])
            {
                if([mazeLevel GetCellAt:x And:y][0])
                {
                    if([mazeLevel GetCellAt:x And:y][1])
                    {
                        glBindTexture(GL_TEXTURE_2D, crateLeftAndRightTexture);
                    }
                    else
                    {
                        glBindTexture(GL_TEXTURE_2D, crateNoRightTexture);
                    }
                }
                else if([mazeLevel GetCellAt:x And:y][1])
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoLeftTexture);
                }
                else
                {
                    glBindTexture(GL_TEXTURE_2D, crateNoWallTexture);
                }
                glUniform1i(uniforms[UNIFORM_TEXTURE], 0);
                glBindVertexArrayOES(_eastVertArray);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _eastIndexBuffer);
                glDrawElements(GL_TRIANGLES, eastNumIndices, GL_UNSIGNED_INT, 0);
            }
        }
    }
    
    if(consoleMap)
    {
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        //_MiniMap.text = [mazeLevel GetMap];
        //_MiniMap.hidden = NO;
        GLKMatrix4 mapRot = GLKMatrix4Rotate(GLKMatrix4Identity, M_PI / 2.0f, 1.0, 0.0, 0.0);
        //render minimap
        // Set up uniforms
        glUseProgram(_mmProgram);
        
        //draw player
        glUniformMatrix4fv(mmUniforms[MM_UNIFORM_ROT], 1, 0, mapRot.m);
        glUniform4fv(mmUniforms[MM_UNIFORM_SCALE], 1, mapScale.v);
        glUniform4fv(mmUniforms[MM_UNIFORM_COLOR], 1, GLKVector4Make(0.0f, 0.0f, 1.0f, 0.75f).v);
        glBindVertexArrayOES(_playerVertArray);
        glUniform1f(mmUniforms[MM_UNIFORM_X_INDEX], -_transEnd.x * 2);
        glUniform1f(mmUniforms[MM_UNIFORM_Y_INDEX], -_transEnd.y * 2);
        glUniformMatrix4fv(mmUniforms[MM_UNIFORM_ORIENT], 1, 0, GLKMatrix4Rotate(GLKMatrix4Identity, -_rotEnd.x + M_PI, 0.0, 0.0, 1.0).m);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _playerIndexBuffer);
        glDrawElements(GL_TRIANGLES, playerNumIndices, GL_UNSIGNED_INT, 0);
        
        //draw enemy
        glUniform4fv(mmUniforms[MM_UNIFORM_COLOR], 1, GLKVector4Make(1.0f, 0.0f, 0.0f, 0.75f).v);
        glBindVertexArrayOES(_enemyMapVertArray);
        glUniform1f(mmUniforms[MM_UNIFORM_X_INDEX], fbxPosition.x * 2);
        glUniform1f(mmUniforms[MM_UNIFORM_Y_INDEX], fbxPosition.z * 2);
        glUniformMatrix4fv(mmUniforms[MM_UNIFORM_ORIENT], 1, 0, GLKMatrix4Rotate(GLKMatrix4Identity, -_rotEnd.x + M_PI, 0.0, 0.0, 1.0).m);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _enemyMapIndexBuffer);
        glDrawElements(GL_TRIANGLES, enemyMapNumIndices, GL_UNSIGNED_INT, 0);
        
        glUniform1i(mmUniforms[MM_UNIFORM_X_INDEX], 0);
        glUniform1i(mmUniforms[MM_UNIFORM_Y_INDEX], 0);
        glUniformMatrix4fv(mmUniforms[MM_UNIFORM_ORIENT], 1, 0, GLKMatrix4Rotate(GLKMatrix4Identity, 0.0, 0.0, 0.0, 1.0).m);

        
        //Draw Maze
        for(int x = 0; x < [mazeLevel GetWidth]; x++)
        {
            for(int y = 0; y < [mazeLevel GetLength]; y++)
            {
                glUniform4fv(mmUniforms[MM_UNIFORM_COLOR], 1, GLKVector4Make(0.5f, 0.5f, 0.0f, 0.75f).v);
                glBindVertexArrayOES(_floorVertArray);
                glUniform1f(mmUniforms[MM_UNIFORM_X_INDEX], x);
                glUniform1f(mmUniforms[MM_UNIFORM_Y_INDEX], y);
                glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _floorIndexBuffer);
                glDrawElements(GL_TRIANGLES, floorNumIndices, GL_UNSIGNED_INT, 0);
                glUniform4fv(mmUniforms[MM_UNIFORM_COLOR], 1, GLKVector4Make(0.0f, 1.0f, 0.0f, 0.75f).v);
                
                if([mazeLevel GetCellAt:x And:y][0])
                {
                    glBindVertexArrayOES(_northVertArray);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _northIndexBuffer);
                    glDrawElements(GL_LINE_LOOP, northNumIndices, GL_UNSIGNED_INT, 0);
                }
                if([mazeLevel GetCellAt:x And:y][1])
                {
                    glBindVertexArrayOES(_southVertArray);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _southIndexBuffer);
                    glDrawElements(GL_LINE_LOOP, southNumIndices, GL_UNSIGNED_INT, 0);
                }
                if([mazeLevel GetCellAt:x And:y][2])
                {
                    glBindVertexArrayOES(_westVertArray);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _westIndexBuffer);
                    glDrawElements(GL_LINE_LOOP, westNumIndices, GL_UNSIGNED_INT, 0);
                }
                if([mazeLevel GetCellAt:x And:y][3])
                {
                    glBindVertexArrayOES(_eastVertArray);
                    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _eastIndexBuffer);
                    glDrawElements(GL_LINE_LOOP, eastNumIndices, GL_UNSIGNED_INT, 0);
                }
            }
        }
        glDisable(GL_BLEND);
        

    }
    else
    {
        _MiniMap.text = [NSString stringWithUTF8String: ""];
        _MiniMap.hidden = YES;
    }
}

#pragma mark -  OpenGL ES 2 shader compilation

- (BOOL)loadShaders
{
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    _program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(_program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_program, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_program, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_program, GLKVertexAttribTexCoord0, "texCoordIn");
    
    // Link program.
    if (![self linkProgram:_program]) {
        NSLog(@"Failed to link program: %d", _program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    //Mini Map Shader
    GLuint vertMMShader, fragMMShader;
    NSString *vertMMShaderPathname, *fragMMShaderPathname;
    
    // Create shader program.
    _mmProgram = glCreateProgram();
    
    // Create and compile vertex shader.
    vertMMShaderPathname = [[NSBundle mainBundle] pathForResource:@"MiniMapShader" ofType:@"vsh"];
    if (![self compileShader:&vertMMShader type:GL_VERTEX_SHADER file:vertMMShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragMMShaderPathname = [[NSBundle mainBundle] pathForResource:@"MiniMapShader" ofType:@"fsh"];
    if (![self compileShader:&fragMMShader type:GL_FRAGMENT_SHADER file:fragMMShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(_mmProgram, vertMMShader);
    
    // Attach fragment shader to program.
    glAttachShader(_mmProgram, fragMMShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(_mmProgram, GLKVertexAttribPosition, "position");
    glBindAttribLocation(_mmProgram, GLKVertexAttribNormal, "normal");
    glBindAttribLocation(_mmProgram, GLKVertexAttribTexCoord0, "texCoordIn");
    
    // Link program.
    if (![self linkProgram:_mmProgram]) {
        NSLog(@"Failed to link program: %d", _mmProgram);
        
        if (vertMMShader) {
            glDeleteShader(vertMMShader);
            vertMMShader = 0;
        }
        if (fragMMShader) {
            glDeleteShader(fragMMShader);
            fragMMShader = 0;
        }
        if (_mmProgram) {
            glDeleteProgram(_mmProgram);
            _mmProgram = 0;
        }
        
        return NO;
    }
    
    // Release vertex and fragment shaders.
    if (vertMMShader) {
        glDetachShader(_mmProgram, vertMMShader);
        glDeleteShader(vertMMShader);
    }
    if (fragMMShader) {
        glDetachShader(_mmProgram, fragMMShader);
        glDeleteShader(fragMMShader);
    }
    
    return YES;
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file
{
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return NO;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
#if defined(DEBUG)
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
#endif
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0) {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    glLinkProgram(prog);
    
#if defined(DEBUG)
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
#endif
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0) {
        return NO;
    }
    
    return YES;
}



#pragma mark - Utility functions

// Load in and set up texture image (adapted from Ray Wenderlich)
- (GLuint)setupTexture:(NSString *)fileName
{
    CGImageRef spriteImage = [UIImage imageNamed:fileName].CGImage;
    if (!spriteImage) {
        NSLog(@"Failed to load image %@", fileName);
        exit(1);
    }
    
    size_t width = CGImageGetWidth(spriteImage);
    size_t height = CGImageGetHeight(spriteImage);
    
    GLubyte *spriteData = (GLubyte *) calloc(width*height*4, sizeof(GLubyte));
    
    CGContextRef spriteContext = CGBitmapContextCreate(spriteData, width, height, 8, width*4, CGImageGetColorSpace(spriteImage), kCGImageAlphaPremultipliedLast);
    
    CGContextDrawImage(spriteContext, CGRectMake(0, 0, width, height), spriteImage);
    
    CGContextRelease(spriteContext);
    
    GLuint texName;
    glGenTextures(1, &texName);
    glBindTexture(GL_TEXTURE_2D, texName);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
    
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, width, height, 0, GL_RGBA, GL_UNSIGNED_BYTE, spriteData);
    
    free(spriteData);
    return texName;
}

int generatePlayer(float scale, GLfloat **vertices, GLfloat **normals,
                  GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat floorVerts[] =
    {
        -0.0f, -0.5f, 0.25f,
        -0.25f, -0.5f,  -0.25f,
        0.25f, -0.5f,  -0.25f,
        0.0f, -0.5f, -0.25f,
        
        //-0.5f, -0.5f, -0.5f,
        //-0.5f, -0.5f,  0.5f,
        //0.5f, -0.5f,  0.5f,
        //0.5f, -0.5f, -0.5f,
    };
    
    GLfloat floorNormals[] =
    {
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
    };
    
    GLfloat floorTex[] =
    {
        /*
         0.0f, 0.0f,
         0.0f, 1.0f,
         1.0f, 1.0f,
         1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        
    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, floorVerts, sizeof ( floorVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, floorNormals, sizeof ( floorNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, floorTex, sizeof ( floorTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            0, 3, 2,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}


int generateEnemy(float scale, GLfloat **vertices, GLfloat **normals,
                   GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat floorVerts[] =
    {
        -0.0f, -0.5f, 0.25f,
        -0.25f, -0.5f,  -0.0f,
        0.25f, -0.5f,  -0.0f,
        0.0f, -0.5f, -0.25f,
        
        //-0.5f, -0.5f, -0.5f,
        //-0.5f, -0.5f,  0.5f,
        //0.5f, -0.5f,  0.5f,
        //0.5f, -0.5f, -0.5f,
    };
    
    GLfloat floorNormals[] =
    {
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
    };
    
    GLfloat floorTex[] =
    {
        /*
         0.0f, 0.0f,
         0.0f, 1.0f,
         1.0f, 1.0f,
         1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        
    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, floorVerts, sizeof ( floorVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, floorNormals, sizeof ( floorNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, floorTex, sizeof ( floorTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            3, 1, 2,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}



int generateFloor(float scale, GLfloat **vertices, GLfloat **normals,
                  GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat floorVerts[] =
    {
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f, -0.5f, -0.5f,
    };
    
    GLfloat floorNormals[] =
    {
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,

    };
    
    GLfloat floorTex[] =
    {
        /*
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,

    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)(float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, floorVerts, sizeof ( floorVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, floorNormals, sizeof ( floorNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, floorTex, sizeof ( floorTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            //0, 2, 1,
            //0, 3, 2,
            
            0,1,2,
            0,2,3,
            
  //          4, 5, 6,
//            4, 6, 7,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

int generateCeiling(float scale, GLfloat **vertices, GLfloat **normals,
                    GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat ceilingVerts[] =
    {
        -0.5f,  0.5f, -0.5f,
        -0.5f,  0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
    };
    
    GLfloat ceilingNormals[] =
    {
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,

    };
    
    GLfloat ceilingTex[] =
    {
        /*
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,

    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, ceilingVerts, sizeof ( ceilingVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, ceilingNormals, sizeof ( ceilingNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, ceilingTex, sizeof ( ceilingTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            0, 3, 2,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

int generateWestWall(float scale, GLfloat **vertices, GLfloat **normals,
                      GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat northVerts[] =
    {
        -0.5f, -0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,
        0.5f,  0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
    };
    
    GLfloat northNormals[] =
    {
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,

        
    };
    
    GLfloat northTex[] =
    {
        /*
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,

    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, northVerts, sizeof ( northVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, northNormals, sizeof ( northNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, northTex, sizeof ( northTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            0, 3, 2,
            //0,1,2,
            //0,2,3,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

int generateEastWall(float scale, GLfloat **vertices, GLfloat **normals,
                      GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat southVerts[] =
    {
        -0.5f, -0.5f, 0.5f,
        -0.5f,  0.5f, 0.5f,
        0.5f,  0.5f, 0.5f,
        0.5f, -0.5f, 0.5f,
    };
    
    GLfloat southNormals[] =
    {
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,

    };
    
    GLfloat southTex[] =
    {
        /*
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,

    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, southVerts, sizeof ( southVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, southNormals, sizeof ( southNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, southTex, sizeof ( southTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
//            0, 2, 1,
//            0, 3, 2,
            0,1,2,
            0,2,3,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

int generateNorthWall(float scale, GLfloat **vertices, GLfloat **normals,
                     GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    GLfloat westVerts[] =
    {
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        -0.5f,  0.5f,  0.5f,
        -0.5f,  0.5f, -0.5f,
    };
    
    GLfloat westNormals[] =
    {
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,

    };
    
    GLfloat westTex[] =
    {
        /*
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,

    };
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, westVerts, sizeof ( westVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, westNormals, sizeof ( westNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, westTex, sizeof ( westTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            0, 3, 2,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

int generateSouthWall(float scale, GLfloat **vertices, GLfloat **normals,
                     GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 4;
    int numIndices = 6;
    
    GLfloat eastVerts[] =
    {
        0.5f, -0.5f, -0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
    };
    
    GLfloat eastNormals[] =
    {
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
    };
    
    GLfloat eastTex[] =
    {
        /*
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,*/
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
    };
    
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, eastVerts, sizeof ( eastVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, eastNormals, sizeof ( eastNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, eastTex, sizeof ( eastTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
//            0, 2, 1,
//            0, 3, 2,
            0,1,2,
            0,2,3,
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}





// Generate vertices, normals, texture coordinates and indices for cube
//      Adapted from Dan Ginsburg, Budirijanto Purnomo from the book
//      OpenGL(R) ES 2.0 Programming Guide
int generateCube(float scale, GLfloat **vertices, GLfloat **normals,
                 GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int numVertices = 24;
    int numIndices = 36;
    
    GLfloat cubeVerts[] =
    {
        //bottom
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f, -0.5f, -0.5f,
        //top
        -0.5f,  0.5f, -0.5f,
        -0.5f,  0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
        //north
        -0.5f, -0.5f, -0.5f,
        -0.5f,  0.5f, -0.5f,
        0.5f,  0.5f, -0.5f,
        0.5f, -0.5f, -0.5f,
        //south
        -0.5f, -0.5f, 0.5f,
        -0.5f,  0.5f, 0.5f,
        0.5f,  0.5f, 0.5f,
        0.5f, -0.5f, 0.5f,
        //west
        -0.5f, -0.5f, -0.5f,
        -0.5f, -0.5f,  0.5f,
        -0.5f,  0.5f,  0.5f,
        -0.5f,  0.5f, -0.5f,
        //east
        0.5f, -0.5f, -0.5f,
        0.5f, -0.5f,  0.5f,
        0.5f,  0.5f,  0.5f,
        0.5f,  0.5f, -0.5f,
    };
    
    GLfloat cubeNormals[] =
    {
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, -1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 1.0f, 0.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, -1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        0.0f, 0.0f, 1.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        -1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
        1.0f, 0.0f, 0.0f,
    };
    
    GLfloat cubeTex[] =
    {
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        1.0f, 0.0f,
        1.0f, 1.0f,
        0.0f, 1.0f,
        0.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
        0.0f, 0.0f,
        0.0f, 1.0f,
        1.0f, 1.0f,
        1.0f, 0.0f,
    };
    
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *vertices, cubeVerts, sizeof ( cubeVerts ) );
        
        for ( i = 0; i < numVertices * 3; i++ )
        {
            ( *vertices ) [i] *= scale;
        }
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
        memcpy ( *normals, cubeNormals, sizeof ( cubeNormals ) );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
        memcpy ( *texCoords, cubeTex, sizeof ( cubeTex ) ) ;
    }
    
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint cubeIndices[] =
        {
            0, 2, 1,
            0, 3, 2,
            4, 5, 6,
            4, 6, 7,
            8, 9, 10,
            8, 10, 11,
            12, 15, 14,
            12, 14, 13,
            16, 17, 18,
            16, 18, 19,
            20, 23, 22,
            20, 22, 21
        };
        
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
        memcpy ( *indices, cubeIndices, sizeof ( cubeIndices ) );
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

// Generate vertices, normals, texture coordinates and indices for sphere
//      Adapted from Dan Ginsburg, Budirijanto Purnomo from the book
//      OpenGL(R) ES 2.0 Programming Guide
int generateSphere(int numSlices, float radius, GLfloat **vertices, GLfloat **normals,
                   GLfloat **texCoords, GLuint **indices, int *numVerts)
{
    int i;
    int j;
    int numParallels = numSlices / 2;
    int numVertices = ( numParallels + 1 ) * ( numSlices + 1 );
    int numIndices = numParallels * numSlices * 6;
    float angleStep = ( 2.0f * M_PI ) / ( ( float ) numSlices );
    
    // Allocate memory for buffers
    if ( vertices != NULL )
    {
        *vertices = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
    }
    
    if ( normals != NULL )
    {
        *normals = (float*)malloc ( sizeof ( GLfloat ) * 3 * numVertices );
    }
    
    if ( texCoords != NULL )
    {
        *texCoords = (float*)malloc ( sizeof ( GLfloat ) * 2 * numVertices );
    }
    
    if ( indices != NULL )
    {
        *indices = (GLuint*)malloc ( sizeof ( GLuint ) * numIndices );
    }
    
    for ( i = 0; i < numParallels + 1; i++ )
    {
        for ( j = 0; j < numSlices + 1; j++ )
        {
            int vertex = ( i * ( numSlices + 1 ) + j ) * 3;
            
            if ( vertices )
            {
                ( *vertices ) [vertex + 0] = radius * sinf ( angleStep * ( float ) i ) *
                sinf ( angleStep * ( float ) j );
                ( *vertices ) [vertex + 1] = radius * cosf ( angleStep * ( float ) i );
                ( *vertices ) [vertex + 2] = radius * sinf ( angleStep * ( float ) i ) *
                cosf ( angleStep * ( float ) j );
            }
            
            if ( normals )
            {
                ( *normals ) [vertex + 0] = ( *vertices ) [vertex + 0] / radius;
                ( *normals ) [vertex + 1] = ( *vertices ) [vertex + 1] / radius;
                ( *normals ) [vertex + 2] = ( *vertices ) [vertex + 2] / radius;
            }
            
            if ( texCoords )
            {
                int texIndex = ( i * ( numSlices + 1 ) + j ) * 2;
                ( *texCoords ) [texIndex + 0] = ( float ) j / ( float ) numSlices;
                ( *texCoords ) [texIndex + 1] = ( 1.0f - ( float ) i ) / ( float ) ( numParallels - 1 );
            }
        }
    }
    
    // Generate the indices
    if ( indices != NULL )
    {
        GLuint *indexBuf = ( *indices );
        
        for ( i = 0; i < numParallels ; i++ )
        {
            for ( j = 0; j < numSlices; j++ )
            {
                *indexBuf++  = i * ( numSlices + 1 ) + j;
                *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + j;
                *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + ( j + 1 );
                
                *indexBuf++ = i * ( numSlices + 1 ) + j;
                *indexBuf++ = ( i + 1 ) * ( numSlices + 1 ) + ( j + 1 );
                *indexBuf++ = i * ( numSlices + 1 ) + ( j + 1 );
            }
        }
    }
    
    if (numVerts != NULL)
        *numVerts = numVertices;
    return numIndices;
}

// >>>

- (IBAction)ToggleDayNight:(id)sender {
    isDay = !isDay;
}

- (IBAction)FlashLightToggle:(id)sender {
    if(isFlashLightOn == 0)
    {
        isFlashLightOn = 1;
    }
    else
    {
        isFlashLightOn = 0;
    }
}

- (IBAction)FogToggle:(id)sender {
    if(isFogOn == 0)
    {
        isFogOn = 1;
    }
    else
    {
        isFogOn = 0;
    }
}

- (IBAction)FBXMoveToggle:(id)sender
{
    fbxMovementToggle = !fbxMovementToggle;
}

- (void)InitializeFBX
{
    // Prepare the FBX SDK.
    InitializeSdkObjects (_sdkManager, _scene) ;
    
    NSString *modelFileName = [[NSBundle mainBundle] pathForResource:@"Chicken_PT" ofType:@"fbx"];
    [self LoadFBXScene:modelFileName];
}

- (void)CleanupFBX
{
    bool bResult ;
    DestroySdkObjects (_sdkManager, bResult) ;
}

- (BOOL)LoadFBXScene:(NSString *)filename
{
    FbxString fbxSt([filename cStringUsingEncoding:[NSString defaultCStringEncoding]]) ;
    bool bResult = LoadScene(_sdkManager, _scene, fbxSt.Buffer());
    if (!bResult) return FALSE;
    
    GLuint vPosition = glGetAttribLocation(_program, "vPosition");
    GLuint vNormal = glGetAttribLocation(_program, "vNormal");
    GLuint vTexCoord = glGetAttribLocation(_program, "vTexCoord");
    glEnableVertexAttribArray(vPosition);
    glEnableVertexAttribArray(vNormal);
    glEnableVertexAttribArray(vTexCoord);
    FbxNode *rootNode = _scene->GetRootNode();
    fbxRender.Initialize(rootNode, vPosition, vNormal, vTexCoord);
    
    return TRUE;
}

@end
