//
//  RegisterViewController.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import UIKit
import FirebaseAuth

class RegisterViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        if let nav = navigationController {
                nav.popViewController(animated: true)
            } else {
                dismiss(animated: true, completion: nil)
            }
    }
    
    @IBAction func registerButtonTapped(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "請輸入帳號和密碼")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { result,error in
            if let error = error {
                self.showAlert(message: "註冊失敗")
            }else{
                self.showAlert(message: "註冊成功") {
                    self.dismiss(animated: true)
                }
            }
        }
    }
    
    //message 是要顯示的訊息文字
    func showAlert(message: String, completion: (() -> Void)? = nil) {
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default) { _ in
            completion?()
        })
        present(alert, animated: true)
    }
    
}
