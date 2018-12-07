//
//  GraphQLVisitor.swift
//  SwiftGraphQLParser
//
//  Created by Ryan Billard on 2018-12-07.
//

import Foundation

class GraphQLTraverser {
    let document: Document
    let visitor: GraphQLBaseVisitor
    
    init(document: Document, with visitor: GraphQLBaseVisitor) {
        self.document = document
        self.visitor = visitor
    }
    
    func traverse() throws {
        try visitor.visitDocument(document: document)
        
        try traverseDefinitions(definitions: document.definitions)
        
        try visitor.exitDocument(document: document)
    }
    
    func traverseDefinitions(definitions: [ExecutableDefinition]) throws {
        try visitor.visitExecutableDefinitions(executableDefinitions: definitions)
        
        for definition in definitions {
            try traverseDefinition(definition: definition)
        }
        
        try visitor.exitExecutableDefinitions(executableDefinitions: definitions)
    }
    
    func traverseDefinition(definition: ExecutableDefinition) throws {
        switch definition {
        case .operation(let operation):
            try traverseOperationDefinition(definition: operation)
        case .fragment(let fragment):
            try traverseFragmentDefinition(definition: fragment)
        }
    }
    
    func traverseOperationDefinition(definition: OperationDefinition) throws {
        try visitor.visitOperationDefinition(operationDefinition: definition)
        
        switch definition {
        case .operation(let operation):
            try traverseOperation(operation: operation)
        case .selectionSet(let selectionSet):
            try traverseSelectionSet(selectionSet: selectionSet)
        }
        
        try visitor.exitOperationDefinition(operationDefinition: definition)
    }
    
    func traverseFragmentDefinition(definition: FragmentDefinition) throws {
        try visitor.visitFragmentDefinition(fragmentDefinition: definition)
        
        try traverseTypeCondition(typeCondition: definition.typeCondition)
        try traverseDirectives(directives: definition.directives)
        try traverseSelectionSet(selectionSet: definition.selectionSet)
        
        try visitor.exitFragmentDefinition(fragmentDefinition: definition)
    }
    
    func traverseOperation(operation: Operation) throws {
        try visitor.visitOperation(operation: operation)
        
        if let variableDefinitions = operation.variableDefinitions {
            try traverseVariableDefinitions(definitions: variableDefinitions)
        }
        try traverseDirectives(directives: operation.directives)
        try traverseSelectionSet(selectionSet: operation.selectionSet)
        
        try visitor.exitOperation(operation: operation)
    }
    
    func traverseSelectionSet(selectionSet: [Selection]) throws {
        try visitor.visitSelectionSet(selectionSet: selectionSet)
        
        for selection in selectionSet {
            switch selection {
            case .field(let field):
                try traverseField(field: field)
            case .fragmentSpread(let fragmentSpread):
                try traverseFragmentSpread(fragmentSpread: fragmentSpread)
            case .inlineFragment(let inlineFragment):
                try traverseInlineFragment(inlineFragment: inlineFragment)
            }
        }
        
        try visitor.exitSelectionSet(selectionSet: selectionSet)
    }
    
    func traverseTypeCondition(typeCondition: TypeCondition) throws {
        try visitor.visitNamedType(namedType: typeCondition.namedType)
        try visitor.exitNamedType(namedType: typeCondition.namedType)
    }
    
    func traverseDirectives(directives: [Directive]) throws {
        for directive in directives {
            try visitor.visitDirective(directive: directive)
            try visitor.exitDirective(directive: directive)
        }
    }
    
    func traverseVariableDefinitions(definitions: [VariableDefinition]) throws {
        for definition in definitions {
            try traverseVariableDefinition(definition: definition)
        }
    }
    
    func traverseVariableDefinition(definition: VariableDefinition) throws {
        try visitor.visitVariableDefinition(variableDefinition: definition)
        
        try traverseVariable(variable: definition.variable)
        try traverseType(type: definition.type)
        if let defaultValue = definition.defaultValue {
            try traverseValue(value: defaultValue)
        }
        try traverseDirectives(directives: definition.directives)
        
        try visitor.exitVariableDefinition(variableDefinition: definition)
    }
    
