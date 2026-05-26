# Extracts only necessary fields from motec csvs

#Imports
import os
import re
import pandas as pd

# File Paths
inputPath = r"telemetry\MoTecCSVs"
baseOutputPath = r"telemetry/ParsedCSVs"
whitelistPath = r"telemetry\Scripts\whitelist.txt"
metaFieldsPath = r"telemetry\Scripts\metaFields.txt"

# Magic numbers
HEADERLENGTH = 11 # Number of lines to skip for the header


def getFieldList(listPath):
    """Loads a list of fields from a txt file, where each list is a field

    Args:
        listpath: the path to the 
    Returns:
        fieldlist: a list of field names
        
    """
    fieldList = []
    with open(listPath, 'r') as listFile:
        for field in listFile:
            fieldList.append(field.strip())
    return fieldList


def getHeaderData(headerDF, keys):
    """Gets relevant data from the header for filename

    Args:
        headerDF: a pandas dataframe containing the header section of the csv
        keys: a list of the field names of interest in the header
    Returns:
        headerdata: a pandas dataframe containing only the relevent headerdata  
    """

    headerData = {}

    # Iterate through each row
    for _, row in headerDF.iterrows():
        key = str(row[0]).strip('"').strip() if pd.notna(row[0]) else ""

        if key in keys:
            value = str(row[1]).strip('"').strip() if len(row) > 1 and pd.notna(row[1]) else ""
            headerData[key] = value

    return headerData


def makeFilename(headerData):
    """Creates a Filename using retrieved header metadata

    Args:
        headerdata: a pandas dataframe containing the extracted headerdata 
    Returns:
        filename: a string constructed from the headerdata
    """

    venue = headerData.get("Venue", "unknown")
    vehicle = headerData.get("Vehicle", "unknown")
    date = headerData.get("Log Date", "unknown")
    time = headerData.get("Log Time", "unknown")

    # Replace slashes and colons with dashes
    dateClean = date.replace("/", "-")
    timeClean = time.replace(":", "-")

    # Remove unsafe filename characters (anything not letters, numbers, dash, or underscore)
    def safe(s):
        return re.sub(r'[^A-Za-z0-9_-]', '_', s)

    filename = f"{safe(venue)}_{safe(vehicle)}_{dateClean}_{timeClean}"
    return filename


def combineUnits(df):
    """Merges the units row into the field names row, more like the KIT dataset

    Args:
        df: a pandas dataframe, where the first field of each column contains the units
    Returns:
        df: the same dataframe as above, but with units contained in field names
    """
    # Get field names and units
    fieldNames = list(df.columns)
    units = list(df.iloc[0])
    
    # Combine them: e.g. "Speed (m/s)"
    newColumns = [
        f"{name.strip()} ({unit.strip()})" if pd.notna(unit) and str(unit).strip() != "" else name.strip()
        for name, unit in zip(fieldNames, units)
    ]
    
    # Drop the units row and rename columns
    df = df.drop(df.index[0]).reset_index(drop=True)
    df.columns = newColumns
    return df

# Retrieve whitelist and metaFields
whitelist = getFieldList(whitelistPath)
metaFields = getFieldList(metaFieldsPath)

# Keys of interest for the header:
nameKeys = ["Vehicle", "Venue", "Log Date", "Log Time"]
metaKeys = ["Vehicle", "Venue", "comment", "Log Date", "Log Time", "Sample Rate", "Duration", "Range"]

# Run on each file in inputPath
for motecFile in os.scandir(inputPath):
    if motecFile.is_file():
        # Header Stuff

        # Retrieve the header
        header_df = pd.read_csv(motecFile, nrows=HEADERLENGTH, usecols=[0,1], header=None)


        # create the output paths for this file
        fileName = makeFilename(getHeaderData(header_df, nameKeys))
        outputPath = os.path.join(baseOutputPath, fileName + '.csv')
        metaOutputPath = os.path.join(baseOutputPath + r'\meta', fileName + 'Meta.csv')

        # Retrieve header metadata
        headerData = pd.DataFrame([getHeaderData(header_df, metaKeys)])
        timeStep = 1 / float(headerData['Sample Rate'][0])


        # Body Stuff

        # Load the body of the file into a pandas dataframe
        motecdf = pd.read_csv(motecFile.path, skiprows=HEADERLENGTH)

        # Parsing steps

        # Retrieve metadata from one of the first lines in the program
        metadf = (motecdf.loc[[3]][[field for field in motecdf if field in metaFields]])

        # write metadf and headerdata to the same file
        pd.concat([headerData.reset_index(drop=True), metadf.reset_index(drop=True)], axis=1).to_csv(metaOutputPath, index = False)

        # Cretae a new dataframe containing only the relevant fields
        filteredMotecdf = combineUnits(motecdf[[field for field in motecdf if field in whitelist]])

        # Add Timestamp as first column
        timestamps = [round(i * timeStep, 5) for i in range(len(filteredMotecdf))]
        filteredMotecdf.insert(0, "Time (s)", timestamps)

        # Write the new dataframe to the output file
        filteredMotecdf.to_csv(outputPath, index=False)
