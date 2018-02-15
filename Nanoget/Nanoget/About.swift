//
//  About.swift
//  Nanoget
//
//  Created by s on 2018-02-08.
//  Copyright © 2018 Hudson Graeme. All rights reserved.
//

import Cocoa

class About: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.window?.styleMask.remove(NSWindow.StyleMask.resizable)
        self.Icon.image = NSApplication.shared.applicationIconImage
    }
    @IBOutlet weak var PayPal: NSButton!
    @IBOutlet weak var Patreon: NSButton!
    @IBOutlet weak var Icon: NSImageView!
    @IBOutlet weak var Txt: NSScrollView!
    
    @IBAction func PayPal(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://www.paypal.me/SpencerGraham")!)
    }
    @IBAction func Patreon(_ sender: Any) {
        NSWorkspace.shared.open(URL(string: "https://www.patreon.com/OSXSpencer")!)
    }
    
    
}
