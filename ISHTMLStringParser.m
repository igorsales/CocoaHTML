//
//  ISHTMLStringParser.m
//  netchup
//
//  Created by Igor Sales on 2012-11-04.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import "ISHTMLStringParser.h"

@implementation ISHTMLStringParser

#pragma mark - Memory management

- (id)init
{
    if ((self = [super init])) {
        self.defaultFont = [UIFont fontWithName:@"Helvetica" size:12.0];
    }

    return self;
}

#pragma mark - Operations

- (NSDictionary*)attributeDictionaryForHTMLTag:(NSString*)htmlTag htmlTag:(NSString**)outTag isSelfContainedTag:(BOOL*)selfContained isClosingTag:(BOOL*)closingTag
{
    if (closingTag) { *closingTag = NO; }
    if (selfContained) { *selfContained = NO; }
    
    NSMutableDictionary* attrs = [NSMutableDictionary new];
    
    NSScanner* scanner = [NSScanner scannerWithString:htmlTag];
    
    // scan white space
    [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
    
    if ([scanner scanString:@"/" intoString:nil]) {
        if (closingTag) { *closingTag = YES; }
        if (selfContained) { *selfContained = NO; }
    }
    
    // scan tag name
    if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:outTag]) {
        return nil;
    }
    
    NSInteger errors = 3;
    while (![scanner isAtEnd] && errors) {
        // scan white space
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        
        // scan closing tag
        if ([scanner scanString:@"/" intoString:nil]) {
            // scan white space
            [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
            
            if (![scanner isAtEnd] || (closingTag && *closingTag)) {
                // Syntax error
                return nil;
            }
            
            if (closingTag) { *closingTag = NO; }
            if (selfContained) { *selfContained = YES; }
        }
        
        // scan attribute name
        NSString* key = nil;
        if (![scanner scanCharactersFromSet:[NSCharacterSet letterCharacterSet] intoString:&key] || key == nil) {
            errors--;
            continue;
        }
        
        // scan white space
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        
        // scan '='
        if (![scanner scanString:@"=" intoString:nil]) {
            errors--;
            continue;
        }
        
        // scan white space
        [scanner scanCharactersFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet] intoString:nil];
        
        // scan '"' or attribute value
        NSString* value = nil;
        if ([scanner scanString:@"\"" intoString:nil]) {
            NSCharacterSet* toSkip = scanner.charactersToBeSkipped;
            scanner.charactersToBeSkipped = nil;
            [scanner scanUpToString:@"\"" intoString:&value];
            [scanner scanString:@"\"" intoString:nil];
            scanner.charactersToBeSkipped = toSkip;
        } else if ([scanner scanString:@"'" intoString:nil]) {
            NSCharacterSet* toSkip = scanner.charactersToBeSkipped;
            scanner.charactersToBeSkipped = nil;
            [scanner scanUpToString:@"'" intoString:&value];
            [scanner scanString:@"'" intoString:nil];
            scanner.charactersToBeSkipped = toSkip;
        } else {
            [scanner scanCharactersFromSet:[NSCharacterSet alphanumericCharacterSet] intoString:&value];
        }
        
        if (value) {
            [attrs setValue:value forKey:key];
        }
    }
    
    return attrs;
}

- (NSArray*)attributesFromHTMLString:(NSString*)html outputString:(NSString**)outString
{
    NSScanner*       scanner      = [NSScanner scannerWithString:html];
    NSMutableString* resultString = [[NSMutableString alloc] init];
    
    if (outString) {
        *outString = resultString;
    }
    
    BOOL scanResult;
    
    NSMutableArray* stack   = [NSMutableArray new];
    NSMutableArray* toApply = [NSMutableArray new];
    
    NSCharacterSet* htmlStoppersSet = [NSCharacterSet characterSetWithCharactersInString:@"<&"];
    
    // scan html tags
    NSString* accum = nil;
    while (![scanner isAtEnd]) {
        scanResult = [scanner scanUpToCharactersFromSet:htmlStoppersSet intoString:&accum];
        
        if (accum) {
            // accumulate string (non-HTML)
            [resultString appendString:accum];
            accum = nil;
        }
        
        if ([scanner scanString:@"&" intoString:nil]) {
            NSString* amp;
            if (![scanner scanUpToString:@";" intoString:&amp]) {
                // TODO: syntax error
                return toApply;
            }
            if ([scanner scanString:@";" intoString:nil]) {
                if ([amp isEqualToString:@"&nbsp"]) {
                    [resultString appendString:@" "];
                }
            }
        } else if ([scanner scanString:@"<" intoString:nil]) {
            // start HTML tag
            NSString* htmlTag = nil;
            if (![scanner scanUpToString:@">" intoString:&htmlTag]) {
                // TODO: syntax error
                return toApply;
            }
            if ([scanner scanString:@">" intoString:nil]) {
                BOOL selfContained = NO;
                BOOL closingTag    = NO;
                NSDictionary* attrs = [self attributeDictionaryForHTMLTag:htmlTag htmlTag:&htmlTag isSelfContainedTag:&selfContained isClosingTag:&closingTag];
                if (attrs == nil || htmlTag == nil) {
                    // TODO: syntax error
                    return toApply;
                }
                
                if (closingTag) {
                    // search the stack for the opening tag
                    NSEnumerator* i = [stack reverseObjectEnumerator];
                    NSDictionary* e = nil;
                    while (e = [i nextObject]) {
                        if ([[e valueForKey:@"tag"] isEqualToString:htmlTag]) {
                            // found the element, so adjust it
                            break;
                        }
                    }
                    
                    if (e) {
                        NSRange tagRange = NSRangeFromString([e valueForKey:@"range"]);
                        tagRange.length = [resultString length] - tagRange.location;
                        [toApply addObject:@{ @"tag": htmlTag, @"attrs": [e valueForKey:@"attrs"], @"range": NSStringFromRange(tagRange)}];
                        [stack removeObject:e];
                    }
                } else if (selfContained) {
                    // handle self contained tags.
                    NSRange tagRange = NSMakeRange([resultString length], 0);
                    [toApply addObject:@{ @"tag": htmlTag, @"attrs": attrs, @"range": NSStringFromRange(tagRange) }];
                } else { // opening tag
                    NSRange tagRange = NSMakeRange([resultString length], [html length]);
                    [stack addObject:@{ @"tag": htmlTag, @"attrs": attrs, @"range": NSStringFromRange(tagRange) }];
                }
            }
        }
    }
    
    [toApply addObjectsFromArray:stack];
    [stack removeAllObjects];
    stack = nil;
    
    return toApply;
}

