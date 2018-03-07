#import "XADDARTRLEHandle.h"
#import "XADException.h"

@implementation XADDARTRLEHandle

-(id)initWithHandle:(CSHandle *)handle
{
    return [self initWithHandle:handle length:CSHandleMaxLength];
}

-(id)initWithHandle:(CSHandle *)handle length:(off_t)length
{
    return [super initWithInputBufferForHandle:handle length:length];
}

-(void)resetByteStream
{
	repeatedbyteA=repeatedbyteB=count=0;
    nextA = YES;
    repeatMode = NO;
}

-(uint8_t)produceByteAtOffset:(off_t)pos
{
	if(repeatMode == YES && count)
	{
		count--;
        if(nextA == YES) {
            nextA = NO;
            return repeatedbyteA;
        }
        else {
            nextA = YES;
            return repeatedbyteB;
        }
	}
    else if(repeatMode == NO && count)
    {
        count--;
        return CSInputNextByte(input);
    }
	else
	{
		if(CSInputAtEOF(input)) CSByteStreamEOF(self);
        while(true) {
            uint8_t b1=CSInputNextByte(input);
            uint8_t b2=CSInputNextByte(input);
            int16_t s = (b1 << 8) | b2;

            if (s==0 || s>=DART_CHUNK || s<=-DART_CHUNK)
                continue;
            else if (s < 0) {
                repeatMode = YES;
                repeatedbyteA = CSInputNextByte(input);
                repeatedbyteB = CSInputNextByte(input);
                count = (-s)*2-1;
                nextA = NO;
                return repeatedbyteA;
            }
            else if (s > 0) {
                repeatMode = NO;
                count = (s)*2-1;
                return CSInputNextByte(input);
            }
        }
    }
}

@end
