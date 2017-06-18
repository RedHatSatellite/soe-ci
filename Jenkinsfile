#!/usr/bin/env groovy

/**
* Right now this is a <b>very</b> simple implementation of handling rpms and a puppet only build in the very same Jenkinsfile.</br>
* In order to have the stages displayed properly in the Jenkins UI you should have the same stages for either way. If stages differ between job-run n-1 and n
* the main page of the job will only display the current job run rather than the cool history of the last runs in the pipeline execution table.</br>
* it's not a dynamic table, what a shame.
*/
node {

  VERBOSE_MODE = params.VERBOSE ? true : false
  bashExec = VERBOSE_MODE ? '/bin/bash -x' : '/bin/bash'

  try {
    if (params.CLEAN_WORKSPACE == true) {
      cleanWs()
    }

    stage('Checkout from SCM') {
      dir('scripts') {
        git credentialsId: "${params.CREDENTIALS_ID_SOE_CI_IN_JENKINS}", branch: "${params.SOE_CI_BRANCH}", poll: false, url: "${params.SOE_CI_REPO_URL}"
      }
      dir('soe') {
        git credentialsId: "${params.CREDENTIALS_ID_ACME_SOE_IN_JENKINS}", branch:"${params.ACME_SOE_BRANCH}" ,poll: false, url: "${params.ACME_SOE_REPO_URL}"
      }
    }

    loadEnvVars()

    stage('build') {
      executeScript("${WORKSPACE}/scripts/rpmbuild.sh ${WORKSPACE}/soe/rpms", true)
      executeScript("${WORKSPACE}/scripts/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts", true)
      executeScript("${WORKSPACE}/scripts/puppetbuild.sh ${WORKSPACE}/soe/puppet", false)
    }

    stage('push to Satellite'){
      executeScript("${WORKSPACE}/scripts/rpmpush.sh ${WORKSPACE}/artefacts", true)
      executeScript("${WORKSPACE}/scripts/puppetpush.sh ${WORKSPACE}/artefacts", false)
      executeScript("${WORKSPACE}/scripts/kickstartpush.sh ${WORKSPACE}/artefacts", true)
    }
    stage('publish and promote CV') {
      executeScript("${WORKSPACE}/scripts/publishcv.sh", false)
    }
    stage('run tests on VMs') {
      if (params.REBUILD_VMS == true) {
        executeScript("${WORKSPACE}/scripts/buildtestvms.sh")
      } else {
        executeScript("${WORKSPACE}/scripts/starttestvms.sh")
      }
      executeScript("${WORKSPACE}/scripts/pushtests.sh")
      step([$class: "TapPublisher", testResults: "test_results/*.tap", ])
    }
  } finally {
      stage('poweroff VMs') {
        if (params.POWER_OFF_VMS_AFTER_BUILD == true) {
          executeScript("${WORKSPACE}/scripts/powerofftestvms.sh")
        } else {
          println "test VMs are not shut down as per passed configuration"
        }
      }
      stage('cleanup') {
        executeScript("${WORKSPACE}/scripts/cleanup.sh")
      }
  }
}

/**
* @fileName - it is assumed the file is located in $WORKSPACE/scripts
*/
def loadEnvVarsFromFile(String fileName) {
  try {
    load "${WORKSPACE}/scripts/$fileName"
  } catch (e) {
    println "Well, this is embarassing, but we couldn't load the file $fileName"
    throw e
  }
}

def loadEnvVars() {
  loadEnvVarsFromFile("script-env-vars.groovy")
  if (params.PUPPET_ONLY == true) {
    loadEnvVarsFromFile("script-env-vars-puppet-only.groovy")
  } else {
    loadEnvVarsFromFile("script-env-vars-rpm.groovy")
  }
}

def executeScript(String bashArguments) {
  executeScript("$bashArguments", false)
}

def executeScript(String bashArguments, boolean rpmRelevant) {
  if (rpmRelevant && params.PUPPET_ONLY == true) {
    println "Skipping, puppet-only build."
  } else {
    sh "${bashExec} $bashArguments"
  }
}
