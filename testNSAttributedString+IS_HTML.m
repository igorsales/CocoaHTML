//
//  testNSAttributedString+HTML.m
//  netchup
//
//  Created by Igor Sales on 2012-11-03.
//  Copyright (c) 2012 Igor Sales. All rights reserved.
//

#import "testNSAttributedString+IS_HTML.h"
#import "NSAttributedString+IS_HTML.h"

@interface NSAttributedString(HTMLPrivate)

+ (NSDictionary*)_dictionaryForHTMLTag:(NSString*)htmlTag htmlTag:(NSString**)outTag isSelfContainedTag:(BOOL*)selfContained isClosingTag:(BOOL*)closingTag;

@end

@implementation testNSAttributedString_IS_HTML

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testAttributeParsing
{
    NSString* tag = nil;
    BOOL sc = NO;
    BOOL ct = NO;
    NSDictionary* attrs = [NSAttributedString _dictionaryForHTMLTag:@"tagbbb a=1 b=\"x2z\" cdefFGH='3abc' space=' a b c '" htmlTag:&tag isSelfContainedTag:&sc isClosingTag:&ct];
    
    STAssertEqualObjects(@"tagbbb", tag, @"incorrect tag");
    STAssertEqualObjects(@"1", [attrs valueForKey:@"a"], @"incorrect attribute value");
    STAssertEqualObjects(@"x2z", [attrs valueForKey:@"b"], @"incorrect attribute value");
    STAssertEqualObjects(@"3abc", [attrs valueForKey:@"cdefFGH"], @"incorrect attribute value");
    STAssertEqualObjects(@" a b c ", [attrs valueForKey:@"space"], @"incorrect attribute value");
}

- (void)testAttributedString
{
    NSAttributedString* string = [NSAttributedString attributedStringFromHTMLString:@"<b>test</b>"];
    STAssertEqualObjects([string string], @"test", @"Incorrect text");
    
    string = [NSAttributedString attributedStringFromHTMLString:@"no html"];
    STAssertEqualObjects([string string], @"no html", @"Incorrect text");
    
    STFail(@"Add more tests");
}

@end
