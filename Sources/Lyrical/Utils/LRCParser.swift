import Foundation

enum LRCParser {
    static func parse(_ lrc: String) -> [LyricLine] {
        var lines: [LyricLine] = []
        var index = 0

        for rawLine in lrc.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)
            guard !line.isEmpty else { continue }

            let pattern = #"\[(\d{1,2}):(\d{2})(?:\.(\d{1,3}))?\]"#
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }

            let nsLine = line as NSString
            let matches = regex.matches(in: line, range: NSRange(location: 0, length: nsLine.length))
            guard !matches.isEmpty else { continue }

            let lastMatch = matches[matches.count - 1]
            let textStart = lastMatch.range.location + lastMatch.range.length
            let text = nsLine.substring(from: textStart).trimmingCharacters(in: .whitespaces)
            guard !text.isEmpty else { continue }

            for match in matches {
                guard match.numberOfRanges >= 3,
                      let minutesRange = Range(match.range(at: 1), in: line),
                      let secondsRange = Range(match.range(at: 2), in: line),
                      let minutes = Double(line[minutesRange]),
                      let seconds = Double(line[secondsRange])
                else { continue }

                var centiseconds: Double = 0
                if match.numberOfRanges >= 4,
                   let fractionRange = Range(match.range(at: 3), in: line),
                   let fraction = Double(line[fractionRange]) {
                    let digits = line[fractionRange].count
                    centiseconds = fraction / pow(10, Double(digits))
                }

                let timestamp = minutes * 60 + seconds + centiseconds
                lines.append(LyricLine(id: index, timestamp: timestamp, text: text))
                index += 1
            }
        }

        return lines.sorted { $0.timestamp < $1.timestamp }
    }

    static func activeLineIndex(in lines: [LyricLine], at progress: TimeInterval) -> Int? {
        guard !lines.isEmpty else { return nil }
        var active: Int?
        for (idx, line) in lines.enumerated() where line.timestamp <= progress + 0.15 {
            active = idx
        }
        return active
    }
}
