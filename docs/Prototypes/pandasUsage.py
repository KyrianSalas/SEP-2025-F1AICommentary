import pandas as pd
import tkinter as tk

#remember to change geometry of window
TOTAL_HEIGHT = 200
TOTAL_WIDTH = 300

#Create the main window
window = tk.Tk()
window.title("Live Display")
window.geometry("300x200")
infoWindow = tk.Tk()
infoWindow.title("Additional info")
infoWindow.geometry("240x300")

#Create canvas    
canvas = tk.Canvas(window, width=TOTAL_WIDTH, height=TOTAL_HEIGHT, bg="white")
canvas.pack()

#find left or right turning
def findTurn(df, x):
    if float(df['Steering Angle'][x]) == 0:
        return "in a straight line"
    elif float(df['Steering Angle'][x]) > 0:
        return f"{df['Steering Angle'][x]} degrees right"
    else:
        return f"{-df['Steering Angle'][x]} degrees left"

#true finds max, false finds min
def findMax(df, column, find=True):
    ans = 0
    if find:
        for val in df[column]:
                #make float
                try:
                    num = float(val)
                    if num > ans:
                        ans = num
                except (ValueError, TypeError):
                    continue
    if not find:
        ans = float(df[column][1])
        for val in df[column]:
                #make float
                try:
                    num = float(val)
                    if num < ans:
                        ans = num
                except (ValueError, TypeError):
                    continue
    return ans

def loadSpecificColumns(csvFile, requiredColumns):
    #Read header to check columns
    try:
        dfHeaders = pd.read_csv(csvFile, nrows=0)
    except FileNotFoundError:
        print("File " + csvFile + " not found.")
        return None

    allColumns = dfHeaders.columns.tolist()

    #Check if the columns being checked are there
    missing = [col for col in requiredColumns if col not in allColumns]
    if missing:
        raise ValueError(f"Missing required columns: {missing}")

    #Only take desired columns into data frame
    df = pd.read_csv(csvFile, usecols=requiredColumns)
    return df

def drawDot(x, y, radius=5, color="black"):
    canvas.create_oval(
        x - radius, y - radius,
        x + radius, y + radius,
        fill=color, outline=""
    )

def useDataExample(df):
    #Find additional value changes for x and y
    #Add 60 to any y co-ord value
    print(df['Car Coord Y'])
    XMin = findMax(df, 'Car Coord X', False)
    YMin = findMax(df, 'Car Coord Y', False)
    XTotal = findMax(df, 'Car Coord X', True) - XMin
    YTotal = findMax(df, 'Car Coord Y', True) - YMin

    #Create labels
    valueLabel = tk.Label(infoWindow, text="", font=('Arial', 9))
    valueLabel.pack(pady=5)
    valueLabel1 = tk.Label(infoWindow, text="", font=('Arial', 9))
    valueLabel1.pack(pady=5)
    valueLabel2 = tk.Label(infoWindow, text="", font=('Arial', 9))
    valueLabel2.pack(pady=5)
    valueLabel3 = tk.Label(infoWindow, text="", font=('Arial', 9))
    valueLabel3.pack(pady=5)
    valueLabel4 = tk.Label(infoWindow, text="", font=('Arial', 9))
    valueLabel4.pack(pady=5)
    x = 0
    while True:        
        #Adjust point in playback
        x += int(input(" : "))

        #Create relevant values x and y
        if XMin < 0:
            NewX = (TOTAL_WIDTH - 50) * ((float(df['Car Coord X'][x]) - XMin) / XTotal) + 25
        else:
            NewX = (TOTAL_WIDTH - 50) * ((float(df['Car Coord X'][x]) + XMin) / XTotal) + 25
        if YMin < 0:
            NewY = (TOTAL_HEIGHT - 20) * ((float(df['Car Coord Y'][x]) - YMin) / YTotal) + 30
        else:
            NewY = (TOTAL_HEIGHT - 20) * ((float(df['Car Coord Y'][x]) + YMin) / YTotal) + 30



        carPos = df['Car Pos Norm'].iloc[x]
        #draw to windows
        valueLabel.config(text=f"The car is : {round(df['Car Pos Norm'].iloc[x]*100, 2)}% through the race")
        valueLabel1.config(text=f"The Engine RPM is : {df['Engine RPM'].iloc[x]}")
        valueLabel2.config(text=f"The car is in gear : {int(df['Gear'].iloc[x])}")
        valueLabel3.config(text=f"The car is at a speed of : {round(float(df['Ground Speed'].iloc[x])/ 1.6, 2)} mph")
        valueLabel4.config(text=f"The car is steering: {findTurn(df,x)}")
        print(f"carPos = {carPos}, X = {NewX}, Y = {NewY}")
        drawDot(NewX, NewY)


if __name__ == "__main__":
    #enter desired file path
    csvPath = 'testFile.csv' 

    #entered used columns headers
    columnsToLoad = ['Car Pos Norm', 'Car Coord X', 'Car Coord Y','Engine RPM','Gear','Ground Speed',"Steering Angle"] 

    try:
        df = loadSpecificColumns(csvPath, columnsToLoad)
        print("Data loaded:")
        print(df)
    except Exception as e:
        print(f"Error: {e}")
    useDataExample(df)
