//
//  SwiftUIChatGPTView.swift
//  GXSwiftNetwork_Example
//
//  Created by 高广校 on 2024/6/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import GGXCozeChat
import PTDebugView
import GGXRSA

class SwiftUIChatGPTViewModel: NSObject, ObservableObject {
    
    var problem = "我的名字叫什么"
    
    var chatTool: ChatService?
    
    @Published var replyContent: String = ""
    
    func loadEncryptToken() -> String? {
        //对token加密
        guard let privatrFile = Bundle.main.path(forResource: "private_key.p12", ofType: nil) else{
            fatalError("private_key.p12 no exist")
        }
        
        print("原始: \(Config.botToken)")
        let enco = GGXRSA.encryptString(Config.botToken, privateKeyPath: privatrFile)
        //        let enco = MZRSA.encryptString(Config.botToken, privateKey: Config.PRIVATE_KEY)
        guard let enco  else {
            print("没有加密成功")
            return nil
        }
        print("加密:\(enco)")
        return enco
    }
    
    // 公钥加密
    func loadPublicEncryptToken() -> String? {
        //对token加密
        guard let publicRsaFile = Bundle.main.path(forResource: "public_key", ofType: "der") else{
            fatalError("public_key.der no exist")
        }
        
        print("原始: \(Config.botToken)")
        let enco = GGXRSA.encryptString(Config.botToken, publicKeyPath: publicRsaFile)
        //        let enco = MZRSA.encryptString(Config.botToken, privateKey: Config.PRIVATE_KEY)
        guard let enco  else {
            print("没有加密成功")
            return nil
        }
        print("加密:\(enco)")
        return enco
    }
    
    func decryptPrivateStringToken(str: String) -> String? {
        guard let privatrFile = Bundle.main.path(forResource: "private_key.p12", ofType: nil) else{
            fatalError("private_key.p12 no exist")
        }
        let rawToken = GGXRSA.decryptString(str, privateKeyPath: privatrFile)
        guard let rawToken else {
            print("解密失败")
            return nil
        }
        print("解密: \(rawToken)")
        return rawToken
    }
    
    func loadEncryptToken1() -> String {
        return "DnoeirHd4Xb6XYMYtf/Kajzt+c7YbxTb+SsI6CcGtkIN43Iz0DTktr+N76jfI6zVSiWtNG5kEazoYbykIjfCtxC/SQPtLN5UP1snPngTXVMB2mx8M7ZT1bjVok+a/iX1QQsf/7f48E00h+urRYudaXZ8Qoo4PEB5ckxnrBsJUxL0OSClsYfafHEUPxzDYtSzOjDX/1547kBCk08OImrKPnlbk6byKFcxjpKOkXqI5kEvIVDrQm9XK19a4Uxnu/zX5r/jaPguClJxBFngs2GOLo/BpCZVwBTX/+Vv+MOlOU6z0QwmNMm+FME3QSGrcDaJNquGyIdWknGc4NDE/MEDMg=="
    }
    