    func traverseVariable(variable: Variable) throws {
        try visitor.visitVariable(variable: variable)
        try visitor.exitVariable(variable: variable)
    }
    
    func traverseField(field: Field) throws {
        try visitor.visitField(field: field)
        
        try traverseArguments(arguments: field.arguments)
        try traverseDirectives(directives: field.directives)
        if let selectionSet = field.selectionSet {
            try traverseSelectionSet(selectionSet: selectionSet)
        }
        
        try visitor.exitField(field: field)
    }
    
    func traverseFragmentSpread(fragmentSpread: FragmentSpread) throws {
        try visitor.visitFragmentSpread(fragmentSpread: fragmentSpread)
        
        try traverseDirectives(directives: fragmentSpread.directives)
        
        try visitor.exitFragmentSpread(fragmentSpread: fragmentSpread)
    }
    
    func traverseInlineFragment(inlineFragment: InlineFragment) throws {
        try visitor.visitInlineFragment(inlineFragment: inlineFragment)
        
        if let typeCondition = inlineFragment.typeCondition {
            try traverseTypeCondition(typeCondition: typeCondition)
        }
        try traverseDirectives(directives: inlineFragment.directives)
        try traverseSelectionSet(selectionSet: inlineFragment.selectionSet)
        
        try visitor.exitInlineFragment(inlineFragment: inlineFragment)
    }
    
    func traverseArguments(arguments: [Argument]) throws {
        for argument in arguments {
            try traverseArgument(argument: argument)
        }
    }
    
    func traverseArgument(argument: Argument) throws {
        try visitor.visitArgument(argument: argument)
        
        try traverseValue(value: argument.value)
        
        try visitor.exitArgument(argument: argument)
    }
    
    func traverseType(type: Type) throws {
        switch type {
        case .listType(let type):
            try traverseListType(wrappedType: type)
        case .nonNullType(let type):
            try traverseNonNullType(wrappedType: type)
        case .namedType(let type):
            try traverseNamedType(namedType: type)
        }
    }
    
    func traverseNamedType(namedType: String) throws {
        try visitor.visitNamedType(namedType: namedType)
        try visitor.exitNamedType(namedType: namedType)
    }
    
    func traverseNonNullType(wrappedType: Type) throws {
        try visitor.visitNonNullType(nonNullType: wrappedType)
        try traverseType(type: wrappedType)
        try visitor.exitNonNullType(nonNullType: wrappedType)
    }
    
    func traverseListType(wrappedType: Type) throws {
        try visitor.visitListType(listType: wrappedType)
        try traverseType(type: wrappedType)
        try visitor.exitListType(listType: wrappedType)
    }
    
    func traverseValue(value: Value) throws {
        switch value {
        case .variable(let variable):
            try traverseVariable(variable: variable)
        case .booleanValue(let val):
            try visitor.visitBooleanValue(booleanValue: val)
            try visitor.exitBooleanValue(booleanValue: val)
        case .enumValue(let val):
            try visitor.visitEnumValue(enumValue: val)
            try visitor.exitEnumValue(enumValue: val)
        case .floatValue(let val):
            try visitor.visitFloatValue(floatValue: val)
            try visitor.exitFloatValue(floatValue: val)
        case .intValue(let val):
            try visitor.visitIntValue(intValue: val)
            try visitor.exitIntValue(intValue: val)
        case .stringValue(let val):
            try visitor.visitStringValue(stringValue: val)
            try visitor.exitStringValue(stringValue: val)
        case .nullValue:
            try visitor.visitNullValue()
            try visitor.exitNullValue()
        case .listValue(let vals):
            try traverseListValue(values: vals)
        case .objectValue(let vals):
            try traverseObjectValue(values: vals)
        }
    }
    
    func traverseListValue(values: [Value]) throws {
        try visitor.visitListValue(listValue: values)
        
        for value in values {
            try traverseValue(value: value)
        }
        
        try visitor.exitListValue(listValue: values)
    }
    
