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
        
        switch coin! {
        case "eth":
            self.Lvl.maxValue = 0.2
            self.Lvl.fillColor = NSColor.orange
        case "etc":
            self.Lvl.maxValue = 1
        case "sia":
            self.Lvl.maxValue = 1000
        case "zec":
            self.Lvl.maxValue = 0.01
        case "xmr":
            self.Lvl.maxValue = 1
        case "pasc":
            self.Lvl.maxValue = 1
        case "etn":
            self.Lvl.maxValue = 500
        default:
            self.Lvl.maxValue = 1
        }
        Lvl.doubleValue = 0
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


    @IBOutlet weak var LoadInd: NSProgressIndicator!
    @IBOutlet weak var LvlLabel: NSTextField!
    @IBOutlet weak var RepHash: NSTextField!
    @IBOutlet weak var Lvl: NSLevelIndicator!
    
    
    let coin = UserDefaults.standard.string(forKey: "Coin")
    
    var output = ""
    
    
    func DoAll() {
        if(GetBalance() == 1) {
            GetReportedHash()
        }
    }
    
    func GetUSD(_ coinValue: Double) {
        if(coin == "sia"||coin == "etn"||coin == "pasc") {
            
        }
        else {
        Alamofire.request("https://api.cryptonator.com/api/ticker/\(coin!)-usd") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    self.LoadInd.doubleValue = 50
                    let json = JSON(data: data!)
                    if(json["success"].intValue == 1) {
                        let usdvalue = json["ticker"]["price"].doubleValue
                        let usd = coinValue * usdvalue
                        self.LvlLabel.stringValue += " | $\(usd)USD"
                        self.LoadInd.doubleValue = 60
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.LvlLabel.stringValue = json["error"].stringValue
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
    
    func GetBalance() -> Int{
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(coin!)/balance/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    self.LoadInd.doubleValue = 25
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        let money = json["data"].doubleValue
                        self.Lvl.doubleValue = money
                        let coinh = self.coin!
                        self.LvlLabel.stringValue = "\(money)\(coinh.capitalized)"
                        self.Lvl.toolTip = "\(money)/\(self.Lvl.maxValue) | \(Double((money / self.Lvl.maxValue) / 10).rounded(toPlaces: 3))%"
                        self.GetUSD(money)
                        self.LoadInd.doubleValue = 40
                    
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.LvlLabel.stringValue = json["error"].stringValue
                        }
                    }
                    
                }
            }
            else {
                print("Failure")
            }
        }
        return 1
    }
    func GetReportedHash() {
        self.LoadInd.doubleValue = 65
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(self.coin!)/reportedhashrates/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        self.LoadInd.doubleValue = 70
                        var keepgoing = true
                        var i = 0
                        var rate = 0 as Double
                        var indRate = 0 as Double
                        while keepgoing == true {
                            if(json["data"][i] != JSON.null) {
                                indRate = json["data"][i]["hashrate"].doubleValue
                            rate += indRate
                            i += 1
                                if(self.LoadInd.doubleValue < 100) {
                                    self.LoadInd.doubleValue += 10
                                }
                                print("\(i)   -   \(indRate)")
                            }
                            else {
                                keepgoing = false
                            }
                            
                        }
                        self.RepHash.stringValue = "\(rate)Mh/s Reported"
                        self.LoadInd.isHidden = true
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.RepHash.stringValue = json["error"].stringValue
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

extension Double {
    func rounded(toPlaces places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded()
    }
}
