export const CUSTOM_EVENT_LANDING_PAGES: Record<number, string> = {
    1: "/l/korba",
};

export const getCustomEventLandingPath = (eventId?: number | string) => {
    if (!eventId) {
        return null;
    }

    const numericId = typeof eventId === "string" ? Number(eventId) : eventId;
    if (!Number.isFinite(numericId)) {
        return null;
    }

    return CUSTOM_EVENT_LANDING_PAGES[numericId] || null;
};
