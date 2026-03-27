export default function Pagination({ current, total, onChange }) {
  if (total <= 1) return null;

  // 현재 페이지 기준 앞뒤 2페이지씩 표시
  const getPageNumbers = () => {
    const pages = [];
    const start = Math.max(1, current - 2);
    const end = Math.min(total, current + 2);
    for (let i = start; i <= end; i++) pages.push(i);
    return pages;
  };

  return (
    <div className="flex justify-center items-center gap-1 mt-8">
      <button
        onClick={() => onChange(1)}
        disabled={current === 1}
        className="px-3 py-1.5 border rounded text-sm hover:bg-gray-100
                   disabled:opacity-30 disabled:cursor-not-allowed"
      >
        처음
      </button>
      <button
        onClick={() => onChange(current - 1)}
        disabled={current === 1}
        className="px-3 py-1.5 border rounded text-sm hover:bg-gray-100
                   disabled:opacity-30 disabled:cursor-not-allowed"
      >
        이전
      </button>
      {getPageNumbers().map((p) => (
        <button
          key={p}
          onClick={() => onChange(p)}
          className={`px-3 py-1.5 border rounded text-sm
            ${p === current
              ? 'bg-[#1a5276] text-white border-[#1a5276]'
              : 'hover:bg-gray-100'}`}
        >
          {p}
        </button>
      ))}
      <button
        onClick={() => onChange(current + 1)}
        disabled={current === total}
        className="px-3 py-1.5 border rounded text-sm hover:bg-gray-100
                   disabled:opacity-30 disabled:cursor-not-allowed"
      >
        다음
      </button>
      <button
        onClick={() => onChange(total)}
        disabled={current === total}
        className="px-3 py-1.5 border rounded text-sm hover:bg-gray-100
                   disabled:opacity-30 disabled:cursor-not-allowed"
      >
        끝
      </button>
    </div>
  );
}
