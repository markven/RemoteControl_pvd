//
//  ViewController.m
//  GunController
//
//  Created by Liu David on 2013/12/30.
//  Copyright (c) 2013年 Liu David. All rights reserved.
//

#import "ViewController.h"
#include<CoreMotion/CoreMotion.h>
#import<CoreFoundation/CoreFoundation.h>
#import "SRWebSocket.h"


@interface ViewController ()<SRWebSocketDelegate> {
    CMMotionManager *motionManager;
    SRWebSocket *socket;
    BOOL socketConnected;
    CGPoint centerPoint;
    CGFloat range;
    
    
    CGFloat tx, ty;
}

@property (weak, nonatomic) IBOutlet UILabel *labelGyro;
@property (weak, nonatomic) IBOutlet UIView *viewTarget;
@property (weak, nonatomic) IBOutlet UIView *viewTest;

- (IBAction)pressBtnCalibration:(id)sender;
- (IBAction)scrollSlider:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    motionManager = [[CMMotionManager alloc] init];
    motionManager.deviceMotionUpdateInterval =1.0/60.0;
    if (motionManager.isDeviceMotionAvailable) {
        [motionManager startDeviceMotionUpdates];
    }
    
    [NSTimer scheduledTimerWithTimeInterval:0.0333333f
                                     target:self
                                   selector:@selector(gameLoop)
                                   userInfo:nil
                                    repeats:YES];
    
    socketConnected = NO;
    range = 0.17f;
    
    NSURL *url;
    url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/wbsc/websocket",SERVICE_HOST_ADDRESS]];
    socket = [[SRWebSocket alloc] initWithURL:url];
    socket.delegate = self;
    [socket open];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - WebSocket Delegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    //NSLog(@"webSocket receive message: %@", message);
    //self.labMsg.text = (NSString*)message;
    
    NSString * str = (NSString*)message;
    NSArray *array = [str componentsSeparatedByString:@" "];
    CGFloat x = [[array objectAtIndex:0] floatValue];
    CGFloat y = [[array objectAtIndex:1] floatValue];

    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    tx = x * screenSize.width;
    ty = y * screenSize.height;
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSLog(@"webSocket: didFailWithError:%@",error);
    //self.labMsg.text = @"Disconnect";
    [socket close];
    self.view.backgroundColor = [UIColor whiteColor];
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    
    NSLog(@"webSocketDidOpen");
    socketConnected = YES;
    self.view.backgroundColor = [UIColor greenColor];
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    //self.labMsg.text = @"Disconnect";
    NSLog(@"webSocket: didClose: %@", reason);
    socketConnected = NO;
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    // Do your thing after shaking device
    NSLog(@"reset!!");
    [self pressBtnCalibration:self];
}

#pragma mark -

-(void)gameLoop {
    static CGFloat xx = 0;
    static CGFloat yy = 0;
    
    if(socketConnected) {
        CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
        CMAttitude *attitude = deviceMotion.attitude;
        
        //self.labelGyro.text = [NSString stringWithFormat:@"%.2f  %.2f  %.2f", attitude.yaw, attitude.pitch, attitude.roll];
        
        CGFloat min, max, x, y;
        
        min = centerPoint.x - range;
        max = centerPoint.x + range;
        x = attitude.yaw;
        if(x < min) x = min;
        if(x > max) x = max;
        x = (x - min) / (max - min);
        x = 1.0f - x;
        
        min = centerPoint.y - range;
        max = centerPoint.y + range;
        y = attitude.pitch;
        if(y < min) y = min;
        if(y > max) y = max;
        y = (y - min) / (max - min);
        y = 1.0f - y;
        
        [socket send:[NSString stringWithFormat:@"%f %f", x, y]];
        
        CGSize screenSize = [UIScreen mainScreen].bounds.size;
        self.viewTest.center = CGPointMake(x * screenSize.width, y * screenSize.height);

        
        
        CGFloat f = 4;

        CGFloat distX = xx - tx;
        CGFloat distY = yy - ty;
        
        xx = xx - distX / f;
        yy = yy - distY / f;

        self.viewTarget.center = CGPointMake(xx, yy);
    }
}

- (IBAction)pressBtnCalibration:(id)sender {
    CMDeviceMotion *deviceMotion = motionManager.deviceMotion;
    CMAttitude *attitude = deviceMotion.attitude;
    
    centerPoint.x = attitude.yaw;
    centerPoint.y = attitude.pitch;
}

- (IBAction)scrollSlider:(id)sender {
    UISlider *slider = (UISlider*)sender;
    
    range = slider.value / 1000.0f;
    NSLog(@"%.3f", range);
    self.labelGyro.text = [NSString stringWithFormat:@"%.3f", range];
}

@end
