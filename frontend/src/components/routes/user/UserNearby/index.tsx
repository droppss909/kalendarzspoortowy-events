import {t, Trans} from "@lingui/macro";
import {PageBody} from "../../../common/PageBody";
import {PageTitle} from "../../../common/PageTitle";
import {Card} from "../../../common/Card";

const UserNearby = () => {
    return (
        <PageBody>
            <PageTitle>{t`Events Near You`}</PageTitle>
            <Card>
                <Trans>We will show races near your location once they are available.</Trans>
            </Card>
        </PageBody>
    );
};

export default UserNearby;
