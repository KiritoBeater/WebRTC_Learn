//
//  ViewController.m
//  WebRTC_Learn
//
//  Created by liyang on 2018/2/28.
//  Copyright © 2018年 liyang. All rights reserved.
//

#import "ViewController.h"

#import <SocketRocket/SRWebSocket.h>
#import <WebRTC/WebRTC.h>

static NSString *const RTCSTUNServerURL = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL2 = @"stun:23.21.150.121";

@interface ViewController ()<SRWebSocketDelegate, RTCPeerConnectionDelegate>

@property (nonatomic, weak) SRWebSocket *ws;

@property (nonatomic, strong) RTCPeerConnectionFactory *factory;

@property (nonatomic, strong) RTCPeerConnection *connection;

@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *myView;

@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *otherView;

@property (nonatomic, copy) NSString *memberID;

@property (nonatomic, copy) NSString *toMemberID;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    SRWebSocket *ws = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:@"ws://localhost:8080"]];
    ws.delegate = self;
    [ws open];
    self.ws = ws;
}

#pragma mark - ReceiveMessage

- (void)joinRoomMessageHandle: (NSDictionary *)messageDic {
    NSString *myId = messageDic[@"id"];
    self.memberID = myId;
    RTCMediaStream *localStream = [self.factory mediaStreamWithStreamId:myId];
    //音频
//    RTCAudioTrack *audioTrack = [self.factory audioTrackWithTrackId:myId];
//    [localStream addAudioTrack:audioTrack];
    //视频
    RTCVideoSource *videoSource = [self.factory videoSource];
    RTCVideoTrack *videoTrack = [self.factory videoTrackWithSource:videoSource trackId:myId];
    [localStream addVideoTrack:videoTrack];
    [videoTrack addRenderer:self.myView];
    
    // 创建connection
    RTCPeerConnection *connection = [self.factory peerConnectionWithConfiguration:[self configuration] constraints:[self localVideoConstraints] delegate:self];
    [connection addStream:localStream];
    self.connection = connection;
    
    // 获取自己的offer 发给对方
    [connection offerForConstraints:[self localVideoConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        NSDictionary *dic = @{@"type": @"offer",
                              @"memberId": self.memberID,
                              @"data": @{@"type": [RTCSessionDescription stringForType:sdp.type],
                                         @"sdp": sdp.sdp}};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        [self.ws send:jsonData];
    }];
    
}

- (void)offerMessageHandle: (NSDictionary *)messageDic {
    NSString *type = messageDic[@"type"];
    NSString *sdp = messageDic[@"sdp"];
    RTCSessionDescription *sessionDescription = [[RTCSessionDescription alloc] initWithType:[RTCSessionDescription typeForString:type] sdp:sdp];
    [self.connection setRemoteDescription:sessionDescription completionHandler:^(NSError * _Nullable error) {
        [self sendAnswer];
    }];
}

// 获取自己的ansser 发给对方
- (void)sendAnswer {
    [self.connection answerForConstraints:[self localVideoConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        NSDictionary *dic = @{@"type": @"answer",
                              @"memberId": self.memberID,
                              @"data": @{@"type": [RTCSessionDescription stringForType:sdp.type],
                                         @"sdp": sdp.sdp}};
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
        [self.ws send:jsonData];
    }];
}

- (void)answerMessageHandle: (NSDictionary *)messageDic {
    NSString *type = messageDic[@"type"];
    NSString *sdp = messageDic[@"sdp"];
    RTCSessionDescription *sessionDescription = [[RTCSessionDescription alloc] initWithType:[RTCSessionDescription typeForString:type] sdp:sdp];
    [self.connection setRemoteDescription:sessionDescription completionHandler:^(NSError * _Nullable error) {
        
    }];
}

- (void)iceCandidateMessageHandle: (NSDictionary *)messageDic {
    NSString *sdp = messageDic[@"sdp"];
    int sdpMLineIndex = [messageDic[@"sdpMLineIndex"] intValue];
    NSString *sdpMid = messageDic[@"sdpMid"];
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
    [self.connection addIceCandidate:candidate];
}

- (void)closeMessageHandle: (NSDictionary *)messageDic {
    
}

//初始化STUN Server （ICE Server）
- (RTCIceServer *)defaultSTUNServer {
    return [[RTCIceServer alloc] initWithURLStrings:@[RTCSTUNServerURL, RTCSTUNServerURL2]];
}

- (RTCMediaConstraints *)localVideoConstraints
{
    NSDictionary *mandatory = @{kRTCMediaConstraintsMaxWidth: @(640), kRTCMediaConstraintsMinWidth: @(640), kRTCMediaConstraintsMaxHeight: @(480), kRTCMediaConstraintsMinHeight: @(480), kRTCMediaConstraintsMinFrameRate: @(15)};
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatory optionalConstraints:nil];
    return constraints;
}

- (RTCConfiguration *)configuration {
    RTCConfiguration *configuration = [[RTCConfiguration alloc] init];
    configuration.iceServers = @[[self defaultSTUNServer]];
    return configuration;
}


#pragma mark - SRWebSocketDelegate

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
    NSLog(@"close");
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message {
    NSDictionary *jsonDic = [NSJSONSerialization JSONObjectWithData:message options:0 error:nil];
    NSLog(@"message, %@", jsonDic);
    
    NSString *type = jsonDic[@"type"];
    NSDictionary *dataDic = jsonDic[@"data"];
    if ([type isEqualToString:@"JoinRoom"]) {
        [self joinRoomMessageHandle:dataDic];
    } else if ([type isEqualToString:@"Offer"]) {
        [self offerMessageHandle:dataDic];
    } else if ([type isEqualToString:@"Answer"]) {
        [self answerMessageHandle:dataDic];
    } else if ([type isEqualToString:@"IceCandidate"]) {
        [self iceCandidateMessageHandle:dataDic];
    } else if ([type isEqualToString:@"Close"]) {
        [self closeMessageHandle:dataDic];
    }

}

#pragma mark - RTCPeerConnectionDelegate

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didAddStream:(nonnull RTCMediaStream *)stream {
    // 显示远程视频。
    [stream.videoTracks.lastObject addRenderer:self.otherView];
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState {
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState {
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged {
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didGenerateIceCandidate:(nonnull RTCIceCandidate *)candidate {
    // 把这个发给对方；
    NSDictionary *dic = @{@"type": @"IceCandidate",
                          @"memberId": self.memberID,
                          @"data": @{@"sdp": candidate.sdp,
                                     @"sdpMLineIndex": @(candidate.sdpMLineIndex),
                                     @"sdpMid": candidate.sdpMid}};
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dic options:0 error:nil];
    [self.ws send:jsonData];
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didOpenDataChannel:(nonnull RTCDataChannel *)dataChannel {
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveIceCandidates:(nonnull NSArray<RTCIceCandidate *> *)candidates {
    
}

- (void)peerConnection:(nonnull RTCPeerConnection *)peerConnection didRemoveStream:(nonnull RTCMediaStream *)stream {
    
}

- (void)peerConnectionShouldNegotiate:(nonnull RTCPeerConnection *)peerConnection {
    
}

- (RTCPeerConnectionFactory *)factory
{
    if (!_factory) {
        _factory = [[RTCPeerConnectionFactory alloc] init];
    }
    return _factory;
}

@end
