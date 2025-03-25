#!/usr/bin/env python3

import argparse
import subprocess
from pathlib import Path
import sys

def run_terragrunt(path, command, run_all, summary=False, dry_run=False, log_level="info"):
    #cmd = ["terragrunt", f"--terragrunt-log-level={log_level}"]
    cmd = ["terragrunt", "--terragrunt-non-interactive", f"--terragrunt-log-level={log_level}"]
    if run_all:
        cmd += ["run-all", command]
    else:
        cmd += [command]

    print(f"\n👉 Running: {' '.join(cmd)} in {path}")
    
    if dry_run:
        print("🧪 Dry run enabled. Command not executed.")
        return
    
    subprocess.run(cmd, cwd=path, check=True)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--account", required=True, help="Account (e.g., nonprod, prod)")
    parser.add_argument("-e", "--env", required=True, help="Environment (e.g., dev, staging)")
    parser.add_argument("-f", "--folder", required=False, help="Specific folder/module")
    parser.add_argument("-c", "--command", default="plan", help="Terraform command (plan, apply, destroy, etc)")
    parser.add_argument("--run-all", action="store_true", help="Use terragrunt run-all")
    parser.add_argument("--summary", action="store_true", help="Summarize drift after plan (only applies to 'plan' command)")
    parser.add_argument("--dry-run", action="store_true", help="Only show the command, don't run it")
    parser.add_argument("--log-level", default="info", choices=["trace", "debug", "info", "warn", "error"], help="Terragrunt log level (default: info)")
    args = parser.parse_args()

    # Build path
    base_path = Path(__file__).resolve().parent.parent
    path = base_path / "environments" / args.account / args.env

    if args.folder:
        path = path / args.folder

    if not path.exists():
        print(f"❌ Error: Path does not exist: {path}")
        sys.exit(1)

    run_terragrunt(path, args.command, args.run_all, args.summary, args.dry_run, args.log_level)

if __name__ == "__main__":
    main()