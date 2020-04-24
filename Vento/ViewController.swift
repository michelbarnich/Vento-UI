//
//  ViewController.swift
//  Vento
//
//  Created by Michel Barnich on 14/04/2020.
//  Copyright © 2020 Michel Barnich. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var iconContainerView: NSView!
    @IBOutlet weak var installButton: NSButton!
    @IBOutlet weak var header: NSTextField!
    @IBOutlet weak var blurView: NSVisualEffectView!
    @IBOutlet var mainView: NSView!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var spinWheel: NSProgressIndicator!
    
    @IBAction func closeButton(_ sender: Any) {
        blurView.isHidden = true
        
        for view in iconContainerView.subviews {
            view.removeFromSuperview()
        }
        iconContainerView.setFrameOrigin(NSPoint(x: 0, y: 142))
        iconContainerView.frame.size.width = 0
        fillContainerView()
    }
    
    func rotateLeft() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = TimeInterval(self.iconContainerView.frame.size.width * 0.02)
            self.iconContainerView.animator().setFrameOrigin(NSPoint(x: self.iconContainerView.frame.size.width * -1 + 480, y: 142)
            )},completionHandler:{self.rotateRight()})
    }
    
    func rotateRight() {
        NSAnimationContext.runAnimationGroup({_ in
        NSAnimationContext.current.duration = TimeInterval(self.iconContainerView.frame.size.width * 0.02)
        self.iconContainerView.animator().setFrameOrigin(NSPoint(x: 0, y: 142)
            )},completionHandler:{ self.rotateLeft()})
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fillContainerView()
        rotateLeft()
        blurView.isHidden = true
        /*mainView.blendingMode = .behindWindow
        mainView.material = .dark*/
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    func fillContainerView() {
        let installedAppsArray = getInstalledAppsInfoArray();
        
        //trashy implementation of icon slideshow
        for i in 0 ... (installedAppsArray.count - 1) {
            print(installedAppsArray[i])
            var imageNameForView = Bundle(path: installedAppsArray[i][1])?.infoDictionary!["CFBundleIconFile"] as! String
            
            if !imageNameForView.hasSuffix(".icns") {
                imageNameForView += ".icns"
            }
            
            let imageForView = NSImage(contentsOf: URL(fileURLWithPath: installedAppsArray[i][1] + "/Contents/resources/" + imageNameForView))
            let newImageView = NSImageView(frame: CGRect(x: (94 * i), y: 0, width: 94, height: 94))
            newImageView.image = imageForView
            iconContainerView.addSubview(newImageView);
            iconContainerView.frame.size.width += 94;
            
        }
    }


    @IBAction func choseTheme(_ sender: Any) {
        let dialog = NSOpenPanel();
         
         dialog.title                   = "Choose a theme";
         dialog.showsResizeIndicator    = false;
         dialog.showsHiddenFiles        = false;
         dialog.canChooseDirectories    = true;
         dialog.canCreateDirectories    = false;
         dialog.allowsMultipleSelection = false;
         dialog.allowedFileTypes        = ["bundle"];

        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            let result = dialog.url // Pathname of the file
             
             if (result != nil) {
                blurView.isHidden = false;
                closeButton.isHidden = true
                self.spinWheel.isHidden = false
                spinWheel.startAnimation(self)
                let path = result!.path
                //SSZipArchive.unzipFile(atPath: path, toDestination: "/Users/\(NSUserName())/Desktop/temp_theme")
                statusLabel.stringValue = "gathering information..."
                DispatchQueue.global(qos: .background).async {
                    //backupCurrentTheme()
                    
                    print("[INFO:] installing Theme")
                    
                    let themeFolderPathCorrected = path
                    
                    let appInfoArray = getInstalledAppsInfoArray()
                    
                    for app in appInfoArray {
                        
                        do {
                            
                            let expectedIconPath = themeFolderPathCorrected + "/" + getBundleIdentifierOfApplication(path: app[1]) + ".png"
                            print(expectedIconPath)
                            
                            if FileManager.default.fileExists(atPath: expectedIconPath) {
                                
                                print("[INFO:] copying Icon for \(app[0])")
                                DispatchQueue.main.async {
                                    self.statusLabel.stringValue = "copying Icon for \(app[0])"
                                }
                                
                                
                                
                                NSWorkspace.shared.setIcon(NSImage(byReferencing: URL(fileURLWithPath: expectedIconPath)), forFile: "/Applications/\(app[0])", options: NSWorkspace.IconCreationOptions(rawValue: 0))
                                
                                var AppURL = URL(fileURLWithPath: "/Applications/\(app[0])")
                                var InfoURL = URL(fileURLWithPath: "/Applications/\(app[0])/Info.plist")
                                var resourceValues = URLResourceValues()
                                resourceValues.contentModificationDate = Date()
                                try? AppURL.setResourceValues(resourceValues)
                                try? InfoURL.setResourceValues(resourceValues)
                            }
                            
                        } catch {
                            print("[ERROR:] \(error)")
                            
                        }
                    }
                    DispatchQueue.main.async {
                        self.statusLabel.stringValue = "cleaning up..."
                        do {
                            try FileManager.default.removeItem(at: URL(fileURLWithPath: "/Users/\(NSUserName())/Desktop/temp_theme/"))
                        } catch {
                            self.statusLabel.stringValue = "could not delete temp_theme"
                        }
                        self.statusLabel.stringValue = "Done! Enjoy your theme!"
                        self.spinWheel.isHidden = true
                        self.closeButton.isHidden = false
                    
                    }
                }
            }
         } else {
             // User clicked on "Cancel"
             return
         }
         
    }
    
}

