import Foundation

public enum ParserErrorType: String {
	case missingFragmentName
	case missingTypeCondition
	case missingSelectionSet
	case unterminatedSelectionSet
	case emptySelectionSet
	case emptyArgumentList
	case unterminatedArgumentList
	case missingArgumentValue
	case unterminatedListValue
	case unterminatedObjectValue
	case missingObjectValue
	case missingDirectiveName
	case emptyVariableDefinitionList
	case unterminatedVariableDefinitionList
	case missingVariableType
}

public struct UnexpectedTokenError: LocalizedError {
	public let token: TokenType
	public let line: Int
	public let column: Int
	
	public var errorDescription: String? {
		return "Unexpected token: \(token) at line: \(line) column: \(column)"
	}
}

public struct ParserError: LocalizedError {
	public let type: ParserErrorType
	public let line: Int
	public let column: Int
	
	public var errorDescription: String? {
		return "\(type) at line: \(line) column: \(column)"
	}
}

private struct InternalParserError: Error {
	let type: ParserErrorType
	let index: String.Index
}

public func parse(_ input: String) throws -> Document {
	var tokens = ArraySlice(tokenize(input))
	var definitions: [ExecutableDefinition] = []
	
	do {
		while let definition = try tokens.readDefinition() {
			definitions.append(definition)
		}
	} catch let error as InternalParserError {
		let (line, column) = error.index.lineAndColumn(in: input)
		throw ParserError(type: error.type, line: line, column: column)
	}
	
	if let token = tokens.first {
		let (line, column) = token.range.upperBound.lineAndColumn(in: input)
		throw UnexpectedTokenError(token: token.type, line: line, column: column)
	}
	
	return Document(definitions: definitions)
}

private extension ArraySlice where Element == Token {
	
	mutating func readDefinition() throws -> ExecutableDefinition? {
		if let operationDefinition = try self.readOperationDefinition() {
			return .operation(operationDefinition)
		} else if let fragmentDefinition = try self.readFragmentDefinition() {
			return .fragment(fragmentDefinition)
		} else {
			return nil
		}
	}
	
	mutating func readOperationDefinition() throws -> OperationDefinition? {
		if let selectionSet = try readSelectionSet() {
			return .selectionSet(selectionSet)
		} else if let operation = try readOperation() {
			return .operation(operation)
		}
		return nil
	}
	
