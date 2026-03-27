import { useState } from 'react';
import { useNavigate } from 'react-router-dom';

export default function SearchBar({ initialValue = '', placeholder = '검색어를 입력하세요' }) {
  const [query, setQuery] = useState(initialValue);
  const navigate = useNavigate();

  const handleSubmit = (e) => {
    e.preventDefault();
    if (query.trim()) {
      navigate(`/search?q=${encodeURIComponent(query.trim())}`);
    }
  };

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <input
        type="text"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        placeholder={placeholder}
        className="flex-1 border-2 border-gray-300 rounded px-4 py-2
                   focus:border-[#1a5276] focus:outline-none"
      />
      <button
        type="submit"
        className="px-6 py-2 bg-[#1a5276] text-white rounded hover:bg-[#154360]"
      >
        검색
      </button>
    </form>
  );
}
