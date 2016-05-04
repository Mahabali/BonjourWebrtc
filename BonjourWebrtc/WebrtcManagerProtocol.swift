//
//  WebrtcManagerProtocol.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
@objc protocol WebrtcManagerProtocol {

  func offerSDPCreated(sdp:RTCSessionDescription)
  func localStreamAvailable(stream:RTCMediaStream)
  func remoteStreamAvailable(stream:RTCMediaStream)
  func answerSDPCreated(sdp:RTCSessionDescription)
  func iceCandidatesCreated(iceCandidate:RTCICECandidate)
  func dataReceivedInChannel(data:NSData)
}