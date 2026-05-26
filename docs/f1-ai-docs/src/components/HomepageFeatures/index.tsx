import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import Link from '@docusaurus/Link';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  image: string;
  href: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Handover Guide',
    image: '/assets/wireframes/IMG_5327.jpeg',
    href: '/docs/handover',
    description: (
      <>
        Follow the recommended takeover sequence, ownership expectations, and key references.
      </>
    ),
  },
  {
    title: 'Asset Gallery',
    image: '/assets/poster/SEPF1testingdayposter.png',
    href: '/docs/assets/overview',
    description: (
      <>
        Access wireframes, poster material, and team visual assets in one place.
      </>
    ),
  },
  {
    title: 'API Reference',
    image: '/assets/team-assets/MERCEDES1.png',
    href: '/api',
    description: (
      <>
        Explore the live OpenAPI schema for integration and backend maintenance checks.
      </>
    ),
  },
];

function Feature({title, image, href, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className={styles.featureCard}>
        <div className={styles.previewWrap}>
          <img className={styles.featureImage} src={image} alt={`${title} preview`} />
        </div>
        <div className="text--center padding-horiz--md">
          <Heading as="h3">{title}</Heading>
          <p>{description}</p>
          <Link className="button button--primary" to={href}>
            Open {title}
          </Link>
        </div>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
