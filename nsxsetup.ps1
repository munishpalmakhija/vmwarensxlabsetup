.\1_nsxdeploy.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Register VC'
.\2_registervc.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Assign License'
.\3_assign_nsx_license.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Host Preparation'
.\4_prepare_host.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - IP Pool Creation'
.\5_createippool.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Controller Deployment'
.\6_deploycontrollers.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Add Segment'
.\7_addsegment.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - VXLAN Config'
.\8_configurevxlan.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Transport Zone Creation'
.\9_createtransportzone.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Logical Switch Creation'
.\10_createlogicalswitch.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - DLR Deployment'
.\11_deploy_dlr.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - ESG Deployment'
.\12_deploy_esg.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - Default Gateway Config'
.\13_configuredefaultgateways.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - OSPF Config in DLR'
.\14_configureospfindlr.ps1
Read-Host -Prompt 'Please check vSphere Web Client and Press Enter to proceed with next Task - OSPF Config in Edge'
.\15_configureospfinedge.ps1


Write-Host "!!! NSX Lab Configuration has been Completed - Enjoy !!!"