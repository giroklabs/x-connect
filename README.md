# SNS Connect

블로그 글을 X(트위터)와 쓰레드에 쉽게 공유할 수 있는 웹앱과 iOS 앱입니다.

## 기능

### 웹앱
- 블로그 링크 입력으로 자동 요약 생성
- Open Graph 메타 태그 기반 요약
- X와 쓰레드 공유 버튼

### iOS 앱
- Share Extension을 통한 공유 시트 통합
- 공유된 블로그 URL 자동 파싱 및 요약
- Deep Link를 통한 X와 쓰레드 앱 열기

## 프로젝트 구조

```
x-connect/
├── web/                          # Next.js 웹앱
│   ├── app/
│   │   ├── page.tsx             # 메인 페이지
│   │   └── api/
│   │       └── summarize/       # 블로그 요약 API
│   ├── components/              # React 컴포넌트
│   └── lib/
│       └── blogParser.ts        # 블로그 파서
└── x-connect/                   # iOS 앱
    ├── x-connect/
    │   ├── App.swift
    │   ├── Views/
    │   ├── Services/
    │   └── Utilities/
    └── x-connectShareExtension/  # Share Extension
```

## 설치 및 실행

### 웹앱

```bash
cd web
npm install
npm run dev
```

웹앱은 `http://localhost:3000`에서 실행됩니다.

### iOS 앱

1. Xcode에서 `x-connect.xcodeproj`를 엽니다.
2. Share Extension 타겟을 추가합니다 (아래 참조).
3. 시뮬레이터 또는 실제 기기에서 실행합니다.

## Share Extension 추가 방법

Share Extension 타겟은 Xcode에서 수동으로 추가해야 합니다:

1. Xcode에서 프로젝트를 엽니다.
2. File > New > Target을 선택합니다.
3. "Share Extension"을 선택하고 Next를 클릭합니다.
4. Product Name: `x-connectShareExtension`, Bundle Identifier: `com.giroklabs.x-connectShareExtension`으로 설정합니다.
5. Finish를 클릭합니다.
6. 생성된 Share Extension의 `ShareViewController.swift`를 삭제하고, `/x-connect/x-connectShareExtension/ShareViewController.swift` 파일을 프로젝트에 추가합니다.
7. Info.plist 파일도 같은 디렉토리의 파일로 교체합니다.
8. Share Extension 타겟의 Build Settings에서 다음을 확인합니다:
   - Swift Version: 5.0
   - iOS Deployment Target: 18.5 (메인 앱과 동일)
9. Share Extension 타겟의 Info 탭에서 "App Groups" capability를 추가하고, 메인 앱과 동일한 그룹을 사용하도록 설정합니다 (선택사항).

## 사용 방법

### 웹앱
1. 브라우저에서 웹앱을 엽니다.
2. 블로그 링크를 입력하고 "요약" 버튼을 클릭합니다.
3. 생성된 요약을 확인하고 X 또는 쓰레드 버튼을 클릭하여 공유합니다.

### iOS 앱
1. Safari나 다른 앱에서 블로그 링크를 엽니다.
2. 공유 버튼을 탭합니다.
3. 공유 시트에서 "SNS Connect"를 선택합니다.
4. 요약이 생성되면 X 또는 쓰레드 버튼을 탭하여 공유합니다.

## 기술 스택

- **웹앱**: Next.js 16, TypeScript, Tailwind CSS, Cheerio
- **iOS 앱**: SwiftUI, Swift 5.0
- **블로그 파싱**: Open Graph 메타 태그, HTML 파싱

## 디자인

디자인은 bitcoin tracker 프로젝트의 스타일을 참조했습니다:
- 카드 기반 레이아웃
- RoundedRectangle (cornerRadius: 12)
- 그림자 효과 (opacity: 0.1, radius: 5)
- 시스템 색상 사용

## 라이선스

MIT

