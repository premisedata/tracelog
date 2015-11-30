/**
 *   TLFilter.m
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
 *   Created by Tony Stone on 11/28/15.
 */
#import "TLFilter.h"

//
// Error codes
//
NSString * TLFilterErrorDomain = @"TLFilterErrorDomain";

NSInteger TLErrorInvalidRegexPattern   = 101;
NSInteger TLErrorRegexEvaluatoinErrors = 102;

NSString * TLFilterFailureReasonsErrorKey = @"TLFilterFailureReasonsErrorKey";

//
// Internal constants
//
static NSArray  * validTargets;
static NSString * delimiterPattern;
static NSString * regexPatternTemplate;
static NSString * regexPatternTemplate2;

//
// Main implementation
//
@implementation TLFilter {
        NSRegularExpression * _regex;
        NSArray *             _targets;
        LogLevel              _logLevel;
    }

    + (void)initialize {
        if(self == [TLFilter class]) {
            
            delimiterPattern = @"(^[^a-zA-Z\\\\ ])(.*)";
            
            NSArray * logLevelStrings = validLogLevelStrings();
            
            // Create a sub-expression for all valid log levels
            NSMutableString * logLevelExpression = [[NSMutableString alloc] initWithFormat: @"(%@", logLevelStrings[0]];
            for (NSUInteger index = 1; index < logLevelStrings.count; index++) {
                [logLevelExpression appendFormat: @"|%@", logLevelStrings[index]];
            }
            [logLevelExpression appendString:@")"];
            
            validTargets = @[@"tag",
                             @"file",
                             @"function",
                             @"line",
                             @"message"];
            
            NSMutableString * validTargetsExpression = [[NSMutableString alloc] initWithFormat: @"(%@", validTargets[0]];
            for (NSUInteger index = 1; index < validTargets.count; index++) {
                [validTargetsExpression appendFormat: @"|%@", validTargets[index]];
            }
            [validTargetsExpression appendString: @")"];
            
            //
            // NOTE: in order for the template expression below to succeed, we
            //       have to double up the \ chars
            //
            //  <delimiter><regex><delimiter><LogLevel>[<delimiter><target>]
            //
            regexPatternTemplate  = [NSString stringWithFormat: @"^(?:$1(.+)(?<!$1\\\\\\\\)$1%@(?:(?<!$1\\\\\\\\)$1(all|%@))?)$", logLevelExpression, validTargetsExpression];
        }
    }

    - (nonnull instancetype)initWithRegex: (nonnull NSRegularExpression *) aRegex targets: (nonnull NSArray *) targets logLevel: (LogLevel) aLogLevel {
        self = [super init];
        if (self) {
            self->_regex    = aRegex;
            self->_targets  = targets;
            self->_logLevel = aLogLevel;
        }
        return self;
    }

    - (nonnull NSRegularExpression *) regex {
        return _regex;
    }

    - (nonnull NSArray *) targets {
        return _targets;
    }

    - (LogLevel) logLevel {
        return _logLevel;
    }

    + (nullable NSArray *) filtersForPattern: (nonnull NSString *) pattern {
        return [self filtersForPattern: pattern error: nil];
    }

    + (nullable NSArray *) filtersForPattern: (nonnull NSString *) pattern error: (NSError * _Nullable * _Nullable) resultError {

        __block NSError * error   = nil;
        NSMutableArray  * filters = [[NSMutableArray alloc] init];

        //
        // Create a regex to find the first character
        // in the users pattern.  This will be applied
        // to the template as a replacement char.
        //
        NSRegularExpression * delimiterRegex = [NSRegularExpression regularExpressionWithPattern: delimiterPattern options: NSRegularExpressionAnchorsMatchLines error:  &error];
        if (error) {
            if (resultError) {
                *resultError = error;
            }
            return nil;
        }

        //
        // Process the template and replace the markers with
        // the delimiter character from above.
        //
        NSString * regexPattern = [delimiterRegex stringByReplacingMatchesInString: pattern options: 0 range: NSMakeRange(0, pattern.length) withTemplate: regexPatternTemplate];

        //
        // Create the final regex that will be used to process the entire pattern
        // the user supplied.
        NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern: regexPattern options: NSRegularExpressionAnchorsMatchLines error: &error];
        if (error) {
            if (resultError) {
                *resultError = error;
            }
            return nil;
        }

        //
        // Now process the users pattern to see if it is valid and build the filters
        //
        NSMutableArray * errors = [[NSMutableArray alloc] init];

        [regex enumerateMatchesInString: pattern options: NSMatchingReportCompletion range: NSMakeRange(0,pattern.length) usingBlock:^(NSTextCheckingResult * _Nullable match, NSMatchingFlags flags, BOOL * _Nonnull stop) {

            NSRange matchRange = [match rangeAtIndex: 1];

            if (!match || (flags & NSMatchingCompleted) || NSEqualRanges(matchRange, NSMakeRange(NSNotFound, 0))) {
                if ([filters count] == 0) {
                    error = [NSError errorWithDomain: TLFilterErrorDomain code: TLErrorInvalidRegexPattern userInfo: @{NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Regex pattern %@ is invalid.", pattern] }];
                    [errors addObject: error];
                }
                return;
            }
            NSString * filterRegexPattern = [pattern substringWithRange: matchRange];

            NSRegularExpression * filterRegex = [NSRegularExpression regularExpressionWithPattern: filterRegexPattern options: NSRegularExpressionAnchorsMatchLines error: &error];

            if (error) {
                [errors addObject: error];
                return;
            }

            NSMutableArray * targets  = [[NSMutableArray alloc] init];
            LogLevel         logLevel = LogLevelOff;

            matchRange = [match rangeAtIndex: 2];
            if (!NSEqualRanges(matchRange, NSMakeRange(NSNotFound, 0))) {
                logLevel = logLevelForString([pattern substringWithRange: matchRange]);
            }

            matchRange = [match rangeAtIndex: 3];
            if (!NSEqualRanges(matchRange, NSMakeRange(NSNotFound, 0))) {
                NSString * target = [pattern substringWithRange: matchRange];

                if ([target isEqualToString: @"all"]) {
                    [targets addObjectsFromArray: validTargets];
                } else {
                    [targets addObject: target];
                }
            } else {
                [targets addObject: @"tag"];
            }
            [filters addObject: [[TLFilter alloc] initWithRegex: filterRegex targets: targets logLevel: logLevel]];

        }];

        if (resultError && errors.count > 0) {
            filters = nil;

            if (errors.count == 1) {
                *resultError = errors[0];
            } else {
                error = [NSError errorWithDomain: TLFilterErrorDomain code: TLErrorRegexEvaluatoinErrors userInfo:
                        @{
                                NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Regex evaluation errors"],
                                TLFilterFailureReasonsErrorKey: errors
                        }];
            }
        }
        return filters;
    }

    - (LogLevel) filteredLevelForTag: (nonnull NSString *) tag file: (nonnull NSString *) file function: (nonnull NSString *) function line: (nonnull NSString *) line message: (nonnull NSString *) message {

        if ([self matches: tag file: file function: function line: line message: message]) {
            return self->_logLevel;
        }
        return LogLevelOff;
    }

    - (BOOL) matches: (nonnull NSString *) tag file: (nonnull NSString *) file function: (nonnull NSString *) function line: (nonnull NSString *) line message: (nonnull NSString *) message {
        NSMutableString * compositeSearchString = [[NSMutableString alloc] init];

        for (NSString * searchItem in self->_targets) {

            if      ([searchItem isEqualToString: @"tag"])      [compositeSearchString appendFormat: @"%@\r", tag];
            else if ([searchItem isEqualToString: @"file"])     [compositeSearchString appendFormat: @"%@\r", file];
            else if ([searchItem isEqualToString: @"function"]) [compositeSearchString appendFormat: @"%@\r", function];
            else if ([searchItem isEqualToString: @"line"])     [compositeSearchString appendFormat: @"%@\r", line];
            else if ([searchItem isEqualToString: @"message"])  [compositeSearchString appendFormat: @"%@\r", message];
        }
        NSInteger matches = [_regex numberOfMatchesInString: compositeSearchString options: 0 range: NSMakeRange(0, compositeSearchString.length)];

        return matches > 0;
    }

    - (NSString *) description {
        return [NSString stringWithFormat: @"%@<%p> {\r\t%8s: %@ \r\t%8s: %@ \r\t%8s: %@\r}\r", NSStringFromClass([self class]), (void *) self, "regex", _regex.pattern, "logLevel", stringForLogLevel(_logLevel), "targets", _targets];
    }

@end
