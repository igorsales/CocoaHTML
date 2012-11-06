//
//  NSString+IS_HTML.m
//  netchup
//
//  Created by Igor Sales on 2012-11-05.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import "NSString+IS_HTML.h"
#import "ISHTMLStringParser.h"

@implementation NSString (IS_HTML)

- (NSString*)plainTextStringFromHTML
{
    ISHTMLStringParser* htmlParser = [ISHTMLStringParser new];
    
    NSString* plainText = nil;
    NSArray*  tags      = [htmlParser attributesFromHTMLString:self outputString:&plainText];
    
    plainText = [htmlParser applyHTMLTags:tags toPlainTextString:plainText];
    
    return plainText;
}

@end