    func initRobot()  {
        var enco: String?
        ///加密
        //        if let encobase = loadPublicEncryptToken()?.encodBase64() {
        ////            let encobase = encodBase64(str: enco1)
        //            print("加密转码：\(encobase)")
        //            //解码
        //            if let originalData = encobase.decodeBase64() {
        //                print("解码base64:\(originalData)")
        //                let rawToken = decryptPrivateStringToken(str: originalData)
        //                guard let rawToken  else {
        //                    print("rawToken获取失败")
        //                    return
        //                }
        //            }
        //        }
        
        
        //其他地方生成编码base64的∫
        if let encbase64 = loadEncryptToken1().encodBase64() {
            print("解码base64-local:\(encbase64)")
            enco = encbase64
        }
        
        //解码base64
        guard let enco else {
            print("解码base64-失败")
            return
        }
        
        //解密
        let rawToken = decryptPrivateStringToken(str: "nezKlPItbT6vKN1sb0BAkancHAFfRLZAMhr3J2+Bo2PAUcZcFjH6MuIsvyP+V7D4yRc88aKepR4jni/sYsji0FLL9zyN2amNwiBgBiakIXHhq27kkMmkl7t+pX5Sp+nH1xKJvhn2DAvdHAY4w26Fdwh3Gcms/ZH74OGe8ctmCjmLfxbNMwl7JmHNEWk2O0hE5UnftWQkYYLpxdPfsR2y6MiHaAhP/+avd6v+oBzy4aNpr7pF83tl032GMI3GkulSy+RoqPnNjzEU3QCdPW3vzK6WfCzWyI3jPPCrzyWLawpePUQgc9QhCxOZEhIqJEP7n0OZOapUxRFkoSDsEdd3HA==")
        guard let rawToken  else {
            print("rawToken获取失败")
            return
        }
        
        let rawBotID =  decryptPrivateStringToken(str: "S9cXhOFINF92vH9WnYjWTkPmlf9OTr5t12/82Bj1guNf/Xa4lHNt4kR0PA0osYkbORZmhIYw3RzOQM2tCfQwnqD3afF0flmDkKIS3/ACtessFkhvqBQzMmxcRjBnWeKlosBxS2UP/cr6VqQ8aQ8H6hGdWRjNo2SpKIlRfC+2vZZaL/lQe6jG7raItxbhlH2y9hOm/GPQj4h2djTTlV1+bsz6xS5JCqbpitQLuwxniIOaBHAaBD3Ga0C9U7GchOH/fvRXVg2v4RRQNYFl6iyr+8L8ZPRILVMHDfPx+KoCKijqXOk6oSWbMQhJGMIrXEj4qISxPOTuuJlM8h8XNAckPg==")
        guard let rawBotID  else {
            print("rawBotID获取失败")
            return
        }
        initRobot(token: Config.botErrorToken, botId: rawBotID)
    }
    
    /*
     Error Domain=cozeChat Code=702242003 "(null)" UserInfo={msg=Do not have the corresponding permission, please refer to the corresponding API Token document and submit feedback if there is any problem}
     */
    func initErrorRobotWithToken() {
        initRobot(token: Config.botErrorToken, botId: Config.botId)
    }
    
    /*
     Error Domain=cozeChat Code=702242002 "(null)" UserInfo={msg=The Bot is not currently published to the corresponding platform
     **/
    func initErrorRobotWithBotID() {
        initRobot(token: Config.botToken, botId: Config.botErrorId)
    }
    
    func initRobot(token: String, botId: String) {
        chatTool = ChatService(url: Config.botURL, botId: botId, token: token, user: nil)
        chatTool?.delegate = self
        chatTool?.createConversation()
    }
    
    func stopRobot() {
        chatTool = nil
    }
    
    @MainActor func oldVersionReply() {
        Task {
            if let content = try? await chatTool?.getRobotReply(text: problem) {
                replyContent = content ?? "error----"
            }
        }
    }
    
    @MainActor func getRobotReply(stream: Bool) {
        
        guard let chatTool else {
            print("初始化Ai机器人")
            return
        }
        
        replyContent = ""
        Task {
            do {
                replyContent = try await chatTool.getReply(text: self.problem)
            } catch let e {
                
                print(e)
            }
        }
    }
    
    @MainActor func robotReplyRetry(stream: Bool) {
        guard let chatTool else {
            print("初始化Ai机器人")
            return
        }
        
        //调用多次
        print("可调用多次")
        replyContent = ""
        Task {
            print("开始调用多次")
            let result = await Task.retrying {
                try await chatTool.getReply(text: self.problem)
            }.result
            
            switch result {
            case .success(let success):replyContent = success
            case .failure(let failure):
                if let urlError = failure as? URLError {
                    print("\(urlError.errorCode)")
                }
                print("\(failure)")
                replyContent = failure.localizedDescription
            }
        }
//        }
        print("调用`Task`之后")
    }
    
