//
//  MultiRequestProgressProtocol.swift
//  GGXSynthesisSpeech
//
//  Created by 高广校 on 2024/7/19.
//

import Foundation

//响应失败时，可重试多次
protocol ResponseFailRetriedable {
    
    //
    var retried: Dictionary<String, Any> {set get}
    
    func execute()
    
    func resetExecute(msgID: String, error: NSError)
    
}
