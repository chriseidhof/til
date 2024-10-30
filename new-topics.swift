#!/usr/bin/env swift

import Foundation

let fileManager = FileManager.default
let directoryURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
let readmeURL = directoryURL.appendingPathComponent("README.md")

// A structure to hold the parsed file information
struct MarkdownFile {
    let date: String
    let title: String
    let path: String
    let topic: String
}

// Function to parse filename
func parseFilename(_ filename: String, in topic: String) -> MarkdownFile? {
    let regex = #/(\d{4}-\d{2}-\d{2})-(.+)\.md/#
    guard let match = filename.wholeMatch(of: regex) else { return nil }

    let date = String(match.output.1)
    let title = String(match.output.2).replacingOccurrences(of: "-", with: " ").capitalized
    let path = "./\(topic)/\(filename)"
    return MarkdownFile(date: date, title: title, path: path, topic: topic.capitalized)
}

// Function to extract existing links from README.md
func extractExistingLinks(from url: URL) -> Set<String> {
    guard let contents = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    let regex = #/\[.*?\]\((\./.+?)\)/#
    let matches = contents.matches(of: regex)
    return Set(matches.compactMap { match in
        String(match.output.1)
    })
}

// Collecting files
var files: [MarkdownFile] = []
let existingLinks = extractExistingLinks(from: readmeURL)

// Traverse directories and gather files
if let topics = try? fileManager.contentsOfDirectory(atPath: directoryURL.path) {
    for topic in topics {
        let topicURL = directoryURL.appendingPathComponent(topic)
        guard topicURL.hasDirectoryPath else { continue }
        if let markdownFiles = try? fileManager.contentsOfDirectory(atPath: topicURL.path) {
            for filename in markdownFiles where filename.hasSuffix(".md") {
                if let markdownFile = parseFilename(filename, in: topic), !existingLinks.contains(markdownFile.path) {
                    files.append(markdownFile)
                }
            }
        }
    }
}

// Generate markdown by date
let sortedByDate = files.sorted { $0.date > $1.date }
var dateMarkdown = "## By Date\n\n"
for file in sortedByDate {
    dateMarkdown += "- [\(file.title)](\(file.path)) (\(file.date))\n"
}

// Generate markdown by topic
let groupedByTopic = Dictionary(grouping: files, by: { $0.topic })
let sortedTopics = groupedByTopic.keys.sorted()
var topicMarkdown = "## By Topic\n\n"
for topic in sortedTopics {
    topicMarkdown += "### \(topic)\n\n"
    let filesForTopic = groupedByTopic[topic]!.sorted { $0.date > $1.date }
    for file in filesForTopic {
        topicMarkdown += "- [\(file.title)](\(file.path)) (\(file.date))\n"
    }
    topicMarkdown += "\n"
}

// Combine both markdown outputs
let finalMarkdown = dateMarkdown + "\n" + topicMarkdown
print(finalMarkdown)
