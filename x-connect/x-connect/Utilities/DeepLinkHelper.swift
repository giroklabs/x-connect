//
//  DeepLinkHelper.swift
//  x-connect
//
//  Created on 1/1/26.
//

import Foundation
import UIKit

struct DeepLinkHelper {
    // X(트위터) 글자수 제한: 280자 (텍스트 + URL + 공백 모두 포함)
    private static let xMaxLength = 280
    
    private static func truncateForX(text: String, url: String) -> String {
        // 전체 텍스트 길이 체크 (텍스트 + 공백 + URL)
        let fullText = "\(text) \(url)"
        
        // 이미 280자 이하면 그대로 반환
        if fullText.count <= xMaxLength {
            return text
        }
        
        // URL 길이 + 공백(1자) + "..."(3자)를 제외한 텍스트 최대 길이 계산
        let urlLength = url.count
        let spaceLength = 1 // 공백
        let ellipsisLength = 3 // "..."
        
        // 텍스트 최대 길이 = 280 - URL - 공백 - "..."
        let maxTextWithoutEllipsis = xMaxLength - ellipsisLength - spaceLength - urlLength
        
        // 최소 10자는 보장 (너무 짧으면 의미가 없음)
        if maxTextWithoutEllipsis < 10 {
            return String(text.prefix(7)) + "..."
        }
        
        // 텍스트를 자르고 "..." 추가
        let truncatedText = String(text.prefix(maxTextWithoutEllipsis)) + "..."
        
        // 최종 확인: 정확히 280자 이하인지 검증
        let finalText = "\(truncatedText) \(url)"
        if finalText.count > xMaxLength {
            // 계산 오류가 있는 경우, 추가로 자름
            let extraChars = finalText.count - xMaxLength
            let safeLength = max(10, maxTextWithoutEllipsis - extraChars)
            return String(text.prefix(safeLength - 3)) + "..."
        }
        
        return truncatedText
    }
    
    /// X(트위터) 앱을 열고 공유 텍스트를 전달합니다.
    static func openXApp(with text: String, url: String) {
        let truncatedText = truncateForX(text: text, url: url)
        let shareText = "\(truncatedText) \(url)"
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // X 앱 URL Scheme 시도 (twitter://)
        if let twitterURL = URL(string: "twitter://post?message=\(encodedText)"),
           UIApplication.shared.canOpenURL(twitterURL) {
            UIApplication.shared.open(twitterURL)
            return
        }
        
        // 웹 Intent URL 사용 (fallback)
        if let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            UIApplication.shared.open(webURL)
        }
    }
    
    /// Threads 앱을 열고 공유 텍스트를 전달합니다.
    static func openThreadsApp(with text: String, url: String) {
        let shareText = "\(text) \(url)"
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        // Threads 앱 URL Scheme 시도 (threads://)
        if let threadsURL = URL(string: "threads://intent/post?text=\(encodedText)"),
           UIApplication.shared.canOpenURL(threadsURL) {
            UIApplication.shared.open(threadsURL)
            return
        }
        
        // 웹 Intent URL 사용 (fallback)
        if let webURL = URL(string: "https://www.threads.net/intent/post?text=\(encodedText)") {
            UIApplication.shared.open(webURL)
        }
    }
}

