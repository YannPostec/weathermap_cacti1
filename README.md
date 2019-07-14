# Weathermaps Producing Script with Cacti 1.x 

Just a quick & dirty way to produce weathermaps with cacti 1.x using [PHP Weathermap](https://github.com/howardjones/network-weathermap)

## Install
Install imagemagick for convert utility  
Retrieve last weathermap version 0.98a and install somewhere like /weathermap  
Clone the script directory into it /weathermap/myscript  
Create a weathermap directory on your website like /var/www/localhost/htdocs/weathermap/  

They are two scripts :
- generate_config.pl to create the main script configuration file
- create_weathermaps.pl to launch weathermap on your map config files and create a web page

Adjust in scripts the variables according to your needs
- $root_dir with the absolute path to weathermap
- $cacti_path_rra with the absolute path to cacti rra directory
- $web_path with the absolute path to your weathermap web directory
- $web_path_relative with the relative url path for your weathermap web directory
- $thumb_size with the size in pixels of weathermap thumbnails
- $debug change to 1 to activate debug in log file

Only if you change defaults
- $conf_dir with path to the weathermap config files
- $exec_dir with path to the script
- $weathermap_bin with the name of weathermap binary
- $html_file with the filename you want for the html result file
- $css_file with the path/filename you want for the css file, you need to edit the script to change the path as well
- $js_file with the path/filename you want for the js file, idem you need to edit the script if you change it
- $ficlog with path to the log file
- $ficconf with path to the script configuration file, must be the same in both scripts

## Generate Configuration

Each time you create or delete a weathermap configuration file, launch this script
````
./generate_config.pl
````
It generates the myscript.conf file while keeping the contents of the previous parameters  
If you delete a weathermap configuration file, it will be deleted from this file.  
If you add one, it will be added with defaults parameters  
	
Structure of this file :
- one line per weatermap configuration file
- per line four parameters separated with ;
- parameter 1: Filename without suffix
- parameter 2: Enable 1=Yes, 2=No
- parameter 3: Group Name if none defaults to Default
- parameter 4: Weathermap Name to display in webpage, default to filename

## Create Weathermaps
To launch the script
````
./create_weathermaps.pl
````

It will 
- Browse every configuration files you enabled
- Launch weathermap to create a picture of each map
- Use convert to create thumbnails for each map
- Create a web page with tabs depending on your groups to display all those maps

## Put task in crontab

Edit your crontab with something like
````
crontab -e
````

and add a launch every 5 minutes
````
*/5 * * * * root /weathermap/myscript/create_weathermap.pl > /weathermap/myscript/log/out.log 2>&1
````

## Add Tab in Cacti

In Cacti in the menu Console/Utilities/External Links you can create a Top Tab pointing to the generated web page
