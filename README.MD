# Getting Started

To get started with this example, you will need to fork this repository and complete the following process in Jenkins:

## Jenkins Setup

1. Create a new multibranch pipeline `openssl-pipeline` in Jenkins by accessing a Jenkins instance, and via the dashboard, go to *New Item* > *Multibranch Pipeline* in the left-hand pane.
2. Within the multibranch pipeline configuration, set your GitHub source to your forked repository for this openssl pipeline example. Make sure to set the correct repository HTTPS URL and credentials.
3. Click on *Scan Repository Now*, you should see two branches discovered in the pipeline: `master` and `CVE-2016-7053-FIXED`.

## Execute Continuous Fuzzing

For Continuous Fuzzing, Mayhem will fuzz the latest version of your software residing on the primary (master) branch, and by default, set Continuous Fuzzing runs with an infinite duration—only stopping a current Mayhem run and beginning a new Mayhem run when a new commit has been pushed to the primary branch. Thus, the name "Continuous Fuzzing".

1. Navigate to the `master` branch for the `openssl-pipeline` Jenkins project and click on *Build with Parameters*. Input the URL of your mayhem instance in the form of `my-company.forallsecure.com` (without any http or https prefixes) and the ID of the Jenkins credentials that contain the corresponding Mayhem API token (you may need to set this up separately). When ready, click on the *Build* button to execute the pipeline for the `master` branch.
2. The new pipeline for the `master` branch should now build the openssl Docker target and upload the corresponding Docker image to the specified Mayhem instance. A new Mayhem run for the bugged `openssl-master` target will then execute and find the underlying defects.

## Execute Regression Testing

For Regression Testing, Mayhem will execute regression tests on new changes or code using previously generated crashing test cases found during Continuous Fuzzing to determine if known defects have been fixed.

1. Navigate to the `CVE-2016-7053-FIXED` branch for the `openssl-pipeline` Jenkins project and click on *Build with Parameters*. Input the URL of your mayhem instance in the form of `my-company.forallsecure.com` (without any http or https prefixes) and the ID of the Jenkins credentials that contain the corresponding Mayhem API token (you may need to set this up separately). When ready, click on the *Build* button to execute the pipeline for the `CVE-2016-7053-FIXED` branch.
2. The new pipeline for the `CVE-2016-7053-FIXED` branch should now build the openssl Docker target and upload the corresponding Docker image to the specified Mayhem instance with the same test corpus generated from the `openssl-master` target. A Mayhem run for the fixed `openssl-cve-2016-7053-fixed` target will then execute to ensure that defects have been resolved.

# Mayhem Example (openssl)

This repository has been forked from the official [openssl repository](https://github.com/openssl/openssl)
repository in GitHub. Additional content has been added to serve as a reference
architecture on how to integrate [ForAllSecure](https://forallsecure.com) Mayhem
into a continuous integration / continuous deployment (CI/CD) workflow.

This example provides the necessary configuration files, pipeline scripts and
documentation necessary to execute a fuzzing test run on openssl using a CI/CD
workflow. In order to leverage this example, the user is expected to have access
to their own CI/CD tools as well as access to a Mayhem instance.

This example has been tested with Mayhem 1.3.0+ with [Jenkins ver. 2.222.3](https://www.jenkins.io/).

Original [openssl README](README)

## Why openssl?

In 2016 [ForAllSecure](https://forallsecure.com) discovered and published an openssl vulnerability
[CVE-2016-7053](https://access.redhat.com/security/cve/cve-2016-7053)
which was acknowledged and resolved by the openssl community.

This fork of openssl demonstrates how Mayhem can discover the issue, as well as
how the regression-testing capabilities of Mayhem can be used to verify the fix
in a separate branch.

## CI/CD with Jenkins

This repository demonstrates how to use a
[Jenkins scripted pipeline](https://www.jenkins.io/doc/book/pipeline/syntax/#scripted-pipeline) to:

* Build openssl and continuously fuzz the output to always be looking for new
  issues.
* Run regression tests generated from continuous fuzzing against a branch.

## What is being fuzzed

**CVE-2016-7053** describes a crash reproducible with the the `openssl` command line interface.
The build will create the `openssl` binary and copy it into a Docker image that
will be uploaded to Mayhem for fuzzing.

libfuzzer harnesses are available to build in the [fuzz](fuzz) folder. These may
be run under Mayhem, but are not included as part of this demonstration.

The `openssl` binary is built with Docker in [mayhem.Dockerfile](mayhem.Dockerfile) as
a stage in the Jenkins Pipeline. This image will be uploaded to the Mayhem Docker registry,
and its tag is referenced by [Mayhemfile](mayhem/Mayhemfile) (described below).

## Defining the Mayhem Run

A Mayhem "Target" is defined using a `Mayhemfile`. A `Mayhemfile` is included
under [mayhem/Mayhemfile](mayhem/Mayhemfile). It is recommended to inspect the
comments and properties of this file to understand how the project will be named
inside of Mayhem.

The `cmds` property of the [Mayhemfile](mayhem/Mayhemfile) describes how the
`openssl` cli will be invoked:

```yaml
cmds:
  # Command used to start the target, "@@" is the input file
  # (when "@@" is omitted Mayhem defaults to stdin inputs)
  - cmd: /home/workdir/mayhem/openssl cms -cmsout -inform DER -in @@
    timeout: 3
```

The path to the command, `/home/workdir/mayhem/openssl` is where the binary
was placed when building the Docker image specified in
[mayhem.Dockerfile](mayhem.Dockerfile).

Mayhem will fuzz the  `openssl` binary using the command described
`openssl cms -cmsout...`. The input will be passed into the command by Mayhem,
replacing the `@@` symbol with fuzzing content. A seed is included in
[mayhem/corpus](mayhem/corpus) to help find the demonstrated defect.

## Jenkins Pipeline

This example makes use of a [Jenkins Multibranch Pipeline](https://www.jenkins.io/doc/book/pipeline/multibranch/#creating-a-multibranch-pipeline)
to coordinate build and Mayhem integration. The Multibranch Pipeline sets
the `BRANCH_NAME` environment variable to whichever branch is being built by
Jenkins. This is used to distinguish between a continuous fuzzing run on the
`master` branch and regression test runs on other branches. Note that the
`BRANCH_NAME` variable is not set by default on a standard Jenkins Pipeline
job.

There is nothing in the build flow that _requires_ Jenkins. The same concepts 
can be applied to different build tools.

The [Jenkinsfile](Jenkinsfile) is located in the root of the project and defines
the build pipeline used to run Mayhem. The bulk of the work to run Mayhem and
to differentiate between continuous and regression runs is in
[run-mayhem.sh](mayhem/scripts/run-mayhem.sh). This script downloads the
`mayhem` cli, which is used to initiate runs.
