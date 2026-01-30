import {t, Trans} from "@lingui/macro";
import {PageBody} from "../../../common/PageBody";
import {PageTitle} from "../../../common/PageTitle";
import {Card} from "../../../common/Card";

const UserHistory = () => {
    return (
        <PageBody>
            <PageTitle>{t`Event History`}</PageTitle>
            <Card>
                <Trans>Your past races will be listed here after you attend an event.</Trans>
            </Card>
        </PageBody>
    );
};

export default UserHistory;
