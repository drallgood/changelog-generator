import ArgumentParser
import Foundation

struct ClearChangelogCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "clear", abstract: "Clear changelogs for a (set of) project(s), e.g. to set up for a new version")
    
    @OptionGroup var gitProjectOptions: GitProjectOptions
    
    @OptionGroup var gitServerOptions: GitPushOptions
    
    @Option(name: [.customShort("f"), .long], help: "Path to CHANGELOG.md template file", completion: .file(extensions: ["json"]))
    var templateFile: String?
    
    
    func run() throws {
        if(gitProjectOptions.projectsConfig != nil) {
            print("Using projects from \(gitProjectOptions.projectsConfig!)")
            
            if let localData = try ProjectsConfig.readProjectsConfigFile(fromPath: gitProjectOptions.projectsConfig!) {
                
                let projectsConfig = ProjectsConfig.parseProjectsConfig(jsonData: localData)
                projectsConfig.projects.forEach  { (project) in
                    clearChangelogForProject(project: project)
                }
            }
        } else {
            let project = Project(title: "some project", gitUrl: gitProjectOptions.gitUrl, localPath: gitProjectOptions.localPath)
            clearChangelogForProject(project: project)
        }
    }
    
    
    private func clearChangelogForProject(project: Project) {
        let gitUtil = GitUtil()
        
        var projectPath: URL?
        let fileManager = FileManager.default
        
        signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            gitUtil.terminate()
            if(projectPath != nil && !gitProjectOptions.noDelete) {
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
            let branchName = "cl_clear_\(Int.random(in: 1...1000))"
            projectPath = try gitUtil.prepareGit(project: project, noPull: gitProjectOptions.noPull, baseBranch: gitProjectOptions.baseBranch, branchName: branchName)
            
            try clearChangelog(projectPath: projectPath!)
            
            try gitUtil.commitChanges(gitUtil: gitUtil, projectPath: projectPath!, branchName: branchName, message: "Clearing changelog [ci-skip]", push: gitServerOptions.push)
            
            if(gitServerOptions.createMR) {
                guard let projectName = gitUtil.extractProjectName(project.gitUrl!) else {
                    print("ERROR: couldn't extract project name from \(project.gitUrl!)")
                    return
                }
                try ConnectorUtil.getConnector().createMR(forProject: projectName, title: "Clearing changelog on \(gitProjectOptions.baseBranch)", body: "Clearing changelog on \(gitProjectOptions.baseBranch) to prepare for next version",token: gitServerOptions.accessToken!, sourceBranchName: branchName, targetBranchName: gitProjectOptions.baseBranch)
            }
            
            if(!gitProjectOptions.noDelete) {
                try fileManager.removeItem(at: projectPath!)
            }
        } catch {
            print("Error when cleaning \(project.title): \(error.localizedDescription)")
        }
    }
    
    private func clearChangelog(projectPath: URL) throws  {
        print("Deleting archive")
        let changelogsPath = projectPath.appendingPathComponent("changelogs")
        try ChangelogUtil.deleteArchive(fromPath: changelogsPath)
        
        
        print("Creating new CHANGELOG.md file")
        let changelogMDFile = projectPath.appendingPathComponent("CHANGELOG.md")
        if(templateFile != nil) {
            if(ChangelogGenerator.debugEnabled) {
                print("Copying \(templateFile!) to \(changelogMDFile)")
            }
            try FileManager.default.copyItem(at: URL(fileURLWithPath: templateFile!), to: changelogMDFile)
        } else {
            if(ChangelogGenerator.debugEnabled) {
                print("Writing new \(changelogMDFile)")
            }
            let content = """
                # Changelog
                All notable changes to this project will be documented in this file.
                
                The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) and the [Gitlab way](https://about.gitlab.com/blog/2018/07/03/solving-gitlabs-changelog-conflict-crisis/) of creating Changelogs.
                
                """;
            let data = content.data(using: .utf8)
            try data!.write(to: changelogMDFile)
        }
        
    }
}
