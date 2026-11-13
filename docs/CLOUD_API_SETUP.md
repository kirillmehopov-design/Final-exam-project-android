# Cloud API deployment required for FINAL.docx

The existing FastAPI + SQLite service has a working local REST API, but a localhost URL is NOT a real deployed cloud REST API. This setup is a deployment guide, not proof of deployment. See the official [Render Blueprint specification](https://render.com/docs/blueprint-spec).

## Suggested demo-only deployment

1. Create a cloud Web Service using the existing public GitHub repository and set **Root Directory** to \`backend\`.
2. Use Python runtime, build command \`pip install -r requirements.txt\`, and start command \`uvicorn app:app --host 0.0.0.0 --port $PORT\`.
3. Set \`SNEAKERHUB_OTP_SECRET\` to a securely generated secret in the provider's environment configuration (do not commit the secret).
4. Use a persistent volume and set \`SNEAKERHUB_DB\` to its SQLite file path; otherwise a redeploy can lose orders, accounts and stock. Many free hosting plans do not provide persistent disk volumes.
5. Deploy, then verify the public HTTPS endpoints \`/health\`, \`/products\`, and \`/docs\`.
6. Run Flutter with:
   \`flutter run -d chrome --dart-define=API_BASE_URL=https://YOUR-PUBLIC-API.example\`
7. Check browser CORS, sign-in, catalog, order and courier flow on the deployed service.

## Important limitations

The backend uses demo credentials and a local SQLite database; it is not production-ready for public use. Do not collect real customer personal information, process real payments or treat the demo OTP as a commercial security system. A production service needs managed persistence, authentication hardening, HTTPS, restricted CORS, rate limits and audit logs.

If you do not deploy a public cloud endpoint and demonstrate live asynchronous calls from the Flutter app to it, the cloud API criterion is not fully met.
