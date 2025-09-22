//
//  OnboardingButton.swift
//  Nova
//
//  Created by Maxime Dondon on 07/09/2025.
//

import SwiftUI

struct OnboardingButton: View {
    var title: String
    var isPrimary: Bool = false
    var disabled: Bool = false
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(isPrimary ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 15)
                .background(isPrimary ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.08), radius: 1, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.5 : 1.0)
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(isPrimary ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.3) , lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.01), radius: 2, x: 0, y: 0.5)
    }
}

#Preview {
    OnboardingButton(title: "Title", isPrimary: false, disabled: false, action: {})
}
