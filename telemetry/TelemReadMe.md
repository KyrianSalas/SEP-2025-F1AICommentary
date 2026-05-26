## Telemetry Directory

A folder containing telemetry and related stuff

## Contents:
 - __MoTecRaw__: Contains raw .ld files from motec, these can't be worked with directly and have to be converted manually to csvs using motec software
 - __MoTecCSVs__: The output of the csv conversion, contains a header and 169 fields for the main data
 - __ParsedCSVs__: The output of the parser, no header and only relevant fields - these may not be the same from file to file if the field whitelist has been changed between runs
- __Scripts__: Any scripts used to process this data - atm only contains the csv parser and whitelist, explained below


## csv parser:
- Prerequisite: pandas
- In scripts directory
- Removes all the unnecessary data from the MoTecCSVs, cutting file size and closer resembling true obd2 data
- Removes header and mushes units into title row
- Only keeps fields based on the contents of the whitelist file
- Creates an additional metadata file for each lap with info from the header and first line, according to metafields.txt