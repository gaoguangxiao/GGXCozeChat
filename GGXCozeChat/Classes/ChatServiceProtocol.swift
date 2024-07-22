//
//  ChatServiceProtocol.swift
//  GGXCozeChat
//
//  Created by 高广校 on 2024/7/16.
//

import Foundation


public protocol ChatServiceProtocol: NSObjectProtocol {
    
    // 开始接受数据
    func onOpen()
    
    /// 流式返回响应结果
//    func onMessage(content: String, isFinish: Bool, event: String)
    /// 流式返回响应结果
    func onMessage(content: String, event: String)
    
    /// 流式返回响应结果，原始解析模型
    func onMessage(stream: GPTReplyStreamModel)
    
    /// 一次性返回结果
    func onComplete(content: String)
    
    /// 一次性返回回复和原始结果
    func onComplete(content: String, rawReply: GPTReplyModel)
    
    /// 有异常抛出
    func onCompleteError(msg: String)
    
    ///
    func onCompleteError(msg: String, event: String ,error: NSError)
}

extension ChatServiceProtocol {
    //默认实现协议
    public func onMessage(stream: GPTReplyStreamModel) {
        
    }
    
    public func onComplete(content: String) {
        
    }
    
    public func onComplete(content: String, rawReply: GPTReplyModel) {
        
    }
}
