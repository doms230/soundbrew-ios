import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit
import TwitterKit
import AuthenticationServices


class NewEmailViewController: UIViewController, NVActivityIndicatorViewable, PFUserAuthenticationDelegate, ASAuthorizationControllerDelegate {
    let color = Color()
    let uiElement = UIElement()
    
    var isLoggingInWithTwitter = false
    var isLoggingInWithApple = false
    
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white

        if isLoggingInWithTwitter {
            loginWithTwitter()
        } else if isLoggingInWithApple {
            loginWithApple()
        } else {
            setupNewEmailView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewUsernameViewController
        if self.twitterID != nil {
            prepareTwitterVariables(viewController)
        } else {
            prepareAppleVariables(viewController)
        }

        var nextTitle: String!
        let localizedUsername = NSLocalizedString("username", comment: "")
        if authToken != nil {
            nextTitle = "\(localizedUsername) | 2/2"
        } else {
            nextTitle = "\(localizedUsername) | 2/3"
        }
        
        let backItem = UIBarButtonItem()
        backItem.title = nextTitle
        navigationItem.backBarButtonItem = backItem
    }
    
    lazy var titleLabel: UILabel = {
        let localizedPayPalPayoutMessage = NSLocalizedString("payPalPayoutMessage", comment: "")
        let label = UILabel()
        label.font = UIFont(name: "\(uiElement.mainFont)", size: 15)
        label.text = localizedPayPalPayoutMessage
        label.textColor = .white
        label.numberOfLines = 0
        return label
    }()
    
    lazy var emailText: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Email"
        textField.font = UIFont(name: uiElement.mainFont, size: 17)
        textField.backgroundColor = .white
        textField.borderStyle = .roundedRect
        textField.clearButtonMode = .whileEditing
        textField.keyboardType = .emailAddress
        textField.tintColor = color.black()
        textField.textColor = color.black()
        textField.attributedPlaceholder = NSAttributedString(string: "Email",
        attributes: [NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        return textField
    }()
    
    lazy var nextButton: UIButton = {
        let localizedNext = NSLocalizedString("next", comment: "")
        let button = UIButton()
        button.setTitle(localizedNext, for: .normal)
        button.titleLabel?.font = UIFont(name: uiElement.mainFont, size: 17)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.textAlignment = .right
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        button.setBackgroundImage(UIImage(named: "background"), for: .normal)
        return button
    }()
    
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    func setupNewEmailView() {
        let localizedCancel = NSLocalizedString("cancel", comment: "")
        let cancelButton = UIBarButtonItem(title: localizedCancel, style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        if authToken != nil {
            self.title = "Email | 1/2"
        } else {
            self.title = "Email | 1/3"
        }
        
        self.view.addSubview(titleLabel)
        self.view.addSubview(emailText)
        self.view.addSubview(nextButton)
        nextButton.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        
        emailText.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(self.view).offset(uiElement.uiViewTopOffset(self))
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        nextButton.snp.makeConstraints { (make) -> Void in
            make.height.equalTo(uiElement.buttonHeight)
            make.top.equalTo(emailText.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        titleLabel.snp.makeConstraints { (make) -> Void in
            make.top.equalTo(nextButton.snp.bottom).offset(uiElement.topOffset)
            make.left.equalTo(self.view).offset(uiElement.leftOffset)
            make.right.equalTo(self.view).offset(uiElement.rightOffset)
        }
        
        emailText.becomeFirstResponder()
    }
    
    @objc func next(_ sender: UIButton){
        emailText.text = self.uiElement.cleanUpText(emailText.text!, shouldLowercaseText: true)
        if validateEmail() {
            checkIfEmailExistsThenMoveForward()
        }
    }
    
    //MARK: Validate jaunts
    func validateEmail() -> Bool {
        let localizedValidEmailRequired = NSLocalizedString("validEmailRequired", comment: "")
        let emailString : NSString = emailText.text! as NSString
        if emailText.text!.isEmpty || !emailString.contains("@") || !emailString.contains(".") {
            self.uiElement.showTextFieldErrorMessage(self.emailText, text: localizedValidEmailRequired)
            return false
        }
        
        return true
    }
    
    func checkIfEmailExistsThenMoveForward() {
        let localizedEmailAlreadyInUse = NSLocalizedString("emailAlreadyInUse", comment: "")
        startAnimating()
        let query = PFQuery(className: "_User")
        query.whereKey("email", equalTo: emailText.text!)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            self.stopAnimating()
            if object != nil && error == nil {
                self.uiElement.showTextFieldErrorMessage(self.emailText, text: localizedEmailAlreadyInUse)
            
            } else if object == nil {
                self.performSegue(withIdentifier: "showUsername", sender: self)
            }
        }
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //login with logic
    func checkIfUserExists(_ loginInService: String, userID: String, authToken: String?, authTokenSecret: String?, username: String?) {
        let query = PFQuery(className: "_User")
        if loginInService == "twitter" {
            query.whereKey("twitterID", equalTo: userID)
        } else {
            query.whereKey("appleID", equalTo: userID)
        }
        
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                self.PFauthenticateWith(loginInService, userId: userID, auth_token: authToken!, auth_token_secret: authTokenSecret!, username: username)
            } else {
                self.stopAnimating()
                self.setupNewEmailView()
            }
        }
    }
    
    func PFauthenticateWith(_ loginService: String, userId: String, auth_token: String, auth_token_secret: String, username: String?) {
        
        var authData: [String: String]

        if loginService == "twitter" {
            authData = ["id": userId, "auth_token": auth_token, "consumer_key": "shY1N1YKquAcxJF9YtdFzm6N3", "consumer_secret": "dFzxXdA0IM9A7NsY3JzuPeWZhrIVnQXiWFoTgUoPVm0A2d1lU1", "auth_token_secret": auth_token_secret ]
        } else {
            authData = ["id": userId]
        }
         
        PFUser.logInWithAuthType(inBackground: loginService, authData: authData).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            Customer.shared.getCustomer(parseUser!.objectId!)
            self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            return AnyObject.self as AnyObject
        })
    }
    
