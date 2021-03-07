import ArgumentParser
import Foundation

struct GenerateCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "generate", abstract: "Generate Changelogs for a project")
    
    @OptionGroup var options: GenerateOptions
    
    @Option(name: [.customShort("g"), .long], help: "Git Url")
    var gitUrl: String?
    
    @Option(name: [.customShort("p"), .long], help: "Git Url")
    var localPath: String?
    
    @Option(name: [.customShort("b"), .long], help: "Base branch")
    var baseBranch: String = "master"

    
    mutating func validate() throws {
        guard (gitUrl != nil || localPath != nil) else {
            throw ValidationError("Please specify either a Git Url or a local path")
        }
    }
    
    func run() throws {
        let branchName = "CL-\(options.release)"
        let fileManager = FileManager.default
        let connector = GitlabConnector()
        let project = Project(title: "", gitUrl: gitUrl, localPath: localPath)
            do {
                let projectPath = prepareGit(project: project, branchName: branchName)
                try generateChangelog(projectPath: projectPath)
                commitChanges(projectPath: projectPath, branchName: branchName)
                
                if(options.createMR) {
                    guard let projectName = extractProjectName(project.gitUrl!) else {
                        print("ERROR: couldn't extract project name from \(project.gitUrl!)")
                        return
                    }
                    connector.createMR(forProject: projectName, release: options.release,token: options.accessToken!, sourceBranchName: branchName, targetBranchName: "master")
                }
                
                if(!options.noDelete) {
                    try fileManager.removeItem(at: projectPath)
                }
            } catch {
                print("Error when generating \(project.title): \(error.localizedDescription)")
            }
    }
    
    private func prepareGit(project: Project, branchName: String) -> URL {
        print("Checking out git project for \(project.title)")
        
        var projectPath: URL
        if(project.localPath == nil) {
            projectPath = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            GitUtil.checkoutGitProject(atUrl: project.gitUrl!, atPath: projectPath.path)
        } else  {
            projectPath = URL(fileURLWithPath: project.localPath!)
        }
        
        print("Creating branch for \(options.release)")
        
        GitUtil.assertOnCorrectBranchAndUpToDate(atPath: projectPath, branchName: branchName)
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
        let markdownString = ChangelogUtil.generateMarkdown(changelogs: sortedLogs, release: options.release)
        print(markdownString)
        print("Updating CHANGELOG.md")
        ChangelogUtil.appendToChangelogFile(filePath: projectPath.appendingPathComponent("CHANGELOG.md"), content: markdownString)
        print("Archiving changelogs for \(options.release)")
        try ChangelogUtil.archiveChangelogs(fromPath: changelogsPath, release: options.release)
    }
    
    private func commitChanges(projectPath: URL, branchName: String) {
        GitUtil.commitChanges(atPath: projectPath, message: "Updating changelog for \(options.release)")
        
        if(options.push) {
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
