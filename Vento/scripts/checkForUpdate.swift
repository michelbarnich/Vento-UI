//
//  test.swift
//  SubscriptionTracker
//
//  Created by Mich on 03/01/2020.
//  Copyright © 2020 MichelBarnich. All rights reserved.
//

import Foundation
//import UIKit

    
    
    
    var buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
    var bundle_version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String;
    let bundleID = Bundle.main.bundleIdentifier;
    
    //let viewControllerInstance = ViewController()
    
    func setURLAndCheckForUpdate() -> String {
        var updateAPI = "https://updateapi.michelbarnich.com?product=Vento"

        if ((bundleID!.contains("Beta"))) {
            updateAPI += "B"
        }

        guard let updateAPIURL = URL(string: updateAPI) else {
            return "false"
        }
        
        //print(updateAPI);

        do {
            let appVersion = try String(contentsOf: updateAPIURL, encoding: .ascii)
            var appVersionArray = appVersion.components(separatedBy: ".")
            var bundle_VersionArray = bundle_version.components(separatedBy: ".")
            
            if (appVersionArray.count == 2) {
                appVersionArray.append("0")
            }
            
            if (bundle_VersionArray.count == 2) {
                bundle_VersionArray.append("0")
            }
            
            if(appVersionArray[0] > bundle_VersionArray[0] || appVersionArray[1] > bundle_VersionArray[1] || appVersionArray[2] > bundle_VersionArray[2]) {
                
                return appVersion
                
            }
            
        } catch {
            return "false";
        }
        
        return "false"
    }
    

