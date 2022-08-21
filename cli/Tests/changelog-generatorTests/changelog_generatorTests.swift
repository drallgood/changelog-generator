import XCTest
import class Foundation.Bundle

final class changelog_generatorTests: XCTestCase {
    func testRun() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }

        let fooBinary = productsDirectory.appendingPathComponent("changelog-generator")

        let process = Process()
        process.executableURL = fooBinary

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var  output = String(data: data, encoding: .utf8)
        output = output?.replacingOccurrences(of: "Using .*\n", with: "", options: [.caseInsensitive, .regularExpression])
        XCTAssertEqual(output, "OVERVIEW: A Swift command-line tool to generate changelogs for configured\nprojects\n\nUSAGE: changelog-generator [--config-file <config-file>] [--debug] <subcommand>\n\nOPTIONS:\n  -c, --config-file <config-file>\n  --debug                 Enable debug logging\n  -h, --help              Show help information.\n\nSUBCOMMANDS:\n  create                  Create a changelog JSON file\n  check                   Check changelogs for a (set of) project(s)\n  generate                Generate Changelogs for a project\n  clear                   Clear changelogs for a (set of) project(s), e.g. to\n                          set up for a new version\n\n  See \'changelog-generator help <subcommand>\' for detailed help.\n")
    }
    
    func testCheck() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let packageRootPath = URL(fileURLWithPath: #file).pathComponents
            .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst()
        let projectDir = packageRootPath.appending("/Tests/changelog-generatorTests/testProject/")
        
        let fooBinary = productsDirectory.appendingPathComponent("changelog-generator")

        let process = Process()
        process.executableURL = fooBinary
        process.arguments = ["check","-l",projectDir,"--no-delete"]

        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var  output = String(data: data, encoding: .utf8)
        output = output?.replacingOccurrences(of: "Using .*\n", with: "", options: [.caseInsensitive, .regularExpression])
        XCTAssertEqual(output, "#### Preparing project directory for some project ####\nFound changelogs dir at /changelogs\nFound 1 valid changelogs.\n")
    }
    
    func testGenerate() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        // Some of the APIs that we use below are available in macOS 10.13 and above.
        guard #available(macOS 10.13, *) else {
            return
        }
        
        let packageRootPath = URL(fileURLWithPath: #file).pathComponents
            .prefix(while: { $0 != "Tests" }).joined(separator: "/").dropFirst()
        let projectDir = packageRootPath.appending("/Tests/changelog-generatorTests/testProject/")
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.copyItem(at:URL(fileURLWithPath: projectDir,isDirectory: true), to: tempDir)
        
        _ = try gitShell(atPath: tempDir, ["init","-b","main"]).waitUntilExit()
        _ = try gitShell(atPath: tempDir, ["config","user.name","'Your Name'"]).waitUntilExit()
        _ = try gitShell(atPath: tempDir, ["config","user.email","'you@example.com'"]).waitUntilExit()
        _ = try gitShell(atPath: tempDir, ["add","."]).waitUntilExit()
        _ = try gitShell(atPath: tempDir, ["commit","-m","'Initial commit'"]).waitUntilExit()
        let fooBinary = productsDirectory.appendingPathComponent("changelog-generator")

        let process = Process()
        process.executableURL = fooBinary
        process.arguments = ["generate","testVersion","-l",tempDir.path,"--dry-run","--no-pull"]
        let pipe = Pipe()
        process.standardOutput = pipe

        try process.run()
        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var  output = String(data: data, encoding: .utf8)
        output = output?.replacingOccurrences(of: "Using .*\n", with: "", options: [.caseInsensitive, .regularExpression])
        XCTAssertEqual(output, "#### Preparing project directory for some project ####\nCreating branch CL-testVersion\nFound changelogs dir at /changelogs\nGenerating markdown\nUpdating CHANGELOG.md\nArchiving changelogs for testVersion\n")
    }

    /// Returns path to the built products directory.
    var productsDirectory: URL {
      #if os(macOS)
        for bundle in Bundle.allBundles where bundle.bundlePath.hasSuffix(".xctest") {
            return bundle.bundleURL.deletingLastPathComponent()
        }
        fatalError("couldn't find the products directory")
      #else
        return Bundle.main.bundleURL
      #endif
    }
    
    private func gitShell(atPath path:URL? = nil,_ command: [String]) throws -> Process {
        let process = Process()
        process.arguments = command
        if(path != nil) {
            process.currentDirectoryURL = path
        }
        process.executableURL = URL(string: "file:///usr/bin/git")
        try process.run()
        return process
    }

    static var allTests = [
        ("testRun", testRun),
        ("testCheck", testCheck),
        ("testGenerate", testGenerate),
    ]
}
