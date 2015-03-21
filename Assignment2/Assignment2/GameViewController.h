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
//The fog near slider
@property (weak, nonatomic) IBOutlet UISlider *NearSlider;
//The fog far slider
@property (weak, nonatomic) IBOutlet UISlider *FarSlider;
//Toggle between day and night
@property (weak, nonatomic) IBOutlet UIButton *DayNightToggleBtn;
//Minimap
@property (weak, nonatomic) IBOutlet UILabel *MiniMap;
//Label for fbx rotation toggle
@property (strong, nonatomic) IBOutlet UILabel *FBXRotationMovementToggleLabel;
//Label for fbx movement toggle
@property (strong, nonatomic) IBOutlet UILabel *FBXZMovementToggleLabel;

//Toggles day and night
- (IBAction)ToggleDayNight:(id)sender;

//Toggles the flashlight
- (IBAction)FlashLightToggle:(id)sender;

//Toggles the fog
- (IBAction)FogToggle:(id)sender;

//Toggles the movement/rotation
- (IBAction)FBXMoveToggle:(id)sender;

//Toggles the z rotation
- (IBAction)FBXZMovementToggle:(id)sender;

//Resets the enemy
- (IBAction)ResetEnemy:(id)sender;
@end
