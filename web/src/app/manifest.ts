import type { MetadataRoute } from "next";

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: "PageFlow",
    short_name: "PageFlow",
    description: "Focused reading sessions, reflections, notes, quotes, and momentum.",
    start_url: "/app",
    display: "standalone",
    background_color: "#0d0d0d",
    theme_color: "#0d0d0d",
    icons: [{ src: "/brand/pageflow-logo.svg", sizes: "any", type: "image/svg+xml", purpose: "any" }],
  };
}
