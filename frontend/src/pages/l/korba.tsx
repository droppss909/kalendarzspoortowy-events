import {Link, useLoaderData} from "react-router";
import {useEffect, useMemo, useState} from "react";
import {Button} from "@mantine/core";
import {EventDocumentHead} from "../../components/common/EventDocumentHead";
import {EventNotAvailable} from "../../components/layouts/EventHomepage/EventNotAvailable";
import {Event} from "../../types.ts";
import {KorbaNavLinks} from "./korbaNav";
import {KorbaFooter} from "./korbaFooter";
import classes from "./korba.module.scss";


type KorbaLandingLoaderData = {
    event: Event | null;
};

const KorbaLanding = () => {
    const {event} = useLoaderData() as KorbaLandingLoaderData;
    const targetDate = useMemo(() => new Date("2026-05-17T10:00:00"), []);
    const slides = useMemo(
        () => [
            "/korba1.png",
            "/korba2.png",
        ],
        []
    );
    const [countdown, setCountdown] = useState({days: 0, hours: 0, minutes: 0});
    const [activeSlide, setActiveSlide] = useState(0);
    const [isNavOpen, setIsNavOpen] = useState(false);

    if (!event) {
        return <EventNotAvailable/>;
    }

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

    useEffect(() => {
        if (slides.length < 2) {
            return;
        }
        const id = setInterval(() => {
            setActiveSlide((current) => (current + 1) % slides.length);
        }, 5000);
        return () => clearInterval(id);
    }, [slides.length]);

    return (
        <div className={classes.page}>
            <EventDocumentHead event={event}/>
            <header className={classes.hero}>
                <div className={classes.heroOverlay}/>
                <div className={classes.heroInner}>
                    <nav className={classes.navbar}>
                        <div className={classes.logoBlock}>
                            {/* TODO: Replace with final logo asset if needed. */}
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
            <div className={classes.slideshow}>
                <div
                    className={classes.slidesTrack}
                    style={{transform: `translateX(-${activeSlide * 100}%)`}}
                >
                    {slides.map((src, index) => (
                        <img
                            key={src}
                            src={src}
                            alt={`Korba slide ${index + 1}`}
                            className={classes.slide}
                        />
                    ))}
                </div>
                <div className={classes.slideDots}>
                    {slides.map((_, index) => (
                        <button
                            key={index}
                            type="button"
                            className={
                                index === activeSlide
                                    ? classes.slideDotActive
                                    : classes.slideDot
                            }
                            onClick={() => setActiveSlide(index)}
                            aria-label={`Przejdź do slajdu ${index + 1}`}
                        />
                    ))}
                </div>
            </div>
            <div className={classes.heroContent}>
            {/* TODO: Replace hero content (imagery, copy, CTAs) with event-specific branding. */}

            <div className={classes.kicker}>
                <h1 className={classes.title}>Złotowska Korba</h1>
                <p className={classes.subtitle}>
                    Temporary landing page template for this event.
                </p>
                <Button
                    component={Link}
                    to="/l/korba/zapisy"
                    size="md"
                    className={classes.registerButton}
                >
                    Zapisz się
                </Button>
            </div>
            </div>
            <section id="strefa-zawodnika" className={classes.section}>
                <h2 className={classes.sectionTitle}>Strefa zawodnika</h2>
                <p className={classes.placeholderText}>
                    Informacje dla uczestnikow, regulamin, biuro zawodow i komunikaty organizatora.
                </p>
            </section>

            <section id="trasa" className={classes.section}>
                <h2 className={classes.sectionTitle}>Trasa</h2>
                <p className={classes.placeholderText}>
                    Opis trasy, mapa oraz kluczowe punkty na trasie wyscigu.
                </p>
            </section>

            <section id="patroni" className={classes.section}>
                <h2 className={classes.sectionTitle}>Sponsorzy</h2>
                <div className={classes.sponsorsGrid}>
                    <img className={classes.sponsorLogo} src="/zlotow.png" alt="Zlotow" />
                    <img className={classes.sponsorLogo} src="/zcas.png" alt="ZCAS" />
                    <img className={classes.sponsorLogo} src="/nadlesnictwo-zlotow.png" alt="Nadlesnictwo Zlotow" />
                    <img className={classes.sponsorLogo} src="/milenium-logo.png" alt="Milenium" />
                    <img className={classes.sponsorLogo} src="/logo-kalendarz-partner.png" alt="Kalendarz Partner" />
                    <img className={classes.sponsorLogo} src="/logo-korba.png" alt="Korba" />
                </div>
            </section>

            <section id="faq" className={classes.section}>
                <h2 className={classes.sectionTitle}>FAQ</h2>
                <p className={classes.placeholderText}>
                    Odpowiedzi na najczesciej zadawane pytania.
                </p>
            </section>
            <KorbaFooter/>
        </div>
    );
};

export default KorbaLanding;
