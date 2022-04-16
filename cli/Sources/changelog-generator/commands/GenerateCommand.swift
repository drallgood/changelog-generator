import ArgumentParser
import Foundation

struct GenerateCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "generate", abstract: "Generate Changelogs for a project")
    
    @OptionGroup var gitProjectOptions: GitProjectOptions
    
    @OptionGroup var gitServerOptions: GitPushOptions
    
    @Argument(help: "The name of the release, e.g. 8.0.1")
    var release: String
    
    mutating func validate() throws {
        guard (gitProjectOptions.projectsConfig != nil || gitProjectOptions.gitUrl != nil || gitProjectOptions.localPath != nil) else {
            throw ValidationError("Please specify either a projects file, a Git Url or a local path")
        }
    }
    
    func run() throws {
        if(gitProjectOptions.projectsConfig != nil) {
            print("Using projects from \(gitProjectOptions.projectsConfig!)")
            
            if let localData = try ProjectsConfig.readProjectsConfigFile(fromPath: gitProjectOptions.projectsConfig!) {
                
                let projectsConfig = ProjectsConfig.parseProjectsConfig(jsonData: localData)
                projectsConfig.projects.forEach  { (project) in
                    generateChangelogForProject(project: project)
                }
            }
        } else {
            let project = Project(title: "some project", gitUrl: gitProjectOptions.gitUrl, localPath: gitProjectOptions.localPath)
            generateChangelogForProject(project: project)
        }
    }
    
    func generateChangelogForProject(project: Project) {
        let branchName = "CL-\(release)"
        let fileManager = FileManager.default
        let gitUtil = GitUtil()
        
        var projectPath: URL?
        
        var connector:Connector?
        if(gitServerOptions.createMR) {
            connector = ConnectorUtil.getConnector()
        }
        
        signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            gitUtil.terminate()
            if(!gitProjectOptions.noDelete && projectPath != nil) {
                do {
                    try fileManager.removeItem(at: projectPath!)
                } catch {
                    print("Couldn't delete temporary directory at \(projectPath!)")
                }
            }
            GenerateCommand.exit(withError: ProcessError.exited(code: 0))
        }
        sigintSrc.resume()
        
        do {
            projectPath = try gitUtil.prepareGit(project: project, noPull: gitProjectOptions.noPull, baseBranch:gitProjectOptions.baseBranch, branchName: branchName)
            guard try generateChangelog(projectPath: projectPath!) else {
                return
            }
            
            try gitUtil.commitChanges(gitUtil: gitUtil, projectPath: projectPath!, branchName: branchName, message: "Updating changelog for \(release)", push: gitServerOptions.push, dryRun: gitServerOptions.dryRun)
            
            if(gitServerOptions.createMR && !gitServerOptions.dryRun) {
                guard let projectName = gitUtil.extractProjectName(project.gitUrl!) else {
                    print("ERROR: couldn't extract project name from \(project.gitUrl!)")
                    return
                }
                try connector?.createMR(forProject: projectName, title: "Merge changelog for \(release) to \(gitProjectOptions.baseBranch)", body: "Generated changelog for \(release). Branch \(branchName) to \(gitProjectOptions.baseBranch)",token: gitServerOptions.accessToken!, sourceBranchName: branchName, targetBranchName: gitProjectOptions.baseBranch)
            }
            
            if(!gitProjectOptions.noDelete) {
                try fileManager.removeItem(at: projectPath!)
            }
        } catch {
            print("Error when generating \(project.title): \(error.localizedDescription)")
        }
    }
    
    
    
    private func generateChangelog(projectPath: URL) throws -> Bool  {
        let changelogsPath = projectPath.appendingPathComponent("changelogs")
        let changelogsList = ChangelogUtil.readChangelogs(fromPath: changelogsPath)
        if (changelogsList.count <= 0) {
            print("No changelogs found.")
            return false
        }
        
        let sortedLogs = ChangelogUtil.sortByType(changelogsList: changelogsList)
        print("Generating markdown")
        let markdownString = ChangelogUtil.generateMarkdown(changelogs: sortedLogs, release: release)
        if(ChangelogGenerator.debugEnabled) {
            print(markdownString)
        }
        print("Updating CHANGELOG.md")
        ChangelogUtil.appendToChangelogFile(filePath: projectPath.appendingPathComponent("CHANGELOG.md"), content: markdownString)
        print("Archiving changelogs for \(release)")
        try ChangelogUtil.archiveChangelogs(fromList: changelogsList, release: release, basePath: changelogsPath)
        return true
    }
}
