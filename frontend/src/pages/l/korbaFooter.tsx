import classes from "./korba.module.scss";

export const KorbaFooter = () => (
    <footer className={classes.footer}>
        <div className={classes.footerInner}>
            <div className={classes.footerLeft}>
                <img
                    src="/korba-icon.png"
                    alt="Zlotowska Korba"
                    className={classes.footerLogo}
                />
                <div className={classes.footerContact}>
                    <h4>Kontakt do organizatora</h4>
                    <p>kontakt@zlotowskakorba.pl</p>
                    <p>+48 600 000 000</p>
                </div>
                {/* <div className={classes.footerSponsors}>
                    <h4>Sponsorzy</h4>
                    <div className={classes.footerSponsorsList}>
                        <span>Sponsor 1</span>
                        <span>Sponsor 2</span>
                        <span>Sponsor 3</span>
                    </div>
                </div> */}
            </div>
            <img
                src="/kalendarz-icon.png"
                alt="Kalendarz Sportowy"
                className={classes.footerLogoSecondary}
            />
        </div>
    </footer>
);
