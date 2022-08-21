import ArgumentParser
import Foundation

struct CheckChangelogCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "check", abstract: "Check changelogs for a (set of) project(s)")
    
    @OptionGroup var options: GitProjectOptions
    
    func run() throws {
        if(options.projectsConfig != nil) {
            print("Using projects from \(options.projectsConfig!)")
            
            if let localData = try ProjectsConfig.readProjectsConfigFile(fromPath: options.projectsConfig!) {
                
                let projectsConfig = ProjectsConfig.parseProjectsConfig(jsonData: localData)
                projectsConfig.projects.forEach  { (project) in
                    checkChangelogForProject(project: project)
                }
            }
        } else {
            let project = Project(title: "some project", gitUrl: options.gitUrl, localPath: options.localPath)
            checkChangelogForProject(project: project)
        }
    }
    
    private func checkChangelogForProject(project: Project) {
        let gitUtil = GitUtil()
        
        var projectPath: URL?
        let fileManager = FileManager.default
        
        signal(SIGINT, SIG_IGN) // // Make sure the signal does not terminate the application.
        let sigintSrc = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSrc.setEventHandler {
            gitUtil.terminate()
            if(projectPath != nil && !options.noDelete) {
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
            projectPath = try gitUtil.prepareGit(project: project, noPull: options.noPull, baseBranch: options.baseBranch, branchName: nil)
            guard try checkChangelogAtURL(projectPath: projectPath!) else {
                return
            }
            
            if(!options.noDelete) {
                try fileManager.removeItem(at: projectPath!)
            }
        } catch {
            print("Error when checking \(project.title): \(error.localizedDescription)")
        }
    }
    
    private func checkChangelogAtURL(projectPath: URL) throws -> Bool  {
        let changelogDirs = ChangelogUtil.getChangeLogDirs(atPath: projectPath)
        var result = true
        try changelogDirs.forEach { changelogDir in
            print("Found changelogs dir at \(changelogDir.path.replacingOccurrences(of: projectPath.path, with: ""))")
            let changelogsList = ChangelogUtil.readChangelogs(fromPath: changelogDir)
            if (changelogsList.count <= 0) {
                print("No changelogs found.")
                result = false
                return
            }
            
            let sortedLogs = ChangelogUtil.sortByType(changelogsList: changelogsList)
            try sortedLogs.keys.forEach { key in
                if !ChangelogGenerator.config.validTicketStates.contains(where:{$0.localizedStandardContains(key)}) {
                    throw ProcessError.InvalidState(state: key)
                }
            }
            print("Found \(changelogsList.count) valid changelogs.")
        }
        return result
    }
}
