/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,jsx,ts,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        gov: {
          navy: "#1B2A4A",
          "navy-dark": "#0F1E36",
          "navy-light": "#2A3F6A",
          gold: "#D4A843",
          "gold-light": "#E8C876",
          "gold-dark": "#B8902E",
          cream: "#FFF9F0",
          "cream-dark": "#F5EFE0",
          slate: "#64748B",
        },
      },
      fontFamily: {
        sans: [
          "Inter",
          "-apple-system",
          "BlinkMacSystemFont",
          "Segoe UI",
          "Roboto",
          "sans-serif",
        ],
      },
    },
  },
  plugins: [],
}
