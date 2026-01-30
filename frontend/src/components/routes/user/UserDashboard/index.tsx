import React, {useMemo} from 'react';
import {Button, Group, Skeleton} from '@mantine/core';
import {NavLink} from 'react-router';
import {IconAlertTriangle, IconCalendar, IconChevronRight, IconFlag, IconUserCircle} from '@tabler/icons-react';
import {t, Trans} from '@lingui/macro';
import dayjs from 'dayjs';

import {PageTitle} from '../../../common/PageTitle';
import {PageBody} from '../../../common/PageBody';
import {Card} from '../../../common/Card';
import {StatBox} from '../../../common/StatBoxes';
import {useGetMe} from '../../../../queries/useGetMe.ts';
import {useGetPublicEvents} from '../../../../queries/useGetPublicEvents.ts';
import {useGetUserEvents} from '../../../../queries/useGetUserEvents.ts';
import {Event, QueryFilters} from '../../../../types.ts';
import {formatNumber} from '../../../../utilites/helpers.ts';
import {formatDate, isDateInFuture} from '../../../../utilites/dates.ts';
import {eventHomepagePath} from '../../../../utilites/urlHelper.ts';
import {EventCard as PublicEventCard} from '../../../layouts/OrganizerHomepage/EventCard';
import classes from './UserDashboard.module.scss';

const UserDashboardSkeleton = () => {
    return (
        <PageBody>
            <Group justify="space-between" mb="xl">
                <Skeleton height={36} radius="md" width="60%"/>
                <Skeleton height={36} radius="md" width={180}/>
            </Group>
            <div className={classes.statisticsContainer}>
                {[...Array(4)].map((_, index) => (
                    <Skeleton key={index} height={110} radius="md"/>
                ))}
            </div>
            {[...Array(3)].map((_, index) => (
                <Skeleton key={index} height={220} radius="md" mb="lg"/>
            ))}
        </PageBody>
    );
};

