//
//  WebrtcManager.swift
//  ConnectedColors
//
//  Created by Mahabali on 4/8/16.
//  Copyright © 2016 Ralf Ebert. All rights reserved.
//

import Foundation
import AVFoundation
class WebrtcManager: NSObject,RTCPeerConnectionDelegate,RTCSessionDescriptionDelegate {
  var peerConnection:RTCPeerConnection?
  var peerConnectionFactory:RTCPeerConnectionFactory?
  var videoCapturer:RTCVideoCapturer?
  var localAudioTrack:RTCAudioTrack?
  var localVideoTrack:RTCVideoTrack?
  var localSDP:RTCSessionDescription?
  var remoteSDP:RTCSessionDescription?
  var delegate:WebrtcManagerProtocol?
  var localStream:RTCMediaStream?
  var unusedICECandidates:[RTCICECandidate] = []
  var initiator = false
  
  override init() {
    super.init()
    peerConnectionFactory = RTCPeerConnectionFactory.init()
    let iceServer = RTCICEServer.init(URI: NSURL(string: "stun:stun.l.google.com:19302"), username: "", password: "")
    peerConnection = peerConnectionFactory?.peerConnectionWithICEServers([iceServer], constraints: RTCMediaConstraints(mandatoryConstraints: nil,optionalConstraints: [RTCPair.init(key: "DtlsSrtpKeyAgreement", value: "true")]), delegate: self)
  }
  
