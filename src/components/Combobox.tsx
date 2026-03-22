import React, { useState, useRef, useEffect, useCallback } from 'react';

export interface ComboboxOption {
  value: string;
  label: string;
}

interface ComboboxProps {
  value: string;
  onChange: (v: string) => void;
  options: ComboboxOption[] | string[];
  placeholder?: string;
  allowCustom?: boolean;
  className?: string;
}

function normalizeOptions(opts: ComboboxOption[] | string[]): ComboboxOption[] {
  if (opts.length === 0) return [];
  if (typeof opts[0] === 'string') {
    return (opts as string[]).map((s) => ({ value: s, label: s }));
  }
  return opts as ComboboxOption[];
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

  const normalized = normalizeOptions(options);

  const filtered = query
    ? normalized.filter((o) => o.label.toLowerCase().includes(query.toLowerCase()))
    : normalized;

  const showCustom = allowCustom && query.trim() && !normalized.some((o) => o.label.toLowerCase() === query.toLowerCase().trim());

  const totalOptions = filtered.length + (showCustom ? 1 : 0);

  const displayLabel = normalized.find((o) => o.value === value)?.label ?? value;

  useEffect(() => {
    setHighlighted(0);
  }, [query]);

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
        select(filtered[highlighted].value);
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
      <button
        type="button"
        onClick={openDropdown}
        className="w-full flex items-center justify-between px-3 py-1.5 bg-white dark:bg-slate-800 border border-slate-300 dark:border-slate-600 rounded-lg text-sm text-left outline-none focus:ring-2 focus:ring-primary/30 focus:border-primary transition hover:border-slate-400 dark:hover:border-slate-500"
      >
        <span className={value ? 'text-slate-900 dark:text-white' : 'text-slate-400'}>
          {value ? displayLabel : placeholder}
        </span>
        <span className="material-symbols-outlined text-slate-400 text-sm ml-2 shrink-0">
          {open ? 'expand_less' : 'expand_more'}
        </span>
      </button>

      {open && (
        <div className="absolute z-50 top-full mt-1 left-0 right-0 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-xl shadow-lg overflow-hidden">
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

          <ul className="max-h-48 overflow-y-auto py-1">
            {filtered.length === 0 && !showCustom && (
              <li className="px-4 py-2 text-sm text-slate-400 text-center">Không tìm thấy</li>
            )}
            {filtered.map((opt, i) => (
              <li key={opt.value}>
                <button
                  type="button"
                  onClick={() => select(opt.value)}
                  className={`w-full text-left px-4 py-2 text-sm transition-colors flex items-center gap-2 ${
                    i === highlighted
                      ? 'bg-primary/10 text-primary'
                      : 'hover:bg-slate-50 dark:hover:bg-slate-800 text-slate-800 dark:text-slate-200'
                  } ${opt.value === value ? 'font-semibold' : ''}`}
                  onMouseEnter={() => setHighlighted(i)}
                >
                  {opt.value === value && (
                    <span className="material-symbols-outlined text-primary text-sm">check</span>
                  )}
                  {opt.value !== value && <span className="w-4" />}
                  {opt.label}
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
