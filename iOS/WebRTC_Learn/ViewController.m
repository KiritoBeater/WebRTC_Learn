//
//  ViewController.m
//  WebRTC_Learn
//
//  Created by liyang on 2018/2/28.
//  Copyright © 2018年 liyang. All rights reserved.
//

#import "ViewController.h"

#import <SocketRocket/SRWebSocket.h>

@interface ViewController ()<SRWebSocketDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SRWebSocket *ws = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost:8080"]];
    ws.delegate = self;
    [ws open];
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"open");
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"fail, %@", error.localizedDescription);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(nullable NSString *)reason wasClean:(BOOL)wasClean
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSLog(@"message, %@", message);

}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
