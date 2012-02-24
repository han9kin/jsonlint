//
//  main.m
//  jsonlint
//
//  Created by 서 상혁 on 12. 2. 23..
//  Copyright (c) 2012년 NHN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "JSONKit.h"


static char *kVersion   = "1.0";
static char *kCopyright = "(c) 2012, han9kin.";
static char *kHelp      = ""
    "Usage: jsonlint [OPTIONS] < jsonfile\n"
    "\n"
    "  Options:\n"
    "    -c NUM      Output NUM (default 2) lines of json text before error position\n"
    "    -q          Quiet mode\n"
    "    -h          Show this help\n"
    "    -v          Show version";


static int gNumberOfLines = 2;
static int gShowOutput    = 1;


void PrintVersion()
{
    printf("jsonlint version %s\n", kVersion, kCopyright);
    exit(0);
}


void PrintHelp()
{
    printf("jsonlint version %s %s\n%s\n", kVersion, kCopyright, kHelp);
    exit(0);
}


BOOL LoadOptions(int argc, char * const argv[])
{
    BOOL sSuccess = YES;
    int  sOpt;

    while ((sOpt = getopt(argc, argv, "c:qhv")) != -1)
    {
        switch (sOpt)
        {
            case 'c':
                gNumberOfLines = atoi(optarg);
                break;
            case 'q':
                gShowOutput = 0;
                break;
            case 'h':
                PrintHelp();
                break;
            case 'v':
                PrintVersion();
                break;
            default:
                sSuccess = NO;
                break;
        }
    }

    if (gNumberOfLines <= 0)
    {
        gNumberOfLines = 2;
    }

    return sSuccess;
}


NSString *LintDescription(const char *aString, size_t aLength, NSError *aError)
{
    NSMutableArray *sResult;
    NSArray        *sLines;
    NSInteger       sLine;
    NSInteger       sIndex;
    const char     *sBegin;
    int             i;

    sResult = [NSMutableArray array];
    sLines  = [[NSString stringWithUTF8String:aString] componentsSeparatedByString:@"\n"];
    sLine   = [[[aError userInfo] objectForKey:@"JKLineNumberKey"] integerValue];
    sIndex  = [[[aError userInfo] objectForKey:@"JKAtIndexKey"] integerValue] - 1;

    /*
     * error description
     */
    [sResult addObject:[NSString stringWithFormat:@"%@", [aError localizedDescription]]];

    /*
     * position of error
     */
    for (sBegin = aString + sIndex; ((sBegin > aString) && (*sBegin != '\n')); sBegin--);

    if (*sBegin == '\n')
    {
        sBegin++;
    }

    [sResult addObject:[NSString stringWithFormat:@"%@^", [@"" stringByPaddingToLength:(12 + sIndex - (sBegin - aString)) withString:@"-" startingAtIndex:0]]];

    /*
     * json text lines
     */
    for (i = sLine - 1; ((i >= 0) && (i >= (sLine - gNumberOfLines))); i--)
    {
        [sResult addObject:[NSString stringWithFormat:@"%10d: %@", (i + 1), [sLines objectAtIndex:i]]];
    }

    return [[[sResult reverseObjectEnumerator] allObjects] componentsJoinedByString:@"\n"];
}


int main(int argc, char * const argv[])
{
    int sStatus = 0;

    @autoreleasepool
    {
        NSString        *sInput;
        NSMutableString *sOutput;

        if (!LoadOptions(argc, argv))
        {
            return 2;
        }

        sInput  = [[[NSString alloc] initWithData:[[NSFileHandle fileHandleWithStandardInput] readDataToEndOfFile] encoding:NSUTF8StringEncoding] autorelease];
        sOutput = [NSMutableString string];

        if (sInput)
        {
            JSONDecoder *sDecoder;
            const char  *sString;
            size_t       sLength;
            NSError     *sError;

            sDecoder = [JSONDecoder decoderWithParseOptions:JKParseOptionStrict];
            sString  = [sInput UTF8String];
            sLength  = strlen(sString);

            if ([sDecoder objectWithUTF8String:(const unsigned char *)sString length:sLength error:&sError])
            {
                [sOutput appendFormat:@"A valid JSON object was parsed.\n"];
            }
            else
            {
                [sOutput appendFormat:@"%@\n", LintDescription(sString, sLength, sError)];
                sStatus = 1;
            }
        }
        else
        {
            [sOutput appendFormat:@"Input data is not UTF-8 encoded.\n"];
            sStatus = 1;
        }

        if (gShowOutput && [sOutput length])
        {
            [(NSFileHandle *)[NSFileHandle fileHandleWithStandardOutput] writeData:[sOutput dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }

    return sStatus;
}
