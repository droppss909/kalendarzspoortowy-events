import {IconHeart, IconHistory, IconLayoutDashboard, IconMapPin} from "@tabler/icons-react";
import {t} from "@lingui/macro";
import {BreadcrumbItem, NavItem} from "../AppLayout/types";
import AppLayout from "../AppLayout";
import {useGetMe} from "../../../queries/useGetMe.ts";

const UserLayout = () => {
    const {data: me} = useGetMe();

    const navItems: NavItem[] = [
        {label: t`Overview`},
        {link: 'dashboard', label: t`User Dashboard`, icon: IconLayoutDashboard},
        {label: t`Discover`},
        {link: 'favorites', label: t`Favorite Events`, icon: IconHeart},
        {link: 'nearby', label: t`Events Near You`, icon: IconMapPin},
        {link: 'history', label: t`Event History`, icon: IconHistory},
    ];

    const breadcrumbItems: BreadcrumbItem[] = [
        {link: '/manage/user/dashboard', content: t`User Panel`},
        {content: me ? `${me.first_name} ${me.last_name}` : t`Dashboard`},
    ];

    return (
        <AppLayout
            navItems={navItems}
            breadcrumbItems={breadcrumbItems}
            entityType="user"
            homeLink="/manage/user/dashboard"
        />
    );
};

export default UserLayout;
