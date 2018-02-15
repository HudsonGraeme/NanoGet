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
import Charts

class MainView: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.Graph.scaleYEnabled = false
        self.Graph.scaleXEnabled = false
        self.Graph.rightAxis.enabled = false
        self.Graph.leftAxis.enabled = false
        self.Graph.xAxis.enabled = false
        self.Graph.legend.enabled = false
        let Address =  UserDefaults.standard.string(forKey: "SSHAddress")
        let Port = UserDefaults.standard.integer(forKey: "SSHPort")
        let Username = UserDefaults.standard.string(forKey: "SSHUser")
        let Password = UserDefaults.standard.string(forKey: "SSHPassword")
        
        switch coin! {
        case "eth":
            self.Lvl?.maxValue = 0.2
            self.Lvl?.fillColor = .orange
            LineColour = .orange
        case "etc":
            self.Lvl?.maxValue = 1
            self.Lvl?.fillColor = .orange
            LineColour = .orange
        case "sia":
            self.Lvl?.maxValue = 1000
            self.Lvl?.fillColor = .green
            LineColour = .green
        case "zec":
            self.Lvl?.maxValue = 0.01
            self.Lvl?.fillColor = .systemBlue
            LineColour = .systemBlue
        case "xmr":
            self.Lvl?.maxValue = 1
            self.Lvl?.fillColor = .gray
            LineColour = .gray
        case "pasc":
            self.Lvl?.maxValue = 1
            self.Lvl?.fillColor = .yellow
            LineColour = .yellow
        case "etn":
            self.Lvl?.maxValue = 50000
            self.Lvl?.fillColor = .systemGray
            LineColour = .systemGray
        default:
            self.Lvl?.maxValue = 1
        }
        Lvl?.doubleValue = 0
        DoAll(tmer: nil)
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
        self.Graph?.drawGridBackgroundEnabled = true
        self.Graph?.gridBackgroundColor = NSColor.darkGray
        self.Graph?.autoScaleMinMaxEnabled = true
        _ = Timer.scheduledTimer(timeInterval: 30.0, target: self, selector: #selector(DoAll), userInfo: self, repeats: true)
        _ = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(Update1s), userInfo: self, repeats: true)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.darkGray.cgColor
    }

    @IBOutlet weak var LoadInd: NSProgressIndicator!
    @IBOutlet weak var LvlLabel: NSTextField!
    @IBOutlet weak var RepHash: NSTextField!
    @IBOutlet weak var Lvl: NSLevelIndicator!
    @IBOutlet weak var Graph: LineChartView!
    @IBOutlet weak var RefreshLabel: NSTextField!
    @IBOutlet weak var RefreshInd: NSProgressIndicator!
    @IBOutlet weak var CalcHash: NSTextField!
    
    let coin = UserDefaults.standard.string(forKey: "Coin")
    var LineColour = NSColor.brown
    var output = ""
    var lineChartEntry = [ChartDataEntry]()
    var i = 0
    var time : Double = 30
    var retry : Int = 0
    var CalcHashRetry : Int = 0
    var RepHashRetry : Int = 0
    
    @objc func Update1s(timer: Timer?) {
        time -= 1
        self.RefreshLabel?.stringValue = "Refreshing in \(time)"
        self.RefreshInd?.doubleValue = time
    }
    
    @objc func DoAll(tmer:Timer?) {
        if(tmer != nil) {
            
            if(GetBalance() == 1) {
                GetReportedHash()
                GetCalculatedHash()
            }
            time = 30
        }
        else {
            
        self.LoadInd?.doubleValue = 10
        if(GetBalance() == 1) {
            self.LoadInd?.doubleValue = 30
            GetReportedHash()
            self.LoadInd?.doubleValue = 70
            GetChartData()
            self.LoadInd?.doubleValue = 90
            GetCalculatedHash()
            self.LoadInd?.doubleValue = 100
        }
        if(self.LoadInd?.doubleValue == 100) {
            self.LoadInd?.isHidden = true
        }
            time = 30
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
                    let json = JSON(data: data!)
                    if(json["success"].intValue == 1) {
                        let usdvalue = json["ticker"]["price"].doubleValue
                        let usd = coinValue * usdvalue
                        self.LvlLabel?.stringValue += " | $\(usd)USD"
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.LvlLabel?.stringValue = json["error"].stringValue
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
    
    func GetBalance() -> Int {
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(coin!)/balance/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        let money = json["data"].doubleValue
                        if(money == 0 && self.retry <= 1) {
                            self.GetBalance()
                            self.retry += 1
                            return
                        }
                        self.Lvl?.doubleValue = money
                        let coinh = self.coin!
                        self.LvlLabel?.stringValue = "\(money)\(coinh.uppercased())"
                        self.Lvl?.toolTip = "\(money)/\(self.Lvl.maxValue) | \(Double((money / self.Lvl.maxValue) / 10).rounded(toPlaces: 3))%"
                        self.GetUSD(money)
                    self.retry = 0
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.LvlLabel?.stringValue = json["error"].stringValue
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
        
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(self.coin!)/reportedhashrates/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        
                        var i = 0
                        var rate = 0 as Double
                        var indRate = 0 as Double
                        while json["data"][i] != JSON.null {
                            indRate = json["data"][i]["hashrate"].doubleValue
                            rate += indRate
                            i += 1
                        }
                        if(self.RepHashRetry <= 2 && rate == 0) {
                            self.GetReportedHash()
                            self.RepHashRetry += 1
                            print("Retry Reported \(self.RepHashRetry)")
                        }
                        else {
                            self.RepHash?.stringValue = "\(rate)Mh/s Reported"
                            self.RepHashRetry = 0
                            }
                    }
                    else {
                        if(self.RepHashRetry <= 2) {
                            self.GetReportedHash()
                            self.RepHashRetry += 1
                            print("Retry Reported \(self.RepHashRetry)")
                        }
                        else {
                            if(json["error"].stringValue != "") {
                                self.RepHash?.stringValue = json["error"].stringValue
                            }
                        }
                    }
                    
                }
            }
            else {
                print("Failure")
            }
        }
    }
    
    func GetCalculatedHash() {
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(self.coin!)/hashrate/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].boolValue == true) {
                        let rate = json["data"].doubleValue
                        self.CalcHash?.stringValue = "\(rate)Mh/s Calculated"
                        if(self.CalcHashRetry <= 2 && rate == 0) {
                            self.GetCalculatedHash()
                            self.CalcHashRetry += 1
                            print("Calculated Retry \(self.CalcHashRetry)")
                        }
                        else {
                            self.CalcHashRetry = 0
                            }
                    }
                    else {
                        if(self.CalcHashRetry <= 2) {
                            self.GetCalculatedHash()
                            self.CalcHashRetry += 1
                            print("Calculated Retry \(self.CalcHashRetry)")
                        }
                        else {
                        if(json["error"].stringValue != "") {
                            self.CalcHash?.stringValue = json["error"].stringValue
                        }
                        }
                    }
                    
                }
            }
            else {
                print("Failure")
            }
        }
    }
    
    
    func GetChartData() {
        let Address = UserDefaults.standard.string(forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(self.coin!)/hashratechart/\(Address!)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    let json = JSON(data: data!)
                    if(json["status"].boolValue == true) {
                        print("Status good")
                        var i = 0
                        var rate = 0 as Double
                        var indRate = 0 as Double
                        while json["data"][i] != JSON.null {
                                indRate = json["data"][i]["shares"].doubleValue
                                let value = ChartDataEntry(x: Double(i), y: indRate)
                                self.lineChartEntry.append(value)
                                i += 1
                                let line = LineChartDataSet(values: self.lineChartEntry, label: "Shares")
                            line.colors = [self.LineColour]
                            line.mode = .cubicBezier
                            line.fillColor = self.LineColour
                            line.fillAlpha = 1
                            line.drawFilledEnabled = true
                            line.drawCirclesEnabled = false
                                let chartdat = LineChartData()
                                chartdat.addDataSet(line)
                                self.Graph?.data = chartdat
                            self.Graph?.chartDescription?.enabled = false
                        }
                        self.RepHash?.stringValue = "\(rate)Mh/s Reported"
                       
                    }
                    else {
                        print("Bad address")
                        if(json["error"].stringValue != "") {
                            self.RepHash?.stringValue = json["error"].stringValue
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
