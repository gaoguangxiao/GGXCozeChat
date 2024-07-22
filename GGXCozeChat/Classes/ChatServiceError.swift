//
//  ChatServiceError.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/19.
//

import Foundation

enum ChatApiError: Error {
    case ConfigError
}

enum ChatServiceError: CustomNSError {    
    case aiSyetemError
}
