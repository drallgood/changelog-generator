import Foundation
import Dispatch
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class GitUtil {
    
    private var task: Process?
    
    
    func prepareGit(project: Project, noPull: Bool, baseBranch: String, branchName: String?) throws -> URL {
        print("#### Preparing project directory for \(project.title) ####")
        
        var projectPath: URL
        if(project.localPath == nil) {
            projectPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try self.checkoutGitProject(atUrl: project.gitUrl!, atPath: projectPath.path)
        } else  {
            projectPath = URL(fileURLWithPath: project.localPath!, isDirectory: true)
        }
        
        if(!noPull) {
            try self.assertOnCorrectBranchAndUpToDate(atPath: projectPath, branchName: baseBranch)
        }
        
        if(branchName != nil && branchName != "") {
            print("Creating branch \(branchName!)")
            
            
            try self.createBranch(atPath: projectPath, baseBranch: baseBranch, branchName: branchName!)
            try self.switchToBranch(atPath: projectPath, branchName: branchName!)
        }
        return projectPath
    }
    
    func commitChanges(gitUtil: GitUtil, projectPath: URL, branchName: String, message: String, push: Bool, dryRun: Bool = false) throws {
        try gitUtil.commitChanges(atPath: projectPath, message: message)
        
        if(push && !dryRun) {
            print("Pushing changelogs")
            try gitUtil.push(atPath: projectPath, branchName: branchName)
        }
    }
    
    //MARK: Git suboperations
    
    func checkoutGitProject(atUrl url: String, atPath path: String) throws {
        try processInGitShell(["clone",url,path])
        if(ChangelogGenerator.debugEnabled) {
            print("Checked out \(url) to \(path)")
        }
        
    }
    
    func createBranch(atPath path: URL, baseBranch: String, branchName: String) throws {
        try processInGitShell(atPath: path,["branch", branchName, baseBranch])
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
        let process = try gitShell(atPath: path,command)
        task = process
        process.waitUntilExit()
        
        if(process.terminationStatus > 0) {
            throw ProcessError.exited(code: task!.terminationStatus)
        }
        task = nil
    }
    
    private func gitShell(atPath path:URL? = nil,_ command: [String]) throws -> Process {
        let process = Process()
        if(ChangelogGenerator.debugEnabled) {
            print("Executing: \(ChangelogGenerator.config.gitExecutablePath) \(command)")
        }
        process.arguments = command
        if(path != nil) {
            process.currentDirectoryURL = path
        }
        
        if(!ChangelogGenerator.debugEnabled) {
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
        }
        process.executableURL = URL(string: "file://\(ChangelogGenerator.config.gitExecutablePath)")
        try process.run()
        return process
    }
    
    func extractProjectName(_ gitUrl: String) -> String? {
        let sanitizedUrl = gitUrl.replacingOccurrences(of: ".git", with: "")
        if(sanitizedUrl.starts(with: "http")) {
            
            guard let url = URL(string: sanitizedUrl) else {
                return nil
            }
            let pathComponents = url.pathComponents
            let numOfComponents = pathComponents.count
            if (numOfComponents >= 2) {
                return "\(pathComponents[numOfComponents-2])/\(pathComponents[numOfComponents-1])"
            }
        } else {
            let pathComponents = sanitizedUrl.split(separator: ":")
            let numOfComponents = pathComponents.count
            if (numOfComponents >= 2) {
                return "\(pathComponents[numOfComponents-1])"
            }
        }
        return nil
    }
    
    
    
    func terminate() {
        self.task?.terminate()
    }
}
