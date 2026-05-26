import subprocess
import sys
import os

# Super Messy but if it works it works ig
# called by my silly batch file

# Parser has just created a new file in DemoCSVs/Archive, identified in latestFile.txt
try: 
    with open(r'C:\Users\miste\Documents\SEPTESTING\sep\2025-F1AICommentary\DemoCSVs\Archive\latestFile.txt', 'r') as f:
        CSV_File = f.read().strip()
        print('New CSV detected: loading', CSV_File)
except FileNotFoundError:
    CSV_File = 'ks_brands_hatch_legends_ford_34_coupe_23-11-2025_13-57-00.csv' # default
    print('No New CSVS detected: Loading default', CSV_File)




MODES = {
    'csv': {
        'name': 'AC CSV Telemetry',
        'env': {
            'DATA_SOURCE': 'csv',
            'CSV_FILE': CSV_File
        }
    },
    'f1': {
        'name': 'FastF1 API', #defaulted to silverstone rn
        'env': {
            'DATA_SOURCE': 'fastf1',
        }
    }
}



def run_mode(mode, port=8000, reload=False, csv_file=None):
    if mode not in MODES:
        print(f"Error: Unknown mode '{mode}'")
        print(f"Available modes: {', '.join(MODES.keys())}")
        sys.exit(1)
    
    config = MODES[mode]
    env = os.environ.copy()
    env.update(config['env'])
    
    if csv_file:
        env['CSV_FILE'] = csv_file
    
    cmd = ['uvicorn', 'fast_app.main:app', f'--port', str(port)]
    
    if reload:
        cmd.append('--reload')
    
    cmd.extend(['--host', '0.0.0.0'])
    
    print(f"Starting F1 Telemetry Backend")
    
    try:
        subprocess.run(cmd, env=env)
    except KeyboardInterrupt:
        print("\n\nServer stopped.")
        sys.exit(0)
    except FileNotFoundError:
        print("Error: uvicorn not found. Install with: pip install uvicorn")
        sys.exit(1)

if __name__ == '__main__':
    args = sys.argv[1:]
    
    mode = args[0]
    port = 8000
    reload = False
    csv_file = None
    
    i = 1
    while i < len(args):
        if args[i] == '--port':
            port = int(args[i+1])
            i += 2
        elif args[i] == '--reload':
            reload = True
            i += 1
        elif args[i] == '--csv-file':
            csv_file = args[i+1]
            i += 2
        else:
            i += 1
    
    run_mode(mode, port, reload, csv_file)
