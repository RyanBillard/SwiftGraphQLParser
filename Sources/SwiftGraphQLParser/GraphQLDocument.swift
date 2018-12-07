//
//  GraphQLDocument.swift
//  SwiftGraphQLParser
//
//  Created by Ryan Billard on 2018-12-07.
//

import Foundation

public struct Document {
    public let definitions: [ExecutableDefinition]
}

public enum ExecutableDefinition {
    case operation(OperationDefinition)
    case fragment(FragmentDefinition)
}

public enum OperationDefinition {
    case selectionSet([Selection])
    case operation(Operation)
}

public struct Operation {
    public let operationType: OperationType
    public let name: String?
    public let variableDefinitions: [VariableDefinition]?
    public let directives: [Directive]
    public let selectionSet: [Selection]
}

public enum OperationType: String {
    case query
    case mutation
    case subscription
}

public enum Selection {
    case field(Field)
    case fragmentSpread(FragmentSpread)
    case inlineFragment(InlineFragment)
}

public struct Field {
    public let alias: String?
    public let name: String
    public let arguments: [Argument]
    public let directives: [Directive]
    public let selectionSet: [Selection]?
}

public struct Argument {
    public let name: String
    public let value: Value
}

public struct FragmentSpread {
    public let fragmentName: String
    public let directives: [Directive]
}

public struct InlineFragment {
    public let typeCondition: TypeCondition?
    public let directives: [Directive]
    public let selectionSet: [Selection]
}

public struct FragmentDefinition {
    public let fragmentName: String
    public let typeCondition: TypeCondition
    public let directives: [Directive]
    public let selectionSet: [Selection]
}

public struct TypeCondition {
    public let namedType: String
}

public indirect enum Value {
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

public struct ObjectField {
    public let name: String
    public let value: Value
}

public struct VariableDefinitions {
    public let variableDefinitions: [VariableDefinition]
}

public struct VariableDefinition {
    public let variable: Variable
    public let type: Type
    public let defaultValue: Value?
    public let directives: [Directive]
}

public struct Variable {
    public let name: String
}

public indirect enum Type {
    case namedType(String)
    case listType(Type)
    case nonNullType(Type)
}

public struct Directive {
    public let name: String
    public let arguments: [Argument]
}
