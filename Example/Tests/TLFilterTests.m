/**
 *   TLFilterTests.h
 *
 *   Copyright 2015 Tony Stone
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *   Created by Tony Stone on 11/24/15.
 */
#import <XCTest/XCTest.h>
#import <TraceLog/TraceLog.h>
#import <TraceLog/TLFilter.h>

@interface TLFilterTests : XCTestCase
@end


//
// Test constants for matching
//
static NSString * matchTestTag      = @"TLFilterTest";
static NSString * matchTestFile     = @"/Users/shared/Workspaces/tracelog/Example/Tests/TLFilterTests.m";
static NSString * matchTestFunction = @"-[TLFilterTests testMatches]";
static NSString * matchTestLine     = @"35";
static NSString * matchTestMessage  = @"Test message with an Error pattern in it";

@implementation TLFilterTests

    - (void) testFiltersForPattern_Pattern_EmbeddedForwardSlashDelimiter {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"//tmp/TL.*$/TRACE2"] lastObject] regex] pattern], @"/tmp/TL.*$");
    }

    - (void) testFiltersForPattern_Pattern_EmbeddedForwardSlashDDelimiterExcaped {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/\\/tmp\\/TL.*$/WARNING"] lastObject] regex] pattern], @"\\/tmp\\/TL.*$");
    }

    - (void) testFiltersForPattern_Pattern_PoundDelimiter {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"#^TL.*#WARNING"] lastObject] regex] pattern], @"^TL.*");
    }

    - (void) testFiltersForPattern_Pattern_ForwardSlashDelimiter {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/^TL.*/WARNING"] lastObject] regex] pattern], @"^TL.*");
    }

    - (void) testFiltersForPattern_Pattern_ForwardSlashDelimiter_WithComment {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/^TL.*(?# Begins with)/WARNING"] lastObject] regex] pattern], @"^TL.*(?# Begins with)");
    }

    - (void) testFiltersForPattern_Pattern_ExclamationMarkDelimiter {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"!/tmp/TL.*$!TRACE3"] lastObject] regex] pattern], @"/tmp/TL.*$");
    }

    - (void) testFiltersForPattern_Pattern_EmbeddedEscapes1 {
        XCTAssert([[[[[TLFilter filtersForPattern: @"/\\bError\\b/TRACE2"] lastObject] regex] pattern] isEqualToString: @"\\bError\\b"]);
    }

    - (void) testFiltersForPattern_Pattern_EmbeddedEscapes2 {
        XCTAssert([[[[[TLFilter filtersForPattern: @"/\\D/TRACE2"] lastObject] regex] pattern] isEqualToString: @"\\D"]);
    }

    - (void) testFiltersForPattern_Pattern_MultiPattern {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/^TL.*/WARNING,/Error/ERROR/tag"] lastObject] regex] pattern], @"^TL.*");
    }

    - (void) testFiltersForPattern_Pattern_InvalidDelimiter {
        NSError * error = nil;
        (void) [[TLFilter filtersForPattern:  @"\\/tmp/TL.*$\\TRACE3" error: &error] lastObject];
    
        XCTAssertNotNil(error);
        NSLog(@"%@", error);
    }

    - (void) testFiltersForPattern_LogLevel_Off {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/OFF"] lastObject] logLevel], LogLevelOff);
    }

    - (void) testFiltersForPattern_LogLevel_Off_WithComment {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*(?# Begins with)/OFF"] lastObject] logLevel], LogLevelOff);
    }

    - (void) testFiltersForPattern_LogLevel_Error {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/ERROR"] lastObject] logLevel], LogLevelError);
    }

    - (void) testFiltersForPattern_LogLevel_Warning {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/WARNING"] lastObject] logLevel], LogLevelWarning);
    }

    - (void) testFiltersForPattern_LogLevel_Info {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/INFO"] lastObject] logLevel], LogLevelInfo);
    }

    - (void) testFiltersForPattern_LogLevel_Trace1 {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/TRACE1"] lastObject] logLevel], LogLevelTrace1);
    }

    - (void) testFiltersForPattern_LogLevel_Trace2 {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/TRACE2"] lastObject] logLevel], LogLevelTrace2);
    }

    - (void) testFiltersForPattern_LogLevel_Trace3 {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/TRACE3"] lastObject] logLevel], LogLevelTrace3);
    }

    - (void) testFiltersForPattern_LogLevel_Trace4 {
        XCTAssertEqual ([[[TLFilter filtersForPattern: @"/^TL.*/TRACE4"] lastObject] logLevel], LogLevelTrace4);
    }

    - (void) testFiltersForPattern_LogLevel_Trace5 {
        NSError * error = nil;
        (void) [TLFilter filtersForPattern: @"/^TL.*/TRACE5" error: &error];

        XCTAssertNotNil(error);
        NSLog(@"%@", error);
    }

//    - (void) testFiltersForPattern_Targets_All {
//        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/all"] lastObject] targets] lastObject], @"message");
//    }

    - (void) testFiltersForPattern_Targets_Default {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO"] lastObject] targets] lastObject], @"tag");
    }

    - (void) testFiltersForPattern_Targets_Default_WithComment {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*(?# Begins with)/INFO"] lastObject] targets] lastObject], @"tag");
    }

    - (void) testFiltersForPattern_Targets_Tag {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/tag"] lastObject] targets] lastObject], @"tag");
    }

    - (void) testFiltersForPattern_Targets_Tag_WithComment {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*(?# Begins with)/INFO/tag"] lastObject] targets] lastObject], @"tag");
    }

    - (void) testFiltersForPattern_Targets_File {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/file"] lastObject] targets] lastObject], @"file");
    }

    - (void) testFiltersForPattern_Targets_Function {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/function"] lastObject] targets] lastObject], @"function");
    }

    - (void) testFiltersForPattern_Targets_Line {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/line"] lastObject] targets] lastObject], @"line");
    }

    - (void) testFiltersForPattern_Targets_Message {
        XCTAssertEqualObjects([[[[TLFilter filtersForPattern:  @"/TL.*/INFO/message"] lastObject] targets] lastObject], @"message");
    }

    - (void) testFiltersForPattern_Targets_Invalid {
        NSError * error = nil;
        (void) [TLFilter filtersForPattern:  @"/TL.*/INFO/door" error: &error];

        XCTAssertNotNil(error);
        NSLog(@"%@", error);
    }

    - (void) testMatches_BeginsWith_DefaultTag {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/^TL.*/WARNING"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_EndsWith_DefaultTag {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/.*Test$/WARNING"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_Exact_DefaultTag {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/^TLFilterTest$/WARNING"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_EndsWith_File {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/.*Tests.m$/WARNING/file"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_EndsWith_All {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/.*Tests.m$/WARNING/all"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_RangeOfNumbers_Line_WithComment {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/^[0-5]?[0-9]$(?# Range 0..59)/WARNING/line"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_ContainsError_Message {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/\\bError\\b/WARNING/message"] lastObject];

        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_ContainsErr_Message {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/\\bErr\\b/WARNING/message"] lastObject];
    
        XCTAssertFalse(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_ContainsInfo_Message_Miss {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/Info/WARNING/message"] lastObject];

        XCTAssertFalse(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

    - (void) testMatches_FilePath {
        TLFilter * filter = [[TLFilter filtersForPattern: @"/.*/Tests/TLFilterTests.m/WARNING/file"] lastObject];
    
        XCTAssertTrue(([filter matches: matchTestTag file: matchTestFile function: matchTestFunction line: matchTestLine message: matchTestMessage]));
    }

@end