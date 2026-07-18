//
//  SBTextField.swift
//  SlotBook
//
//  Calm text field with label, optional error, and design-system styling.
//

import SwiftUI

struct SBTextField: View {
    let title: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var error: String? = nil
    var autocapitalization: TextInputAutocapitalization = .words

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(SBColor.textSecondary)

            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboardType == .phonePad || keyboardType == .numberPad)
                .font(.system(size: 16, weight: .regular))
                .foregroundStyle(SBColor.textPrimary)
                .padding(.horizontal, Spacing.md)
                .padding(.vertical, Spacing.sm + 2)
                .background(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .fill(SBColor.card)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .stroke(borderColor, lineWidth: error == nil ? 1 : 1.5)
                )
                .animation(.easeInOut(duration: 0.18), value: error)

            if let error {
                Text(error)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(SBColor.destructive)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                    .accessibilityLabel("Error: \(error)")
            }
        }
        .accessibilityElement(children: .contain)
    }

    private var borderColor: Color {
        error == nil ? SBColor.border : SBColor.destructive.opacity(0.7)
    }
}

// MARK: - Previews

#Preview("Text Fields — Light") {
    @Previewable @State var name = ""
    @Previewable @State var phone = ""

    VStack(spacing: Spacing.lg) {
        SBTextField(
            title: "Name",
            placeholder: "Your full name",
            text: $name,
            textContentType: .name
        )
        SBTextField(
            title: "Phone",
            placeholder: "(555) 123-4567",
            text: $phone,
            keyboardType: .phonePad,
            textContentType: .telephoneNumber,
            error: "Phone number is required",
            autocapitalization: .never
        )
    }
    .padding()
    .background(SBColor.background)
}

#Preview("Text Fields — Dark") {
    @Previewable @State var name = "Alex Rivera"

    SBTextField(title: "Name", text: $name)
        .padding()
        .background(SBColor.background)
        .preferredColorScheme(.dark)
}
