'use client';

interface ShareButtonsProps {
  summary: string;
  url: string;
}

// X(트위터) 글자수 제한: 280자 (텍스트 + URL + 공백 모두 포함)
const X_MAX_LENGTH = 280;

function truncateForX(text: string, url: string): string {
  // 전체 텍스트 길이 체크 (텍스트 + 공백 + URL)
  const fullText = `${text} ${url}`;
  
  // 이미 280자 이하면 그대로 반환
  if (fullText.length <= X_MAX_LENGTH) {
    return text;
  }
  
  // URL 길이 + 공백(1자)을 제외한 텍스트 최대 길이 계산
  const urlLength = url.length;
  const spaceLength = 1; // 공백
  const ellipsisLength = 3; // "..."
  
  // 텍스트 최대 길이 = 280 - URL - 공백 - "..."
  // 하지만 "..."은 텍스트 끝에 추가되므로, 실제로는:
  // truncatedText = text.substring(0, maxTextWithoutEllipsis) + "..."
  // finalText = truncatedText + " " + url
  // finalText.length = maxTextWithoutEllipsis + 3 + 1 + urlLength = 280
  // 따라서: maxTextWithoutEllipsis = 280 - 3 - 1 - urlLength
  
  const maxTextWithoutEllipsis = X_MAX_LENGTH - ellipsisLength - spaceLength - urlLength;
  
  // 최소 10자는 보장 (너무 짧으면 의미가 없음)
  if (maxTextWithoutEllipsis < 10) {
    return text.substring(0, 7) + '...';
  }
  
  // 텍스트를 자르고 "..." 추가
  const truncatedText = text.substring(0, maxTextWithoutEllipsis) + '...';
  
  // 최종 확인: 정확히 280자 이하인지 검증
  const finalText = `${truncatedText} ${url}`;
  if (finalText.length > X_MAX_LENGTH) {
    // 계산 오류가 있는 경우, 추가로 자름
    const extraChars = finalText.length - X_MAX_LENGTH;
    const safeLength = Math.max(10, maxTextWithoutEllipsis - extraChars);
    return text.substring(0, safeLength - 3) + '...';
  }
  
  return truncatedText;
}

export default function ShareButtons({ summary, url }: ShareButtonsProps) {
  // X 공유를 위한 텍스트 길이 제한 적용
  const xSummary = truncateForX(summary, url);
  const xShareText = `${xSummary} ${url}`;
  
  const handleShareX = () => {
    const tweetUrl = `https://twitter.com/intent/tweet?text=${encodeURIComponent(xShareText)}`;
    window.open(tweetUrl, '_blank', 'width=550,height=420');
  };
  
  const handleShareThreads = () => {
    // Threads는 웹에서 직접 공유할 수 있는 공식 방법이 제한적이므로
    // 앱이 설치되어 있다면 앱으로 열고, 없으면 웹사이트로 이동
    const threadsShareText = `${summary} ${url}`;
    const threadsUrl = `https://www.threads.net/intent/post?text=${encodeURIComponent(threadsShareText)}`;
    window.open(threadsUrl, '_blank');
  };

  return (
    <div className="flex flex-col gap-3">
      <p className="text-sm font-medium text-gray-600 dark:text-gray-400">
        공유하기
      </p>
      <div className="flex gap-3">
        <button
          onClick={handleShareX}
          className="flex-1 px-6 py-3 bg-black dark:bg-gray-900 text-white rounded-lg 
                   font-medium hover:bg-gray-800 dark:hover:bg-gray-800 
                   focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2
                   transition-colors duration-200 flex items-center justify-center gap-2"
        >
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231zm-1.161 17.52h1.833L7.084 4.126H5.117z"/>
          </svg>
          X (트위터)
        </button>
        
        <button
          onClick={handleShareThreads}
          className="flex-1 px-6 py-3 bg-white dark:bg-gray-800 text-gray-900 dark:text-white 
                   border-2 border-gray-900 dark:border-gray-700 rounded-lg font-medium 
                   hover:bg-gray-50 dark:hover:bg-gray-700 
                   focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2
                   transition-colors duration-200 flex items-center justify-center gap-2"
        >
          <svg className="w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
            <path d="M12.186 8.302c1.399-1.816 3.6-3.027 6.116-3.027 3.755 0 6.698 3.115 6.698 7.27 0 5.417-4.926 10.88-12.814 10.88-3.015 0-5.868-1.236-7.886-3.433.352.055.707.082 1.064.082 2.077 0 4.006-.717 5.53-2.026-1.94-.038-3.577-1.323-4.14-3.092.272.053.549.08.834.08.404 0 .796-.055 1.166-.157-2.028-.411-3.556-2.206-3.556-4.362v-.054c.597.334 1.28.534 2.007.558-1.19-.803-1.973-2.17-1.973-3.72 0-.82.22-1.59.606-2.254 2.203 2.718 5.496 4.505 9.21 4.692-.072-.328-.108-.67-.108-1.019 0-2.474 2.01-4.48 4.49-4.48 1.291 0 2.459.548 3.278 1.426 1.023-.203 1.984-.578 2.852-1.094-.336 1.052-1.048 1.936-1.977 2.493.91-.11 1.778-.352 2.584-.712-.603.909-1.365 1.708-2.243 2.344z"/>
          </svg>
          쓰레드
        </button>
      </div>
    </div>
  );
}

