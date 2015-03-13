//
//  MazeGen.m
//  Assignment2
//
//  Created by Tim Wang on 2015-02-27.
//  Copyright (c) 2015 Tim Wang. All rights reserved.
//

#import "MazeGen.h"
#include "Maze.h"

struct MazeClass
{
    Maze theMaze;
};

@implementation MazeGen

- (id)init
{
    self = [super init];
    if(self)
    {
        mazeObject = new MazeClass;
    }

    return self;
}

-(void)CreateMaze
{
    mazeObject->theMaze.Create();
}

-(int)GetWidth
{
    return mazeObject->theMaze.GetWidth();
}

-(int)GetLength
{
    return mazeObject->theMaze.GetLength();
}

-(bool*)GetCellAt:(int)row And:(int)col
{
    bool* cellLayout = (bool*)malloc(sizeof(bool) * 4);
    cellLayout[0] = mazeObject->theMaze.GetCell(row, col).northWallPresent;
    cellLayout[1] = mazeObject->theMaze.GetCell(row, col).southWallPresent;
    cellLayout[2] = mazeObject->theMaze.GetCell(row, col).westWallPresent;
    cellLayout[3] = mazeObject->theMaze.GetCell(row, col).eastWallPresent;
    return cellLayout;
}

-(NSString*)GetMap
{
    NSString *mazeMap = [NSString stringWithUTF8String: mazeObject->theMaze.GetMap().c_str()];
    return mazeMap;
}
@end
