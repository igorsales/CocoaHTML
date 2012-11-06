//
//  NSAttributedString+HTML.m
//  netchup
//
//  Created by Igor Sales on 2012-11-03.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import "NSAttributedString+IS_HTML.h"
#import <CoreText/CoreText.h>

@implementation NSAttributedString (IS_HTML)

+ (NSAttributedString*)attributedStringFromHTMLString:(NSString*)html
{
    return [self attributedStringFromHTMLString:html configurationBlock:nil];
}

+ (NSAttributedString*)attributedStringFromHTMLString:(NSString*)html configurationBlock:(void(^)(ISHTMLStringParser* parser))configBlock
{
    ISHTMLStringParser* htmlParser = [ISHTMLStringParser new];
    
    if (configBlock) {
        configBlock(htmlParser);
    }
    
    NSString* plainText  = nil;
    NSArray*  attributes = [htmlParser attributesFromHTMLString:html outputString:&plainText];
    
    return [htmlParser attributedStringWithString:plainText afterApplyingHTMLTagsInArray:attributes];
}

@end
