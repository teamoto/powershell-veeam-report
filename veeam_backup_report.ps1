##
## Title: Veeam Backup Report  
## Date: 02/27/2018
## Version: 1.00
## Author: Ted Emoto    
## This scripts retrieves results of each backup job on Veeam Backup and Replication.
## Also you have an option to send the report to specific email address(es).
##


#### User defined variables ####

### Please define variables in the following section ###

$reportTitle = "Veeam Backup Report"
$reportFileName = "veeam_backup_report"
$outputFolder = "c:\temp"


### Please fill out the following section if you need to send an email ###

$sendEmail = "no" # please use either "yes" or "no" to determine whether sending an email or not
$fromAddress = "veeam@your_domain.com"
$recipients = "your_email_address@your_domain.com" # for single destination
# $recipients = (your_email_address@your_domain.com",your_boss_s_email_address@your_domain.com") # for multi-destination (you can add destinations by adding comma and quotes)
$message = "Please see the attached report."
$smtpServer = "smtp.your_domain.com"

#### End of user defined variables ####
#### Please do not modify anything below ####



# Get today's date
$today = Get-Date


# Define an empty variable that contains html design
$htmlCode=""

# Add CSS template
$htmlCode +="<style>TABLE{ border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;align:center;width:100%;}
TH{border-width: 1px;background-color: lightblue;bgcolor=blue;padding: 3px;border-style: solid;border-color: black;}
TD{border-width: 1px;color: Black;background-color: #DFDADA;padding: 3px;border-style: solid;border-color: black;}
 
h1{text-shadow: 1px 1px 1px #000,3px 3px 5px blue; text-align: center;font-style: calibri;font-family: Calibri;</style>"

# Main Header
$htmlCode +="<HTML><BODY>"
$htmlCode +="<h2 align=center><u>$($reportTitle)</u></h2>"
$htmlCode +="<h3 align=center><u>Issued on $($today)</u></h3>"
$htmlCode +="</br></br>"



# Importing Veeam Backup and Replication API
Add-PSSnapin VeeamPSSnapin
# Get backup job information
$vbrJobs = Get-VBRJob | Sort-Object typetostring,name
$vbrSessions = Get-VBRBackupSession

# Create a table for easy-to-read layout
$htmlCode +="<table border=1 width=100%>"
$htmlCode +="<tr><th><B>Backup Job</B></th><th><B>Creation Time</B></th><th><B>Status</B></th></tr>"

# Loop to populate results of all backup jobs
Foreach($job in $vbrJobs)
{
    
    # Get job name
    $jobName = $job.Name
    # Limit the result for the last 1
    $result = $vbrSessions | Where {$_.JobName -eq "$($jobName)"} | Sort Creationtime -Descending | Select -First 1
   
    # Testing output 
    #Write-Output "Backup Job: $($result.Name)"
    #Write-Output "Created: $($result.CreationTime)"
    #Write-Output "Status: $($result.Result)"
    
    # Change result color depending upon backup status
    if($result.Result -eq "Success") {
        $htmlCode +="<tr><td>$($result.Name)</td><td>$($result.CreationTime)</td><td style='background-color:Green'><font color='White'>$($result.Result)</font></td></tr>"
    } elseif ($result.Result -eq "Warning"){
        $htmlCode +="<tr><td>$($result.Name)</td><td>$($result.CreationTime)</td><td style='background-color:Yellow'><font color='White'>$($result.Result)</font></td></tr>"
    } else {
        $htmlCode +="<tr><td>$($result.Name)</td><td>$($result.CreationTime)</td><td style='background-color:Red'><font color='White'>$($result.Result)</font></td></tr>"
    }


}


# End of html
$htmlCode += "</table></BODY></HTML>"

# Export the html report
$htmlPath = "$($outputFolder)\$($reportTitle).html"
$htmlCode | out-file $htmlPath

# Send an email if $sendEmail variable is equal to "yes"
if ($sendEmail -eq "yes") {

    Send-MailMessage -from $fromAddress -to $recipients -subject "$($reportTitle) on $($today)" -BodyAsHTML -body $htmlCode -priority normal -smtpServer $smtpServer -Attachment $htmlPath
}