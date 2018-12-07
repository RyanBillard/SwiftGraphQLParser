//
//  GraphQLDocument.swift
//  SwiftGraphQLParser
//
//  Created by Ryan Billard on 2018-12-07.
//

import Foundation

struct Document {
    let definitions: [ExecutableDefinition]
}

enum ExecutableDefinition {
    case operation(OperationDefinition)
    case fragment(FragmentDefinition)
}

enum OperationDefinition {
    case selectionSet([Selection])
    case operation(Operation)
}

struct Operation {
    let operationType: OperationType
    let name: String?
    let variableDefinitions: [VariableDefinition]?
    let directives: [Directive]
    let selectionSet: [Selection]
}

enum OperationType: String {
    case query
    case mutation
    case subscription
}

enum Selection {
    case field(Field)
    case fragmentSpread(FragmentSpread)
    case inlineFragment(InlineFragment)
}

struct Field {
    let alias: String?
    let name: String
    let arguments: [Argument]
    let directives: [Directive]
    let selectionSet: [Selection]?
}

struct Argument {
    let name: String
    let value: Value
}

struct FragmentSpread {
    let fragmentName: String
    let directives: [Directive]
}

struct InlineFragment {
    let typeCondition: TypeCondition?
    let directives: [Directive]
    let selectionSet: [Selection]
}

struct FragmentDefinition {
    let fragmentName: String
    let typeCondition: TypeCondition
    let directives: [Directive]
    let selectionSet: [Selection]
}

struct TypeCondition {
    let namedType: String
}

indirect enum Value {
    case variable(Variable)
    case intValue(String)
    case floatValue(String)
    case stringValue(String)
    case booleanValue(Bool)
    case nullValue
    case enumValue(String)
    case listValue([Value])
    case objectValue([ObjectField])
}

struct ObjectField {
    let name: String
    let value: Value
}

struct VariableDefinitions {
    let variableDefinitions: [VariableDefinition]
}

struct VariableDefinition {
    let variable: Variable
    let type: Type
    let defaultValue: Value?
    let directives: [Directive]
}

struct Variable {
    let name: String
}

indirect enum Type {
    case namedType(String)
    case listType(Type)
    case nonNullType(Type)
}

struct Directive {
    let name: String
    let arguments: [Argument]
}
