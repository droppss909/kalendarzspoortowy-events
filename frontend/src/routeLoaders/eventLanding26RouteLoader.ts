import {eventsClientPublic} from "../api/event.client.ts";
import {EventStatus} from "../types.ts";

const EVENT_ID = 1;

export const eventLanding26RouteLoader = async () => {
    try {
        const {data} = await eventsClientPublic.findByID(EVENT_ID, null);
        if (data?.status !== EventStatus.LIVE) {
            return {event: null};
        }
        return {event: data};
    } catch (error: any) {
        if (error?.response?.status === 404) {
            return {event: null};
        }

        console.error(error);
        throw error;
    }
};
