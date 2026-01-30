import classes from "./korba.module.scss";

type KorbaNavLinksProps = {
    className?: string;
};

export const KorbaNavLinks = ({className}: KorbaNavLinksProps) => (
    <div className={[classes.bottomNav, className].filter(Boolean).join(" ")}>
        <a href="/l/korba#strefa-zawodnika">Strefa zawodnika</a>
        <a href="/l/korba/trasa">Trasa wyscigu</a>
        <a href="/l/korba/zapisy">Zapisy</a>
        <a href="/l/korba#patroni">Patroni</a>
        <a href="/l/korba#faq" style={{color: "orange"}}>FAQ</a>
    </div>
);
