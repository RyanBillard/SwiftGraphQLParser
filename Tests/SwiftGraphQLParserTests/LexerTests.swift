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

            query CustomerList($after: String, $imageMaxSize: Int!) {
                customers(first: 50, after: $after, sortKey: NAME, query: "abcdefg") {
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
		let tokens = tokenize(query).map { $0.type }
		let expectedTokens: [TokenType] = [
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
			.stringValue(.singleQuote("abcdefg")),
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
	
	func testTokenize2() throws {
		let query = """
		fragment FulfillmentService on FulfillmentService {
		  id
		  productBased
		  serviceName
		  inventoryManagement
		  handle
		  type
		  location {
			id
		  }
		}

		query ProductDetails($productID: ID!, $productImageSize: Int!, $variantImageSize: Int!, $locationId: ID!) {
		  ...PublicationsSummary
		  product(id: $productID) {
			...ProductDetails
		  }
		  shop {
			fulfillmentServices {
			  ...FulfillmentService
			}
			weightUnit
			richTextEditorUrl
			url
			productCostBetaFlag: beta(name: "product_cost")
		  }
		  onlineStore {
			urlWithPasswordBypass
		  }
		}

		"""
		let tokens = tokenize(query).map { $0.type }
		let expectedTokens: [TokenType] = [
			TokenType.identifier("fragment"),
			TokenType.identifier("FulfillmentService"),
			TokenType.identifier("on"),
			TokenType.identifier("FulfillmentService"),
			TokenType.leftCurlyBrace,
			TokenType.identifier("id"),
			TokenType.identifier("productBased"),
			TokenType.identifier("serviceName"),
			TokenType.identifier("inventoryManagement"),
			TokenType.identifier("handle"),
			TokenType.identifier("type"),
			TokenType.identifier("location"),
			TokenType.leftCurlyBrace,
			TokenType.identifier("id"),
			TokenType.rightCurlyBrace,
			TokenType.rightCurlyBrace,
			TokenType.identifier("query"),
			TokenType.identifier("ProductDetails"),
			TokenType.leftParentheses,
			TokenType.dollarSign,
			TokenType.identifier("productID"),
			TokenType.colon,
			TokenType.identifier("ID"),
			TokenType.exclamation,
			TokenType.dollarSign,
			TokenType.identifier("productImageSize"),
			TokenType.colon,
			TokenType.identifier("Int"),
			TokenType.exclamation,
			TokenType.dollarSign,
			TokenType.identifier("variantImageSize"),
			TokenType.colon,
			TokenType.identifier("Int"),
			TokenType.exclamation,
			TokenType.dollarSign,
			TokenType.identifier("locationId"),
			TokenType.colon,
			TokenType.identifier("ID"),
			TokenType.exclamation,
			TokenType.rightParentheses,
			TokenType.leftCurlyBrace,
			TokenType.ellipses,
			TokenType.identifier("PublicationsSummary"),
			TokenType.identifier("product"),
			TokenType.leftParentheses,
			TokenType.identifier("id"),
			TokenType.colon,
			TokenType.dollarSign,
			TokenType.identifier("productID"),
			TokenType.rightParentheses,
			TokenType.leftCurlyBrace,
			TokenType.ellipses,
			TokenType.identifier("ProductDetails"),
			TokenType.rightCurlyBrace,
			TokenType.identifier("shop"),
			TokenType.leftCurlyBrace,
			TokenType.identifier("fulfillmentServices"),
			TokenType.leftCurlyBrace,
			TokenType.ellipses,
			TokenType.identifier("FulfillmentService"),
			TokenType.rightCurlyBrace,
			TokenType.identifier("weightUnit"),
			TokenType.identifier("richTextEditorUrl"),
			TokenType.identifier("url"),
			TokenType.identifier("productCostBetaFlag"),
			TokenType.colon,
			TokenType.identifier("beta"),
			TokenType.leftParentheses,
			TokenType.identifier("name"),
			TokenType.colon,
			TokenType.stringValue(SwiftGraphQLParser.StringValue.singleQuote("product_cost")),
			TokenType.rightParentheses,
			TokenType.rightCurlyBrace,
			TokenType.identifier("onlineStore"),
			TokenType.leftCurlyBrace,
			TokenType.identifier("urlWithPasswordBypass"),
			TokenType.rightCurlyBrace,
			TokenType.rightCurlyBrace,
		]
		XCTAssertEqual(tokens, expectedTokens)
	}
}
