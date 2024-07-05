//
//  SwiftUIChatGPTViewModel.swift
//  GGXCozeChat_Example
//
//  Created by 高广校 on 2024/7/5.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import Foundation
import GGXCozeChat
import PTDebugView

public struct Config {
    static let botName = "机器人"
    public static let botId = "7383946252129927176"
    public static let botToken = "Bearer pat_OeGaGw1cAqmTuZduE5JoJVSJvSxJcBbOEY7DgtQApGFIJe2j2TYveqJspZxlm0wt"
    public static let botURL = "https://api.coze.com/open_api/v2/chat"
}

class SwiftUIChatGPTViewModel: NSObject, ObservableObject {
    
    var problem = "我的名字叫什么"
    
    lazy var chatTool: ChatApiService = {
        let chat = ChatApiService(url: Config.botURL, botId: Config.botId, token: Config.botToken)
        chat.delegate = self
        return chat
    }()
    
    @Published var replyContent: String = ""
    
    func initRobot()  {
        
        chatTool.createConversation()
        
    }
    
    @MainActor func oldVersion() async {
        replyContent = ""
        
        replyContent = await chatTool.getRobotReply(text: "我的名字是高广校")
//        replyContent = await chatTool.initConversation(prologue: "我的名字是高广校", url: ChatConfig.botURL,
//                                                       botId: ChatConfig.botId,
//                                                       token: ChatConfig.botToken)
    }
    
    func oldVersionReply() {
        replyContent = ""
        Task {
            replyContent = await chatTool.getRobotReply(text: problem)
        }
        //        chatTool.initConversation(prologue: "我的名字是？")
    }
    
    @MainActor func getRobotReply(stream: Bool) {
        
        replyContent = ""
        //        Task {
        do {
            try chatTool.requestRobotReply(text: problem,stream: stream)
//            try chatTool.requestRobotReply(botURL: ChatConfig.botURL,
//                                           botId: ChatConfig.botId,
//                                           token: ChatConfig.botToken,
//                                           text: problem,
//                                           stream: stream)
        } catch {
            
        }
        //        }
    }
}

extension SwiftUIChatGPTViewModel: ChatApiServiceProtocol {
    func onCompleteError(msg: String) {
        //        replyContent = msg
    }
    
    @MainActor func onMessage(content: String, isFinish: Bool) {
        replyContent = replyContent + content
        ZKTLog("replyContent: \(replyContent)")
    }
    
    @MainActor func onComplete(content: String) {
        replyContent = content
    }
    
    
}
