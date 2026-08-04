import Foundation

/// A single compiled ignore rule.
struct IgnorePattern {
    let regex: NSRegularExpression
    let isNegation: Bool
    let isDirectoryOnly: Bool
    let originalPattern: String
}

/// Parses and evaluates `.gitignore`-syntax rules for a `.ts_ignore` file.
final class TSIgnoreMatcher {
    private let patterns: [IgnorePattern]
    private let baseURL: URL

    init(ignoreFileURL: URL, baseURL: URL) throws {
        self.baseURL = baseURL
        let content = try String(contentsOf: ignoreFileURL, encoding: .utf8)
        self.patterns = Self.parse(content)
    }

    init(contents: String, baseURL: URL) {
        self.baseURL = baseURL
        self.patterns = Self.parse(contents)
    }

    // MARK: - Parsing

    static func parse(_ content: String) -> [IgnorePattern] {
        var result: [IgnorePattern] = []

        for rawLine in content.components(separatedBy: .newlines) {
            var line = rawLine

            // Trim trailing unescaped whitespace.
            if !line.hasSuffix("\\ ") {
                while line.hasSuffix(" ") { line.removeLast() }
            }
            guard !line.isEmpty, !line.hasPrefix("#") else { continue }

            var pattern = line
            var isNegation = false
            if pattern.hasPrefix("!") {
                isNegation = true
                pattern.removeFirst()
            }
            if pattern.hasPrefix("\\!") || pattern.hasPrefix("\\#") {
                pattern.removeFirst()
            }

            var isDirectoryOnly = false
            if pattern.hasSuffix("/") {
                isDirectoryOnly = true
                pattern.removeLast()
            }

            // A slash anywhere but the trailing position anchors the
            // pattern to the ignore file's directory, per gitignore rules.
            let anchored = pattern.dropLast().contains("/") || pattern.hasPrefix("/")

            let regexPattern = globToRegex(pattern, anchored: anchored)
            if let regex = try? NSRegularExpression(pattern: regexPattern) {
                result.append(IgnorePattern(regex: regex,
                                             isNegation: isNegation,
                                             isDirectoryOnly: isDirectoryOnly,
                                             originalPattern: line))
            }
        }
        return result
    }

    private static func globToRegex(_ pattern: String, anchored: Bool) -> String {
        var regex = anchored ? "^" : "^(?:.*/)?"
        var chars = Array(pattern)
        if chars.first == "/" { chars.removeFirst() }

        var i = 0
        while i < chars.count {
            let c = chars[i]
            switch c {
            case "*":
                if i + 1 < chars.count, chars[i + 1] == "*" {
                    if i + 2 < chars.count, chars[i + 2] == "/" {
                        regex += "(?:.*/)?"
                        i += 3
                        continue
                    } else {
                        regex += ".*"
                        i += 2
                        continue
                    }
                }
                regex += "[^/]*"
            case "?":
                regex += "[^/]"
            case "[":
                var cls = "["
                var j = i + 1
                if j < chars.count, chars[j] == "!" || chars[j] == "^" {
                    cls += "^"; j += 1
                }
                while j < chars.count, chars[j] != "]" {
                    cls.append(chars[j]); j += 1
                }
                cls += "]"
                regex += cls
                i = j
            default:
                regex += NSRegularExpression.escapedPattern(for: String(c))
            }
            i += 1
        }
        regex += "(?:/.*)?$"
        return regex
    }

    // MARK: - Matching

    /// - Parameters:
    ///   - relativePath: path relative to the ignore file's base directory, "/"-separated.
    ///   - isDirectory: whether the path refers to a directory.
    func isIgnored(relativePath: String, isDirectory: Bool) -> Bool {
        let path = relativePath.hasPrefix("/") ? String(relativePath.dropFirst()) : relativePath
        let range = NSRange(path.startIndex..., in: path)
        var ignored = false
        // Later rules override earlier ones, matching git's semantics.
        for pattern in patterns {
            if pattern.isDirectoryOnly && !isDirectory { continue }
            if pattern.regex.firstMatch(in: path, range: range) != nil {
                ignored = !pattern.isNegation
            }
        }
        return ignored
    }

    func isIgnored(url: URL) -> Bool {
        let relative = url.path.replacingOccurrences(of: baseURL.path, with: "")
        let trimmed = relative.hasPrefix("/") ? String(relative.dropFirst()) : relative
        let isDir = (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory ?? false
        return isIgnored(relativePath: trimmed, isDirectory: isDir)
    }
}

// MARK: - Example usage

/*
let baseURL = URL(fileURLWithPath: "/path/to/library")
let ignoreURL = baseURL.appendingPathComponent(".ts_ignore")
let matcher = try TSIgnoreMatcher(ignoreFileURL: ignoreURL, baseURL: baseURL)

let fm = FileManager.default
guard let enumerator = fm.enumerator(
    at: baseURL,
    includingPropertiesForKeys: [.isDirectoryKey],
    options: [.skipsHiddenFiles]
) else { return }

for case let fileURL as URL in enumerator {
    if matcher.isIgnored(url: fileURL) {
        if (try? fileURL.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
            enumerator.skipDescendants() // don't walk into ignored directories
        }
        continue
    }
    // process fileURL
}
*/
