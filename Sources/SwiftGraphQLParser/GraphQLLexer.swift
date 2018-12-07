//
//  GraphQLLexer.swift
//  SwiftGraphQLParser
//
//  Created by Ryan Billard on 2018-12-06.
//

import Foundation

public enum Token: Equatable {
    case identifier(String)
    case intValue(String)
    case floatValue(String)
    case stringValue(String)
    case exclamation
    case dollarSign
    case leftParentheses
    case rightParentheses
    case ellipses
    case colon
    case equalsSign
    case atSign
    case leftSquareBracket
    case rightSquareBracket
    case leftCurlyBrace
    case rightCurlyBrace
    case pipe
}

enum LexerError: Error {
    case unrecognizedInput(String)
}

func tokenize(_ input: String) throws -> [Token] {
    var scalars = Substring(input).unicodeScalars
    var tokens: [Token] = []
    while let token = scalars.readToken() {
        tokens.append(token)
    }
    if !scalars.isEmpty {
        throw LexerError.unrecognizedInput(String(scalars))
    }
    return tokens
}

private extension Substring.UnicodeScalarView {
    mutating func readToken() -> Token? {
        skipIgnoredTokens()
        return readPunctuator()
            ?? readIdentifier()
            ?? readFloatValue()
            ?? readIntValue()
            ?? readStringValue()
    }
    
    mutating func skipIgnoredTokens() {
        let whitespace = CharacterSet.whitespacesAndNewlines
        while let scalar = self.first {
            if whitespace.contains(scalar) {
                self.removeFirst()
            } else if scalar == "," {
                self.removeFirst()
            } else if scalar == "#" {
                self.removeFirst()
                while let next = self.first, CharacterSet.newlines.contains(next) == false {
                    self.removeFirst()
                }
            } else {
                break
            }
        }
    }
    
    mutating func readPunctuator() -> Token? {
        let start = self
        switch self.popFirst() {
        case "!":
            return .exclamation
        case "$":
            return .dollarSign
        case "(":
            return .leftParentheses
        case ")":
            return .rightParentheses
        case ".":
            guard self.popFirst() == ".", self.popFirst() == "." else {
                break
            }
            return .ellipses
        case ":":
            return .colon
        case "=":
            return .equalsSign
        case "@":
            return .atSign
        case "[":
            return .leftSquareBracket
        case "]":
            return .rightSquareBracket
        case "{":
            return .leftCurlyBrace
        case "}":
            return .rightCurlyBrace
        case "|":
            return .pipe
        default:
            break
        }
        self = start
        return nil
    }
    
    mutating func readIdentifier() -> Token? {
        let start = self
        var identifier = ""
		let validFirstCharacters = CharacterSet.letters.union(CharacterSet(charactersIn: "_"))
        if let first = self.popFirst(), validFirstCharacters.contains(first) {
            identifier.append(String(first))
			let validSecondaryCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
            while let next = self.first, validSecondaryCharacters.contains(next) {
                identifier.append(String(self.removeFirst()))
            }
            return .identifier(identifier)
        }
        self = start
        return nil
    }
    
    mutating func readIntValue() -> Token? {
        if let integer = readIntegerPart() {
            return .intValue(integer)
        }
        return nil
    }
    
    mutating func readIntegerPart() -> String? {
        let start = self
        var intValue = ""
        if self.first == "-", let first = self.popFirst() {
            intValue.append(String(first))
        }
        if let zero = readZeroDigit(), readNonZeroDigit() == nil {
            intValue.append(String(zero))
            return intValue
        } else if let nonZero = readNonZeroDigit() {
            intValue.append(String(nonZero))
            while let next = readDigit() {
                intValue.append(String(next))
            }
            return intValue
        }
        self = start
        return nil
    }

    
    mutating func readZeroDigit() -> String? {
        let start = self
        if let first = self.popFirst(), first == "0" {
            return "0"
        }
        self = start
        return nil
    }
    
