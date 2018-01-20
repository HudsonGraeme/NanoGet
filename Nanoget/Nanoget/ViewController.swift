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

    }

    @IBAction func Btn(_ sender: Any) {
        if(Addr.stringValue.count == 42) {
            Addr.textColor = NSColor.black
            Addr.stringValue = Addr.stringValue.replacingOccurrences(of: "0x", with: "")
            Go(Addr.stringValue)
        }
        else if(Addr.stringValue.count == 40&&Addr.stringValue.contains("0x") != true){
            Addr.textColor = NSColor.black
            Go(Addr.stringValue)
        }
        else {
            Addr.textColor = NSColor.red
            Addr.stringValue = "Invalid Address"
        }
    }
    func Go(_ Address:String) {
        Alamofire.request("https://api.nanopool.org/v1/eth/balance/\(Address)") .responseJSON { response in
            let data = response.data
            if(response.result.isSuccess) {
                if let result = response.result.value {
                    print(result)
                    
                    let json = JSON(data: data!)
                    if(json["status"].intValue == 1) {
                        UserDefaults.standard.set(Address, forKey: "Acc")
                        self.performSegue(withIdentifier:NSStoryboardSegue.Identifier(rawValue: "ToMain"), sender: self)
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
}

