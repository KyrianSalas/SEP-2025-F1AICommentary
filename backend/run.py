import subprocess
import sys
import os
import signal

def _stop_process_group(proc: subprocess.Popen, timeout_seconds: float = 5.0) -> None:
    """Terminate the uvicorn process group so reload children don't linger on the port."""
    if proc.poll() is not None:
        return

    try:
        os.killpg(proc.pid, signal.SIGINT)
    except ProcessLookupError:
        return

    try:
        proc.wait(timeout=timeout_seconds)
        return
    except subprocess.TimeoutExpired:
        pass

    for sig in (signal.SIGTERM, signal.SIGKILL):
        if proc.poll() is not None:
            return
        try:
            os.killpg(proc.pid, sig)
        except ProcessLookupError:
            return
        try:
            proc.wait(timeout=timeout_seconds)
            return
        except subprocess.TimeoutExpired:
            continue

def run_server(port=8000, reload=True):
    backend_root = os.path.dirname(os.path.abspath(__file__))
    fastf1_cache_dir = os.path.join(backend_root, 'cache')
    app_dir = os.path.join(backend_root, 'fast_app')
    models_dir = os.path.join(backend_root, 'models')
    os.makedirs(fastf1_cache_dir, exist_ok=True)

    cmd = ['uvicorn', 'fast_app.main:app', '--host', '0.0.0.0', '--port', str(port)]
    
    if reload:
        cmd.extend([
            '--reload',
            '--reload-dir', app_dir,
            '--reload-dir', models_dir,
        ])
        
    cmd.extend(['--timeout-graceful-shutdown', '0'])
    
    print(f"Starting F1 Telemetry Backend on port {port}")
    print(f"FastF1 cache directory: {fastf1_cache_dir}")
    
    try:
        env = os.environ.copy()
        env['FASTF1_CACHE'] = fastf1_cache_dir
        proc = subprocess.Popen(cmd, start_new_session=True, env=env)
        return proc.wait()
    except KeyboardInterrupt:
        print("\n\nStopping server...")
        _stop_process_group(proc)
        print("Server stopped.")
        return 0
    except FileNotFoundError:
        print("Error: uvicorn not found. Make sure you are in a virtual environment and run: pip install uvicorn")
        return 1
    finally:
        if 'proc' in locals() and proc.poll() is None:
            _stop_process_group(proc)

if __name__ == '__main__':
    sys.exit(run_server())
