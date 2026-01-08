import {useQuery} from "@tanstack/react-query";
import {userClient} from "../api/user.client.ts";
import {QueryFilters, UserEventsMeta, Event, GenericPaginatedResponse} from "../types.ts";

export const GET_USER_EVENTS_QUERY_KEY = 'getUserEvents';

export type UserEventsResponse = GenericPaginatedResponse<Event> & {
    meta: UserEventsMeta;
};

export const useGetUserEvents = (pagination: QueryFilters) => {
    return useQuery<UserEventsResponse>({
        queryKey: [GET_USER_EVENTS_QUERY_KEY, pagination],
        queryFn: async () => {
            return await userClient.myEvents(pagination) as UserEventsResponse;
        }
    });
};
