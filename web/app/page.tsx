'use client';

import { useState } from 'react';
import LinkInput from '@/components/LinkInput';
import SummaryCard from '@/components/SummaryCard';
import ShareButtons from '@/components/ShareButtons';
import { BlogInfo, extractBlogInfo } from '@/lib/blogParser';

export default function Home() {
  const [url, setUrl] = useState('');
  const [blogInfo, setBlogInfo] = useState<BlogInfo | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async () => {
    if (!url.trim()) return;
    
    setIsLoading(true);
    setError(null);
    setBlogInfo(null);
    
    try {
      // GitHub Pages는 API 라우트를 지원하지 않으므로 클라이언트 사이드에서 직접 처리
      const data = await extractBlogInfo(url.trim());
      setBlogInfo(data);
    } catch (err) {
      setError(err instanceof Error ? err.message : '알 수 없는 오류가 발생했습니다.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <main className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <div className="container mx-auto px-4 py-8 max-w-2xl">
        {/* Header */}
        <div className="mb-8 text-center">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-2">
            SNS Connect
          </h1>
          <p className="text-gray-600 dark:text-gray-400">
            블로그 글을 X와 쓰레드에 쉽게 공유하세요
          </p>
        </div>

        {/* Link Input Card */}
        <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 mb-6
                      border border-gray-200 dark:border-gray-700">
          <LinkInput
            value={url}
            onChange={setUrl}
            onSubmit={handleSubmit}
            isLoading={isLoading}
          />
        </div>

        {/* Error Message */}
        {error && (
          <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 
                        rounded-xl p-4 mb-6">
            <div className="flex items-center gap-2">
              <svg className="w-5 h-5 text-red-600 dark:text-red-400" fill="currentColor" viewBox="0 0 20 20">
                <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zM8.707 7.293a1 1 0 00-1.414 1.414L8.586 10l-1.293 1.293a1 1 0 101.414 1.414L10 11.414l1.293 1.293a1 1 0 001.414-1.414L11.414 10l1.293-1.293a1 1 0 00-1.414-1.414L10 8.586 8.707 7.293z" clipRule="evenodd" />
              </svg>
              <p className="text-red-800 dark:text-red-200">{error}</p>
            </div>
          </div>
        )}

        {/* Loading State */}
        {isLoading && (
          <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-12 
                        border border-gray-200 dark:border-gray-700 text-center">
            <div className="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
            <p className="mt-4 text-gray-600 dark:text-gray-400">블로그 정보를 가져오는 중...</p>
          </div>
        )}

        {/* Summary Card */}
        {blogInfo && (
          <div className="space-y-6">
            <SummaryCard blogInfo={blogInfo} />
            
            {/* Share Buttons Card */}
            <div className="bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6
                          border border-gray-200 dark:border-gray-700">
              <ShareButtons summary={blogInfo.summary} url={blogInfo.url} />
            </div>
          </div>
        )}
      </div>
    </main>
  );
}
