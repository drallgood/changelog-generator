import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class GitUtil {
    static func checkoutGitProject(atUrl url: String, atPath path: String) {
        let process = Process()
        try! process.clone(repo: url, path: path)
        process.waitUntilExit()
        
        print("Checked out \(url) to \(path)")
    }
    
    static func createBranch(atPath path: URL, branchName: String) {
        let process = Process()
        try! process.createBranch(atPath: path, branchName: branchName)
        process.waitUntilExit()
    }
    
    static func assertOnCorrectBranchAndUpToDate(atPath path: URL, branchName: String) {
        GitUtil.switchToBranch(atPath: path, branchName: branchName)
        GitUtil.pull(atPath: path)
    }
    
    static func switchToBranch(atPath path: URL, branchName: String) {
        let process = Process()
        try! process.switchToBranch(atPath: path, branchName: branchName)
        process.waitUntilExit()
    }
    
    static func commitChanges(atPath path: URL, message: String) {
        let process = Process()
        try! process.gitAdd(atPath: path, toAdd: ".")
        process.waitUntilExit()
        
        let process2 = Process()
        try! process2.gitCommit(atPath: path, message: message)
        process2.waitUntilExit()
    }
    
    static func pull(atPath path: URL) {
        let process = Process()
        try! process.gitPull(atPath: path)
        process.waitUntilExit()
    }
    
    static func push(atPath path: URL, branchName: String) {
        let process = Process()
        try! process.gitPush(atPath: path, branchName: branchName)
        process.waitUntilExit()
    }
}
