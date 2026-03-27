/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        gov: {
          900: '#0d2e4a',
          800: '#133a5c',
          700: '#1a5276',
          600: '#216a99',
          500: '#2980b9',
          400: '#5dade2',
          300: '#85c1e9',
          200: '#aed6f1',
          100: '#d6eaf8',
          50:  '#ebf5fb',
        },
        amber: {
          500: '#c8a84e',
          400: '#d4b96a',
          300: '#e0ca86',
        },
        status: {
          received: '#3498db',
          processing: '#f39c12',
          completed: '#27ae60',
          rejected: '#e74c3c',
        }
      },
      fontFamily: {
        sans: ['Pretendard', 'Noto Sans KR', 'sans-serif'],
        display: ['Pretendard', 'sans-serif'],
      },
      backgroundImage: {
        'gov-pattern': `url("data:image/svg+xml,%3Csvg width='60' height='60' xmlns='http://www.w3.org/2000/svg'%3E%3Cpath d='M30 0L60 30L30 60L0 30Z' fill='none' stroke='%231a5276' stroke-width='0.5' opacity='0.08'/%3E%3C/svg%3E")`,
        'seal-ring': `url("data:image/svg+xml,%3Csvg width='200' height='200' xmlns='http://www.w3.org/2000/svg'%3E%3Ccircle cx='100' cy='100' r='90' fill='none' stroke='%23c8a84e' stroke-width='2' opacity='0.15'/%3E%3Ccircle cx='100' cy='100' r='70' fill='none' stroke='%23c8a84e' stroke-width='1' opacity='0.1'/%3E%3C/svg%3E")`,
      },
      animation: {
        'fade-up': 'fadeUp 0.6s ease-out both',
        'fade-in': 'fadeIn 0.5s ease-out both',
        'slide-in': 'slideIn 0.4s ease-out both',
        'scale-in': 'scaleIn 0.3s ease-out both',
        'pulse-soft': 'pulseSoft 2s ease-in-out infinite',
      },
      keyframes: {
        fadeUp: {
          '0%': { opacity: '0', transform: 'translateY(24px)' },
          '100%': { opacity: '1', transform: 'translateY(0)' },
        },
        fadeIn: {
          '0%': { opacity: '0' },
          '100%': { opacity: '1' },
        },
        slideIn: {
          '0%': { opacity: '0', transform: 'translateX(-16px)' },
          '100%': { opacity: '1', transform: 'translateX(0)' },
        },
        scaleIn: {
          '0%': { opacity: '0', transform: 'scale(0.95)' },
          '100%': { opacity: '1', transform: 'scale(1)' },
        },
        pulseSoft: {
          '0%, 100%': { opacity: '1' },
          '50%': { opacity: '0.7' },
        },
      },
    },
  },
  plugins: [],
}