export const UserDashboard = () => {
    const {data: me, isFetching: isMeLoading} = useGetMe();
    const userEventsQuery = useGetUserEvents({
        perPage: 100,
        sortBy: 'start_date',
        sortDirection: 'asc',
    } as QueryFilters);
    const publicEventsQuery = useGetPublicEvents();

    const registeredEvents = userEventsQuery.data?.data || [];
    const statsMeta = userEventsQuery.data?.meta?.user_event_stats;
    const recommendedEvents = publicEventsQuery.data?.data?.slice(0, 4) || [];
    const listEvents = publicEventsQuery.data?.data?.slice(0, 6) || [];

    const nextEvent = useMemo(() => {
        if (registeredEvents.length === 0) return undefined;
        const upcomingEvents = registeredEvents.filter((event) => isDateInFuture(event.start_date));
        if (upcomingEvents.length === 0) return undefined;
        return [...upcomingEvents].sort((a, b) => {
            return Date.parse(a.start_date) - Date.parse(b.start_date);
        })[0];
    }, [registeredEvents]);

    const formatTimeUntil = (startDate: string) => {
        const diffMs = dayjs.utc(startDate).diff(dayjs());
        if (diffMs <= 0) {
            return t`Started`;
        }

        const totalMinutes = Math.floor(diffMs / 60000);
        const days = Math.floor(totalMinutes / (60 * 24));
        const hours = Math.floor((totalMinutes % (60 * 24)) / 60);
        const minutes = totalMinutes % 60;

        const parts = [];
        if (days > 0) parts.push(`${days}d`);
        if (hours > 0 || days > 0) parts.push(`${hours}h`);
        parts.push(`${minutes}m`);
        return parts.join(' ');
    };

    const nextEventDisplay = nextEvent
        ? formatTimeUntil(nextEvent.start_date)
        : t`No upcoming races`;

    const registeredCount = statsMeta?.total_events ?? registeredEvents.length;
    const paidCount = statsMeta?.paid_events ?? 0;
    const unpaidCount = statsMeta?.unpaid_events ?? 0;

    const isLoading = isMeLoading || publicEventsQuery.isLoading || userEventsQuery.isLoading;

    if (isLoading) {
        return <UserDashboardSkeleton/>;
    }

    const statItems = [
        {
            value: nextEventDisplay,
            description: t`Next race`,
            icon: <IconFlag size={18}/>,
            backgroundColor: '#7C63E6'
        },
        {
            value: formatNumber(registeredCount),
            description: t`Registered races`,
            icon: <IconCalendar size={18}/>,
            backgroundColor: '#4B7BE5'
        },
        {
            value: formatNumber(paidCount),
            description: t`Paid registrations`,
            icon: <IconCalendar size={18}/>,
            backgroundColor: '#63B3A1'
        },
        {
            value: formatNumber(unpaidCount),
            description: t`Unpaid registrations`,
            icon: <IconAlertTriangle size={18}/>,
            backgroundColor: '#E67D49'
        },
    ];

    return (
        <PageBody>
            <div className={classes.headerSection}>
                <PageTitle className={classes.pageTitle}>
                    {me ? `${me.first_name} ${me.last_name} - ${t`Dashboard`}` : t`User Dashboard`}
                </PageTitle>
                <div className={classes.headerActions}>
                    <Button
                        component={NavLink}
                        to="/manage/events"
                        variant="light"
                        rightSection={<IconChevronRight size={16}/>}
                    >
                        {t`Organizer Panel`}
                    </Button>
                </div>
            </div>

            <div className={classes.statisticsContainer}>
                {statItems.map((item) => (
                    <StatBox
                        key={item.description}
                        number={String(item.value)}
                        description={item.description}
                        icon={item.icon}
                        backgroundColor={item.backgroundColor}
                    />
                ))}
                <NavLink to="/manage/profile" className={classes.statLink}>
                    <Card className={classes.editTile}>
                        <div>
                            <p className={classes.editTileTitle}>{t`Edit profile`}</p>
                            <p className={classes.editTileDescription}>
                                <Trans>Update your account details and preferences.</Trans>
                            </p>
                        </div>
                        <IconUserCircle size={28}/>
                    </Card>
                </NavLink>
            </div>

            <section className={classes.section}>
                <div className={classes.sectionHeader}>
                    <h3 className={classes.sectionTitle}>{t`Your registrations`}</h3>
                </div>
                {registeredEvents.length > 0 ? (
                    <div className={classes.cardsGrid}>
                        {registeredEvents.map((event: Event) => (
                            <PublicEventCard key={event.id || event.slug} event={event}/>
                        ))}
                    </div>
                ) : (
                    <div className={classes.emptyState}>
                        <Trans>You have not registered for any races yet.</Trans>
                    </div>
                )}
            </section>

            <section className={classes.section}>
                <div className={classes.sectionHeader}>
                    <h3 className={classes.sectionTitle}>{t`Our picks for you`}</h3>
                </div>
                {recommendedEvents.length > 0 ? (
                    <div className={classes.cardsGrid}>
                        {recommendedEvents.map((event: Event) => (
                            <PublicEventCard key={event.id || event.slug} event={event}/>
                        ))}
                    </div>
                ) : (
                    <div className={classes.emptyState}>
                        <Trans>No recommendations available yet.</Trans>
                    </div>
                )}
            </section>

            <section className={classes.section}>
                <div className={classes.sectionHeader}>
                    <h3 className={classes.sectionTitle}>{t`Race list`}</h3>
                </div>
                {listEvents.length > 0 ? (
                    <div className={classes.listGrid}>
                        {listEvents.map((event: Event) => {
                            const location =
                                event.location_details?.city ||
                                event.settings?.location_details?.city ||
                                event.location_details?.venue_name ||
                                event.settings?.location_details?.venue_name;

                            return (
                                <NavLink
                                    key={event.id || event.slug}
                                    to={eventHomepagePath(event)}
                                    className={classes.statLink}
                                >
                                    <Card className={classes.listItem}>
                                        <div>
                                            <p className={classes.listItemTitle}>{event.title}</p>
                                            <p className={classes.listItemMeta}>
                                                {formatDate(event.start_date, 'MMM D, YYYY', event.timezone)}
                                                {location ? ` • ${location}` : ''}
                                            </p>
                                        </div>
                                        <IconChevronRight size={18}/>
                                    </Card>
                                </NavLink>
                            );
                        })}
                    </div>
                ) : (
                    <div className={classes.emptyState}>
                        <Trans>No races available right now.</Trans>
                    </div>
                )}
            </section>
        </PageBody>
    );
};

export default UserDashboard;
