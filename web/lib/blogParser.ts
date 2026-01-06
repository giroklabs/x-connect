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
    
    // 요약 텍스트 생성 (간단하고 짧게)
    // X 공유를 위해 최대 120자로 제한 (URL + 공백 고려 시 안전한 길이)
    let summary = ogDescription.trim();
    
    if (summary) {
      // 설명이 있으면 120자로 제한
      if (summary.length > 120) {
        // 문장 단위로 자르기 (마지막 문장 부호 기준)
        const truncated = summary.substring(0, 117);
        const lastPeriod = truncated.lastIndexOf('。');
        const lastPeriodKr = truncated.lastIndexOf('.');
        const lastPeriodKr2 = truncated.lastIndexOf('!');
        const lastPeriodKr3 = truncated.lastIndexOf('?');
        const lastBreak = Math.max(lastPeriod, lastPeriodKr, lastPeriodKr2, lastPeriodKr3);
        
        if (lastBreak > 50) {
          // 문장 끝이 있으면 그곳에서 자름
          summary = truncated.substring(0, lastBreak + 1);
        } else {
          // 문장 끝이 없으면 그냥 자름
          summary = truncated + '...';
        }
      }
    } else if (firstParagraph) {
      // 첫 문단 사용 (120자로 제한)
      if (firstParagraph.length > 120) {
        const truncated = firstParagraph.substring(0, 117);
        const lastPeriod = truncated.lastIndexOf('。');
        const lastPeriodKr = truncated.lastIndexOf('.');
        const lastBreak = Math.max(lastPeriod, lastPeriodKr);
        
        if (lastBreak > 50) {
          summary = truncated.substring(0, lastBreak + 1);
        } else {
          summary = truncated + '...';
        }
      } else {
        summary = firstParagraph;
      }
    } else {
      // 제목만 사용 (최대 100자)
      summary = ogTitle || '블로그 포스트';
      if (summary.length > 100) {
        summary = summary.substring(0, 97) + '...';
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

