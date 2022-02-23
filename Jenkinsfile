
// Build parameters are used to point to the appropraite Mayhem host and API
// token credentials.
properties([
    parameters([
        string(name: 'MAYHEM_HOST',
               description: 'The hostname of the Mayhem deploy to run against. e.g. my-company.forallsecure.com'),
        string(name: 'MAYHEM_TOKEN_CREDENTIAL_ID',
               description: 'The ID of the Jenkins credentials that contain the Mayhem API Token.'),
    ])
])

// Run the build on a node with the 'docker' label
node("docker") {
  checkout scm
  sh "git clean -fdx"

  // MAYHEM_TOKEN - The API Token for accessing the Mayhem from Jenkins Credentials.
  withCredentials([
      string(credentialsId: "${MAYHEM_TOKEN_CREDENTIAL_ID}", variable: "MAYHEM_TOKEN")
      ]) {

    // MAYHEM_URL      - The URL to the instance where the URL will be analyzed
    // DOCKER_REGISTRY - The docker registry hosted in Mayhem
    // IMAGE_TAG       - The tag for the image that contains the mayhem harness
    withEnv([
        "MAYHEM_URL=https://${MAYHEM_HOST}",
        "DOCKER_REGISTRY=${MAYHEM_HOST}:5000",
        "IMAGE_TAG=${MAYHEM_HOST}:5000/openssl-mayhem:${env.BRANCH_NAME}"
        ]) {

        // Build the fuzzing target in a docker iamge
        def mayhemImage
        stage("Build") {
            mayhemImage = docker.build("${env.IMAGE_TAG}", "-f mayhem.Dockerfile .")
        }

        // Call a helper script to analyze the target with Mayhem
        stage("Run Mayhem") {
          dir("mayhem") {
            sh 'scripts/run-mayhem.sh'

            // Collect junit results. Allow for empty results as regression tests
            // may not have been generated yet.
            junit allowEmptyResults: true, testResults: 'junit-results.xml'
          }
        }
    } // withEnv
  } // withCredentials
} // node