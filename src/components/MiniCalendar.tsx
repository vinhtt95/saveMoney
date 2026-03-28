import { useState, useEffect } from 'react';
import { toYYYYMMDD } from '../utils/formatters';

export type CalendarAccentColor = 'rose' | 'emerald' | 'blue';

interface MiniCalendarProps {
  value: string;          // YYYY-MM-DD
  onChange: (date: string) => void;
  accentColor: CalendarAccentColor;
}

const SELECTED_CLASSES: Record<CalendarAccentColor, string> = {
  rose: 'bg-rose-500 text-white',
  emerald: 'bg-emerald-500 text-white',
  blue: 'bg-blue-500 text-white',
};

const HOVER_CLASSES: Record<CalendarAccentColor, string> = {
  rose: 'hover:bg-rose-50 dark:hover:bg-rose-900/20',
  emerald: 'hover:bg-emerald-50 dark:hover:bg-emerald-900/20',
  blue: 'hover:bg-blue-50 dark:hover:bg-blue-900/20',
};

const WEEKDAYS = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];

export function MiniCalendar({ value, onChange, accentColor }: MiniCalendarProps) {
  const [viewYear, setViewYear] = useState<number>(new Date().getFullYear());
  const [viewMonth, setViewMonth] = useState<number>(new Date().getMonth());

  // Sync viewYear and viewMonth when value prop changes
  useEffect(() => {
    try {
      const date = new Date(value + 'T00:00:00');
      setViewYear(date.getFullYear());
      setViewMonth(date.getMonth());
    } catch {
      // Invalid date, keep current view
    }
  }, [value]);

  // Parse current selected date
  let selectedYear = new Date().getFullYear();
  let selectedMonth = new Date().getMonth();
  let selectedDay = new Date().getDate();
  try {
    const date = new Date(value + 'T00:00:00');
    selectedYear = date.getFullYear();
    selectedMonth = date.getMonth();
    selectedDay = date.getDate();
  } catch {
    // Invalid date
  }

  // Today's date
  const today = new Date();
  const todayYear = today.getFullYear();
  const todayMonth = today.getMonth();
  const todayDay = today.getDate();

  // Build calendar cells for viewYear/viewMonth
  function buildCalendar() {
    const firstDay = new Date(viewYear, viewMonth, 1).getDay();
    const daysInMonth = new Date(viewYear, viewMonth + 1, 0).getDate();
    const cells: (number | null)[] = [];

    // Leading nulls
    for (let i = 0; i < firstDay; i++) {
      cells.push(null);
    }

    // Days of month
    for (let i = 1; i <= daysInMonth; i++) {
      cells.push(i);
    }

    // Trailing nulls to fill 42 cells (6×7)
    while (cells.length < 42) {
      cells.push(null);
    }

    return cells;
  }

  function prevMonth() {
    if (viewMonth === 0) {
      setViewMonth(11);
      setViewYear(y => y - 1);
    } else {
      setViewMonth(m => m - 1);
    }
  }

  function nextMonth() {
    if (viewMonth === 11) {
      setViewMonth(0);
      setViewYear(y => y + 1);
    } else {
      setViewMonth(m => m + 1);
    }
  }

  function handleDayClick(day: number) {
    const date = new Date(viewYear, viewMonth, day);
    onChange(toYYYYMMDD(date));
  }

  const cells = buildCalendar();

  return (
    <div className="flex flex-col gap-2 select-none">
      {/* Header: prev / month / next */}
      <div className="flex items-center justify-between px-1">
        <button
          type="button"
          onClick={prevMonth}
          className="flex items-center justify-center w-6 h-6 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
        >
          <span className="material-symbols-outlined text-lg">chevron_left</span>
        </button>
        <span className="text-xs font-semibold text-slate-600 dark:text-slate-300 min-w-fit">
          Tháng {viewMonth + 1} / {viewYear}
        </span>
        <button
          type="button"
          onClick={nextMonth}
          className="flex items-center justify-center w-6 h-6 rounded-lg text-slate-600 dark:text-slate-400 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors"
        >
          <span className="material-symbols-outlined text-lg">chevron_right</span>
        </button>
      </div>

      {/* Weekday headers */}
      <div className="grid grid-cols-7 gap-0.5">
        {WEEKDAYS.map((day) => (
          <div
            key={day}
            className="text-[10px] font-bold text-slate-400 text-center h-5 flex items-center justify-center"
          >
            {day}
          </div>
        ))}
      </div>

      {/* Day grid */}
      <div className="grid grid-cols-7 gap-0.5 min-w-0">
        {cells.map((day, i) => {
          if (day === null) {
            return <div key={i} />;
          }

          const isSelected = day === selectedDay && viewMonth === selectedMonth && viewYear === selectedYear;
          const isToday = day === todayDay && viewMonth === todayMonth && viewYear === todayYear;

          return (
            <button
              key={i}
              type="button"
              onClick={() => handleDayClick(day)}
              className={`
                w-full aspect-square flex items-center justify-center rounded-full text-xs font-medium
                transition-colors
                ${isSelected ? SELECTED_CLASSES[accentColor] : ''}
                ${isToday && !isSelected ? 'ring-1 ring-slate-400 dark:ring-slate-500' : ''}
                ${!isSelected ? `text-slate-700 dark:text-slate-200 ${HOVER_CLASSES[accentColor]}` : ''}
              `}
            >
              {day}
            </button>
          );
        })}
      </div>
    </div>
  );
}
