//
//  CozeResponseModel.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/18.
//

import Foundation
import SmartCodable

struct lastError: SmartCodable {
    var code: Int?
    var msg: String?
}

//MARK: - 类型枚举

//role 发送消息的角色。
public enum ChatRoleType: String, SmartCaseDefaultable {
    case user   //代表该条消息内容是用户发送的
    case assistant //代表该条消息内容是 Bot 发送的。
}

public enum ChatContentType: String, SmartCaseDefaultable {
    case text   //文本
    case object_string //多模态内容，即文本和文件的组合、文本和图片的组合
    case card   // 卡片。此枚举值仅在接口响应中出现，不支持作为入参。
}

public enum ReplayMessageRowType:String, SmartCaseDefaultable {
    
    case unknown
    case verbose //冗长的信息，此时`content`为JSON格式
    case query   //用户输入的内容
    case answer //Bot 最终返回给用户的消息内容
    case function_call //Bot 对话过程中决定调用 function_call 的中间结果
    case tool_response //function_call 调用工具后返回的结果
    case follow_up //如果在 Bot 上配置打开了 Auto-Suggestion 开关，则会返回 flow_up 内容
}
