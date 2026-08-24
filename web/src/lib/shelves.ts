/** The four shelves a volume can stand on, and how the register names them. */
export const SHELVES = [
  { status: "Currently Reading", label: "Reading", tag: "tag-accent" },
  { status: "Want to Read", label: "To read", tag: "tag-outline" },
  { status: "Completed", label: "Finished", tag: "tag-neutral" },
  { status: "Abandoned", label: "Set aside", tag: "tag-outline" },
] as const;

export const SHELF_STATUSES = ["Currently Reading", "Want to Read", "Completed", "Abandoned"] as const;

export const SHELF_BY_STATUS = new Map<string, (typeof SHELVES)[number]>(SHELVES.map((shelf) => [shelf.status, shelf]));
