/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./app/**/*.{js,ts,jsx,tsx}",
    "./components/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        valdoria: {
          navy: "#1B3A5C",
          "navy-dark": "#0F2640",
          "navy-light": "#2A5580",
          gold: "#D4A843",
          "gold-light": "#E8C876",
          "gold-dark": "#B8902E",
          cream: "#FAF8F5",
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
};
