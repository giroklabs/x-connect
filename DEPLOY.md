# GitHub Pages 배포 가이드

## 사전 준비

1. GitHub 저장소가 이미 생성되어 있어야 합니다: `https://github.com/giroklabs/x-connect`

## 배포 방법

### 방법 1: GitHub Actions를 통한 자동 배포 (권장)

1. GitHub 저장소에 코드를 푸시합니다:
```bash
cd /Users/greego/Desktop/x-connect
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/giroklabs/x-connect.git
git push -u origin main
```

2. GitHub 저장소 설정:
   - Settings > Pages로 이동
   - Source를 "GitHub Actions"로 선택
   - 저장하면 자동으로 배포가 시작됩니다

3. 이후 `main` 브랜치에 푸시할 때마다 자동으로 배포됩니다.

### 방법 2: 수동 배포

1. 로컬에서 빌드:
```bash
cd web
npm install
npm run build
```

2. `web/out` 폴더의 내용을 GitHub Pages에 업로드:
   - Settings > Pages로 이동
   - Source를 "Deploy from a branch"로 선택
   - Branch를 `gh-pages`로 선택하고 `/root` 또는 `/docs` 선택
   - `out` 폴더의 내용을 선택한 경로에 푸시

## 주의사항

- GitHub Pages는 정적 사이트만 지원하므로 API 라우트는 작동하지 않습니다.
- 따라서 블로그 파싱을 클라이언트 사이드에서 직접 처리하도록 변경했습니다.
- CORS 문제를 해결하기 위해 프록시 서비스(AllOrigins)를 사용합니다.
- 일부 사이트는 CORS 정책으로 인해 접근이 제한될 수 있습니다.

## 접속 URL

배포 후 다음 URL에서 접속할 수 있습니다:
- `https://giroklabs.github.io/x-connect/`

## 빌드 확인

로컬에서 빌드 테스트:
```bash
cd web
npm run build
```

빌드된 파일은 `web/out` 폴더에 생성됩니다.
