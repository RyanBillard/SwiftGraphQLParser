//
//  LexerTests.swift
//  SwiftGraphQLParserTests
//
//  Created by Ryan Billard on 2018-12-06.
//

import XCTest
@testable import SwiftGraphQLParser

class LexerTests: XCTestCase {
    func testTokenize() throws {
        let query = """
            fragment CustomerSummary on Customer {
                id
                defaultAddress {
                id
                    countryCode: countryCodeV2
                    formattedArea
                }
                email
                phone
                displayName
                firstName
                lastName
                hasNote
                image {
                id
                    transformedSrc(maxWidth: $imageMaxSize, maxHeight: $imageMaxSize)
                }
                ordersCount
                tags
                totalSpent
            }

            query CustomerList($after: String, $query: String, $imageMaxSize: Int!) {
                customers(first: 50, after: $after, sortKey: NAME, query: $query) {
                    edges {
                        cursor
                        node {
                            ...CustomerSummary
                        }
                    }
                    pageInfo {
                        hasNextPage
                    }
                }
            }
        """
        let tokens = try tokenize(query)
        let expectedTokens: [Token] = [
            .identifier("fragment"),
            .identifier("CustomerSummary"),
            .identifier("on"),
            .identifier("Customer"),
            .leftCurlyBrace,
            .identifier("id"),
            .identifier("defaultAddress"),
            .leftCurlyBrace,
            .identifier("id"),
            .identifier("countryCode"),
            .colon,
            .identifier("countryCodeV2"),
            .identifier("formattedArea"),
            .rightCurlyBrace,
            .identifier("email"),
            .identifier("phone"),
            .identifier("displayName"),
            .identifier("firstName"),
            .identifier("lastName"),
            .identifier("hasNote"),
            .identifier("image"),
            .leftCurlyBrace,
            .identifier("id"),
            .identifier("transformedSrc"),
            .leftParentheses,
            .identifier("maxWidth"),
            .colon,
            .dollarSign,
            .identifier("imageMaxSize"),
            .identifier("maxHeight"),
            .colon,
            .dollarSign,
            .identifier("imageMaxSize"),
            .rightParentheses,
            .rightCurlyBrace,
            .identifier("ordersCount"),
            .identifier("tags"),
            .identifier("totalSpent"),
            .rightCurlyBrace,
            .identifier("query"),
            .identifier("CustomerList"),
            .leftParentheses,
            .dollarSign,
            .identifier("after"),
            .colon,
            .identifier("String"),
            .dollarSign,
            .identifier("query"),
            .colon,
            .identifier("String"),
            .dollarSign,
            .identifier("imageMaxSize"),
            .colon,
            .identifier("Int"),
            .exclamation,
            .rightParentheses,
            .leftCurlyBrace,
            .identifier("customers"),
            .leftParentheses,
            .identifier("first"),
            .colon,
            .intValue("50"),
            .identifier("after"),
            .colon,
            .dollarSign,
            .identifier("after"),
            .identifier("sortKey"),
            .colon,
            .identifier("NAME"),
            .identifier("query"),
            .colon,
            .dollarSign,
            .identifier("query"),
            .rightParentheses,
            .leftCurlyBrace,
            .identifier("edges"),
            .leftCurlyBrace,
            .identifier("cursor"),
            .identifier("node"),
            .leftCurlyBrace,
            .ellipses,
            .identifier("CustomerSummary"),
            .rightCurlyBrace,
            .rightCurlyBrace,
            .identifier("pageInfo"),
            .leftCurlyBrace,
            .identifier("hasNextPage"),
            .rightCurlyBrace,
            .rightCurlyBrace,
            .rightCurlyBrace
        ]
        XCTAssertEqual(tokens, expectedTokens)
    }
}
