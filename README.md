# Niceoppai Notifier

Google Cloud Functions (serverless) that help notify any update cartoon on [niceoppai](https://niceoppai.net), by send direct to Line, to each user

## Development

- [x] Run on Google Cloud Platform (required [functions_framework](https://github.com/GoogleCloudPlatform/functions-framework-ruby) to deploy)
- [x] Store data on Google Firestore
- [x] Line notify
- [ ] CI - rubocop, lint
- [ ] CD - Github Actions
- [ ] Front end !!!

## Deploy

Manually, for now

- cartoons_list_update: `gcloud functions deploy cartoons_list_update --region=asia-southeast2 --runtime=ruby27 --project=niceoppai-notifier --trigger-topic=update_cartoon_list`
- cartoon_update: `gcloud functions deploy cartoon_update --region=asia-southeast2 --runtime=ruby27 --project=niceoppai-notifier --trigger-event=providers/cloud.firestore/eventTypes/document.update --trigger-resource="projects/niceoppai-notifier/databases/(default)/documents/cartoons/{cartoon_name}"`

## TODO

- Setup STG environment
- CI/CD