	mutating func readFragmentDefinition() throws -> FragmentDefinition? {
		let start = self
		
		guard case .identifier(let val)? = self.popFirst()?.type,
			val == "fragment" else {
				self = start
				return nil
		}
		
		guard let name = readFragmentName() else {
			throw InternalParserError(type: .missingFragmentName, index: start.first!.range.upperBound)
		}
		
		guard let typeCondition = readTypeCondition() else {
			throw InternalParserError(type: .missingTypeCondition, index: start.first!.range.upperBound)
		}
		
		let directives = try readDirectives()
		
		guard let selectionSet = try readSelectionSet() else {
			throw InternalParserError(type: .missingSelectionSet, index: start.first!.range.upperBound)
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
		
		guard case .identifier(let val)? = self.popFirst()?.type,
			val == "on",
			let type = readNamedType() else {
				self = start
				return nil
		}
		
		return TypeCondition(namedType: type)
	}
	
	mutating func readSelectionSet() throws -> [Selection]? {
		let start = self
		
		guard self.popFirst()?.type == .leftCurlyBrace else {
			self = start
			return nil
		}
		
		var selections: [Selection] = []
		while let selection = try readSelection() {
			selections.append(selection)
		}
		
		guard selections.isEmpty == false else {
			throw InternalParserError(type: .emptySelectionSet, index: start.first!.range.upperBound)
		}
		
		guard self.popFirst()?.type == .rightCurlyBrace else {
			throw InternalParserError(type: .unterminatedSelectionSet, index: start.first!.range.upperBound)
		}
		
		return selections
	}
	
	mutating func readSelection() throws -> Selection? {
		let start = self
		
		if let field = try readField() {
			return Selection.field(field)
		} else if let fragmentSpread = try readFragmentSpread() {
			return Selection.fragmentSpread(fragmentSpread)
		} else if let inlineFragment = try readInlineFragment() {
			return Selection.inlineFragment(inlineFragment)
		}
		
		self = start
		return nil
	}
	
	mutating func readField() throws -> Field? {
		let start = self
		
		let alias = self.readAlias()
		
		guard let name = self.readName() else {
			self = start
			return nil
		}
		
		let arguments = try self.readArguments()
		
		let directives = try self.readDirectives()
		
		let selectionSet = try self.readSelectionSet()
		
		return Field(alias: alias, name: name, arguments: arguments, directives: directives, selectionSet: selectionSet)
	}
	
	mutating func readAlias() -> String? {
		let start = self
		
		if case TokenType.identifier(let identifier)? = self.popFirst()?.type, self.popFirst()?.type == TokenType.colon {
			return identifier
		}
		
		self = start
		return nil
	}
	
	mutating func readName() -> String? {
		let start = self
		
		if case TokenType.identifier(let identifier)? = self.popFirst()?.type {
			return identifier
		}
		
		self = start
		return nil
	}
	
	mutating func readArguments() throws -> [Argument] {
		let start = self
		
		guard self.popFirst()?.type == TokenType.leftParentheses else {
			self = start
			return []
		}
		
		var arguments: [Argument] = []
		while let argument = try self.readArgument() {
			arguments.append(argument)
		}
		
		guard arguments.isEmpty == false else {
			throw InternalParserError(type: .emptyArgumentList, index: start.first!.range.upperBound)
		}
		
		guard self.popFirst()?.type == TokenType.rightParentheses else {
			throw InternalParserError(type: .unterminatedArgumentList, index: start.first!.range.upperBound)
		}
		
		return arguments
	}
	
	mutating func readArgument() throws -> Argument? {
		let start = self
		
		guard let name = self.readName(),
			self.popFirst()?.type == TokenType.colon else {
				self = start
				return nil
		}
		
		guard let value = try self.readValue() else {
			throw InternalParserError(type: .missingArgumentValue, index: start.first!.range.upperBound)
		}
		
		return Argument(name: name, value: value)
	}
	
	mutating func readValue() throws -> Value? {
		if let variable = readVariable() {
			return Value.variable(variable)
		}
		if let simpleValue = readSimpleValue() {
			return simpleValue
		}
		if let listValue = try readListValue() {
			return Value.listValue(listValue)
		}
		if let objectValue = try readObjectValue() {
			return Value.objectValue(objectValue)
		}
		return nil
	}
	
	mutating func readVariable() -> Variable? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.dollarSign, case .identifier(let identifier)? = self.popFirst()?.type else {
			self = start
			return nil
		}
		
		return Variable(name: identifier)
	}
	
	mutating func readSimpleValue() -> Value? {
		let start = self
		
		switch self.popFirst()?.type {
		case TokenType.intValue(let val)?:
			return Value.intValue(val)
		case TokenType.floatValue(let val)?:
			return Value.floatValue(val)
		case TokenType.stringValue(let val)?:
			return Value.stringValue(val)
		case TokenType.identifier(let val)? where val == "true":
			return Value.booleanValue(true)
		case TokenType.identifier(let val)? where val == "false":
			return Value.booleanValue(false)
		case TokenType.identifier(let val)? where val == "null":
			return Value.nullValue
		case TokenType.identifier(let val)?:
			return Value.enumValue(val)
		default:
			break
		}
		self = start
		return nil
	}
	
	mutating func readListValue() throws -> [Value]? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.leftSquareBracket else {
			self = start
			return nil
		}
		
		var values: [Value] = []
		while let value = try readValue() {
			values.append(value)
		}
		
		guard self.popFirst()?.type == TokenType.rightSquareBracket else {
			throw InternalParserError(type: .unterminatedListValue, index: start.first!.range.upperBound)
		}
		
