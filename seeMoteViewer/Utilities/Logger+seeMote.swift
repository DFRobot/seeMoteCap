//
//  Logger+seeMote.swift
//  seeMoteViewer
//
//  Copyright © 2026 seeMote. All rights reserved.
//

import Foundation
import os.log

extension Logger {
    /// 使用当前应用 bundle 标识符创建日志记录器。
    init(category: String) {
        self.init(
            subsystem: Bundle.main.bundleIdentifier ?? "com.example.seeMoteViewer",
            category: category
        )
    }
}
