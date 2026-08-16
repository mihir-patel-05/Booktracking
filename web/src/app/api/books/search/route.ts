import { NextResponse, type NextRequest } from "next/server";

export async function GET(request: NextRequest) {
  const query = request.nextUrl.searchParams.get("q")?.trim();
  if (!query || query.length < 2) return NextResponse.json({ items: [] });

  const endpoint = new URL("https://www.googleapis.com/books/v1/volumes");
  endpoint.searchParams.set("q", query.slice(0, 120));
  endpoint.searchParams.set("maxResults", "8");
  endpoint.searchParams.set("printType", "books");
  if (process.env.GOOGLE_BOOKS_API_KEY) endpoint.searchParams.set("key", process.env.GOOGLE_BOOKS_API_KEY);

  try {
    const response = await fetch(endpoint, { next: { revalidate: 3600 } });
    if (!response.ok) throw new Error("Google Books request failed");
    const payload = await response.json() as { items?: Array<{ id: string; volumeInfo?: { title?: string; authors?: string[]; pageCount?: number; imageLinks?: { thumbnail?: string } } }> };
    const items = (payload.items ?? []).flatMap(({ id, volumeInfo }) => {
      if (!volumeInfo?.title || !volumeInfo.pageCount) return [];
      return [{ id, title: volumeInfo.title, author: volumeInfo.authors?.join(", ") || "Unknown author", totalPages: volumeInfo.pageCount, coverUrl: volumeInfo.imageLinks?.thumbnail?.replace("http://", "https://") ?? "" }];
    });
    return NextResponse.json({ items }, { headers: { "Cache-Control": "public, max-age=300, stale-while-revalidate=3600" } });
  } catch {
    return NextResponse.json({ error: "Book search is temporarily unavailable." }, { status: 502 });
  }
}
