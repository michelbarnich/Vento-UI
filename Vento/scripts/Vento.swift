//
//  Vento.swift
//  Vento CLI
//
//  Created by Michel Barnich on 01/04/2020.
//  Copyright © 2020 Michel Barnich. All rights reserved.
//

import Foundation
import AppKit

func getInstalledAppsInfoArray() -> Array<Array<String>> {
    var installedAppsArray = [[String]]()
    
    let ls = Process()
    ls.launchPath = "/usr/bin/mdfind"
    ls.arguments = ["kMDItemContentType == 'com.apple.application-bundle'"]

    let pipe = Pipe()

    ls.standardOutput = pipe
    ls.launch()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let output = String(data: data, encoding: String.Encoding.utf8) {
        
        let appPaths = output.split(separator: "\n");
        
        for i in 0...appPaths.count - 1 {
            installedAppsArray.append([(appPaths[i] as NSString).lastPathComponent, String(appPaths[i])])
        }
    }
    
    return installedAppsArray
    
    /*do {
        let installedApps = try FileManager.default.contentsOfDirectory(atPath: "/Applications")
        
        for app in installedApps {
            
            if app.hasSuffix(".app") {
                installedAppsArray.append([app, "/Applications/\(app)"])
            }
        }
        
        return installedAppsArray
    } catch {
        return installedAppsArray
    }*/
}

func backupCurrentTheme() {
    print("[INFO:] creating Backup of current theme...")
    if(!FileManager.default.fileExists(atPath: "/Users/\(NSUserName())/Desktop/vento_backup.bundle")) {
        
        do {
            try FileManager.default.createDirectory(atPath: "/Users/\(NSUserName())/Desktop/vento_backup.bundle", withIntermediateDirectories: false, attributes: nil)
            
            for appInfo in getInstalledAppsInfoArray() {
                DispatchQueue.main.async {
                    let icon = NSWorkspace.shared.icon(forFile: appInfo[1])
                    
                        
                        if(!FileManager.default.fileExists(atPath: "/Users/\(NSUserName())/Desktop/vento_backup.bundle/\(getBundleIdentifierOfApplication(path: appInfo[1])).png")) {
                            
                            print("[INFO:] backing up \(getBundleIdentifierOfApplication(path: appInfo[1]))")
                            
                            //try FileManager.default.copyItem(at: URL(fileURLWithPath: "/Applications/\(appInfo[0])/Contents/Resources/\(iconName)"), to: URL(fileURLWithPath: "/Users/\(NSUserName())/Desktop/vento_backup/\(getBundleIdentifierOfApplication(path: appInfo[1])).png"))
                            FileManager.default.createFile(atPath: "/Users/\(NSUserName())/Desktop/vento_backup.bundle/\(getBundleIdentifierOfApplication(path: appInfo[1])).png", contents: icon.tiffRepresentation, attributes: nil)
                            
                        }
                    }
                }
            
        } catch {
            print("[ERROR:] \(error)")
        }
        
    }
    
}

func installTheme(themeFolderPath: String, installedAppsArray: Array<Array<String>>) {
    //backupCurrentTheme()
    
    if(UserDefaults.standard.bool(forKey: "mountRootFS")) {
        
    }
    
    print("[INFO:] installing Theme")
    
    var themeFolderPathCorrected = themeFolderPath
    if !themeFolderPath.hasSuffix("/") {
        themeFolderPathCorrected += "/"
    }
    
    let appInfoArray = installedAppsArray;
    
    for app in appInfoArray {
        
        do {
            
            var appIconName = getApplicationIconName(path: app[1])
            if !appIconName.hasSuffix(".icns") {
                appIconName = appIconName + ".icns"
            }
            
            let expectedIconPath = themeFolderPathCorrected + getBundleIdentifierOfApplication(path: app[1]) + ".icns"
            
            if FileManager.default.fileExists(atPath: expectedIconPath) {
                
                print("[INFO:] copying Icon for \(app[0])")
                //ViewController().updateStatus(status: "copying Icon for \(app[0])")
                
                NSWorkspace.shared.setIcon(NSImage(byReferencing: URL(fileURLWithPath: expectedIconPath)), forFile: app[1], options: NSWorkspace.IconCreationOptions(rawValue: 0))
                
                var AppURL = URL(fileURLWithPath: app[1])
                var InfoURL = URL(fileURLWithPath: "\(app[1])/Info.plist")
                var resourceValues = URLResourceValues()
                resourceValues.contentModificationDate = Date()
                try? AppURL.setResourceValues(resourceValues)
                try? InfoURL.setResourceValues(resourceValues)
            }
            
        }
    }
    
}

func fixPermissions(_ password:String, appPath:String) {
    let taskOne = Process()
    taskOne.launchPath = "/bin/echo"
    taskOne.arguments = [password]

    let taskTwo = Process()
    taskTwo.launchPath = "/usr/bin/sudo"
    taskTwo.arguments = ["-S", "/usr/sbin/chown", NSUserName(), appPath]

    let pipeBetween:Pipe = Pipe()
    taskOne.standardOutput = pipeBetween
    taskTwo.standardInput = pipeBetween

    let pipeToMe = Pipe()
    taskTwo.standardOutput = pipeToMe
    taskTwo.standardError = pipeToMe

    taskOne.launch()
    taskTwo.launch()

    let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
    let output : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    print(output)
}

func remountRootFS(password: String) {
    let taskOne = Process()
    taskOne.launchPath = "/bin/echo"
    taskOne.arguments = [password]

    let taskTwo = Process()
    taskTwo.launchPath = "/usr/bin/sudo"
    taskTwo.arguments = ["-S", "/sbin/mount", "-u", "-o", "rw", "/"]

    let pipeBetween:Pipe = Pipe()
    taskOne.standardOutput = pipeBetween
    taskTwo.standardInput = pipeBetween

    let pipeToMe = Pipe()
    taskTwo.standardOutput = pipeToMe
    taskTwo.standardError = pipeToMe

    taskOne.launch()
    taskTwo.launch()

    let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
    let output : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue)! as String
    print(output)
}
