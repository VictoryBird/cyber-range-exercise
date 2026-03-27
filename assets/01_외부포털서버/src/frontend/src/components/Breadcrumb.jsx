import { Link } from 'react-router-dom';

export default function Breadcrumb({ items }) {
  return (
    <nav className="text-sm text-gray-500 py-3">
      {items.map((item, i) => (
        <span key={i}>
          {i > 0 && <span className="mx-1">&gt;</span>}
          {item.to ? (
            <Link to={item.to} className="hover:text-[#1a5276]">{item.label}</Link>
          ) : (
            <span className="text-gray-800 font-medium">{item.label}</span>
          )}
        </span>
      ))}
    </nav>
  );
}
