'use client';

interface LinkInputProps {
  value: string;
  onChange: (value: string) => void;
  onSubmit: () => void;
  isLoading: boolean;
}

export default function LinkInput({ value, onChange, onSubmit, isLoading }: LinkInputProps) {
  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!isLoading && value.trim()) {
      onSubmit();
    }
  };

  return (
    <form onSubmit={handleSubmit} className="w-full">
      <div className="flex flex-col gap-2">
        <label htmlFor="blog-url" className="text-sm font-medium text-gray-600 dark:text-gray-400">
          블로그 링크 입력
        </label>
        <div className="flex gap-2">
          <input
            id="blog-url"
            type="url"
            value={value}
            onChange={(e) => onChange(e.target.value)}
            placeholder="https://example.com/blog-post"
            className="flex-1 px-4 py-3 border border-gray-300 dark:border-gray-600 rounded-lg 
                     focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent
                     bg-white dark:bg-gray-800 text-gray-900 dark:text-white
                     placeholder:text-gray-400 dark:placeholder:text-gray-500"
            disabled={isLoading}
          />
          <button
            type="submit"
            disabled={isLoading || !value.trim()}
            className="px-6 py-3 bg-blue-600 text-white rounded-lg font-medium
                     hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2
                     disabled:bg-gray-400 disabled:cursor-not-allowed
                     transition-colors duration-200"
          >
            {isLoading ? '처리 중...' : '요약'}
          </button>
        </div>
      </div>
    </form>
  );
}

