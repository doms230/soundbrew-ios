//
//  AccountWebViewController.swift
//  soundbrew
//
//  Created by Dominic  Smith on 6/6/20.
//  Copyright © 2020 Dominic  Smith. All rights reserved.
//

import UIKit
import WebKit
import Alamofire
import SwiftyJSON
import SnapKit
class AccountWebViewController: UIViewController, WKUIDelegate {
    var accountId: String!
    var webView: WKWebView!
    let uiElement = UIElement()
    let color = Color()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .white
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white
        setupDoneButton()
        getAccountLink(accountId)
    }
    
    //MARK: done butotn
    lazy var doneButton: UIButton = {
        let button = UIButton()
        button.setTitle("Done", for: .normal)
        button.addTarget(self, action: #selector(self.didPressDoneButton), for: .touchUpInside)
        button.isOpaque = true
        return button
    }()
    
    func setupDoneButton() {
        self.view.addSubview(doneButton)
        doneButton.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
    }
    
    @objc func didPressDoneButton(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: Account
    func getAccountLink(_ accountId: String) {
        let baseURL = URL(string: "https://www.soundbrew.app/accounts/")
        let url = baseURL!.appendingPathComponent("links")
        let parameters: Parameters = [
            "accountId": accountId]
        
        AF.request(url, method: .post, parameters: parameters, encoding: URLEncoding(destination: .queryString))
            .validate(statusCode: 200..<300)
            .responseJSON { responseJSON in
                switch responseJSON.result {
                case .success(let json):
                    let json = JSON(json)
                    if let url = json["url"].string {
                        print("stripe url: \(url)")
                        self.setupAndShowWebView(url)
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                    
                case .failure(let error):
                    print(error)
                    self.dismiss(animated: true, completion: nil)
                    //self.uiElement.showAlert("Un-Successful", message: error.errorDescription ?? "", target: self)
                }
        }
    }
    
    //MARK: Web view
    func setupAndShowWebView(_ url: String) {
        let linkURL = URL(string: url)
        let myRequest = URLRequest(url: linkURL!)
        let webView = WKWebView()
        webView.load(myRequest)
        webView.uiDelegate = self
        self.view.addSubview(webView)
        webView.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(doneButton.snp.bottom).offset(uiElement.topOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset * 2)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.bottom.equalTo(self.view).offset(uiElement.bottomOffset)
        }
    }
}
