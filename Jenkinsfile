#!/usr/bin/env groovy

/**
* This is a <b>very</b> simple implementation of handling rpms and a puppet only build in the very same Jenkinsfile.</br>
* In order to have the stages displayed properly in the Jenkins UI you should have the same stages for either way. If stage names differ between job-run n-1 and n
* the main page of the job will only display the current job run rather than the cool history of the last runs in the pipeline execution table.</br>
*/
node {

  SCRIPTS_DIR = "${WORKSPACE}/scripts"
  GENERAL_CONFIG_FILE = "${SCRIPTS_DIR}/script-env-vars.groovy"
  RHEL_VERSION_SPECIFIC_CONFIG_FILE_SUFFIX = "-script-env-vars-rpm.groovy"
  RHEL_VERSION_SPECIFIC_PUPPEPT_ONLY_CONFIG_FILE_SUFFIX= "-script-env-vars-puppet-only.groovy"

  runScriptVerbose = params.VERBOSE ? true : false
  bashExec = runScriptVerbose ? '/bin/bash -x' : '/bin/bash'

  rhelVersionSpecificConfigFile = "${SCRIPTS_DIR}/${params.RHEL_VERSION}" + RHEL_VERSION_SPECIFIC_CONFIG_FILE_SUFFIX
  rhelVersionSpecificPuppetOnlyConfigFile = "${SCRIPTS_DIR}/${params.RHEL_VERSION}" + RHEL_VERSION_SPECIFIC_PUPPEPT_ONLY_CONFIG_FILE_SUFFIX
  specificConfigFile = params.PUPPET_ONLY == true ? rhelVersionSpecificPuppetOnlyConfigFile : rhelVersionSpecificConfigFile

  try {

    if (params.CLEAN_WORKSPACE == true) {
      deleteDir()
    }

    stage('Checkout from Git') {
      dir('scripts') {
        git credentialsId: "${params.CREDENTIALS_ID_SOE_CI_IN_JENKINS}", branch: "${params.SOE_CI_BRANCH}", poll: false, url: "${params.SOE_CI_REPO_URL}"
      }
      dir('soe') {
        git credentialsId: "${params.CREDENTIALS_ID_ACME_SOE_IN_JENKINS}", branch:"${params.ACME_SOE_BRANCH}", poll: false, url: "${params.ACME_SOE_REPO_URL}"
      }
    }

    stage('check that config files exist') {
      checkThatConfigFilesExist()
    }

    environmentVariables()

    stage('build') {
      executeScript("${SCRIPTS_DIR}/rpmbuild.sh ${WORKSPACE}/soe/rpms", true)
      executeScript("${SCRIPTS_DIR}/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts", true)
      executeScript("${SCRIPTS_DIR}/puppetbuild.sh ${WORKSPACE}/soe/puppet", false)
    }

    stage('push to Satellite'){
      executeScript("${SCRIPTS_DIR}/rpmpush.sh ${WORKSPACE}/artefacts", true)
      executeScript("${SCRIPTS_DIR}/puppetpush.sh ${WORKSPACE}/artefacts", false)
      executeScript("${SCRIPTS_DIR}/kickstartpush.sh ${WORKSPACE}/artefacts", true)
    }
    stage('publish and promote CV') {
      executeScript("${SCRIPTS_DIR}/publishcv.sh", false)
      executeScript("${SCRIPTS_DIR}/capsule-sync-check.sh", false)
    }
    stage('prepare VMs') {
      if (params.REBUILD_VMS == true) {
        executeScript("${SCRIPTS_DIR}/buildtestvms.sh")
      } else {
        executeScript("${SCRIPTS_DIR}/starttestvms.sh")
      }
    }
    stage('run tests') {
      executeScript("${SCRIPTS_DIR}/pushtests.sh")
      step([$class: "TapPublisher", testResults: "test_results/*.tap", ])
    }
  } finally {
      stage('poweroff VMs') {
        if (params.POWER_OFF_VMS_AFTER_BUILD == true) {
          executeScript("${SCRIPTS_DIR}/powerofftestvms.sh")
        } else {
          println "test VMs are not shut down as per passed configuration"
        }
      }
      stage('cleanup') {
        executeScript("${SCRIPTS_DIR}/cleanup.sh")
      }
  }
}

/**
* depending on the chosen value of the param <code>RHEL_VERSION</code>,
* we need to check that the config files exist rather than to wait for the pipeline
* to reach the point where it needs those configs and then fails.
*/
def checkThatConfigFilesExist() {
  filesMissing = false
  errorMessage = "The following config files are missing:"
  [GENERAL_CONFIG_FILE, specificConfigFile].each { fileName -> 
    if (fileExists("${fileName}") == false) {
      filesMissing = true
      errorMessage = errorMessage + " ${fileName}"
    }
  }
  if (filesMissing) {
    error(errorMessage)
  }
}

def environmentVariables() {
  [GENERAL_CONFIG_FILE, specificConfigFile].each { fileName -> 
    load "${fileName}"
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
