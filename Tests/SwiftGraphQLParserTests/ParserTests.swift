import XCTest
@testable import SwiftGraphQLParser

class ParserTests: XCTestCase {
    func testParse() throws {
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
        
        let document = try parse(query)
        print(document)
    }
}
