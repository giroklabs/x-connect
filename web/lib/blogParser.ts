export interface BlogInfo {
  title: string;
  description: string;
  image?: string;
  url: string;
  summary: string;
}

/**
 * 메타 태그에서 속성값 추출 (브라우저 환경용)
 */
function getMetaContent(html: string, property?: string, name?: string): string {
  let pattern = '';
  if (property) {
    pattern = `<meta[^>]*(?:property|name)=["']${property}["'][^>]*content=["']([^"']+)["']`;
  } else if (name) {
    pattern = `<meta[^>]*name=["']${name}["'][^>]*content=["']([^"']+)["']`;
  }
  
  if (pattern) {
    const regex = new RegExp(pattern, 'i');
    const match = html.match(regex);
    if (match && match[1]) {
      return match[1];
    }
  }
  return '';
}

/**
 * HTML에서 텍스트 추출
 */
function extractText(html: string, selector: string): string {
  const regex = new RegExp(`<${selector}[^>]*>([^<]+)</${selector}>`, 'i');
  const match = html.match(regex);
  return match && match[1] ? match[1].trim() : '';
}

/**
 * 블로그 URL에서 메타 태그를 추출하여 요약 정보를 생성합니다.
 * 브라우저 환경에서 작동하도록 구현 (cheerio 대신 정규식 사용)
 */
