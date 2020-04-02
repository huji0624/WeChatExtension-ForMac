//
//  TKAboutWindowController.m
//  WeChatExtension
//
//  Created by WeChatExtension on 2018/5/4.
//  Copyright © 2018年 WeChatExtension. All rights reserved.
//

#import "TKAboutWindowController.h"
#import "YMNetWorkHelper.h"
#import "YMMessageManager.h"

@interface TKAboutWindowController ()

@property (weak) IBOutlet NSTextField *versionLabel;
@property (weak) IBOutlet NSTextField *projectHomepageLabel;
@property (weak) IBOutlet NSTextField *titleLabel;
@property (weak) IBOutlet NSTextField *homePageTitleLabel;
@property (weak) IBOutlet NSImageView *aliPay;

@end

@implementation TKAboutWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    self.titleLabel.stringValue = YMLanguage(@"微信小助手", @"WeChat Assistant");
    self.homePageTitleLabel.stringValue = YMLanguage(@"项目主页:", @"Project Homepage:");
    self.window.backgroundColor = [NSColor whiteColor];
    NSDictionary *localInfo = [[TKWeChatPluginConfig sharedConfig] localInfoPlist];
    if (!localInfo) {
        return;
    }
    NSString *localBundle = localInfo[@"CFBundleShortVersionString"];
    self.versionLabel.stringValue = localBundle;
    
    NSBundle *bundle = [NSBundle bundleWithIdentifier:@"MustangYM.WeChatExtension"];
    NSString *imgPath= [bundle pathForImageResource:@"aliPayCode.png"];
    NSImage *placeholder = [[NSImage alloc] initWithContentsOfFile:imgPath];
    self.aliPay.image = placeholder;
}

- (void)delSendMsg:(NSString*)mid{
    __weak __typeof (self) wself = self;
    NSDictionary *param = [NSDictionary dictionaryWithObject:mid forKey:@"mid"];
    
    [[YMNetWorkHelper share] GET:@"https://api.guyu.biz:8082/delsend" parameters:param success:^(id responsobject) {
        NSDictionary *ret = responsobject;
        NSLog(@"del http success.%@",ret);
        
        if([ret[@"err"] isEqualToNumber:@(0)]){
            NSLog(@"send ok!!!!will try 2 second later.");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself autoSendMsg];
            });
        }else{
            NSLog(@"msg err!!!!try again:%@",mid);
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self delSendMsg:mid];
            });
        }
    } failure:^(NSError *error, NSString *failureMsg) {
        NSLog(@"network err!!!!try again.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self delSendMsg:mid];
        });
    }];
}

- (void)autoSendMsg{
    if([self.titleLabel.stringValue isEqualToString:@"stopping"]){
        self.titleLabel.stringValue = @"stopped";
        return;
    }
    
    __weak __typeof (self) wself = self;
    
    [[YMNetWorkHelper share] GET:@"https://api.guyu.biz:8082/needsend" parameters:nil success:^(id responsobject) {
        NSDictionary *dict = responsobject;
        if([dict objectForKey:@"msg"]){
            NSString *msgid = dict[@"id"];
            NSString *msg = dict[@"msg"];
            NSString *to = dict[@"to"];
            NSLog(@"yes will send.");
            [[YMMessageManager shareManager] sendTextMessage:msg toUsrName:to delay:0];
            
            [wself delSendMsg:msgid];
        }else{
            NSLog(@"no msg!!!!will try 10 second later.");
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(10 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [wself autoSendMsg];
            });
        }
    } failure:^(NSError *error, NSString *failureMsg) {
        NSLog(@"fail!!!!will try 2 second later.");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [wself autoSendMsg];
        });
    }];
}

- (IBAction)didClickHomepageURL:(NSButton *)sender {
//    [[NSWorkspace sharedWorkspace] openURL:[NSURL //URLWithString:@"https://github.com/MustangYM/WeChatExtension-ForMac"]];
    
    if([self.titleLabel.stringValue isEqualToString:@"started"]){
        self.titleLabel.stringValue = @"stopping";
    }else if([self.titleLabel.stringValue isEqualToString:@"stopping"]){
    }else{
        self.titleLabel.stringValue = @"started";
        [self autoSendMsg];
    }
}

@end
