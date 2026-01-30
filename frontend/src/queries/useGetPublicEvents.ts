import {useQuery} from "@tanstack/react-query";
import {eventsClientPublic} from "../api/event.client.ts";

export const GET_PUBLIC_EVENTS_QUERY_KEY = 'getPublicEvents';

export const useGetPublicEvents = () => {
    return useQuery({
        queryKey: [GET_PUBLIC_EVENTS_QUERY_KEY],
        queryFn: async () => {
            return await eventsClientPublic.all();
        }
    });
};
