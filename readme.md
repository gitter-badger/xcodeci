xcodeci
=======

Ruby script for build/test/archive/distribuite iOS application.

This script can be uset to create a simple continuous integration service for xcode.

The project is still in development, **any contribution will be appreciate.**

Basic info
==========

The script runs in a loop and every five minutes it:

1. Reads the configuration file on `~/.xcodeci/xcodeci.conf.yaml` and iterates on each listed project
	1. Clones the repository inside the folder `~/.xcodeci/[app_name]`
	2. Executes `git fetch`, `git pull` and `git checkout` on the specified branch
	3. For each commit on that branch it:
		1. Builds the application (only if it's necessarely, otherwise skip to the next commit)
		2. Runs the unit test
		3. Save the dSym file on the output folder[^1]
		4. Generates the ipa file and the manifest.plist on the output folder
2. Generates a web page for the OTA distribution

[^1]: The current output folder is the dropbox folder specified on the configuration file.

How it's looks like
===================
This the output on console

![console output](https://dl.dropboxusercontent.com/u/792862/Screenshot%202014-10-03%2011.45.47.png)

And this is the html report
![web report](https://dl.dropboxusercontent.com/u/792862/Screenshot%202014-10-03%2011.47.41.png)

Basic usage
===========

1. Clone the script: 

	`git clone https://github.com/ignazioc/xcodeci`
	
2. Install the required gems

	`bundle install
	`
3. Install **xctool**

	`brew install xctool`
	
	for more info about brew command see the [brew website](http://brew.sh)
	
4. Run the script

	`./bin/xcodeci`
	
	The first time you will run the script a sample configuration file will be created on `~/.xcodeci/xcodeci.conf.yaml`

5. Edit your configuration file (see info below)

6. Run the script again and wait :)


The configuration file
======================

This is an example of the configuration file

	---
	App_Config:
	   #The public dropbox folder on your machine
	  :DROPBOX_FOLDER:    '/Users/username/Dropbox/Public/'
	  
	  #This is your dropbox userid, you can find it when you share a file stored on the
	  #public folder like this one https://dl.dropboxusercontent.com/u/792862/avatar_grumpy.png
	  #In this example the user id is 792862
	  #The user id is used to crete the links on the html report for install the application.
	  
	  :DROPBOX_USER_ID:   '792862'
	SampleApp1:
	  :REPO_URL:         'git@github.com:ignazioc/sample_repo_1.git'
	  :APP_NAME:         'SampleApp-1'
	  :TARGET_BRANCH:    'master'
	  :WORKSPACE:        'SampleApp 1.xcworkspace'
	  :SCHEME:           'SampleApp 1'
	SampleApp2:
	  :REPO_URL:         '.....'
	  :APP_NAME:         '.....'
	  :TARGET_BRANCH:    '.....'
	  :WORKSPACE:        '.....'
	  :SCHEME:           '.....'



 