  func addLocalMediaStream(){
    var cameraID: String?
    for captureDevice in AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo) {
      // Support Front cam alone, as it's suitable for video conferencing
      if captureDevice.position == AVCaptureDevicePosition.Front {
        cameraID = captureDevice.localizedName
      }
    }
    let videoCapturer = RTCVideoCapturer(deviceName: cameraID)
    self.videoCapturer = videoCapturer
    let videoSource = peerConnectionFactory?.videoSourceWithCapturer(videoCapturer, constraints: nil)
    let videoTrack = peerConnectionFactory?.videoTrackWithID("ARDAMSv0", source: videoSource)
    localStream = peerConnectionFactory?.mediaStreamWithLabel("ARDAMS")
    let audioTrack = peerConnectionFactory?.audioTrackWithID("ARDAMSa0")
    localAudioTrack = audioTrack
    localVideoTrack = videoTrack
    localStream?.addVideoTrack(videoTrack)
   localStream?.addAudioTrack(audioTrack)
    dispatch_async(dispatch_get_main_queue()) { 
    
    }
    self.peerConnection?.addStream(localStream!)
    self.delegate?.localStreamAvailable(localStream!)
  }
  
  func startWebrtcConnection(){
    if (initiator){
      self.createOffer()
    }
    else{
      self.waitForAnswer()
    }
  }
  
  func createOffer(){
    addLocalMediaStream()
    let offerContratints = createConstraints()
    self.peerConnection?.createOfferWithDelegate(self, constraints: offerContratints)
  }
  
  func createConstraints() -> RTCMediaConstraints{
    let pairOfferToReceiveAudio = RTCPair(key: "OfferToReceiveAudio", value: "true")
    let pairOfferToReceiveVideo = RTCPair(key: "OfferToReceiveVideo", value: "true")
    let pairDtlsSrtpKeyAgreement = RTCPair(key: "DtlsSrtpKeyAgreement", value: "true")
    let peerConnectionConstraints = RTCMediaConstraints(mandatoryConstraints: [pairOfferToReceiveVideo,pairOfferToReceiveAudio], optionalConstraints: [pairDtlsSrtpKeyAgreement])
    return peerConnectionConstraints
  }
  
  func waitForAnswer(){
    // Do nothing. Maybe initialize something here. Nothing for this example
  }
  
  func createAnswer(){
    dispatch_async(dispatch_get_main_queue()) { 
      let remoteSDP = self.remoteSDP!
      self.addLocalMediaStream()
      self.peerConnection!.setRemoteDescriptionWithDelegate(self, sessionDescription: remoteSDP)
    }
      }
  
  func setAnswerSDP(){
    dispatch_async(dispatch_get_main_queue()) {
      self.peerConnection?.setRemoteDescriptionWithDelegate(self, sessionDescription: self.remoteSDP)
      self.addUnusedIceCandidates()
    }
    
  }
  
  func setICECandidates(iceCandidate:RTCICECandidate){
    dispatch_async(dispatch_get_main_queue()) {
      self.peerConnection?.addICECandidate(iceCandidate)
    }
  }
  
  func addUnusedIceCandidates(){
    for (iceCandidate) in self.unusedICECandidates{
      print("added unused ices")
      self.peerConnection?.addICECandidate(iceCandidate)
    }
    self.unusedICECandidates = []
  }
  func peerConnection(peerConnection: RTCPeerConnection!, addedStream stream: RTCMediaStream!) {
    print("Log: PEER CONNECTION:- Stream Added")
    self.delegate?.remoteStreamAvailable(stream)
  }
  
  func peerConnection(peerConnection: RTCPeerConnection!, gotICECandidate candidate: RTCICECandidate!) {
    print("PEER CONNECTION:- Got ICE Candidate - \(candidate)")
    self.delegate?.iceCandidatesCreated(candidate)
 
  }
  func peerConnection(peerConnection: RTCPeerConnection!, iceConnectionChanged newState: RTCICEConnectionState)
  {
    print("PEER CONNECTION:- ICE Connection Changed \(newState)")
  }
  func peerConnection(peerConnection: RTCPeerConnection!, iceGatheringChanged newState: RTCICEGatheringState) {
    print("PEER CONNECTION:- ICE Gathering Changed - \(newState)")
  
  }
  func peerConnection(peerConnection: RTCPeerConnection!, removedStream stream: RTCMediaStream!) {
    print("PEER CONNECTION:- Stream Removed")
  }
  func peerConnection(peerConnection: RTCPeerConnection!, signalingStateChanged stateChanged: RTCSignalingState){
    print("PEER CONNECTION:- Signaling State Changed \(stateChanged)")
  }
  func peerConnectionOnRenegotiationNeeded(peerConnection: RTCPeerConnection!) {
    print("PEER CONNECTION:- Renegotiation Needed")
  }
  
  func peerConnection(peerConnection:RTCPeerConnection!, didOpenDataChannel dataChannel:RTCDataChannel) {
    print("PEER CONNECTION:- Open Data Channel")
  }

  func peerConnection(peerConnection: RTCPeerConnection!, didCreateSessionDescription sdp: RTCSessionDescription!, error: NSError!) {
    if let er = error {
      print(er.localizedDescription)
    }
    if(sdp == nil) {
      print("Problem creating SDP - \(sdp)")
    } else {
      
      print("SDP created -: \(sdp)")
    }
    self.localSDP = sdp
    self.peerConnection?.setLocalDescriptionWithDelegate(self, sessionDescription: sdp)
    if (initiator){
      self.delegate?.offerSDPCreated(sdp)
    }
    else{
      self.delegate?.answerSDPCreated(sdp)
    }
  }
  
  func peerConnection(peerConnection: RTCPeerConnection!, didSetSessionDescriptionWithError error: NSError!) {
    if error != nil{
    print("sdp error \(error.localizedDescription) \(error)")
    }
    else{
      print("SDP set success")
      if initiator == false && self.localSDP == nil{
      
        let answerConstraints = self.createConstraints()
        self.peerConnection!.createAnswerWithDelegate(self, constraints: answerConstraints)
      }
    }
  }
  
  // Called when the data channel state has changed.
  func channelDidChangeState(channel:RTCDataChannel){

  }
  
  func channel(channel: RTCDataChannel!, didReceiveMessageWithBuffer buffer: RTCDataBuffer!) {
   self.delegate?.dataReceivedInChannel(buffer.data)
  }
  func disconnect(){
    self.peerConnection?.close()
  }
}
