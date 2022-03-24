cwlVersion: v1.2
class: Workflow
requirements:
  - class: MultipleInputFeatureRequirement
inputs:
  - id: input_wiff
    type: File
  - id: input_fasta
    type: File
outputs:
  - id: history
    outputSource: execution/history
    type: Directory
steps:
  - id: preprocessing
    in:
      - id: input_wiff
        source: input_wiff
      - id: input_fasta
        source: input_fasta
    out:
      - paramFile
      - inputDataFolder
    run:
      cwlVersion: v1.2
      class: CommandLineTool
      requirements:
        - class: InlineJavascriptRequirement
        - class: ShellCommandRequirement
        - class: DockerRequirement
          dockerFile:
            $include: ./dockerfiles/cwl-galaxy-parser/Dockerfile
          dockerImageId: cwl-galaxy-parser
        - class: NetworkAccess
          networkAccess: true
      baseCommand: cwl-galaxy-parser
      inputs:
        - id: input_wiff
          type: File
          inputBinding:
            prefix: '--file input_wiff'
            shellQuote: false
        - id: input_fasta
          type: File
          inputBinding:
            prefix: '--file input_fasta'
            shellQuote: false
      outputs:
        - id: paramFile
          type: File
          outputBinding:
            glob: $(runtime.outdir)/galaxyInput.yml
        - id: inputDataFolder
          type: Directory
          outputBinding:
            glob: $(runtime.outdir)
  - id: execution
    in:
      - id: workflowInputParams
        source: preprocessing/paramFile
      - id: inputDataFolder
        source: preprocessing/inputDataFolder
    out:
      - history
    run:
      cwlVersion: v1.2
      class: CommandLineTool
      requirements:
        - class: InlineJavascriptRequirement
        - class: ShellCommandRequirement
        - class: InitialWorkDirRequirement
          listing:
            - entryname: inputDataFolder
              entry: $(inputs.inputDataFolder)
            - $(inputs.workflowInputParams)
            - class: File
              location: workflow.ga
            - entryname: history
              entry: '$({class: ''Directory'', listing: []})'
              writable: true
        - class: DockerRequirement
          dockerFile:
            $include: ./dockerfiles/planemo-run/Dockerfile
          dockerImageId: planemo
        - class: NetworkAccess
          networkAccess: true
      baseCommand:
        - planemo
        - run
      arguments:
        - position: 1
          valueFrom: ./workflow.ga
        - position: 3
          prefix: '--output_directory'
          valueFrom: $(runtime.outdir)/history
        - position: 4
          valueFrom: '--download_outputs'
        - position: 5
          prefix: '--engine'
          valueFrom: external_galaxy
        - position: 6
          prefix: '--galaxy_url'
          valueFrom: $GALAXY_URL
          shellQuote: false
        - position: 7
          prefix: '--galaxy_user_key'
          valueFrom: $GALAXY_API_KEY
          shellQuote: false
      inputs:
        - id: inputDataFolder
          type: Directory
        - id: workflowInputParams
          type: File
          inputBinding:
            position: 2
      outputs:
        - id: history
          type: Directory
          outputBinding:
            glob: $(runtime.outdir)/history
