Continuous Integration Scripts for Satellite 6
==============================================

- - -

* Author: Janine Eichler
* Email: <jaeichle@redhat.com>
* Revision: 0.4
* Introduce Jenkins Pipeline

- - -

* Domain Architect: Eric Lavarde
* Email: <elavarde@redhat.com>
* Consultant: Patrick C. F. Ernzer
* Email: <pcfe@redhat.com>
* Date: February to November 2016
* Revision: 0.3
* Satellite 6.2 is now a minimum requirement, 6.1 will not work.
* Satellite 6.3, 6.4 and 6.5 have been tested.
* as a general rule the latest version of Satellite is the one I develop against.

- - -

* Author: Nick Strugnell
* Email: <nstrug@redhat.com>
* Date: 2014-11-20
* Revision: 0.1

Table of Contents
==

* [Standard Operating Environment Overview](#standard-operating-environment-overview)
* [Introduction](#introduction)
* [Setup](#setup)
  * [Jenkins Server](#jenkins-server)
    * [Installation](#installation)
    * [Jenkins Jobs](#jenkins-jobs)
      * [Overview](#overview)
      * [Job Parameters and what they do](#job-parameters-and-what-they-do)
      * [Create the Jobs](#create-the-jobs)
      * [How do I change the Pipeline](#how-do-i-change-the-pipeline)
      * [Create a Job which runs the pipeline](#create-a-job-which-runs-the-pipeline)
      * [Create a job which polls the SCMs and then triggers the previously created job](#create-a-job-which-polls-the-scms-and-then-triggers-the-previously-created-job)
  * [Git Repository](#git-repository)
  * [Satellite 6](#satellite-6)
  * [Bootstrapping](#bootstrapping)
* [Getting Started](#getting-started)
* [COMING SOON](#coming-soon)

# Standard Operating Environment Overview
It is extremely helpful if you read the following blog posts, that explain the concepts behind this repo, before trying to implement.

* [Part I: Concepts and Structures](http://www.opensourcearchitects.org/index.php/2016/10/31/standard-operating-environment-part-i-concepts-and-structures/)
* [Part II: Workflows in Detail](http://www.opensourcearchitects.org/index.php/2016/11/22/standard-operating-environment-part-ii-workflows-in-detail/)
* [Part III: A Reference Implementation](http://www.opensourcearchitects.org/index.php/2017/06/01/standard-operating-environment-part-iii-a-reference-implementation/)

# Introduction
Continuous Integration for Infrastructure (CII) is a process by which the Operating System build ("build") component of a Standard Operating Environment (SOE) can be rapidly developed, tested and deployed.

A build is composed of the following components:

* Red Hat provided base packages
* 3rd party and in-house developed packages
* Deployment instructions in the form of kickstart templates
* Configuration instructions in the form of puppet modules
* Test instructions in the form of BATS scripts

The CII system consists of the following components:

* A git repository, containing the 3rd party and in-house packages, kickstarts, puppet modules and BATS scripts. This is where development of the build takes place.
* A Jenkins instance. This is responsible for building artefacts such as RPMs and Puppet modules, Pushing artefacts into the Red Hat Satellite, and orchestrating and reporting tests.
* Red Hat Satellite 6. This acts as the repository for Red Hat-provided and 3rd party packages, kickstarts and puppet modules. The Foreman module is also used to deploy test clients.
* A virtualisation infrastructure to run test clients. I have used KVM/Libvirt, VMware and RHEV in different engagements.

The architecture is shown in [this YeD diagram](https://github.com/RedHatEMEA/soe-ci/blob/master/Engineering%20Platform.graphml).

# Setup
The following steps should help you get started with CII.

## Jenkins Server

NB I have SELinux enabled on the Jenkins server and it poses no problems.

### Installation

* Install a standard RHEL 7 server with a minimum of 4GB RAM, 50GB availabile in `/var/lib/jenkins` and 10GB available in `/var/lib/mock` if you intend to do non CI triggered mock builds (highly recommended for debugging). It's fine to use a VM for this.
* verify with `timedatectl` that your timezone is set correctly (for correct timestamps in Jenkins).
* Register the server to RHN RHEL7 base and RHEL7 rhel-7-server-satellite-tools repos. You need the Satellite Tools repo for puppet.
* Configure the server for access to the [EPEL](https://fedoraproject.org/wiki/EPEL) and [Jenkins](http://pkg.jenkins-ci.org/redhat/) repos.
    * note that for EPEL 7, in addition to the 'optional' repository (rhel-7-server-optional-rpms), you also need to enable the 'extras' repository (rhel-7-server-extras-rpms).
* Install `httpd`, `mock`, `createrepo`, `git`, `nc` and `puppet` on the system. All but mock are available from the standard RHEL repos so should just install with yum. mock is available from EPEL.
    * `[root@jenkins ~]# yum install httpd mock createrepo git nc puppet`
* Ensure that `httpd` is enabled, running and reachable.
```bash
[root@jenkins ~]# systemctl enable httpd ; systemctl start httpd
[root@jenkins ~]# firewall-cmd --get-active-zones
[root@jenkins ~]# firewall-cmd --zone=public --add-service=http --permanent
[root@jenkins ~]# firewall-cmd --zone=public --add-service=https --permanent
[root@jenkins ~]# firewall-cmd --reload
[root@jenkins ~]# firewall-cmd --zone=public --list-all
```
* Configure `mock` by copying the [rhel-7-x86_64.cfg](https://github.com/RedHatEMEA/soe-ci/blob/master/rhel-7-x86_64.cfg) or [rhel-6-x86_64.cfg](https://github.com/RedHatEMEA/soe-ci/blob/master/rhel-6-x86_64.cfg) file to `/etc/mock` on the jenkins server and setting MOCK_CONFIG for the relevant Jenkins job.
    * edit the file and replace the placeholder `YOUROWNKEY` with your key as found in the `/etc/yum.repos.d/redhat.repo` file on the Jenkins server.
    * please see [this post on the Satellite blog](https://access.redhat.com/blogs/1169563/posts/2191211) for a more detailled explanation on mock with Satellite 6.
    * make sure the baseurl points at your Satellite server. The easiest way to do this is to just copy the relevant repo blocks from the Jenkins server's `/etc/yum.repos.d/redhat.repo`
    * if your Jenkins server is able to access the Red Hat CDN, then you can leave the baseurls pointing at https://cdn.redhat.com
    * if you are getting mock errors related to _systemd-nspawn_ then add `config_opts['use_nspawn'] = False` to your relevant mock config files.
* Install `jenkins`, `tomcat` and Java. If you have setup the Jenkins repo correctly you should be able to simply use yum.
    * `[root@jenkins ~]# yum install jenkins tomcat java`
* Ensure that `jenkins` is enabled, running and reachable.
```bash
[root@jenkins ~]# systemctl enable jenkins ; systemctl start jenkins
[root@jenkins ~]# firewall-cmd --zone=public --add-port="8080/tcp" --permanent
[root@jenkins ~]# firewall-cmd --reload
[root@jenkins ~]# firewall-cmd --zone=public --list-all
```
* Now that Jenkins is running, browse to it's console at http://jenkinsserver:8080/
* Select the 'Manage Jenkins' link, followed by 'Manage Plugins'. You will need to add the following plugins:
    * [Git Plugin](https://wiki.jenkins.io/display/JENKINS/Git+Plugin)
    * [Multiple SCMs Plugin](https://wiki.jenkins.io/display/JENKINS/Multiple+SCMs+Plugin)
    * [TAP Plugin](https://wiki.jenkins.io/display/JENKINS/TAP+Plugin)
    * [Pipeline Plugin](https://wiki.jenkins.io/display/JENKINS/Pipeline+Plugin)
    * [Parametrized Trigger Plugin](https://wiki.jenkins.io/display/JENKINS/Parameterized+Trigger+Plugin)


* Select 'Configure System'
    * Enable 'Environment variables' in the Global properties section and click save (there is no need to Add any). Failing to enable this property leads to https://github.com/RedHatSatellite/soe-ci/issues/48
* Restart Jenkins
* Add the `jenkins` user to the `mock` group (`usermod -a -G mock jenkins`). This will allow Jenkins to build RPMs.
* Create `/var/www/html/pub/soe-repo`, `/var/www/html/pub/soe-puppet` and assign their ownership to the `jenkins` user. These will be used as the upstream repositories to publish artefacts to the satellite.
    * Create `/var/www/html/pub/soe-puppet-only` for the puppet only workflow and assign its ownership to the `jenkins` user. It serves for the puppet only workflow.
    * The pipeline handles both full builds and puppet-only via variables, so set them up both.
* `su` to the `jenkins` user (`su jenkins -s /bin/bash`) and use `ssh-keygen` to create an ssh keypair. These will be used for authentication to both the git repository, and to the satellite server.

### Jenkins Jobs

#### Overview

First of all, let's have a look at the bigger picture here.
You'll create at least two jobs. One will be solely  responsible for polling your SCM. When changes are detected on the SCM, the second job will be triggered. The second job will then take care of building, pushing to Satellite and running the tests.
It is important to note that these steps (building the rpm's and/or puppet modules, pushing them to Satellite, running the tests etc.) will be done using a Jenkins Pipeline, so it is code written in Groovy and part of the soe-ci git repository. Documentation for the pipeline can be found [here](https://jenkins.io/doc/book/pipeline/). We use a scripted pipeline, not the declarative one.

The configuration options will be explained later on.

In general you might want to have multiple of these job pairs. E.g. for EL6 and EL7, building only puppet modules or the "full" build including RPMs.

#### Job parameters and what they do


Right now a couple of job parameters are used which you need to configure:

| Parameter Name  | Description  |
|---|---|
| SOE_CI_REPO_URL |  the git repository url of your soe-ci project |
| SOE_CI_BRANCH | the branch containing the Jenkinsfile and config file to build the RPMs and puppet modules from |
| CREDENTIALS_ID_SOE_CI_IN_JENKINS | the credentials id of the user configured in Jenkisn to access the source code of the soe ci project in git |
| ACME_SOE_REPO_URL | the git repository url to checkout the 'acme-soe' project from |
| ACME_SOE_BRANCH | the branch to checkout of the 'acme-soe' repo. |
| CREDENTIALS_ID_ACME_SOE_IN_JENKINS | analogous to CREDENTIALS_ID_SOE_CI_IN_JENKINS, can be the same, depending on your setup |
| RHEL_VERSION | this param indirectly configures two things: which mock config to use (the pattern is /etc/mock/<RHEL_VERSION>-x86_64.cfg) and which config file the pipeline uses for environment parameters (pattern is <RHEL_VERSION>-script-env-vars-puppet-only.groovy for a PUPPET_ONLY build and <RHEL_VERSION>-script-env-vars-rpm.groovy for a rpm and puppet module build.)
| REBUILD_VMS | whether or not to reinstall the test VMs before running the tests |
| POWER_OFF_VMS_AFTER_BUILD | Whether or not to power off the VMs after the build. The build result (successful / failed) is not taken into consideration. |
| PUPPET_ONLY | Whether or not **only** puppet modules should be built and pushed. This will reduce the duration of the build significantly (provided you update a CV that only contains puppet modules), however it ignores RPMs completely.
| CLEAN_WORKSPACE | Whether or not to clean the jenkins workspace before the job execution.|
| VERBOSE | Whether or not to run the executed scripts in a verbose mode. Basically it decides whether run 'bash -x' or just 'bash '|

### Create the jobs

#### Create a Job which runs the pipeline

* Create a directory matching the job name in /var/lib/jenkins/jobs (e.g.  (e.g. /var/lib/jenkins/jobs/soe-el7) and copy the [config-jenkinsfile.xml](config-jenkinsfile.xml) file into it as /var/lib/jenkins/jobs/&lt;job-name&gt;/config.xml. Make sure the jenkins user is the owner of both.
* Reload the configuration from disk using 'Manage Jenkins -> Reload Configuration from Disk'.
* Check that the build plan is visible and correct via the Jenkins UI, you will surely need to adapt the parameter values to your environment.
  * Make sure that in the "Pipeline" section of the job configuration the "Lightweight checkout" is ticked and that the value for "Script Path" points to the "Jenkinsfile" in your repository.

#### Create a job which polls the SCMs and then triggers the previously created job

* Create a directory matching the job name in /var/lib/jenkins/jobs (e.g.  (e.g. /var/lib/jenkins/jobs/scm-poll-for-soe-el7) and copy the [config.xml](config.xml) file into it. Make sure the jenkins user is the owner of both.
* Reload the configuration from disk using 'Manage Jenkins -> Reload Configuration from Disk'.
* Check that the build plan is visible and correct via the Jenkins UI, you will surely need to adapt the parameter values to your environment.

### How do I change the pipeline
It's simple. It's written in [Groovy](http://groovy-lang.org/syntax.html). If you want to test your changes first before pushing multiple commits to the repository, you can simply create a new job, which is a copy of your "second" job (remember, there are two jobs, one which pulls and one which builds), and change in the "Pipeline" section the "Defintion" from "Pipeline Script from SCM" to "Pipeline Script". Copy and paste your pipeline in the box (it's a groovy sandbox), and you're good to go. Remember this is for testing only. Once you're done, push your changes accordingly and delete the job you created for testing purposes.

## Git Repository

* Clone the following two git repos:

    * https://github.com/RedHatSatellite/soe-ci These are the scripts used to by Jenkins to drive CI
    * https://github.com/RedHatSatellite/acme-soe This is a demo CI environment
* Push these to a private git remote (or branch/fork on github).
* Edit the build plan on your Jenkins instance so that the two SCM checkouts point (one for acme-soe, the other for soe-ci) point to your private git remote - you will need to edit both of these.
* Make sure to set up the files `script-env-vars.groovy  script-env-vars-puppet-only.groovy  script-env-vars-rpm.groovy`
    * be sure to have a different PUPPET_REPO_ID for the full and puppet-only build.
* Maintain your pipeline script `Jenkinsfile` in soe-ci.git
* Commit and push to git

## Satellite 6

* Install and register a Red Hat Satellite 6 as per the [instructions](https://access.redhat.com/site/documentation/en-US/Red_Hat_Satellite/6.0/html/Installation_Guide/index.html).
* Enable the following repos: RHEL 7 Server Kickstart 7Server, RHEL 7 Server RPMs 7Server, RHEL 7 Server - RH Common RPMs 7 Server
* Create a sync plan that does a daily sync of the RHEL product
* Do an initial sync
* Create a product called 'ACME SOE'
* Create two Puppet repos
    * One called 'Puppet' with an upstream repo of http://jenkinsserver/pub/soe-puppet
    * One called 'Puppet only' with an upstream repo of http://jenkinsserver/pub/soe-puppet-only
* Create an RPM repository called 'RPMs' with an upstream repo of http://jenkinsserver/pub/soe-repo
* Do NOT create a sync plan for the ACME SOE product. This will be synced by Jenkins when needed.
    * keep an eye on [RHBZ #1132980](https://bugzilla.redhat.com/show_bug.cgi?id=1132980) if you use a web proxy at your site to download packages to the Satellite.
    * see [here](https://bugzilla.redhat.com/show_bug.cgi?id=1132980#c22) or [here](https://access.redhat.com/solutions/2026163) for a workaround until this is fixed.
* Take a note of the repo IDs for the Puppet and RPMs repos. You can find these by hovering over the repository names in the Products view on the Repositories tab. The digits at the end of the URL are the repo IDs.
* Create a `jenkins` user on the satellite.
* Configure hammer for passwordless usage by creating a `~jenkins/.hammer/cli.modules.d/foreman.yml` file (older Satellite versions use `~jenkins/.hammer/cli_config.yml`). [More details here](http://blog.theforeman.org/2013/11/hammer-cli-for-foreman-part-i-setup.html).
* Copy over the public key of the `jenkins` user on the Jenkins server to the `jenkins` user on the satellite and ensure that `jenkins` on the Jenkins server can do passwordless `ssh` to the satellite.
* Configure a Compute Resource on the satellite - I use libvirt, but most people are using VMWare or RHEV. This will be used to deploy test machines.

## Bootstrapping
In order to create a Content View on the satellite, you need some initial content. That can be generated by Jenkins.

Now manually trigger both

* a normal build
* a puppet-only build

This will fail, however it will create some content in the output directories by building the demo RPMs and Puppet modules. Check that these are available then do the following tasks:

* On the satellite, do a manual sync of your ACME SOE product. Check that it syncs correctly and you have got the RPMs and puppet modules that Jenkins built for you.
* Add the ACME SOE RPM and Puppet repos to the Content View, along with the RHEL 7 RPMs and RHEL 7 Common repos, and any third party puppet modules that are needed.
* Publish the Content View - ensure that it contains your RPMs and puppet modules.
* Create a lifecycle environment that your test clients will live in. I called mine 'SOE Test' you will need to get the ID of this environment, most likely it will be 2 or you can find it with 'hammer lifecycle-environment list --organization="Default_Organization"'
* Create an activation key that provides access to the RHEL 7 RPMs, RHEL 7 Common, RPMS, and Puppet repos. (you don't need access to the kickstart repo after installation)
* Create a hostgroup (I called mine 'Test Servers') that deploys machines on to the Compute Resource that you configured earlier, and uses the activation key that you created. Create a default root password and make a note of it.
* Create a couple of initial test servers and deploy them. Ensure that they can see your private RPM and puppet repositories as well as the Red Hat repositories.
    * If you plan to use the conditional VM build feature, edit the comment field of your test host(s) with the names of the Puppet modules, RPM packages and/or kickstart files surrounded by '#' if they are relevant to be tested on this specific host. E.g. if the 'ssh' module is modified, a host will only be re-built and tested if its comment field contains the string '#ssh#'.
* CReate one or two Host Collections and configure TESTVM_HOSTCOLLECTION in `script-env-vars-puppet-only.groovy` and `script-env-vars-rpm.groovy`

FIXME: add instructions on HC

# Getting Started
At this point, you should be good to go. In fact Jenkins may have already kicked off a build for you when you pushed to github.

Develop your build in your checkout of acme-soe. Software that you want packaging goes in 'rpms', puppet modules in 'puppet' and BATS tests in 'tests'. You MUST update versions (in specfiles and metadata.json files) whenever you make a change, otherwise satellite6 will not pick up that you have new versions, even though Jenkins will have repackaged them.

# COMING SOON

* Desperately missing a feature? Found a bug? Open a ticket on https://github.com/RedHatSatellite/soe-ci/issues