    //MARK: TWITTER
    var authTokenSecret: String?
    var twitterUsername: String?
    var twitterID: String?
    var authToken: String?
    
    func prepareTwitterVariables(_ viewController: NewUsernameViewController) {
        viewController.emailString = emailText.text!
        viewController.authToken = self.authToken
        viewController.authTokenSecret = self.authTokenSecret
        viewController.twitterID = self.twitterID
        viewController.twitterUsername = self.twitterUsername
    }
    
    func loginWithTwitter() {
        self.startAnimating()
        let store = TWTRTwitter.sharedInstance().sessionStore
        if let session = store.session() {
            store.logOutUserID(session.userID)
        }
        
        TWTRTwitter.sharedInstance().logIn(completion: { (session, error) in
            if let session = session {
                self.twitterID = session.userID
                self.authToken = session.authToken
                self.authTokenSecret = session.authTokenSecret
                self.twitterUsername = session.userName
                self.checkIfUserExists("twitter", userID: session.userID, authToken: session.authToken, authTokenSecret: session.authTokenSecret, username: session.userName)
                
            } else if let error = error {
                print("error: \(error.localizedDescription)");
                self.stopAnimating()
                self.dismiss(animated: true, completion: nil)
            }
        })
    }
    
    //apple
    var appleID: String?
    var appleName: String?
    
    func prepareAppleVariables(_ viewController: NewUsernameViewController) {
        viewController.appleID = self.appleID
        if let name = self.appleName {
            viewController.appleName = name
        }
    }
    
    func loginWithApple() {
        if #available(iOS 13.0, *) {
            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            //controller.presentationContextProvider = (self as! ASAuthorizationControllerPresentationContextProviding)
            controller.performRequests()
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        switch authorization.credential {
        case let appleIDCredential as ASAuthorizationAppleIDCredential:
            let appleID = appleIDCredential.user
            self.appleID = appleID
            
            if let name = appleIDCredential.fullName?.givenName {
                self.appleName = name
            }
            
            if let email = appleIDCredential.email {
                self.emailText.text = email
            }
            
            self.checkIfUserExists("apple", userID: appleID, authToken: nil, authTokenSecret: nil, username: nil)
            
            break
        default:
            break
        }
    }
    
    @available(iOS 13.0, *)
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        print(error)
        self.dismiss(animated: true, completion: nil)
    }
}
