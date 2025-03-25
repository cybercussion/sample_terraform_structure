#!/usr/bin/env python3

import os
import argparse
import shutil
import subprocess
from pathlib import Path
import sys
try:
    import questionary
    from questionary import Choice
except ImportError:
    print("📦 Installing 'questionary'...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "questionary"])
    import questionary
    from questionary import Choice
    
IGNORED = {"templates", "__pycache__", ".DS_Store", "README.md", "artifacts"}

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

def choose_stack():
    base_path = Path(__file__).resolve().parent.parent / "environments"

    # Step 1: Choose account
    accounts = sorted([f.name for f in base_path.iterdir() if f.is_dir() and f.name not in IGNORED])
    account = questionary.select("Select an account:", choices=accounts).ask()
    if not account:
        return None

    # Step 2: Choose environment under that account
    account_path = base_path / account
    envs = sorted([f.name for f in account_path.iterdir() if f.is_dir() and f.name not in IGNORED])
    env = questionary.select("Select an environment:", choices=envs).ask()
    if not env:
        return None

    # Step 3: Choose stack/module under that env
    env_path = account_path / env
    stacks = sorted([
      f.name for f in env_path.iterdir()
      if (
        f.is_dir()
        and f.name not in IGNORED
        and ((f / "common.hcl").exists() or (f / "terragrunt.hcl").exists())
      )
    ])
    if not stacks:
        print(f"❌ No valid stacks found in {account}/{env}")
        return None

    stack = questionary.select("Select a stack/module:", choices=stacks).ask()
    if not stack:
        return None

    return env_path / stack

def main():
  used_wizard = False
  check_tools_installed()
  parser = argparse.ArgumentParser()
  parser.add_argument("-a", "--account", required=False, help="Account (e.g., nonprod, prod)")
  parser.add_argument("-e", "--env", required=False, help="Environment (e.g., dev, staging)")
  parser.add_argument("-f", "--folder", required=False, help="Specific folder/module")
  parser.add_argument("-c", "--command", help="Terraform command (init, plan, apply, destroy, etc)")
  parser.add_argument("--run-all", action="store_true", help="Use terragrunt run-all")
  parser.add_argument("--non-interactive", action="store_true", help="Run in non-interactive mode")
  parser.add_argument("--parallelism", type=int, help="Max number of parallel operations")
  parser.add_argument("--dry-run", action="store_true", help="Only show the command, don't run it")
  parser.add_argument("--log-level", default="info", choices=["trace", "debug", "info", "warn", "error"], help="Terragrunt log level (default: info)")
  parser.add_argument("--extra-args", nargs="*", help="Additional arguments to pass to terragrunt")
  args = parser.parse_args()
  
  if not args.account or not args.env:
    print("🔍 Launching interactive stack selector...\n")
    selected_path = choose_stack()
    if not selected_path:
        sys.exit(1)

    # Extract account/env/folder from selected path
    args.account = selected_path.parents[2].name
    args.env = selected_path.parents[1].name
    args.folder = selected_path.name

    path = selected_path  # ✅ Use the full resolved path
    used_wizard = True
  else:
      base_path = Path(__file__).resolve().parent.parent
      path = base_path / "environments" / args.account / args.env
      if args.folder:
          path = path / args.folder

  if not path.exists():
    print(f"❌ Error: Path does not exist: {path}")
    sys.exit(1)
    
  if not args.command:
    args.command = questionary.select(
      "Choose a Terraform command to run:",
      choices=["init", "validate", "plan", "apply", "destroy"]
    ).ask()
  
  # Check if CI=true, then set non-interactive mode
  if os.getenv("CI", "").lower() == "true":
    args.non_interactive = True
  else:
    if used_wizard and not args.dry_run:
      args.non_interactive = questionary.select(
        "Terragrunt interaction mode?",
        choices=[
          Choice(title="Interactive (allow prompts like create S3 bucket)", value=False),
          Choice(title="Non-interactive (recommended for CI)", value=True)
        ]
      ).ask()
    else:
        args.non_interactive = False

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