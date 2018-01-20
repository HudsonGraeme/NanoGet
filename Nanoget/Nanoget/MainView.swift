//
//  MainView.swift
//  Nanoget
//
//  Created by s on 2018-01-10.
//  Copyright © 2018 Carspotter Daily. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

class MainView: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let Address =  UserDefaults.standard.string(forKey: "SSHAddress")
        let Port = UserDefaults.standard.integer(forKey: "SSHPort")
        let Username = UserDefaults.standard.string(forKey: "SSHUser")
        let Password = UserDefaults.standard.string(forKey: "SSHPassword")
        ETHLvl.doubleValue = 0
        DoAll()
        @discardableResult
        func shell(_ args: String...) -> (String?, Int32) {
            let task = Process()
            task.launchPath = Bundle.main.path(forResource: "/bin/bash", ofType: nil);
            task.arguments = args
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            task.launch()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            output = String(data: data, encoding: .utf8)!
            print("OUTPUT::  ", output)
            task.waitUntilExit()
            return (output, task.terminationStatus)
        }
        if(Address != "" && Port > 0 && Password != "" && Username != "") {
            shell("ssh", "-p", "\(Port)", "\(Username)@\(Address)")
        }
    }
    @IBOutlet weak var mhs: NSTextField!
    var output = ""
    @IBOutlet weak var ETHLvl: NSLevelIndicator!
    @IBOutlet weak var ETHAmnt: NSTextField!
    
    func DoAll() {
        GetBalance()
        GetReportedHash()
    }
    
    
    
    func GetBalance() {
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/eth/balance/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        let eth = json["data"].doubleValue
                        self.ETHLvl.doubleValue = eth
                        self.ETHAmnt.stringValue = "\(eth)ETH"
                    }
                    else {
                        print("Bad address")
                    }
                    
                }
            }
            else {
                print("Failure")
            }
        }
    }
    func GetReportedHash() {
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/eth/reportedhashrates/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        let rate = json["data"][0]["hashrate"].stringValue
                        self.mhs.stringValue = "\(rate)Mh/s Reported"
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.mhs.stringValue = json["error"].stringValue
                        }
                        
                    }
                    
                }
            }
            else {
                print("Failure")
            }
        }
    }
}
