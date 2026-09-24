# AWS Elastic Beanstalk Express Sample - Secure CI/CD Project

This repository is my fork of the [AWS Elastic Beanstalk Express sample](https://github.com/aws-samples/aws-elastic-beanstalk-express-js-sample). I extended the sample with automated tests, container packaging, dependency security assessment and a Jenkins CI/CD pipeline. The pipeline installs locked dependencies, runs the tests, applies a High/Critical vulnerability gate, builds a Docker image and publishes an approved image to Docker Hub.

## Application

The Express application exposes one route:

- `GET /` returns HTTP `200` with `Hello World!`.

The server listens on port `8080` by default and accepts an alternative through the `PORT` environment variable.

## Repository contents

| Path | Purpose |
| --- | --- |
| `app.js` | Defines the Express application and root route. |
| `server.js` | Starts the HTTP server. |
| `test/app.test.js` | Verifies the root route with Jest and SuperTest. |
| `package.json`, `package-lock.json` | Define and lock application and test dependencies. |
| `Dockerfile` | Builds the non-root production application image. |
| `Jenkinsfile` | Defines checkout, installation, testing, security assessment, image build, publication and artifact archival. |
| `.gitignore`, `.dockerignore` | Exclude generated dependencies, reports, metadata and local files from versioned or container build contexts. |

## Local development

### Prerequisites

- Node.js 16 and npm
- Docker Engine for container verification

Install the locked dependencies:

```sh
npm ci
```

Start the application:

```sh
npm start
```

Verify the root route from another terminal:

```sh
curl http://127.0.0.1:8080/
```

The expected response is:

```text
Hello World!
```

## Tests

Run the CI test command locally:

```sh
npm run test:ci
```

The command runs Jest serially and writes the JUnit report to `reports/junit.xml`. Generated reports remain outside Git.

## Application container

Build and run the production image:

```sh
docker build --pull -t assessment2-app:local .
docker run --rm -p 8080:8080 assessment2-app:local
```

The Dockerfile installs production dependencies from the lockfile and runs the application as the non-root `node` user.

## Jenkins pipeline

The Jenkins job retrieves the root `Jenkinsfile` from `main`. The Pipeline executes these stages in order:

1. Checkout and source-revision recording
2. Locked dependency installation in a Node 16 container
3. Unit tests and JUnit report generation
4. Dependency vulnerability assessment
5. Docker image construction
6. Docker Hub publication

The dependency gate executes `npm audit --audit-level=high --json`. High or Critical findings return a non-zero status and prevent image construction and publication. The audit JSON, JUnit XML and image metadata are archived when their paths exist.

Successful images are published to:

<https://hub.docker.com/r/unbeelee/aws-elastic-beanstalk-express-js-sample>

Each image tag contains the Jenkins build number and the first 12 characters of the checked-out Git revision. The image metadata also records the full source revision and published registry digest.

## Triggering and retention

Jenkins polls `main` with `H/15 * * * *`, which checks for source changes at a stable job-specific offset approximately every 15 minutes. The job retains the latest 30 ordinary build records and matching archived artifacts, while explicitly preserved evidence builds remain outside normal rotation.

The Pipeline clears generated reports and image metadata from the reused workspace before checkout. This prevents a failed run from archiving stale output left by an earlier successful run.

## Security boundaries

- Node stages run as UID/GID `1000:1000` and reject UID `0`.
- Registry credentials are bound only inside the publication stage and are not committed to Git.
- Shell tracing is disabled while the registry credential is in scope.
- Tests and the High/Critical dependency gate complete before image publication.
- Jenkins communicates with a separate TLS-protected Docker-in-Docker daemon managed by the infrastructure repository.
- Docker daemon access remains a privileged capability, so the Pipeline is intended for trusted project code rather than untrusted pull requests.

The related Jenkins and Docker Compose infrastructure is stored in:

<https://github.com/unbee-lee/isec6000-assessment2-jenkins>

## License

This project retains the original MIT-0 licence. See [LICENSE](LICENSE).