    func traverseObjectValue(values: [ObjectField]) throws {
        try visitor.visitObjectValue(objectValue: values)
        
        for field in values {
            try traverseObjectField(field: field)
        }
        
        try visitor.exitObjectValue(objectValue: values)
    }
    
    func traverseObjectField(field: ObjectField) throws {
        try visitor.visitObjectField(objectField: field)
        
        try traverseValue(value: field.value)
        
        try visitor.exitObjectField(objectField: field)
    }
}

class GraphQLBaseVisitor {
    struct Error: LocalizedError {
        let errorDescription: String?
        
        init(description: String) {
            self.errorDescription = description
        }
    }
    
    func visitDocument(document: Document) throws {}
    
    func exitDocument(document: Document) throws {}
    
    func visitOperationDefinition(operationDefinition: OperationDefinition) throws {}
    
    func exitOperationDefinition(operationDefinition: OperationDefinition) throws {}
    
    func visitOperation(operation: Operation) throws {}
    
    func exitOperation(operation: Operation) throws {}
    
    func visitExecutableDefinitions(executableDefinitions: [ExecutableDefinition]) throws {}
    
    func exitExecutableDefinitions(executableDefinitions: [ExecutableDefinition]) throws {}
    
    func visitVariableDefinition(variableDefinition: VariableDefinition) throws {}
    
    func exitVariableDefinition(variableDefinition: VariableDefinition) throws {}
    
    func visitSelectionSet(selectionSet: [Selection]) throws {}
    
    func exitSelectionSet(selectionSet: [Selection]) throws {}
    
    func visitField(field: Field) throws {}
    
    func exitField(field: Field) throws {}
    
    func visitFragmentSpread(fragmentSpread: FragmentSpread) throws {}
    
    func exitFragmentSpread(fragmentSpread: FragmentSpread) throws {}
    
    func visitArgument(argument: Argument) throws {}
    
    func visitInlineFragment(inlineFragment: InlineFragment) throws {}
    
    func visitFragmentDefinition(fragmentDefinition: FragmentDefinition) throws {}
    
    func exitFragmentDefinition(fragmentDefinition: FragmentDefinition) throws {}
    
    func exitNamedType(namedType: String) throws {}
    
    func exitListType(listType: Type) throws {}
    
    func exitNonNullType(nonNullType: Type) throws {}
    
    func visitNamedType(namedType: String) throws {}
    
    func visitValue(value: Value) throws {}
    
    func visitVariable(variable: Variable) throws {}
    
    func visitIntValue(intValue: String) throws {}
    
    func visitFloatValue(floatValue: String) throws {}
    
    func visitStringValue(stringValue: String) throws {}
    
    func visitBooleanValue(booleanValue: Bool) throws {}
    
    func visitNullValue() throws {}
    
    func visitEnumValue(enumValue: String) throws {}
    
    func visitListValue(listValue: [Value]) throws {}
    
    func visitObjectValue(objectValue: [ObjectField]) throws {}
    
    func visitObjectField(objectField: ObjectField) throws {}
    
    func visitDirective(directive: Directive) throws {}
    
    func visitListType(listType: Type) throws {}
    
    func visitNonNullType(nonNullType: Type) throws {}
    
    func exitArgument(argument: Argument) throws {}
    
    func exitInlineFragment(inlineFragment: InlineFragment) throws {}
    
    func exitValue(value: Value) throws {}
    
    func exitVariable(variable: Variable) throws {}
    
    func exitIntValue(intValue: String) throws {}
    
    func exitFloatValue(floatValue: String) throws {}
    
    func exitStringValue(stringValue: String) throws {}
    
    func exitBooleanValue(booleanValue: Bool) throws {}
    
    func exitNullValue() throws {}
    
    func exitEnumValue(enumValue: String) throws {}
    
    func exitListValue(listValue: [Value]) throws {}
    
    func exitObjectValue(objectValue: [ObjectField]) throws {}
    
    func exitObjectField(objectField: ObjectField) throws {}
    
    func exitDirective(directive: Directive) throws {}
}

