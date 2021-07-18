# Niceoppai Notifier

Google Cloud Functions (serverless) that help notify any update cartoon on [niceoppai](https://niceoppai.net)
by send direct to Line, of each user

## Development

- [x] Run on Google Cloud Platform (required [functions_framework](https://github.com/GoogleCloudPlatform/functions-framework-ruby) to deploy)
- [x] Store data on Google Firestore
- [x] Line notify
- [] CI - rubocop, lint
- [] CD - Github Actions

## Deploy

Manually, for now

- update_cartoon_list: `gcloud functions deploy update_cartoon_list --region=asia-southeast2 --runtime=ruby27 --project=niceoppai-notifier --trigger-http`
- cartoon_update: `gcloud functions deploy cartoon_update --region=asia-southeast2 --runtime=ruby27 --project=niceoppai-notifier --trigger-event=providers/cloud.firestore/eventTypes/document.update --trigger-resource="projects/niceoppai-notifier/databases/(default)/documents/cartoons/{cartoon_name}"`

## TODO

- Change trigger on `update_cartoon_list` to Pub/Sub instead
- Setup STG environment
- CI/CD
