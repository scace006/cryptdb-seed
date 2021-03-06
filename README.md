# Cryptdb-seed Repo

This repor is a fork of the original cryptdb  https://github.com/CryptDB/cryptdb

##### 1. Downloading and installing required software.
* Download and install VirtualBox from https://www.virtualbox.org/wiki/Downloads
* Download a desktop image of Ubuntu14 from http://releases.ubuntu.com/14.04/
* Open VirtualBox and create a new machine
	* Type: Linux
	* Version: Ubuntu
	* Hard disk: Create a virtual hard disk now
	* Allocation of 15GB is recommended

##### 2. Set up the machine using the Ubuntu14 image
* Select the new machine, and click start
* Select the ubuntu image, if not already selected, and click start
* Once the machine boots, follow on-screen instructions to install Ubuntu

##### 3. Updating the software
* On first reboot, the system will prompt you to upgrade to the newer Ubuntu16. Decline
* To update the system, there are two options:
	* I. Launch software updater
	* II. Launch terminal, and use the commands:
		* **sudo apt update**
		* **sudo apt upgrade**
				
##### 4. Downloading and installing required software for CryptDB
* Download the cryptdb_supp folder from the GitHub page
* In terminal, navigate to the cryptdb_supp folder
* Run the setup.sh file using the command **sudo ./setup.sh**
	* This will install bison2.7, ruby, git, apache2, php5, and download a copy of cryptdb
* In terminal, navigate to cryptdb/scripts/ and run **sudo gedit install.rb**
	* Remove all of line 40, and the backslash from line 39
* Navigate back to the cryptdb folder, and run **sudo scripts/install.rb .**
	* Do not omit the dot at the end of the command
	* This will install cryptdb
	* In order for cryptdb to work with its default configurations, MySQL password should be **letmein**
* (Optional) To install the webview, run **sudo cp -r ~cryptdb_supp/webview/ /var/www/html/**
	* This will copy the webview directory to the apache root
	* To use webview, launch the browser, and go to **localhost/webview**
	
#### 5. Using cryptdb
* To run cryptdb, there should be a cdbserver.sh and cdbclient.sh file inside the directory
	* Run the server file with **./cdbserver.sh** first
	* Run the client file with **./cdbclient.sh** in a seperate window
* To exit from cryptdb, make sure that all clients disconnect before terminating the server
	* To disconnect the client, simply enter **quit**
	* To terminate the server use ctrl-c
