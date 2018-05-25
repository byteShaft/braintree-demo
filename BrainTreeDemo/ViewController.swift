//
//  ViewController.swift
//  Donate
//
//  Created by Ziad on 8/7/17.
//  Copyright © 2017 IntensifyStudio. All rights reserved.
//

import UIKit
import BraintreeDropIn
import Braintree

class ViewController: UIViewController {
    
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var donateButton: UIButton! {
        didSet {
            donateButton.imageEdgeInsets = UIEdgeInsets(top: 0, left: -42, bottom: 0, right: 0)
            donateButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: -12, bottom: 0, right: 0)
            donateButton.layer.cornerRadius = donateButton.bounds.midY
            donateButton.layer.masksToBounds = true
        }
    }
    
    @IBOutlet weak var currencyLabel: UILabel! {
        didSet {
            currencyLabel.layer.cornerRadius = currencyLabel.bounds.midY
            currencyLabel.layer.masksToBounds = true
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        amountTextField.becomeFirstResponder()
    }
    
    var toKinizationKey = ""
    
    @IBAction func pay(_ sender: Any) {
        // Test Values
        // Card Number: 4111111111111111
        // Expiration: 08/2018
        getToken()
        
    }
    
    func getToken()
    {
        
        activityIndicator.startAnimating()
        
        let headers = [
            "cache-control": "no-cache",
            "postman-token": "ddc04196-98bf-a622-63b8-ac53512bec31"
        ]
        
        let request = NSMutableURLRequest(url: NSURL(string: "http://138.68.170.85:9000/api/payments/token")! as URL,
                                          cachePolicy: .useProtocolCachePolicy,
                                          timeoutInterval: 10.0)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = headers
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request as URLRequest, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                self.show(message: error!.localizedDescription)
            } else {
                let json = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                self.toKinizationKey = (json!["token"] as? String)!
                self.openDropIn()
            }
        })
        
        dataTask.resume()
        
    }
    
    func openDropIn()
    {
        let request =  BTDropInRequest()
        let dropIn = BTDropInController(authorization: toKinizationKey, request: request)
        { [unowned self] (controller, result, error) in
            
            if let error = error {
                self.show(message: error.localizedDescription)
                
            } else if (result?.isCancelled == true) {
                self.show(message: "Transaction Cancelled")
                
            } else if let nonce = result?.paymentMethod?.nonce, let amount = self.amountTextField.text {
                self.sendRequestPaymentToServer(nonce: nonce, amount: amount)
            }
            controller.dismiss(animated: true, completion: nil)
        }
        
        DispatchQueue.main.async {
            
            self.present(dropIn!, animated: true, completion: nil)
            
        }
        
    }
    
    func sendRequestPaymentToServer(nonce: String, amount: String) {
        activityIndicator.startAnimating()
        // http://138.68.170.85:9000/api/payments/token
        let paymentURL = URL(string: "http://138.68.170.85:9000/api/payments/pay")!
        var request = URLRequest(url: paymentURL)
        request.httpBody = "payment_method_nonce=\(nonce)&amount=\(amount)".data(using: String.Encoding.utf8)
        request.httpMethod = "POST"
        
        URLSession.shared.dataTask(with: request) { [weak self] (data, response, error) -> Void in
            if (error != nil) {
                self?.show(message: error!.localizedDescription)
            } else {
                let json = try! JSONSerialization.jsonObject(with: data!, options: .mutableContainers) as? NSDictionary
                
                if let message = json!["message"] as? String
                {
                    self?.show(message: message)
                }
            }
            
            }.resume()
    }
    
    func show(message: String) {
        DispatchQueue.main.async {
            self.activityIndicator.stopAnimating()
            
            let alertController = UIAlertController(title: message, message: "", preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
            self.present(alertController, animated: true, completion: nil)
        }
    }
}


