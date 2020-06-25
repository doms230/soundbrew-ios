import UIKit
import Parse
import NVActivityIndicatorView
import SnapKit
import AuthenticationServices


class NewEmailViewController: UIViewController, NVActivityIndicatorViewable, PFUserAuthenticationDelegate, ASAuthorizationControllerDelegate {
    let color = Color()
    let uiElement = UIElement()
    
    var isLoggingInWithApple = false
    var authToken: String!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white

        if isLoggingInWithApple {
            loginWithApple()
        } else {
            setupNewEmailView()
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewUsernameViewController
        viewController.emailString = emailText.text!
        prepareAppleVariables(viewController)

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
    
    var emailText: UITextField!
    var emailLabel: UILabel!
    var emailDividerLine: UIView!
    
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
        button.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        return button
    }()
    
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    func setupNewEmailView() {
        DispatchQueue.main.async {
            let localizedCancel = NSLocalizedString("cancel", comment: "")
            let cancelButton = UIBarButtonItem(title: localizedCancel, style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
            self.navigationItem.leftBarButtonItem = cancelButton
            
            if self.authToken != nil {
                self.title = "Email | 1/2"
            } else {
                self.title = "Email | 1/3"
            }
            
            self.view.addSubview(self.nextButton)
            self.nextButton.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(self.uiElement.buttonHeight)
                make.centerY.equalTo(self.view)
                make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
                make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            }
            
            self.emailLabel = self.uiElement.soundbrewLabel("Email", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
            self.view.addSubview(self.emailLabel)
            self.emailLabel.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(50)
                make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
                make.bottom.equalTo(self.nextButton.snp.top).offset(self.uiElement.bottomOffset * 2)
            }
            
            self.emailText = self.uiElement.soundbrewTextInput(.emailAddress, isSecureTextEntry: false)
            self.view.addSubview(self.emailText)
            self.emailText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.emailLabel)
                make.left.equalTo(self.emailLabel.snp.right)
                make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            }
            
            self.emailDividerLine = self.uiElement.soundbrewDividerLine()
            self.view.addSubview(self.emailDividerLine)
            self.emailDividerLine.snp.makeConstraints { (make) -> Void in
                make.height.equalTo(0.5)
                make.top.equalTo(self.emailText.snp.bottom)
                make.left.equalTo(self.emailText)
                make.right.equalTo(self.emailText)
            }
            
            self.emailText.becomeFirstResponder()
        }
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
                DispatchQueue.main.async {
                    self.performSegue(withIdentifier: "showUsername", sender: self)
                }
            }
        }
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //login with logic
    //checking if user exists because apple only gives access to email once *side eyes*, so need to ask for email for 2nd, etc. tries at signing in with apple
    func checkIfUserExists(_ loginInService: String, userID: String, authToken: String, authTokenSecret: String?, username: String?) {
        let query = PFQuery(className: "_User")
        query.whereKey("appleID", equalTo: userID)
        
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                self.PFauthenticateWith(loginInService, userId: userID, auth_token: authToken, auth_token_secret: authTokenSecret, username: username)
                
            } else {
                self.stopAnimating()
                self.setupNewEmailView()
            }
        }
    }
    
    func PFauthenticateWith(_ loginService: String, userId: String, auth_token: String, auth_token_secret: String?, username: String?) {
        
        var authData: [String: String]

        authData = ["id": userId, "token": auth_token]
         
        PFUser.logInWithAuthType(inBackground: loginService, authData: authData).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            Customer.shared.getCustomer(parseUser!.objectId!)
            DispatchQueue.main.async {
                self.uiElement.newRootView("Main", withIdentifier: "tabBar")
            }
            return AnyObject.self as AnyObject
        })
    }
    
    //apple
    var appleID: String?
    var appleName: String?
    var appleToken: String?
    
    func prepareAppleVariables(_ viewController: NewUsernameViewController) {
        viewController.appleID = self.appleID
        viewController.appleToken = self.appleToken
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
            self.appleToken = String(data: appleIDCredential.identityToken!, encoding: .utf8)
            
            if let name = appleIDCredential.fullName?.givenName {
                self.appleName = name
            }
            
            if let email = appleIDCredential.email {
                self.emailText.text = email
            }
            
            self.checkIfUserExists("apple", userID: appleID, authToken: self.appleToken!, authTokenSecret: nil, username: nil)
            
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
