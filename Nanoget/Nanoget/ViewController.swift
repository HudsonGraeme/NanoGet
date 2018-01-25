//
//  ViewController.swift
//  Nanoget
//
//  Created by s on 2018-01-10.
//  Copyright © 2018 Carspotter Daily. All rights reserved.
//

import Cocoa
import Alamofire
import SwiftyJSON

class ViewController: NSViewController {
    
    @IBOutlet weak var Lbl: NSTextField!
    @IBOutlet weak var Addr: NSTextField!
    @IBOutlet weak var Btn: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let acc = UserDefaults.standard.string(forKey: "Acc") {
            Addr.stringValue = acc
        }
let area = NSTrackingArea.init(rect: Btn.bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
        Btn.addTrackingArea(area)
        self.Btn.wantsLayer = true
        self.Btn.layer?.backgroundColor = NSColor.systemBlue.cgColor
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.lightGray.cgColor
    }
    
    override func mouseEntered(with event: NSEvent) {
        print("Entered: \(event)")
        self.Btn.layer?.backgroundColor = NSColor.blue.blended(withFraction: 0.5, of: .systemBlue)?.cgColor
    }
    
    override func mouseExited(with event: NSEvent) {
        print("Exited: \(event)")
        self.Btn.layer?.backgroundColor = NSColor.systemBlue.cgColor
        
    }
    

    @IBAction func Btn(_ sender: Any) {
        if(Addr.stringValue.count == 42) {
            Addr.textColor = NSColor.orange
            Addr.stringValue = Addr.stringValue.replacingOccurrences(of: "0x", with: "")
            HandleCoins(suspectedCoin: "eth")
        }
        else if(Addr.stringValue.count == 40&&Addr.stringValue.contains("0x") != true){
            Addr.textColor = NSColor.orange
            HandleCoins(suspectedCoin: "eth")
        }
        else if(Addr.stringValue.count == 76) {
            Addr.textColor = NSColor.green
            HandleCoins(suspectedCoin: "sia")
        }
        else if(Addr.stringValue.count == 8) {
            Addr.textColor = NSColor.yellow
            HandleCoins(suspectedCoin: "pasc")
        }
        else if(Addr.stringValue.count > 95) {
            Addr.textColor = NSColor.black
            HandleCoins(suspectedCoin: "etn")
        }
        else if(Addr.stringValue.count == 95) {
            Addr.textColor = NSColor.gray
            HandleCoins(suspectedCoin: "xmr")
        }
        else if(Addr.stringValue.count == 35) {
            Addr.textColor = NSColor.systemBlue
            HandleCoins(suspectedCoin: "zec")
        }
        else {
            Addr.textColor = NSColor.red
            Addr.stringValue = "Invalid Address"
        }
    }
    
    func HandleCoins(suspectedCoin coin:String) {
        if(coin == "eth"){
            Go(Addr.stringValue, coin)
            Go(Addr.stringValue, "etc")
        }
        else {
        Go(Addr.stringValue, coin)
        }
    }
    var canload: Bool = false
    func Go(_ Address:String, _ coin: String){
        UserDefaults.standard.set(Address, forKey: "Acc")
        Alamofire.request("https://api.nanopool.org/v1/\(coin)/balance/\(Address)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        self.canload = true
                        self.YorN(coin)
                    }
                    else {
                        self.canload = false
                      self.YorN(coin)
                    }

                }
            }
            else {
                print("Failure")
                self.canload = false
                self.YorN(coin)
            }
        }
    }
    func YorN(_ coin: String) {
        if(self.canload == true) {
            UserDefaults.standard.set(coin, forKey: "Coin")
            self.performSegue(withIdentifier:NSStoryboardSegue.Identifier(rawValue: "ToMain"), sender: self)
        }
        else {
            print("nope")
        }
    }
}

