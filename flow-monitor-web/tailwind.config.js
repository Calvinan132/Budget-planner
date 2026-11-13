/** @type {import('tailwindcss').Config} */
export default {
  content: [
    "./index.html",
    "./src/**/*.{js,ts,jsx,tsx}",
  ],
  theme: {
    extend: {
      colors: {
        flowDark: {
          950: '#070b13',
          900: '#0c1322',
          800: '#172238',
          700: '#233352',
        }
      }
    },
  },
  plugins: [],
}