class ViewController2: NSViewController {
    
    @IBOutlet weak var backupbttn: NSButton!
    @IBAction func backup(_ sender: Any) {
        DispatchQueue.main.async {
            self.backupbttn.stringValue = "backing up..."
            backupCurrentTheme()
        }
    }
    
    
    @IBAction func fixPerm(_ sender: Any) {
        
    }
}

class FixViewController: NSViewController {
    
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var veView: NSVisualEffectView!
    @IBOutlet weak var fixStatusLabel: NSTextField!
    
    @IBAction func cancelFix(_ sender: Any) {
        self.view.window?.windowController?.close()
    }
    
    func checkPasswordAndFix(password:String) {
        if(authenticateLocalUser(username: NSUserName(), password: password)) {
            DispatchQueue.global(qos: .background).async {
                let installedApps = getInstalledAppsInfoArray()
                
                DispatchQueue.main.async {
                    self.veView.isHidden = false;
                    self.passwordInput.isHidden = true
                }
                
                for i in 0 ... (installedApps.count - 1) {
                    fixPermissions(password, appPath: installedApps[i][1])
                    
                    DispatchQueue.main.async {
                        self.fixStatusLabel.stringValue = "fixing " + installedApps[1][0]
                    }
                    
                }
                DispatchQueue.main.async {
                    self.view.window?.windowController?.close()
                }
            }
        } else {
            self.view.window?.shakeWindow()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        veView.isHidden = true;
    }
    
    @IBAction func applyFix(_ sender: Any) {
        self.checkPasswordAndFix(password: passwordInput.stringValue)
    }
    
    @IBAction func passwordInput(_ sender: Any) {
        self.checkPasswordAndFix(password: passwordInput.stringValue)
    }
}

extension NSWindow {

    func shakeWindow(){
        let numberOfShakes      = 3
        let durationOfShake     = 0.25
        let vigourOfShake : CGFloat = 0.015

        let frame : CGRect = self.frame
        let shakeAnimation :CAKeyframeAnimation  = CAKeyframeAnimation()

        let shakePath = CGMutablePath()
        shakePath.move(to: CGPoint(x: frame.minX, y: frame.minY))

        for _ in 0...numberOfShakes-1 {
            shakePath.addLine(to: CGPoint(x: frame.minX - frame.size.width * vigourOfShake, y: frame.minY))
            shakePath.addLine(to: CGPoint(x: frame.minX + frame.size.width * vigourOfShake, y: frame.minY))
        }

        shakePath.closeSubpath()

        shakeAnimation.path = shakePath;
        shakeAnimation.duration = durationOfShake;

        self.animations = ["frameOrigin":shakeAnimation]
        self.animator().setFrameOrigin(self.frame.origin)
    }

}
