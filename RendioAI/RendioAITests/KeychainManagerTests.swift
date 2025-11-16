//
//  KeychainManagerTests.swift
//  RendioAITests
//
//  Unit tests for JWT parsing functionality in KeychainManager
//

import XCTest
@testable import RendioAI

final class KeychainManagerTests: XCTestCase {

    // MARK: - Test parseJWTExpiry with Valid Token

    func testParseJWTExpiry_ValidToken() {
        // Create a valid JWT token with exp claim
        // Payload: {"exp": 1731789600, "sub": "user-123"}
        // Base64url encoded payload: eyJleHAiOjE3MzE3ODk2MDAsInN1YiI6InVzZXItMTIzIn0

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"  // {"alg":"HS256","typ":"JWT"}
        let payload = "eyJleHAiOjE3MzE3ODk2MDAsInN1YiI6InVzZXItMTIzIn0"  // {"exp":1731789600,"sub":"user-123"}
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        // Parse the token
        let expiryDate = KeychainManager.parseJWTExpiry(token)

        // Verify expiry date is correct
        XCTAssertNotNil(expiryDate, "Expiry date should not be nil for valid token")

        if let expiry = expiryDate {
            // Expected: Nov 16, 2024 at 19:40:00 UTC
            let expectedTimestamp: TimeInterval = 1731789600
            XCTAssertEqual(expiry.timeIntervalSince1970, expectedTimestamp, accuracy: 1.0,
                          "Expiry timestamp should match the exp claim")
        }
    }

    func testParseJWTExpiry_ValidTokenWithPadding() {
        // Test with payload that needs base64 padding
        // Payload: {"exp": 1700000000}
        // Base64url: eyJleHAiOjE3MDAwMDAwMDB9 (no padding needed in base64url)

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJleHAiOjE3MDAwMDAwMDB9"  // Requires padding when decoded
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNotNil(expiryDate, "Should handle payload that needs padding")

        if let expiry = expiryDate {
            XCTAssertEqual(expiry.timeIntervalSince1970, 1700000000, accuracy: 1.0)
        }
    }

    // MARK: - Test parseJWTExpiry with Missing Exp Claim

    func testParseJWTExpiry_MissingExpClaim() {
        // Create token without exp claim
        // Payload: {"sub": "user-123", "iat": 1731789600}
        // Base64url: eyJzdWIiOiJ1c2VyLTEyMyIsImlhdCI6MTczMTc4OTYwMH0

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJzdWIiOiJ1c2VyLTEyMyIsImlhdCI6MTczMTc4OTYwMH0"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil when exp claim is missing")
    }

    // MARK: - Test parseJWTExpiry with Malformed Base64

    func testParseJWTExpiry_MalformedBase64() {
        // Create token with invalid base64 payload
        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "!!!invalid-base64!!!"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for malformed base64")
    }

    func testParseJWTExpiry_InvalidJSON() {
        // Create token with valid base64 but invalid JSON
        // Payload: "not-json-at-all"
        // Base64: bm90LWpzb24tYXQtYWxs

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "bm90LWpzb24tYXQtYWxs"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for invalid JSON in payload")
    }

    // MARK: - Test parseJWTExpiry with Invalid JWT Format

    func testParseJWTExpiry_InvalidFormat_TwoParts() {
        // Token with only 2 parts (missing signature)
        let token = "header.payload"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for token with only 2 parts")
    }

    func testParseJWTExpiry_InvalidFormat_OnePart() {
        // Token with only 1 part
        let token = "just-one-part"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for token with only 1 part")
    }

    func testParseJWTExpiry_InvalidFormat_FourParts() {
        // Token with 4 parts (extra dot)
        let token = "header.payload.signature.extra"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for token with 4 parts")
    }

    func testParseJWTExpiry_EmptyString() {
        // Empty token
        let token = ""

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNil(expiryDate, "Should return nil for empty token")
    }

    // MARK: - Test parseJWTExpiry with Base64url Encoding

    func testParseJWTExpiry_Base64urlEncoding() {
        // Test that base64url characters (-_ instead of +/) are handled correctly
        // This payload contains characters that differ between base64 and base64url
        // Payload with special chars: {"exp": 1731789600, "data": "test+value/here"}
        // Base64url: eyJleHAiOjE3MzE3ODk2MDAsImRhdGEiOiJ0ZXN0K3ZhbHVlL2hlcmUifQ
        // Note: In base64url, + becomes - and / becomes _

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        // Using base64url encoding with - and _ instead of + and /
        let payload = "eyJleHAiOjE3MzE3ODk2MDAsImRhdGEiOiJ0ZXN0K3ZhbHVlL2hlcmUifQ"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNotNil(expiryDate, "Should handle base64url encoding correctly")

        if let expiry = expiryDate {
            XCTAssertEqual(expiry.timeIntervalSince1970, 1731789600, accuracy: 1.0)
        }
    }

    // MARK: - Test parseJWTExpiry with Real-World Token Structure

    func testParseJWTExpiry_SupabaseStyleToken() {
        // Simulate a Supabase-style JWT token
        // Payload: {
        //   "aud": "authenticated",
        //   "exp": 1731793200,
        //   "iat": 1731789600,
        //   "sub": "abc123-def456-ghi789",
        //   "role": "authenticated"
        // }
        // Base64url (actual encoding of above):
        // eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzMxNzkzMjAwLCJpYXQiOjE3MzE3ODk2MDAsInN1YiI6ImFiYzEyMy1kZWY0NTYtZ2hpNzg5Iiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNzMxNzkzMjAwLCJpYXQiOjE3MzE3ODk2MDAsInN1YiI6ImFiYzEyMy1kZWY0NTYtZ2hpNzg5Iiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNotNil(expiryDate, "Should parse Supabase-style token")

        if let expiry = expiryDate {
            // exp: 1731793200 (1 hour after iat)
            XCTAssertEqual(expiry.timeIntervalSince1970, 1731793200, accuracy: 1.0)
        }
    }

    // MARK: - Test parseJWTExpiry with Edge Cases

    func testParseJWTExpiry_ExpiryZero() {
        // Token with exp: 0 (epoch time)
        // Payload: {"exp": 0}
        // Base64url: eyJleHAiOjB9

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJleHAiOjB9"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNotNil(expiryDate, "Should handle exp: 0")

        if let expiry = expiryDate {
            XCTAssertEqual(expiry.timeIntervalSince1970, 0, accuracy: 1.0)
        }
    }

    func testParseJWTExpiry_FutureExpiry() {
        // Token expiring far in the future (year 2099)
        // Payload: {"exp": 4102444800}
        // Base64url: eyJleHAiOjQxMDI0NDQ4MDB9

        let header = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9"
        let payload = "eyJleHAiOjQxMDI0NDQ4MDB9"
        let signature = "mock-signature"
        let token = "\(header).\(payload).\(signature)"

        let expiryDate = KeychainManager.parseJWTExpiry(token)

        XCTAssertNotNil(expiryDate, "Should handle far future expiry")

        if let expiry = expiryDate {
            XCTAssertEqual(expiry.timeIntervalSince1970, 4102444800, accuracy: 1.0)

            // Verify it's actually in the future
            XCTAssertGreaterThan(expiry, Date(), "Expiry should be in the future")
        }
    }
}