- (NSAttributedString*)attributedStringWithString:(NSString*)inString afterApplyingHTMLTagsInArray:(NSArray*)toApply
{
    NSMutableAttributedString* resultString = [[NSMutableAttributedString alloc] initWithString:inString];
    [resultString beginEditing];
    
    NSMutableArray* insertions = [NSMutableArray new];
    
    for (NSDictionary* tag in toApply) {
        NSString* tagName = [tag valueForKey:@"tag"];
        NSDictionary* attrs = [tag valueForKey:@"attrs"];
        NSRange range = NSRangeFromString([tag valueForKey:@"range"]);
        if (range.location + range.length > [resultString length]) {
            range.length = [resultString length] - range.location;
        }
        
        if ([tagName isEqualToString:@"b"] || [tagName isEqualToString:@"strong"]) {
            NSDictionary* attributes = [resultString attributesAtIndex:range.location effectiveRange:nil];
            UIFont* font = [attributes valueForKey:NSFontAttributeName];
            if (font == nil) {
                font = self.defaultFont;
            }
            NSString* fontName = [NSString stringWithFormat:@"%@-Bold", font.fontName];
            UIFont* newFont = [UIFont fontWithName:fontName size:font.pointSize];
            if (newFont) {
                font = newFont;
            }
            [resultString addAttribute:NSFontAttributeName value:font range:range];
        } else if ([tagName isEqualToString:@"br"]) {
            // Insert them so that we can go through them backwards.
            [insertions insertObject:tag atIndex:0];
        } else if ([tagName isEqualToString:@"font"]) {
            // check size, color and face
            NSString* value = nil;
            if ((value = [attrs valueForKey:@"color"])) {
                UIColor* color = [self colorFromHTMLColorString:value];
                if (color) {
                    [resultString addAttribute:NSForegroundColorAttributeName value:color range:range];
                }
            }
        }
    }
    
    for (NSDictionary* tag in insertions) {
        NSString* tagName = [tag valueForKey:@"tag"];
        NSRange range = NSRangeFromString([tag valueForKey:@"range"]);

        if ([tagName isEqualToString:@"br"]) {
            NSAttributedString* string = [[NSAttributedString alloc] initWithString:@"\n"];
            [resultString insertAttributedString:string atIndex:range.location];
        }
    }
    
    [resultString endEditing];
    
    return resultString;
}

- (UIColor*)colorFromHTMLColorString:(NSString*)htmlColor
{
    NSScanner* scanner = [NSScanner scannerWithString:htmlColor];
    
    if (![scanner scanString:@"#" intoString:nil]) {
        return nil; // not a colour
    }

    unsigned int hexColor = 0;
    NSUInteger colourLength = [scanner scanLocation];
    if (![scanner scanHexInt:&hexColor]) {
        return nil;
    }
    
    colourLength = [scanner scanLocation] - colourLength;
    
    CGFloat a = -1.0, r, g, b, d;
    switch (colourLength) {
        case 4:
            a = (hexColor >> 12) & 0xF;
        case 3:
            r = (hexColor >> 8) & 0xF;
            g = (hexColor >> 4) & 0xF;
            b = (hexColor >> 0) & 0xF;
            d = 0xF;
            break;
            
        case 8:
            a = (hexColor >> 24) & 0xFF;
        case 6:
            r = (hexColor >> 16) & 0xFF;
            g = (hexColor >>  8) & 0xFF;
            b = (hexColor >>  0) & 0xFF;
            d = 0xFF;
            break;
    }
    
    if (a < 0) {
        a = d;
    }

    
    return [UIColor colorWithRed:r/d green:g/d blue:b/d alpha:a/d];
}

- (NSString*)applyHTMLTags:(NSArray*)tags toPlainTextString:(NSString*)plainText
{
    NSMutableString* result = [plainText mutableCopy];
    
    NSEnumerator* e = [tags reverseObjectEnumerator];
    NSDictionary* t = nil;
    while(t = [e nextObject]) {
        NSString* tag   = [t valueForKey:@"tag"];
        NSRange   range = NSRangeFromString([t valueForKey:@"range"]);
        
        if ([tag isEqualToString:@"br"] && range.location < result.length) {
            [result insertString:@"\n" atIndex:range.location];
        }
    }
    
    return result;
}

@end
