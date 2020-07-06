import UIKit
import Parse
import SnapKit
import Alamofire
import GoogleSignIn

class NewEmailViewController: UIViewController, PFUserAuthenticationDelegate, ArtistDelegate {
    
    let color = Color()
    let uiElement = UIElement()
    
    var loginType: String!
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.view.backgroundColor = color.black()
        navigationController?.navigationBar.barTintColor = color.black()
        navigationController?.navigationBar.tintColor = .white

        switch loginType {
        case "apple":
            if let email = self.appleEmail {
                self.checkIfEmailExistsThenMoveForward(email, authData: self.appleAuthData)
            } else {
                self.PFauthenticateWith(self.appleAuthData)
            }
            
            break
            
        case "google":
            self.checkIfEmailExistsThenMoveForward(self.googleEmail, authData: self.googleAuthData)
            break
            
        default:
            setupNewEmailView()
            break
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let viewController = segue.destination as! NewUsernameViewController
        viewController.emailString = emailText.text!

        var nextTitle: String!
        let localizedUsername = NSLocalizedString("username", comment: "")
        if self.loginType != "email" {
            nextTitle = "\(localizedUsername) | 2/2"
        } else {
            nextTitle = "\(localizedUsername) | 2/3"
        }
        
        let backItem = UIBarButtonItem()
        backItem.title = nextTitle
        navigationItem.backBarButtonItem = backItem
    }
    
    lazy var emailText: UITextField = {
        return self.uiElement.soundbrewTextInput(.emailAddress, isSecureTextEntry: false)
    }()
    
    lazy var emailLabel: UILabel = {
        return self.uiElement.soundbrewLabel("Email", textColor: .white, font: UIFont(name: "\(self.uiElement.mainFont)", size: 17)!, numberOfLines: 1)
    }()
    
    lazy var emailDividerLine: UIView = {
        return self.uiElement.soundbrewDividerLine()
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
        button.addTarget(self, action: #selector(next(_:)), for: .touchUpInside)
        return button
    }()
    
    lazy var nextSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView()
        spinner.color = .white
        spinner.isHidden = true
        return spinner
    }()
    
    func restoreAuthentication(withAuthData authData: [String : String]?) -> Bool {
        return true
    }
    
