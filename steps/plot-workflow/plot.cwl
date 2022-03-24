cwlVersion: v1.2
class: CommandLineTool
hints:
  DockerRequirement:
    dockerPull: mcr.microsoft.com/dotnet/sdk:5.0
requirements:
  InitialWorkDirRequirement:
    listing:
      - class: File
        location: plot.fsx
  EnvVarRequirement:
    envDef:
      - envName: DOTNET_NOLOGO
        envValue: "true"
  NetworkAccess:
    networkAccess: true  
baseCommand: [dotnet, fsi]
arguments:
  - position: 1
    valueFrom: ./plot.fsx
inputs:
  assay_file:
    type: File
    inputBinding:
      position: 2
  quantAndProt_dir:
    type: Directory
    inputBinding:
      position: 3
outputs:
  plot_file:
    type: File
    outputBinding:
      glob: "plot.html"
