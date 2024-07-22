//
//  GPTReplyStreamModel.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/5.
//

import Foundation
import SmartCodable

/// 流式响应结果
/*
 {
     "event": "message",
     "message":
     {
         "role": "assistant",
         "type": "answer",
         "content": "红",
         "content_type": "text"
     },
     "is_finish": false,
     "index": 1,
     "conversation_id": "9kgU9upqxS",
     "seq_id": 1
 }
 **/

typealias GPTSteamEventEnum = GPTReplyStreamModel.eventEnum

public struct GPTReplyStreamModel: SmartCodable {
    
    public enum eventEnum: String, SmartCaseDefaultable {
        case message
        case done
    }
    
    public var event: eventEnum?
    
    public var message: GPTMessageObject?
    
    public var is_finish: Bool = false
    
    public var index: Int?
    
    public var conversation_id: String?
    
    public var seq_id: Int?

    public init (){}
}
