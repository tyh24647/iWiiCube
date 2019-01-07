///
///  WebBrowserViewController
///
///  Created by Tyler Hostager on 1/7/19.
///  Copyright © 2019 Tyler Hostager. All rights reserved.
///

import UIKit
import WebKit
import SafariServices

extension SFSafariViewController {
    public func mainUIView() -> UIView {
        return super.view!
    }
}

class WebBrowserViewController: UIViewController, UITextFieldDelegate, SFSafariViewControllerDelegate, UINavigationBarDelegate {
    @IBOutlet var searchTF: UITextField!
    @IBOutlet var cancelButton: UIButton!
    @IBOutlet var webView: WKWebView!
    //@IBOutlet var webView: UIView!
    @IBOutlet var navBar: UINavigationBar!

    ///
    override func viewWillLayoutSubviews() {
        searchTF.delegate = self
        navBar.delegate = self
        
        if self.searchTF.isEnabled && !cancelButton.isHidden {
            cancelButton.isHidden = true
        }
    }
    
    
    ///
    ///
    /// - Parameter animated:
    override func viewWillAppear(_ animated: Bool) {
        if cancelButton.isHidden {
            hideCancelBtn(searchTF)
        }
        
        //webView = SFSafariViewController(url: URL(string: "http://www.google.com/")!).view
        let webCoder = NSCoder()
        let webkitConfiguration = WKWebViewConfiguration(coder: webCoder)!
        webkitConfiguration.allowsAirPlayForMediaPlayback = true
        webkitConfiguration.allowsInlineMediaPlayback = true
        webkitConfiguration.allowsPictureInPictureMediaPlayback = true
        webkitConfiguration.applicationNameForUserAgent = "iWiiCube"
        webkitConfiguration.dataDetectorTypes = .all
        webkitConfiguration.ignoresViewportScaleLimits = true
        webkitConfiguration.mediaTypesRequiringUserActionForPlayback = [ .video, .audio ]
        webkitConfiguration.preferences = { () -> WKPreferences in
            var _ = WKPreferences.init()
            _.javaScriptEnabled = true
            _.minimumFontSize = 8.0
            _.javaScriptCanOpenWindowsAutomatically = false
            return _
        }
        
        
        webView = WKWebView(frame: super.view.frame, configuration: WKWebViewConfiguration)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

    @IBAction func searchTFDidBeginEditing(_ sender: Any) {
        showCancelBtn(searchTF)
    }
    
    @IBAction func searchTFSelected(_ sender: Any) {
        showCancelBtn(searchTF)
    }
    
    @IBAction func searchTFDidEndEditing(_ sender: Any) {
        hideCancelBtn(searchTF)
    }
    
    @IBAction func searchTFReturnActionTriggered(_ sender: Any) {
        searchTFDidEndEditing(sender)
        updateFocusIfNeeded()
        
        if let url = URL(string: searchTF.text ?? "http://www.google.com/") {
            var tmp: SFSafariViewController!
            tmp = SFSafariViewController(url: url)
            
            var config: NSObject!
            tmp.configuration.barCollapsingEnabled = true
            tmp.configuration.entersReaderIfAvailable = false
            config = tmp.configuration
            
            let webView = SFSafariViewController(url: url, configuration: config as! SFSafariViewController.Configuration)
            self.webView.addSubview(webView.view)
            self.webView.autoresizesSubviews = true
            present(webView, animated: false)
        }
        
        
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        searchTFReturnActionTriggered(textField)
        return true
    }
    
    func showTutorial(_ which: Int) {
        if let url = URL(string: "https://www.hackingwithswift.com/read/\(which + 1)") {
            let config = SFSafariViewController.Configuration()
            config.entersReaderIfAvailable = true
            
            let vc = SFSafariViewController(url: url, configuration: config)
            present(vc, animated: true)
        }
    }
    
    func showCancelBtn(_ sender: Any) -> Void {
        toggleHideCancelBtn(sender, shouldHide: false)
    }
    
    func hideCancelBtn(_ sender: Any) -> Void {
        toggleHideCancelBtn(sender, shouldHide: true)
    }
    
    func toggleHideCancelBtn(_ sender: Any, shouldHide: Bool) -> Void {
        
        if let tf: UITextField = sender as? UITextField, tf == searchTF {
            cancelButton.isHidden = shouldHide
        }
        
        searchTF.sizeToFit()
    }
    
    @IBAction func cancelBtnPressed(_ sender: Any) {
        searchTFDidEndEditing(sender)
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
