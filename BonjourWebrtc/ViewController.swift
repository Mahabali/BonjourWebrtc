//
//  ViewController.swift
//  BonjourWebrtc
//
//  Created by Mahabali on 5/4/16.
//  Copyright © 2016 Mahabali. All rights reserved.
//

import UIKit
enum ResponseValue: String {
  case incomingCall = "incomingCall"
  case callAccepted = "callAccepted"
  case callRejected = "callRejected"
}
class ViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
  @IBOutlet weak var connectionsLabel: UILabel!
  @IBOutlet weak var tableView: UITableView!
  // Differentiates caller and receiver
  var isInitiator = false
  var peerListArray : [String] = []
  let bonjourService = BonjourServiceManager.sharedBonjourServiceManager
  
  override func viewDidLoad() {
    super.viewDidLoad()
    bonjourService.delegate = self
    tableView.registerClass(UITableViewCell.self,
                            forCellReuseIdentifier: "Cell")
    self.title = "Peers"
  }
  
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    bonjourService.delegate = self
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    let unownedSelf = self
    if segue.destinationViewController.isKindOfClass(RTCVideoChatViewController){
      let destinationController:RTCVideoChatViewController = segue.destinationViewController as! RTCVideoChatViewController
      destinationController.isInitiator = unownedSelf.isInitiator
      BonjourServiceManager.sharedBonjourServiceManager.delegate = nil
    }
  }
  
  func showAlert(caller : String) {
    let unownedSelf = self
    let alert = UIAlertController(title: "Incoming Call",
                                  message: caller,
                                  preferredStyle: .Alert)
    let idx = peerListArray.indexOf(caller) //
    let acceptAction = UIAlertAction(title: "Accept",
                                     style: .Default,
                                     handler: { (action:UIAlertAction) -> Void in
                                      unownedSelf.bonjourService.callRequest("callAccepted", index: idx!)
                                      unownedSelf.isInitiator = false
                                      unownedSelf.startCallViewController()
    })
    let rejectAction = UIAlertAction(title: "Reject",
                                     style: .Default) { (action: UIAlertAction) -> Void in
                                      unownedSelf.bonjourService.callRequest("callRejected", index: idx!)
                                      
    }
    alert.addAction(acceptAction)
    alert.addAction(rejectAction)
    presentViewController(alert, animated: true, completion: nil)
  }
  
  func startCallViewController(){
    let unownedSelf = self
    dispatch_async(dispatch_get_main_queue()) {
      unownedSelf.performSegueWithIdentifier("showVideoCall", sender: unownedSelf)
    }
  }
  
  // tableView
  
  func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    return 70
  }
  
  
  func tableView(tableView: UITableView,
                 numberOfRowsInSection section: Int) -> Int {
    return peerListArray.count
  }
  
  func tableView(tableView: UITableView,cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell")
    cell?.textLabel?.text = peerListArray[indexPath.row]
    return cell!
  }
  
  func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    bonjourService.callRequest("incomingCall", index: indexPath.row)
    self.isInitiator = true
  }
  
  
}

extension ViewController : BonjourServiceManagerProtocol {
  
  func connectedDevicesChanged(manager: BonjourServiceManager, connectedDevices: [String]) {
    let unownedSelf = self
    NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
      unownedSelf.connectionsLabel.text = "Connections: \(connectedDevices)"
      unownedSelf.peerListArray = connectedDevices
      unownedSelf.tableView.reloadData()
    }
  }
  
  func receivedData(manager: BonjourServiceManager, peerID: String, responseString: String) {
    let unownedSelf = self
    dispatch_async(dispatch_get_main_queue()) {
      switch responseString {
      case ResponseValue.incomingCall.rawValue :
        print("incomingCall")
        unownedSelf.showAlert(peerID)
      case ResponseValue.callAccepted.rawValue:
        print("callAccepted")
        unownedSelf.startCallViewController()
      case ResponseValue.callRejected.rawValue:
        print("callRejected")
      default:
        print("Unknown color value received: \(responseString)")
      }
    }
  }
}
