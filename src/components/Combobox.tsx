import React, { useState, useRef, useEffect, useCallback } from 'react';

interface ComboboxProps {
  value: string;
  onChange: (v: string) => void;
  options: string[];
  placeholder?: string;
  allowCustom?: boolean;
  className?: string;
}

export function Combobox({
  value,
  onChange,
  options,
  placeholder = 'Chọn hoặc nhập...',
  allowCustom = true,
  className = '',
}: ComboboxProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const [highlighted, setHighlighted] = useState(0);
  const containerRef = useRef<HTMLDivElement>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  const filtered = query
    ? options.filter((o) => o.toLowerCase().includes(query.toLowerCase()))
    : options;

  // Show "add custom" option if allowCustom and query not in options
  const showCustom = allowCustom && query.trim() && !options.some((o) => o.toLowerCase() === query.toLowerCase().trim());

  const totalOptions = filtered.length + (showCustom ? 1 : 0);

  useEffect(() => {
    setHighlighted(0);
  }, [query]);

  // Close on outside click
  useEffect(() => {
    function handler(e: MouseEvent) {
      if (containerRef.current && !containerRef.current.contains(e.target as Node)) {
        setOpen(false);
        setQuery('');
      }
    }
    document.addEventListener('mousedown', handler);
    return () => document.removeEventListener('mousedown', handler);
  }, []);

  function openDropdown() {
    setQuery('');
    setHighlighted(0);
    setOpen(true);
    setTimeout(() => inputRef.current?.focus(), 0);
  }

  function select(val: string) {
    onChange(val);
    setOpen(false);
    setQuery('');
  }

  const handleKeyDown = useCallback((e: React.KeyboardEvent) => {
    if (!open) return;
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      setHighlighted((h) => Math.min(h + 1, totalOptions - 1));
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      setHighlighted((h) => Math.max(h - 1, 0));
    } else if (e.key === 'Enter') {
      e.preventDefault();
      if (highlighted < filtered.length) {
        select(filtered[highlighted]);
      } else if (showCustom) {
        select(query.trim());
      }
    } else if (e.key === 'Escape') {
      setOpen(false);
      setQuery('');
    }
  }, [open, highlighted, filtered, showCustom, query]);

  return (
    <div ref={containerRef} className={`relative ${className}`}>
      {/* Trigger button showing current value */}
      <button
        type="button"
        onClick={openDropdown}
        className="w-full flex items-center justify-between px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm text-left outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition hover:border-slate-400 dark:hover:border-slate-500"
      >
        <span className={value ? 'text-slate-900 dark:text-white' : 'text-slate-400'}>
          {value || placeholder}
        </span>
        <span className="material-symbols-outlined text-slate-400 text-sm ml-2 shrink-0">
          {open ? 'expand_less' : 'expand_more'}
        </span>
      </button>

      {/* Dropdown panel */}
      {open && (
        <div className="absolute z-50 top-full mt-1 left-0 right-0 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden">
          {/* Search input */}
          <div className="p-2 border-b border-slate-100 dark:border-slate-800">
            <div className="flex items-center gap-2 px-2 py-1.5 bg-slate-50 dark:bg-slate-800 rounded-lg">
              <span className="material-symbols-outlined text-slate-400 text-sm">search</span>
              <input
                ref={inputRef}
                type="text"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                onKeyDown={handleKeyDown}
                placeholder="Tìm kiếm..."
                className="flex-1 text-sm bg-transparent outline-none text-slate-900 dark:text-white placeholder:text-slate-400"
              />
              {query && (
                <button type="button" onClick={() => setQuery('')} className="text-slate-400 hover:text-slate-600">
                  <span className="material-symbols-outlined text-sm">close</span>
                </button>
              )}
            </div>
          </div>

          {/* Options list */}
          <ul className="max-h-48 overflow-y-auto py-1">
            {filtered.length === 0 && !showCustom && (
              <li className="px-4 py-2 text-sm text-slate-400 text-center">Không tìm thấy</li>
            )}
            {filtered.map((opt, i) => (
              <li key={opt}>
                <button
                  type="button"
                  onClick={() => select(opt)}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors flex items-center gap-2 ${
                    i === highlighted
                      ? 'bg-primary/10 text-primary'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-800 dark:text-slate-200'
                  } ${opt === value ? 'font-semibold' : ''}`}
                  onMouseEnter={() => setHighlighted(i)}
                >
                  {opt === value && (
                    <span className="material-symbols-outlined text-primary text-sm">check</span>
                  )}
                  {opt !== value && <span className="w-4" />}
                  {opt}
                </button>
              </li>
            ))}
            {showCustom && (
              <li>
                <button
                  type="button"
                  onClick={() => select(query.trim())}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors flex items-center gap-2 ${
                    highlighted === filtered.length
                      ? 'bg-primary/10 text-primary'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-500 dark:text-slate-400'
                  }`}
                  onMouseEnter={() => setHighlighted(filtered.length)}
                >
                  <span className="material-symbols-outlined text-sm">add</span>
                  Thêm &ldquo;{query.trim()}&rdquo;
                </button>
              </li>
            )}
          </ul>
        </div>
      )}
    </div>
  );
}
