# vmwarensxlabsetup
It contains scripts(16) to quickly setup VMware NSX Lab to perform testing for basic Testing. It actually perform 15 tasks and for each task there is a script and all the scripts are called from single script named "nsxsetup.ps1"
All the scripts captures the environment specific details via the json file named "infradetails.json"

Usage Instructions 

Download all the scripts and create a folder called "Scripts" under C:\ for windows ( I haven't had chance to test it in linux)
Modify the json file as per your environment 
Open PowerCLI and navigate to the C:\Scripts and execute "nsxsetup.ps1"

Pre-requisites

Management VC – VC where NSX Manager will be deployed. It could be same as Compute VC. It is named as mgmtvsphere in json file 
Compute VC -   VC which will be integrated with NSX. It is named as vsphere in json file  
VDS – Distributed Switch on Compute VC along with Port Group with MTU 1600
Datastore(s) – Datastores where all the VMs will be deployed i.e. NSX Manager , NSX Controller, NSX DLR & NSX Edge. Details needs to be updated in JSON file
IP Details – All the IP details for all the VMs deployed. Details needs to be updated in JSON file 

Demo Link

I have recorded Demo for the Script . ### No Audio. Visual Updates Only ###

https://youtu.be/67YTv8NI7VY
