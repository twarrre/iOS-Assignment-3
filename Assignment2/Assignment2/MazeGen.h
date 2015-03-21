//
//  MazeGen.h
//  Assignment2
//
//  Created by Tim Wang on 2015-02-27.
//  Copyright (c) 2015 Tim Wang. All rights reserved.
//

#ifndef Assignment2_MazeGen_h
#define Assignment2_MazeGen_h
#import <Foundation/Foundation.h>

struct MazeClass;

@interface MazeGen : NSObject
{
    @private
    struct MazeClass *mazeObject;
}

//Creates the maze
-(void)CreateMaze;

//Gets the width of the maze
-(int)GetWidth;

//Gets the length of the maze
-(int)GetLength;

//Get the specific cell at the particular indices
-(bool*)GetCellAt:(int)row And:(int)col;

//Gets the map in a string
-(NSString*)GetMap;

@end
#endif
