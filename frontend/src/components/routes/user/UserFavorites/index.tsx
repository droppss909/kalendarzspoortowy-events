import {t, Trans} from "@lingui/macro";
import {PageBody} from "../../../common/PageBody";
import {PageTitle} from "../../../common/PageTitle";
import {Card} from "../../../common/Card";

const UserFavorites = () => {
    return (
        <PageBody>
            <PageTitle>{t`Favorite Events`}</PageTitle>
            <Card>
                <Trans>Your favorite events will appear here once you start saving them.</Trans>
            </Card>
        </PageBody>
    );
};

export default UserFavorites;
