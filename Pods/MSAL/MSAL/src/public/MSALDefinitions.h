//------------------------------------------------------------------------------
//
// Copyright (c) Microsoft Corporation.
// All rights reserved.
//
// This code is licensed under the MIT License.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files(the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and / or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions :
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//------------------------------------------------------------------------------

#ifndef MSALDefinitions_h
#define MSALDefinitions_h

@class MSALResult;
@class MSALAccount;


/*! Levels of logging. Defines the priority of the logged message */
typedef NS_ENUM(NSInteger, MSALLogLevel)
{
    MSALLogLevelNothing,
    MSALLogLevelError,
    MSALLogLevelWarning,
    MSALLogLevelInfo,
    MSALLogLevelVerbose,
    MSALLogLevelLast = MSALLogLevelVerbose,
};


typedef NS_ENUM(NSInteger, MSALWebviewType)
{
#if TARGET_OS_IPHONE
    // For iOS 11 and up, uses AuthenticationSession (ASWebAuthenticationSession
    // or SFAuthenticationSession).
    // For older versions, with AuthenticationSession not being available, uses
    // SafariViewController.
    MSALWebviewTypeDefault,
    
    // Use SFAuthenticationSession/ASWebAuthenticationSession
    MSALWebviewTypeAuthenticationSession,
    
    // Use SFSafariViewController for all versions.
    MSALWebviewTypeSafariViewController,
    
#endif
    // Use WKWebView
    MSALWebviewTypeWKWebView,
};

typedef NS_ENUM(NSInteger, MSALBrokeredAvailability)
{
#if TARGET_OS_IPHONE
    // Use broker when possible
    MSALBrokeredAvailabilityAuto,
#endif
    // Disallow using broker
    MSALBrokeredAvailabilityNone
};


typedef NS_ENUM(NSUInteger, MSALPromptType)
{
    /*!
     If no user is specified the authentication webview will present a list of users currently
     signed in for the user to select among.
     */
    MSALPromptTypeSelectAccount,

    /*!
     Require the user to authenticate in the webview
     */
    MSALPromptTypeLogin,
    /*!
     Require the user to consent to the current set of scopes for the request.
     */
    MSALPromptTypeConsent,
    /*!
     The SSO experience will be determined by the presence of cookies in the webview and account type.
     User won't be prompted unless necessary.
     If multiple users are signed in, select account experience will be presented.
     */
    MSALPromptTypePromptIfNecessary,
    MSALPromptTypeDefault = MSALPromptTypeSelectAccount,
};

typedef void (^MSALCompletionBlock)(MSALResult * _Nullable result, NSError * _Nullable error);
typedef void (^MSALAccountsCompletionBlock)(NSArray<MSALAccount *> * _Nullable accounts, NSError * _Nullable error);


/*!
 The LogCallback block for the MSAL logger
 
 @param  level           The level of the log message
 @param  message         The message being logged
 @param  containsPII     If the message might contain Personally Identifiable Information (PII)
 this will be true. Log messages possibly containing PII will not be
 sent to the callback unless PIllLoggingEnabled is set to YES on the
 logger.
 
 */
typedef void (^MSALLogCallback)(MSALLogLevel level, NSString * _Nullable message, BOOL containsPII);


#endif /* MSALConstants_h */