		return values
	}
	
	mutating func readObjectValue() throws -> [ObjectField]? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.leftCurlyBrace else {
			self = start
			return nil
		}
		
		var objectFields: [ObjectField] = []
		while let objectField = try self.readObjectField() {
			objectFields.append(objectField)
		}
		
		guard self.popFirst()?.type == TokenType.rightCurlyBrace else {
			throw InternalParserError(type: .unterminatedObjectValue, index: start.first!.range.upperBound)
		}
		
		return objectFields
	}
	
	mutating func readObjectField() throws -> ObjectField? {
		let start = self
		
		guard let name = self.readName(),
			self.popFirst()?.type == TokenType.colon else {
				self = start
				return nil
		}
		
		guard let value = try self.readValue() else {
			throw InternalParserError(type: .missingObjectValue, index: start.first!.range.upperBound)
		}
		
		return ObjectField(name: name, value: value)
	}
	
	mutating func readDirectives() throws -> [Directive] {
		var directives: [Directive] = []
		
		while let directive = try self.readDirective() {
			directives.append(directive)
		}
		
		return directives
	}
	
	mutating func readDirective() throws -> Directive? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.atSign else {
				self = start
				return nil
		}
		
		guard let name = self.readName() else {
			throw InternalParserError(type: .missingDirectiveName, index: start.first!.range.upperBound)
		}
		
		let arguments = try self.readArguments()
		
		return Directive(name: name, arguments: arguments)
	}
	
	mutating func readFragmentSpread() throws -> FragmentSpread? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.ellipses,
			let fragmentName = readFragmentName() else {
				self = start
				return nil
		}
		let directives = try readDirectives()
		return FragmentSpread(fragmentName: fragmentName, directives: directives)
	}
	
	mutating func readInlineFragment() throws -> InlineFragment? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.ellipses else {
			self = start
			return nil
		}
		
		let typeCondition = readTypeCondition()
		let directives = try readDirectives()
		
		guard let selectionSet = try readSelectionSet() else {
			self = start
			return nil
		}
		return InlineFragment(typeCondition: typeCondition, directives: directives, selectionSet: selectionSet)
	}
	
	mutating func readOperation() throws -> Operation? {
		let start = self
		
		guard let operationType = readOperationType() else {
			self = start
			return nil
		}
		
		let name = readName()
		
		let variableDefinitions = try readVariableDefinitions()
		
		let directives = try readDirectives()
		
		guard let selectionSet = try readSelectionSet() else {
			throw InternalParserError(type: .missingSelectionSet, index: start.first!.range.upperBound)
		}
		
		return Operation(operationType: operationType, name: name, variableDefinitions: variableDefinitions, directives: directives, selectionSet: selectionSet)
	}
	
	mutating func readOperationType() -> OperationType? {
		let start = self
		switch self.popFirst()?.type {
		case TokenType.identifier(let val)? where val == "query":
			return OperationType.query
		case TokenType.identifier(let val)? where val == "mutation":
			return OperationType.mutation
		case TokenType.identifier(let val)? where val == "subscription":
			return OperationType.subscription
		default:
			self = start
			return nil
		}
	}
	
	mutating func readVariableDefinitions() throws -> [VariableDefinition]? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.leftParentheses else {
			self = start
			return nil
		}
		
		var variableDefinitions: [VariableDefinition] = []
		while let variableDefinition = try readVariableDefinition() {
			variableDefinitions.append(variableDefinition)
		}
		
		guard variableDefinitions.isEmpty == false else {
			throw InternalParserError(type: .emptyVariableDefinitionList, index: start.first!.range.upperBound)
		}
		
		guard self.popFirst()?.type == TokenType.rightParentheses else {
			throw InternalParserError(type: .unterminatedVariableDefinitionList, index: start.first!.range.upperBound)
		}
		
		return variableDefinitions
	}
	
	mutating func readVariableDefinition() throws -> VariableDefinition? {
		let start = self
		
		guard let variable = readVariable(),
			self.popFirst()?.type == TokenType.colon else {
				self = start
				return nil
		}
		
		guard let type = readType() else {
			throw InternalParserError(type: .missingVariableType, index: start.first!.range.upperBound)
		}

		let defaultValue = try readDefaultValue()
		
		let directives = try readDirectives()
		
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
		
		if case .identifier(let val)? = self.popFirst()?.type {
			return val
		}
		
		self = start
		return nil
	}
	
	mutating func readListType() -> Type? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.leftSquareBracket,
			let type = readType(),
			self.popFirst()?.type == TokenType.rightSquareBracket else {
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
		
		guard self.popFirst()?.type == TokenType.exclamation else {
			self = start
			return nil
		}
		
		return Type.nonNullType(type)
	}
	
	mutating func readDefaultValue() throws -> Value? {
		let start = self
		
		guard self.popFirst()?.type == TokenType.equalsSign,
			let value = try readValue() else {
				self = start
				return nil
		}
		
		return value
	}
}
