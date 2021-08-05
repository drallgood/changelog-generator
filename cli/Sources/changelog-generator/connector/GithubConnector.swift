//
//  File.swift
//  
//
//  Created by Patrice on 3/7/21.
//

import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class GithubConnector: Connector {
    private var baseUrl: String
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func createMR(forProject project: String, release: String, token: String, sourceBranchName: String, targetBranchName: String) throws {

        let urlString = "\(baseUrl)/repos/\(project)/pulls"
        guard let url = URL(string: urlString) else {
            throw ProcessError.URLError(url: urlString)
        }
        
        let sem = DispatchSemaphore.init(value: 0)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Accept", forHTTPHeaderField: "application/vnd.github.v3+json")
        request.setValue(token, forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 20
        
        let json = [
            "head":sourceBranchName,
            "base":targetBranchName,
            "title":"Merge changelog for \(release) to \(targetBranchName)",
            "body":"Generated changelog for \(release). Branch \(sourceBranchName) to \(targetBranchName)",
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = jsonData
            
            print("Creating Pull Request for \(project). Branch \(sourceBranchName) to \(targetBranchName)")
            
            let task = URLSession.shared.dataTask(with: request) { data, response, error in
                defer { sem.signal() }
                // Check if the response has an error
                if error != nil{
                    print("Error \(String(describing: error))")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse{
                    if httpResponse.statusCode != 201{
                        print("Got \(httpResponse.statusCode)")
                        return
                    }
                }
                
                if let data = data {
                    do {
                        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                            print("MR can be found at \(json["html_url"] ?? "")")
                        }
                    } catch {
                        print(error)
                    }
                }
                
            }
            task.resume()
            // This line will wait until the semaphore has been signaled
            // which will be once the data task has completed
            sem.wait()
        } catch {
            print("Error creating MR: \(error.localizedDescription)")
        }
    }
}
