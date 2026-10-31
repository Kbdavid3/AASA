//
//  CheatSheet.swift
//  kiccbacc
//
//  Created by ANKIT YADAV on 17/03/21.
//  Copyright © 2021 APPLE. All rights reserved.
//

import UIKit

func alertWithDefaultAction(AlertTitle: String, Message: String, ActionBttnTitle: String) -> UIAlertController{
    let alertController = UIAlertController(title: AlertTitle, message: Message, preferredStyle: .alert)
    let defaultAction = UIAlertAction(title: ActionBttnTitle, style: .cancel, handler: nil)
    alertController.addAction(defaultAction)
    return alertController
}

func openApp(userName: String, appName: String){
    let appURL = NSURL(string: "\(appName)://user?screen_name=\(userName)")!
    let webURL = NSURL(string: "https://\(appName).com/\(userName)")!

    let application = UIApplication.shared

    if application.canOpenURL(appURL as URL) {
        application.open(appURL as URL)
    } else {
        application.open(webURL as URL)
    }
}

func mediumImpactHeptic(){
    let generator = UIImpactFeedbackGenerator(style: .medium)
    generator.impactOccurred()
}
