//
//  ISHTMLStringParser.h
//  netchup
//
//  Created by Igor Sales on 2012-11-04.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ISHTMLStringParser : NSObject

@property (nonatomic, retain) UIFont* defaultFont;

- (NSDictionary*)attributeDictionaryForHTMLTag:(NSString*)htmlTag htmlTag:(NSString**)outTag isSelfContainedTag:(BOOL*)selfContained isClosingTag:(BOOL*)closingTag;
- (NSArray*)attributesFromHTMLString:(NSString*)html outputString:(NSString**)outString;
- (NSAttributedString*)attributedStringWithString:(NSString*)inString afterApplyingHTMLTagsInArray:(NSArray*)toApply;
- (UIColor*)colorFromHTMLColorString:(NSString*)htmlColor;
- (NSString*)applyHTMLTags:(NSArray*)tags toPlainTextString:(NSString*)plainText;

@end
