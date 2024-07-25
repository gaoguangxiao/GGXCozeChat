//
//  ChatServiceError.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/19.
//

import Foundation

public enum ChatServiceError: LocalizedError {
    case configError
    case dataStructError
    case contentEmpty

    public var errorDescription: String? {
        switch self {
        case .dataStructError:
            "无法解析响应数据"
        case .contentEmpty:
            "messages中content为空"
        case .configError:
            "初始化token、botid为空"
        }
    }
}
