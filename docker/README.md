this triggers the gcloud build of the develop branch of GridKit. Run this is the repository root:

```sh
gcloud builds submit --project=gridkitvm --config=docker/cloudbuild.yaml .
```
