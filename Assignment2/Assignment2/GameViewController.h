//
//  GameViewController.h
//  Assignment2
//
//  Created by Tim Wang on 2015-02-27.
//  Copyright (c) 2015 Tim Wang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import "MazeGen.h"

@interface GameViewController : GLKViewController
{
    MazeGen *mazeLevel;
}
@property (weak, nonatomic) IBOutlet UISlider *NearSlider;
@property (weak, nonatomic) IBOutlet UISlider *FarSlider;
@property (weak, nonatomic) IBOutlet UIButton *DayNightToggleBtn;
@property (weak, nonatomic) IBOutlet UILabel *MiniMap;
- (IBAction)ToggleDayNight:(id)sender;
- (IBAction)FlashLightToggle:(id)sender;
- (IBAction)FogToggle:(id)sender;
- (IBAction)FBXMoveToggle:(id)sender;
- (IBAction)FBXZMovementToggle:(id)sender;
@property (strong, nonatomic) IBOutlet UILabel *FBXRotationMovementToggleLabel;
@property (strong, nonatomic) IBOutlet UILabel *FBXZMovementToggleLabel;
@end
