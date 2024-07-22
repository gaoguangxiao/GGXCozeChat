//
//  CozeApiService.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import PTDebugView
import GGXSwiftExtension

public class ChatService {
    
    public static let share: ChatService = {
        return ChatService()
    }()
    
    //配置
    var botURL: String?
    
    var botID: String?
    
    var botToken: String?
    
    var userName: String = "user"
    
    public var conversationId: String = ""
    
    //
    public var chatHistorys: Array<Any>?
    
    public weak var delegate: ChatServiceProtocol?
    
    //记录每次请求，对每次请求 随机一个数值，保存该次请求的处理流程
    //    var requestConversationProgress: Dictionary<String, GPTRequestModel> = [:]
    var currentMsgID = UUID().uuidString
    
    var loopChatTimer: Timer?
    var currentTime: Float = 0 //当前响应时长
    
    public var maxloopTime: Float = 5//单词对话响应的最长时间，默认5秒
    public var repeatFailCount = 3   //对话失败时，重试次数，默认3次
    public var currentFailCount = 0  //对话失败时，记录重试次数，默认0次
    
    public init() {
        
    }
    
    public init(url: String,
                botId: String,
                token: String,
                user: String = "user") {
        botURL = url
        botID = botId
        botToken = token
        userName = user
    }
    
    public func initConversation(prologue: String,
                                 url: String,
                                 botId: String,
                                 token: String) async -> String {
        
        createConversation()
        
        botURL = url
        botID = botId
        botToken = token
        
        return await self.getRobotReply(botURL: url, botId: botId, token: token, text: prologue)
    }
    
    /// 指定会话ID初始化聊天
    /// - Parameter conversationId: <#conversationId description#>
    /// - Returns: <#description#>
    @discardableResult
    public func createConversation(_ conversationId: String? = nil) -> String {
        self.conversationId = if let conversationId {
            conversationId
        } else {
            String.randomString(length: 10)
        }
        chatHistorys = []
        return self.conversationId
    }
    
    // 解析非流式数据
    private func handReplay(problem: String, reply: GPTReplyModel?) -> String {
        if reply?.code == 0 {
            let message = reply?.messages?.filter({ $0.type == .answer }).first
            //                    print("回复：\(message)")
            if let content = message?.content {
                //保存聊天记录
                var problemChat = GPTMessageObject()
                problemChat.content = problem
                problemChat.role = .user
                if let dicProblemChat = problemChat.toDictionary() {
                    self.chatHistorys?.append(dicProblemChat)
                    ZKWLog.Log("user: \(dicProblemChat)")
                }
                //本次回答
                var answerChat = GPTMessageObject()
                answerChat.content = content
                answerChat.role = .assistant
                answerChat.type = .answer
                if let dicAnswerChat = answerChat.toDictionary() {
                    self.chatHistorys?.append(dicAnswerChat)
                    ZKWLog.Log("回复: \(dicAnswerChat)")
                }
                return content
                //self.chatHistorys
                //                continuation.resume(with: .success(content))
            } else {
                return "fail"
                //                continuation.resume(with: .success("\(ChatConfig.botName) reply is fail"))
            }
        } else {
            return "fail"
        }
    }
    
    func initEventSource(botURL: String,
                         botId: String,
                         token: String,
                         text: String,
                         chatHistory:Array<Any>,
                         stream: Bool = false,
                         user: String) -> EventSource? {
        //保存本次历史记录
        guard let serverURL = URL(string: botURL) else {
            return nil
        }
        let dataRaw = [
            "query": text,
            "conversation_id": conversationId,
            "user":user,
            "stream":stream,
            "bot_id":botId,
            "chat_history": chatHistory
        ] as [String : Any]
        
        return EventSource(url: serverURL,
                           method: "POST",
                           headers: ["Authorization":token,
                                     "Content-Type":"application/json"],
                           body: dataRaw.toJsonString ?? "")
    }
}

//MARK: - 获取GPT回复
public extension ChatService {
    
    
    
    func requestRobotReply(text: String,
                           stream: Bool = false,
                           isHistory: Bool = true,
                           user: String? = nil) throws {
        guard let botURL, let botID , let botToken else {
            print("请初始化配置")
            throw ChatApiError.ConfigError
        }
        let userID = if let user { user } else { userName }
        initEventSource(botURL: botURL, botId: botID, token: botToken, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream: stream,user: userID)?
            .onMessage({ id, event, data in
                guard let reply = GPTReplyStreamModel.deserialize(from: data) else {
                    self.delegate?.onCompleteError(msg: "回复`data`为空")
                    return
                }
                
                self.delegate?.onMessage(stream: reply)
                
                guard reply.event != .done else {
                    self.delegate?.onMessage(content: "", event: GPTSteamEventEnum.done.rawValue)
                    return
                }
                //为空，代表event.done了
                guard let message = reply.message else {
                    self.delegate?.onCompleteError(msg: "回复`data.message`为空")
                    return
                }
                
                guard let content = message.content else {
                    self.delegate?.onCompleteError(msg: "回复`data.message.content`为空")
                    return
                }
                
                if message.type == .answer {
                    self.delegate?.onMessage(content: content,
                                             event: reply.event?.rawValue ?? GPTSteamEventEnum.message.rawValue)
                }
                
            }).onComplete({ code, b, error, data in
                
                if let data {
                    guard let reply = GPTReplyModel.deserialize(from: data) else {
                        self.delegate?.onCompleteError(msg: "回复`data`为空")
                        return
                    }
                    
                    let content = self.handReplay(problem: text, reply: reply)
                    self.delegate?.onComplete(content: content,rawReply: reply)
                }
            }).onOpen {
                self.delegate?.onOpen()
            }.connect()
        
    }
    
    //初始化
    func getRobotReply(text: String) async -> String {
        
        guard let botURL, let botID , let botToken else {
            print("请初始化配置")
            return ""
        }
        return await getRobotReply(botURL: botURL, botId: botID, token: botToken, text: text)
    }
    
    func getReply(text: String, isHistory: Bool = true) async throws -> String {
        guard let botURL, let botID , let botToken else {
            throw ChatApiError.ConfigError
        }
        return try await withUnsafeThrowingContinuation { continuation in
            let userID = userName
            initEventSource(botURL: botURL, botId: botID, token: botToken, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream:false, user: userID)?
                .onComplete({ code, b, error, data in
                    if let error {
                        //通过 continuation.resume(throwing:) 方法抛出异常。
                        continuation.resume(throwing: error)
                    } else {
                        if let data {
                            let reply = GPTReplyModel.deserialize(from: data)
                            let content = self.handReplay(problem: text, reply: reply)
                            //                            continuation.resume(with: .success(content))
                            //通过`continuation.resume(returning:)`返回结果
                            continuation.resume(returning: content)
                        }
                    }
                }).connect()
        }
    }
    
    func getRobotReply(botURL: String,
                       botId: String,
                       token: String,
                       text: String,
                       stream: Bool = false,
                       user: String? = nil,
                       isHistory: Bool = true) async -> String {
        
        return await withUnsafeContinuation { continuation in
            let userID = if let user { user } else { userName }
            initEventSource(botURL: botURL, botId: botId, token: token, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream:stream, user: userID)?.onComplete({ code, b, error, data in
                if let data {
                    let reply = GPTReplyModel.deserialize(from: data)
                    let content = self.handReplay(problem: text, reply: reply)
                    continuation.resume(with: .success(content))
                }
            }).connect()
        }
    }
    
}