    mutating func readNonZeroDigit() -> String? {
        let start = self
        if let first = self.popFirst(), CharacterSet.decimalDigits.contains(first), first != "0" {
            return String(first)
        }
        self = start
        return nil
    }
    
    mutating func readDigit() -> String? {
        let start = self
        if let first = self.popFirst(), CharacterSet.decimalDigits.contains(first) {
            return String(first)
        }
        self = start
        return nil
    }
    
    mutating func readFloatValue() -> Token? {
        let start = self
        
        guard let integerPart = readIntegerPart() else {
            self = start
            return nil
        }
        
        var floatValue = integerPart
        let fractionalPart = readFractionalPart()
        let exponentPart = readExponentPart()
        
        guard fractionalPart != nil || exponentPart != nil else {
            self = start
            return nil
        }
        
        if let fractionalPart = fractionalPart {
            floatValue.append(fractionalPart)
        }
        
        if let exponentPart = exponentPart {
            floatValue.append(exponentPart)
        }
        return .floatValue(floatValue)
    }
    
    mutating func readFractionalPart() -> String? {
        let start = self
        
        if let decimal = self.popFirst(), decimal == ".", let firstDigit = self.popFirst(), CharacterSet.decimalDigits.contains(firstDigit) {
            var fractionalPart = ""
            fractionalPart.append(String(decimal))
            fractionalPart.append(String(firstDigit))
            while let next = self.readDigit() {
                fractionalPart.append(next)
            }
            return fractionalPart
        }
        
        self = start
        return nil
    }
    
    mutating func readExponentPart() -> String? {
        let start = self
        let exponentIndicators = CharacterSet.init(charactersIn: "eE")
        guard let exponentIndicator = self.popFirst(), exponentIndicators.contains(exponentIndicator) else {
            self = start
            return nil
        }
        var exponentPart = ""
        exponentPart.append(String(exponentIndicator))
        
        if let sign = readSign() {
            exponentPart.append(sign)
        }
        
        guard let firstDigit = self.readDigit() else {
            self = start
            return nil
        }
        
        exponentPart.append(firstDigit)
        while let next = self.readDigit() {
            exponentPart.append(next)
        }
        
        self = start
        return nil
    }
    
    mutating func readSign() -> String? {
        let start = self
        
        let signs = CharacterSet.init(charactersIn: "+-")
        if let first = self.popFirst(), signs.contains(first) {
            return String(first)
        }
        
        self = start
        return nil
    }
    
    mutating func readStringValue() -> Token? {
        let start = self
        
        if let quote = readSingleQuote() {
            var stringValue = quote
            while let next = self.first, CharacterSet.newlines.contains(next) == false && next != "\"" {
                stringValue.append(String(self.removeFirst()))
            }
            guard let endQuote = readSingleQuote() else {
                self = start
                return nil
            }
            stringValue.append(endQuote)
            return .stringValue(stringValue)
        } else if let quote = readBlockQuote() {
            var stringValue = quote
            
            while let _ = self.first {
                guard String(self.prefix(3)) != "\"\"\"" else {
                    break
                }
                stringValue.append(String(self.removeFirst()))
            }
            
            guard let endQuote = readBlockQuote() else {
                self = start
                return nil
            }
            stringValue.append(endQuote)
            return .stringValue(stringValue)
        }
        
        self = start
        return nil
    }
    
    mutating func readSingleQuote() -> String? {
        let start = self
        
        if let singleQuote = self.popFirst(), singleQuote == "\"", self.first != "\"" {
            return String(singleQuote)
        }
        
        self = start
        return nil
    }
    
    mutating func readBlockQuote() -> String? {
        let start = self
        
        let blockQuote = String(self.dropFirst(3))
        if blockQuote == "\"\"\"" {
            return blockQuote
        }
        
        self = start
        return nil
    }
}
