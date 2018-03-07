#import "XADDARTParser.h"
#import "XADLZHDynamicHandle.h"
#import "XADDARTRLEHandle.h"
#import "CSMemoryHandle.h"


@implementation XADDARTParser


+(int)requiredHeaderSize { return 148; }

+(BOOL)recognizeFileWithHandle:(CSHandle *)handle firstBytes:(NSData *)data name:(NSString *)name
{
    int nBlocks;
    int runningTotal = 0;
    const uint8_t *bytes=[data bytes];
    int compressionID = bytes[0];
    if(CSUInt16BE(bytes+2) == 1440)
        nBlocks = 72;
    else
        nBlocks = 40;
    for (int i = 0; i < nBlocks; i++) {
        if(CSInt16BE(bytes+4+(i*2)) == -1)
            runningTotal += DART_CHUNK;
        else if(compressionID == RLE_COMPR)
            runningTotal += CSInt16BE(bytes+4+(i*2))*2;
        else
            runningTotal += CSInt16BE(bytes+4+(i*2));

    }
//    NSLog(@"actual size: %lld; predicted size: %d", [handle fileSize], 4 + nBlocks*2 + runningTotal);

    return ([handle fileSize] == 4 + nBlocks*2 + runningTotal);
}


-(void)parse
{

	[self setIsMacArchive:YES];

	CSHandle *fh=[self handle];

	int compressionID = [fh readUInt8];
    int diskID = [fh readUInt8];
    NSMutableArray *blockLengths = [[NSMutableArray alloc] initWithCapacity:72];
    int uncDataSize = [fh readUInt16BE];
    int nBlocks;
    if(uncDataSize == 1440)
        nBlocks = 72;
    else
        nBlocks = 40;
    for(int i = 0; i < nBlocks; i++) {
        [blockLengths addObject:[NSNumber numberWithInt:[fh readInt16BE]]];
    }

    NSString *name=[[[self name] stringByDeletingPathExtension] stringByAppendingPathExtension:@"dc42"];
    NSString *compressionType = @"";
    switch (compressionID)
    {
        case RLE_COMPR:
            compressionType = @"DARTRLE";
            break;
        case LZH_COMPR:
            compressionType = @"DynamicLZH";
            break;
        case NO_COMPR:
            compressionType = @"None";
            break;
    }

    NSMutableDictionary *dict=[NSMutableDictionary dictionaryWithObjectsAndKeys:
                               [self XADPathWithUnseparatedString:name],XADFileNameKey,
                               [self XADStringWithString:compressionType],XADCompressionNameKey,
                               [NSNumber numberWithInt:compressionID] ,@"CompressionID",
                               [NSNumber numberWithInt:diskID], @"DiskID",
                               [NSNumber numberWithInt:nBlocks], @"NumBlocks",
                               [NSNumber numberWithInt:uncDataSize], @"UncompressedDataSizeKB",
                               blockLengths, @"BlockLengths",
                               [NSNumber numberWithInt:[fh fileSize]],XADCompressedSizeKey,
                               [NSNumber numberWithInt:(uncDataSize*1024 + uncDataSize*2*12 + 84)],XADFileSizeKey,
                               nil];
	[self addEntryWithDictionary:dict];
}

