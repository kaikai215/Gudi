//
//  LoginViewController.swift
//  Gudi
//
//  Created by 林聖凱 on 2025/6/26.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController {
    
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
    
    override func viewWillAppear(_ animated: Bool){
        super.viewWillAppear(animated)
        emailTextField.text = ""
        passwordTextField.text = ""
    }
    func showAlert(message: String){
        let alert = UIAlertController(title: "提示", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "好", style: .default))
        present(alert, animated: true)
    }


    
    @IBAction func loginButton(_ sender: Any) {
        guard let email = emailTextField.text, !email.isEmpty,
              let password = passwordTextField.text, !password.isEmpty else {
            showAlert(message: "請輸入帳號與密碼")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("❌ 登入失敗：\(error.localizedDescription)")
                self.showAlert(message: "登入失敗")
                return
            }
            
            DispatchQueue.main.async {
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                // ⚠️ 這邊要記得設定 Storyboard ID 為 "MainTabBarController"
                guard let tabBarController = storyboard.instantiateViewController(withIdentifier: "MainTabBarController") as? UITabBarController else {
                    print("❌ 找不到 MainTabBarController")
                    return
                }
                
                // 選擇第一個 tab (HomeViewController)，並傳遞 userEmail
                if let nav = tabBarController.viewControllers?.first as? UINavigationController,
                   let homeVC = nav.topViewController as? HomeViewController {
                    homeVC.userEmail = email
                }
                
                // 設為 rootViewController
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let sceneDelegate = scene.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    window.rootViewController = tabBarController
                    window.makeKeyAndVisible()
                }
            }
        }
    }
}
