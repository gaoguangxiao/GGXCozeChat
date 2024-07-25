//
//  CozeApiService.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
//import PTDebugView
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
                user: String?) {
        botURL = url
        botID = botId
        botToken = token
        self.userName = if let user { user } else { "user" }
    }
    
    public func initConversation(prologue: String,
                                 url: String,
                                 botId: String,
                                 token: String) async -> String {
        
        createConversation()
        
        botURL = url
        botID = botId
        botToken = token
        
        do {
            return try await self.getRobotReply(botURL: url, botId: botId, token: token, text: prologue)
        } catch  {
            return "error----"
        }
//        return try? await self.getRobotReply(botURL: url, botId: botId, token: token, text: prologue)
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
    
    /// 清理之前聊天记录
    public func clearHistory() {
        chatHistorys = []
    }
    
    // 解析非流式数据
    private func handReplay(problem: String, reply: GPTReplyModel?) throws -> String {
        
        guard let reply else {
            throw ChatServiceError.dataStructError
        }
        
        guard reply.code == 0 else {
            let serviceError = NSError(domain: "cozeChat", code: reply.code,userInfo: ["msg":reply.msg ?? "coze并没有给出具体错误msg"])
            throw serviceError
        }
        
        let message = reply.messages?.filter({ $0.type == .answer }).first
        
        //在`messages`，找到了回复，但是`content`为空
        guard let content = message?.content else {
            throw ChatServiceError.contentEmpty
        }
        
        //保存聊天记录
        var problemChat = GPTMessageObject()
        problemChat.content = problem
        problemChat.role = .user
        if let dicProblemChat = problemChat.toDictionary() {
            self.chatHistorys?.append(dicProblemChat)
//            ZKWLog.Log("user: \(dicProblemChat)")
        }
        //本次回答
        var answerChat = GPTMessageObject()
        answerChat.content = content
        answerChat.role = .assistant
        answerChat.type = .answer
        if let dicAnswerChat = answerChat.toDictionary() {
            self.chatHistorys?.append(dicAnswerChat)
//            ZKWLog.Log("回复: \(dicAnswerChat)")
        }
        return content
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
            throw ChatServiceError.configError
        }
        let userID = if let user { user } else { userName }
        initEventSource(botURL: botURL, botId: botID, token: botToken, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream: stream,user: userID)?
            .onMessage({ id, event, data in
                guard let reply = GPTReplyStreamModel.deserialize(from: data) else {
                    self.delegate?.onCompleteError(error: ChatServiceError.dataStructError)
                    return
                }
                
                self.delegate?.onMessage(stream: reply)
                
                guard reply.event != .done else {
                    self.delegate?.onMessage(content: "", event: GPTSteamEventEnum.done.rawValue)
                    return
                }
                //为空，代表event.done了
                guard let message = reply.message else {
                    self.delegate?.onCompleteError(error: ChatServiceError.contentEmpty)
                    return
                }
                
                guard let content = message.content else {
                    self.delegate?.onCompleteError(error: ChatServiceError.contentEmpty)
                    return
                }
                
                if message.type == .answer {
                    self.delegate?.onMessage(content: content,
                                             event: reply.event?.rawValue ?? GPTSteamEventEnum.message.rawValue)
                }
                
            }).onComplete({ code, b, error, data in
                
                if let data {
                    guard let reply = GPTReplyModel.deserialize(from: data) else {
                        self.delegate?.onCompleteError(error: ChatServiceError.dataStructError)
                        return
                    }
                    do {
                        let content = try self.handReplay(problem: text, reply: reply)
                        self.delegate?.onComplete(content: content,rawReply: reply)
                    } catch {
                        self.delegate?.onCompleteError(error: error)
                    }
                }
            }).onOpen {
                self.delegate?.onOpen()
            }.connect()
        
    }
    
    func getReply(text: String, isHistory: Bool = true) async throws -> String {
        guard let botURL, let botID , let botToken else {
            throw ChatServiceError.configError
        }
        return try await withUnsafeThrowingContinuation { continuation in
            let userID = userName
            initEventSource(botURL: botURL, botId: botID, token: botToken, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream:false, user: userID)?
                .onComplete({ code, b, error, data in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        if let data {
                            let reply = GPTReplyModel.deserialize(from: data)
                            do {
                                let content = try self.handReplay(problem: text, reply: reply)
                                continuation.resume(returning: content)
                            } catch  {
                                continuation.resume(throwing: error)
                            }
                        }
                    }
                }).connect()
        }
    }
    
    //初始化
    func getRobotReply(text: String) async throws -> String {
        
        guard let botURL, let botID , let botToken else {
            print("请初始化配置")
            return ""
        }
        return try await getRobotReply(botURL: botURL, botId: botID, token: botToken, text: text)
    }
    
    func getRobotReply(botURL: String,
                       botId: String,
                       token: String,
                       text: String,
                       stream: Bool = false,
                       user: String? = nil,
                       isHistory: Bool = true) async throws -> String {
        return try await withUnsafeThrowingContinuation { continuation in
            let userID = if let user { user } else { userName }
            initEventSource(botURL: botURL, botId: botId, token: token, text: text,chatHistory:isHistory ? (chatHistorys ?? []) : [], stream:stream, user: userID)?.onComplete({ code, b, error, data in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    if let data {
                        let reply = GPTReplyModel.deserialize(from: data)
                        do {
                            let content = try self.handReplay(problem: text, reply: reply)
                            continuation.resume(returning: content)
                        } catch  {
                            continuation.resume(throwing: error)
                        }
                    }
                }
            }).connect()
        }
    }
    
}


