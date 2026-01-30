import {useLoaderData} from "react-router";
import {useEffect, useMemo, useState} from "react";
import {EventDocumentHead} from "../../components/common/EventDocumentHead";
import {EventNotAvailable} from "../../components/layouts/EventHomepage/EventNotAvailable";
import {Event} from "../../types.ts";
import {KorbaNavLinks} from "./korbaNav";
import {KorbaFooter} from "./korbaFooter";
import classes from "./korba.module.scss";

type KorbaLandingLoaderData = {
    event: Event | null;
};

const KorbaRaceRoute = () => {
    const {event} = useLoaderData() as KorbaLandingLoaderData;
    const targetDate = useMemo(() => new Date("2026-05-17T10:00:00"), []);
    const [countdown, setCountdown] = useState({days: 0, hours: 0, minutes: 0});
    const [isNavOpen, setIsNavOpen] = useState(false);

    useEffect(() => {
        const tick = () => {
            const now = Date.now();
            const diff = Math.max(targetDate.getTime() - now, 0);
            const totalMinutes = Math.floor(diff / 60000);
            const days = Math.floor(totalMinutes / (60 * 24));
            const hours = Math.floor((totalMinutes % (60 * 24)) / 60);
            const minutes = totalMinutes % 60;
            setCountdown({days, hours, minutes});
        };

        tick();
        const id = setInterval(tick, 60000);
        return () => clearInterval(id);
    }, [targetDate]);

    if (!event) {
        return <EventNotAvailable/>;
    }

    return (
        <div className={classes.page}>
            <EventDocumentHead event={event}/>
            <header className={classes.hero}>
                <div className={classes.heroOverlay}/>
                <div className={classes.heroInner}>
                    <nav className={classes.navbar}>
                        <div className={classes.logoBlock}>
                            <img
                                src="/korba-icon.png"
                                alt="Zlotowska Korba"
                                className={classes.logoImage}
                            />
                        </div>
                    </nav>
                    <button
                        type="button"
                        className={classes.mobileNavToggle}
                        aria-expanded={isNavOpen}
                        aria-controls="korba-mobile-nav"
                        onClick={() => setIsNavOpen((open) => !open)}
                    >
                        Menu
                    </button>
                    <div
                        className={
                            isNavOpen
                                ? `${classes.mobileNavOverlay} ${classes.mobileNavOverlayOpen}`
                                : classes.mobileNavOverlay
                        }
                        onClick={() => setIsNavOpen(false)}
                    />
                    <aside
                        id="korba-mobile-nav"
                        className={
                            isNavOpen
                                ? `${classes.mobileNavDrawer} ${classes.mobileNavDrawerOpen}`
                                : classes.mobileNavDrawer
                        }
                    >
                        <div className={classes.mobileNavHeader}>
                            <span>Nawigacja</span>
                            <button
                                type="button"
                                className={classes.mobileNavClose}
                                onClick={() => setIsNavOpen(false)}
                                aria-label="Zamknij menu"
                            >
                                ×
                            </button>
                        </div>
                        <KorbaNavLinks className={classes.mobileNavList}/>
                    </aside>
                    <div className={classes.navigation}>
                        <KorbaNavLinks/>
                        <div className={classes.poweredBy}>
                            <span>Powered by</span>
                            <img
                                src="/kalendarz-icon.png"
                                alt="Kalendarz Sportowy"
                                className={classes.poweredByLogo}
                            />
                        </div>
                    </div>
                </div>
            </header>
            <div className={classes.countdownBar}>
                <div className={classes.countdownInner}>
                    <span className={classes.countdownLabel}>Start za</span>
                    <div className={classes.countdownUnits}>
                        <span><strong>{countdown.days}</strong> dni</span>
                        <span><strong>{countdown.hours}</strong> godzin</span>
                        <span><strong>{countdown.minutes}</strong> minut</span>
                    </div>
                </div>
            </div>
            <section className={`${classes.section} ${classes.sectionWide}`}>
                <h2 className={classes.sectionTitle}>Trasa wyscigu</h2>
                <div className={classes.iframeWrap}>
                    <iframe style={{width: "100%", height: "500px", border: "0"}} allow="geolocation" src="//umap.openstreetmap.fr/pl/map/mapa-bez-nazwy_1351233?scaleControl=false&miniMap=false&scrollWheelZoom=false&zoomControl=true&editMode=disabled&moreControl=true&searchControl=null&tilelayersControl=null&embedControl=null&datalayersControl=true&onLoadPanel=none&captionBar=false&captionMenus=true"></iframe><p><a href="//umap.openstreetmap.fr/pl/map/mapa-bez-nazwy_1351233?scaleControl=false&miniMap=false&scrollWheelZoom=true&zoomControl=true&editMode=disabled&moreControl=true&searchControl=null&tilelayersControl=null&embedControl=null&datalayersControl=true&onLoadPanel=none&captionBar=false&captionMenus=true">Pełny ekran</a></p>
                </div>
            </section>
            <section className={`${classes.section} ${classes.sectionWide}`}>
                <h3 className={classes.sectionTitle}>Kluczowe informacje</h3>
                <p className={classes.placeholderText}>
                    Start i meta: centrum Zlotowa. Na trasie beda punkty odzywcze i serwisowe.
                </p>
            </section>
            <KorbaFooter/>
        </div>
    );
};

export default KorbaRaceRoute;
