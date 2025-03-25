#!/usr/bin/env python3

import argparse
import shutil
import subprocess
from pathlib import Path
import sys

def run_terragrunt(path, command, run_all, non_interactive, parallelism, dry_run=False, log_level="info", extra_args=None):
  cmd = ["terragrunt"]
  if non_interactive:
    cmd.append("--terragrunt-non-interactive")
  if parallelism:
    cmd.append(f"--terragrunt-parallelism={parallelism}")
  
  if run_all:
    cmd += ["run-all", command]
  else:
    cmd += [command]
    
  if log_level:
    cmd.append(f"--terragrunt-log-level={log_level}")
    
  if extra_args:
    cmd.extend(extra_args)

  print(f"\n👉 Running: {' '.join(cmd)} in {path}")
  
  if dry_run:
    print(f"🧪 Dry run: Would execute '{' '.join(cmd)}' in {path}")
    return
  
  subprocess.run(cmd, cwd=path, check=True)
    
def check_tools_installed():
    errors = []
    if not shutil.which("terragrunt"):
        errors.append("❌ Error: 'terragrunt' is not installed or not found in PATH.")
    if not shutil.which("terraform"):
        errors.append("❌ Error: 'terraform' is not installed or not found in PATH.")
    
    if errors:
        for error in errors:
            print(error)
        print("Please install the missing tools and ensure they are available in your PATH.")
        sys.exit(1)

def main():
  check_tools_installed()
  parser = argparse.ArgumentParser()
  parser.add_argument("-a", "--account", required=True, help="Account (e.g., nonprod, prod)")
  parser.add_argument("-e", "--env", required=True, help="Environment (e.g., dev, staging)")
  parser.add_argument("-f", "--folder", required=False, help="Specific folder/module")
  parser.add_argument("-c", "--command", default="plan", help="Terraform command (plan, apply, destroy, etc)")
  parser.add_argument("--run-all", action="store_true", help="Use terragrunt run-all")
  parser.add_argument("--non-interactive", action="store_true", help="Run in non-interactive mode")
  parser.add_argument("--parallelism", type=int, help="Max number of parallel operations")
  parser.add_argument("--dry-run", action="store_true", help="Only show the command, don't run it")
  parser.add_argument("--log-level", default="info", choices=["trace", "debug", "info", "warn", "error"], help="Terragrunt log level (default: info)")
  parser.add_argument("--extra-args", nargs="*", help="Additional arguments to pass to terragrunt")
  args = parser.parse_args()

  # Build path
  base_path = Path(__file__).resolve().parent.parent
  path = base_path / "environments" / args.account / args.env

  if args.folder:
    path = path / args.folder

  if not path.exists():
    print(f"❌ Error: Path does not exist: {path}")
    sys.exit(1)

  run_terragrunt(
    path,
    args.command,
    args.run_all,
    args.non_interactive,
    args.parallelism,
    dry_run=args.dry_run,
    log_level=args.log_level,
    extra_args=args.extra_args
  )

if __name__ == "__main__":
  main()