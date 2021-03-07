import Foundation

extension Process {
    
    private static let gitExecURL = URL(fileURLWithPath: "/usr/bin/git")
    
    public func clone(repo: String, path: String) throws {
        executableURL = Process.gitExecURL
        arguments = ["clone", repo, path]
        try run()
    }
    
    public func createBranch(atPath path: URL, branchName: String) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["branch", branchName, "master"]
        try run()
    }
    
    public func switchToBranch(atPath path: URL, branchName: String) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["checkout", branchName]
        try run()
    }
    
    public func gitAdd(atPath path: URL, toAdd added: String) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["add", added]
        try run()
    }
    
    public func gitCommit(atPath path: URL, message: String) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["commit","-m", message]
        try run()
    }
    
    public func gitPush(atPath path: URL, branchName: String) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["push","--set-upstream","origin",branchName]
        try run()
    }
    
    public func gitPull(atPath path: URL) throws {
        currentDirectoryURL = path
        executableURL = Process.gitExecURL
        arguments = ["pull"]
        try run()
    }
}
