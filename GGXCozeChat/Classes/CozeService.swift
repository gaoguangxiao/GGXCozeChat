//
//  CozeService.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/18.
//

import Foundation
import GXSwiftNetwork
import SmartCodable

public struct CozeConfig {
    public static let URL = "https://api.coze.com"
}

//MARK: - coze的封装
class CozeApi: MSBApi {
    
    static let URL = "https://api.coze.com"
    
    ///创建会话
    class CreateConversation: CozeApi {
        init(messages: Array<Any>) {
            super.init(path: "/v1/conversation/create", method: .post,showErrorMsg: false)
        }
    }
    
    /// 创建消息
    class CreateMessage: CozeApi {
        init(ID: String, formData: [String: Any]) {
            super.init(url: "\(CozeApi.URL)/v1/conversation/message/create?conversation_id=\(ID)",
                       method: .post,
                       sampleData: formData.toJsonString ?? "",
                       showErrorMsg: false)
        }
    }
    
    /// 获取消息列表
    
    //发起对话
    class SendConversation: CozeApi {
        init(ID: String, formData: [String: Any]) {
            super.init(url: "\(CozeApi.URL)/v3/chat?conversation_id=\(ID)",
                       method: .post,
                       sampleData: formData.toJsonString ?? "",
                       showErrorMsg: false)
        }
    }
    
    //查看对话详情
    class ChatRetrieve: CozeApi {
        init(ID: String, chatID: String) {
            super.init(url: "\(CozeApi.URL)/v3/chat/retrieve?conversation_id=\(ID)&chat_id=\(chatID)")
        }
    }
    
    //查看对话消息详情
    class ChatMessageDetail: CozeApi {
        init(ID: String, chatID: String) {
            super.init(url: "\(CozeApi.URL)/v3/chat/message/list?conversation_id=\(ID)&chat_id=\(chatID)")
        }
    }
    
}

extension ChatService {
    
    func initCozeEventSource(botURL: String,
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
            "conversation_id": conversationId,
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
    
    func sendConversation(botToken: String, botID: String, requestModel: GPTRequestModel) {
        
        var msgModel = GPTMessageObject()
        msgModel.role = .user
        msgModel.type = .query
        msgModel.content_type = .text
        msgModel.content = requestModel.content
        let chatMsg = [msgModel.toDictionary()]
        let dataRaw = [
            "bot_id": botID,
            "user_id": requestModel.userID,
            "additional_messages":chatMsg,
            "stream": requestModel.stream,
            "auto_save_history":requestModel.autoSaveHistory
        ] as [String : Any]
        
        if requestModel.stream {
            let allUrl = "\(CozeApi.URL)/v3/chat?conversation_id=\(self.conversationId)"
            guard let serverURL = URL(string: allUrl) else {
                return
            }
            
            EventSource(url: serverURL,
                        method: "POST",
                        headers: ["Authorization":botToken,
                                  "Content-Type":"application/json"],
                        body: dataRaw.toJsonString ?? "")
            .onMessage { id, event, data in
                print(data)
            }.connect()
        } else {
            
            let api = CozeApi.SendConversation(ID: "\(self.conversationId)", formData: dataRaw)
            Task {
                let (result,_) = await api.netRequest(SendConversationModel.self)
                guard let conversationChatModel = result?.ydata else {
                    self.delegate?.onCompleteError(msg: "没有此对话-error")
                    return
                }
                //获取对话详情
                guard let chatID = conversationChatModel.id else {
                    return
                }
                beginLoopQueryChat(chatID: chatID)
            }
        }
    }
    
    func resetSendConversation(msgID: String) {
        guard let botID ,let botToken else {
            self.delegate?.onCompleteError(msg: "初始化配置-error")
            return
        }
        
        //获取本次消息ID，请求实例，如果为空为新的请求
        guard var chatModel = requestConversationProgress[msgID] else {
            self.delegate?.onCompleteError(msg: "没有此对话-error")
            return
        }
        
        guard chatModel.failCount < repeatFailCount else {
            requestConversationProgress.removeValue(forKey: currentMsgID)
            self.delegate?.onCompleteError(msg: "重试失败了-error")
            return
        }
        //2、发起请求
        chatModel.failCount =  chatModel.failCount + 1
        //更新
        requestConversationProgress.updateValue(chatModel, forKey: msgID)
        sendConversation(botToken: botToken, botID: botID, requestModel: chatModel)
    }

    func endConversation(reply: ReplyDetailBaseModel) {
        let content = self.handV2Replay(reply: reply)
        self.delegate?.onComplete(content: content)
        
        //移除此key
        requestConversationProgress.removeValue(forKey: currentMsgID)
    }
    
    func endLoopQuery() {
        self.loopChatTimer?.invalidate()
        self.loopChatTimer = nil
    }
    
    //
    func beginLoopQueryChat(chatID: String) {
        
        self.loopChatTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
            
            guard let `self` = self else {
                return
            }
            self.currentTime = self.currentTime + 1.0
            
            guard self.currentTime < self.maxloopTime else {
                self.endLoopQuery()
                self.resetSendConversation(msgID: self.currentMsgID)
                return
            }
 
            //当取得结果之后，也需要停止
            Task {
                if let retrieveResult = await self.queryChat(chatID: chatID) {
                    let retrieve = retrieveResult.ydata
                    //接口失败-重试
                    if (retrieve?.last_error) != nil {
                        self.endLoopQuery()
                        self.resetSendConversation(msgID: self.currentMsgID)
                        return
                    }
                    let status = retrieveResult.ydata?.status
                    guard status != .failed else {
                        self.endLoopQuery()
                        self.resetSendConversation(msgID: self.currentMsgID)
                        return
                    }
                    //当状态为status == completed
                    if status == .completed {
                        self.endLoopQuery()
                        if let detailResult = await self.getChatDetail(chatID: chatID) {
                            self.endConversation(reply: detailResult)
//                            print("获取结果:\(content)")
                        } else {
                            //结果-获取失败
                            self.delegate?.onCompleteError(msg: "重试失败了-error")
                            
                        }
                    } else if status == .in_progress {
                        print("进程中。。。")
//                        status == .requires_action
                    } else {
                        self.endLoopQuery()
                        self.resetSendConversation(msgID: self.currentMsgID)
                    }
                }
            }
        })
        
