//
//  PhoneNumberFormatter.swift
//  SlotBook
//
//  Lightweight phone digit extraction + display formatting.
//  Iteration 4 uses a North-American-style mask for calm, familiar input.
//

import Foundation

enum PhoneNumberFormatter {
    /// Strips everything except digits (keeps leading country-code digits if typed).
    nonisolated static func digits(from raw: String) -> String {
        raw.filter(\.isNumber)
    }

    /// Formats digits as the user types: (555) 123-4567
    /// Caps display length at 10 national digits for the mask; extras are kept in digits storage.
    nonisolated static func applyMask(toDigits digits: String) -> String {
        let limited = String(digits.prefix(10))
        var result = ""
        for (index, char) in limited.enumerated() {
            switch index {
            case 0:
                result.append("(")
                result.append(char)
            case 2:
                result.append(char)
                result.append(") ")
            case 5:
                result.append(char)
                result.append("-")
            default:
                result.append(char)
            }
        }
        return result
    }

    /// Display helper for stored digit strings.
    nonisolated static func display(fromDigits digits: String) -> String {
        let masked = applyMask(toDigits: digits)
        return masked.isEmpty ? digits : masked
    }

    /// Valid when we have at least 10 digits.
    nonisolated static func isValid(digits: String) -> Bool {
        digits.count >= 10
    }
}
