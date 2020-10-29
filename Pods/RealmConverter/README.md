# Realm Converter

Realm Converter is an open source software utility framework to make it easier
to get data both in and out of Realm.
It has been built in Swift, but can also be easily utilized in Objective-C projects.

## Technical Requirements

macOS: 10.9 or later
iOS: 10.0 or later

## Features

### Schema Generator
* Provides an interface to analyze the intended files to import and produce
a compatible schema set that can be used to generate the Realm file

### Importer
* Imports from CSV, XLSX and JSON.

### Exporter
* Exports a Realm file to CSV.

## Examples

Using Swift's Objective-C bridging, it's possible to use Realm Converter in Objective-C
as well; and all classes on the Objective-C side are pre-fixed with `RLM`.

### Exporting a Realm file to CSV
```swift
let realmFilePath = '' // Absolute file path to my Realm file
let outputFolderPath = '' // Absolute path to the folder which will hold the CSV files

let csvDataExporter = try! CSVDataExporter(realmFilePath: realmFilePath)
try! csvDataExporter.export(toFolderAtPath: outputFolderPath)
```

### Generate a Realm file from CSV
```swift
var filePaths = [String]() // Array of file paths to each CSV file to include
let destinationRealmPath = '' // Path to the folder that will hold this Realm file

// Analyze the files and produce a Realm-compatible schema
let generator =  ImportSchemaGenerator(files: filePaths)
let schema = try! generator.generate()

// Use the schema and files to create the Realm file, and import the data
let dataImporter = CSVDataImporter(files: filePaths)
try! dataImporter.import(toPath: destinationRealmPath, schema: schema)
```

# License

Realm Converter is licensed under the Apache license. See the LICENSE file for details.