        guard let loptimer = loopChatTimer else { return }
        RunLoop.current.add(loptimer, forMode: .common)
        sleep(UInt32(1.0))
        RunLoop.current.run()
        
    }
    
}
//MARK: coze的Api方法
extension ChatService {
    
    /// 创建会话
    /*
     //    ["code": 0, "msg": , "data": {
     //        "created_at" = 1721199682;//会话创建的时间。格式为 10 位的 Unixtime 时间戳，单位为秒。
     //        id = 7392494850781888530; //为Conversation ID，即会话的唯一标识。
     //        "meta_data" =     { //创建消息时的附加消息，获取消息时也会返回此附加消息。
     //        };
     //    }]
     //    code:0 代表调用成功。
     //    id：为Conversation ID，即会话的唯一标识。
     **/
    public func cozeCreateConversation(){
        //        let messages = []
        //        let meta_data = []
        let api = CozeApi.CreateConversation(messages: [])
        Task {
            let (m,error) = await api.netRequest(ConversationBaseModel.self)
            guard error == nil else {
                //接口报错
                return
            }
            guard let conversationModel = m?.ydata else {
                //无解析data
                return
            }
            self.conversationId =  conversationModel.id ?? "0000"
        }
    }
    
    //MARK: - 创建消息
    /// 创建文本消息
    /// 创建一条消息，并将其添加到指定的会话中。
    /*
     请求：
     role：user：代表该条消息内容是用户发送的; assistant：代表该条消息内容是 Bot 发送的。
     content_type:
     响应
     当会话不存在
     ["code": 4002, "msg": Invalid conversation (including wrong conversation ID, conversation cannot be found)]
     **/
    public func cozeCreateMessage(text: String) {
        let dataRaw = [
            "role": ChatRoleType.user.rawValue,
            "content": text,
            "content_type":ChatContentType.text.rawValue,
        ]
        let api = CozeApi.CreateMessage(ID: "\(self.conversationId)", formData: dataRaw)
        Task {
            let (result,error) = await api.netRequest(MSBApiModel.self)
            print(result)
        }
    }
    
    // 创建图文消息
    
    // 创建文本和图文消息
    func getMessageList() {
        
    }
    //MARK: - 对话
        
    /// <#Description#>
    /// - Parameter BotID：要进行会话聊天的 Bot ID。
    /// - Parameter userID: 标识当前与 Bot 交互的用户，由使用方在业务系统中自行定义、生成与维护。
    public func sendConversation(userID: String, content: String, stream: Bool = true, autoSaveHistory: Bool = true) {
        guard let botID ,let botToken else {
            self.delegate?.onCompleteError(msg: "初始化配置-error")
            return
        }
        //新建消息ID
        currentMsgID = String.randomString(length: 10)
        
        let reqModel = GPTRequestModel(content: content)
        //保存本次请求内容
        requestConversationProgress[currentMsgID] = reqModel
        //发起请求
        sendConversation(botToken: botToken, botID: botID, requestModel: reqModel)
    }
    
    //非流式响应，定期轮询查询聊天状态
    public func queryChat(chatID: String) async -> RetrieveBaseModel? {
        let api = CozeApi.ChatRetrieve(ID: self.conversationId, chatID: chatID)
        let (result,_) = await api.netRequest(RetrieveBaseModel.self)
        return result
    }
    
    public func getChatDetail(chatID: String) async -> ReplyDetailBaseModel? {
        let api = CozeApi.ChatMessageDetail(ID: self.conversationId, chatID: chatID)
        let (result,_) = await api.netRequest(ReplyDetailBaseModel.self)
        return result
    }
    
}
