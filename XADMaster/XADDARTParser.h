#import "XADMacArchiveParser.h"

#define DART_CHUNK 20960
#define DART_DATA  20480
#define DART_TAGS    480

#define MAC_DISK    1
#define LISA_DISK   2
#define APPLE2_DISK 3

#define MAC_HD_DISK 16
#define DOS_LD_DISK 17
#define DOS_HD_DISK 18

#define RLE_COMPR 0
#define LZH_COMPR 1
#define NO_COMPR  2

@interface XADDARTParser:XADArchiveParser
{
}

+(int)requiredHeaderSize;
+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name;

-(void)parse;
-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum;
-(NSString *)formatName;

@end
