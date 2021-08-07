import XCTest
import class Foundation.Bundle

final class changelog_generatorTests: XCTestCase {
    func testExample() throws {
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
        let output = String(data: data, encoding: .utf8)

        XCTAssertEqual(output, "OVERVIEW: A Swift command-line tool to generate changelogs for configured\nprojects\n\nUSAGE: changelog-generator [--config-file <config-file>] <subcommand>\n\nOPTIONS:\n  -c, --config-file <config-file>\n  -h, --help              Show help information.\n\nSUBCOMMANDS:\n  generate                Generate Changelogs for a project\n  generate-all            Generate Changelogs for all projects\n\n  See \'changelog-generator help <subcommand>\' for detailed help.\n")
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

    static var allTests = [
        ("testExample", testExample),
    ]
}
