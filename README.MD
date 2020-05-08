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

This example makes use of [Jenkins Pipeline](https://www.jenkins.io/doc/book/pipeline/)
to coordinate the build and Mayhem integration. There is nothing in the build
flow that requires Jenkins. The same concepts can be applied to different build
tools.

The [Jenkinsfile](Jenkinsfile) is located in the root of the project and defines
the build pipeline used to run Mayhem. The bulk of the work to run Mayhem and
to differentiate between continuous and regression runs is in
[run-mayhem.sh](mayhem/scripts/run-mayhem.sh). This script downloads the
`mayhem` cli, which is used to initiate runs.