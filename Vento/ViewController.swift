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
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            self.iconContainerView.animator().setFrameOrigin(NSPoint(x: self.iconContainerView.frame.size.width * -1 + 480, y: 142)
            )},completionHandler:{
                self.rotateRight()
                
        })
    }
    
    func rotateRight() {
        NSAnimationContext.runAnimationGroup({_ in
            NSAnimationContext.current.duration = TimeInterval(self.iconContainerView.frame.size.width * 0.02)
            NSAnimationContext.current.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            self.iconContainerView.animator().setFrameOrigin(NSPoint(x: 0, y: 142)
        )},completionHandler:{
            self.rotateLeft()
            
        })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let launchedBefore = UserDefaults.standard.bool(forKey: "launchedBefore")
        if !launchedBefore {
            UserDefaults.standard.setValue(true, forKey: "launchedBefore");
            UserDefaults.standard.setValue(true, forKey: "remountRootFS");
        }
        
        fillContainerView()
        rotateLeft()
        blurView.isHidden = true
        /*mainView.blendingMode = .behindWindow
        mainView.material = .dark*/
        
        if (setURLAndCheckForUpdate() != "false") {
            var myWindow: NSWindow? = nil
            let storyboard = NSStoryboard(name: "Main",bundle: nil)
            let controller: NSViewController = storyboard.instantiateController(withIdentifier: "updateView") as! NSViewController
            myWindow = NSWindow(contentViewController: controller)
            myWindow?.makeKeyAndOrderFront(self)
            let vc = NSWindowController(window: myWindow)
            vc.showWindow(self)
        }
    }

    override var representedObject: Any? {
        didSet {
        }
    }
    
    func fillContainerView() {
        let installedAppsArray = getInstalledAppsInfoArray();
        
        //trashy implementation of icon slideshow
        let defaultIcon = "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericApplicationIcon.icns"
        for i in 0 ... (installedAppsArray.count - 1) {
            print(installedAppsArray[i])
            var imageNameForView:String = Bundle(path: installedAppsArray[i][1])?.infoDictionary?["CFBundleIconFile"] as? String ?? defaultIcon
            
            if !imageNameForView.hasSuffix(".icns") {
                imageNameForView += ".icns"
            }
            
            var imageForView = NSImage(contentsOf: URL(fileURLWithPath: installedAppsArray[i][1] + "/Contents/resources/" + imageNameForView))
            
            if(imageNameForView == defaultIcon) {
                imageForView = NSImage(contentsOf: URL(fileURLWithPath: defaultIcon))
            }
            
            let newImageView = NSImageView(frame: CGRect(x: (94 * i), y: 0, width: 94, height: 94))
            newImageView.image = imageForView
            iconContainerView.addSubview(newImageView);
            iconContainerView.frame.size.width += 94;
            
        }
    }
    
    @IBAction func listView(_ sender: Any) {
        
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if(segue.identifier == "remount") {
            let viewController = segue.destinationController as! FixViewController
            viewController.action = "remount";
        }
    }
    
    func showFixViewForRemount() {
    }


    @IBAction func choseTheme(_ sender: Any) {
        
        if(UserDefaults.standard.bool(forKey: "remountRootFS")) {
            self.performSegue(withIdentifier: "remount", sender: self)
        }
        
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
                statusLabel.stringValue = "Installing Theme..."
                DispatchQueue.global(qos: .background).async {
                    //backupCurrentTheme()
                    
                    print("[INFO:] installing Theme")
                    
                    let themeFolderPathCorrected = path
                    
                    let appInfoArray = getInstalledAppsInfoArray()
                    
                    for app in appInfoArray {
                        
                        do {
                            DispatchQueue.main.async {
                                let expectedIconPath = themeFolderPathCorrected + "/" + getBundleIdentifierOfApplication(path: app[1]) + ".png"
                                print(expectedIconPath)
                                
                                if FileManager.default.fileExists(atPath: expectedIconPath) {
                                    
                                    print("[INFO:] copying Icon for \(app[0])")
                                    //self.statusLabel.stringValue = "copying Icon for \(app[0])"

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
                    DispatchQueue.main.async {
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
    
    @IBOutlet weak var remountState: NSButton!
    @IBOutlet weak var backupbttn: NSButton!
    @IBAction func backup(_ sender: Any) {
        DispatchQueue.main.async {
            self.backupbttn.stringValue = "backing up..."
            backupCurrentTheme()
        }
    }
    
    @IBAction func fixPerm(_ sender: Any) {
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if(UserDefaults.standard.bool(forKey: "remountRootFS")) {
            remountState.state = NSControl.StateValue.on
        } else {
            remountState.state = NSControl.StateValue.off
        }
    }
    
    @IBAction func changeState(_ sender: Any) {
        if(UserDefaults.standard.bool(forKey: "remountRootFS")) {
            UserDefaults.standard.setValue(false, forKey: "remountRootFS");
            remountState.state = NSControl.StateValue.off
        } else {
            UserDefaults.standard.setValue(true, forKey: "remountRootFS");
            remountState.state = NSControl.StateValue.on
        }
    }
}

class updateView: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    
    @IBAction func closeButton(_ sender: Any) {
        self.view.window?.close()
    }
    
}

class FixViewController: NSViewController {
    
    @IBOutlet weak var fixButton: NSButton!
    @IBOutlet weak var fixText: NSTextField!
    @IBOutlet weak var passwordInput: NSSecureTextField!
    @IBOutlet weak var veView: NSVisualEffectView!
    @IBOutlet weak var fixStatusLabel: NSTextField!
    
    @IBAction func cancelFix(_ sender: Any) {
        self.view.window?.windowController?.close()
        self.dismiss(self)
    }
    
    var action = "fix";
    
    func checkPasswordAndFix(password:String) {
        if(authenticateLocalUser(username: NSUserName(), password: password)) {
            if(action == "fix") {
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
                self.dismiss(self)
                remountRootFS(password: password);
            }
        } else {
            self.view.window?.shakeWindow()
            self.dismiss(self)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        veView.isHidden = true;
        
        if(action != "fix") {
            fixText.stringValue = "To remount the rootFS, Vento needs your password. It will not be saved, or send anywhere!"
            fixButton.stringValue = "remount"
        }
    }
    
    @IBAction func applyFix(_ sender: Any) {
        self.checkPasswordAndFix(password: passwordInput.stringValue)
    }
    
    @IBAction func passwordInput(_ sender: Any) {
        self.checkPasswordAndFix(password: passwordInput.stringValue)
    }
}

class restoreDefaults: NSViewController {
    
    @IBOutlet weak var spinningWheel: NSProgressIndicator!
    @IBOutlet weak var statusLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        spinningWheel.startAnimation(self)
        
        let installedAppArray = getInstalledAppsInfoArray()
        DispatchQueue.global(qos: .background).async {
            for i in 0...(installedAppArray.count - 1) {
                var iconName = getApplicationIconName(path: installedAppArray[i][1])
                if !iconName.hasSuffix(".icns") {
                    iconName += ".icns"
                }
                
                print("[INFO:] restoring \(installedAppArray[i][1])")
          
                NSWorkspace.shared.setIcon(NSImage(byReferencing: URL(fileURLWithPath: installedAppArray[i][1] + "/Contents/Resources/\(iconName)")), forFile: installedAppArray[i][1], options: NSWorkspace.IconCreationOptions(rawValue: 0))
            }
            DispatchQueue.main.async {
                self.view.window?.windowController?.close()
            }
        }
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
