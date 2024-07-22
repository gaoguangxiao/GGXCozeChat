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
import GGXRSA

public struct Config {
    static let botName = "机器人"
    public static let botId = "7383946252129927176"
    public static let botToken = "Bearer pat_OeGaGw1cAqmTuZduE5JoJVSJvSxJcBbOEY7DgtQApGFIJe2j2TYveqJspZxlm0wt"
    public static let botURL = "https://api.coze.com/open_api/v2/chat"
    //https://api.coze.com/open_api/v2/chat
    //https://api.coze.com/v3/chat
    
    static let PRIVATE_KEY = """
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC/Vqk+t7IozjYN
gw6Dne54cTOJMo3x+MnaaeUrp7Ci8+43v65cWZqDGn7RHydT2n765vIGkAgjYEkA
6DvMmUC+q+YUNY0zPCsn8/PjoPC1SsSuHcdVekL9CLpJW8c3AybqDMyh/1XGyy3E
/7/65hfsu9DWdwMoAteR//8F4RyVRx/4oHaZEMULL0f6q3WuZ1dS/3N/YISpML7c
k3WBloPURkoXOfceiXy2MshV78EgYvqPUPLn6pg5MJvY5uAoV1SF6IDBds2RdlCy
txz9MmVUSs2ukMMofU8o0C9ykinnQGvyL/UUBXxxrzuCBumPIxYVTZOvandu9GjS
La83DWv7AgMBAAECggEBALdLj6pzU4rfsMxU5kyTuOVMnHAsK+rHyKchltaxN/eC
8owZZjE17Vz2vtIapBQiVk6JewVqaUFqdcUWtGKV1X5TMn/dpTyVwUnu248OmEk0
LSIXiOOL0iyQddTcxQUgUeEZDdeKwWNFNL1pu0Hhtr2kVrV9IVrtDhHhSS8arcUZ
yBaVsIMxiLJ5RmLpZ6lsJTlSUXDG61xGZCowPlyTX4cR50d1+t8f/9LPGQJNLm2m
srghL4YkLf1JcUsxhHauCurP/2hW/XfkyD0rpRwmNC1GGc/dRqi70kIty15NdSku
5lmGjtG4AYzjPtX3PUqw3+F+D002pLGmLxYKhUIexlECgYEA/BMSehI6NF7Rl1MG
tNfwsy0hzGjTZzJCaOUoIBNCdITJ5VGFYRCDYoECsOhNxWNDjhXQQEbDHoTpDxyR
/czxYedtc1S5hS1t1F6xHTPqnAONey00yZ9OzXG+5TFfzmZjDuXeazKKKot6HHPa
yaY0Zo9r+opl9zjAucdEMUsbRvUCgYEAwlF1AKhliNHfMwgFyin3Icfvob3xh5Eq
1E3168bnMhDwFPno7txGBvM1YHf9NFlKUY8fX/7d6jlG4O+AjoVORlpr+PpxTTDI
6lFQ/kdDyfx6lXWtNOOvqBfvUTwxtyH0RfmuH4tA3cxR1ClDfgmcDgYjbH1a33rI
mEOkKteMsS8CgYAC7FWyhLOYF+FmV9gkEL0B1uwlarHI6JRMkxu8A30pzMBqoF9j
mMVtRwG4+3iraVNHOomHtUpd+DybqEEpKE9ES2LBi6H7IWO8qrxzEj8OQBxL6WJL
VEWdrEwCbGgoBJfxfEjwBU4E4EkyO0W2QO8qoU8nQKOeElJp1R29VJmkYQKBgEjh
TETG4+4A6Pm21JUSUEI3PsUm/GOgKrQd2VJo82VvvNvhL2AG9ay9oxNfbXQo2Rrl
1xql+I1UliTfLxRFIyp31282XzBYT8KyZPI5wE8Nhtxvmlrv2n3tHDEXpn3NGlT0
ZD4oeFe3vikYoNuwtvr7imWyTlbrMjkJhZUb6wS5AoGASE2flveir/yENcmhdylC
0eeAgDZ9UIm4SddLHivICw6ToGwqD+furm9Mwno/N47cXV2VStBLTnn8zYtYwuqS
tCKERdYbp5sbJ39Pcun0krETjP8k7nGbabRjqqJlXzf6n7frlrQ0Mk0o3ScwMReG
WiwllaoLb4CXpJLlJsK0+Vo=
-----END PRIVATE KEY-----
"""
    
    static let PUBLIC_KEY = """
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAv1apPreyKM42DYMOg53u
eHEziTKN8fjJ2mnlK6ewovPuN7+uXFmagxp+0R8nU9p++ubyBpAII2BJAOg7zJlA
vqvmFDWNMzwrJ/Pz46DwtUrErh3HVXpC/Qi6SVvHNwMm6gzMof9VxsstxP+/+uYX
7LvQ1ncDKALXkf//BeEclUcf+KB2mRDFCy9H+qt1rmdXUv9zf2CEqTC+3JN1gZaD
1EZKFzn3Hol8tjLIVe/BIGL6j1Dy5+qYOTCb2ObgKFdUheiAwXbNkXZQsrcc/TJl
VErNrpDDKH1PKNAvcpIp50Br8i/1FAV8ca87ggbpjyMWFU2Tr2p3bvRo0i2vNw1r
+wIDAQAB
-----END PUBLIC KEY-----
"""
}
