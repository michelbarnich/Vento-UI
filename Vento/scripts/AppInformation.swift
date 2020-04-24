//
//  AppInformation.swift
//  macOS Theme Installer
//
//  Created by Michel Barnich on 31/03/2020.
//  Copyright © 2020 Michel Barnich. All rights reserved.
//

import Foundation
import AppKit

func getBundleIdentifierOfApplication(path: String) -> String {
    
    return (Bundle(path: path)?.bundleIdentifier)!
    
}

func getApplicationIconName(path: String) -> String {    
    return Bundle(path: path)?.infoDictionary!["CFBundleIconFile"] as! String
}
