import ArgumentParser
import Foundation

struct GenerateAllCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "generate-all", abstract: "Generate Changelogs for all projects")
    
    @Argument(help: "The name of the release, e.g. 8.0-IT-32")
    private var release: String
    
    @Flag(name: [.customShort("p"), .long], help: "Push")
    private var push: Bool = false
    
    @Flag(name: [.customShort("m"), .long], help: "Create merge request")
    private var createMR: Bool = false
    
    @Flag(name: [.customShort("d"), .long], help: "Don't delete git project when finished")
    private var noDelete: Bool = false
    
    @Option(name: [.customShort("t"), .long], help: "Gitlab personal token (needed for merge request operations)")
    private var gitlabToken: String?
    
    mutating func validate() throws {
        guard !createMR || (createMR && gitlabToken != nil) else {
            throw ValidationError("Please specify a 'gitlab-token'")
        }
    }
    
    func run() throws {
        let configFile = ChangelogGenerator.configFile
        let connector = GitlabConnector()
        print("Using \(configFile ?? "nil")")
        if( configFile != nil) {
            if let localData = ConfigUtil.readConfigFile(fromPath: configFile!) {
                let branchName = "CL-\(release)"
                let fileManager = FileManager.default
                let projects = ConfigUtil.parse(jsonData: localData)
                projects.forEach  { (project) in
                    do {
                        let projectPath = prepareGit(project: project, branchName: branchName)
                        try generateChangelog(projectPath: projectPath)
                        commitChanges(projectPath: projectPath, branchName: branchName)
                        
                        if(createMR) {
                            guard let projectName = extractProjectName(project.gitUrl!) else {
                                print("ERROR: couldn't extract project name from \(project.gitUrl!)")
                                return
                            }
                            connector.createMR(forProject: projectName, release: release,token: gitlabToken!, sourceBranchName: branchName, targetBranchName: "master")
                        }
                        
                        if(!noDelete) {
                            try fileManager.removeItem(at: projectPath)
                        }
                    } catch {
                        print("Error when generating \(project.title): \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    private func prepareGit(project: Project, branchName: String) -> URL {
        print("Checking out git project for \(project.title)")
        
        var projectPath: URL
        if(project.localPath == nil) {
            projectPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        } else  {
            projectPath = URL(fileURLWithPath: project.localPath!)
        }
        
        GitUtil.checkoutGitProject(atUrl: project.gitUrl!, atPath: projectPath.path)
        
        print("Creating branch for \(release)")
        
        GitUtil.createBranch(atPath: projectPath, branchName: branchName)
        GitUtil.switchToBranch(atPath: projectPath, branchName: branchName)
        return projectPath
    }
    
    private func generateChangelog(projectPath: URL) throws {
        let changelogsPath = projectPath.appendingPathComponent("changelogs")
        let changelogsList = ChangelogUtil.readChangelogs(fromPath: changelogsPath)
        if (changelogsList.count <= 0) {
            print("No changelogs found.")
            return
        }
        
        let sortedLogs = ChangelogUtil.sortByType(changelogsList: changelogsList)
        print("Generating markdown")
        let markdownString = ChangelogUtil.generateMarkdown(changelogs: sortedLogs, release: release)
        print(markdownString)
        print("Updating CHANGELOG.md")
        ChangelogUtil.appendToChangelogFile(filePath: projectPath.appendingPathComponent("CHANGELOG.md"), content: markdownString)
        print("Archiving changelogs for \(release)")
        try ChangelogUtil.archiveChangelogs(fromPath: changelogsPath, release: release)
    }
    
    private func commitChanges(projectPath: URL, branchName: String) {
        GitUtil.commitChanges(atPath: projectPath, message: "Updating changelog for \(release)")
        
        if(push) {
            print("Pushing changelogs")
            GitUtil.push(atPath: projectPath, branchName: branchName)
        }
    }
    
    private func extractProjectName(_ gitUrl: String) -> String? {
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
}
