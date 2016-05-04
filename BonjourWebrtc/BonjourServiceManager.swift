//
//  BonjourServiceManager.swift
//  ConnectedColors
//
//  Created by Ralf Ebert on 28/04/15.
//  Copyright (c) 2015 Ralf Ebert. All rights reserved.
//

import Foundation
import MultipeerConnectivity

protocol BonjourServiceManagerProtocol {
  func connectedDevicesChanged(manager : BonjourServiceManager, connectedDevices: [String])
  func receivedData(manager : BonjourServiceManager, peerID : String, responseString: String)
}

class BonjourServiceManager : NSObject {
  static let sharedBonjourServiceManager = BonjourServiceManager()
  private let serviceType = "webrtc-service"
  private let myPeerId = MCPeerID(displayName: UIDevice.currentDevice().name)
  private let serviceAdvertiser : MCNearbyServiceAdvertiser
  private let serviceBrowser : MCNearbyServiceBrowser
  var selectedPeer:MCPeerID?
  var delegate : BonjourServiceManagerProtocol?
  
  override init() {
    self.serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerId, discoveryInfo: nil, serviceType: serviceType)
    self.serviceBrowser = MCNearbyServiceBrowser(peer: myPeerId, serviceType: serviceType)
    super.init()
    self.serviceAdvertiser.delegate = self
    self.serviceAdvertiser.startAdvertisingPeer()
    self.serviceBrowser.delegate = self
    self.serviceBrowser.startBrowsingForPeers()
  }
  
  deinit {
    self.serviceAdvertiser.stopAdvertisingPeer()
    self.serviceBrowser.stopBrowsingForPeers()
  }
  
  lazy var session: MCSession = {
    let session = MCSession(peer: self.myPeerId, securityIdentity: nil, encryptionPreference: MCEncryptionPreference.Required)
    session.delegate = self
    return session
  }()
  
  
  
  func sendColor(colorName : String) {
    print("sendColor: \(colorName)")
    if session.connectedPeers.count > 0 {
      var error : NSError?
      do {
        try self.session.sendData(colorName.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: session.connectedPeers, withMode: MCSessionSendDataMode.Reliable)
      } catch let error1 as NSError {
        error = error1
        print("Error \(error)")
      }
    }
  }
  
  
  func callRequest(recipient : String, index : NSInteger) {
    
    if session.connectedPeers.count > 0 {
      var error : NSError?
      do {
        try self.session.sendData(recipient.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!, toPeers: [session.connectedPeers[index]], withMode: MCSessionSendDataMode.Reliable)
        self.selectedPeer = session.connectedPeers[index]
        print("connected peers --- > \(session.connectedPeers[index])")
      } catch let error1 as NSError {
        error = error1
        print("\(error)")
      }
    }
    
  }
  
  func sendDataToSelectedPeer(json:Dictionary<String,AnyObject>){
    do {
      let jsonData = try NSJSONSerialization.dataWithJSONObject(json, options: NSJSONWritingOptions.PrettyPrinted)
      try self.session.sendData(jsonData, toPeers: [self.selectedPeer!], withMode: MCSessionSendDataMode.Reliable)
      print("command \(json) --- > \(self.selectedPeer?.displayName)")
    } catch let error1 as NSError {
      print("\(error1)")
    }
  }
  
  
  
}

extension BonjourServiceManager : MCNearbyServiceAdvertiserDelegate {
  
  func advertiser(advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: NSError) {
    print("didNotStartAdvertisingPeer: \(error)")
  }
  
  func advertiser(advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: NSData?, invitationHandler: ((Bool, MCSession) -> Void)) {
    print("didReceiveInvitationFromPeer \(peerID)")
    invitationHandler(true, self.session)
  }
  
}

extension BonjourServiceManager : MCNearbyServiceBrowserDelegate {
  
  func browser(browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: NSError) {
    print("didNotStartBrowsingForPeers: \(error)")
  }
  
  func browser(browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
    print("foundPeer: \(peerID)")
    print("invitePeer: \(peerID)")
    browser.invitePeer(peerID, toSession: self.session, withContext: nil, timeout: 10)
  }
  
  func browser(browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
    print("lostPeer: \(peerID)")
  }
  
}

extension MCSessionState {
  
  func stringValue() -> String {
    switch(self) {
    case .NotConnected: return "NotConnected"
    case .Connecting: return "Connecting"
    case .Connected: return "Connected"
    }
  }
  
}

extension BonjourServiceManager : MCSessionDelegate {
  
  func session(session: MCSession, peer peerID: MCPeerID, didChangeState state: MCSessionState) {
    print("peer \(peerID) didChangeState: \(state.stringValue())")
    self.delegate?.connectedDevicesChanged(self, connectedDevices: session.connectedPeers.map({$0.displayName}))
    print(session.connectedPeers.map({$0.displayName}))
    var arr:[String] = session.connectedPeers.map({$0.displayName})
    if arr.count > 0 {
      print(arr[0])
    }
    
  }
  
  func session(session: MCSession, didReceiveData data: NSData, fromPeer peerID: MCPeerID) {
    
    let str = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
    print("didReceiveData: \(str) from \(peerID.displayName) bytes")
    let peerId = peerID.displayName
    self.delegate?.receivedData(self, peerID: peerId, responseString: str)
  }
  
  func session(session: MCSession, didReceiveStream stream: NSInputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
    print("didReceiveStream")
  }
  
  func session(session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, atURL localURL: NSURL, withError error: NSError?) {
    print("didFinishReceivingResourceWithName")
  }
  
  func session(session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, withProgress progress: NSProgress) {
    print("didStartReceivingResourceWithName")
  }
  
}
