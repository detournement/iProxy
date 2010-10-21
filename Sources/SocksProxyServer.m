//
//  SocksProxyServer.m
//  iProxy
//
//  Created by Jérôme Lebel on 12/10/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SocksProxyServer.h"
#import "SharedHeader.h"
#include <unistd.h>

int proto_socks(int sock);
void relay(int cs, int ss);

@implementation SocksProxyServer

@synthesize connexionCount = _connexionCount;

+ (id)sharedSocksProxyServer
{
	static SocksProxyServer *shared = nil;
    
    if (!shared) {
    	shared = [[SocksProxyServer alloc] init];
    }
    return shared;
}

- (NSString *)serviceDomaine
{
	return SOCKS_PROXY_DOMAIN;
}

- (int)servicePort
{
	return SOCKS_PROXY_PORT;
}

- (void)_didCloseConnexion
{
	[self willChangeValueForKey:@"connexionCount"];
    _connexionCount--;
    [self didChangeValueForKey:@"connexionCount"];
}

- (void)processIncomingConnection:(NSFileHandle *)fileHandle
{
	NSAutoreleasePool *pool;
    int clientSocket, serverSocket;
    
    pool = [[NSAutoreleasePool alloc] init];
    clientSocket = [fileHandle fileDescriptor];
    serverSocket = proto_socks(clientSocket);
    if (serverSocket != -1) {
	    relay(clientSocket, serverSocket);
	    close(serverSocket);
    }
    [self performSelectorOnMainThread:@selector(_didCloseConnexion) withObject:nil waitUntilDone:NO];
    [fileHandle closeFile];
    [fileHandle release];
    [pool drain];
}

- (void)receiveIncomingConnectionNotification:(NSNotification *)notification
{
	[self willChangeValueForKey:@"connexionCount"];
    _connexionCount++;
    [self didChangeValueForKey:@"connexionCount"];
	[NSThread detachNewThreadSelector:@selector(processIncomingConnection:) toTarget:self withObject:[[[notification userInfo] objectForKey:NSFileHandleNotificationFileHandleItem] retain]];
	[[notification object] acceptConnectionInBackgroundAndNotify];
}

@end
