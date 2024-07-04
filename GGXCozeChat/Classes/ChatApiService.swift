//
//  CozeApiService.swift
//  RSChatRobot
//
//  Created by 高广校 on 2024/7/2.
//

import Foundation
import SmartCodable
import GXSwiftNetwork
import PTDebugView

public struct ChatConfig {
    static let botName = "机器人"
    public static let bot_id = "7383946252129927176"
    public static let botToken = "Bearer pat_OeGaGw1cAqmTuZduE5JoJVSJvSxJcBbOEY7DgtQApGFIJe2j2TYveqJspZxlm0wt"
}

class ChatGPTApi: MSBApi {
    init(paras : Dictionary<String, Any>) {
        super.init(url: "https://api.coze.com/open_api/v2/chat",
                   path: "",
                   method: .post,
                   headers: ["Authorization":ChatConfig.botToken,
                             "Accept":"text/event-stream"],
                   parameters:paras)
//                   sampleData: paras.toJsonString ?? "")
    }
}

public class ChatApiService {
    
    public static let share : ChatApiService = {
        return ChatApiService()
    }()
    
    var conversationId: String?
    
    //
    var chatHistorys: Array<GPTReplayMessage>?
        
    public func initConversation(prologue: String) async -> String {
        
        createConversation()
        
        return await self.getRobotReply(text: prologue)
    }
    
    public func createConversation() {
        
        self.conversationId = String.randomString(length: 10)
        
        chatHistorys = []
    }
}

//MARK: - 获取GPT回复
public extension ChatApiService {
      
    func requestRobotReply(dataRaw: Dictionary<String, Any>) async -> GPTReplyModel? {
        return await withUnsafeContinuation { continuation in
            requestTextReply(dataRaw: dataRaw) { reply in
                continuation.resume(with: .success(reply))
            }
        }
    }
    
    func requestStreamReply(text: String) async -> String {
        return await getRobotReply(text: text, stream: true)
    }
    
    func getRobotReply(text: String, stream: Bool) async -> String {
        //保存本次历史记录
        let dataRaw = [
            "query": text,
            "conversation_id": conversationId ?? "",
            "user":ChatConfig.botName,
            "stream":stream,
            "bot_id":ChatConfig.bot_id,
            "chat_history":chatHistorys?.toJSONString() ?? [:]
        ] as [String : Any]
        
//        ZKWLog.Log("user 询问请求参数 \(dataRaw.toJsonString!)")
        return await withUnsafeContinuation { continuation in
            requestTextReply(dataRaw: dataRaw) { reply in
                if reply?.code == 0 {
                    let message = reply?.messages?.filter({ $0.typeNum == .answer }).first
//                    print("回复：\(message)")
                    if let content = message?.content {
                        
                        //保存聊天记录
                        var problemChat = GPTReplayMessage()
                        problemChat.content = text
                        problemChat.role = "user"
                        self.chatHistorys?.append(problemChat)
                        if let dicProblemChat = problemChat.toJSONString(prettyPrint: true) {
                            ZKWLog.Log("user: \(dicProblemChat)")
                        }
                        //本次回答
                        var answerChat = GPTReplayMessage()
                        answerChat.content = content
                        answerChat.role = "assistant"
                        answerChat.type = "answer"
                        if let dicAnswerChat = answerChat.toJSONString(prettyPrint: true) {
                            self.chatHistorys?.append(problemChat)
                            ZKWLog.Log("\(ChatConfig.botName): \(dicAnswerChat)")
                        }
//                        self.chatHistorys
                        continuation.resume(with: .success(content))
                    } else {
                        continuation.resume(with: .success("\(ChatConfig.botName) reply is fail"))
                    }
                } else {
                    //调用是被
                    continuation.resume(with: .success("\(ChatConfig.botName) reply is fail"))
                }
            }
        }
    }
    
    func getRobotReply(text: String) async -> String {
        return await getRobotReply(text: text, stream: false)
    }
    
    func requestTextReply(dataRaw: Dictionary<String, Any>,closure: @escaping ((GPTReplyModel?) -> ())) {
        let api = ChatGPTApi(paras: dataRaw)
        api.request { (result: GPTReplyModel?) in
            closure(result)
        } onFailure: { _ in
            closure(nil)
        }
    }
    
    func requestStream(dataRaw: Dictionary<String, Any>,closure: @escaping ((GPTReplyModel?) -> ())) {
        let api = ChatGPTApi(paras: dataRaw)
        api.requestStream { (result: GPTReplyModel?) in
            closure(result)
        } onFailure: { _ in
            closure(nil)
        }
    }
}
