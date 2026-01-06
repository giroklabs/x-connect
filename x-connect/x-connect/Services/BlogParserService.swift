//
//  BlogParserService.swift
//  x-connect
//
//  Created on 1/1/26.
//

import Foundation

struct BlogInfo {
    let title: String
    let description: String
    let image: String?
    let url: String
    let summary: String
}

class BlogParserService {
    static let shared = BlogParserService()
    
    private init() {}
    
    /// 블로그 URL에서 메타 태그를 추출하여 요약 정보를 생성합니다.
    func extractBlogInfo(from urlString: String) async throws -> BlogInfo {
        guard let url = URL(string: urlString) else {
            throw BlogParserError.invalidURL
        }
        
        // HTML 가져오기
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw BlogParserError.networkError
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw BlogParserError.invalidEncoding
        }
        
        // 메타 태그 추출 (정규식 사용)
        let title = extractMetaTag(html: html, property: "og:title") ??
                   extractMetaTag(html: html, name: "twitter:title") ??
                   extractTitle(html: html) ??
                   "제목 없음"
        
        let description = extractMetaTag(html: html, property: "og:description") ??
                         extractMetaTag(html: html, name: "twitter:description") ??
                         extractMetaTag(html: html, name: "description") ??
                         extractFirstParagraph(html: html) ??
                         ""
        
        let image = extractMetaTag(html: html, property: "og:image") ??
                   extractMetaTag(html: html, name: "twitter:image")
        
        let ogUrl = extractMetaTag(html: html, property: "og:url") ?? urlString
        
        // 이미지 URL 정규화
        var imageUrl: String? = image
        if let img = image, !img.starts(with: "http") {
            if let baseURL = URL(string: urlString),
               let absoluteURL = URL(string: img, relativeTo: baseURL) {
                imageUrl = absoluteURL.absoluteString
            }
        }
        
        // 요약 텍스트 생성
        // 요약 텍스트 생성 (간단하고 짧게)
        // X 공유를 위해 최대 120자로 제한 (URL + 공백 고려 시 안전한 길이)
        var summary = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !summary.isEmpty {
            // 설명이 있으면 120자로 제한
            if summary.count > 120 {
                // 문장 단위로 자르기 (마지막 문장 부호 기준)
                let truncated = String(summary.prefix(117))
                
                // 마지막 문장 부호 찾기
                var lastBreakIndex: String.Index? = nil
                var lastBreakDistance = 0
                
                if let period = truncated.lastIndex(of: ".") {
                    let distance = truncated.distance(from: truncated.startIndex, to: period)
                    if distance > lastBreakDistance {
                        lastBreakIndex = period
                        lastBreakDistance = distance
                    }
                }
                if let periodKr = truncated.lastIndex(of: "。") {
                    let distance = truncated.distance(from: truncated.startIndex, to: periodKr)
                    if distance > lastBreakDistance {
                        lastBreakIndex = periodKr
                        lastBreakDistance = distance
                    }
                }
                if let exclamation = truncated.lastIndex(of: "!") {
                    let distance = truncated.distance(from: truncated.startIndex, to: exclamation)
                    if distance > lastBreakDistance {
                        lastBreakIndex = exclamation
                        lastBreakDistance = distance
                    }
                }
                if let question = truncated.lastIndex(of: "?") {
                    let distance = truncated.distance(from: truncated.startIndex, to: question)
                    if distance > lastBreakDistance {
                        lastBreakIndex = question
                        lastBreakDistance = distance
                    }
                }
                
                if let breakIndex = lastBreakIndex, lastBreakDistance > 50 {
                    // 문장 끝이 있으면 그곳에서 자름
                    let endIndex = truncated.index(breakIndex, offsetBy: 1)
                    summary = String(truncated[truncated.startIndex..<endIndex])
                } else {
                    // 문장 끝이 없으면 그냥 자름
                    summary = truncated + "..."
                }
            }
        } else {
            // 제목만 사용 (최대 100자)
            summary = title
            if summary.count > 100 {
                summary = String(summary.prefix(97)) + "..."
            }
        }
        
        return BlogInfo(
            title: title,
            description: description,
            image: imageUrl,
            url: ogUrl,
            summary: summary
        )
    }
    
    // MARK: - Private Methods
    
    private func extractMetaTag(html: String, property: String) -> String? {
        let pattern = "<meta\\s+property=[\"']\(property)[\"']\\s+content=[\"']([^\"']+)[\"']"
        return extractRegex(html: html, pattern: pattern, captureGroup: 1)
    }
    
    private func extractMetaTag(html: String, name: String) -> String? {
        let pattern = "<meta\\s+name=[\"']\(name)[\"']\\s+content=[\"']([^\"']+)[\"']"
        return extractRegex(html: html, pattern: pattern, captureGroup: 1)
    }
    
    private func extractTitle(html: String) -> String? {
        let pattern = "<title>([^<]+)</title>"
        return extractRegex(html: html, pattern: pattern, captureGroup: 1)
    }
    
    private func extractFirstParagraph(html: String) -> String? {
        // <p> 태그 내용 추출
        let pattern = "<p[^>]*>([^<]+)</p>"
        if let match = html.range(of: pattern, options: .regularExpression) {
            let paragraph = String(html[match])
            if let contentRange = paragraph.range(of: ">([^<]+)<", options: .regularExpression) {
                let content = String(paragraph[contentRange])
                    .trimmingCharacters(in: CharacterSet(charactersIn: "><"))
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                return content.isEmpty ? nil : content
            }
        }
        return nil
    }
    
    private func extractRegex(html: String, pattern: String, captureGroup: Int) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive, .dotMatchesLineSeparators]) else {
            return nil
        }
        
        let range = NSRange(html.startIndex..., in: html)
        if let match = regex.firstMatch(in: html, options: [], range: range),
           captureGroup < match.numberOfRanges {
            let matchRange = match.range(at: captureGroup)
            if let swiftRange = Range(matchRange, in: html) {
                return String(html[swiftRange])
            }
        }
        
        return nil
    }
}

enum BlogParserError: LocalizedError {
    case invalidURL
    case networkError
    case invalidEncoding
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "유효하지 않은 URL입니다."
        case .networkError:
            return "네트워크 오류가 발생했습니다."
        case .invalidEncoding:
            return "인코딩 오류가 발생했습니다."
        case .parsingError:
            return "블로그 정보를 파싱할 수 없습니다."
        }
    }
}

