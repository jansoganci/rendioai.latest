//
//  UIApplication+Extensions.swift
//  RendioAI
//
//  Created by Rendio AI Team
//

import UIKit
import SwiftUI

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(force)
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.endEditing(true)
    }
}

