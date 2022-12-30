//
//  PushNotificationSender.swift

import Foundation
import UIKit
class PushNotificationSender {
    private let serverKey:String = "" // This get from fcm
    func sendPushNotification(_ data:NSDictionary, registrationIds:[String]) {
        let urlString = "https://fcm.googleapis.com/fcm/send"
        let url = NSURL(string: urlString)!
        let paramString: [String : Any] = ["registration_ids" : registrationIds,
                                           "notification" : [
                                                                "title" : data["title"],
                                                                "body" : data["body"],
                                                                "content_available" : false,
                                                                "badge":data["badgeCount"],
                                                                "sound":"newMessage.wav"
                                                            ],
                                           "data" : [
                                                        "priority" : "high",
                                                        "conversationId":data["conversationId"]
                                                    ]
        ]
        //print(paramString);
        let request = NSMutableURLRequest(url: url as URL)
        request.httpMethod = "POST"
        request.httpBody = try? JSONSerialization.data(withJSONObject:paramString, options: [.prettyPrinted])
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("key=\(serverKey)", forHTTPHeaderField: "Authorization")
        let task =  URLSession.shared.dataTask(with: request as URLRequest)  { (data, response, error) in
            do {
                if let jsonData = data {
                    if let jsonDataDict  = try JSONSerialization.jsonObject(with: jsonData, options: JSONSerialization.ReadingOptions.allowFragments) as? [String: AnyObject] {
                        NSLog("Received data:\n\(jsonDataDict))")
                    }
                }
            } catch let err as NSError {
                print(err.debugDescription)
            }
        }
        task.resume()
    }
}
