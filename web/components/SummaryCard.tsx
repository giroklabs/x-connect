'use client';

import { BlogInfo } from '@/lib/blogParser';

interface SummaryCardProps {
  blogInfo: BlogInfo;
}

export default function SummaryCard({ blogInfo }: SummaryCardProps) {
  return (
    <div className="w-full bg-white dark:bg-gray-800 rounded-xl shadow-lg p-6 
                  border border-gray-200 dark:border-gray-700">
      {blogInfo.image && (
        <div className="mb-4 rounded-lg overflow-hidden">
          <img 
            src={blogInfo.image} 
            alt={blogInfo.title}
            className="w-full h-48 object-cover"
            onError={(e) => {
              (e.target as HTMLImageElement).style.display = 'none';
            }}
          />
        </div>
      )}
      
      <div className="space-y-3">
        <div>
          <h2 className="text-xl font-bold text-gray-900 dark:text-white mb-2">
            {blogInfo.title}
          </h2>
          <p className="text-gray-600 dark:text-gray-300 leading-relaxed">
            {blogInfo.summary}
          </p>
        </div>
        
        <div className="pt-3 border-t border-gray-200 dark:border-gray-700">
          <a 
            href={blogInfo.url} 
            target="_blank" 
            rel="noopener noreferrer"
            className="text-sm text-blue-600 dark:text-blue-400 hover:underline"
          >
            원문 보기 →
          </a>
        </div>
      </div>
    </div>
  );
}

