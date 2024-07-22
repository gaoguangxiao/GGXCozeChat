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
    public var messages: [GPTMessageObject]?
    public var msg: String?
    
    public init() {
        
    }
    
}
// MARK: - Message
public struct GPTMessageObject: SmartCodable {
    //        role 发送消息的角色。
    //        type  标识消息类型，主要用于区分 role=assistant 时 Bot 返回的消息。
    //        content 消息内容。
    //        contentType 消息内容的类型。
    public var content: String?
    
    public var role: ChatRoleType?
    
    public var content_type: ChatContentType?
    
    public var type: ReplayMessageRowType?

    public init() {
        
    }
    
}