    func setupNewEmailView() {
        DispatchQueue.main.async {
            let localizedCancel = NSLocalizedString("cancel", comment: "")
            let cancelButton = UIBarButtonItem(title: localizedCancel, style: .plain, target: self, action: #selector(self.didPressCancelButton(_:)))
            self.navigationItem.leftBarButtonItem = cancelButton
            
            if self.loginType != "email" {
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
            
            self.view.addSubview(self.nextSpinner)
            self.nextSpinner.snp.makeConstraints { (make) -> Void in
                make.height.width.equalTo(self.uiElement.buttonHeight / 2)
                make.center.equalTo(self.nextButton)
            }
            
            self.view.addSubview(self.emailLabel)
            self.emailLabel.snp.makeConstraints { (make) -> Void in
                make.width.equalTo(50)
                make.left.equalTo(self.view).offset(self.uiElement.leftOffset)
                make.bottom.equalTo(self.nextButton.snp.top).offset(self.uiElement.bottomOffset * 2)
            }
            
            self.view.addSubview(self.emailText)
            self.emailText.snp.makeConstraints { (make) -> Void in
                make.top.equalTo(self.emailLabel)
                make.left.equalTo(self.emailLabel.snp.right)
                make.right.equalTo(self.view).offset(self.uiElement.rightOffset)
            }
            
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
        if validateEmail(), let email = self.emailText.text {
           let cleanEmail = self.uiElement.cleanUpText(email, shouldLowercaseText: true)
            self.nextButton.setTitle("", for: .normal)
            self.nextSpinner.startAnimating()
            self.nextSpinner.isHidden = false
            checkIfEmailExistsThenMoveForward(cleanEmail, authData: nil)
        }
    }
    
    @objc func didPressCancelButton(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    //apple
    /*var appleID: String?
    var appleName: String?
    var appleToken: String?*/
    var appleEmail: String!
    var appleName: String? 
    var appleAuthData: [String: String]!
    
    //MARK: Google
    var googleName: String?
    var googleEmail: String!
    var googleImage: URL?
    var googleAuthData: [String: String]!
    
    //Validations
    //checking if user exists because apple only gives access to email once *side eyes*, so need to ask for email for 2nd, etc. tries at signing in with apple
   /* func checkIfUserExists(_ userID: String, authToken: String) {
        let query = PFQuery(className: "_User")
        query.whereKey("appleID", equalTo: userID)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                let authData = ["id": userID, "token": authToken]
                self.PFauthenticateWith(authData)
            } else {
                self.setupNewEmailView()
            }
        }
    }*/
    
    func checkIfEmailExistsThenMoveForward(_ email: String, authData: [String: String]?) {
        let localizedEmailAlreadyInUse = NSLocalizedString("emailAlreadyInUse", comment: "")
        let query = PFQuery(className: "_User")
        query.whereKey("email", equalTo: email)
        query.getFirstObjectInBackground {
            (object: PFObject?, error: Error?) -> Void in
            if object != nil && error == nil {
                if let authData = authData {
                    if self.loginType == "google" && object?["googleId"] == nil {
                        GIDSignIn.sharedInstance().signOut()
                        self.showErrorMessageAndDismiss()
                    } else if self.loginType == "apple" && object?["appleID"] == nil {
                        self.showErrorMessageAndDismiss()
                    } else  {
                        self.PFauthenticateWith(authData)
                    }
                    
                } else {
                    self.nextSpinner.stopAnimating()
                    self.nextSpinner.isHidden = true
                    self.nextButton.setTitle("next", for: .normal)
                    self.uiElement.showTextFieldErrorMessage(self.emailText, text: localizedEmailAlreadyInUse)
                }
                
            } else if object == nil {
                if let authData = authData {
                    self.PFauthenticateWith(authData)
                } else {
                    DispatchQueue.main.async {
                        self.performSegue(withIdentifier: "showUsername", sender: self)
                    }
                }
            }
        }
    }
    
    func showErrorMessageAndDismiss() {
        let alertController = UIAlertController (title: "Error" , message: "An account exists with email provided: \(self.googleEmail ?? "email")", preferredStyle: .alert)
        
        let okayAction = UIAlertAction(title: "Okay", style: .default) { (_) -> Void in
            self.dismiss(animated: true, completion: nil)
        }
        alertController.addAction(okayAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func validateEmail() -> Bool {
        let localizedValidEmailRequired = NSLocalizedString("validEmailRequired", comment: "")
        let emailString : NSString = emailText.text! as NSString
        if emailText.text!.isEmpty || !emailString.contains("@") || !emailString.contains(".") {
            self.uiElement.showTextFieldErrorMessage(self.emailText, text: localizedValidEmailRequired)
            return false
        }
        
        return true
    }
    
    //PF authenticate
    func PFauthenticateWith(_ authData:  [String: String]) {
        PFUser.logInWithAuthType(inBackground: self.loginType, authData: authData).continueOnSuccessWith(block: {
            (ignored: BFTask!) -> AnyObject? in
            
            let parseUser = PFUser.current()
            let installation = PFInstallation.current()
            installation?["user"] = parseUser
            installation?["userId"] = parseUser?.objectId
            installation?.saveEventually()
            
            if let isNew = parseUser?.isNew, isNew {
                if self.loginType == "google" {
                    if let image = self.googleImage {
                        self.downloadImageAndUpdateUserInfo(image)
                    } else {
                        self.updateUserInfo(nil)
                    }
                } else if self.loginType == "apple" {
                    self.updateUserInfo(nil)
                }

            } else {
                Customer.shared.getCurrentUserInfo(parseUser!.objectId!)
                DispatchQueue.main.async {
                    self.uiElement.newRootView("Main", withIdentifier: "tabBar")
                }
            }
            return AnyObject.self as AnyObject
        })
    }
    
    func downloadImageAndUpdateUserInfo(_ imageURL: URL) {
        AF.download(imageURL).responseData { response in
            if let data = response.value, let newProfileImageFile = PFFileObject(name: "profile_ios.jpeg", data: data) {
                newProfileImageFile.saveInBackground {
                  (success: Bool, error: Error?) in
                    if let error = error?.localizedDescription {
                        print("dowloading Image error: \(error)")
                    }
                    if success {
                        self.updateUserInfo(newProfileImageFile)
                    } else {
                        self.updateUserInfo(nil)
                    }
                }
            }
        }
    }
    
    func updateUserInfo(_ image: PFFileObject?) {
        if let currentUserId = PFUser.current()?.objectId {
            let query = PFQuery(className: "_User")
            query.getObjectInBackground(withId: currentUserId) {
                (user: PFObject?, error: Error?) -> Void in
                if let error = error {
                    print(error)
                    
                } else if let user = user {
                    if self.loginType == "google" {
                        user["email"] = self.googleEmail
                        user["googleId"] = self.googleAuthData["id"]
                        if let name = self.googleName {
                            user["artistName"] = name
                        }
                        
                    } else {
                        user["email"] = self.appleEmail
                        user["appleID"] = self.appleAuthData["id"]
                        if let name = self.appleName {
                            user["artistName"] = name
                        }
                    }
                    
                    if let image = image {
                        user["userImage"] = image
                    }
                    
                    user.saveEventually {
                        (success: Bool, error: Error?) in
                        self.saveNewArtistInfo(self.uiElement.newArtistObject(user))
                    }
                }
            }
        }
    }
    
    func saveNewArtistInfo(_ artist: Artist) {
        let locale = Locale.current
        if let currencySymbol = locale.currencySymbol, let currencyCode = locale.currencyCode {
            Customer.shared.currencySymbol = currencySymbol
            Customer.shared.currencySymbol = currencyCode.lowercased()
        } else {
            Customer.shared.currencySymbol = "$"
            Customer.shared.currencySymbol = "usd"
        }
        
        Customer.shared.artist = artist
        
        DispatchQueue.main.async {
            let modal = EditProfileViewController()
            modal.artistDelegate = self
            self.present(modal, animated: true, completion: nil)
        }
    }
    
    func changeBio(_ value: String?) {
    }
    
    func receivedArtist(_ value: Artist?) {
        self.uiElement.newRootView("Main", withIdentifier: "tabBar")
    }
    
}
