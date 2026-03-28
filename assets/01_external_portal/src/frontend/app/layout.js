import "./globals.css";
import Header from "../components/Header";
import Footer from "../components/Footer";

export const metadata = {
  title: "MOIS Portal - Republic of Valdoria",
  description:
    "Official portal of the Ministry of Interior and Safety, Republic of Valdoria. Access government notices, services, and inquiry tracking.",
  keywords: "Valdoria, MOIS, government, portal, ministry, safety",
};

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className="flex flex-col min-h-screen">
        <Header />
        <main className="flex-1">{children}</main>
        <Footer />
      </body>
    </html>
  );
}
