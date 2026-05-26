# Extracts only necessary fields from motec csvs

#Imports
import os
import re
import pandas as pd

# File Paths
inputPath = r"C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary\DemoCSVs"
baseOutputPath = r"C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary\DemoCSVs\Archive"
whitelistPath = r"C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary\telemetry\Scripts\whitelist.txt"
metaFieldsPath = r"C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary\telemetry\Scripts\metaFields.txt"

# Demo Jank
txtPath = os.path.join(baseOutputPath, "latestFile.txt")

# Magic numbers
HEADERLENGTH = 11 # Number of lines to skip for the header

def getFieldList(listPath):
    """
    Load a list of fields from a txt file, where each list is a field
    Args:
        listPath : the path to a txt file containing a list fo fields
    Returns:
        fieldList : a list of fields
    """

    fieldList = []
    with open(listPath, 'r') as listFile:
        for field in listFile:
            fieldList.append(field.strip())
    return fieldList

def getHeaderData(headerDF, keys):
    """
    Get relevant data from the header for filename
    Args:
        headerDF   : a dataframe constructed from the header of a MoTecCSV
        keys       : a list containing the fields of interest from the header
    Returns:
        headerData : a dictionary containing the relevant header data
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
    """
    Create a Filename using retrieved header metadata
    Args:
        headerData : a dictionary of data from the header of a MoTecCSV
    Returns:
        filename
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
    """
    Merge the units row into the field names row, more like the KIT dataset
    Args:
        df : a dataframe where the 1st row contains the units of each column
    Returns:
        df : the same dataframe with the 1st two rows merged
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

def getTotalLapCount(df):
    """
    Retrieve total number of laps from body of file (last entry of lap count)
    Args:
        df : a dataframe with a 'Session Lap Count' column
    Returns:
        the final lap count
    """

    return df.iloc[-2]['Session Lap Count']

def getLapIndexes(df):
    """
    Find and return a list of indexes where laps are completed
    Args:
        df : a dataframe with a 'Session Lap Count' column
    Returns:
        a list containing every index where lap count increments
    """

    lapChanges = df['Session Lap Count'].diff() == 1
    return df.index[lapChanges].tolist()

def getMaxSpeed(df):
    """
    Find maximum ground speed value
    Args:
        df : a dataframe containing a 'Ground Speed (km/h)' column
    Returns:
        the maximum value of said column
    """

    return pd.to_numeric(df['Ground Speed (km/h)']).max()

def getRaceLength(df):
    return len(df)

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

        # Retrieve metadata from one of the first lines in the program
        metadf = (motecdf.loc[[3]][[field for field in motecdf if field in metaFields]])

        # Cretae a new dataframe containing only the relevant fields
        filteredMotecdf = combineUnits(motecdf[[field for field in motecdf if field in whitelist]])

        # Generate additional meta data fields from contents of body

        metadf['TotalLapCount']   = getTotalLapCount(filteredMotecdf)
        metadf['LapIndexes']      = [getLapIndexes(filteredMotecdf)]
        metadf['MaxSpeed']        = getMaxSpeed(filteredMotecdf)
        metadf['RaceIndexLength'] = getRaceLength(filteredMotecdf)


        # Add Timestamp as first column
        timestamps = [round(i * timeStep, 5) for i in range(len(filteredMotecdf))]
        filteredMotecdf.insert(0, "Time (s)", timestamps)

        # write metadf and headerdata to the same file
        pd.concat([headerData.reset_index(drop=True), metadf.reset_index(drop=True)], axis=1).to_csv(metaOutputPath, index = False)

        # Write the new dataframe to the output file
        filteredMotecdf.to_csv(outputPath, index=False)




        # DEMO SPECIAL:
        # write a txt file containing the name of the most recently added file
        with open(txtPath, 'w') as f:
            f.write(str(os.path.join(r'C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary', outputPath)))
        
        # delete the unparsed file
        os.remove(motecFile.path)
