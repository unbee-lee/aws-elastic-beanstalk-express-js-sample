# AWS Elastic Beanstalk Node.js Sample App

This repository contains a sample Node.js web application built using [Express](https://expressjs.com/), meant to be used as part of the AWS DevOps Learning Path.

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## Jenkins pipeline

The Jenkins pipeline polls `main` every 15 minutes using `H/15 * * * *`. It retains the latest 30 build records and matching diagnostic artifacts, with explicitly preserved evidence builds excluded from normal discard. Reports are archived in Jenkins and excluded from Git.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

