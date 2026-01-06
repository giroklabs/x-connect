//
//  ContentView.swift
//  x-connect
//
//  Created on 1/1/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 0) {
            // Custom Header (bitcoin tracker 스타일 참조)
            AppHeaderView()
            
            // Main Scrollable Content
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Card (bitcoin tracker 스타일 참조)
                    VStack(alignment: .leading, spacing: 14) {
                        Text("블로그 공유")
                            .font(.system(size: 15))
                            .foregroundColor(.secondary)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Safari나 다른 앱에서 공유 버튼을 눌러 블로그 글을 X와 쓰레드에 쉽게 공유하세요.")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                            
                            Text("공유 시트에서 'SNS Connect'를 선택하면 블로그 내용이 자동으로 요약되어 공유됩니다.")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    .padding(.top)
                }
                .padding(.vertical)
            }
        }
    }
}

// AppHeaderView (bitcoin tracker 스타일 참조)
struct AppHeaderView: View {
    var body: some View {
        HStack(spacing: 12) {
            // Logo
            Image(systemName: "link.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 28, height: 28)
                .foregroundColor(.blue)
            
            // App Title
            Text("SNS Connect")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Color(.systemBackground)
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

#Preview {
    ContentView()
}

