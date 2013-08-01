//
//  SDClient.m
//  Zephyros
//
//  Created by Steven Degutis on 7/31/13.
//  Copyright (c) 2013 Giant Robot Software. All rights reserved.
//

#import "SDClient.h"

#define FOREVER (60*60*24*365)

@implementation SDClient

- (void) waitForNewMessage {
    [self.sock readDataToData:[@"\n" dataUsingEncoding:NSUTF8StringEncoding]
                  withTimeout:FOREVER
                          tag:0];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == 0) {
        NSString* str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSInteger size = [str integerValue];
        
        [self.sock readDataToLength:size
                        withTimeout:FOREVER
                                tag:1];
    }
    else if (tag == 1) {
        id obj = [NSJSONSerialization JSONObjectWithData:data options:0 error:0];
        [self handleMessage:obj];
        [self waitForNewMessage];
    }
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.disconnectedHandler(self);
}

- (void) handleMessage:(id)msg {
    NSLog(@"new msg: %@", msg);
    [self sendMessage:msg];
}

- (void) sendMessage:(id)msg {
    NSLog(@"sending [%@]", msg);
    msg = @[[msg objectAtIndex:0], @"ok"];
    
    NSData* data = [NSJSONSerialization dataWithJSONObject:msg options:0 error:NULL];
    NSString* len = [NSString stringWithFormat:@"%ld", [data length]];
    [self.sock writeData:[len dataUsingEncoding:NSUTF8StringEncoding] withTimeout:3 tag:0];
    [self.sock writeData:[GCDAsyncSocket LFData] withTimeout:3 tag:0];
    [self.sock writeData:data withTimeout:3 tag:0];
}

@end
