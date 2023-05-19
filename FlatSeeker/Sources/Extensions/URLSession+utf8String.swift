import Foundation

extension URLSession {
    func utf8String(from url: URL) async -> String? {
        let result = try? await self.data(from: url)
        return result.flatMap { data, _ in
            String(data: data, encoding: .utf8)
        }
    }
}