export async function extractBlogInfo(url: string): Promise<BlogInfo> {
  try {
    // URL 유효성 검사
    const urlObj = new URL(url);
    
    // CORS 프록시를 통해 HTML 가져오기 (GitHub Pages 환경)
    // 직접 fetch는 CORS 문제가 있을 수 있으므로 프록시 사용
    const proxyUrl = `https://api.allorigins.win/get?url=${encodeURIComponent(url)}`;
    
    let html: string;
    try {
      const proxyResponse = await fetch(proxyUrl);
      if (!proxyResponse.ok) {
        throw new Error(`Failed to fetch via proxy: ${proxyResponse.statusText}`);
      }
      const proxyData = await proxyResponse.json();
      html = proxyData.contents;
    } catch (proxyError) {
      // 프록시 실패 시 직접 시도 (CORS 허용된 경우)
      const response = await fetch(url, {
        mode: 'cors',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
        },
      } as RequestInit);
      
      if (!response.ok) {
        throw new Error(`Failed to fetch: ${response.statusText}`);
      }
      html = await response.text();
    }
    
    // Open Graph 메타 태그 추출
    const ogTitle = getMetaContent(html, 'og:title') ||
                    getMetaContent(html, undefined, 'twitter:title') ||
                    extractText(html, 'title') ||
                    '';
    
    const ogDescription = getMetaContent(html, 'og:description') ||
                         getMetaContent(html, undefined, 'twitter:description') ||
                         getMetaContent(html, undefined, 'description') ||
                         '';
    
    const ogImage = getMetaContent(html, 'og:image') ||
                   getMetaContent(html, undefined, 'twitter:image') ||
                   '';
    
    const ogUrl = getMetaContent(html, 'og:url') || url;
    
    // 첫 문단 추출 (fallback용) - 정규식으로 간단히 추출
    let firstParagraph = '';
    const articleMatch = html.match(/<article[^>]*>[\s\S]*?<p[^>]*>([^<]+)<\/p>/i);
    if (articleMatch && articleMatch[1]) {
      firstParagraph = articleMatch[1].trim();
    } else {
      const pMatch = html.match(/<p[^>]*>([^<]+)<\/p>/i);
      if (pMatch && pMatch[1]) {
        firstParagraph = pMatch[1].trim();
      }
    }
    
    // 요약 텍스트 생성 (간단하고 짧게, 완전한 문장으로 끝나도록)
    // X 공유를 위해 최대 120자로 제한 (URL + 공백 고려 시 안전한 길이)
    let summary = ogDescription.trim();
    
    // 문장 단위로 자르는 함수 (완전한 문장으로 끝나도록)
    const truncateToSentence = (text: string, maxLength: number): string => {
      if (text.length <= maxLength) {
        return text;
      }
      
      // 완전한 문장을 찾기 위해 maxLength를 약간 넘어서도 검색 (최대 15자까지 확장)
      const searchLength = Math.min(text.length, maxLength + 15);
      const searchText = text.substring(0, searchLength);
      
      // 문장 부호를 찾아서 완전한 문장으로 끝나도록 조정
      // 한국어와 영어 문장 부호 모두 고려
      const sentenceEnders = ['.', '。', '!', '?', '…'];
      let bestBreak = -1;
      let perfectBreak = -1; // 문장 부호 + 공백이 있는 완벽한 경우
      
      // 뒤에서부터 문장 부호를 찾음 (가장 가까운 완전한 문장 끝)
      // maxLength 이내에서 우선 검색, 없으면 확장 범위에서 검색
      for (let i = searchText.length - 1; i >= Math.max(0, maxLength - 80); i--) {
        if (sentenceEnders.includes(searchText[i])) {
          // 숫자나 약어에 포함된 점인지 확인 (예: "2026.1.6.", "U.S.A.")
          // 하지만 "습니다.", "니다." 같은 한국어 패턴은 허용
          const prevChar = i > 0 ? searchText[i - 1] : '';
          const isInNumberOrAbbr = i > 0 && 
            (/\d/.test(prevChar) || (/[A-Za-z]/.test(prevChar) && !/[다습니요]/.test(prevChar)));
          
          if (!isInNumberOrAbbr) {
            // 문장 부호가 마지막 문자이면 완벽한 문장 끝
            if (i === searchText.length - 1) {
              perfectBreak = i + 1;
              break;
            }
            const nextChar = searchText[i + 1];
            // 문장 부호 뒤에 공백/줄바꿈이 있으면 완벽한 문장 끝
            if (nextChar === ' ' || nextChar === '\n' || nextChar === '\r') {
              perfectBreak = i + 1;
              break;
            } else if (bestBreak === -1) {
              // 첫 번째로 찾은 문장 부호는 백업으로 저장
              bestBreak = i + 1;
            }
          }
        }
      }
      
      // 완벽한 문장 끝을 우선 사용 (maxLength를 약간 넘어도 허용)
      if (perfectBreak > 0) {
        const result = searchText.substring(0, perfectBreak).trim();
        // maxLength를 크게 넘지 않는 경우에만 사용 (최대 15자까지 허용)
        // 완전한 문장을 위해 약간의 여유를 둠
        if (result.length <= maxLength + 15) {
          return result;
        }
      }
      
      // 완벽한 문장 끝이 없거나 너무 길면, maxLength 이내에서 일반 문장 부호 사용
      const truncated = text.substring(0, maxLength);
      if (bestBreak > 0 && bestBreak <= maxLength && bestBreak >= maxLength - 30) {
        return truncated.substring(0, bestBreak).trim();
      }
      
      // 문장 부호를 찾지 못했으면, 단어 단위로 자르기 시도
      const lastSpace = truncated.lastIndexOf(' ');
      if (lastSpace > maxLength - 20) {
        return truncated.substring(0, lastSpace) + '...';
      }
      
      // 단어도 없으면 그냥 자르되 "..." 추가
      return truncated.trim() + '...';
    };
    
    if (summary) {
      // 설명이 있으면 120자로 제한 (완전한 문장으로)
      summary = truncateToSentence(summary, 120);
    } else if (firstParagraph) {
      // 첫 문단 사용 (120자로 제한, 완전한 문장으로)
      summary = truncateToSentence(firstParagraph, 120);
    } else {
      // 제목만 사용 (최대 100자)
      summary = ogTitle || '블로그 포스트';
      if (summary.length > 100) {
        summary = truncateToSentence(summary, 100);
      }
    }
    
    // 이미지 URL 정규화 (상대 경로를 절대 경로로 변환)
    let imageUrl = ogImage;
    if (imageUrl && !imageUrl.startsWith('http')) {
      imageUrl = new URL(imageUrl, url).href;
    }
    
    return {
      title: ogTitle || '제목 없음',
      description: ogDescription || summary,
      image: imageUrl || undefined,
      url: ogUrl,
      summary: summary,
    };
  } catch (error) {
    console.error('Error extracting blog info:', error);
    throw new Error(`블로그 정보를 가져올 수 없습니다: ${error instanceof Error ? error.message : '알 수 없는 오류'}`);
  }
}

