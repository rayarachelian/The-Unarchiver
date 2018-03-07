#import "CSByteStreamHandle.h"

#define DART_CHUNK 20960

@interface XADDARTRLEHandle : CSByteStreamHandle
{
	int repeatedbyteA, repeatedbyteB, count;
    BOOL nextA; // YES if A, NO if B
    BOOL repeatMode; // YES if we're repeating, NO if we're just copying
}

-(id)initWithHandle:(CSHandle *)handle;
-(id)initWithHandle:(CSHandle *)handle length:(off_t)length;
-(void)resetByteStream;
-(uint8_t)produceByteAtOffset:(off_t)pos;

@end
