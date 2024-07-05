//
//  CozeApiService.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import SmartCodable
import PTDebugView

public protocol ChatApiServiceProtocol: NSObjectProtocol {
    
    func onOpen()
    
    func onMessage(content: String, isFinish: Bool)
    
    func onComplete(content: String)
    
    func onCompleteError(msg: String)
}

public class ChatApiService {
    
    public static let share : ChatApiService = {
        return ChatApiService()
    }()
    
    //配置
    var botURL: String?
    
    var botID: String?
    
    var botToken: String?
    
    var conversationId: String?
    
    //
    var chatHistorys: Array<Any>?
    
    public weak var delegate: ChatApiServiceProtocol?

    public init() {
        
    }
    
    public init(url: String,
                 botId: String,
                 token: String) {
        botURL = url
        botID = botId
        botToken = token
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
    
    public func createConversation() {
        
        self.conversationId = String.randomString(length: 10)
        
        chatHistorys = []
    }
    
    // 解析非流式数据
    private func handReplay(problem: String, reply: GPTReplyModel?) -> String {
        if reply?.code == 0 {
            let message = reply?.messages?.filter({ $0.typeNum == .answer }).first
            //                    print("回复：\(message)")
            if let content = message?.content {
                //保存聊天记录
                var problemChat = GPTReplayMessage()
                problemChat.content = problem
                problemChat.role = "user"
                if let dicProblemChat = problemChat.toDictionary() {
                    self.chatHistorys?.append(dicProblemChat)
                    ZKWLog.Log("user: \(dicProblemChat)")
                }
                //本次回答
                var answerChat = GPTReplayMessage()
                answerChat.content = content
                answerChat.role = "assistant"
                answerChat.type = "answer"
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
                         stream: Bool = false,user: String = "user") -> EventSource? {
        //保存本次历史记录
        guard let serverURL = URL(string: botURL) else {
            return nil
        }
        let dataRaw = [
            "query": text,
            "conversation_id": conversationId ?? "",
            "user":user,
            "stream":stream,
            "bot_id":botId,
            "chat_history":chatHistorys ?? []
        ] as [String : Any]
        
        return EventSource(url: serverURL,
                                  method: "POST",
                                  headers: ["Authorization":token,
                                            "Content-Type":"application/json"],
                                  body: dataRaw.toJsonString ?? "")
    }
}

//MARK: - 获取GPT回复
public extension ChatApiService {
    
    enum ChatApiError: Error {
        case ConfigError
    }
    
    func requestRobotReply(text: String,
                           stream: Bool = false,user: String = "user") throws {
        guard let botURL, let botID , let botToken else {
            print("请初始化配置")
            throw ChatApiError.ConfigError
        }
        initEventSource(botURL: botURL, botId: botID, token: botToken, text: text,stream: stream)?.onMessage({ id, event, data in
            let reply = GPTReplyStreamModel.deserialize(from: data)
            guard let message = reply?.message else { return  }
            if message.typeNum == .answer {
                self.delegate?.onMessage(content: message.content ?? "", isFinish: reply?.is_finish ?? false)
            }
        }).onComplete({ code, b, error, data in
            if let data {
                let reply = GPTReplyModel.deserialize(from: data)
                let content = self.handReplay(problem: text, reply: reply)
                self.delegate?.onComplete(content: content)
            }
        }).onOpen {
            self.delegate?.onOpen()
        }.connect()

    }
    
    //初始化是
    func getRobotReply(text: String) async -> String {
        
        guard let botURL, let botID , let botToken else {
            print("请初始化配置")
            return ""
        }
        return await getRobotReply(botURL: botURL, botId: botID, token: botToken, text: text)
    }
    
    func getRobotReply(botURL: String,
                       botId: String,
                       token: String,
                       text: String,
                       stream: Bool = false,user: String = "user") async -> String {
        return await withUnsafeContinuation { continuation in
            initEventSource(botURL: botURL, botId: botId, token: token, text: text, stream:stream)?.onComplete({ code, b, error, data in
                if let data {
                    let reply = GPTReplyModel.deserialize(from: data)
                    let content = self.handReplay(problem: text, reply: reply)
                    continuation.resume(with: .success(content))
                }
            }).connect()
        }
    }
}
