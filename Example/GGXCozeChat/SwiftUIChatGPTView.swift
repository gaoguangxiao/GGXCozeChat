//
//  SwiftUIChatGPTView.swift
//  GXSwiftNetwork_Example
//
//  Created by 高广校 on 2024/6/25.
//  Copyright © 2024 CocoaPods. All rights reserved.
//

import SwiftUI
import GGXCozeChat

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
                    viewModel.stopRobot()
                } label: {
                    Text("结束")
                }
            }

            Section {
                Button {
                    viewModel.creteCon()
                } label: {
                    Text("创建会话")
                }
                
                Button {
//                    viewModel.creteCon()
                } label: {
                    Text("查看会话消息")
                }
            }

            Section {
                Button {
                    viewModel.creteMsg()
                } label: {
                    Text("创建消息")
                }
            }

            Section {
                Button {
                    viewModel.sendC()
                } label: {
                    Text("发起对话-流式")
                }
                
                Button {
                    viewModel.sendC1()
                } label: {
                    Text("发起对话-非流式")
                }
                
                Button {
                    viewModel.sendC2()
                } label: {
                    Text("发起对话-非流式")
                }
                
                Button {
//                    viewModel.sendC2()
                } label: {
                    Text("查看对话详情")
                }
                
                Button {
                    viewModel.sendC2()
                } label: {
                    Text("查看对话消息详情")
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
