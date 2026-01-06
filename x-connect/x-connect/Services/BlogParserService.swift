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
        // 요약 텍스트 생성 (간단하고 짧게, 완전한 문장으로 끝나도록)
        // X 공유를 위해 최대 120자로 제한 (URL + 공백 고려 시 안전한 길이)
        
        // 문장 단위로 자르는 함수 (완전한 문장으로 끝나도록)
        func truncateToSentence(_ text: String, maxLength: Int) -> String {
            if text.count <= maxLength {
                return text
            }
            
            // 완전한 문장을 찾기 위해 maxLength를 약간 넘어서도 검색 (최대 15자까지 확장)
            let searchLength = min(text.count, maxLength + 15)
            let searchText = String(text.prefix(searchLength))
            
            // 문장 부호를 찾아서 완전한 문장으로 끝나도록 조정
            let sentenceEnders: [Character] = [".", "。", "!", "?", "…"]
            var bestBreak: String.Index? = nil
            var perfectBreak: String.Index? = nil // 문장 부호 + 공백이 있는 완벽한 경우
            
            // 뒤에서부터 문장 부호를 찾음 (가장 가까운 완전한 문장 끝)
            let searchStart = searchText.index(searchText.startIndex, offsetBy: max(0, maxLength - 80))
            for i in (searchStart..<searchText.endIndex).reversed() {
                if sentenceEnders.contains(searchText[i]) {
                    // 숫자나 약어에 포함된 점인지 확인 (예: "2026.1.6.", "U.S.A.")
                    // 하지만 "습니다.", "니다." 같은 한국어 패턴은 허용
                    var isInNumberOrAbbr = false
                    if i > searchText.startIndex {
                        let prevIndex = searchText.index(before: i)
                        let prevChar = searchText[prevIndex]
                        // 한국어 종결어미가 아닌 경우만 약어로 간주
                        let koreanEndings = "다습니요"
                        isInNumberOrAbbr = prevChar.isNumber || (prevChar.isLetter && !koreanEndings.contains(prevChar))
                    }
                    
                    if !isInNumberOrAbbr {
                        // 문장 부호가 마지막 문자이면 완벽한 문장 끝
                        if i == searchText.index(before: searchText.endIndex) {
                            perfectBreak = searchText.endIndex
                            break
                        }
                        let nextIndex = searchText.index(after: i)
                        if nextIndex < searchText.endIndex {
                            let nextChar = searchText[nextIndex]
                            if nextChar == " " || nextChar == "\n" || nextChar == "\r" {
                                perfectBreak = searchText.index(after: i)
                                break
                            } else if bestBreak == nil {
                                // 첫 번째로 찾은 문장 부호는 백업으로 저장
                                bestBreak = searchText.index(after: i)
                            }
                        }
                    }
                }
            }
            
            // 완벽한 문장 끝을 우선 사용 (maxLength를 약간 넘어도 허용)
            if let breakIndex = perfectBreak {
                let result = String(searchText[searchText.startIndex..<breakIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
                // maxLength를 크게 넘지 않는 경우에만 사용 (최대 15자까지 허용)
                // 완전한 문장을 위해 약간의 여유를 둠
                if result.count <= maxLength + 15 {
                    return result
                }
            }
            
            // 완벽한 문장 끝이 없거나 너무 길면, maxLength 이내에서 일반 문장 부호 사용
            let truncated = String(text.prefix(maxLength))
            if let breakIndex = bestBreak, 
               truncated.distance(from: truncated.startIndex, to: breakIndex) <= maxLength,
               truncated.distance(from: truncated.startIndex, to: breakIndex) >= maxLength - 30 {
                return String(truncated[truncated.startIndex..<breakIndex]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            
            // 문장 부호를 찾지 못했으면, 단어 단위로 자르기 시도
            if let lastSpace = truncated.lastIndex(of: " "), truncated.distance(from: truncated.startIndex, to: lastSpace) > maxLength - 20 {
                return String(truncated[truncated.startIndex..<lastSpace]) + "..."
            }
            
            // 단어도 없으면 그냥 자르되 "..." 추가
            return truncated.trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }
        
        var summary = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !summary.isEmpty {
            // 설명이 있으면 120자로 제한 (완전한 문장으로)
            summary = truncateToSentence(summary, 120)
        } else {
            // 제목만 사용 (최대 100자)
            summary = title
            if summary.count > 100 {
                summary = truncateToSentence(summary, 100)
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

