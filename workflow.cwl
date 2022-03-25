cwlVersion: v1.2
class: Workflow
requirements:
  - class: MultipleInputFeatureRequirement
  - class: SubworkflowFeatureRequirement
inputs:
  - id: fasta_file
    type: File
  - id: wiff_archive
    type: File
  - id: assay_file
    type: File
outputs:
  plot_file:
      type: File
      outputSource: plot-workflow/plot_file
steps:
  - id: proteomiqon-delegation-workflow
    in:
      - id: input_fasta
        source: fasta_file
      - id: input_wiff
        source: wiff_archive
    out: [history]
    run: ./steps/proteomiqon-delegation-workflow/workflow.cwl
  - id: plot-workflow
    in:
      - id: quantAndProt_dir
        source: proteomiqon-delegation-workflow/history
      - id: assay_file
        source: assay_file
    out:
      - plot_file
    run: ./steps/plot-workflow/plot.cwl