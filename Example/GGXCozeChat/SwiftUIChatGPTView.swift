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
    
    @State var noStreamReply: String = ""
    
//    @State var streamReply: String = ""
    
    @StateObject var viewModel = SwiftUIChatGPTViewModel()
    
    var problem = "红楼梦的作者是?"
    
    var body: some View {
        
        Form {
            
            Button {
//                Task{
                     viewModel.initRobot()
//                }
            } label: {
                Text("初始化")
            }

            Button(action: {
                Task {
                    
                    await viewModel.oldVersion()
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
            
            Text("机器人回复：\(viewModel.replyContent)")
        }
        .onAppear(perform: {
            viewModel.initRobot()
        })
    }
}

#Preview {
    SwiftUIChatGPTView()
}
