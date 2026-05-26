import React from 'react';
import Layout from '@theme/Layout';
import SwaggerUI from 'swagger-ui-react';
import 'swagger-ui-react/swagger-ui.css';

export default function ApiDoc() {
  return (
    <Layout
      title="API Documentation"
      description="API Documentation for the F1 AI Commentary backend">
      <main style={{ padding: '2rem' }}>
        <SwaggerUI url="/openapi.json" />
      </main>
    </Layout>
  );
}