-(CSHandle *)handleForEntryWithDictionary:(NSDictionary *)dict wantChecksum:(BOOL)checksum
{
    int compressionID = [[dict objectForKey:@"CompressionID"] integerValue];
    CSHandle *fh=[self handleAtDataOffsetForDictionary:dict];
    NSMutableData *outputData = [[NSMutableData alloc] initWithLength:[[dict objectForKey:XADFileSizeKey] integerValue]];
    char imageName[64];
    memset(imageName, 0, 64);
    char *title = "DART image converted by XADMaster";
    strcpy(imageName+1,title);
    imageName[0] = strlen(title);
    [outputData replaceBytesInRange:NSMakeRange(0, 64) withBytes:imageName];

    uint8_t encodingAndFormat[4];
    int dataSize = [[dict objectForKey:@"UncompressedDataSizeKB"] integerValue];
    int diskID = [[dict objectForKey:@"DiskID"] integerValue];

    // disk types
    // NSLog(@"Disk ID: %d", diskID);
    if(diskID == DOS_LD_DISK && dataSize == 720) {
        encodingAndFormat[0] = 0x02;
        encodingAndFormat[1] = 0x22;
    } else if(diskID == DOS_HD_DISK && dataSize == 1440) {
        encodingAndFormat[0] = 0x03;
        encodingAndFormat[1] = 0x22;
    } else if(diskID == APPLE2_DISK && dataSize == 800) {
        encodingAndFormat[0] = 0x01;
        encodingAndFormat[1] = 0x24;
    } else if(diskID == MAC_DISK && dataSize == 400) {
        encodingAndFormat[0] = 0x00;
        encodingAndFormat[1] = 0x02;
    } else if((diskID == LISA_DISK) && dataSize == 400) {
        encodingAndFormat[0] = 0x00;
        encodingAndFormat[1] = 0x12;
    } else if(diskID == MAC_DISK && dataSize == 800) {
        encodingAndFormat[0] = 0x01;
        encodingAndFormat[1] = 0x22;
    } else
        [XADException raiseIllegalDataException];

    encodingAndFormat[2] = 0x01;
    encodingAndFormat[3] = 0x00;

    [outputData replaceBytesInRange:NSMakeRange(0x50, 4) withBytes:encodingAndFormat];


    int headerSize = 4 + [[dict objectForKey:@"NumBlocks"] integerValue] * 2;

    NSMutableArray *blockLengths = [dict objectForKey:@"BlockLengths"];

    NSUInteger index = 0;
    NSUInteger runningTotal = 0;
    for(NSNumber *block in blockLengths) {

        CSHandle *compData;
//        NSLog(@"block %ld has size %ld", index, [block integerValue]);
        if ([block integerValue] == 0)
            break;
        else if([block integerValue] == -1)
            compData = [fh nonCopiedSubHandleFrom:(headerSize + index*DART_CHUNK) length:DART_CHUNK];
        else if(compressionID == RLE_COMPR)
            compData = [fh nonCopiedSubHandleFrom:(headerSize + runningTotal) length:([block integerValue]*2)];
        else
            compData = [fh nonCopiedSubHandleFrom:(headerSize + runningTotal) length:[block integerValue]];
//        NSLog(@"begin loc: %ld, length: %ld", headerSize + runningTotal, [block integerValue]);

        CSHandle *uncData;
        if ([block integerValue] == -1) {
            uncData = compData;
        }
        else {
            switch(compressionID) {
                case RLE_COMPR:
                    uncData = [[XADDARTRLEHandle alloc] initWithHandle:compData length:DART_CHUNK];
                    break;
                case LZH_COMPR:
                    uncData = [[XADLZHDynamicHandle alloc] initWithHandle:compData length:DART_CHUNK prefill:NO];
                    break;
                case NO_COMPR:
                    uncData = compData;
                    break;
            }
        }
        uint8_t *data = malloc(DART_DATA);
        uint8_t *tags = malloc(DART_TAGS);
        [uncData readBytes:DART_DATA toBuffer:data];
        [uncData readBytes:DART_TAGS toBuffer:tags];
        [outputData replaceBytesInRange:NSMakeRange(0x54 + index*DART_DATA, DART_DATA) withBytes:data];
        [outputData replaceBytesInRange:NSMakeRange(0x54 + dataSize*1024 + index*DART_TAGS, DART_TAGS) withBytes:tags];

        index++;
        if([block integerValue] == -1)
            runningTotal += DART_CHUNK;
        else if(compressionID == RLE_COMPR)
            runningTotal += [block integerValue]*2;
        else
            runningTotal += [block integerValue];
    }

    uint8_t sizesAndChecksums[16];
    memset(sizesAndChecksums, 0, 16);
    CSSetUInt32BE(sizesAndChecksums,[[dict objectForKey:@"UncompressedDataSizeKB"] integerValue] * 1024);
    CSSetUInt32BE(sizesAndChecksums + 4, [[dict objectForKey:@"UncompressedDataSizeKB"] integerValue] * 2 * 12);

    uint32_t cksum = 0;
    for(int i = 0; i < dataSize * 1024 / 2; i++) {
        cksum += CSUInt16BE([outputData bytes] + 0x54 + i*2);
        cksum = (cksum >> 1) | (cksum << 31);
    }
    CSSetUInt32BE(sizesAndChecksums + 8, cksum);
//    NSLog(@"Data cksum: %x", cksum);
    cksum = 0;

    for(int i = 0; i < ((dataSize * 2 * 12) - 12)/2; i++) {
        cksum += CSUInt16BE([outputData bytes] + 0x54 + dataSize*1024 + 12 + i*2);
        cksum = (cksum >> 1) | (cksum << 31);
    }
    CSSetUInt32BE(sizesAndChecksums + 12, cksum);
//    NSLog(@"Tag cksum: %x", cksum);

    [outputData replaceBytesInRange:NSMakeRange(0x40, 16) withBytes:sizesAndChecksums];

    CSMemoryHandle *outFile = [[CSMemoryHandle alloc] initWithData:outputData];

    return outFile;
}



-(NSString *)formatName { return @"DART"; }

@end
