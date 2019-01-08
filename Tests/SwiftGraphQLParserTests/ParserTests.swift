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
		let expectedDocument = Document(definitions: [ExecutableDefinition.fragment(FragmentDefinition(fragmentName: "CustomerSummary", typeCondition: TypeCondition(namedType: "Customer"), directives: [], selectionSet: [Selection.field(Field(alias: nil, name: "id", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "defaultAddress", arguments: [], directives: [], selectionSet: Optional([Selection.field(Field(alias: nil, name: "id", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: Optional("countryCode"), name: "countryCodeV2", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "formattedArea", arguments: [], directives: [], selectionSet: nil))]))), Selection.field(Field(alias: nil, name: "email", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "phone", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "displayName", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "firstName", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "lastName", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "hasNote", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "image", arguments: [], directives: [], selectionSet: Optional([Selection.field(Field(alias: nil, name: "id", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "transformedSrc", arguments: [Argument(name: "maxWidth", value: Value.variable(Variable(name: "imageMaxSize"))), Argument(name: "maxHeight", value: Value.variable(Variable(name: "imageMaxSize")))], directives: [], selectionSet: nil))]))), Selection.field(Field(alias: nil, name: "ordersCount", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "tags", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "totalSpent", arguments: [], directives: [], selectionSet: nil))])), ExecutableDefinition.operation(OperationDefinition.operation(Operation(operationType: OperationType.query, name: Optional("CustomerList"), variableDefinitions: Optional([VariableDefinition(variable: Variable(name: "after"), type: Type.namedType("String"), defaultValue: nil, directives: []), VariableDefinition(variable: Variable(name: "query"), type: Type.namedType("String"), defaultValue: nil, directives: []), VariableDefinition(variable: Variable(name: "imageMaxSize"), type: Type.nonNullType(Type.namedType("Int")), defaultValue: nil, directives: [])]), directives: [], selectionSet: [Selection.field(Field(alias: nil, name: "customers", arguments: [Argument(name: "first", value: Value.intValue("50")), Argument(name: "after", value: Value.variable(Variable(name: "after"))), Argument(name: "sortKey", value: Value.enumValue("NAME")), Argument(name: "query", value: Value.variable(Variable(name: "query")))], directives: [], selectionSet: Optional([Selection.field(Field(alias: nil, name: "edges", arguments: [], directives: [], selectionSet: Optional([Selection.field(Field(alias: nil, name: "cursor", arguments: [], directives: [], selectionSet: nil)), Selection.field(Field(alias: nil, name: "node", arguments: [], directives: [], selectionSet: Optional([Selection.fragmentSpread(FragmentSpread(fragmentName: "CustomerSummary", directives: []))])))]))), Selection.field(Field(alias: nil, name: "pageInfo", arguments: [], directives: [], selectionSet: Optional([Selection.field(Field(alias: nil, name: "hasNextPage", arguments: [], directives: [], selectionSet: nil))])))])))])))])
		XCTAssertEqual(document, expectedDocument)
    }
}
