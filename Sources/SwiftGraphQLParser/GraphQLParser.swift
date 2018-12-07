import Foundation

enum ParserError: Error, Equatable {
    case unexpectedToken(Token)
}

func parse(_ input: String) throws -> Document {
    var tokens = try ArraySlice(tokenize(input))
    var definitions: [ExecutableDefinition] = []
    
    while let definition = tokens.readDefinition() {
        definitions.append(definition)
    }
    
    if let token = tokens.first {
        throw ParserError.unexpectedToken(token)
    }
    
    return Document(definitions: definitions)
}

private extension ArraySlice where Element == Token {
    
    mutating func readDefinition() -> ExecutableDefinition? {
        if let operationDefinition = self.readOperationDefinition() {
            return .operation(operationDefinition)
        } else if let fragmentDefinition = self.readFragmentDefinition() {
            return .fragment(fragmentDefinition)
        } else {
            return nil
        }
    }
    
    mutating func readOperationDefinition() -> OperationDefinition? {
        if let selectionSet = readSelectionSet() {
            return .selectionSet(selectionSet)
        } else if let operation = readOperation() {
            return .operation(operation)
        }
        return nil
    }
    
    mutating func readFragmentDefinition() -> FragmentDefinition? {
        let start = self
        
        guard case .identifier(let val)? = self.popFirst(),
            val == "fragment",
            let name = readFragmentName(),
            let typeCondition = readTypeCondition() else {
            self = start
            return nil
        }
        
        let directives = readDirectives()
        
        guard let selectionSet = readSelectionSet() else {
            self = start
            return nil
        }
        return FragmentDefinition(fragmentName: name, typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
    }
    
    mutating func readFragmentName() -> String? {
        let start = self
        
        guard let name = readName(), name != "on" else {
            self = start
            return nil
        }
        
        return name
    }
    
    mutating func readTypeCondition() -> TypeCondition? {
        let start = self
        
        guard case .identifier(let val)? = self.popFirst(),
            val == "on",
            let type = readNamedType() else {
            self = start
            return nil
        }
        
        return TypeCondition(namedType: type)
    }
    
    mutating func readSelectionSet() -> [Selection]? {
        let start = self
        
        guard self.popFirst() == .leftCurlyBrace else {
            self = start
            return nil
        }
        
        var selections: [Selection] = []
        while let selection = readSelection() {
            selections.append(selection)
        }
        
        guard selections.isEmpty == false else {
            self = start
            return nil
        }
        
        guard self.popFirst() == .rightCurlyBrace else {
            self = start
            return nil
        }

        return selections
    }
    
    mutating func readSelection() -> Selection? {
        let start = self
        
        if let field = readField() {
            return Selection.field(field)
        } else if let fragmentSpread = readFragmentSpread() {
            return Selection.fragmentSpread(fragmentSpread)
        } else if let inlineFragment = readInlineFragment() {
            return Selection.inlineFragment(inlineFragment)
        }
        
        self = start
        return nil
    }
    
    mutating func readField() -> Field? {
        let start = self
        
        let alias = self.readAlias()
        
        guard let name = self.readName() else {
            self = start
            return nil
        }
        
        let arguments = self.readArguments()
        
        let directives = self.readDirectives()
        
        let selectionSet = self.readSelectionSet()
        
        return Field(alias: alias, name: name, arguments: arguments, directives: directives, selectionSet: selectionSet)
    }
    
    mutating func readAlias() -> String? {
        let start = self
        
        if case Token.identifier(let identifier)? = self.popFirst(), self.popFirst() == Token.colon {
            return identifier
        }
        
        self = start
        return nil
    }
    
    mutating func readName() -> String? {
        let start = self
        
        if case Token.identifier(let identifier)? = self.popFirst() {
            return identifier
        }
        
        self = start
        return nil
    }
    
    mutating func readArguments() -> [Argument] {
        let start = self
        
        guard self.popFirst() == Token.leftParentheses else {
            self = start
            return []
        }
        
        var arguments: [Argument] = []
        while let argument = self.readArgument() {
            arguments.append(argument)
        }
        
        guard arguments.isEmpty == false, self.popFirst() == Token.rightParentheses else {
            self = start
            return []
        }
        
        return arguments
    }
    
    mutating func readArgument() -> Argument? {
        let start = self
        
        guard let name = self.readName(),
            self.popFirst() == Token.colon,
            let value = self.readValue() else {
            self = start
            return nil
        }
        
        return Argument(name: name, value: value)
    }
    
    mutating func readValue() -> Value? {
        if let variable = readVariable() {
            return Value.variable(variable)
        }
        if let simpleValue = readSimpleValue() {
            return simpleValue
        }
        if let listValue = readListValue() {
            return Value.listValue(listValue)
        }
        if let objectValue = readObjectValue() {
            return Value.objectValue(objectValue)
        }
        return nil
    }
    
    mutating func readVariable() -> Variable? {
        let start = self
        
        guard self.popFirst() == Token.dollarSign, case .identifier(let identifier)? = self.popFirst() else {
            self = start
            return nil
        }
        
        return Variable(name: identifier)
    }
    
    mutating func readSimpleValue() -> Value? {
        let start = self
        
        switch self.popFirst() {
        case Token.intValue(let val)?:
            return Value.intValue(val)
        case Token.floatValue(let val)?:
            return Value.floatValue(val)
        case Token.stringValue(let val)?:
            return Value.stringValue(val)
        case Token.identifier(let val)? where val == "true":
            return Value.booleanValue(true)
        case Token.identifier(let val)? where val == "false":
            return Value.booleanValue(false)
        case Token.identifier(let val)? where val == "null":
            return Value.nullValue
        case Token.identifier(let val)?:
            return Value.enumValue(val)
        default:
            break
        }
        self = start
        return nil
    }
    
    mutating func readListValue() -> [Value]? {
        let start = self
        
        guard self.popFirst() == Token.leftSquareBracket else {
            self = start
            return nil
        }
        
        var values: [Value] = []
        while let value = readValue() {
            values.append(value)
        }
        
        guard self.popFirst() == Token.rightSquareBracket else {
            self = start
            return nil
        }
        
        return values
    }
    
    mutating func readObjectValue() -> [ObjectField]? {
        let start = self
        
        guard self.popFirst() == Token.leftCurlyBrace else {
            self = start
            return nil
        }
        
        var objectFields: [ObjectField] = []
        while let objectField = self.readObjectField() {
            objectFields.append(objectField)
        }
        
        guard self.popFirst() == Token.rightCurlyBrace else {
            self = start
            return nil
        }
        
        return objectFields
    }
    
    mutating func readObjectField() -> ObjectField? {
        let start = self
        
        guard let name = self.readName(),
            self.popFirst() == Token.colon,
            let value = self.readValue() else {
            self = start
            return nil
        }
        
        return ObjectField(name: name, value: value)
    }
    
    mutating func readDirectives() -> [Directive] {
        var directives: [Directive] = []
        
        while let directive = self.readDirective() {
            directives.append(directive)
        }
        
        return directives
    }
    
    mutating func readDirective() -> Directive? {
        let start = self
        
        guard self.popFirst() == Token.atSign,
            let name = self.readName() else {
            self = start
            return nil
        }
        
        let arguments = self.readArguments()
        
        return Directive(name: name, arguments: arguments)
    }
    
    mutating func readFragmentSpread() -> FragmentSpread? {
        let start = self
        
        guard self.popFirst() == Token.ellipses,
            let fragmentName = readFragmentName() else {
            self = start
            return nil
        }
        let directives = readDirectives()
        return FragmentSpread(fragmentName: fragmentName, directives: directives)
    }
    
    mutating func readInlineFragment() -> InlineFragment? {
        let start = self
        
        guard self.popFirst() == Token.ellipses else {
            self = start
            return nil
        }
        
        let typeCondition = readTypeCondition()
        let directives = readDirectives()
        
        guard let selectionSet = readSelectionSet() else {
            self = start
            return nil
        }
        return InlineFragment(typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
    }
    
    mutating func readOperation() -> Operation? {
        let start = self
        
        guard let operationType = readOperationType() else {
            self = start
            return nil
        }
        
        let name = readName()
        
        let variableDefinitions = readVariableDefinitions()
        
        let directives = readDirectives()
        
        guard let selectionSet = readSelectionSet() else {
            self = start
            return nil
        }
        
        return Operation(operationType: operationType, name: name, variableDefinitions: variableDefinitions, directives: directives, selectionSet: selectionSet)
    }
    
    mutating func readOperationType() -> OperationType? {
        let start = self
        switch self.popFirst() {
        case Token.identifier(let val)? where val == "query":
            return OperationType.query
        case Token.identifier(let val)? where val == "mutation":
            return OperationType.mutation
        case Token.identifier(let val)? where val == "subscription":
            return OperationType.subscription
        default:
            self = start
            return nil
        }
    }
    
    mutating func readVariableDefinitions() -> [VariableDefinition]? {
        let start = self
        
        guard self.popFirst() == Token.leftParentheses else {
            self = start
            return nil
        }
        
        var variableDefinitions: [VariableDefinition] = []
        while let variableDefinition = readVariableDefinition() {
            variableDefinitions.append(variableDefinition)
        }
        
        guard variableDefinitions.isEmpty == false, self.popFirst() == Token.rightParentheses else {
            self = start
            return nil
        }
        
        return variableDefinitions
    }
    
    mutating func readVariableDefinition() -> VariableDefinition? {
        let start = self
        
        guard let variable = readVariable(),
            self.popFirst() == Token.colon,
            let type = readType() else {
            self = start
            return nil
        }
        
        let defaultValue = readDefaultValue()
        
        let directives = readDirectives()
        
        return VariableDefinition(variable: variable, type: type, defaultValue: defaultValue, directives: directives)
    }
    
    mutating func readType() -> Type? {
        if let nonNullType = readNonNullType() {
            return nonNullType
        }
        if let listType = readListType() {
            return listType
        }
        if let namedType = readNamedType() {
            return Type.namedType(namedType)
        }
        return nil
    }
    
    mutating func readNamedType() -> String? {
        let start = self
        
        if case .identifier(let val)? = self.popFirst() {
            return val
        }
        
        self = start
        return nil
    }
    
    mutating func readListType() -> Type? {
        let start = self
        
        guard self.popFirst() == Token.leftSquareBracket,
            let type = readType(),
            self.popFirst() == Token.rightSquareBracket else {
            self = start
            return nil
        }
        return Type.listType(type)
    }
    
    mutating func readNonNullType() -> Type? {
        let start = self
        
        var type: Type
        if let namedType = readNamedType() {
            type = Type.namedType(namedType)
        } else if let listType = readListType() {
            type = listType
        } else {
            self = start
            return nil
        }
        
        guard self.popFirst() == Token.exclamation else {
            self = start
            return nil
        }
        
        return Type.nonNullType(type)
    }
    
    mutating func readDefaultValue() -> Value? {
        let start = self
        
        guard self.popFirst() == Token.equalsSign,
            let value = readValue() else {
            self = start
            return nil
        }
        
        return value
    }
}
