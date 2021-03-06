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

class GitlabConnector: Connector {
    
    private var baseUrl: String
    
    init(baseUrl: String) {
        self.baseUrl = baseUrl
    }
    
    func createMR(forProject project: String, title: String, body: String, token: String, sourceBranchName: String, targetBranchName: String) throws {
        guard let projectEncoded = project.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
            throw ProcessError.URLError(url: project)
        }
        let urlString = "\(baseUrl)/api/v4/projects/\(projectEncoded)/merge_requests"
        guard let url = URL(string: urlString) else {
            throw ProcessError.URLError(url: urlString)
        }
        
        let sem = DispatchSemaphore.init(value: 0)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(token, forHTTPHeaderField: "Private-Token")
        request.timeoutInterval = 20
        
        let json = [
            "source_branch":sourceBranchName,
            "target_branch":targetBranchName,
            "title":title,
            "description":body,
            "remove_source_branch": "true"
        ]
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: [])
            request.httpBody = jsonData
            
            print("Creating MergeRequest for \(project). Branch \(sourceBranchName) to \(targetBranchName)")
            
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
                            print("MR can be found at \(json["web_url"] ?? "")")
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
