//
//  fixPermissions.swift
//  Vento
//
//  Created by Mich on 24/04/2020.
//  Copyright © 2020 Michel Barnich. All rights reserved.
//

import Foundation
import OpenDirectory

func authenticateLocalUser(username: String, password: String) -> Bool {
    do {
        let session = ODSession()
        let node = try ODNode(session: session, type: ODNodeType(kODNodeTypeLocalNodes))
        let record = try node.record(withRecordType: kODRecordTypeUsers, name: username, attributes: nil)
        try record.verifyPassword(password)
        return true
    } catch {
        return false
    }
}

func fixPermission(appPath:String, password:String) {
    let taskOne = Process()
    taskOne.launchPath = "/bin/echo"
    taskOne.arguments = [password]

    let taskTwo = Process()
    taskTwo.launchPath = "/usr/bin/sudo"
    taskTwo.arguments = ["-S", "/usr/sbin/chown", NSUserName() , appPath]

    let pipeBetween:Pipe = Pipe()
    taskOne.standardOutput = pipeBetween
    taskTwo.standardInput = pipeBetween

    let pipeToMe = Pipe()
    taskTwo.standardOutput = pipeToMe
    taskTwo.standardError = pipeToMe

    taskOne.launch()
    taskTwo.launch()

    let data = pipeToMe.fileHandleForReading.readDataToEndOfFile()
    let output : String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as! String
    print(output)
}
