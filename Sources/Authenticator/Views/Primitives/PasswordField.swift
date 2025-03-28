//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// This field encapsulates a native TextField and a SecureField in a single component,
/// providing a button to toggle betweem them, as is common.
/// It also applies Amplify UI's theming
struct PasswordField: View {
    @Environment(\.authenticatorTheme) var theme
    @ObservedObject private var validator: Validator
    @Binding private var text: String
    @FocusState private var focusedField: FieldType?
    @State private var isShowingPassword: Bool = false
    private let label: String?
    private let placeholder: String

    init(_ label: String,
         text: Binding<String>,
         placeholder: String,
         validator: Validator? = nil) {
        self.label = label
        self._text = text
        self.placeholder = placeholder
        self.validator = validator ?? .init(
            using: FieldValidators.none
        )
        self.validator.value = text
    }

    init(_ placeholder: String,
         text: Binding<String>,
         validator: Validator? = nil) {
        self.label = nil
        self._text = text
        self.placeholder = placeholder
        self.validator = validator ?? .init(
            using: FieldValidators.none
        )
        self.validator.value = text
    }

    var body: some View {
        AuthenticatorField(
            label,
            placeholder: placeholder,
            validator: validator,
            isFocused: isFocused
        ) {
            HStack {
                createInput()
                    .disableAutocorrection(true)
                    .onChange(of: text) { text in
                        if validator.state != .normal || !text.isEmpty {
                            validator.validate()
                        }
                    }
                    .onChange(of: focusedField) { focused in
                        if focused == nil {
                            validator.validate()
                        }
                    }
                    .textFieldStyle(.plain)
                    .foregroundColor(foregroundColor)
                    .frame(height: Platform.isMacOS ? 20 : 25)
                    .padding([.top, .bottom, .leading], theme.components.field.padding)
                #if os(iOS)
                    .autocapitalization(.none)
                #endif

                if shouldDisplayShowPasswordButton {
                    ImageButton(showPasswordImage) {
                        isShowingPassword.toggle()
                        focusedField = isShowingPassword ? .plain : .secure
                    }
                    .tintColor(showPasswordButtonColor)
                    .padding([.top, .bottom, .trailing], theme.components.field.padding)
                }
            }
            .animation(.linear(duration: 0.1), value: isShowingPassword)
        }
    }

    @ViewBuilder private func createInput() -> some View {
        if isShowingPassword {
            SwiftUI.TextField("", text: $text, prompt: createPlaceHolderView(label: placeholder))
                .focused($focusedField, equals: .plain)
        } else {
            SwiftUI.SecureField("", text: $text, prompt: createPlaceHolderView(label: placeholder))
                .focused($focusedField, equals: .secure)
        }
    }

    private var isFocused: Bool {
        return focusedField != nil
    }

    private func createPlaceHolderView(label: String) -> SwiftUI.Text {
        let textView = SwiftUI.Text(label)
            .foregroundColor(theme.colors.foreground.disabled.opacity(0.6))
            .font(theme.fonts.body)
        textView.accessibilityHidden(true)
        return textView
    }

    private var foregroundColor: Color {
        switch validator.state {
        case .normal:
            return theme.colors.foreground.secondary
        case .error:
            return theme.colors.foreground.error
        }
    }

    private var showPasswordButtonColor: Color {
        switch validator.state {
        case .normal:
            return isFocused ?
                theme.colors.border.interactive : theme.colors.border.primary
        case .error:
            return theme.colors.border.error
        }
    }

    private var showPasswordImage: ImageButton.Image {
        return isShowingPassword ? .showPassword : .hidePassword
    }

    private var shouldDisplayShowPasswordButton: Bool {
        // Show the show password button when there's text and
        // the field is focused on non-macOS platforms
        return !text.isEmpty && (Platform.isMacOS || focusedField != nil)
    }

    private enum FieldType: Hashable {
        case plain
        case secure
    }
}
