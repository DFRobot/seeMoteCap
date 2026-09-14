//
//  LocaleManager.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation
import SwiftUI

/// 应用支持的语言。
private enum AppLanguage: String {
    case english = "en"
    case simplifiedChinese = "zh-Hans"

    /// 对应的 Locale。
    var locale: Locale {
        Locale(identifier: rawValue)
    }
}

/// 解析并暴露系统首选语言对应的 Locale。
///
/// 每次启动时重新解析；若系统首选语言不在支持列表则回退英文。
@MainActor
@Observable
final class LocaleManager {
    /// 当前 Locale，视图层可据此选择本地化字符串。
    let currentLocale: Locale

    init() {
        currentLocale = Self.resolvePreferredLanguage().locale
    }

    /// 根据系统首选语言解析应用支持的语言。
    ///
    /// 仅匹配首选语言；若不支持则回退英文。
    private static func resolvePreferredLanguage() -> AppLanguage {
        guard let preferredIdentifier = Locale.preferredLanguages.first else {
            return .english
        }

        if AppLanguage(rawValue: preferredIdentifier) == .simplifiedChinese {
            return .simplifiedChinese
        }

        let preferredLocale = Locale(identifier: preferredIdentifier)
        if preferredLocale.language.languageCode?.identifier == "zh" {
            return .simplifiedChinese
        }

        return .english
    }
}
