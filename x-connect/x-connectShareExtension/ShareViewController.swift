//
//  ShareViewController.swift
//  x-connectShareExtension
//
//  Created on 1/1/26.
//

import UIKit
import Social
import SwiftUI
import UniformTypeIdentifiers

// Note: These types should be shared with the main app target
// For now, they are duplicated here for the extension to work independently
struct ShareBlogInfo {
    let title: String
    let description: String
    let image: String?
    let url: String
    let summary: String
}

class ShareBlogParserService {
    static let shared = ShareBlogParserService()
    
    private init() {}
    
    func extractBlogInfo(from urlString: String) async throws -> ShareBlogInfo {
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "ShareExtension", code: -1, userInfo: [NSLocalizedDescriptionKey: "유효하지 않은 URL입니다."])
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw NSError(domain: "ShareExtension", code: -2, userInfo: [NSLocalizedDescriptionKey: "네트워크 오류가 발생했습니다."])
        }
        
        guard let html = String(data: data, encoding: .utf8) else {
            throw NSError(domain: "ShareExtension", code: -3, userInfo: [NSLocalizedDescriptionKey: "인코딩 오류가 발생했습니다."])
        }
        
        let title = extractMetaTag(html: html, property: "og:title") ??
                   extractMetaTag(html: html, name: "twitter:title") ??
                   extractTitle(html: html) ??
                   "제목 없음"
        
        let description = extractMetaTag(html: html, property: "og:description") ??
                         extractMetaTag(html: html, name: "twitter:description") ??
                         extractMetaTag(html: html, name: "description") ??
                         ""
        
        let image = extractMetaTag(html: html, property: "og:image") ??
                   extractMetaTag(html: html, name: "twitter:image")
        
        let ogUrl = extractMetaTag(html: html, property: "og:url") ?? urlString
        
        var imageUrl: String? = image
        if let img = image, !img.starts(with: "http"), let baseURL = URL(string: urlString),
           let absoluteURL = URL(string: img, relativeTo: baseURL) {
            imageUrl = absoluteURL.absoluteString
        }
        
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
        
        return ShareBlogInfo(title: title, description: description, image: imageUrl, url: ogUrl, summary: summary)
    }
    
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

struct ShareDeepLinkHelper {
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
    
    static func openXApp(with text: String, url: String) {
        let truncatedText = truncateForX(text: text, url: url)
        let shareText = "\(truncatedText) \(url)"
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let twitterURL = URL(string: "twitter://post?message=\(encodedText)"),
           UIApplication.shared.canOpenURL(twitterURL) {
            UIApplication.shared.open(twitterURL)
            return
        }
        
        if let webURL = URL(string: "https://twitter.com/intent/tweet?text=\(encodedText)") {
            UIApplication.shared.open(webURL)
        }
    }
    
    static func openThreadsApp(with text: String, url: String) {
        let shareText = "\(text) \(url)"
        let encodedText = shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        
        if let threadsURL = URL(string: "threads://intent/post?text=\(encodedText)"),
           UIApplication.shared.canOpenURL(threadsURL) {
            UIApplication.shared.open(threadsURL)
            return
        }
        
        if let webURL = URL(string: "https://www.threads.net/intent/post?text=\(encodedText)") {
            UIApplication.shared.open(webURL)
        }
    }
}

class ShareViewController: UIViewController {
    private var hostingController: UIHostingController<ShareView>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 공유 항목 가져오기
        guard let extensionItem = extensionContext?.inputItems.first as? NSExtensionItem,
              let attachments = extensionItem.attachments else {
            showError("공유할 항목을 찾을 수 없습니다.")
            return
        }
        
        // URL 찾기
        for attachment in attachments {
            if attachment.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { (item, error) in
                    if let url = item as? URL {
                        DispatchQueue.main.async {
                            self.showShareView(url: url.absoluteString)
                        }
                    } else if let urlString = item as? String {
                        DispatchQueue.main.async {
                            self.showShareView(url: urlString)
                        }
                    }
                }
                return
            } else if attachment.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                attachment.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { (item, error) in
                    if let text = item as? String,
                       let url = self.extractURL(from: text) {
                        DispatchQueue.main.async {
                            self.showShareView(url: url)
                        }
                    }
                }
                return
            }
        }
        
        // URL을 찾지 못한 경우
        showError("URL을 찾을 수 없습니다.")
    }
    
    private func extractURL(from text: String) -> String? {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
        return matches?.first?.url?.absoluteString
    }
    
    private func showShareView(url: String) {
        let shareView = ShareView(url: url) {
            self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
        }
        
        let hostingController = UIHostingController(rootView: shareView)
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hostingController.didMove(toParent: self)
        self.hostingController = hostingController
    }
    
    private func showError(_ message: String) {
        let alert = UIAlertController(title: "오류", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default) { _ in
            self.extensionContext?.cancelRequest(withError: NSError(domain: "ShareExtension", code: -1))
        })
        present(alert, animated: true)
    }
}

// MARK: - SwiftUI Share View

struct ShareView: View {
    let url: String
    let onDismiss: () -> Void
    
    @State private var blogInfo: ShareBlogInfo?
    @State private var isLoading = true
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("블로그 정보를 가져오는 중...")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                    }
                } else if let error = errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                } else if let info = blogInfo {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Summary Card
                            VStack(alignment: .leading, spacing: 12) {
                                if let image = info.image, let imageURL = URL(string: image) {
                                    AsyncImage(url: imageURL) { image in
                                        image
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                    } placeholder: {
                                        Rectangle()
                                            .fill(Color.gray.opacity(0.3))
                                    }
                                    .frame(height: 200)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                
                                Text(info.title)
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                Text(info.summary)
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                                    .lineLimit(3)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                            )
                            .padding(.horizontal)
                            .padding(.top)
                            
                            // Share Buttons
                            VStack(spacing: 12) {
                                Text("공유하기")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.horizontal)
                                
                                Button(action: {
                                    ShareDeepLinkHelper.openXApp(with: info.summary, url: info.url)
                                    onDismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "at")
                                        Text("X (트위터)")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                                
                                Button(action: {
                                    ShareDeepLinkHelper.openThreadsApp(with: info.summary, url: info.url)
                                    onDismiss()
                                }) {
                                    HStack {
                                        Image(systemName: "text.bubble")
                                        Text("쓰레드")
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black, lineWidth: 2)
                                    )
                                    .cornerRadius(12)
                                }
                                .padding(.horizontal)
                            }
                            .padding(.vertical)
                        }
                    }
                }
            }
            .navigationTitle("SNS Connect")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") {
                        onDismiss()
                    }
                }
            }
        }
        .task {
            await loadBlogInfo()
        }
    }
    
    private func loadBlogInfo() async {
        do {
            let info = try await ShareBlogParserService.shared.extractBlogInfo(from: url)
            blogInfo = info
            isLoading = false
        } catch {
            errorMessage = (error as NSError).localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    ShareView(url: "https://example.com") {}
}

