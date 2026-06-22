import Foundation

// MARK: - JSON 转义

extension String {
    var jsonEscaped: String {
        var escaped = ""
        for char in self {
            switch char {
            case "\"": escaped += "\\\""
            case "\\": escaped += "\\\\"
            case "\n": escaped += "\\n"
            case "\r": escaped += "\\r"
            case "\t": escaped += "\\t"
            default:   escaped.append(char)
            }
        }
        return escaped
    }
}
