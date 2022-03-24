#r "nuget: FSharp.Stats, 0.4.3"
#r "nuget: BioFSharp, 2.0.0-beta5"
#r "nuget: BioFSharp.IO, 2.0.0-beta5"
#r "nuget: Plotly.NET, 2.0.0-preview.18"
#r "nuget: Plotly.NET.ImageExport, 2.0.0-preview.16"
#r "nuget: BIO-BTE-06-L-7_Aux, 0.0.9"
#r "nuget: Deedle, 2.5.0"
#r "nuget: ISADotNet, 0.4.0-preview.4"
#r "nuget: ISADotNet.XLSX, 0.4.0-preview.4"
#r "nuget: ISADotNet.IO, 0.0.2"

#if IPYNB
#r "nuget: Plotly.NET.Interactive, 2.0.0-preview.16"
#endif // IPYNB

open System.IO
open ISADotNet
open ISADotNet.API
open Deedle
open BioFSharp
open FSharpAux
open FSharp.Stats
open Plotly.NET
open Plotly.NET.ImageExport
open arcIO.NET
open BIO_BTE_06_L_7_Aux.Deedle_Aux

let args : string array = fsi.CommandLineArgs |> Array.tail

let dataPath = Directory.GetFiles(args.[1], "*.quantAndProt").[0] 
let isaPath =  args.[0] 

let _,_,_,myAssayFile = XLSX.AssayFile.Assay.fromFile isaPath
let inOutMap = ISADotNet.createInOutMap myAssayFile

let normalizeFileName (f: string) = if Path.HasExtension f then f else Path.ChangeExtension(f, "wiff")
  
let getStrain (fileName: string) =
    let fN = fileName |> normalizeFileName
    ISADotNet.tryGetCharacteristic inOutMap "Cultivation" "strain" fN myAssayFile
    |> Option.defaultValue ""

let getGroupID (fileName: string) =
    let fN = fileName |> normalizeFileName
    ISADotNet.tryGetParameter inOutMap "Protein extraction" "Group name" fN myAssayFile
    |> Option.defaultValue ""
    |> int

let rawData = Frame.ReadCsv(dataPath, separators = "\t")

let indexedData =
    rawData
    |> Frame.indexRowsUsing (fun os -> 
            {|
                ProteinGroup    = os.GetAs<string>("ProteinGroup"); 
                StringSequence  = os.GetAs<string>("StringSequence");
                PepSequenceID   = os.GetAs<int>("PepSequenceID");
                GlobalMod       = os.GetAs<int>("GlobalMod")
                Charge          = os.GetAs<int>("Charge")
            |}
        )

let chargesCounted = 
    indexedData.RowKeys
    |> Seq.countBy (fun x -> x.Charge)

let globalmodCounted = 
    indexedData.RowKeys
    |> Seq.countBy (fun x -> x.GlobalMod)

let absDeltaMass = 
    indexedData.GetColumn<float>("AbsDeltaMass")
    |> Series.values
    
let lightQuant = 
    indexedData.GetColumn<float>("Quant_Light")
    |> Series.values
    |> Seq.map log2

let correlationsLight = 
    indexedData.GetColumn<float>("Correlation_Light_Heavy")
    |> Series.filter (fun k s -> k.GlobalMod = 0)
    |> Series.values
        
let correlationsHeavy = 
    indexedData.GetColumn<float>("Correlation_Light_Heavy")
    |> Series.filter (fun k s -> k.GlobalMod = 1)
    |> Series.values

let grid = 
    [
        Chart.Column(chargesCounted,Name="distribution of peptide charges")
        |> Chart.withXAxisStyle "charge"
        |> Chart.withYAxisStyle "count"    
        Chart.Histogram(lightQuant,Name="distribution of peptide quantifications")
        |> Chart.withXAxisStyle "log2(peak area) [a. u.]"
        |> Chart.withYAxisStyle "count"    
        Chart.Histogram(absDeltaMass,Name="distribution of mass differences")
        |> Chart.withXAxisStyle "mass difference [Da]"
        |> Chart.withYAxisStyle "count"
        [
        Chart.BoxPlot(correlationsLight,Name="light PSMs")
        |> Chart.withXAxisStyle "pearson correlation of XIC traces"
        Chart.BoxPlot(correlationsHeavy,Name="heavy PSMs")
        ]
        |> Chart.combine
    ]
    |> Chart.Grid(2,2)
    |> Chart.withTitle (sprintf "Quality Control: Group %i, strain: %s" (getGroupID "WCGr3_UF_1") (getStrain "WCGr3_UF_1"))
    |> Chart.withSize(1200.,600.)

grid 
|> Chart.saveHtml("plot")













