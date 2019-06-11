Configuration InstallIIS
# Configuration Main
{

Param ( [string] $nodeName, $WebDeployPackagePath )

Import-DscResource -ModuleName PSDesiredStateConfiguration

Node $nodeName
  {
    WindowsFeature WebServerRole
    {
      Name = "Web-Server"
      Ensure = "Present"
    }
    WindowsFeature WebManagementConsole
    {
      Name = "Web-Mgmt-Console"
      Ensure = "Present"
    }
    WindowsFeature WebManagementService
    {
      Name = "Web-Mgmt-Service"
      Ensure = "Present"
    }
    WindowsFeature ASPNet45
    {
      Name = "Web-Asp-Net45"
      Ensure = "Present"
    }
    WindowsFeature HTTPRedirection
    {
      Name = "Web-Http-Redirect"
      Ensure = "Present"
    }
    WindowsFeature CustomLogging
    {
      Name = "Web-Custom-Logging"
      Ensure = "Present"
    }
    WindowsFeature LogginTools
    {
      Name = "Web-Log-Libraries"
      Ensure = "Present"
    }
    WindowsFeature RequestMonitor
    {
      Name = "Web-Request-Monitor"
      Ensure = "Present"
    }
    WindowsFeature Tracing
    {
      Name = "Web-Http-Tracing"
      Ensure = "Present"
    }
    WindowsFeature BasicAuthentication
    {
      Name = "Web-Basic-Auth"
      Ensure = "Present"
    }
    WindowsFeature WindowsAuthentication
    {
      Name = "Web-Windows-Auth"
      Ensure = "Present"
    }
    WindowsFeature ApplicationInitialization
    {
      Name = "Web-AppInit"
      Ensure = "Present"
    }
    Script DownloadDotNetCore
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\dotnet-hosting-2.2.5-win.exe"
        }
        SetScript ={
            $source = "https://download.visualstudio.microsoft.com/download/pr/34f4b2a6-c3b8-495c-a11f-6db955f27757/8c340c1a8c25966e39e0c0a4b308dff4/dotnet-hosting-2.2.5-win.exe"
            $dest = "C:\WindowsAzure\dotnet-hosting-2.2.5-win.exe"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "DownloadDotNetCore"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Package InstallDotNetCore
    {
        Ensure = "Present"  
        Path  = "C:\WindowsAzure\dotnet-hosting-2.2.5-win.exe"
        Name = ".NET Core Runtime & Hosting Bundle"
        ProductId = "{8D27B411-C430-4CA0-8D49-DE3637140931}"
        Arguments = "/install /quiet"
        DependsOn = "[Script]DownloadDotNetCore"
    }
    Script DownloadWebDeploy
    {
        TestScript = {
            Test-Path "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        }
        SetScript ={
            $source = "https://download.microsoft.com/download/0/1/D/01DC28EA-638C-4A22-A57B-4CEF97755C6C/WebDeploy_amd64_en-US.msi"
            $dest = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
            Invoke-WebRequest $source -OutFile $dest
        }
        GetScript = {@{Result = "DownloadWebDeploy"}}
        DependsOn = "[WindowsFeature]WebServerRole"
    }
    Package InstallWebDeploy
    {
        Ensure = "Present"  
        Path  = "C:\WindowsAzure\WebDeploy_amd64_en-US.msi"
        Name = "Microsoft Web Deploy 3.6"
        ProductId = "{6773A61D-755B-4F74-95CC-97920E45E696}"
        Arguments = "ADDLOCAL=ALL"
        DependsOn = "[Script]DownloadWebDeploy"
    }
    Service StartWebDeploy
    {                    
        Name = "WMSVC"
        StartupType = "Automatic"
        State = "Running"
        DependsOn = "[Package]InstallWebDeploy"
    }
	Script DeployWebPackage
	{
		GetScript = {
            @{
                Result = ""
            }
        }
        TestScript = {
            $false
        }
        SetScript ={
		$WebClient = New-Object -TypeName System.Net.WebClient
		$Destination= "C:\WindowsAzure\WebApplication.zip" 
        $WebClient.DownloadFile($using:WebDeployPackagePath,$destination)
        $Argument = '-source:package="C:\WindowsAzure\WebApplication.zip" -dest:auto,ComputerName="localhost", -verb:sync -allowUntrusted'
		$MSDeployPath = (Get-ChildItem "HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" | Select -Last 1).GetValue("InstallPath")
        Start-Process "$MSDeployPath\msdeploy.exe" $Argument -Verb runas 
        }
	}
  }
}