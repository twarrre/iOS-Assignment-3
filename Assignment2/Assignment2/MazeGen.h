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

-(void)CreateMaze;

-(int)GetWidth;

-(int)GetLength;

-(bool*)GetCellAt:(int)row And:(int)col;

-(NSString*)GetMap;

@end
#endif
