//
//  SwiftUIChatGPTView.swift
//  GXSwiftNetwork_Example
//
//  Created by 高广校 on 2024/6/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import GGXCozeChat

struct SwiftUIChatGPTView: View {
    
    @State var reply: String = ""
    
    var problem = "红楼梦的作者是?"
    
    var body: some View {
        
        Button(action: {
            
//            let dataRaw = [
//                "query":"今红楼梦的作者",
//                "conversation_id":"10",
//                "user":"纳威",
//                "stream":1,
//                "bot_id":ChatConfig.bot_id
//            ]
            
            reply = ""
            Task {
//                reply =  await ChatApiService.share.getRobotReply(text: problem)
                
                reply = await ChatApiService.share.requestStreamReply(text: problem)
            }
            
        }, label: {
            Text("问答:")
        })
        
        Text("机器人回复：\(reply)")
    }
}

#Preview {
    SwiftUIChatGPTView()
}
