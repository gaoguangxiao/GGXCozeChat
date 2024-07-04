//
//  GPTReplyModel.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/3.
//

import Foundation
import SmartCodable

// MARK: - GPTReplyModel
public struct GPTReplyModel: SmartCodable {
    public var code: Int?
    /// 标识对话发生在哪一次会话中，使用方自行维护此字段。
    public var conversation_id: String?
    public var messages: [GPTReplayMessage]?
    public var msg: String?
    
    public init() {
        
    }
    
}
// MARK: - Message
public struct GPTReplayMessage: SmartCodable {
    //        role 发送消息的角色。
    //        type  标识消息类型，主要用于区分 role=assistant 时 Bot 返回的消息。
    //        content 消息内容。
    //        contentType 消息内容的类型。
    public var content, role, type: String?
    
    public var content_type: String = "text"
    
    public enum ReplayMessageRowType {
        case unknown
        case verbose //
        case answer //Bot 最终返回给用户的消息内容
        case function_call //Bot 对话过程中决定调用 function_call 的中间结果
        case tool_response //function_call 调用工具后返回的结果
        case follow_up //如果在 Bot 上配置打开了 Auto-Suggestion 开关，则会返回 flow_up 内容
    }
    
    public var typeNum: ReplayMessageRowType {
        switch type {
        case "answer": .answer
        case "verbose": .verbose
        case "function_call": .function_call
        case "tool_response":.tool_response
        case "follow_up": .follow_up
        default: .unknown
        }
    }
    
    public init() {
        
    }
    
}