    @MainActor func retryCondition() {
        guard let chatTool else {
            print("初始化Ai机器人")
            return
        }
        
        //调用多次
        print("可调用多次")
        replyContent = ""
        Task {
            let result = await Task.retrying { error in
                if let e = error as? ChatServiceError {
                    return switch e {
                    case .configError:true
                    default: false
                    }
                }
                return true
            } operation: {
                try await chatTool.getReply(text: self.problem)
            }.result

            switch result {
            case .success(let success):replyContent = success
            case .failure(let failure):
                if let urlError = failure as? URLError {
                    print("\(urlError.errorCode)")
                }
                print("\(failure)")
                replyContent = failure.localizedDescription
            }
        }
//        }
        print("调用`Task`之后")
    }
}

extension SwiftUIChatGPTViewModel: ChatServiceProtocol {
    func onCompleteError(error: any Error) {
        
        print("er:\(error.localizedDescription)")
    }
    
    func onMessage(content: String, event: String) {
        
    }
    
    func onOpen() {
        
    }
    
    func onCompleteError(msg: String) {
        //        replyContent = msg
    }
    
    @MainActor func onMessage(content: String, isFinish: Bool, event: String) {
        replyContent = replyContent + content
        ZKTLog("replyContent: \(replyContent)")
    }
    
    func onMessage(stream: GPTReplyStreamModel) {
        
        //知识回忆
        //第一条消息
        ZKLog(stream.message?.content)
        
        ZKTLog("stream: \(String(describing: stream.toJSONString() ?? ""))")
    }
    
    @MainActor func onComplete(rawReply: GPTReplyModel) {
        
        if let ms = rawReply.messages {
            for m in ms {
                if let content = m.content {
                    //                   let verbose = GPTVerboseContent.deserialize(from: content)
                    //                    replyContent = replyContent + verbose?.data
                }
            }
        }
        
        //        replyContent = rawReply.messages
        ZKLog(rawReply)
    }
    
    @MainActor func onComplete(content: String) {
        replyContent = content
    }
    
    //获取问答结果，原始数据，不需要SDK的分析
    
}

@available(iOS 14.0, *)
struct SwiftUIChatGPTView: View {
    
    @State var noStreamReply: String = ""
    
    //    @State var streamReply: String = ""
    
    @StateObject var viewModel = SwiftUIChatGPTViewModel()
    
    var problem = "红楼梦的作者是?"
    
    var body: some View {
        
        Form {
            
            Section {
                Button {
                    viewModel.initRobot()
                } label: {
                    Text("初始化")
                }
                
                Button {
                    viewModel.initErrorRobotWithToken()
                } label: {
                    Text("初始化错误的Token")
                }
                
                Button {
                    viewModel.initErrorRobotWithBotID()
                } label: {
                    Text("初始化错误的BotID")
                }
                
                Button {
                    viewModel.stopRobot()
                } label: {
                    Text("结束")
                }
            }
            
            Button(action: {
                Task {
                    viewModel.oldVersionReply()
                }
            }, label: {
                Text("旧版问答:")
            })
            
            Button(action: {
                viewModel.getRobotReply(stream: true)
            }, label: {
                Text("流式问答:")
            })
            
            Button(action: {
                viewModel.getRobotReply(stream: false)
            }, label: {
                Text("非流式问答:")
            })
            
            Button(action: {
                viewModel.robotReplyRetry(stream: false)
            }, label: {
                Text("非流式问答允许，失败后多次请求")
            })
            
            Button(action: {
                viewModel.retryCondition()
            }, label: {
                Text("非流式问答允许，失败多次请求-重试有条件")
            })
            
            Text("机器人回复：\(viewModel.replyContent)")
        }
        .onAppear(perform: {
            viewModel.initRobot()
        })
    }
}

@available(iOS 14.0, *)
#Preview {
    SwiftUIChatGPTView()
}
