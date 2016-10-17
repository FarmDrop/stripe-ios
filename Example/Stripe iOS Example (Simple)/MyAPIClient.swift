//
//  BackendAPIAdapter.swift
//  Stripe iOS Example (Simple)
//
//  Created by Ben Guo on 4/15/16.
//  Copyright © 2016 Stripe. All rights reserved.
//

import Foundation
import Stripe

class MyAPIClient: NSObject, STPBackendAPIAdapter {
    
    static let sharedClient = MyAPIClient()
    let session: URLSession
    var baseURLString: String? = nil
    var defaultSource: STPCard? = nil
    var sources: [STPCard] = []
    
    override init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 5
        self.session = URLSession(configuration: configuration)
        super.init()
    }
    
    func decodeResponse(_ response: URLResponse?, error: NSError?) -> NSError? {
        if let httpResponse = response as? HTTPURLResponse
            , httpResponse.statusCode != 201 && httpResponse.statusCode != 200  {
            return error ?? NSError.networkingError(httpResponse.statusCode)
        }
        return error
    }
    
    func completeCharge(_ result: STPPaymentResult, amount: Int, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set baseURLString to your Heroku URL in CheckoutViewController.swift"
                ])
            completion(error)
            return
        }
        //let path = "charge"
        let path = "2/orders/2671073/confirm"
        let url = baseURL.appendingPathComponent(path)
        let params: [String: AnyObject] = [
            "source" :  "ios app"  as AnyObject
            //"source": result.source.stripeID as AnyObject,
            //"amount": amount as AnyObject
        ]
        var request = URLRequest.request(url, method: .PUT, params: [:])
        request.setValue("kq-K3RYNtWprasxNEH5x", forHTTPHeaderField: "X-User-Token")
        request.setValue("test4@farmdrop.com", forHTTPHeaderField: "X-User-Email")
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func retrieveCustomer(_ completion: @escaping STPCustomerCompletionBlock) {
        guard let key = Stripe.defaultPublishableKey() , !key.contains("#") else {
            let error = NSError(domain: StripeDomain, code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Please set stripePublishableKey to your account's test publishable key in CheckoutViewController.swift"
                ])
            completion(nil, error)
            return
        }
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            // This code is just for demo purposes - in this case, if the example app isn't properly configured, we'll return a fake customer just so the app works.
            let customer = STPCustomer(stripeID: "cus_test", defaultSource: self.defaultSource, sources: self.sources)
            completion(customer, nil)
            return
        }
        let path = "1/stripe_payment_sources"
        let url = baseURL.appendingPathComponent(path)
        
        var request = URLRequest.request(url, method: .GET, params: [:])
        request.setValue("kq-K3RYNtWprasxNEH5x", forHTTPHeaderField: "X-User-Token")
        request.setValue("test4@farmdrop.com", forHTTPHeaderField: "X-User-Email")
        
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                let deserializer = STPCustomerDeserializer(data: data, urlResponse: urlResponse, error: error)
                if let error = deserializer.error {
                    completion(nil, error)
                    return
                } else if let customer = deserializer.customer {
                    completion(customer, nil)
                }
            }
        }
        task.resume()
    }
    
    @objc func selectDefaultCustomerSource(_ source: STPSource, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken {
                self.defaultSource = token.card
            }
            completion(nil)
            return
        }
        let path = "1/stripe_payment_sources"
        let url = baseURL.appendingPathComponent(path)
        let params = [
            "default_source": source.stripeID,
            ]
        var request = URLRequest.request(url, method: .POST, params: [:])
        request.setValue("kq-K3RYNtWprasxNEH5x", forHTTPHeaderField: "X-User-Token")
        request.setValue("test4@farmdrop.com", forHTTPHeaderField: "X-User-Email")
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        
        let jsonData = try? JSONSerialization.data(withJSONObject: params, options: .prettyPrinted)
        request.httpBody = jsonData
        
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
    @objc func attachSource(toCustomer source: STPSource, completion: @escaping STPErrorBlock) {
        guard let baseURLString = baseURLString, let baseURL = URL(string: baseURLString) else {
            if let token = source as? STPToken, let card = token.card {
                self.sources.append(card)
                self.defaultSource = card
            }
            completion(nil)
            return
        }
        //let path = "/customer/sources"
        let path = "1/stripe_payment_sources"
        let url = baseURL.appendingPathComponent(path)
        let params: Dictionary<String, AnyObject> = [
            "token": source.stripeID as AnyObject,
            ]
        var request = URLRequest.request(url, method: .POST, params: params)
        request.setValue("kq-K3RYNtWprasxNEH5x", forHTTPHeaderField: "X-User-Token")
        request.setValue("test4@farmdrop.com", forHTTPHeaderField: "X-User-Email")
        let task = self.session.dataTask(with: request) { (data, urlResponse, error) in
            
            if let d = data {
                let json = try? JSONSerialization.jsonObject(with: d, options: .mutableContainers)
                print("json: \(json)")
            }
            
            
            //id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            DispatchQueue.main.async {
                if let error = self.decodeResponse(urlResponse, error: error as NSError?) {
                    completion(error)
                    return
                }
                completion(nil)
            }
        }
        task.resume()
    }
    
}
