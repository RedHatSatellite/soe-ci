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

  isInErrorState = false

  if (params.CLEAN_WORKSPACE == true) {
    deleteDir()
  }

  def stageCheckout = {
    dir('scripts') {
      git credentialsId: "${params.CREDENTIALS_ID_SOE_CI_IN_JENKINS}", branch: "${params.SOE_CI_BRANCH}", poll: false, url: "${params.SOE_CI_REPO_URL}"
    }
    dir('soe') {
      git credentialsId: "${params.CREDENTIALS_ID_ACME_SOE_IN_JENKINS}", branch:"${params.ACME_SOE_BRANCH}", poll: false, url: "${params.ACME_SOE_REPO_URL}"
    }
  }
  executeStage(stageCheckout, 'Checkout from Git')
  
  def stageLoadConfig = { 
    checkThatConfigFilesExist()
    environmentVariables()
  }
  executeStage(stageLoadConfig, 'check that config files exist')

  def stageBuild = {
    executeScript("${SCRIPTS_DIR}/rpmbuild.sh ${WORKSPACE}/soe/rpms", true)
    executeScript("${SCRIPTS_DIR}/kickstartbuild.sh ${WORKSPACE}/soe/kickstarts", true)
    executeScript("${SCRIPTS_DIR}/puppetbuild.sh ${WORKSPACE}/soe/puppet", false)
  }
  executeStage(stageBuild, 'build')

  def stagePushToSat = {
    executeScript("${SCRIPTS_DIR}/rpmpush.sh ${WORKSPACE}/artefacts", true)
    executeScript("${SCRIPTS_DIR}/puppetpush.sh ${WORKSPACE}/artefacts", false)
    executeScript("${SCRIPTS_DIR}/kickstartpush.sh ${WORKSPACE}/artefacts", true)
  }
  executeStage(stagePushToSat, 'push to Satellite')

  def stagePubAndPromote = {
    executeScript("${SCRIPTS_DIR}/publishcv.sh", false)
    executeScript("${SCRIPTS_DIR}/capsule-sync-check.sh", false)
  }
  executeStage(stagePubAndPromote, 'publish and promote CV')

  def stagePrepTestVms = {
    if (params.REBUILD_VMS == true) {
      executeScript("${SCRIPTS_DIR}/buildtestvms.sh")
    } else {
      executeScript("${SCRIPTS_DIR}/starttestvms.sh")
    }
  }
  executeStage(stagePrepTestVms, 'prepare test VMs')

  def stageRunTests = {
    executeScript("${SCRIPTS_DIR}/pushtests.sh")
    step([$class: "TapPublisher", testResults: "test_results/*.tap", failedTestsMarkBuildAsFailure: true ])
    if (currentBuild.result == 'FAILURE') {
      isInErrorState = true
      error('There were test failures')
    }
  }
  executeStage(stageRunTests, 'run tests')
   
  def stagePowerOffTestVMs = {
    if (params.POWER_OFF_VMS_AFTER_BUILD == true) {
      executeScript("${SCRIPTS_DIR}/powerofftestvms.sh")
    } else {
      println "test VMs are not shut down as per passed configuration"
    }
  }
  executeStage(stagePowerOffTestVMs, 'power off test VMs')

/*
* promote to GOLDENVM_ENV here or do we do both test and golden VMs from same LCE?
* the latter is actually fine as long as the pipeline exits on failure at one of the previous steps
* the former gives us a nicer separation (so (C)CVs in the LCE can be used for other tasks that want only a version where automated testing passed)
*/
  def stagePromote2GoldenLCE = {
    executeScript("${SCRIPTS_DIR}/promote2goldenlce.sh")
    executeScript("${SCRIPTS_DIR}/capsule-sync-check.sh")
  }
<<<<<<< HEAD
  executeStage(stagePromote2GoldenLCE, 'promote CV to golden')
=======
  executeStage(stagePromote2GoldenLCE, 'publish and promote CV')
>>>>>>> 8ea8585... WIP, add script to promote to golden LCE

  def stagePrepGoldenVms = {
    executeScript("${SCRIPTS_DIR}/buildgoldenvms.sh")
    executeScript("${SCRIPTS_DIR}/wait4goldenvmsup.sh")
    executeScript("${SCRIPTS_DIR}/shutdowngoldenvms.sh")
  }
  executeStage(stagePrepGoldenVms, 'prepare golden VMs')

  // where do we run virt-sysprep (1) after this is successful? Ideally on the machine doing qemu-img convert

  def stageCleanup = {
    executeScript("${SCRIPTS_DIR}/cleanup.sh")
  }
  executeStage(stageCleanup, 'cleanup')
}

def executeStage(Closure closure, String stageName) {
    stage(stageName) {
    if ( isInErrorState == false) {
      try {
        closure()
      } catch(e) {
        isInErrorState = true
        error(e.getMessage())
        currentBuild.result = 'FAILURE'
      }
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