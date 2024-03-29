import Foundation

class ChangelogUtil {
    static func readChangelogs(fromPath path: URL) -> [ChangelogWrapper]{
        var changelogs: [ChangelogWrapper] = []
        do {
            let changelogFiles = try ChangelogUtil.getChangelogFiles(fromPath: path)
            changelogFiles.forEach { (fileURL) in
                
                if(ChangelogGenerator.debugEnabled) {
                    print("Reading \(fileURL.path)")
                }
                do {
                    let jsonData = try String(contentsOfFile: fileURL.path).data(using: .utf8)
                    if(jsonData != nil) {
                        var changelogWrapper: ChangelogWrapper
                        do {
                            let changelogsArray = try JSONDecoder().decode(Array<Changelog>.self,
                                                                           from: jsonData!)
                            changelogWrapper = ChangelogWrapper(changelogs: changelogsArray, file: fileURL)
                        } catch {
                            // Maybe a single file
                            let changelog = try JSONDecoder().decode(Changelog.self, from: jsonData!)
                            changelogWrapper = ChangelogWrapper(changelogs: [changelog], file: fileURL)
                        }
                        changelogs.append(changelogWrapper)
                    }
                } catch {
                    print ("Error processing file \(fileURL): \(error.localizedDescription)")
                }
            }
        } catch {
            print(error)
        }
        
        return changelogs
    }
    
    static func getChangeLogDirs(atPath path: URL) -> [URL]{
        var dirs = [URL]()
        if let enumerator = FileManager.default.enumerator(at: path, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles, .skipsPackageDescendants]) {
            for case let fileURL as URL in enumerator {
                do {
                    let fileAttributes = try fileURL.resourceValues(forKeys:[.isDirectoryKey])
                    if fileAttributes.isDirectory! && fileURL.path.contains("changelogs") {
                        dirs.append(fileURL)
                    }
                } catch {
                    //print(error, fileURL)
                }
            }
            return dirs
        }
        return []
    }
    
    static func sortByType(changelogsList:[ChangelogWrapper]) -> Dictionary<String, [Changelog]> {
        let changelogs = changelogsList.map { (wrapper) -> [Changelog] in
            return wrapper.changelogs
        }.flatMap { $0 }
        return Dictionary(grouping: changelogs, by: { $0.type })
    }
    
    static func generateMarkdown(changelogs: Dictionary<String, [Changelog]>, release:String) -> String {
        
        let baseUrl = ChangelogGenerator.config.ticketBaseUrl
        
        var result = "## \(release)\n"
        changelogs.forEach { (key, logs) in
            // Prepare the group header.
            // Example:
            // ### Added (54 changes)
            
            result += "### \(key.capitalized) (\(logs.count) changes)\n\n"
            
            // Add entries to the group.
            logs.forEach({ (log) in
                result += "- \(log.title)"
                if(!log.reference.isEmpty) {
                    result += " ([\(log.reference)](\(baseUrl ?? "")\(log.reference)))"
                }
                result += "\n"
            })
            
            result += "\n"
        }
        return result
    }
    
    static func appendToChangelogFile(filePath: URL, content: String) {
        let data = content.data(using: .utf8)
        if FileManager.default.fileExists(atPath: filePath.path) {
            if let fileHandle = try? FileHandle(forWritingTo: filePath) {
                fileHandle.seekToEndOfFile()
                fileHandle.write(data!)
                fileHandle.closeFile()
            }
        } else {
            try? data!.write(to: filePath)
        }
    }
    
    static func archiveChangelogs(fromList changelogs: [ChangelogWrapper], release: String, basePath: URL) throws {
        let archiveDir = basePath.appendingPathComponent("archive").appendingPathComponent(release)
        if !FileManager.default.fileExists(atPath: archiveDir.path) {
            do {
                try FileManager.default.createDirectory(atPath: archiveDir.path, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print(error.localizedDescription);
            }
        }
        
        try changelogs.forEach { (wrapper) in
            let fileUrl = wrapper.file
            let newUrl = archiveDir.appendingPathComponent(fileUrl.lastPathComponent)
            try FileManager.default.moveItem(at: fileUrl, to: newUrl)
        }
        
    }
    
    static func getChangelogFiles(fromPath path: URL) throws -> [URL]{
        let directoryContents = try FileManager.default.contentsOfDirectory(at: path, includingPropertiesForKeys: nil)
        return directoryContents.filter{ $0.pathExtension == "json" }
    }
    
    static func writeChangelogs(changelogWrapper: ChangelogWrapper) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try! encoder.encode(changelogWrapper.changelogs)
        print("Writing \(changelogWrapper.file)")
        try data.write(to: changelogWrapper.file, options: [.atomic])
    }
    
    static func deleteArchive(fromPath path: URL) throws {
        let archiveDir = path.appendingPathComponent("archive")
        if !FileManager.default.fileExists(atPath: archiveDir.path) {
            return
        }
        let directoryContents = try FileManager.default.contentsOfDirectory(at: archiveDir, includingPropertiesForKeys: nil)
        try directoryContents.forEach { (file) in
            if(ChangelogGenerator.debugEnabled) {
                print("Deleting \(file.path)")
            }
            try FileManager.default.removeItem(atPath: file.path)
        }
        
        
    }
}
