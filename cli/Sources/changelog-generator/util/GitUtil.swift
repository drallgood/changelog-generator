import Foundation
import Dispatch
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class GitUtil {
    
    private var task: Process?
    
    func checkoutGitProject(atUrl url: String, atPath path: String) throws {
        try processInGitShell(["clone",url,path])
        print("Checked out \(url) to \(path)")
    }
    
    func createBranch(atPath path: URL, branchName: String) throws {
        try processInGitShell(atPath: path,["branch", branchName, "master"])
    }
    
    func assertOnCorrectBranchAndUpToDate(atPath path: URL, branchName: String) throws {
        try switchToBranch(atPath: path, branchName: branchName)
        try pull(atPath: path)
    }
    
    func switchToBranch(atPath path: URL, branchName: String) throws {
        try  processInGitShell(atPath: path,["checkout", branchName])
    }
    
    func commitChanges(atPath path: URL, message: String) throws {
        try processInGitShell(atPath: path, ["add", "."])
        try processInGitShell(atPath: path, ["commit","-m", message])
    }
    
    func pull(atPath path: URL) throws {
        try processInGitShell(atPath: path,["pull"])
    }
    
    func push(atPath path: URL, branchName: String) throws {
        try processInGitShell(atPath: path,["push","--set-upstream","origin",branchName])
    }
    
    private func processInGitShell(atPath path:URL? = nil,_ command: [String]) throws {
        let process = gitShell(atPath: path,command)
        task = process
        process.waitUntilExit()
        
        if(process.terminationStatus > 0) {
            throw ProcessError.exited(code: task!.terminationStatus)
        }
        task = nil
    }
    
    private func gitShell(atPath path:URL? = nil,_ command: [String]) -> Process {
        let process = Process()
        print("Executing: \(command)")
        process.arguments = command
        if(path != nil) {
            process.currentDirectoryURL = path
        }
        process.launchPath = ChangelogGenerator.config.gitExecutablePath
        process.launch()
        return process
    }
    
    func terminate() {
        self.task?.terminate()
    }
}
