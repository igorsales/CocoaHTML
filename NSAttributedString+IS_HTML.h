//
//  NSAttributedString+HTML.h
//  netchup
//
//  Created by Igor Sales on 2012-11-03.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ISHTMLStringParser.h"

@interface NSAttributedString (IS_HTML)

+ (NSAttributedString*)attributedStringFromHTMLString:(NSString*)html;
+ (NSAttributedString*)attributedStringFromHTMLString:(NSString*)html configurationBlock:(void(^)(ISHTMLStringParser* parser))configBlock;

@end
