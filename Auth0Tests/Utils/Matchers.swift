// Matchers.swift
//
// Copyright (c) 2016 Auth0 (http://auth0.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

import Foundation
import OHHTTPStubs
import Nimble
@testable import Auth0

func hasAllOf(parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        return parameters.count == payload.count && parameters.reduce(true, combine: { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasAtLeast(parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload else { return false }
        return parameters.filter { (key, _) in payload.contains { (name, _) in  key == name } }.reduce(true, combine: { (initial, entry) -> Bool in
            return initial && payload[entry.0] as? String == entry.1
        })
    }
}

func hasUserMetadata(metadata: [String: String]) -> OHHTTPStubsTestBlock {
    return hasObjectAttribute("user_metadata", value: metadata)
}

func hasObjectAttribute(name: String, value: [String: String]) -> OHHTTPStubsTestBlock {
    return { request in
        guard let payload = request.a0_payload, actualValue = payload[name] as? [String: AnyObject] else { return false }
        return value.count == actualValue.count && value.reduce(true, combine: { (initial, entry) -> Bool in
            guard let value = actualValue[entry.0] as? String else { return false }
            return initial && value == entry.1
        })
    }
}

func hasNoneOf(parameters: [String: String]) -> OHHTTPStubsTestBlock {
    return !hasAtLeast(parameters)
}

func isResourceOwner(domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/oauth/ro")
}

func isSignUp(domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/signup")
}

func isResetPassword(domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/dbconnections/change_password")
}

func isPasswordless(domain: String) -> OHHTTPStubsTestBlock {
    return isMethodPOST() && isHost(domain) && isPath("/passwordless/start")
}

func haveError<T>(code code: String, description: String) -> MatcherFunc<Result<T, Authentication.Error>> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "an error response with code <\(code)> and description <\(description)>"
        if let actual = try expression.evaluate(), case .Failure(let cause) = actual, case .Response(let actualCode, let actualDescription) = cause {
            return code == actualCode && description == actualDescription
        }
        return false
    }
}

func haveCredentials(accessToken: String? = nil, _ idToken: String? = nil) -> MatcherFunc<Result<Credentials, Authentication.Error>> {
    return MatcherFunc { expression, failureMessage in
        var message = "a successful authentication result"
        if let accessToken = accessToken {
            message = message.stringByAppendingString(" <access_token: \(accessToken)>")
        }
        if let idToken = idToken {
            message = message.stringByAppendingString(" <id_token: \(idToken)>")
        }
        failureMessage.postfixMessage = message
        if let actual = try expression.evaluate(), case .Success(let credentials) = actual {
            return (accessToken == nil || credentials.accessToken == accessToken) && (idToken == nil || credentials.idToken == idToken)
        }
        return false
    }
}

func haveCreatedUser(email: String, username: String? = nil) -> MatcherFunc<Result<DatabaseUser, Authentication.Error>> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "have created user with email <\(email)>"
        if let actual = try expression.evaluate(), case .Success(let created) = actual {
            return created.email == email && (username == nil || created.username == username)
        }
        return false
    }
}

func beSuccessfulResult<T>() -> MatcherFunc<Result<T, Authentication.Error>> {
    return MatcherFunc { expression, failureMessage in
        failureMessage.postfixMessage = "be a successful result"
        if let actual = try expression.evaluate(), case .Success = actual {
            return true
        }
        return false
    }
}

extension NSURLRequest {
    var a0_payload: [String: AnyObject]? {
        return NSURLProtocol.propertyForKey(ParameterPropertyKey, inRequest: self) as? [String: AnyObject]
    }
}

extension NSMutableURLRequest {
    override var a0_payload: [String: AnyObject]? {
        get {
            return NSURLProtocol.propertyForKey(ParameterPropertyKey, inRequest: self) as? [String: AnyObject]
        }
        set(newValue) {
            if let parameters = newValue {
                NSURLProtocol.setProperty(parameters, forKey: ParameterPropertyKey, inRequest: self)
            }
        }
    }
}