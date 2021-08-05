import ArgumentParser
import Foundation

struct GenerateAllCommand: ParsableCommand {
    
    public static let configuration = CommandConfiguration(commandName: "generate-all", abstract: "Generate Changelogs for all projects")
    
    @OptionGroup var options: GenerateOptions
    
    @Option(name: [.customShort("p"), .long], help: "Path to projects file")
    var projectsConfig: String
    
    func run() throws {
        print("Using projects from \(projectsConfig)")
        
        if let localData = try ProjectsConfig.readProjectsConfigFile(fromPath: projectsConfig) {

            let projectsConfig = ProjectsConfig.parseProjectsConfig(jsonData: localData)
            try projectsConfig.projects.forEach  { (project) in
            
                var subcommand: GenerateCommand = GenerateCommand(options: options, title: project.title, gitUrl: project.gitUrl, localPath: project.localPath)
                try subcommand.validate()
                try subcommand.run()
            }
        }
    }
}
