//
//  CozeResponseModel.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/18.
//

import Foundation
import SmartCodable
import GXSwiftNetwork

//每次请求时，随机一个值，用该值为key，记录该请求的成功与否，和请求成功的次数
//请求
struct GPTRequestModel {
    ///
    var failCount: Int = 0

    //
    var userID: String = "user"
    
    var stream: Bool = false
    
    var content: String
    
    var autoSaveHistory: Bool = true
}

//MARK: coze的响应模型

//创建对话响应模型
class ConversationBaseModel: MSBApiModel {
    
    struct ConversationModel: SmartCodable {
        var created_at: Int64?
        var id: String?
        @SmartAny
        var meta_data: Any?
    }
    
    var ydata: ConversationModel? {
        return ConversationModel.deserialize(from: data as? Dictionary<String, Any>)
    }
}

//发起对话响应模型
class SendConversationModel: MSBApiModel {
    
    var ydata: ConversationChatModel? {
        return ConversationChatModel.deserialize(from: data as? Dictionary<String, Any>)
    }
    
    struct ConversationChatModel: SmartCodable {
        var bot_id: String? //要进行会话聊天的 Bot ID。
        var created_at: Int64? //对话创建的时间。格式为 10 位的 Unixtime 时间戳，单位为秒。
        var conversation_id: String?//会话 ID，即会话的唯一标识。
        var id: String? // 对话 ID，即对话的唯一标识。
        var last_error: lastError? //对话运行异常时，此字段中返回详细的错误信息
        @SmartAny
        var meta_data: Any?
    }
}

public class RetrieveBaseModel: MSBApiModel {
    
    var ydata: RetrieveModel? {
        return RetrieveModel.deserialize(from: data as? Dictionary<String, Any>)
    }
    
    struct RetrieveModel: SmartCodable {
        var bot_id: String? //要进行会话聊天的 Bot ID。
        var created_at: Int64? //对话创建的时间。格式为 10 位的 Unixtime 时间戳，单位为秒。
        var completed_at: Int64?
        var conversation_id: String?//会话 ID，即会话的唯一标识。
        
        var last_error: lastError? //对话运行异常时，此字段中返回详细的错误信息
        
        var id: String? // 对话 ID，即对话的唯一标识。
        var status: Status?
        var usage: Usage?
    }
    
    enum Status:String, SmartCaseDefaultable {
        
        case created //会话已创建。
        case in_progress //Bot 正在处理中。
        case completed //Bot 已完成处理，本次会话结束。
        case failed //会话失败。
        case requires_action //会话中断，需要进一步处理。
    }
    
    struct Usage: SmartCodable{
        var input_count: Int32?
        var output_count: Int32?
        var token_count: Int32?
        
    }
}

public class ReplyDetailBaseModel: SmartCodable {
    
    public var code: Int?
    public var msg: String?
    
    public var data: [ReplyDetailModel]?
    
    public struct ReplyDetailModel: SmartCodable {
        var bot_id: String? //要进行会话聊天的 Bot ID。
        var conversation_id: String?//会话 ID，即会话的唯一标识。
        var id: String? // 对话 ID，即对话的唯一标识。
        var content: String?
        var content_type: ChatContentType?
        var chat_id: String?
        var role: ChatRoleType?
        var type: ReplayMessageRowType?
        
        public init () {}
    }
    
    required public init () {}
}


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
