Continuous Integration Scripts for Satellite 6
==============================================

* Domain Architect: Eric Lavarde
* Email: <elavarde@redhat.com>
* Consultant: Patrick C. F. Ernzer
* Email: <pcfe@redhat.com>
* Date: February and March 2016
* Revision: 0.2

- - -

* Author: Nick Strugnell
* Email: <nstrug@redhat.com>
* Date: 2014-11-20
* Revision: 0.1


## Introduction
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

## Setup
The following steps should help you get started with CII.

### Jenkins Server

NB I have SELinux disabled on the Jenkins server as I ran into too many problems with it enabled and didn't have the time to fix them.

#### Installation

* Install a standard RHEL 7 server with a minimum of 4GB RAM, 50GB availabile in `/var/lib/jenkins` and 10GB availabile in `/var/lib/mock. It's fine to use a VM for this.
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
[root@jenkins ~]# firewall-cmd  --reload
[root@jenkins ~]# firewall-cmd --zone=public --list-all
```
* Configure `mock` by copying the [rhel-7-x86_64.cfg](https://github.com/RedHatEMEA/soe-ci/blob/master/rhel-7-x86_64.cfg) or [rhel-6-x86_64.cfg](https://github.com/RedHatEMEA/soe-ci/blob/master/rhel-6-x86_64.cfg) file to `/etc/mock` on the jenkins server and symlinking, ensuring that the link `/etc/mock/default.cfg` points to it.
    * edit the file and replace the placeholder `YOUROWNKEY` with your key as found in the `/etc/yum.repos.d/redhat.repo` file on the Jenkins server.
    * please see [this post on the Satellite blog](https://access.redhat.com/blogs/1169563/posts/2191211) for a more detailled explanation on mock with Satellite 6.
    * make sure the baseurl points at your Satellite server. The easiest way to do this is to just copy the relevant repo blocks from the Jenkins server's `/etc/yum.repos.d/redhat.repo`
    * if your Jenkins server is able to access the Red Hat CDN, then you can leave the baseurls pointing at https://cdn.redhat.com
* Install `jenkins`, `tomcat` and Java. If you have setup the Jenkins repo correctly you should be able to simply use yum.
    * `[root@jenkins ~]# yum install jenkins tomcat java`
* Ensure that `jenkins` is enabled, running and reachable.
```bash
[root@jenkins ~]# systemctl enable jenkins ; systemctl start jenkins
[root@jenkins ~]# firewall-cmd --zone=public --add-port="8080/tcp" --permanent
[root@jenkins ~]# firewall-cmd  --reload
[root@jenkins ~]# firewall-cmd --zone=public --list-all
```
* Now that Jenkins is running, browse to it's console at http://jenkinsserver:8080/
* Select the 'Manage Jenkins' link, followed by 'Manage Plugins'. You will need to add the following plugins:
    * Git Plugin
    * Multiple SCMs Plugin
    * TAP Plugin
    * Post-Build Script Plug-in
* Select 'Configure System'
    * Enable 'Environment variables' in the Global properties section and click save (there is no need to Add any). Failing to enable this property leads to https://github.com/RedHatSatellite/soe-ci/issues/48
* Restart Jenkins
* Add the `jenkins` user to the `mock` group (`usermod -a -G mock jenkins`). This will allow Jenkins to build RPMs.
* Create `/var/www/html/pub/soe-repo` and `/var/www/html/pub/soe-puppet` and assign their ownership to the `jenkins` user. These will be used as the upstream repositories to publish artefacts to the satellite.
* `su` to the `jenkins` user (`su jenkins -s /bin/bash`) and use `ssh-keygen` to create an ssh keypair. These will be used for authentication to both the git repository, and to the satellite server.
* Create a build plan in Jenkins by creating the directory `/var/lib/jenkins/jobs/SOE` and copying in the  [config.xml] file
* Check that the build plan is visible and correct via the Jenkins UI, you will surely need to adapt the parameter values to your environment.
    * you might need to reload the configuration from disk using 'Manage Jenkins -> Reload Configuration from Disk'.

### Git Repository
* Clone the following two git repos:
    * https://github.com/RedHatEMEA/soe-ci   These are the scripts used to by Jenkins to drive CII
    * https://github.com/RedHatEMEA/acme-soe This is a demo CI environment
* Push these to a private git remote (or branch/fork on github).
* Edit the build plan on your Jenkins instance so that the two SCM checkouts point (one for acme-soe, the other for soe-ci) point to your private git remote - you will need to edit both of these.

### Satellite 6
* Install and register a Red Hat Satellite 6 as per the [instructions](https://access.redhat.com/site/documentation/en-US/Red_Hat_Satellite/6.0/html/Installation_Guide/index.html).
* Enable the following repos: RHEL 7 Server Kickstart 7Server, RHEL 7 Server RPMs 7Server, RHEL 7 Server - RH Common RPMs 7 Server
* Create a sync plan that does a daily sync of the RHEL product
* Do an initial sync
* Create a product called 'ACME SOE'
* Create a puppet repository called 'Puppet' with an upstream repo of http://jenkinsserver/pub/soe-puppet
* Create an RPM repository called 'RPMs' with an upstream repo of http://jenkinsserver/pub/soe-repo
* Do NOT create a sync plan for the ACME SOE product. This will be synced by Jenkins when needed.
    * keep an eye on [RHBZ #1132980](https://bugzilla.redhat.com/show_bug.cgi?id=1132980) if you use a web proxy at your site to download packages to the Satellite.
    * see [here](https://bugzilla.redhat.com/show_bug.cgi?id=1132980#c22) or [here](https://access.redhat.com/solutions/2026163) for a workaround until this is fixed.
* Take a note of the repo IDs for the Puppet and RPMs repos. You can find these by hovering over the repository names in the Products view on the Repositories tab. The digits at the end of the URL are the repo IDs.
* Create a `jenkins` user on the satellite.
* Configure hammer for passwordless usage by creating a `~jenkins/.hammer/cli_config.yml` file. [More details here](http://blog.theforeman.org/2013/11/hammer-cli-for-foreman-part-i-setup.html).
* Copy over the public key of the `jenkins` user on the Jenkins server to the `jenkins` user on the satellite and ensure that `jenkins` on the Jenkins server can do passwordless `ssh` to the satellite.
* Configure a Compute Resource on the satellite - I use libvirt, but most people are using VMWare or RHEV. This will be used to deploy test machines.

### Bootstrapping
In order to create a Content View on the satellite, you need some initial content. That can be generated by Jenkins.

Now manually trigger a build on Jenkins. This will fail, however it will create some content in the output directories by building the demo RPMs and Puppet modules. Check that these are available then do the following tasks:

* On the satellite, do a manual sync of your ACME SOE product. Check that it syncs correctly and you have got the RPMs and puppet modules that Jenkins built for you.
* Add the ACME SOE RPM and Puppet repos to the Content View, along with the RHEL 7 RPMs and RHEL 7 Common repos, and any third party puppet modules that are needed.
* Publish the Content View - ensure that it contains your RPMs and puppet modules.
* Create a lifecycle environment that your test clients will live in. I called mine 'SOE Test' you will need to get the ID of this environment, most likely it will be 2 or you can find it with 'hammer lifecycle-environment list --organization="Default_Organization"'
* Create an activation key that provides access to the RHEL 7 RPMs, RHEL 7 Common, RPMS, and Puppet repos. (you don't need access to the kickstart repo after installation)
* Create a hostgroup (I called mine 'Test Servers') that deploys machines on to the Compute Resource that you configured earlier, and uses the activation key that you created. Create a default root password and make a note of it.
* Create a couple of initial test servers and deploy them. Ensure that they can see your private RPM and puppet repositories as well as the Red Hat repositories.
    * If you plan to use the conditional VM build feature, edit the comment field of your test host(s) with the names of the Puppet modules, RPM packages and/or kickstart files surrounded by '#' if they are relevant to be tested on this specific host. E.g. if the 'ssh' module is modified, a host will only be re-built and tested if its comment field contains the string '#ssh#'.

### Getting Started
At this point, you should be good to go. In fact Jenkins may have already kicked off a build for you when you pushed to github.

Develop your build in your checkout of acme-soe. Software that you want packaging goes in 'rpms', puppet modules in 'puppet' and BATS tests  in 'tests'. You MUST update versions (in specfiles and metadata.json files) whenever you make a change, otherwise satellite6 will not pick up that you have new versions, even though Jenkins will have repackaged them.

## COMING SOON
* Kickstart files (currently doesn't do anything)
* Hiera usage
* Selective BATS tests - currently all tests run on all test servers, irrespective of whether the puppet module that they are testing is installed
